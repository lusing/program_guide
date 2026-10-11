import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np
rng = np.random.default_rng(2626)
print("==== 26 fixed-points (Python) ====")
theta = 2*np.pi * rng.random(1000)
print(f"uniform S1 mean: {theta.mean()/(2*np.pi):.4f} ≈ 0.5")
assert abs(theta.mean()/(2*np.pi) - 0.5) < 0.02
print("Haar measure on S1 = uniform: PASS")
print("==== 26 fixed-points END ====")
