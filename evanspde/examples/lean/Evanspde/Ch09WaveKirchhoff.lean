import Mathlib

/-!
# Ch09 波方程 I：行波解的完整机器证明

对应书 §2.4.1（一维波方程的显式解：两个传输方程的叠加）。本文件
证明**右行波**满足波方程：

    u(x,t) = g(x − t)    ⟹    u_tt − u_xx = 0

两个方向的二层导数分别为 g″·(−1)² 与 g″·(1−1·…)——内层导数 ±1
的平方**消去符号**，这正是"波向两个方向传播"的代数痕迹（左行波
同理；Ch00 superposition 承担叠加，即 d'Alembert 公式）。
-/

open Real

namespace Evanspde.Ch09

/-- 右行波 g(x−t) 的二阶 t 导数（产出形状：`(0−1)*(0−1)` 因子）。 -/
theorem right_wave_tt (g g' g'' : ℝ → ℝ) (x t : ℝ)
    (h1 : ∀ y, HasDerivAt g (g' y) y) (h2 : ∀ y, HasDerivAt g' (g'' y) y) :
    deriv (fun t => deriv (fun s => g (x - s)) t) t
      = g'' (x - t) * (0 - 1) * (0 - 1) + g' (x - t) * 0 := by
  have ht1 : ∀ s : ℝ, HasDerivAt (fun s : ℝ => x - s) (0 - 1) s := fun s =>
    (hasDerivAt_const s x).sub (hasDerivAt_id s)
  have hA : ∀ s : ℝ, HasDerivAt (fun s : ℝ => g (x - s)) (g' (x - s) * (0 - 1)) s :=
    fun s => (h1 (x - s)).comp s (ht1 s)
  have eA : (fun s => deriv (fun z : ℝ => g (x - z)) s)
      = fun s => g' (x - s) * (0 - 1) :=
    funext fun s => (hA s).deriv
  have hB : HasDerivAt (fun s : ℝ => g' (x - s) * (0 - 1))
      (g'' (x - t) * (0 - 1) * (0 - 1) + g' (x - t) * 0) t :=
    ((h2 (x - t)).comp t (ht1 t)).mul (hasDerivAt_const t (0 - 1))
  rw [eA]
  exact hB.deriv

/-- 右行波 g(x−t) 的二阶 x 导数。 -/
theorem right_wave_xx (g g' g'' : ℝ → ℝ) (x t : ℝ)
    (h1 : ∀ y, HasDerivAt g (g' y) y) (h2 : ∀ y, HasDerivAt g' (g'' y) y) :
    deriv (fun y => deriv (fun z => g (z - t)) y) x
      = g'' (x - t) * (1 - 0) * (1 - 0) + g' (x - t) * 0 := by
  have hx1 : ∀ z : ℝ, HasDerivAt (fun z : ℝ => z - t) (1 - 0) z := fun z =>
    (hasDerivAt_id z).sub (hasDerivAt_const z t)
  have hA : ∀ z : ℝ, HasDerivAt (fun z : ℝ => g (z - t)) (g' (z - t) * (1 - 0)) z :=
    fun z => (h1 (z - t)).comp z (hx1 z)
  have eA : (fun y => deriv (fun z : ℝ => g (z - t)) y)
      = fun y => g' (y - t) * (1 - 0) :=
    funext fun y => (hA y).deriv
  have hB : HasDerivAt (fun y : ℝ => g' (y - t) * (1 - 0))
      (g'' (x - t) * (1 - 0) * (1 - 0) + g' (x - t) * 0) x :=
    ((h2 (x - t)).comp x (hx1 x)).mul (hasDerivAt_const x (1 - 0))
  rw [eA]
  exact hB.deriv

/-- **右行波满足波方程**：u_tt − u_xx = 0。 -/
theorem right_wave_solves (g g' g'' : ℝ → ℝ) (x t : ℝ)
    (h1 : ∀ y, HasDerivAt g (g' y) y) (h2 : ∀ y, HasDerivAt g' (g'' y) y) :
    deriv (fun t => deriv (fun s => g (x - s)) t) t
      - deriv (fun y => deriv (fun z => g (z - t)) y) x = 0 := by
  rw [right_wave_tt g g' g'' x t h1 h2, right_wave_xx g g' g'' x t h1 h2]
  ring

end Evanspde.Ch09

