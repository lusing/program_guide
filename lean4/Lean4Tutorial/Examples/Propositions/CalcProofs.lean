/-
文件: 05_propositions/calc_proofs.lean
描述: Lean 4 calc 计算证明
编译: lake build Lean4Tutorial.Examples.Propositions.CalcProofs
-/

namespace Lean4Tutorial.Examples.Propositions.CalcProofs

/-! # calc 证明模式简介 -/

-- calc 是 Lean 中用于链式计算证明的特殊语法
-- 它可以用来证明等式、不等式等关系的链式传递
-- 格式：
--   calc
--     表达式1 = 表达式2 := 证明1
--     _ = 表达式3 := 证明2
--     ...
--     _ = 表达式n := 证明n-1

/-! # 基本的等式 calc 证明 -/

-- 一个简单的算术等式证明
theorem calc_simple : (2 + 3) * 4 = 5 * 4 := by
  calc
    (2 + 3) * 4 = 5 * 4 := by rw [show (2 + 3) = 5 by rfl]

-- 更简洁的写法
theorem calc_simple' : (2 + 3) * 4 = 20 := by
  calc
    (2 + 3) * 4
      = 5 * 4 := by rfl
    _ = 20 := by rfl

-- 也可以用 term mode 写
theorem calc_term : (2 + 3) * 4 = 20 :=
  calc
    (2 + 3) * 4
      = 5 * 4 := by rfl
    _ = 20 := by rfl

/-! # 多步 calc 证明 -/

-- 代数恒等式的证明
theorem algebra1 (a b c : Nat) : a + b + c = c + b + a := by
  calc
    a + b + c
      = (a + b) + c := by rfl
    _ = a + (b + c) := by omega
    _ = a + (c + b) := by rw [add_comm b c]
    _ = (a + c) + b := by omega
    _ = (c + a) + b := by rw [add_comm a c]
    _ = c + a + b := by rfl
    _ = c + (a + b) := by omega
    _ = c + (b + a) := by rw [add_comm a b]
    _ = c + b + a := by rfl

-- 使用 ring 可以一步证明，但这里展示 calc 的用法

/-! # 不等式的 calc 证明 -/

-- calc 也可以用于不等式
theorem calc_ineq (a b c : Nat) (h1 : a ≤ b) (h2 : b ≤ c) : a ≤ c := by
  calc
    a ≤ b := h1
    _ ≤ c := h2

-- 更复杂的不等式
theorem calc_ineq2 (a b c d : Nat) (h1 : a ≤ b) (h2 : c ≤ d) :
  a + c ≤ b + d := by
  calc
    a + c
      ≤ b + c := by linarith
    _ ≤ b + d := by linarith

-- 混合等式和不等式
theorem calc_mixed (a b c : Nat) (h1 : a = b) (h2 : b ≤ c) : a ≤ c := by
  calc
    a = b := h1
    _ ≤ c := h2

/-! # 自然数性质的证明 -/

-- 证明 n^2 = n * n
theorem square_eq_mul (n : Nat) : n ^ 2 = n * n := by
  calc
    n ^ 2
      = n ^ 1 * n := by rw [pow_succ]
    _ = (n ^ 0 * n) * n := by rw [pow_succ]
    _ = (1 * n) * n := by rw [pow_zero]
    _ = n * n := by simp

-- 证明 (a + b)^2 = a^2 + 2*a*b + b^2
theorem square_sum (a b : Nat) : (a + b) ^ 2 = a ^ 2 + 2 * a * b + b ^ 2 := by
  calc
    (a + b) ^ 2
      = (a + b) * (a + b) := by rw [square_eq_mul]
    _ = a * (a + b) + b * (a + b) := by rw [add_mul]
    _ = a * a + a * b + b * (a + b) := by rw [mul_add]
    _ = a * a + a * b + (b * a + b * b) := by rw [mul_add]
    _ = a * a + a * b + b * a + b * b := by omega
    _ = a * a + a * b + a * b + b * b := by rw [mul_comm b a]
    _ = a * a + 2 * (a * b) + b * b := by ring_nf
    _ = a ^ 2 + 2 * a * b + b ^ 2 := by
      rw [square_eq_mul a, square_eq_mul b] <;> ring

/-! # 使用 calc 证明传递性 -/

-- 小于关系的传递性
theorem lt_trans' (a b c : Nat) (h1 : a < b) (h2 : b < c) : a < c := by
  calc
    a < b := h1
    _ < c := h2

-- 小于等于的传递性
theorem le_trans' (a b c : Nat) (h1 : a ≤ b) (h2 : b ≤ c) : a ≤ c := by
  calc
    a ≤ b := h1
    _ ≤ c := h2

-- 等价关系的传递性
theorem iff_trans' (P Q R : Prop) (h1 : P ↔ Q) (h2 : Q ↔ R) : P ↔ R := by
  calc
    P ↔ Q := h1
    _ ↔ R := h2

/-! # calc 与归纳法结合 -/

-- 证明前 n 个自然数的和公式
-- 1 + 2 + ... + n = n * (n + 1) / 2
-- 因为自然数除法的问题，我们用乘法形式表述

def sum_to (n : Nat) : Nat :=
  match n with
  | 0 => 0
  | k + 1 => sum_to k + (k + 1)

theorem sum_formula : ∀ n : Nat, 2 * sum_to n = n * (n + 1) := by
  intro n
  induction n with
  | zero =>
    calc
      2 * sum_to 0
        = 2 * 0 := by rfl
      _ = 0 := by rfl
      _ = 0 * (0 + 1) := by rfl
  | succ n ih =>
    calc
      2 * sum_to (n + 1)
        = 2 * (sum_to n + (n + 1)) := by rfl
      _ = 2 * sum_to n + 2 * (n + 1) := by ring
      _ = n * (n + 1) + 2 * (n + 1) := by rw [ih]
      _ = (n + 2) * (n + 1) := by ring
      _ = (n + 1) * (n + 2) := by rw [mul_comm]
      _ = (n + 1) * ((n + 1) + 1) := by ring

/-! # calc 的其他关系 -/

-- calc 可以用于任何传递的关系
-- 例如：子集关系、整除关系等

-- 整除关系的传递性
theorem dvd_trans (a b c : Nat) (h1 : a ∣ b) (h2 : b ∣ c) : a ∣ c :=
  dvd_trans h1 h2

theorem calc_dvd (a b c : Nat) (h1 : a ∣ b) (h2 : b ∣ c) : a ∣ c := by
  calc
    a ∣ b := h1
    _ ∣ c := h2

/-! # calc 中的不同关系 -/

-- calc 可以在一个证明中使用不同的关系
-- 只要关系之间有适当的转换规则

-- 例如：a = b 且 b ≤ c 可以推出 a ≤ c
theorem eq_le (a b c : Nat) (h1 : a = b) (h2 : b ≤ c) : a ≤ c := by
  calc
    a = b := h1
    _ ≤ c := h2

-- a < b 蕴含 a ≤ b
theorem lt_imp_le (a b : Nat) (h : a < b) : a ≤ b :=
  Nat.lt_succ_iff.mp (Nat.succ_le_succ_iff.mpr h)

/-! # 列表等式的 calc 证明 -/

-- 列表操作的等式证明
theorem list_append_nil {α : Type} (xs : List α) : xs ++ [] = xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    calc
      (x :: xs) ++ []
        = x :: (xs ++ []) := by rfl
      _ = x :: xs := by rw [ih]

theorem list_append_assoc {α : Type} (xs ys zs : List α) :
  (xs ++ ys) ++ zs = xs ++ (ys ++ zs) := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    calc
      ((x :: xs) ++ ys) ++ zs
        = (x :: (xs ++ ys)) ++ zs := by rfl
      _ = x :: ((xs ++ ys) ++ zs) := by rfl
      _ = x :: (xs ++ (ys ++ zs)) := by rw [ih]
      _ = (x :: xs) ++ (ys ++ zs) := by rfl

/-! # calc 的反向证明 -/

-- 有时候从目标往回证更方便
-- 可以使用对称的等式

theorem reverse_calc (a b c : Nat) (h1 : a = b) (h2 : c = b) : a = c := by
  calc
    a = b := h1
    _ = c := h2.symm

/-! # 使用 calc 证明代数恒等式 -/

-- 平方差公式
theorem square_diff (a b : Nat) (h : a ≥ b) :
  a ^ 2 - b ^ 2 = (a + b) * (a - b) := by
  have h1 : ∃ k, a = b + k := by
    refine' ⟨a - b, _⟩
    omega
  rcases h1 with ⟨k, rfl⟩
  calc
    (b + k) ^ 2 - b ^ 2
      = ((b + k) * (b + k)) - b ^ 2 := by rw [square_eq_mul]
    _ = (b * b + b * k + k * b + k * k) - b ^ 2 := by ring
    _ = (b ^ 2 + 2 * b * k + k ^ 2) - b ^ 2 := by
      rw [square_eq_mul b, square_eq_mul k] <;> ring
    _ = 2 * b * k + k ^ 2 := by omega
    _ = k * (2 * b + k) := by ring
    _ = (b + k + b) * k := by ring
    _ = (b + k + b) * ((b + k) - b) := by omega
    _ = ((b + k) + b) * ((b + k) - b) := by rw [add_comm]

/-! # calc 与 ring/simp 等战术结合 -/

-- 在 calc 的每一步中，可以使用各种战术
theorem complex_calc (a b c d : Nat) :
  (a + b) * (c + d) = a * c + a * d + b * c + b * d := by
  calc
    (a + b) * (c + d)
      = a * (c + d) + b * (c + d) := by rw [add_mul]
    _ = a * c + a * d + b * (c + d) := by rw [mul_add]
    _ = a * c + a * d + (b * c + b * d) := by rw [mul_add]
    _ = a * c + a * d + b * c + b * d := by omega

/-! # 总结 -/

-- calc 证明模式的优点：
-- 1. 清晰易读：每一步的变换都很明确
-- 2. 易于调试：如果证明失败，可以定位到具体哪一步
-- 3. 结构化：展示了证明的推理过程
--
-- 适用场景：
-- - 链式等式证明
-- - 链式不等式证明
-- - 任何传递关系的链式推导
-- - 代数恒等式的逐步推导

end Lean4Tutorial.Examples.Propositions.CalcProofs
