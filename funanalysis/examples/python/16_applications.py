import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
"""第 16 章 · 应用三讲（Conway III.7-9*）——scipy 通道。"""
import numpy as np
print("==== 16 applications (Python) ====")
# Banach 极限：Cesàro 均值
x = np.array([(-1.0)**k + 1.0/(k+1) for k in range(1000)])
cesaro = x.cumsum() / np.arange(1, 1001)
print(f"Cesaro at n=1000: {cesaro[-1]:.6f}")
assert -1.1 < cesaro[-1] < 1.1
for k in [10, 50]:
    shifted = x[k:].mean()
    print(f"  shift by {k}: {shifted:.6f}")
    assert abs(shifted - cesaro[-1]) < 0.1
# Runge 逼近
zs = np.array([0.7 + 0.1j*k for k in range(-5, 6)])
f = lambda z: 1/z
for n in [5, 10, 20]:
    p = sum(((-1)**k) * (zs - 1)**k for k in range(n+1))
    err = np.abs(p - f(zs)).max()
    print(f"Runge Taylor n={n}: max|p-f| = {err:.6f}")
    if n >= 10:
        assert err < 0.1
print("==== 16 applications END ====")
