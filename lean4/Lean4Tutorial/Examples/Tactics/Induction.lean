/-
文件: 06_tactics/induction.lean
描述: Lean 4 归纳证明（加法性质）
编译: lake build Lean4Tutorial.Examples.Tactics.Induction
-/

namespace Lean4Tutorial.Examples.Tactics.Induction

/-! # 归纳法简介 -/

-- 归纳法是证明关于自然数（或其他归纳类型）的命题的基本方法
-- 数学归纳法原理：
-- 如果 P(0) 成立，且 P(n) → P(n+1) 对所有 n 成立
-- 那么 P(n) 对所有自然数 n 成立
--
-- 在 Lean 中，使用 induction 战术进行归纳证明

/-! # induction 战术 -/

-- 证明：对于所有自然数 n，0 + n = n
theorem zero_add : ∀ n : Nat, 0 + n = n := by
  intro n
  induction n with
  | zero =>
    -- 基础情况：n = 0
    -- 目标：0 + 0 = 0
    rfl
  | succ n ih =>
    -- 归纳步骤：假设对于 n 成立（ih 是归纳假设）
    -- 证明对于 n + 1 成立
    -- 目标：0 + (n + 1) = n + 1
    simp [Nat.add_succ, ih]
    <;> rfl

-- 也可以直接对参数进行归纳
theorem zero_add' : ∀ n : Nat, 0 + n = n
  | 0 => by rfl
  | n + 1 => by
    simp [Nat.add_succ, zero_add' n]
    <;> rfl

/-! # 加法性质 -/

-- 证明：n + 0 = n（这是定义，因为加法是对第二个参数递归的）
theorem add_zero (n : Nat) : n + 0 = n := by
  rfl

-- 证明加法交换律
theorem add_comm : ∀ m n : Nat, m + n = n + m := by
  intro m n
  induction m with
  | zero =>
    -- 0 + n = n + 0
    rw [zero_add n, add_zero n]
  | succ m ih =>
    -- (m + 1) + n = n + (m + 1)
    simp [Nat.add_succ, ih]
    <;> rfl

-- 证明加法结合律
theorem add_assoc : ∀ m n k : Nat, (m + n) + k = m + (n + k) := by
  intro m n k
  induction m with
  | zero =>
    -- (0 + n) + k = 0 + (n + k)
    rfl
  | succ m ih =>
    -- (m + 1 + n) + k = m + 1 + (n + k)
    simp [Nat.add_succ, ih] <;> rfl

/-! # 乘法性质 -/

-- 证明：n * 0 = 0
theorem mul_zero (n : Nat) : n * 0 = 0 := by
  induction n with
  | zero => rfl
  | succ n ih => simp [Nat.mul_succ, ih] <;> rfl

-- 证明：n * 1 = n
theorem mul_one (n : Nat) : n * 1 = n := by
  induction n with
  | zero => rfl
  | succ n ih => simp [Nat.mul_succ, ih] <;> rfl

-- 证明乘法分配律（左分配）
theorem left_distrib : ∀ m n k : Nat, m * (n + k) = m * n + m * k := by
  intro m n k
  induction m with
  | zero =>
    simp [Nat.zero_mul]
  | succ m ih =>
    simp [Nat.mul_succ, ih, add_assoc] <;> ring_nf <;> rfl

-- 证明乘法交换律
theorem mul_comm : ∀ m n : Nat, m * n = n * m := by
  intro m n
  induction m with
  | zero =>
    simp [mul_zero]
    <;> rfl
  | succ m ih =>
    simp [Nat.mul_succ, ih, left_distrib, mul_one]
    <;> ring_nf <;> rfl

/-! # 幂运算性质 -/

-- 证明：a^(m + n) = a^m * a^n
theorem pow_add (a m n : Nat) : a ^ (m + n) = a ^ m * a ^ n := by
  induction m with
  | zero =>
    simp [pow_zero]
    <;> rfl
  | succ m ih =>
    simp [pow_succ, ih, mul_assoc] <;> rfl

-- 证明：(a^m)^n = a^(m*n)
theorem pow_mul (a m n : Nat) : (a ^ m) ^ n = a ^ (m * n) := by
  induction n with
  | zero =>
    simp [pow_zero, mul_zero]
  | succ n ih =>
    rw [pow_succ, ih, pow_add, mul_comm]
    <;> rfl

/-! # 强归纳法（完全归纳法）-/

-- 强归纳法：证明 P(n) 时，可以假设对于所有 k < n，P(k) 都成立
-- 使用 induction ... using Nat.strong_induction_on

-- 示例：证明每个大于 1 的自然数都有素因子
-- （简化版本，证明每个 n ≥ 2 有一个因子 ≥ 2）

theorem has_factor_ge_two : ∀ n : Nat, n ≥ 2 → ∃ d : Nat, d ≥ 2 ∧ d ∣ n := by
  intro n
  induction n using Nat.strong_induction_on with
  | h n ih =>
    intro hn
    by_cases h_prime : (∀ k : Nat, 2 ≤ k → k < n → ¬(k ∣ n))
    · -- n 没有 2 到 n-1 之间的因子，那么 n 自己就是因子
      exact ⟨n, hn, dvd_refl n⟩
    · -- 存在 k 使得 2 ≤ k < n 且 k ∣ n
      push_neg at h_prime
      rcases h_prime with ⟨k, hk1, hk2, hk3⟩
      exact ⟨k, hk1, hk3⟩

/-! # 对归纳类型的归纳 -/

-- 归纳法不仅适用于自然数，也适用于任何归纳类型
-- 例如列表、树等

-- 列表的归纳证明
theorem list_append_nil {α : Type} : ∀ xs : List α, xs ++ [] = xs := by
  intro xs
  induction xs with
  | nil =>
    rfl
  | cons x xs ih =>
    simp [List.cons_append, ih]
    <;> rfl

theorem list_append_assoc {α : Type} : ∀ xs ys zs : List α,
  (xs ++ ys) ++ zs = xs ++ (ys ++ zs) := by
  intro xs ys zs
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    simp [List.cons_append, ih] <;> rfl

-- 列表长度与拼接的关系
theorem length_append {α : Type} : ∀ xs ys : List α,
  (xs ++ ys).length = xs.length + ys.length := by
  intro xs ys
  induction xs with
  | nil => simp
  | cons x xs ih =>
    simp [List.length_cons, ih] <;> rfl

/-! # 归纳假设的使用 -/

-- 有时候需要选择合适的归纳变量
-- 例如证明 m + n = n + m 时，对 m 归纳还是对 n 归纳

-- 另一个例子：证明 n * m = m * n
-- 我们选择对 n 归纳

theorem mul_comm' (m n : Nat) : m * n = n * m := by
  induction n with
  | zero =>
    simp [mul_zero]
    <;> rfl
  | succ n ih =>
    simp [Nat.mul_succ, ih, left_distrib, mul_one]
    <;> ring_nf <;> rfl

/-! # 嵌套归纳 -/

-- 有时候需要嵌套归纳（双重归纳）
-- 例如证明加法交换律时，也可以用双重归纳

-- 另一个例子：证明 m * (n + k) = m * n + m * k
-- 我们已经对 m 归纳了，也可以对 n 归纳

theorem right_distrib (m n k : Nat) : (m + n) * k = m * k + n * k := by
  induction k with
  | zero =>
    simp [mul_zero]
  | succ k ih =>
    simp [Nat.mul_succ, ih, add_assoc] <;> ring_nf <;> rfl

/-! # 归纳法的另一种形式：cases -/

-- cases 也是一种归纳，但不生成归纳假设
-- 它只是分情况讨论

theorem cases_example (n : Nat) : n = 0 ∨ n > 0 := by
  cases n with
  | zero =>
    left
    rfl
  | succ n =>
    right
    simp

-- 但 cases 不能替代 induction 来证明需要归纳的命题
-- 例如下面的"证明"是不行的：
-- theorem bad_proof : ∀ n, n = 0 := by
--   intro n
--   cases n with
--   | zero => rfl
--   | succ n => sorry  -- 这里没有归纳假设，无法继续

/-! # 相互归纳 -/

-- 对于互递归定义的类型或函数，需要用互归纳

-- 示例：判断偶数和奇数的互递归函数
mutual
  def isEven : Nat → Bool
    | 0 => true
    | n + 1 => isOdd n

  def isOdd : Nat → Bool
    | 0 => false
    | n + 1 => isEven n
end

-- 证明：isEven n ↔ ¬ isOdd n
theorem even_iff_not_odd : ∀ n : Nat, isEven n ↔ ¬ isOdd n := by
  intro n
  induction n with
  | zero =>
    simp [isEven, isOdd]
    <;> tauto
  | succ n ih =>
    simp [isEven, isOdd, ih] <;> tauto

/-! # 归纳法的常见模式 -/

-- 1. 对哪个变量归纳？
--    通常选择递归定义中的"主参数"
--    例如加法对第二个参数递归，证明时对第二个参数归纳更方便

-- 2. 需要推广（generalize）吗？
--    有时候需要先推广命题才能进行归纳
--    例如证明 ∀ m, m + n = n + m 时对 n 归纳

-- 3. 归纳假设不够强怎么办？
--    可以使用强归纳法
--    或者先证明一个更强的命题

/-! # 一个完整的例子：求和公式 -/

-- 定义前 n 个数的和
def sumN (n : Nat) : Nat :=
  match n with
  | 0 => 0
  | k + 1 => sumN k + (k + 1)

-- 证明：2 * sumN n = n * (n + 1)
theorem sumN_formula : ∀ n : Nat, 2 * sumN n = n * (n + 1) := by
  intro n
  induction n with
  | zero =>
    simp [sumN]
    <;> rfl
  | succ n ih =>
    calc
      2 * sumN (n + 1)
        = 2 * (sumN n + (n + 1)) := by rfl
      _ = 2 * sumN n + 2 * (n + 1) := by ring
      _ = n * (n + 1) + 2 * (n + 1) := by rw [ih]
      _ = (n + 2) * (n + 1) := by ring
      _ = (n + 1) * (n + 2) := by rw [mul_comm]
      _ = (n + 1) * ((n + 1) + 1) := by ring

end Lean4Tutorial.Examples.Tactics.Induction
