# 31 · 集合与函数

> 对应示例：`examples/18_mathlib_sets_functions/sets_functions.lean`

**对标**: *Mathematics in Lean* 第4章（Sets and Functions）；*Theorem Proving in Lean 4* 第11章。

集合论是 Mathlib 表达"数学对象的范围"的基础语言。本章覆盖 `Set` 的本质、集合运算、像与原像，
以及函数的单射/满射/双射三性质——它们贯穿整个 Mathlib，从代数到分析无处不在。

## 31.1 Set 就是 α → Prop

Lean 里没有"集合"这个原始概念：`Set α` 就是 **`α → Prop`** 的类型别名——一个集合即一个谓词，
"属于"即"满足谓词"。这带来一个关键后果：`Set` 是**经典且非构造性**的，`x ∈ s` 是一个命题，
不保证可判定，所以不能用 `#eval` 直接打印一个 `Set`（要打印具体集合得用 `Finset`，见 31.4）。

```lean
import Mathlib.Data.Set.Basic
import Mathlib.Data.Set.Image
import Mathlib.Data.Set.Lattice.Order
import Mathlib.Logic.Function.Basic
import Mathlib.Data.Finset.Basic
import Mathlib.Tactic

open Set Function

#check (Set Nat)                          -- Set ℕ : Type
#check ({n : Nat | n % 2 = 0} : Set Nat)  -- {n | n % 2 = 0} : Set ℕ

example : (2 : Nat) ∈ {n | n % 2 = 0} := by decide
example : (3 : Nat) ∉ {n | n % 2 = 0} := by decide

-- ∅（空集）与 univ（全集）是两个极端
example (x : Nat) : x ∈ (Set.univ : Set Nat) := trivial
example (x : Nat) : x ∉ (∅ : Set Nat) := fun h => h
```

集合构造记法 `{x : α | p x}`（注意是竖线 `|`，区别于子类型的 `//`）读作"所有满足 `p` 的 `x`"。
`x ∈ {x | p x}` 按定义就等于 `p x`，所以 `decide` 能直接判定具体数值。

## 31.2 集合运算与德摩根律

并 `∪`、交 `∩`、差 `\`、补 `ᶜ` 都按谓词逐点定义：`x ∈ s ∪ t ↔ x ∈ s ∨ x ∈ t`，依此类推。

```lean
example (s t : Set Nat) : s ∩ t ⊆ s := inter_subset_left
example (x : Nat) (s t : Set Nat) : x ∈ s ∪ t ↔ x ∈ s ∨ x ∈ t := mem_union x s t
example (s t : Set Nat) : s \ t = s ∩ tᶜ := Set.sdiff_eq s t

-- 德摩根律：ext 引入元素后化简
example (s t : Set Nat) : (s ∪ t)ᶜ = sᶜ ∩ tᶜ := by ext x; simp
example (s t : Set Nat) : (s ∩ t)ᶜ = sᶜ ∪ tᶜ := by ext x; grind

-- 分配律
example (s t u : Set Nat) : s ∩ (t ∪ u) = (s ∩ t) ∪ (s ∩ u) := by
  ext x
  grind
```

> **为什么第二条德摩根律要用 `grind` 而不是 `simp`**：`¬(P ∨ Q) ↔ ¬P ∧ ¬Q` 是**构造性**成立的，
> `simp` 直接关掉；但 `¬(P ∧ Q) ↔ ¬P ∨ ¬Q` 需要**排中律**（经典逻辑）。`simp` 是构造性的，
> 推不出它；`grind`（4.35 起的核心自动化）和 `aesop` 内置经典推理，能直接关闭。这也是 Mathlib
> 全程 `open Classical` 的原因——数学里经典逻辑是常态。

## 31.3 子集与外延相等

证明两个集合相等的标准套路是 **`ext`（外延性）+ 逐点证 `↔`**：`s = t` 当且仅当 `∀ x, x ∈ s ↔ x ∈ t`。

```lean
-- ⊆ 的定义：s ⊆ t 当且仅当每个 x ∈ s 也 ∈ t
example (s t : Set α) : s ⊆ t ↔ ∀ x ∈ s, x ∈ t := by
  constructor
  · intro h x hx
    exact h hx
  · intro h x hx
    exact h x hx

theorem set_ext_demo (s t : Set α) (h : ∀ x, x ∈ s ↔ x ∈ t) : s = t := by
  ext x
  exact h x

example (s t : Set α) : s ∪ t = t ∪ s := by
  ext x
  grind
```

> **版本陷阱**：`Set.subset_def` 现在陈述为**命题等式** `(s ⊆ t) = (∀ x ∈ s, x ∈ t)`（用 `=` 而非 `↔`，
> 且用 `∀ x ∈ s` 绑定记法），不能再当 `↔` 直接 `exact`。上面用 `constructor` 手动证更稳妥。

`ext` 战术背后是 `Set.ext` 引理；它对任何"由成员刻画"的类型都适用（子群、理想、滤子……），
是 Mathlib 里出场率最高的战术之一。

## 31.4 像、原像、值域

给定 `f : α → β`：

| 概念 | 记法 | 定义 |
|---|---|---|
| 像 image | `f '' s` | `{y | ∃ x ∈ s, f x = y}` |
| 原像 preimage | `f ⁻¹' t` | `{x | f x ∈ t}` |
| 值域 range | `Set.range f` | `{y | ∃ x, f x = y}` |

```lean
example (f : α → β) (s : Set α) : f '' s = {y | ∃ x ∈ s, f x = y} := by
  ext y
  grind
example (f : α → β) (t : Set β) : f ⁻¹' t = {x | f x ∈ t} := rfl
example (f : α → β) : range f = {y | ∃ x, f x = y} := rfl

-- 像/原像与复合
example (f : α → β) (g : β → γ) (s : Set α) : g ∘ f '' s = g '' (f '' s) :=
  image_comp g f s
example (f : α → β) (g : β → γ) (t : Set γ) : (g ∘ f) ⁻¹' t = f ⁻¹' (g ⁻¹' t) :=
  preimage_comp

-- 单射 ⇒ 原像∘像 = 原集合；满射 ⇒ 像∘原像 = 原集合
example (f : α → β) (s : Set α) (h : Injective f) : f ⁻¹' (f '' s) = s :=
  preimage_image_eq s h
example (f : α → β) (t : Set β) (h : Surjective f) : f '' (f ⁻¹' t) = t :=
  image_preimage_eq t h
```

注意 `f ⁻¹' t = {x | f x ∈ t}` 和 `range f = {y | ∃ x, f x = y}` 都是 `rfl`（按定义相等），
而像 `f '' s` 的刻画需要 `ext + grind`，因为 `''` 的定义里包了一层 `∃`。

`Set` 是谓词、不可计算，所以**具体集合的求值要用 `Finset`**（有限集合，带 `DecidableEq` 可 `#eval`）：

```lean
#eval (({1, 2, 3} : Finset Nat).image (· * 2))         -- {2, 4, 6}
#eval (({1, 2, 3, 4} : Finset Nat).filter (· % 2 = 0)) -- {2, 4}
#eval (({1, 2, 3} : Finset Nat) ∪ {3, 4})              -- {1, 2, 3, 4}
#eval (({1, 2, 3} : Finset Nat) \ {2})                 -- {1, 3}
```

`Finset` 与 `Set` 的关系：`Finset α` 携带一个 `Set α`（`↑s` 强制转换）外加"有限性"证明。
组合数学（第17章）大量用 `Finset`，分析/代数里"子集"则多用 `Set`。

> **版本陷阱**：`Set.diff_eq`（`s \ t = s ∩ tᶜ`）已弃用，改名 `Set.sdiff_eq`。
> 另外 `Mathlib.Data.Set.Lattice` 这个旧导入已**拆分**为 `.Bounded` / `.Disjoint` / `.Image` /
> `.Indexed` / `.Order` 五个子模块，直接 import 旧名会报 deprecation 警告。

## 31.5 单射、满射、双射

`Function` 命名空间（`open Function` 后可省前缀）定义了三性质：

- `Injective f`：`f a = f b → a = b`（不同输入给不同输出）
- `Surjective f`：`∀ b, ∃ a, f a = b`（值域覆盖整个陪域）
- `Bijective f`：`⟨Injective f, Surjective f⟩`（既是单射又是满射）

```lean
-- fun n => n + 1 在 ℕ 上单射但不满射（0 不在值域）
example : Injective (fun n : Nat => n + 1) := fun _ _ h => Nat.succ.inj h
example : ¬ Surjective (fun n : Nat => n + 1) := by
  intro h
  obtain ⟨n, hn⟩ := h 0
  have : n + 1 = 0 := hn   -- 先 beta-归约，omega 才认得
  omega

-- ℤ 上的后继是双射
example : Surjective (fun n : Int => n + 1) := by
  intro b
  use b - 1
  show (b - 1) + 1 = b
  omega
example : Bijective (fun n : Int => n + 1) := by
  refine ⟨?_, ?_⟩
  · intro x y h
    have : x + 1 = y + 1 := h
    omega
  · intro b
    use b - 1
    show (b - 1) + 1 = b
    omega

-- 复合保持单射/满射
example (f : α → β) (g : β → γ) (hf : Injective f) (hg : Injective g) :
    Injective (g ∘ f) := Injective.comp hg hf
example (f : α → β) (g : β → γ) (hf : Surjective f) (hg : Surjective g) :
    Surjective (g ∘ f) := Surjective.comp hg hf
```

> **版本陷阱（高频）**：`omega` **不会自动 beta-归约** lambda。目标若是 `(fun n => n + 1) (b - 1) = b`，
> `omega` 会把 `(fun n => n+1)(b-1)` 当成一个不透明原子，报 "No usable constraints" 或给出假反例。
> 必须先用 `show (b - 1) + 1 = b` 或 `have : n + 1 = 0 := hn` 把 beta-redex 显式归约掉，再 `omega`。
> 这是把"后继函数"写成 lambda 时最常踩的坑。

注意单射/满射对**同一个映射在不同底数域上结论不同**：`n ↦ n + 1` 在 `Nat` 上不满射（漏掉 0），
在 `Int` 上却是双射（`b ↦ b - 1` 是它的逆）。

## 31.6 左逆、右逆、等价

```lean
-- LeftInverse g f 即 g ∘ f = id；有左逆 ⇒ 单射，有右逆 ⇒ 满射
example (f : α → β) (g : β → α) (h : LeftInverse g f) : Injective f :=
  LeftInverse.injective h
example (f : α → β) (g : β → α) (h : RightInverse g f) : Surjective f :=
  RightInverse.surjective h
```

`Equiv α β`（记作 `α ≃ β`）把双射**打包成数据**：一个 `toFun`、一个 `invFun`，外加两条逆律
`left_inv : e.symm (e x) = x` 与 `right_inv : e (e.symm y) = y`。它比"裸双射"好用，因为逆映射是显式的。

```lean
#check (Equiv.refl Nat : Nat ≃ Nat)        -- Equiv.refl ℕ : ℕ ≃ ℕ
#check (Equiv.symm : Nat ≃ Int → Int ≃ Nat) -- Equiv.symm : ℕ ≃ ℤ → ℤ ≃ ℕ
example (e : Nat ≃ Int) : Int ≃ Nat := e.symm
example (e : Nat ≃ Int) (n : Nat) : e.symm (e n) = n := e.left_inv n

-- 由双射构造等价：Equiv.ofBijective（依赖经典选择，故 noncomputable）
#check @Equiv.ofBijective
-- @Equiv.ofBijective : {α : Sort u_1} → {β : Sort u_2} → (f : α → β) → Bijective f → α ≃ β
```

> **版本陷阱**：`Equiv.ofBijective` 是 `noncomputable`——从"双射存在"造出"显式逆映射"要用经典选择
> （`Classical.choice`）。把它写进 `example` 会触发 `dependsOnNoncomputable` 编译错误；要演示就用
> `#check @Equiv.ofBijective` 看类型，或把结果标 `noncomputable def`。

### Schröder–Bernstein 定理

集合论的经典结论：**若存在单射 `α → β` 和单射 `β → α`，则 `α` 与 `β` 等势**（存在双射）。
Mathlib 在 `Mathlib/SetTheory/Cardinal/SchroederBernstein.lean` 中给出：

```text
theorem schroeder_bernstein {f : α → β} {g : β → α}
    (hf : Function.Injective f) (hg : Function.Injective g) :
    ∃ h : α → β, Bijective h
```

它的证明颇具技巧性（要 carefully 把 `α` 拆成"被 `g` 覆盖"与"未被覆盖"两部分分别定义双射），
是 *Mathematics in Lean* 第4章的压轴练习。本教程不展开证明，只指出它的位置与陈述——
需要时 `import Mathlib.SetTheory.Cardinal.SchroederBernstein` 即可引用。

---

> 上一章：[29 · 性能、编译与程序验证](29-performance-verification.md) ｜ 下一章：[32 · 序与格](32-order-lattices.md) ｜ 返回：[README](../README.md)
