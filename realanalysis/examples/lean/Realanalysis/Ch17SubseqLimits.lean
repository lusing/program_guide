import Mathlib.Algebra.Order.Ring.Abs
import Mathlib.Order.Filter.AtTopBot.Archimedean
import Mathlib.Order.Filter.AtTopBot.Field
import Mathlib.Order.Filter.AtTopBot.Ring
import Mathlib.Order.LiminfLimsup
import Mathlib.Topology.Order.LiminfLimsup
import Realanalysis.Ch15Subsequences
import Mathlib.Tactic

/-!
# 第 17 章 子序列极限

对应原书第 17 章：发散到正无穷和负无穷、上极限与下极限。
交替序列的上极限是 1、下极限是 -1；常数序列两者都等于极限。
-/

namespace Realanalysis.Ch17

open Filter Realanalysis.Ch15

/-! ## 17.1–17.2 发散到无穷 -/

/-- 例 17.2：n² 发散到 +∞。平方是 n 和自己相乘。 -/
theorem squares_to_top : Tendsto (fun n : ℕ => (n : ℝ) ^ 2) atTop atTop := by
  simpa [pow_two] using
    (tendsto_natCast_atTop_atTop (R := ℝ)).atTop_mul_atTop₀
      (tendsto_natCast_atTop_atTop (R := ℝ))

/-- 例 17.2：-5n 发散到 -∞。 -/
theorem neg_five_to_bot : Tendsto (fun n : ℕ => (-5 : ℝ) * n) atTop atBot :=
  tendsto_natCast_atTop_atTop.const_mul_atTop_of_neg (by norm_num : (-5 : ℝ) < 0)

/-- (-1)^n 的绝对值恒为 1，所以它不会变得任意大。 -/
theorem alt_abs : ∀ n : ℕ, |(-1 : ℝ) ^ n| = 1 :=
  abs_neg_one_pow

theorem odd_pow (k : ℕ) : (-1 : ℝ) ^ (2 * k + 1) = -1 := by
  rw [pow_add, pow_one, pow_mul]
  norm_num

theorem even_pow (k : ℕ) : (-1 : ℝ) ^ (2 * k) = 1 := by
  rw [pow_mul]
  norm_num

theorem alt_not_top : ¬ Tendsto (fun n : ℕ => (-1 : ℝ) ^ n) atTop atTop := by
  intro h
  have heq : (fun k : ℕ => (-1 : ℝ) ^ (2 * k + 1)) = fun _ => (-1 : ℝ) := by
    ext k
    exact odd_pow k
  have hconst : Tendsto (fun _ : ℕ => (-1 : ℝ)) atTop atTop := by
    rw [← heq]
    exact h.comp odd_strictMono.tendsto_atTop
  have h0 : ∀ᶠ _ : ℕ in atTop, (0 : ℝ) ≤ -1 := hconst (mem_atTop 0)
  obtain ⟨_, hn⟩ := h0.exists
  linarith

/-! ## 17.4–17.6 上极限与下极限 -/

/-- 常数序列的每个子序列极限都是 1，所以上极限和下极限都是 1。 -/
theorem const_limsup : limsup (fun _ : ℕ => (1 : ℝ)) atTop = 1 :=
  tendsto_const_nhds.limsup_eq

theorem const_liminf : liminf (fun _ : ℕ => (1 : ℝ)) atTop = 1 :=
  tendsto_const_nhds.liminf_eq

/-- 定理 17.6 的一个方向：收敛到有限极限时，上极限和下极限都等于它。 -/
theorem limsup_liminf_of_tendsto {s : ℕ → ℝ} {a : ℝ} (h : Tendsto s atTop (nhds a)) :
    limsup s atTop = a ∧ liminf s atTop = a :=
  ⟨h.limsup_eq, h.liminf_eq⟩

/-- (-1)^n 不超过 1，也不低于 -1。 -/
theorem alt_le_one : ∀ n : ℕ, (-1 : ℝ) ^ n ≤ 1 := by
  intro n
  calc
    (-1 : ℝ) ^ n ≤ |(-1 : ℝ) ^ n| := le_abs_self _
    _ = 1 := abs_neg_one_pow n

theorem alt_ge_neg_one : ∀ n : ℕ, (-1 : ℝ) ≤ (-1 : ℝ) ^ n := by
  intro n
  calc
    (-1 : ℝ) = -|(-1 : ℝ) ^ n| := by rw [abs_neg_one_pow]
    _ ≤ (-1 : ℝ) ^ n := neg_abs_le _

theorem alt_bounded_above : IsBoundedUnder (· ≤ ·) atTop (fun n : ℕ => (-1 : ℝ) ^ n) :=
  ⟨1, by rw [eventually_map]; exact Eventually.of_forall alt_le_one⟩

theorem alt_bounded_below : IsBoundedUnder (· ≥ ·) atTop (fun n : ℕ => (-1 : ℝ) ^ n) :=
  ⟨-1, by rw [eventually_map]; exact Eventually.of_forall alt_ge_neg_one⟩

theorem alt_cobounded_above : IsCoboundedUnder (· ≤ ·) atTop (fun n : ℕ => (-1 : ℝ) ^ n) := by
  refine ⟨-1, ?_⟩
  intro a ha
  rw [eventually_map] at ha
  obtain ⟨N, hN⟩ := eventually_atTop.1 ha
  have hidx : N ≤ 2 * N := Nat.le_mul_of_pos_left N (by decide : 0 < 2)
  have hterm : (-1 : ℝ) ^ (2 * N) ≤ a := hN _ hidx
  rw [even_pow] at hterm
  linarith

theorem alt_cobounded_below : IsCoboundedUnder (· ≥ ·) atTop (fun n : ℕ => (-1 : ℝ) ^ n) := by
  refine ⟨1, ?_⟩
  intro a ha
  rw [eventually_map] at ha
  obtain ⟨N, hN⟩ := eventually_atTop.1 ha
  have hidx : N ≤ 2 * N + 1 := by
    exact Nat.le_trans (Nat.le_mul_of_pos_left N (by decide : 0 < 2)) (Nat.le_add_right _ 1)
  have hterm : a ≤ (-1 : ℝ) ^ (2 * N + 1) := hN _ hidx
  rw [odd_pow] at hterm
  linarith

theorem even_cobounded_above :
    IsCoboundedUnder (· ≤ ·) (atTop.map fun k : ℕ => 2 * k) (fun n : ℕ => (-1 : ℝ) ^ n) := by
  refine ⟨-1, ?_⟩
  intro a ha
  rw [eventually_map] at ha
  obtain ⟨N, hN⟩ := eventually_atTop.1 ha
  have hterm : (-1 : ℝ) ^ (2 * N) ≤ a := hN N le_rfl
  rw [even_pow] at hterm
  linarith

theorem odd_cobounded_below :
    IsCoboundedUnder (· ≥ ·) (atTop.map fun k : ℕ => 2 * k + 1) (fun n : ℕ => (-1 : ℝ) ^ n) := by
  refine ⟨1, ?_⟩
  intro a ha
  rw [eventually_map] at ha
  obtain ⟨N, hN⟩ := eventually_atTop.1 ha
  have hterm : a ≤ (-1 : ℝ) ^ (2 * N + 1) := hN N le_rfl
  rw [odd_pow] at hterm
  linarith

/-- 例 17.5：偶子序列趋于 1，所以上极限至少是 1；每一项又不超过 1。 -/
theorem alt_limsup : limsup (fun n : ℕ => (-1 : ℝ) ^ n) atTop = 1 := by
  have hsub : limsup (fun k : ℕ => (-1 : ℝ) ^ (2 * k)) atTop = 1 := even_alt.limsup_eq
  have hcomp :
      limsup ((fun n : ℕ => (-1 : ℝ) ^ n) ∘ fun k : ℕ => 2 * k) atTop ≤
        limsup (fun n : ℕ => (-1 : ℝ) ^ n) atTop :=
    even_strictMono.tendsto_atTop.limsup_comp_le_limsup
      (hvf := even_cobounded_above) (hg := alt_bounded_above)
  have hle : limsup (fun k : ℕ => (-1 : ℝ) ^ (2 * k)) atTop ≤
      limsup (fun n : ℕ => (-1 : ℝ) ^ n) atTop := by
    simpa [Function.comp_def] using hcomp
  have hge : (1 : ℝ) ≤ limsup (fun n : ℕ => (-1 : ℝ) ^ n) atTop := by
    calc
      (1 : ℝ) = limsup (fun k : ℕ => (-1 : ℝ) ^ (2 * k)) atTop := hsub.symm
      _ ≤ limsup (fun n : ℕ => (-1 : ℝ) ^ n) atTop := hle
  have hup : limsup (fun n : ℕ => (-1 : ℝ) ^ n) atTop ≤ 1 :=
    limsup_le_of_le (hf := alt_cobounded_above) (h := Eventually.of_forall alt_le_one)
  exact le_antisymm hup hge

/-- 奇子序列趋于 -1，所以下极限至多是 -1；每一项又不低于 -1。 -/
theorem alt_liminf : liminf (fun n : ℕ => (-1 : ℝ) ^ n) atTop = -1 := by
  have hsub : liminf (fun k : ℕ => (-1 : ℝ) ^ (2 * k + 1)) atTop = -1 := odd_alt.liminf_eq
  have hcomp :
      liminf (fun n : ℕ => (-1 : ℝ) ^ n) atTop ≤
        liminf ((fun n : ℕ => (-1 : ℝ) ^ n) ∘ fun k : ℕ => 2 * k + 1) atTop :=
    odd_strictMono.tendsto_atTop.liminf_le_liminf_comp
      (hvf := odd_cobounded_below) (hg := alt_bounded_below)
  have hle : liminf (fun n : ℕ => (-1 : ℝ) ^ n) atTop ≤
      liminf (fun k : ℕ => (-1 : ℝ) ^ (2 * k + 1)) atTop := by
    simpa [Function.comp_def] using hcomp
  have hle' : liminf (fun n : ℕ => (-1 : ℝ) ^ n) atTop ≤ -1 := by
    calc
      liminf (fun n : ℕ => (-1 : ℝ) ^ n) atTop ≤
          liminf (fun k : ℕ => (-1 : ℝ) ^ (2 * k + 1)) atTop := hle
      _ = -1 := hsub
  have hge : (-1 : ℝ) ≤ liminf (fun n : ℕ => (-1 : ℝ) ^ n) atTop :=
    le_liminf_of_le (hf := alt_cobounded_below) (h := Eventually.of_forall alt_ge_neg_one)
  exact le_antisymm hle' hge

/-- 定理 17.10：一项始终不大于另一项时，上极限保持次序。
    实数上还要假设左边不往正无穷逃、右边有上界；扩张实数把无穷算进上确界，就不必另写。 -/
theorem limsup_mono {s t : ℕ → ℝ} (h : ∀ n, s n ≤ t n)
    (hs : IsCoboundedUnder (· ≤ ·) atTop s) (ht : IsBoundedUnder (· ≤ ·) atTop t) :
    limsup s atTop ≤ limsup t atTop :=
  limsup_le_limsup (Eventually.of_forall h) hs ht

/-- 下极限同样保持次序。 -/
theorem liminf_mono {s t : ℕ → ℝ} (h : ∀ n, s n ≤ t n)
    (hs : IsBoundedUnder (· ≥ ·) atTop s) (ht : IsCoboundedUnder (· ≥ ·) atTop t) :
    liminf s atTop ≤ liminf t atTop :=
  liminf_le_liminf (Eventually.of_forall h) hs ht

end Realanalysis.Ch17
