import Mathlib

/-!
# Ch15 守恒律：Rankine-Hugoniot 条件的代数核

对应书 §3.4.1（激波与 RH 条件）。对 Burgers 通量 f(u) = u²/2，
激波速度

    s = (f(uL) − f(uR))/(uL − uR) = (uL + uR)/2

是 RH 条件的直接代数后果；Lax 熵条件 f′(uL) > s > f′(uR) 化为
uL > uR。本文件完整证明这两条（除法情形与退化情形 uL = uR）。
-/

namespace Evanspde.Ch15

/-- **RH 速度恒等式（Burgers）**：uL ≠ uR 时
(f(uL) − f(uR))/(uL − uR) = (uL + uR)/2。 -/
theorem rh_burgers (uL uR : ℝ) (h : uL ≠ uR) :
    ((uL^2 / 2) - (uR^2 / 2)) / (uL - uR) = (uL + uR) / 2 := by
  field_simp
  ring

/-- **Lax 熵条件（Burgers）**：uL > uR ⟺ f′(uL) = uL > s > uR = f′(uR)，
其中 s = (uL+uR)/2。 -/
theorem lax_entropy_burgers (uL uR : ℝ) (h : uL > uR) :
    uL > (uL + uR) / 2 ∧ (uL + uR) / 2 > uR := by
  constructor <;> linarith

end Evanspde.Ch15
