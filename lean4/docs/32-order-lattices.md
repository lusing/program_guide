# 32 · 序与格

> 对应示例：`examples/19_mathlib_order_lattices/order_lattices.lean`

**对标**: *Mathematics in Lean* 第8-9章（Hierarchies / Groups and Rings 中的序部分）；Mathlib `Order/` 库。

序关系（`≤`）是数学的另一条主干。Mathlib 把"序"组织成一条精致的类型类层级：
从最弱的 `Preorder` 到 `PartialOrder`、`LinearOrder`，再到带上下确界运算的 `Lattice`
和带任意上下确界的 `CompleteLattice`。本章顺着这条层级走一遍。

## 32.1 序结构层级

```lean
import Mathlib.Order.Lattice
import Mathlib.Order.CompleteLattice.Basic
import Mathlib.Order.Hom.Basic
import Mathlib.Order.GaloisConnection.Basic
import Mathlib.Data.Set.Basic
import Mathlib.Data.Set.Lattice.Order
import Mathlib.Tactic

open OrderHom

#check (inferInstance : Preorder Nat)      -- inferInstance : Preorder ℕ
#check (inferInstance : PartialOrder Nat)  -- inferInstance : PartialOrder ℕ
#check (inferInstance : LinearOrder Nat)   -- inferInstance : LinearOrder ℕ
```

三层结构逐级加强：

| 类型类 | 公理 | 直觉 |
|---|---|---|
| `Preorder` | `≤` 自反、传递 | 预序（可能有不可比元素） |
| `PartialOrder` | + 反对称（`a ≤ b ∧ b ≤ a → a = b`） | 偏序 |
| `LinearOrder` | + 全序（`a ≤ b ∨ b ≤ a`） | 线序/全序 |

基本引理直接对应公理：

```lean
example (a : Nat) : a ≤ a := le_refl a
example (a b c : Nat) (h1 : a ≤ b) (h2 : b ≤ c) : a ≤ c := le_trans h1 h2
example (a b : Nat) (h1 : a ≤ b) (h2 : b ≤ a) : a = b := le_antisymm h1 h2

-- 严格序 < 由非严格序 ≤ 刻画
example (a b : Nat) : a < b ↔ a ≤ b ∧ ¬ b ≤ a := by omega
```

> **命名规律**：序引理遵循 `le_*`（`≤`）、`lt_*`（`<`）前缀。`le_refl`/`le_trans`/`le_antisymm`
> 是三大公理；`lt_iff_le_not_le` 这类把 `<` 翻译成 `≤` 的引理在 `Mathlib.Order.Basic`。
> 注意 `≤` 的记法 `≤` 与函数名 `LE.le` 是两回事——`a ≤ b` 脱糖为 `LE.le a b`，由类型类提供实例。

## 32.2 格：上确界 ⊔ 与下确界 ⊓

`Lattice` 在偏序上加两个二元运算：`a ⊔ b`（join/sup，最小上界）和 `a ⊓ b`（meet/inf，最大下界）。
在 `Nat` 上 `⊔ = max`、`⊓ = min`；在 `Bool` 上 `⊔ = ||`、`⊓ = &&`；在 `Set` 上 `⊔ = ∪`、`⊓ = ∩`。

```lean
#eval (5 : Nat) ⊔ 3              -- 5（Nat 上 ⊔ = max）
#eval (5 : Nat) ⊓ 3              -- 3（Nat 上 ⊓ = min）
#eval (true : Bool) ⊓ false      -- false
#eval (true : Bool) ⊔ false      -- true
```

刻画上下确界的" universal 性质"引理是 proving 格恒等式的主力：

```lean
example (a b : Nat) : a ≤ a ⊔ b := le_sup_left
example (a b : Nat) : b ≤ a ⊔ b := le_sup_right
example (a b c : Nat) (h1 : a ≤ c) (h2 : b ≤ c) : a ⊔ b ≤ c := sup_le h1 h2
example (a b : Nat) : a ⊓ b ≤ a := inf_le_left
example (a b : Nat) : a ⊓ b ≤ b := inf_le_right
example (a b c : Nat) (h1 : c ≤ a) (h2 : c ≤ b) : c ≤ a ⊓ b := le_inf h1 h2

-- 交换律、结合律
example (a b : Nat) : a ⊔ b = b ⊔ a := sup_comm a b
example (a b : Nat) : a ⊓ b = b ⊓ a := inf_comm a b
example (a b c : Nat) : a ⊔ b ⊔ c = a ⊔ (b ⊔ c) := sup_assoc a b c

-- Nat 是分配格：⊓ 对 ⊔ 分配
example (a b c : Nat) : a ⊓ (b ⊔ c) = a ⊓ b ⊔ a ⊓ c := inf_sup_left a b c
```

读法：`le_sup_left : a ≤ a ⊔ b`（`a` 是 `a ⊔ b` 的下界之一），`sup_le : a ≤ c → b ≤ c → a ⊔ b ≤ c`
（任何同时是 `a`、`b` 上界的 `c`，一定也是 `a ⊔ b` 的上界）——这正是"最小上界"的两半。`inf` 对偶。

`DistribLattice` 要求 `⊓`/`⊔` 互相分配（`inf_sup_left` 等）；`Nat`、`Bool`、`Set α` 都是分配格。
更特殊的 `BooleanAlgebra` 再补一个取反运算 `ᶜ`（`Set α` 是布尔代数，`Nat` 不是）。

## 32.3 完备格：⊤ ⊥ 与任意上/下确界

`CompleteLattice` 要求**任意**子集（不只是有限个元素）都有上确界 `sSup` 和下确界 `sInf`，
并提供最大元 `⊤`、最小元 `⊥`。`Set α`（按 `⊆` 排序）是典型完备格：

```lean
#check (inferInstance : CompleteLattice (Set Nat))  -- inferInstance : CompleteLattice (Set ℕ)
example : (⊥ : Set Nat) = ∅ := rfl
example : (⊤ : Set Nat) = Set.univ := rfl
example (s : Set Nat) : s ⊆ (⊤ : Set Nat) := Set.subset_univ s
#check @sSup   -- @sSup : {α : Type u_1} → [self : SupSet α] → Set α → α
#check @sInf   -- @sInf : {α : Type u_1} → [self : InfSet α] → Set α → α
```

在 `Set α` 上：`⊥ = ∅`、`⊤ = univ`、`sSup S = ⋃₀ S`（并集）、`sInf S = ⋂₀ S`（交集），都是 `rfl`。

"最大/最小元素"用 `IsGreatest` / `IsLeast` 表达（注意它们要求元素**属于**集合）：

```lean
-- IsGreatest s a：a ∈ s 且 a 是 s 的上界
example : IsGreatest {n : Nat | n ≤ 5} 5 := ⟨by decide, fun _ hx => hx⟩
-- IsLeast s a：a ∈ s 且 a 是 s 的下界
example : IsLeast {n : Nat | 5 ≤ n} 5 := ⟨by decide, fun _ hx => hx⟩
```

`IsGreatest s a` 展开成 `a ∈ s ∧ ∀ x ∈ s, x ≤ a`，所以构造子 `⟨属于证明, 上界证明⟩`。
与之相对的 `IsLUB`（上确界，不要求属于）和 `sSup` 是另一组概念，别混淆。

## 32.4 单调函数与序同态

保序的映射在 Mathlib 里有三档，强度递增：

| 概念 | 记法 | 含义 |
|---|---|---|
| `Monotone f` | — | `a ≤ b → f a ≤ f b`（仅保序，是个谓词） |
| `OrderHom` | `α →o β` | 单调函数 + 保序证明（打包成数据） |
| `OrderEmbedding` | `α ↪o β` | 单射且 `f a ≤ f b ↔ a ≤ b`（保序且反映序） |
| `OrderIso` | `α ≃o β` | 双射序同构（双向保序，有逆） |

```lean
example : Monotone (fun n : Nat => n + 1) := fun _ _ h => Nat.succ_le_succ h

-- OrderHom（记作 →o）= 单调函数 + 保序证明
def addOneHom : Nat →o Nat where
  toFun n := n + 1
  monotone' _ _ h := Nat.succ_le_succ h
#eval addOneHom 5   -- 6

#check (OrderIso.refl Nat : Nat ≃o Nat)   -- OrderIso.refl ℕ : ℕ ≃o ℕ
```

`OrderHom` 有 `CoeFun` 实例，所以 `addOneHom 5` 能直接当函数调用。构造时用 `where` 语法填两个字段：
`toFun`（ underlying 函数）和 `monotone'`（保序证明，带撇号是 Mathlib 结构字段的惯例）。

## 32.5 Galois 连接

`GaloisConnection f g`（`f : α → β`、`g : β → α`）表示一对"互相最优逼近"的单调映射：

> `∀ a b, f a ≤ b ↔ a ≤ g b`

直觉：`f` 是 `g` 的"左伴随"。典型例子是 `Nat` 上的 `(· * 2)` 与 `(· / 2)`——
`a * 2 ≤ b` 当且仅当 `a ≤ b / 2`。

```lean
example : GaloisConnection (fun n : Nat => n * 2) (fun n => n / 2) := by
  intro a b
  constructor
  · intro h
    have : a * 2 ≤ b := h
    show a ≤ b / 2
    omega
  · intro h
    have : a ≤ b / 2 := h
    show a * 2 ≤ b
    omega
```

> **版本陷阱**：`GaloisConnection` 现在是一个**可展开的 `def`**（`:= ∀ a b, f a ≤ b ↔ a ≤ g b`），
> 不再是 `structure`。所以不能用 `constructor` 拆它（会报 "target is not an inductive datatype"），
> 要直接 `intro a b` 让它 whnf-展开成 `∀`。`omega` 前同样要先 `have`/`show` 把 lambda beta-归约掉（见 31.5）。

Galois 连接是 Mathlib 里构造"闭包算子"（closure）、研究 `⊤`/`⊥` 对偶、乃至范畴论伴随的统一工具，
出现在子群闭包、拓扑闭包、Galois 理论等大量场景。`Mathlib/Order/GaloisConnection/` 下有完整理论。

---

> 上一章：[31 · 集合与函数](31-sets-functions.md) ｜ 下一章：[33 · 滤子](33-filters.md) ｜ 返回：[README](../README.md)
