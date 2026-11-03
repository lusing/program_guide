import Mathlib.Tactic

/-!
# 第 36 章：Neyman–Pearson 的逐点证书与精确检验账
-/

namespace Ch36

/--
NP 证明的逐点核心：`phi` 是似然比检验的拒绝概率，`psi` 是任意竞争检验。
在 `f1>k*f0` 时 `phi=1`，在 `f1<k*f0` 时 `phi=0`；因此逐点收益非负。
求和或积分后即得 `Power(phi)-Power(psi) ≥ k*(Size(phi)-Size(psi))`。
-/
theorem np_pointwise_gain (phi psi f0 f1 k : ℚ)
    (hpsi0 : 0 ≤ psi) (hpsi1 : psi ≤ 1)
    (hupper : k * f0 < f1 → phi = 1)
    (hlower : f1 < k * f0 → phi = 0) :
    0 ≤ (phi - psi) * (f1 - k * f0) := by
  rcases lt_trichotomy f1 (k * f0) with h | h | h
  · rw [hlower h]
    nlinarith
  · simp [h]
  · rw [hupper h]
    nlinarith

/-- 五点 Bernoulli 例中，`K≥4` 在 `p=1/4` 下的 size。 -/
example : ((5 : ℚ) * 3 + 1) / 4 ^ 5 = 1 / 64 := by norm_num

/-- 同一拒绝域在 `p=3/4` 下的功效。 -/
example : ((5 : ℚ) * 3 ^ 4 + 3 ^ 5) / 4 ^ 5 = 81 / 128 := by norm_num

/-- 第二类错误率就是 `1-power`。 -/
example : (1 : ℚ) - 81 / 128 = 47 / 128 := by norm_num

/-- 在 `K=3` 时以 `1/5` 概率拒绝，size 精确增至 `17/512`。 -/
example : (1 : ℚ) / 64 + (1 / 5) * (90 / 1024) = 17 / 512 := by norm_num

/-- 随机化后的功效为 `351/512`。 -/
example : (81 : ℚ) / 128 + (1 / 5) * (270 / 1024) = 351 / 512 := by norm_num

/-- 正态例的非中心位移：`sqrt(n)*(mu1-mu0)/sigma=2`。 -/
example : ((4 : ℚ) * (12 - 10)) / 4 = 2 := by norm_num

/-- 更极端的观测只可能有更小的上尾 p 值；这里核对两点精确大小关系。 -/
example : (1 : ℚ) / 64 < 53 / 512 := by norm_num

end Ch36
