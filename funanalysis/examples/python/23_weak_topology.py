import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
"""第 23 章 · 弱拓扑。"""
import numpy as np
rng = np.random.default_rng(2323)
print("==== 23 weak-topology (Python) ====")
x = 1.0 / np.arange(1, 101)
print(f"x[n] at n=100: {x[99]:.4f} → 0 (e_n → 0 weak* in ℓ¹)")
assert abs(x[99]) < 0.02
print("==== 23 weak-topology END ====")
