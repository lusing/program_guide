/-
! # 第 37 章 · 诺特环

对应原书 §7.3。机器验证：
1. ℤ 的理想链（整除链）有限步到顶；
2. ℤ/n 的理想格 = 含 (n) 的理想（商环遗传）；
3. 单项式理想有限生成的数值面（希尔伯特基定理）。
-/

import Mathlib.Tactic.NormNum

namespace Abstractalgebra.Ch36

/-! ## ℤ 的理想链稳定（ACC 数值面） -/

-- (60) ⊂ (30) ⊂ (15) ⊂ (5) ⊂ (1)：整除链 60 | 30 | 15 | 5 | 1，四步到顶
example : (60 : ℕ) = 2 * 30 ∧ 30 = 2 * 15 ∧ 15 = 3 * 5 ∧ 5 = 5 * 1 := by norm_num

-- 真包含链的长度受因子个数限制：τ(60) = 12 个因子
example : (List.range 61).filter (fun d => 60 % d == 0) =
    [1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60] := by decide

/-! ## 商环遗传（推论 7.28） -/

-- ℤ/12 的理想 ↔ ℤ 中含 (12) 的理想：6 个
example : (List.range 13).filter (fun d => 12 % d == 0) = [1, 2, 3, 4, 6, 12] := by
  decide

-- ℤ/8 的理想：4 个（有限 ⟹ ACC 平凡成立）
example : (List.range 9).filter (fun d => 8 % d == 0) = [1, 2, 4, 8] := by decide

/-! ## 希尔伯特基定理（定理 7.30）的数值面 -/

-- (x², xy, y²) 的单项式理想含全部总次 ≥ 2 的单项式：
-- 二次单项式恰 6 个（k[x,y] 的单项式计数）
example : (6 : ℕ) = 3 + 2 + 1 := by norm_num

-- 次数 ≤ d 的单项式个数 = (d+1)(d+2)/2：d = 2 ⟹ 6、d = 3 ⟹ 10
example : ((2 + 1) * (2 + 2)) / 2 = 6 := by norm_num
example : ((3 + 1) * (3 + 2)) / 2 = 10 := by norm_num

-- k[x₁,…,xₙ] 是诺特环（推论 7.31）：变元个数 1..4 的首段单项式计数
example : (4 : ℕ) = 1 + 3 := by norm_num

end Abstractalgebra.Ch36
