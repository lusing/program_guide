/-
文件: 06_tactics/simp_norm_num.lean
描述: Lean 4 simp 和 norm_num 战术
编译: lake build Lean4Tutorial.Examples.Tactics.SimpNormNum
-/

namespace Lean4Tutorial.Examples.Tactics.SimpNormNum

/-! # simp 战术简介 -/

-- simp 是 Lean 中最常用的战术之一
-- 它使用一组"简化引理"（simp lemmas）来自动简化目标
-- simp 会递归地应用简化规则，直到无法继续简化为止

/-! # simp 的基本用法 -/

-- 简化自然数表达式
theorem simp_nat1 : 2 + 3 = 5 := by simp

theorem simp_nat2 : ∀ n : Nat, n + 0 = n := by
  intro n
  simp

-- 简化列表表达式
theorem simp_list1 : [1, 2, 3].length = 3 := by simp

theorem simp_list2 : [1, 2] ++ [3] = [1, 2, 3] := by simp

-- 简化布尔表达式
theorem simp_bool1 : true && false = false := by simp

theorem simp_bool2 : ∀ b : Bool, b && true = b := by
  intro b
  simp

-- 简化 Option
theorem simp_option : (some 5).isSome = true := by simp

/-! # simp 的参数 -/

-- simp 可以使用特定的引理
-- simp [lemma1, lemma2, ...]

-- 自定义引理，标记为 simp
@[simp]
theorem double_zero : 2 * 0 = 0 := by simp

@[simp]
theorem double_add (n : Nat) : 2 * (n + 1) = 2 * n + 2 := by
  ring

-- 现在 simp 会自动使用这些引理
theorem use_custom_simp : 2 * 3 = 6 := by simp

-- 也可以在 simp 中手动指定引理
theorem add_simp_lemma : 2 * 3 = 6 := by
  simp [Nat.mul_succ, Nat.zero_mul]

/-! # simp at -/

-- simp 也可以简化假设
theorem simp_at (n : Nat) (h : n + 0 = 5) : n = 5 := by
  simp at h
  exact h

-- 同时简化目标和假设
theorem simp_at_all (n m : Nat) (h : n + 0 = m + 0) : n = m := by
  simp at h ⊢
  exact h

/-! # simp only -/

-- simp only 只使用指定的引理，不使用默认的 simp 集合
-- 这对于控制证明的范围很有用

theorem simp_only1 : [1, 2, 3].length = 3 := by
  simp only [List.length]
  <;> decide

-- 可以禁用某些 simp 引理
theorem simp_without (n : Nat) : n + 0 = n := by
  -- 只使用 add_zero，不使用其他 simp 引理
  simp only [Nat.add_zero]

/-! # simp 与条件重写 -/

-- simp 可以使用条件等式
-- 例如：if 语句的简化

theorem simp_if : (if true then 1 else 2) = 1 := by simp

theorem simp_if2 (n : Nat) : (if n = 0 then 0 else n + 1) > 0 := by
  by_cases h : n = 0
  · simp [h]
  · simp [h] <;> omega

/-! # norm_num 战术 -/

-- norm_num 用于数值计算
-- 它可以计算具体的数值表达式（自然数、整数、有理数等）

theorem norm_num1 : 1234 + 5678 = 6912 := by norm_num

theorem norm_num2 : 123 * 456 = 56088 := by norm_num

theorem norm_num3 : 2 ^ 20 = 1048576 := by norm_num

theorem norm_num4 : 1000000 / 7 = 142857 := by norm_num

theorem norm_num5 : 999 * 999 = 998001 := by norm_num

-- norm_num 也可以处理不等式
theorem norm_num6 : 1234 < 5678 := by norm_num

theorem norm_num7 : 2 ^ 10 > 1000 := by norm_num

/-! # decide 战术 -/

-- decide 可以证明可判定的命题
-- 对于具体的数值，decide 很有用

theorem decide1 : 2 + 2 = 4 := by decide

theorem decide2 : 3 ≤ 5 := by decide

theorem decide3 : [1, 2, 3] ≠ [] := by decide

theorem decide4 : "hello".length = 5 := by decide

-- decide 也可以处理更复杂的可判定命题
theorem decide5 : ∃ n < 10, n * n = 25 := by decide

/-! # simp vs norm_num vs decide -/

-- simp：使用简化引理进行重写，可以处理含变量的表达式
-- norm_num：专门用于数值计算，处理具体的数值
-- decide：证明可判定的命题，可以处理具体的数值和有限结构

-- 都能处理的情况：
theorem all_three : 2 + 3 = 5 := by
  -- simp, norm_num, decide 都可以
  simp

-- norm_num 适合大数计算
theorem big_num : 2 ^ 30 = 1073741824 := by norm_num

-- decide 适合有限结构的判定
theorem finite_decidable :
  (List.range 5).all (· < 10) := by decide

/-! # 常见的 simp 引理 -/

-- 加法
-- Nat.add_zero : n + 0 = n
-- Nat.zero_add : 0 + n = n
-- Nat.add_assoc : (m + n) + k = m + (n + k)
-- Nat.add_comm : m + n = n + m

-- 乘法
-- Nat.mul_zero : n * 0 = 0
-- Nat.zero_mul : 0 * n = 0
-- Nat.mul_one : n * 1 = n
-- Nat.one_mul : 1 * n = n
-- Nat.mul_comm : m * n = n * m
-- Nat.mul_assoc : (m * n) * k = m * (n * k)

-- 列表
-- List.nil_append : [] ++ xs = xs
-- List.append_nil : xs ++ [] = xs
-- List.append_assoc : (xs ++ ys) ++ zs = xs ++ (ys ++ zs)
-- List.length_nil : [].length = 0
-- List.length_cons : (x :: xs).length = xs.length + 1

-- 布尔
-- Bool.and_true : b && true = b
-- Bool.and_false : b && false = false
-- Bool.or_true : b || true = true
-- Bool.or_false : b || false = b
-- Bool.not_not : !(!b) = b

/-! # 添加自定义 simp 引理 -/

-- 使用 @[simp] 属性将定理标记为 simp 引理

-- 定义一个函数
def triple (n : Nat) : Nat := 3 * n

-- 证明它的性质并标记为 simp
@[simp]
theorem triple_zero : triple 0 = 0 := by
  rfl

@[simp]
theorem triple_succ (n : Nat) : triple (n + 1) = triple n + 3 := by
  simp [triple] <;> ring

-- 现在 simp 可以简化 triple 的调用
theorem triple_three : triple 3 = 9 := by simp

theorem triple_five : triple 5 = 15 := by simp

/-! # simp 对自定义类型的使用 -/

-- 定义一个类型
structure Point where
  x : Nat
  y : Nat
deriving Repr

-- 定义一些操作
def Point.add (p1 p2 : Point) : Point :=
  ⟨p1.x + p2.x, p1.y + p2.y⟩

def Point.zero : Point := ⟨0, 0⟩

-- 证明性质并标记为 simp
@[simp]
theorem Point.add_zero (p : Point) : p.add Point.zero = p := by
  cases p
  simp [Point.add, Point.zero]
  <;> rfl

@[simp]
theorem Point.zero_add (p : Point) : Point.zero.add p = p := by
  cases p
  simp [Point.add, Point.zero]
  <;> rfl

-- 使用 simp
theorem point_add_zero (p : Point) : p.add Point.zero = p := by simp

/-! # simp 与归纳证明 -/

-- 在归纳证明中，simp 常用于简化归纳步骤

theorem sum_id : ∀ n : Nat, 2 * (n * (n + 1) / 2) = n * (n + 1) := by
  intro n
  induction n with
  | zero => norm_num
  | succ n ih =>
    simp [Nat.mul_succ, Nat.add_assoc] at * <;> ring_nf at * <;> omega

/-! # simpa 战术 -/

-- simpa 是 simp + exact 的组合
-- 它先简化目标，然后用给定的证明项匹配

theorem simpa_example (n : Nat) (h : n + 0 = 5) : n = 5 := by
  simpa using h

-- simpa 也可以使用 with 来添加额外的 simp 引理
theorem simpa_with (n m : Nat) (h : n + m = m + n) : m + n = n + m := by
  simpa [add_comm] using h

/-! # dsimp 战术 -/

-- dsimp（definitional simp）只进行定义性的简化
-- 不会改变表达式的定义相等性
-- 它比 simp 更快，但功能更弱

theorem dsimp_example : (fun x : Nat => x + 1) 5 = 6 := by
  dsimp
  rfl

/-! # 总结 -/

-- simp：通用的简化战术，使用 simp 引理重写
--   - 可以处理含变量的表达式
--   - 使用 @[simp] 标记自定义引理
--   - simp [lem1, lem2] 添加额外引理
--   - simp only [lem1, lem2] 只使用指定引理
--   - simp at h 简化假设
--
-- norm_num：数值计算战术
--   - 处理具体的数值表达式
--   - 支持加减乘除、幂等运算
--   - 支持不等式
--
-- decide：可判定命题证明
--   - 证明具体的、可判定的命题
--   - 适用于有限结构
--
-- simpa：simp + exact 的组合
-- dsimp：定义性简化

end Lean4Tutorial.Examples.Tactics.SimpNormNum
