import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np
from scipy.linalg import expm

rng = np.random.default_rng(3636)
print("==== 36 spectral_measures (Python) ====")
n = 8
H0 = rng.standard_normal((n, n))
H = (H0 + H0.T) / 2
vals, V = np.linalg.eigh(H)
I = np.eye(n)

# 谱测度（PVM）：E(Δ) = Σ_{λᵢ∈Δ} vᵢ vᵢ*
def E(pred):
    return V @ np.diag([1.0 if pred(λ) else 0.0 for λ in vals]) @ V.T

assert np.linalg.norm(E(lambda λ: False)) < 1e-12
assert np.linalg.norm(E(lambda λ: True) - I) < 1e-12
E1 = E(lambda λ: λ < 0)
E2 = E(lambda λ: λ >= 0)
assert np.linalg.norm(E1 @ E2) < 1e-12
assert np.linalg.norm(E1 + E2 - I) < 1e-12
assert np.linalg.norm(E1 @ E1 - E1) < 1e-12
print("PVM 公理：E(∅)=0，E(ℝ)=I，不相交⟹正交，可加，幂等：✓")

# 谱积分：H = ∫ λ dE(λ)
assert np.linalg.norm(V @ np.diag(vals) @ V.T - H) < 1e-12
print("∫ λ dE(λ) = H：✓")

# 函数演算：f(H) = ∫ f(λ) dE(λ)
assert np.linalg.norm(V @ np.diag(vals ** 2) @ V.T - H @ H) < 1e-12
assert np.linalg.norm(V @ np.diag(np.exp(vals)) @ V.T - expm(H)) < 1e-10
print("f(H) = ∫ f dE（λ²、e^λ 双验证）：✓")
print("==== 36 spectral_measures END ====")
