import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.Order.Archimedean.Basic
import Mathlib.Data.Int.Order.Units
import Mathlib.Tactic

/-!
# 第 04 章 实数域（上）：域公理

对应原书第 5 章前半：域公理（定义 5.1）、封闭性的非平凡性（例 5.2）、
有序域公理（定义 5.3），以及“只用公理就能推出”的基本性质。
有限域 ℤ₅（原书例 5.2 的 mod 5 构造）在 mathlib 中是 `ZMod 5`。
-/

namespace Realanalysis.Ch04

/-- ℤ 不是域：2 没有整数乘法逆元（原书例 5.2 的脚注修正版：
    除 ±1 外的元素都没有逆元）。 -/
example : ¬ ∃ z : ℤ, 2 * z = 1 := by omega

/-- ℚ 的封闭性验证（原书例 5.2）：每个有理数都是整数之比，
    于是和与积仍落在 ℚ 里。num/den 给出规范代表。 -/
example (x : ℚ) : ∃ a b : ℤ, b ≠ 0 ∧ x = (a : ℚ) / b :=
  ⟨x.num, x.den, by exact_mod_cast x.den_nz, (Rat.num_div_den x).symm⟩

/-- 例 5.2 的加法公式：(a/b) + (c/d) = (ad + bc)/(bd)。 -/
theorem rat_add (a b c d : ℤ) (hb : b ≠ 0) (hd : d ≠ 0) :
    (a : ℚ) / b + (c : ℚ) / d = ((a * d + b * c : ℤ) : ℚ) / (b * d) := by
  field_simp
  ring

/-- 例 5.2 的乘法公式：(a/b)·(c/d) = (ac)/(bd)。 -/
theorem rat_mul (a b c d : ℤ) (hb : b ≠ 0) (hd : d ≠ 0) :
    ((a : ℚ) / b) * ((c : ℚ) / d) = ((a * c : ℤ) : ℚ) / (b * d) := by
  field_simp
  ring

/-- 编者注的修正：整数里乘法可逆的只有 ±1。 -/
theorem int_unit_iff (z : ℤ) : (∃ w : ℤ, z * w = 1) ↔ z = 1 ∨ z = -1 := by
  constructor
  · rintro ⟨w, hw⟩
    have hu : IsUnit z := isUnit_of_mul_eq_one z w hw
    rw [Int.isUnit_iff_abs_eq] at hu
    rcases le_total (0 : ℤ) z with hz | hz
    · left
      rwa [abs_of_nonneg hz] at hu
    · right
      rw [abs_of_nonpos hz] at hu
      linarith
  · rintro (rfl | rfl)
    · exact ⟨1, by norm_num⟩
    · exact ⟨-1, by ring⟩

/-- ℕ 不是域：1 没有加法逆元。 -/
example : ¬ ∃ n : ℕ, 1 + n = 0 := by omega

/-- 有限域 ℤ₅：mod 5 下 2 + 3 = 0（封闭性的怪异但合法的实现）。 -/
example : (2 + 3 : ZMod 5) = 0 := by decide

/-- ℤ₅ 里每个非零元都有逆元：2 · 3 = 1。 -/
example : (2 * 3 : ZMod 5) = 1 := by decide

/-- ℤ₅ 确实是域：非零元都可逆。有限域上可直接判定。 -/
example : ∀ x : ZMod 5, x ≠ 0 → ∃ y : ZMod 5, x * y = 1 := by decide

/-- 只用域公理就能证明的基本事实（mathlib 中对应定理）：
    0·x = 0、(-1)·x = -x、-(-x) = x。 -/
example (x : ℝ) : 0 * x = 0 := zero_mul x
example (x : ℝ) : (-1) * x = -x := neg_one_mul x
example (x : ℝ) : -(-x) = x := neg_neg x

/-- 乘法逆的唯一性：xy = 1 蕴含 y = 1/x。 -/
example (x y : ℝ) (hx : x ≠ 0) (h : x * y = 1) : y = 1 / x := by
  field_simp
  linarith

/-- 有序域公理 O2 的直接推论：平方非负。 -/
example (x : ℝ) : 0 ≤ x ^ 2 := sq_nonneg x

/-- 有序域里 0 < 1（由 1 = 1² 非负且 1 ≠ 0）。 -/
example : (0 : ℝ) < 1 := zero_lt_one

/-- 原书列举的有序域性质：x > 0 且 y < z 蕴含 xy < xz。 -/
example (x y z : ℝ) (hx : 0 < x) (h : y < z) : x * y < x * z :=
  mul_lt_mul_of_pos_left h hx

/-- 0 < x < y 蕴含 0 < 1/y < 1/x（正数取倒数反转顺序）。 -/
example (x y : ℝ) (hx : 0 < x) (h : x < y) : 1 / y < 1 / x :=
  one_div_lt_one_div_of_lt hx h

/-- 中点严格落在两数之间——第 05 章稠密性定理的最简形式。 -/
example (a b : ℝ) (h : a < b) : a < (a + b) / 2 ∧ (a + b) / 2 < b :=
  ⟨by linarith, by linarith⟩

/-- 定义 5.4 的两半：ℝ 包含 ℚ，并且每个非空有上界子集都有上确界。
    ℚ 本身是有序域，但第 03 章已经证明它没有最小上界性。 -/
example (q : ℚ) : ∃ x : ℝ, x = (q : ℝ) := ⟨(q : ℝ), rfl⟩

example (s : Set ℝ) (hne : s.Nonempty) (hb : BddAbove s) :
    ∃ a, IsLUB s a :=
  ⟨sSup s, Real.isLUB_sSup hne hb⟩

end Realanalysis.Ch04
