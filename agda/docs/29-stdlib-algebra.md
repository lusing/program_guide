# 29 · stdlib 代数结构：Structures / Bundles / 求解器

第四章（18 代数）带你认识了 `Semigroup`/`Monoid` 这类**接口**长什么样；
这一章把它放大成 stdlib 代数部分的"一套产业"：`Algebra.Definitions`
（一份性质词典）、`Algebra.Structures`（性质记录）、`Algebra.Bundles`
（带 `Carrier` 的整包）三层各司其职，以及一个把单调证明交给编译器的
`Solver` 家族。全程仍是 27 章教过的读法：**去看源码**，本章所有行号都是
`/Volumes/mac004/lang/agda-stdlib/src`（macOS 本教程改用 git 源，Debian
上是 `/usr/share/agda-stdlib/src`）上实测的。

对应示例：`../examples/Ex29_stdlib-algebra.agda`

## 29.1 三层结构：Definitions → Structures → Bundles

打开 `Algebra/` 目录（实测 `ls` 有 10 个子目录 + 6 个顶层模块）：
`Apartness`、`Bundles`、`Consequences`、`Construct`、`Core`、
`Definitions`、`Lattice`、`Module`、`Morphism`、`Properties`、`Solver`
与 `Structures`。它们各自只干一件事，按依赖方向排：

| 层 | 模块 | 放什么 | 例子（实测） |
|---|---|---|---|
| 定义 | `Algebra.Definitions` | **性质的类型别名**：`Associative`/`Commutative`/`Identity`/`DistributesOver` | `Associative _∙_ = ∀ x y z → ((x ∙ y) ∙ z) ≈ (x ∙ (y ∙ z))`（第 49 行） |
| 结构 | `Algebra.Structures` | **性质记录**：`IsSemigroup`/`IsMonoid`/`IsGroup`/`IsRing`，字段是上述定义 | `IsMonoid (∙ : Op₂ A) (ε : A)`，字段 `isSemigroup`+`identity`（第 190 行） |
| 整包 | `Algebra.Bundles` | **带 Carrier 的包裹**：`Monoid`/`CommutativeMonoid`/`Ring`，字段含 `Carrier`/`_≈_`/`_∙_`/`ε` | `Monoid`（第 293 行）：`Carrier`/`_≈_`/`_∙_`/`ε`/`isMonoid` |

**关键心智**：三层是"C→R→B"的依赖链，`Bundles` 依赖 `Structures`，
`Structures` 依赖 `Definitions`。但**你的 import 不用链式**——大部分时候你
从任一层的"门面"（如 `Data.Nat.Properties`）直接拿现成实例，三层结构是
为了**组织库**，不是让你每层手搓。

## 29.2 一层一层剥：以 `_+_` 的 Monoid 为例

### Definitions：性质 = 一阶类型

```agda
open import Algebra.Definitions (_≡_ {A = ℕ}) using (Associative; Commutative)
```

实测（`Algebra/Definitions.agda`）：

```text
49:Associative : Op₂ A → Set _
49:Associative _∙_ = ∀ x y z → ((x ∙ y) ∙ z) ≈ (x ∙ (y ∙ z))
52:Commutative : Op₂ A → Set _
52:Commutative _∙_ = ∀ x y → (x ∙ y) ≈ (y ∙ x)
```

`Associative _+_` 就是 `∀ x y z → (x + y) + z ≈ (x + (y + z))` 的别名。
想给某运算"证明它满足结合律"，就是给出这样一个 `∀`。**没有魔法，只是把
命题起了个名。**

### Structures：性质记录 = 一组成串的约束

```agda
open import Algebra.Structures (_≡_ {A = ℕ}) using (IsMonoid; IsSemigroup)
```

实测 `IsMonoid`（`Algebra/Structures.agda` 第 190–209 行）字段**只有两个**：

```text
190:record IsMonoid (∙ : Op₂ A) (ε : A) : Set (a ⊔ ℓ) where
192:  field isSemigroup : IsSemigroup ∙
193:        identity    : Identity ε ∙
```

注意参数是**两个**：二元运算 `∙` 和单位元 `ε`。字段 `isSemigroup` 再嵌一层，
`assoc` 是 `IsSemigroup` 的字段（`IsSemigroup`（第 128 行）字段是 `isMagma`+
`assoc`）。所以从 `IsMonoid` 拿 `assoc` 要穿过两层：

```agda
open IsSemigroup (IsMonoid.isSemigroup m) using (assoc)
```

示例 `Ex29` 的 `assoc₃` 就是这么拆的。**别在 IsMonoid 上直接找 `assoc`**
——它不是那个记录的直接字段，报错里的 `(did you mean IsMonoid.isSemigroup?)`
就是路标。

### Bundles：整包开箱

`Data.Nat.Properties` 已有焊好的实例，一个 `CommutativeMonoid` 整包：

```agda
M : CommutativeMonoid _ _
M = +-0-commutativeMonoid
open CommutativeMonoid M using (assoc; comm; identity)
```

实测 `+-0-commutativeMonoid`（`Data/Nat/Properties.agda`）字段公开了
`isCommutativeMonoid`，打开后 `assoc`/`comm`/`identity` 直接可用——因为你从
一个 `CommutativeMonoid` bundle 拿到的 `Carrier`/`_≈_`/`_∙_`/`ε` 是**具体
的**（`ℕ`/`_≡_`/`_+_`/`0`），所以这些定理都成了不含自由变量的闭合命题。

## 29.3 版本：3.0 里的"偏置结构"（Algebra.Structures.Biased）

3.0 新增 `Algebra/Structures/Biased.agda`（实测 199 行），把"只给左/右单边
性质也能建成完整结构"的能力做成记录。实测表：

| 记录 | 行号 | 字段 | 得到 |
|---|---|---|---|
| `IsCommutativeMonoidˡ` | 29 | `isSemigroup`/`identityˡ`/`comm` | 构造出 `IsCommutativeMonoid` |
| `IsCommutativeMonoidʳ` | 48 | `isSemigroup`/`identityʳ`/`comm` | 同上 |
| `IsSemiringWithoutOne*` | 69 | `+-isCommutativeMonoid`/`*-isSemigroup`/`distrib`/`zero` | `IsSemiringWithoutOne` |
| `IsRing*` | 195 | `+-isAbelianGroup`/`*-isMonoid`/`distrib`/`zero` | `IsRing` |

一句话：**如果你想证明的运算是"对称/symmetric"的，只要给一边性质**
（如只证右单位元 `identityʳ`）就能反过来补出另一边。写定理库时这能省掉
镜像复制的代码。

## 29.4 Solver 家族：把单调证明交给编译器

`Algebra/` 下有 `Solver/`（`Algebra/Solver/Monoid.agda`、`Ring.agda`），还有
`Tactic/` 层的封装（`Tactic.MonoidSolver`、`Tactic.RingSolver`）。它们是宏：
给定目标两侧属于某个 monoid / semiring 词，编译器**当场算平**。

实测（`Tactic/MonoidSolver.agda` 第 268–270 行）：

```text
268:macro
269:  solve : Term → Term → TC _
270:  solve = solve-macro
```

`Tactic.RingSolver` 的 `solve-∀` 同理（其 `solve-∀` 在第 300–302 行；它要一个
`Name` 参数，`Data.Nat.Tactic.RingSolver` 已把 ℕ 的 ring 名焊进去，所以
`Data.Nat` 版 `solve-∀ : Term → TC ⊤` 只留一个隐式洞）。

用法（示例件 3）：

```agda
open import Data.Nat.Tactic.RingSolver using (solve-∀)

ring-demo : (a b : ℕ) → (a + b) * (a + b) ≡ a * a + (a * b) + (a * b) + b * b
ring-demo = solve-∀
```

`solve-∀` 自动读目标里的全称量词与两侧，把变量当未知元、按 semiring 公理
求值，相等就出 `refl`。**注意这不是重写 `refl`，而是一次不展开闭合项的计算**
——它与 27 章说"官方 `sort` 不配合 refl"是一回事的两面：宏是"算"，
不是"证"。`MonoidSolver` 的 `solve` 则要你把 monoid bundle（如 `+-0-monoid`）
作为第一个显式实参递过去（34 章 34.3 有完整用法）。

## 坑位清单

1. **`IsMonoid` 参数是两个**（`∙` 和 `ε`），不是三个；`assoc` 不在 `IsMonoid`
   直接字段里，要 `open IsSemigroup (IsMonoid.isSemigroup m)`。报错给的路标是
   `did you mean IsMonoid.isSemigroup`。
2. **Bundles 与 Structures 同名不同物**：`Associative`（Definitions，别名）、
   `IsMonoid`（Structures，记录）、`Monoid`（Bundles，整包）是三个不同层级，
   别在别名上 `open`、别在整包上找"定义"。
3. **`Ring` 的乘法单位元字段叫 `*-identity`**，不是 `*-isMonoid`——`IsRing`
   （第 948 行）的字段是 `+-isAbelianGroup`/`*-cong`/`*-assoc`/`*-identity`/
   `distrib`，`*-isMonoid` 是内部派生出来的，不是构造参数。
4. **Solver 宏两侧要给模板词**，且必须都落在所带入的运算(semiring/monoid)语言里；
   含 `if`/函数调用等不"词化"的部分宏会拒绝或算不动。
5. **3.0 把 `Algebra.Operations.CommutativeMonoid` 等 v1.0 弃用模块删光了**，
   网上旧例子的 import 直连这些路径会 `No such module`，一律改到
   `Algebra.Bundles`/`Algebra.Structures` 的对应名字。

---
上一章：[28 · 坑清单与最佳实践](28-pitfalls.md) ｜ 下一章：[30 · stdlib 判定性体系](30-stdlib-decidable.md) ｜ 返回：[README](../README.md)