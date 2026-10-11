import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
"""第 21 章 · 分离定理。"""
import numpy as np
rng = np.random.default_rng(2121)
print("==== 21 separation (Python) ====")
cB = np.array([3.0, 0.0]); rB = 0.5
n_vec = cB / np.linalg.norm(cB)
c = 1.0 + (np.linalg.norm(cB) - rB - 1.0) / 2
assert np.linalg.norm(cB) - rB > c  # B's closest point > c
print(f"separation: ball A < {c:.4f} < dist to B center - rB")
print("==== 21 separation END ====")
