import Mathlib.Basic.Real.Basic
import Mathlib.Order.Interval.Set.Basic
import Mathlib.Algebra.Order.Archimedean.Basic
import Mathlib.NumberTheory.Real.Irrational
import Mathlib.Tactic

/-!
# 第 03 章 上确界

对应原书第 4 章《上确界》：有理数的“洞”（定理 4.1）、有序集、
上下界、上确界的定义与唯一性、定理 4.9、例 4.8 的 {1/(n+1)}、
ℚ 没有最小上界性（例 4.11），以及最小上界性与最大下界性等价
（定理 4.12、4.13）。
-/

namespace Realanalysis.Ch03

open Set

/-- 原书定理 4.1 的核心构造：A = {p ∈ ℚ, p > 0, p² < 2} 没有最大元。
    对任意 p ∈ A，取 q = (2p+2)/(p+2)，则 q > p 且 q² < 2。
    关键恒等式：q - p = (2 - p²)/(p+2)，q² - 2 = 2(p²-2)/(p+2)²。 -/
theorem q_trick_gt (p : ℚ) (h0 : 0 < p) (h2 : p ^ 2 < 2) :
    ∃ q : ℚ, p < q ∧ q ^ 2 < 2 := by
  use (2 * p + 2) / (p + 2)
  have hpos : (0 : ℚ) < p + 2 := by linarith
  constructor
  · -- p < (2p+2)/(p+2) ⟺ p(p+2) < 2p+2 ⟺ p² < 2
    rw [lt_div_iff₀ hpos]
    nlinarith [h2]
  · -- ((2p+2)/(p+2))² < 2 ⟺ (2p+2)² < 2(p+2)² ⟺ 2p² + 4 < 4p²... ⟺ p² < 2
    rw [div_pow, div_lt_iff₀ (pow_pos hpos 2)]
    nlinarith [h2]

/-- 对偶：B = {p ∈ ℚ, p > 0, p² > 2} 没有最小元。同一个 q 给出更小的成员。
    p - q = (p² - 2)/(p+2)，q² - 2 = 2(p²-2)/(p+2)² > 0。 -/
theorem q_trick_lt (p : ℚ) (h0 : 0 < p) (h2 : 2 < p ^ 2) :
    ∃ q : ℚ, 0 < q ∧ q < p ∧ 2 < q ^ 2 := by
  use (2 * p + 2) / (p + 2)
  have hpos : (0 : ℚ) < p + 2 := by linarith
  refine ⟨by positivity, ?_, ?_⟩
  · -- (2p+2)/(p+2) < p ⟺ 2p+2 < p(p+2) ⟺ 2 < p²
    rw [div_lt_iff₀ hpos]
    nlinarith [h2]
  · rw [div_pow, lt_div_iff₀ (pow_pos hpos 2)]
    nlinarith [h2]

/-- 上确界的唯一性：最小上界若存在必唯一（反对称性的直接推论）。 -/
example (s : Set ℝ) (a b : ℝ) (ha : IsLUB s a) (hb : IsLUB s b) : a = b :=
  ha.unique hb

/-- 开区间的上确界是右端点：(a, b) 的每一点都小于 b，
    而 b 左侧任意位置都能找到区间成员。 -/
example (a b : ℝ) (h : a < b) : sSup (Ioo a b) = b := csSup_Ioo h

/-- 序列值域的上确界：sup {1 - 1/(n+1) | n ∈ ℕ} = 1。
    1 是上界（每项都差一个正的单位分数）；
    它是最小的：任何 b < 1 都会被某个 n 的项超过——Archimedean 性质
    保证 1/(n+1) < 1 - b。 -/
theorem one_sub_div_lub :
    IsLUB (Set.range fun n : ℕ => 1 - 1 / (n + 1 : ℝ)) 1 := by
  refine ⟨?_, ?_⟩
  · -- 1 是上界
    rintro _ ⟨n, rfl⟩
    have h : (0 : ℝ) ≤ 1 / (n + 1 : ℝ) := by positivity
    linarith
  · -- 1 是最小上界：反证，若 b < 1 是上界则推出矛盾
    intro b hb
    by_contra hlt
    push Not at hlt
    have hε : (0 : ℝ) < 1 - b := by linarith
    obtain ⟨n, hn⟩ := exists_nat_one_div_lt hε
    have hmem := hb (Set.mem_range_self n)
    -- hmem : 1 - 1/(n+1) ≤ b，但 hn : 1/(n+1) < 1 - b，两者相加矛盾
    linarith

/-- 定义 4.2：有序集的两条公理在 ℝ 上就是三分律与传递性。 -/
example (x y : ℝ) : x < y ∨ x = y ∨ y < x := lt_trichotomy x y

example (x y z : ℝ) (hxy : x < y) (hyz : y < z) : x < z := lt_trans hxy hyz

/-- 例 4.4：A ⊆ B 时，min B ≤ min A。
    b 是 B 的下界，而 a ∈ A ⊆ B，所以 b ≤ a。 -/
example {A B : Set ℝ} {a b : ℝ}
    (hA : IsLeast A a) (hB : IsLeast B b) (hAB : A ⊆ B) : b ≤ a := by
  rcases hA with ⟨ha, -⟩
  rcases hB with ⟨-, hb⟩
  exact hb (hAB ha)

/-- 例 4.6：开区间 (0, 3) 在 ℝ 里有上界 3，但 3 自己不在区间里。 -/
example : BddAbove (Ioo (0 : ℝ) 3) := by
  use 3
  intro x hx
  exact hx.2.le

example : (3 : ℝ) ∉ Ioo (0 : ℝ) 3 := by simp [mem_Ioo]

/-- 同一个区间若只被允许在自己内部寻找上界，则上界不存在：
    任何内部候选 α 的右侧中点仍在区间里，并且比 α 大。 -/
example : ¬ ∃ α, α ∈ Ioo (0 : ℝ) 3 ∧ α ∈ upperBounds (Ioo (0 : ℝ) 3) := by
  rintro ⟨α, ⟨h0, h3⟩, hub⟩
  have hm : (α + 3) / 2 ∈ Ioo (0 : ℝ) 3 := by constructor <;> linarith
  have : (α + 3) / 2 ≤ α := hub hm
  linarith

/-- 例 4.8 的中点论证：任何小于 3 的有理数都不是 (−∞, 3) ∩ ℚ 的上界，
    因为 γ 与 3 的中点仍是有理数，并且落在 γ 与 3 之间。 -/
example (γ : ℚ) (h : γ < 3) : ∃ x : ℚ, γ < x ∧ x < 3 :=
  ⟨(γ + 3) / 2, by constructor <;> linarith⟩

/-- 定理 4.9：属于集合的上界就是最小上界。
    任何上界 b 都必须 ≥ a，因为 a 自己是集合的元素。 -/
theorem upper_bound_mem_is_lub {α : Type*} [Preorder α] {s : Set α} {a : α}
    (hub : a ∈ upperBounds s) (hmem : a ∈ s) : IsLUB s a := by
  refine ⟨hub, ?_⟩
  intro b hb
  exact hb hmem

/-- 例 4.8 的练习，上确界一侧：{1/(n+1) | n ∈ ℕ} 的上确界是 1。
    1 = 1/1 属于值域，又是上界，定理 4.9 直接给出。 -/
theorem one_div_sup :
    IsLUB (Set.range fun n : ℕ => (1 : ℝ) / (n + 1)) 1 := by
  refine upper_bound_mem_is_lub ?_ ?_
  · rintro _ ⟨n, rfl⟩
    have hpos : (0 : ℝ) < (n : ℝ) + 1 := by positivity
    rw [div_le_one hpos]
    linarith
  · exact ⟨0, by simp⟩

/-- 例 4.8 的练习，下确界一侧：下确界是 0，而 0 不属于值域。
    任何正数 b 都会被某个足够小的 1/(n+1) 钻到底下——这是
    Archimedean 性质 `exists_nat_one_div_lt`。 -/
theorem one_div_inf :
    IsGLB (Set.range fun n : ℕ => (1 : ℝ) / (n + 1)) 0 := by
  refine ⟨?_, ?_⟩
  · rintro _ ⟨n, rfl⟩
    positivity
  · intro b hb
    by_contra hlt
    push Not at hlt
    obtain ⟨n, hn⟩ := exists_nat_one_div_lt hlt
    have hmem := hb (Set.mem_range_self n)
    linarith

/-- 开区间的下确界是左端点，与 `csSup_Ioo` 对偶。 -/
example (a b : ℝ) (h : a < b) : sInf (Ioo a b) = a := csInf_Ioo h

/-- 没有有理数的平方等于 2。若 q² = 2，则 √2 = |q|，
    与第 00 章的 `irrational_sqrt_two` 矛盾。 -/
theorem rat_sq_ne_two (q : ℚ) : q ^ 2 ≠ 2 := by
  intro h
  apply irrational_sqrt_two
  have hy : (0 : ℝ) ≤ ((|q| : ℚ) : ℝ) := by positivity
  have hsq : ((|q| : ℚ) : ℝ) ^ 2 = 2 := by
    calc
      ((|q| : ℚ) : ℝ) ^ 2 = (((|q| : ℚ) ^ 2 : ℚ) : ℝ) := by simp [Rat.cast_pow]
      _ = ((q ^ 2 : ℚ) : ℝ) := by rw [sq_abs]
      _ = (2 : ℝ) := by exact_mod_cast h
  have hsqrt : Real.sqrt 2 = ((|q| : ℚ) : ℝ) :=
    (Real.sqrt_eq_iff_eq_sq (by norm_num : (0 : ℝ) ≤ 2) hy).mpr hsq.symm
  exact ⟨(|q| : ℚ), hsqrt.symm⟩

/-- 定理 4.1 的集合 A：正有理数中平方严格小于 2 的那些。 -/
abbrev hole : Set ℚ := {p : ℚ | 0 < p ∧ p ^ 2 < 2}

theorem hole_nonempty : hole.Nonempty := ⟨1, by simp [hole]⟩

/-- 2 是 hole 的一个上界：p > 0 且 p² < 2 < 4 迫使 p < 2。 -/
theorem hole_bddAbove : BddAbove hole := by
  use 2
  intro p hp
  nlinarith [hp.1, hp.2]

/-- 例 4.11：hole 在 ℚ 里没有上确界。候选 a 先被 1 ∈ hole 逼成正数，
    再按 a² 与 2 的三分律分叉：小于 2 则还能再增大，等于 2 则不是有理数，
    大于 2 则还能再缩小。 -/
theorem hole_no_lub : ¬ ∃ a : ℚ, IsLUB hole a := by
  rintro ⟨a, ha⟩
  rcases ha with ⟨ha_ub, ha_least⟩
  have hone : (1 : ℚ) ∈ hole := by simp [hole]
  have ha_pos : 0 < a := by linarith [ha_ub hone]
  rcases lt_trichotomy (a ^ 2) 2 with hlt | heq | hgt
  · obtain ⟨q, hq, hq2⟩ := q_trick_gt a ha_pos hlt
    have hqmem : q ∈ hole := ⟨by linarith, hq2⟩
    exact lt_irrefl a (lt_of_lt_of_le hq (ha_ub hqmem))
  · exact rat_sq_ne_two a heq
  · obtain ⟨q, hq0, hq_lt, hq2⟩ := q_trick_lt a ha_pos hgt
    have hq_ub : q ∈ upperBounds hole := by
      intro p hp
      nlinarith [hp.1, hp.2, hq0, hq2]
    linarith [ha_least hq_ub, hq_lt]

/-- 定义 4.10 在 ℚ 上失败：存在非空、有上界、却没有上确界的子集。 -/
theorem rat_lacks_lub_property :
    ¬ ∀ s : Set ℚ, s.Nonempty → BddAbove s → ∃ a, IsLUB s a := by
  intro h
  exact hole_no_lub (h hole hole_nonempty hole_bddAbove)

/-- 定理 4.12。假设有序集的每个非空有上界子集都有上确界。
    则每个非空有下界子集 B 都有下确界，而且这个下确界就是
    B 的全体下界之集的上确界。 -/
theorem glb_from_lub {α : Type*} [LinearOrder α]
    (hcomplete : ∀ s : Set α, s.Nonempty → BddAbove s → ∃ a, IsLUB s a)
    {B : Set α} (hne : B.Nonempty) (hbd : BddBelow B) :
    ∃ β, IsLUB (lowerBounds B) β ∧ IsGLB B β := by
  have hLne : (lowerBounds B).Nonempty := hbd
  obtain ⟨b0, hb0⟩ := hne
  have hBA : BddAbove (lowerBounds B) := ⟨b0, fun ℓ hℓ => hℓ hb0⟩
  obtain ⟨β, hβ⟩ := hcomplete (lowerBounds B) hLne hBA
  rcases hβ with ⟨hβ_ub, hβ_least⟩
  have hlow : β ∈ lowerBounds B := by
    intro x hx
    exact hβ_least (fun ℓ hℓ => hℓ hx)
  exact ⟨β, ⟨hβ_ub, hβ_least⟩, ⟨hlow, hβ_ub⟩⟩

/-- ℝ 满足定理 4.12 的假设：非空有上界集的上确界由 `sSup` 给出。 -/
example {B : Set ℝ} (hne : B.Nonempty) (hbd : BddBelow B) : ∃ β, IsGLB B β := by
  obtain ⟨β, -, hglb⟩ :=
    glb_from_lub (fun s hs hb => ⟨sSup s, Real.isLUB_sSup hs hb⟩) hne hbd
  exact ⟨β, hglb⟩

/-- 定理 4.13，把原书的填空补完：最大下界性推出最小上界性，
    上确界等于全体上界之集的下确界。 -/
theorem lub_from_glb {α : Type*} [LinearOrder α]
    (hcomplete : ∀ s : Set α, s.Nonempty → BddBelow s → ∃ a, IsGLB s a)
    {B : Set α} (hne : B.Nonempty) (hbd : BddAbove B) :
    ∃ β, IsGLB (upperBounds B) β ∧ IsLUB B β := by
  have hUne : (upperBounds B).Nonempty := hbd
  obtain ⟨b0, hb0⟩ := hne
  have hBB : BddBelow (upperBounds B) := ⟨b0, fun u hu => hu hb0⟩
  obtain ⟨β, hβ⟩ := hcomplete (upperBounds B) hUne hBB
  rcases hβ with ⟨hβ_lb, hβ_great⟩
  have hup : β ∈ upperBounds B := by
    intro x hx
    exact hβ_great (fun u hu => hu hx)
  exact ⟨β, ⟨hβ_lb, hβ_great⟩, ⟨hup, hβ_lb⟩⟩

end Realanalysis.Ch03
