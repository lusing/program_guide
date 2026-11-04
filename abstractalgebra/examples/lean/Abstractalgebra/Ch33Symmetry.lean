/-
! # 第 33 章 · 装饰的对称

对应原书 §6.3。机器验证：
1. 平面等距的基本关系式（t / R / α / β / ρ 的代数，函数等式层面）；
2. 滑动反射 ρ² = t、点群 ⊆ V₄（ℤ/2 × ℤ/2 的自逆性）；
3. 旋转矩阵的阶（晶体学限制的数值面：阶 ∈ {1,2,3,4,6}）。
-/

import Mathlib.Data.Matrix.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum

namespace Abstractalgebra.Ch33

/-! ## 五个基本等距（ℚ² 上的函数） -/

/-- 单位平移 t(x, y) = (x+1, y)。 -/
def T (p : ℚ × ℚ) : ℚ × ℚ := (p.1 + 1, p.2)

/-- 平移逆 t⁻¹(x, y) = (x−1, y)。 -/
def Tinv (p : ℚ × ℚ) : ℚ × ℚ := (p.1 - 1, p.2)

/-- 半翻转（180° 旋转）R(x, y) = (−x, −y)。 -/
def R (p : ℚ × ℚ) : ℚ × ℚ := (-p.1, -p.2)

/-- α：关于 x-轴的反射 (x, y) ↦ (x, −y)。 -/
def Alpha (p : ℚ × ℚ) : ℚ × ℚ := (p.1, -p.2)

/-- β：关于 y-轴的反射 (x, y) ↦ (−x, y)。 -/
def Beta (p : ℚ × ℚ) : ℚ × ℚ := (-p.1, p.2)

/-- ρ：滑动反射（x-轴反射 + 沿轴半单位平移）。 -/
def Rho (p : ℚ × ℚ) : ℚ × ℚ := (p.1 + 1 / 2, -p.2)

/-! ## 基本关系式（全部 funext；simp 后个别需 constructor + ring） -/

example : T ∘ Tinv = id := by
  funext p; simp [T, Tinv]
example : Tinv ∘ T = id := by
  funext p; simp [T, Tinv]

-- 对合：三个反射型等距平方为恒等
example : R ∘ R = id := by
  funext p; simp [R]
example : Alpha ∘ Alpha = id := by
  funext p; simp [Alpha]
example : Beta ∘ Beta = id := by
  funext p; simp [Beta]

-- 半翻转 = 两个垂直反射之积
example : Beta ∘ Alpha = R := by
  funext p; simp [Beta, Alpha, R]
example : Alpha ∘ Beta = R := by
  funext p; simp [Beta, Alpha, R]

-- 滑动反射的平方是单位平移（ρ² = t）
example : Rho ∘ Rho = T := by
  funext p; simp [Rho, T]; ring

-- α 与 t 交换；β 与 R 与 t 反交换（半翻转/竖直反射翻转平移方向）
example : Alpha ∘ T = T ∘ Alpha := by
  funext p; simp [Alpha, T]
example : Beta ∘ T = Tinv ∘ Beta := by
  funext p; simp [Beta, T, Tinv]; ring
example : R ∘ T = Tinv ∘ R := by
  funext p; simp [R, T, Tinv]; ring

-- α 与 ρ 交换（合成给出沿轴的半平移：α·ρ = ρ·α = t_{1/2}）
example : Alpha ∘ Rho = Rho ∘ Alpha := by
  funext p; simp [Alpha, Rho]

/-! ## 点群 ⊆ V₄（推论 6.49） -/

-- 点群是 {1, f, g, h} 的子群；V₄ ≅ ℤ/2 × ℤ/2：每个元素自逆
example : ∀ v : ZMod 2 × ZMod 2, v + v = 0 := by decide

-- V₄ 中的乘法：f·g = h（对角符号矩阵 (±1, ±1) 的分量乘法）
example : ((1 : ZMod 2), (0 : ZMod 2)) + (0, 1) = (1, 1) := by decide

/-! ## 旋转矩阵的阶（晶体学限制的数值面） -/

-- 90° 旋转矩阵 M 的平方 = −I、四次方 = I
def M4 : Matrix (Fin 2) (Fin 2) ℤ := Matrix.of ![![0, -1], ![1, 0]]

example : M4 * M4 = Matrix.of ![![-1, 0], ![0, -1]] := by decide
example : M4 * M4 * M4 * M4 = Matrix.of ![![1, 0], ![0, 1]] := by decide

-- 60° 旋转的整数化身：N = !![0,-1;1,1] 满足 N³ = −I ⟹ 阶 6；
-- N² 是 120° 旋转（阶 3）
def M6 : Matrix (Fin 2) (Fin 2) ℤ := Matrix.of ![![0, -1], ![1, 1]]

example : M6 * M6 * M6 = Matrix.of ![![-1, 0], ![0, -1]] := by decide
example : M6 ^ 6 = Matrix.of ![![1, 0], ![0, 1]] := by decide

-- 迹核对：tr M4 = 0 = 2cos(2π/4)，tr M6 = 1 = 2cos(2π/6)
-- （晶体学限制：格上旋转的迹必为整数 ⟹ 阶只能取 {1,2,3,4,6}；
--   阶 5 要求 tr = (√5−1)/2 ∉ ℤ，被排除——数值面见 julia 通道）
example : M4 0 0 + M4 1 1 = 0 := by decide
example : M6 0 0 + M6 1 1 = 1 := by decide

/-! ## Leonardo 定理（6.47）的数值面 -/

-- D_{2m} 的阶 = 2m；m = 1..6 的六边形对称群等
example : (2 : ℕ) * 6 = 12 := by norm_num
example : (2 : ℕ) * 4 = 8 := by norm_num

end Abstractalgebra.Ch33
