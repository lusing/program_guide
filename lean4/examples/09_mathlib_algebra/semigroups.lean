/-
文件: 09_mathlib_algebra/semigroups.lean
描述: 半群 Semigroup - 结合性二元运算
编译: lake build Lean4Tutorial.Examples.MathlibAlgebra.Semigroups
依赖: Mathlib.Algebra.Group.Basic
-/

import Mathlib.Algebra.Group.Basic

namespace Lean4Tutorial.Examples.MathlibAlgebra.Semigroups

/-! # 半群（Semigroup） -/

-- 半群是具有一个结合二元运算的代数结构
-- 在 Mathlib 中，半群有两种表示：
--   MulSemigroup：乘法半群（用 * 表示运算）
--   AddSemigroup：加法半群（用 + 表示运算）

/-! ## 乘法半群 MulSemigroup -/

-- MulSemigroup G 表示类型 G 上有一个乘法运算 *，满足结合律
-- class MulSemigroup G extends Mul G where
--   mul_assoc : ∀ a b c : G, (a * b) * c = a * (b * c)

-- 自然数乘法构成半群
#check (Nat.mul_assoc : ∀ a b c : ℕ, (a * b) * c = a * (b * c))

-- 整数乘法构成半群
#check (Int.mul_assoc : ∀ a b c : ℤ, (a * b) * c = a * (b * c))

-- 使用 mul_assoc 定理
theorem nat_mul_assoc_example (a b c : ℕ) : (a * b) * c = a * (b * c) := by
  exact mul_assoc a b c

/-! ## 加法半群 AddSemigroup -/

-- AddSemigroup G 表示类型 G 上有一个加法运算 +，满足结合律
-- class AddSemigroup G extends Add G where
--   add_assoc : ∀ a b c : G, (a + b) + c = a + (b + c)

-- 自然数加法构成半群
#check (Nat.add_assoc : ∀ a b c : ℕ, (a + b) + c = a + (b + c))

-- 整数加法构成半群
#check (Int.add_assoc : ∀ a b c : ℤ, (a + b) + c = a + (b + c))

-- 使用 add_assoc 定理
theorem int_add_assoc_example (a b c : ℤ) : (a + b) + c = a + (b + c) := by
  exact add_assoc a b c

/-! ## 交换半群 -/

-- 交换半群：运算还满足交换律
-- MulCommSemigroup：乘法交换半群
-- AddCommSemigroup：加法交换半群

-- 自然数加法是交换的
theorem nat_add_comm (a b : ℕ) : a + b = b + a := by
  exact add_comm a b

-- 自然数乘法是交换的
theorem nat_mul_comm (a b : ℕ) : a * b = b * a := by
  exact mul_comm a b

/-! ## 半群的性质推导 -/

-- 利用结合律可以证明更多等式
theorem reassociate_example (a b c d : ℕ) :
    ((a + b) + c) + d = a + (b + (c + d)) := by
  rw [add_assoc, add_assoc]

-- 利用交换律和结合律可以重新排列
theorem rearrange_example (a b c : ℕ) :
    a + b + c = c + b + a := by
  rw [add_comm a b, add_assoc, add_comm b c, add_assoc]

/-! ## 半群同态 -/

-- 半群同态是保持半群运算的函数
-- f : G → H 是半群同态，如果 f(a * b) = f(a) * f(b)

-- 例如：Nat → Int 的嵌入是加法半群同态
theorem nat_cast_add (a b : ℕ) : (↑(a + b) : ℤ) = (↑a : ℤ) + (↑b : ℤ) := by
  exact?

/-! # 常用半群实例 -/

-- 列表的 append 操作构成半群（以 ++ 为运算）
#check (List.append_assoc : ∀ (l₁ l₂ l₃ : List ℕ), (l₁ ++ l₂) ++ l₃ = l₁ ++ (l₂ ++ l₃))

-- 字符串拼接构成半群
theorem string_append_assoc (s₁ s₂ s₃ : String) :
    (s₁ ++ s₂) ++ s₃ = s₁ ++ (s₂ ++ s₃) := by
  simp

/-! ## 使用 simp 简化半群表达式 -/

-- simp 可以自动使用结合律、交换律等进行化简
example (a b c : ℕ) : a + (b + c) = (a + b) + c := by
  simp [add_assoc]

example (a b c : ℕ) : a * b * c = c * b * a := by
  simp [mul_comm, mul_left_comm, mul_assoc]

end Lean4Tutorial.Examples.MathlibAlgebra.Semigroups
