/-
! # 第 14 章 · 用群计算：伯恩赛德与 Pólya

对应原书 §2.8。机器验证（例 2.159/2.163 的 4×4 双色棋盘）：
1. C₄ 旋转群的四个元素在 16 格上的循环数：16 / 4 / 8 / 4；
2. Pólya 公式 (2^16 + 2·2^4 + 2^8)/4 = 16456。
-/

import Mathlib.GroupTheory.Perm.List
import Mathlib.GroupTheory.Perm.Cycle.Factors
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch14

/-! ## 90° 旋转作为 16 格上的置换 -/

-- r90 = (0 4 8 12)(1 5 9 13)(2 6 10 14)(3 7 11 15)：四个 4-循环
def r90 : Equiv.Perm (Fin 16) :=
  (List.formPerm [0, 4, 8, 12] *
   (List.formPerm [1, 5, 9, 13] *
    (List.formPerm [2, 6, 10, 14] * List.formPerm [3, 7, 11, 15])))

-- 转四下回家（阶 = 4 的幂版）
example : r90 ^ 4 = 1 := by native_decide

example : r90 ^ 2 ≠ 1 := by native_decide

-- 四个元素的循环数 t(τ)：
-- 恒等 t = 16（不动染色 2^16）
example : Fintype.card (Fin 16) = 16 := by decide

-- r90 与 r270：t = 4（四个 4-循环，不动染色 2^4）
example : r90.cycleFactorsFinset.card = 4 := by native_decide

-- r180 = r90²：t = 8（八个 2-循环，不动染色 2^8）
example : (r90 ^ 2).cycleFactorsFinset.card = 8 := by native_decide

example : (r90 ^ 3).cycleFactorsFinset.card = 4 := by native_decide

-- 恒等没有非平凡循环因子（16 个不动点）
example : (1 : Equiv.Perm (Fin 16)).cycleFactorsFinset.card = 0 := by simp

/-! ## Pólya 公式（定理 2.163）：4×4 双色棋盘 = 16456 -/

example : (2 ^ 16 + 2 * 2 ^ 4 + 2 ^ 8) / 4 = 16456 := by norm_num

end Abstractalgebra.Ch14
