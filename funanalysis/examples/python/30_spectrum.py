import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np
rng = np.random.default_rng(3030)
print("==== 30 spectrum (Python) ====")
A = rng.standard_normal((5, 5))
λ = np.linalg.eigvals(A)
ρ = np.abs(λ).max()
print(f"spectral radius = {ρ:.4f}")
print(f"opnorm = {np.linalg.norm(A, 2):.4f}")
assert ρ <= np.linalg.norm(A, 2)
print("==== 30 spectrum END ====")
