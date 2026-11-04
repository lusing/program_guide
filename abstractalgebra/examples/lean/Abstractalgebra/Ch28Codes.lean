/-
! # 第 28 章 · 码：分组码、线性码与译码

对应原书 §4.5。机器验证（[7,4] 汉明码）：
1. 伴随式映射的线性性；
2. 校验矩阵的 7 列 = GF(2)³ 的全部非零向量；
3. 伴随式译码的 8 种情形。
-/

import Mathlib.Data.Matrix.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch28

/-! ## 伴随式的线性性 -/

example (H : Matrix (Fin 3) (Fin 7) (ZMod 2))
    (y z : Fin 7 → (ZMod 2)) :
    H.mulVec (y + z) = H.mulVec y + H.mulVec z := by
  simp [Matrix.mulVec_add]

example (H : Matrix (Fin 3) (Fin 7) (ZMod 2))
    (a : ZMod 2) (y : Fin 7 → (ZMod 2)) :
    H.mulVec (a • y) = a • H.mulVec y := by
  simp [Matrix.mulVec_smul]

/-! ## [7,4] 汉明码的校验矩阵 -/

-- 列 = GF(2)³ 的全部非零向量（按自然序）
def H74 : Matrix (Fin 3) (Fin 7) (ZMod 2) :=
  Matrix.of fun i j =>
    (j.val + 1 : ℕ) / (2 : ℕ) ^ i.val  -- 第 j 列 = j+1 的二进制位

-- 伴随式 s = H·y
def syndrome (y : Fin 7 → (ZMod 2)) : Fin 3 → (ZMod 2) :=
  H74.mulVec y

-- 伴随式的 8 种取值：s = 0（无错）或 s = H 的某列（指认错误位）
-- 列的非零性与互异性：H 的 7 列恰是 GF(2)³ 的非零向量（逐列 decide）
example : ∀ j : Fin 7, H74.mulVec (Pi.single j 1) ≠ 0 := by
  intro j
  fin_cases j <;> decide

-- 码字 x（Hx = 0）的单错译码：伴随式 ≠ 0 且等于第 j 列
example (x : Fin 7 → (ZMod 2)) (h : H74.mulVec x = 0) (j : Fin 7) :
    H74.mulVec (x + Pi.single j 1) = H74.mulVec (Pi.single j 1) := by
  have h2 : H74.mulVec (x + Pi.single j 1)
      = H74.mulVec x + H74.mulVec (Pi.single j 1) := Matrix.mulVec_add _ _ _
  rw [h2, h, zero_add]

end Abstractalgebra.Ch28
