import Mathlib

/-!
# Ch01 分类与适定性：调和函数 sin x · sinh y 的机器证明

对应书 §1.3（Hadamard 适定性）与 §1.5 习题背景（Laplace 方程
Cauchy 问题的 Hadamard 反例 u_n = sin(nx)·sinh(ny)/n²）。

反例的代数核：**sin x · sinh y 调和**（Δ = ∂xx + ∂yy = 0）——
缩放 n 倍仍是调和的，而它在 y = 0 上的边值恒为零、在内部却随 n
指数增长。本文件把"调和"这一半（含缩放版）做成完整 Lean 证明；
增长部分（sinh n / n² → ∞）在 Julia/Python 通道数值对表。

证明模式（全书复用）：**∀ 型导数等式**——先用 HasDerivAt 组合子
对每个点建立导数值，`funext`/`.deriv` 固化为函数等式，再改写目标
后交给 `ring` / `field_simp`。
-/

open Real

namespace Evanspde.Ch01

/-- `sin x * sinh y` 的 x 方向二阶导：∂²/∂x² (sin x * sinh y) = −sin x * sinh y。 -/
theorem pxx_sin_sinh (y x : ℝ) :
    deriv (fun x => deriv (fun x => sin x * sinh y) x) x = -sin x * sinh y := by
  have h1 : ∀ x : ℝ, HasDerivAt (fun x => sin x * sinh y) (cos x * sinh y) x := fun x =>
    (hasDerivAt_sin x).mul_const _
  have e1 : (fun x => deriv (fun x => sin x * sinh y) x) = fun x => cos x * sinh y :=
    funext fun x => (h1 x).deriv
  have h2 : ∀ x : ℝ, HasDerivAt (fun x => cos x * sinh y) (-sin x * sinh y) x := fun x =>
    (hasDerivAt_cos x).mul_const _
  rw [e1]
  exact (h2 x).deriv

/-- `sin x * sinh y` 的 y 方向二阶导：∂²/∂y² (sin x * sinh y) = sin x * sinh y。 -/
theorem pyy_sin_sinh (x y : ℝ) :
    deriv (fun y => deriv (fun y => sin x * sinh y) y) y = sin x * sinh y := by
  have h1 : ∀ y : ℝ, HasDerivAt (fun y => sin x * sinh y) (sin x * cosh y) y := fun y =>
    (hasDerivAt_sinh y).const_mul _
  have e1 : (fun y => deriv (fun y => sin x * sinh y) y) = fun y => sin x * cosh y :=
    funext fun y => (h1 y).deriv
  have h2 : ∀ y : ℝ, HasDerivAt (fun y => sin x * cosh y) (sin x * sinh y) y := fun y =>
    (hasDerivAt_cosh y).const_mul _
  rw [e1]
  exact (h2 y).deriv

/-- **Hadamard 反例的代数核**：u = sin x · sinh y 调和（Δu = 0），
故 u_n = sin(nx)·sinh(ny)/n² 亦然（线性性），但它在直线 y = 0 上
恒为零。 -/
theorem harmonic_sin_sinh (x y : ℝ) :
    deriv (fun x => deriv (fun x => sin x * sinh y) x) x
      + deriv (fun y => deriv (fun y => sin x * sinh y) y) y = 0 := by
  rw [pxx_sin_sinh, pyy_sin_sinh]
  ring

/-- Hadamard 序列的每一项都调和：u_n = sin(nx)·sinh(ny)/n²。
（链式法则组合子给出的导数值自带 `n * 1` 形状，不硬掰——最后
`field_simp` + `ring` 收账。） -/
theorem harmonic_scaled (n : ℝ) (x y : ℝ) :
    deriv (fun x => deriv (fun x => sin (n * x) * sinh (n * y) / n ^ 2) x) x
      + deriv (fun y => deriv (fun y => sin (n * x) * sinh (n * y) / n ^ 2) y) y = 0 := by
  -- x 方向
  have hxi : ∀ x : ℝ, HasDerivAt (fun x : ℝ => n * x) (n * 1) x := fun x =>
    (hasDerivAt_id x).const_mul n
  have hs1 : ∀ x : ℝ, HasDerivAt (fun x : ℝ => sin (n * x)) (cos (n * x) * (n * 1)) x := fun x =>
    (hasDerivAt_sin (n * x)).comp x (hxi x)
  have hw1 : ∀ x : ℝ, HasDerivAt (fun x : ℝ => sin (n * x) * sinh (n * y) / n ^ 2)
      (cos (n * x) * (n * 1) * sinh (n * y) / n ^ 2) x := fun x =>
    ((hs1 x).mul_const (sinh (n * y))).div_const (n ^ 2)
  have e1 : (fun x => deriv (fun x : ℝ => sin (n * x) * sinh (n * y) / n ^ 2) x)
      = fun x => cos (n * x) * (n * 1) * sinh (n * y) / n ^ 2 :=
    funext fun x => (hw1 x).deriv
  have hc1 : ∀ x : ℝ, HasDerivAt (fun x : ℝ => cos (n * x)) (-sin (n * x) * (n * 1)) x :=
    fun x => (hasDerivAt_cos (n * x)).comp x (hxi x)
  have hw2 : ∀ x : ℝ, HasDerivAt (fun x : ℝ => cos (n * x) * (n * 1) * sinh (n * y) / n ^ 2)
      (-sin (n * x) * (n * 1) * (n * 1) * sinh (n * y) / n ^ 2) x := fun x =>
    (((hc1 x).mul_const (n * 1)).mul_const (sinh (n * y))).div_const (n ^ 2)
  -- y 方向
  have hyi : ∀ y : ℝ, HasDerivAt (fun y : ℝ => n * y) (n * 1) y := fun y =>
    (hasDerivAt_id y).const_mul n
  have g1 : ∀ y : ℝ, HasDerivAt (fun y : ℝ => sin (n * x) * sinh (n * y) / n ^ 2)
      (sin (n * x) * (cosh (n * y) * (n * 1)) / n ^ 2) y := fun y =>
    (((hasDerivAt_sinh (n * y)).comp y (hyi y)).const_mul (sin (n * x))).div_const (n ^ 2)
  have e2 : (fun y => deriv (fun y : ℝ => sin (n * x) * sinh (n * y) / n ^ 2) y)
      = fun y => sin (n * x) * (cosh (n * y) * (n * 1)) / n ^ 2 :=
    funext fun y => (g1 y).deriv
  have gc1 : ∀ y : ℝ, HasDerivAt (fun y : ℝ => cosh (n * y)) (sinh (n * y) * (n * 1)) y :=
    fun y => (hasDerivAt_cosh (n * y)).comp y (hyi y)
  have g2 : ∀ y : ℝ, HasDerivAt (fun y : ℝ => sin (n * x) * (cosh (n * y) * (n * 1)) / n ^ 2)
      (sin (n * x) * (sinh (n * y) * (n * 1) * (n * 1)) / n ^ 2) y := fun y =>
    (((gc1 y).mul_const (n * 1)).const_mul (sin (n * x))).div_const (n ^ 2)
  -- 收账
  rw [e1, (hw2 x).deriv, e2, (g2 y).deriv]
  by_cases hn : n = 0
  · simp [hn]
  · field_simp
    ring

end Evanspde.Ch01
