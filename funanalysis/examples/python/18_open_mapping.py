import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
"""第 18 章 · 开映射定理（Conway III.12-13）。"""
import numpy as np
rng = np.random.default_rng(1818)
print("==== 18 open-mapping (Python) ====")
A = rng.standard_normal((3, 5))
σ = np.linalg.svd(A, compute_uv=False)
print(f"min singular value = {σ[2]:.6f}")
assert σ[2] > 0.1
print(f"||A^-1|| ≈ 1/min σ = {1/σ[2]:.4f}")
print("==== 18 open-mapping END ====")
