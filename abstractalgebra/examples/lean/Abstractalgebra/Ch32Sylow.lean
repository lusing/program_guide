/-
! # 第 32 章 · 西罗定理

对应原书 §6.2。机器验证：
1. 西罗计数条件的候选枚举（n_p | m ∧ n_p ≡ 1 mod p）；
2. 引理 6.25 的 30/40/56 三案元素计数算术；
3. |GL(n,F_q)| 公式与 UT 的阶（定理 6.30/6.32 的数值面）。
-/

import Mathlib.Tactic.NormNum

namespace Abstractalgebra.Ch32

/-! ## 西罗计数的候选枚举 -/

-- 40 = 2³·5：n₅ | 8 且 ≡ 1 (mod 5) 只有 1 ⟹ 西罗 5-子群正规
example : (List.range 9).filter (fun d => d ∣ 8 ∧ d % 5 = 1) = [1] := by decide

-- 56 = 2³·7：n₇ | 8 且 ≡ 1 (mod 7) ∈ {1, 8}；非单群走 n₇ = 8 分支
example : (List.range 9).filter (fun d => d ∣ 8 ∧ d % 7 = 1) = [1, 8] := by decide

-- 30 = 2·3·5：n₅ | 6 且 ≡ 1 (mod 5) ∈ {1, 6}
example : (List.range 7).filter (fun d => d ∣ 6 ∧ d % 5 = 1) = [1, 6] := by decide

-- 30 的 n₃ | 10 且 ≡ 1 (mod 3) ∈ {1, 10}
example : (List.range 11).filter (fun d => d ∣ 10 ∧ d % 3 = 1) = [1, 10] := by decide

/-! ## 引理 6.25 的元素计数（阶 < 60 无非阿贝尔单群） -/

-- 30 案：n₅ = 6 个 5-阶子群供 6×4 = 24 个非单位元；n₃ = 10 个 3-阶子群供 20 个；
-- 24 + 20 = 44 > 29 = 30 − 1（非单位元预算）⟹ 矛盾
example : 6 * (5 - 1) + 10 * (3 - 1) = 44 := by norm_num
example : 6 * (5 - 1) + 10 * (3 - 1) > 30 - 1 := by norm_num

-- 56 案：n₇ = 8 个 7-阶子群供 8×6 = 48 个非单位元；加单位元与一个西罗 2-子群
-- （7 个非单位元）恰 56 封顶——第二个西罗 2-子群必超限
example : 8 * 6 + 1 + (8 - 1) = 56 := by norm_num
example : 8 * 6 + 1 + (8 - 1) + 1 > 56 := by norm_num

/-! ## |GL(n, F_q)| 与 UT 的阶（定理 6.30 / 命题 6.28 / 定理 6.32） -/

-- |GL(2, F₂)| = (4−1)(4−2) = 6
example : (2 ^ 2 - 1) * (2 ^ 2 - 2) = 6 := by norm_num

-- |GL(3, F₂)| = (8−1)(8−2)(8−4) = 168
example : (2 ^ 3 - 1) * (2 ^ 3 - 2) * (2 ^ 3 - 2 ^ 2) = 168 := by norm_num

-- |UT(3, F_q)| = q^{3·2/2} = q³；q = 2 时 8 阶，且 8 | 168（西罗 2-子群的阶）
example : 2 ^ (3 * 2 / 2) = 8 := by norm_num
example : 8 ∣ 168 := by decide

-- 168 = 8 · 21（p^e·m 分解）
example : 168 = 2 ^ 3 * 21 := by norm_num

/-! ## 拉格朗日的部分逆（命题 6.26 的数值面） -/

-- 4 ∣ 12 且 A₄ 确有 4 阶子群（V₄）；而 6 ∣ 12 却无 6 阶子群（命题 2.97 反例，
-- 拉格朗日逆命题不成立——西罗定理只保证素数幂部分）
example : 4 ∣ 12 := by decide
example : 6 ∣ 12 := by decide

end Abstractalgebra.Ch32
