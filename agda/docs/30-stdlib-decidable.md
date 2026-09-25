# 30 · stdlib 判定性体系：Dec / Recomputable / 判定式

15 章的 `Dec` 让你看到了"布林判定与命题证明的分野"。这一章把 `Relation.Nullary`
整片掀开：`Dec` 的内部构造（它不是 `data`，是 `record`）、`Recomputable`
为什么能让你在 `irrelevance` 下"把证明捡回来"、判定式组合子（`_×?_` 家族）、
以及 3.0 的 `_≡?_`/`_≈?_` 改名现场。**判定性不是附赠品，是 stdlib 几乎所有
"可判定性质"跑得动的地基。**

对应示例：`../examples/Ex30_stdlib-decidable.agda`

## 30.1 `Dec` 到底长什么样：一个 record，不是 data

很多教材画 `Dec A = yes A ⊎ no (¬ A)`。**在 3.0 里它不是 sum，是 `record`**。

实测（`Relation/Nullary/Decidable/Core.agda` 第 52–61 行）：

```agda
record Dec (A : Set a) : Set a where
  constructor _because_
  field
    does  : Bool
    proof : Reflects A does

pattern yes a = true because ofʸ a
pattern no ¬a = false because ofⁿ ¬a
```

拆开看：

- 一个 `Dec A` 元素 = **一个 `Bool`（`does`）+ 一个"这个 Bool 反映命题真伪"
  的证据（`proof : Reflects A does`）**。
- `Reflects A true` 表示"`A` 为真"（构造子 `ofʸ`），`Reflects A false` 表示
  "`A` 为假"（`ofⁿ`）。
- `yes a` / `no ¬a` 只是**模式**（`pattern`），不是构造子——`_because_` 才是
  构造子。所以你不能给 `Dec` 做模式匹配之外的"分派"，它天生是判定机。

**为什么用 record 而不是 sum？** 因为 `record + pattern` 让你能同时拥有：
① 一个能进计算的 `Bool`（`does`）；② 一个命题证据（`proof`）。sum 做不到——
你只能要么存值要么存证，没法带上一个"可计算的判定结果"。

## 30.2 `Recomputable`：把"无关证据"捡回来

`irrelevant`（标 `.` 的点）参数运行时擦掉，代价是你在需要它的时候**拿不到**。
`Recomputable` 是把它们"重建"出来的桥：

实测（`Relation/Nullary/Recomputable/Core.agda` 第 30–31 行）：

```text
30:Recomputable : (A : Set a) → Set a
30:Recomputable A = .A → A
```

`Recomputable A` 就是一个**论证解引用**：给你一个被擦除的 `A`，仍能还给你一个
实心 `A`。靠的是 `Dec`：

实测（`Relation/Nullary/Decidable/Core.agda` 第 82–89 行）：

```text
82:recompute : Dec A → Recomputable A
83:recompute = Reflects.recompute ∘ proof
```

`sorted : ∀ {A} → Dec A → .A → A`——只要你有 `a? : Dec A` 和一个擦掉的 `a`，
`recompute a? a` 就从判定里把证据重建出来。这才是"判定性 = 可用来擦除后
复原证据"的机制。

## 30.3 判定式组合子与 `⌊_⌋`

`Data.Nat`/`Data.Fin` 的 `_≡?_`/`_≤?_` 返回 `Dec`。把 `Dec` 变成 `Bool` 用
`⌊_⌋`：

实测（`Relation/Nullary/Decidable/Core.agda` 第 150–164 行）：

```text
isYes : Dec A → Bool
isYes (true because _) = true
isYes (false because _) = false
⌊_⌋ = isYes
```

`Decidable` 定义在 `Relation/Binary/Definitions.agda` 第 271–272 行：

```text
271:Decidable : REL A B ℓ → Set _
272:Decidable _∼_ = ∀ x y → Dec (x ∼ y)
```

组合子实测（`Relation/Nullary/Decidable/Core.agda`，第 95/108 行；旧名
`_×-dec_` 已标注 v2.4 弃用，`Relation.Nullary.Decidable` 门面整体 public
转发 Core，两处 import 都拿得到）：

| 组合子 | 类型 | 作用 |
|---|---|---|
| `_×?_` | `Dec A → Dec B → Dec (A × B)` | 逻辑且 |
| `_⊎?_` | `Dec A → Dec B → Dec (A ⊎ B)` | 逻辑或 |
| `_→?_` | `Dec A → Dec B → Dec (A → B)` | 蕴含 |
| `¬?_` | `Dec A → Dec (¬ A)` | 取否（在 `Decidable.Core`，第 100 行附近） |

## 30.4 3.0 改名：`_≟_` → `_≡?_`

3.0 高亮（`CHANGELOG.md`）把判定式记法标准化：

- `_≡?_`：`DecidableEquality`（即 `Decidable _≡_`）。
- `_≈?_`：一般 `IsDecEquivalence` 的字段名。
- 旧名 `_≟_` **保留但废弃**，是 `_≡?_` 的同义别名。

实测（`Data/Nat/Properties.agda` 第 2448–2450 行）：

```text
2448:infix 4 _≟_
2449:_≟_ = _≡?_
```

所以示例里 `open import Data.Nat using (_≡?_)` 得到新名；27 章八件套及其它
早期章节里你若还写 `_≟_`，会收到 deprecation 警告（仍退出码 0）。**新代码
一律写 `_≡?_`。**

## 坑位清单

1. **`Dec` 是 record，`_because_` 是构造子**，`yes`/`no` 只是 pattern。想从
   `Dec A` 里拿证据，用 `toWitness`/`fromWitness`（`Decidable.Core`），别
   直接 `with` 出构造子要 `Reflects` 拆。
2. **`⌊_⌋` 只给 `Bool`，捡不回证据**——需要真证就 `from-yes`
   （`Decidable.Core`，`from-yes : (a? : Dec A) → .A`）。
3. **`¬?` 是 `Dec A → Dec (¬ A)`**，不是取反的 `Bool` 运算；`Dec` 族与
   `Bool` 族是两套宇宙，别拿 `not ⌊ ⌋` 冒充 `¬?`。
4. **3.0 用 `_≡?_`/`_≈?_`，`_≟_` 已废弃**：旧代码跑通但满屏弃用警告，新代码
   该用 `?` 家族。
5. **`Decidable` 两个参数是关系 `_∼_` 和两个对象**——`Decidable _≡_ ℕ` 这样写
   是错的，正确是 `Decidable (_≡_ {A = ℕ})`（关系层面点开两点）。
6. **组合子旧名 `_×-dec_` 等已弃用**，统一 `_×?_`/`_⊎?_`/`_→?_`。

---
上一章：[29 · stdlib 代数结构](29-stdlib-algebra.md) ｜ 下一章：[31 · stdlib 关系产业](31-stdlib-relations.md) ｜ 返回：[README](../README.md)