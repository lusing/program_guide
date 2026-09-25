# 34 · stdlib 自动证明：Reasoning 链与 Tactic 求解器

14、27 章用过链式推理。这一章把 `Relation.Binary.Reasoning` 和 `Tactic`
求解器讲到底：链式推理的**基础设施**（`Base.Single/Double/Triple` 到底导出
哪些语法）、`begin`/`begin-equality` 的区别（坑：Triple 的 `begin` 回到
`≤` 而不回 `≤` 相等）、`Tactic.Cong`/`MonoidSolver`/`RingSolver` 什么时候
真能一键收工。**目标是把"写证明"从手工单步推进升级成"把式子摆给编译器
算平"**。行号实测于 `/Volumes/mac004/lang/agda-stdlib/src`。

对应示例：`../examples/Ex34_stdlib-automation.agda`

## 34.1 推理基础设施：Single / Double / Triple

`Relation/Binary/Reasoning/Base/` 下三个心：`Single`（单关系）、`Double`
（等式+弱序）、`Triple`（等式+弱序+强序）。各自是一套专供实例化的"语法
引擎"：定义 `data _IsRelatedTo_`、`_go` 步骤、`begin`/`end` 语法，然后由
高层模块（`Relation.Binary.Reasoning.Preorder`/`PartialOrder`/`Setoid`）用
具体关系去实例化。

实测 `Base.Single` 导出（第 47–50 行）：

```agda
open begin-syntax _IsRelatedTo_ start public
open ≡-syntax _IsRelatedTo_ ≡-go public
open ∼-syntax _IsRelatedTo_ _IsRelatedTo_ ∼-go public
open end-syntax _IsRelatedTo_ stop public
```

`Base.Triple` 导出（第 122–130 行）多了这三条抽象层：

```text
open begin-syntax ... start public               -- begin → _≤_（见坑 1）
open begin-equality-syntax ... eqRelation public -- begin-equality → _≈_
open begin-strict-syntax ... strictRelation public
open ≡-syntax / ≈-syntax / ≤-syntax / <-syntax ... public -- 对应每轨的 ⟨ ⟩
open end-syntax ... stop public
```

`begin` 与 `begin-equality` 的差别**极坑**（`Base.Triple` 第 47–50 行）：

```text
47:start : _IsRelatedTo_ ⇒ _≤_
48:start (equals x≈y)    = reflexive x≈y
49:start (nonstrict x≤y) = x≤y
50:start (strict x<y)    = <⇒≤ x<y
```

`start` 把终结目标**归一成 `≤`**。所以从 `begin` 起步的链，`∎` 落到 `≤`；
你要证 `≡` 时，务必用 `begin-equality`，否则最后一步类型对不上。

另一处换代：旧 `step-∼`/`_∼⟨_⟩_` 在 2.0 已弃用（`Base.Double` 第 95–101 行有
`WARNING_ON_USAGE`），一律写 `_≈⟨_⟩_`/`_≲⟨_⟩_`/`_≤⟨_⟩_`。

## 34.2 高层接口怎么拿

给一个 bundle 实例，打开对应 reasoning 模块（31 章 31.5 预告过）：

```agda
open import Relation.Binary.Reasoning.PartialOrder ≤-poset
  using (begin_; begin-equality_; _≤⟨_⟩_; _≡⟨_⟩_; _∎)

open import Relation.Binary.Reasoning.Setoid setoid
  using (begin_; _≈⟨_⟩_; _∎)
```

`PartialOrder` 底下挂 `Triple`，`Preorder` 挂 `Double`，`Setoid` 挂 `Single`
（但把 `∼-go` 改 `≈-go`，它的 `_≈⟨_⟩_` 是对 `_≈_` 的）。想要 `≡`/`≤` 双轨
混排，就开 `PartialOrder`（它有 `_≡⟨_⟩_` 与 `_≤⟨_⟩_` 两条轨）。

## 34.3 Tactic：让宏证明

三把常用的宏（都要求目标是词化等式/某类单词）：

**`Tactic.Cong`**（`Tactic/Cong.agda` 第 239–241 行）：

```text
239:macro
240:  cong! : ∀ {a} {A : Set a} {x y : A} → x ≡ y → Term → TC ⊤
```

用在 reasoning 链的一个 `≡⟨ ⟩` 步骤里：把"这一步只在某参数位置变了"的反
归约成 `cong`，自动找 `cong f eq`。典型写进链里：

```text
≡⟨ cong! (+-identityʳ m) ⟩
```

**`Tactic.MonoidSolver`**（`Tactic/MonoidSolver.agda` 第 268–270 行）：

```text
268:macro
269:  solve : Term → Term → TC _
270:  solve = solve-macro
```

用法（29 章预告过）：给一个 `Monoid` bundle，把目标两侧当 monoid 词，宏
当场算平：

```agda
open import Tactic.MonoidSolver using (solve)
open import Data.Nat.Properties using (+-0-monoid)   -- 一个 Monoid bundle

mono-proof : ∀ a b c → a + b + c ≡ b + a + c
mono-proof a b c = solve +-0-monoid
```

**`Tactic.RingSolver`**：泛型版，两个宏都在 `Tactic/RingSolver.agda`——
`solve-∀`（第 300–302 行，`Name → Term → TC ⊤`，第一参是 ring 名）与
`solve`（第 386–388 行，`Term → Name → Term → TC ⊤`，ring 名居中）；
`Data.Nat.Tactic.RingSolver` 已按 ℕ 的 ring 现装配好（`solve-∀ : Term →
TC ⊤`，不用再传 ring 名；`solve : Term → Term → TC ⊤` 传两侧模板），
29 章示例给过完整用法。

## 34.4 什么时候用宏，什么时候别用

- **用宏**：目标自己就是 monoid/ring 词（只有 `+`/`*`/变量/常量、无 `if`、
  无 recursor）。宏在两秒钟内给你 `refl`。
- **别用宏**：目标含 `if`、`map`、`replicate` 或任何非"纯词"的函数调用——
  宏只懂"词"结构，出结果就忘，宁可拆成链里几步 `≡⟨⟩`/`≡⟨ cong? ⟩`。
- **Reasoning 链永远是主力**，宏是"最后一里路"：链把"我要证什么"的叙事写
  出来，宏把"这一步算平"偷懒。

## 坑位清单

1. **`Triple` 的 `begin` 回到 `≤` 而非 `≡`**：证等式用 `begin-equality`，
   `begin`/`∎` 归一成 `≤` 时最后一步会 `Type mismatch`。
2. **旧 `step-∼`/`_∼⟨_⟩_` 弃用**：新链写 `_≈⟨_⟩_`/`_≲⟨_⟩_`/`_≤⟨_⟩_`；`Setoid`
   模块做了 `renaming`，它导出的就是 `_≈⟨_⟩_`。
3. **`cong!` 是链内宏**，参数是"这一步的左/右等式"，不是直接给出整个 `cong`；
   别拿它当 `refl`。
4. **MonoidSolver/RingSolver 只认词**：含 `if`/函数调用算不动。先把非词部分
   `with`/`cong` 剥出去，剩下的词再交给 `solve`。
5. **`Data.Nat.Tactic.RingSolver` 的 `solve` 传两侧模板**；`Tactic.RingSolver`
   的 `solve-∀` 是"对任意变量"形式（`Name → Term → TC ⊤`），两者别混。
6. **高层 reasoning 模块名 = bundle 名**：`Relation.Binary.Reasoning.Preorder`
   配 `Relation.Binary.Reasoning` 下的 `Preorder`，别串到别的 bundle（用错
   关系参数立刻 `Type mismatch`）。

---
上一章：[33 · stdlib 数据结构系统](33-stdlib-data.md) ｜ 下一章：[35 · macOS 校验与 3.0 迁移](35-macos-checklist.md) ｜ 返回：[README](../README.md)