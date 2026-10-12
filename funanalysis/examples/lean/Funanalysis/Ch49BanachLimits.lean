import Mathlib.Order.LiminfLimsup
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Order.Filter.IsBounded
import Mathlib.Algebra.Order.Archimedean.Real.Basic

/-!
# 第 49 章 · Banach 极限与不变平均（Lax 3.3, 4.2, 4.3）

mathlib 树中没有 Banach 极限（不存在 `BanachLimit`，全树检索确认），
但 Banach 构造的支点——p(x) = limsup aₙ——的两条关键性质可以
完整机器化：

- 平移不变性 p(Ax) = p(x)（Lax (13)）：`limsup_nat_add`；
- 夹逼 liminf ≤ p ≤ 支配（定理 3 (iv) 的骨架）：`liminf_le_limsup`。

实测坑（2026 版 mathlib 树，教训入册）：
- `eventually_of_forall` 已更名 `Filter.Eventually.of_forall`；
- `IsBoundedUnder` 是 map-像的界，从 BddAbove (range u) 转换
  要用 `isBoundedUnder_of`；
- `CountableInterFilter` 与 `IsCountablyGenerated` 已解耦，全树无
  `CountableInterFilter atTop` 实例，故 `eventually_le_limsup`
  （次可加性证明的支点）对 atTop 不可用——limsup 次可加性
  （Lax 4.2 练习）留作纸笔习题 1。
-/

open Filter

/-- 有界序列 ⟹ limsup 型有界（`IsBoundedUnder (· ≤ ·) atTop`）。 -/
theorem isBoundedUnder_of_bddAbove {u : ℕ → ℝ} (h : BddAbove (Set.range u)) :
    IsBoundedUnder (· ≤ ·) atTop u := by
  obtain ⟨C, hC⟩ := h
  exact isBoundedUnder_of ⟨C, fun x => hC ⟨x, rfl⟩⟩

/-- 有界序列 ⟹ liminf 型有界（`IsBoundedUnder (· ≥ ·) atTop`）。 -/
theorem isBoundedUnder_of_bddBelow {u : ℕ → ℝ} (h : BddBelow (Set.range u)) :
    IsBoundedUnder (· ≥ ·) atTop u := by
  obtain ⟨C, hC⟩ := h
  exact isBoundedUnder_of ⟨C, fun x => hC ⟨x, rfl⟩⟩

-- 平移不变（Lax (13)）：去掉前 k 项不改变 limsup——
-- 这正是 Banach 极限构造中 p(Ax) = p(x) 的逐字机器化。
example (f : ℕ → ℝ) (k : ℕ) :
    limsup (fun i => f (i + k)) atTop = limsup f atTop :=
  limsup_nat_add f k

-- 夹逼下界：liminf ≤ limsup（Banach 极限性质 (iv) 的骨架）。
example (f : ℕ → ℝ) (h1 : BddAbove (Set.range f)) (h2 : BddBelow (Set.range f)) :
    liminf f atTop ≤ limsup f atTop :=
  liminf_le_limsup (isBoundedUnder_of_bddAbove h1) (isBoundedUnder_of_bddBelow h2)

-- 常序列的 limsup = 常值（性质 (i)：收敛列上 LIM = lim 的影子）。
example (c : ℝ) : limsup (fun _ : ℕ => c) atTop = c := by
  simp [limsup_const]

#check @limsup_nat_add
#check @limsup_const
