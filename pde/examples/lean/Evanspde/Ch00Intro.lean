import Mathlib

/-!
# Ch00 导言：叠加原理的最小完整机器证明

对应书 §1.1（线性方程的定义）与 §1.4（"无普遍理论，逐类研究"的
景观）。本文件把书里一句话——"线性方程的两个解的线性组合仍是解"
（叠加原理）——做成完整 Lean 证明，作为全书"代数核"风格的样本：

* 算子 L u = u″ + u（谐算子，齐次线性方程的样本）；
* `superposition`：u、v 是解 ⟹ a•u + b•v 是解，逐点恒等。
-/

open Real

namespace Evanspde.Ch00

/-- 叠加原理：若 u″ + u = 0 与 v″ + v = 0（以 HasDerivAt 的两层
导数表述），则任意线性组合 a•u + b•v 也满足同一方程。 -/
theorem superposition {u u' u'' v v' v'' : ℝ → ℝ} (a b : ℝ)
    (hu1 : ∀ x, HasDerivAt u (u' x) x) (hu2 : ∀ x, HasDerivAt u' (u'' x) x)
    (hv1 : ∀ x, HasDerivAt v (v' x) x) (hv2 : ∀ x, HasDerivAt v' (v'' x) x)
    (hEu : ∀ x, u'' x + u x = 0) (hEv : ∀ x, v'' x + v x = 0) (x : ℝ) :
    deriv (deriv (fun y => a * u y + b * v y)) x + (a * u x + b * v x) = 0 := by
  -- 一阶：w := a•u + b•v 的导函数在每点为 a•u' + b•v'
  have hw1 : ∀ y, HasDerivAt (fun y => a * u y + b * v y) (a * u' y + b * v' y) y := fun y =>
    ((hu1 y).const_mul a).add ((hv1 y).const_mul b)
  have e1 : (fun y => deriv (fun y => a * u y + b * v y) y) = fun y => a * u' y + b * v' y :=
    funext fun y => (hw1 y).deriv
  -- 二阶：w 的导函数的导数在每点为 a•u'' + b•v''
  have hw2 : ∀ y, HasDerivAt (deriv fun y => a * u y + b * v y) (a * u'' y + b * v'' y) y := by
    intro y
    rw [show deriv (fun y => a * u y + b * v y) = fun y => a * u' y + b * v' y from e1]
    exact ((hu2 y).const_mul a).add ((hv2 y).const_mul b)
  rw [(hw2 x).deriv]
  have key : a * u'' x + b * v'' x + (a * u x + b * v x)
      = a * (u'' x + u x) + b * (v'' x + v x) := by ring
  rw [key, hEu x, hEv x]
  ring

/-- 用 `superposition` 落到具体函数：2cos + 3sin 仍是 u″ + u = 0 的解。
cos 的两层导数：cos → −sin → −cos；sin 的两层导数：sin → cos → −sin。 -/
example (x : ℝ) :
    deriv (deriv (fun y => 2 * cos y + 3 * sin y)) x + (2 * cos x + 3 * sin x) = 0 := by
  refine superposition (a := 2) (b := 3)
    (u := fun y => cos y) (u' := fun y => -sin y) (u'' := fun y => -cos y)
    (v := fun y => sin y) (v' := fun y => cos y) (v'' := fun y => -sin y)
    (fun y => hasDerivAt_cos y) (fun y => (hasDerivAt_sin y).neg)
    (fun y => hasDerivAt_sin y) (fun y => hasDerivAt_cos y)
    (fun y => by ring) (fun y => by ring) x

end Evanspde.Ch00
