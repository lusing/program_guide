import Mathlib.SetTheory.Ordinal.Arithmetic
import Mathlib.Tactic

open scoped Ordinal
open Order

/-!
# 第 71 章 · 序数与累积层次（冯琦 §1.7）

定义 1.57 的内禀三条件在商序数类上的官方化身：可比较性（定理 1.50）、
最小序数原理（定理 1.51）、极限序数存在（定理 1.52）。4.33 的引理族
换了一代（IsLimit 不存在，幸存者是 Order.IsSuccLimit；succ 走
SuccOrder 通用实例，点记号被 Quot 头部劫持——须写 Order.succ a）。
-/

namespace Settheory.Ch71

-- ---------- 定理 1.50（可比较性）：三择一的官方形态 ----------

/-- 冯琦的 Φ₁（∈-连通）+ Φ₂（良基）在商序数类上浓缩成一条
`lt_trichotomy`——任何两个序数恰居 <、=、> 三者之一。 -/
theorem comparable (a b : Ordinal) : a < b ∨ a = b ∨ b < a :=
  lt_trichotomy a b

-- ---------- 命题 1.18：后继序数 ----------

/-- α ∪ {α}（= Order.succ α）严格更大——三条件验收的一条实例。
本版点记号 a.succ 被 Quot 头部劫持，须写 Order.succ a。 -/
example (a : Ordinal) : a < Order.succ a :=
  Order.lt_succ_iff.mpr le_rfl

-- ---------- 定理 1.51：最小序数原理 ----------

/-- 序数的非空集合有最小元：良基（Φ₂ 的另一半）给出选择元。 -/
theorem min_of_nonempty {s : Set Ordinal} (h : s.Nonempty) :
    ∃ m ∈ s, ∀ b ∈ s, m ≤ b :=
  ⟨wellFounded_lt.min s h, WellFounded.min_mem _ s h,
    fun _ hb => WellFoundedLT.min_le hb⟩

-- ---------- 例 1.20 与定理 1.52：极限序数 ----------

/-- ω 是非零极限序数（4.33 的幸存名字：isSuccLimit_omega0）。 -/
example : Order.IsSuccLimit (Ordinal.omega0 : Ordinal) :=
  Ordinal.isSuccLimit_omega0

/-- 定理 1.52：任意大的极限序数存在——a + ω ≥ a 且是极限。
（官方引理 a.isSuccLimit_add_right ω。） -/
theorem exists_limit_ge (a : Ordinal) :
    ∃ l, a ≤ l ∧ IsSuccLimit l :=
  ⟨a + ω, le_add_right (le_refl a), Ordinal.isSuccLimit_add a Ordinal.isSuccLimit_omega0⟩

/-- ω 之下恰是自然数（lt_omega0）：冯诺伊曼数字填满第一层楼。 -/
example (o : Ordinal) (h : o < ω) : ∃ n : ℕ, o = n :=
  Ordinal.lt_omega0.1 h

-- ---------- 推论：布拉利-福尔蒂驯服（真类注记） ----------
/- 若全体序数成集合 s，则 sSup s 是序数且 ≥ 一切序数——含它自己的
后继，与三择一冲突。类型论的回答写在宇宙分层里：Ordinal.{u} :
Type (u+1)，"序数全体"在下一层宇宙。此为类论陈述，不做成 example。 -/

end Settheory.Ch71
