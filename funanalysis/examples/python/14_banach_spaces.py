import sys, io, math
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
"""第 14 章 · Banach 空间的数值实验（Conway III.1-4）——scipy 通道。"""
import numpy as np
rng = np.random.default_rng(1414)
print("==== 14 banach-spaces (Python) ====")
# Taylor 逼近收敛
xs = np.linspace(0, 1, 200)
for k in [5, 10, 20]:
    p = sum(xs**j / math.factorial(j) for j in range(k+1))
    err = np.abs(p - np.exp(xs)).max()
    print(f"Taylor degree {k}: sup error = {err:.6f}")
    assert err < 0.01  # Taylor 收敛
# 商空间范数
M_basis = np.array([1.0, 0.0, 0.0])
x = np.array([1.0, 2.0, 3.0])
x_perp = x - np.dot(x, M_basis) * M_basis
qn = np.linalg.norm(x_perp)
print(f"quotient ||x+M|| = {qn:.6f}  sqrt(13) = {np.sqrt(13):.6f}")
assert abs(qn - np.sqrt(13)) < 1e-12
# 高维随机向量近似正交
d = 1000
v1 = rng.standard_normal(d); v1 /= np.linalg.norm(v1)
v2 = rng.standard_normal(d); v2 /= np.linalg.norm(v2)
cos_angle = abs(np.dot(v1, v2))
print(f"random unit vectors in R^{d}: |cos| = {cos_angle:.6f}")
assert cos_angle < 0.1
print("==== 14 banach-spaces END ====")
