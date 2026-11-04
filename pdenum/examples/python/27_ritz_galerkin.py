# 27_ritz_galerkin.py —— 第 27 章：Ritz/Galerkin/配点（Python 通道，独立复算）

import math
import numpy as np

print("==== 27 ritz galerkin")

uex27 = lambda x: x - math.sinh(x) / math.sinh(1)

n = 40
c = [((1.0 if j % 2 == 1 else -1.0) / (j * math.pi)) / ((j**2 * math.pi**2 + 1) / 2) for j in range(1, n + 1)]
u_ritz = lambda x: sum(c[j - 1] * math.sin(j * math.pi * x) for j in range(1, n + 1))
err = max(abs(u_ritz(x) - uex27(x)) for x in np.linspace(0, 1, 1001))
print(f"Ritz (sine basis, n={n}): max err = {err:.3e}")
assert err < 5e-5

errs = []
for m in (2, 4, 8):
    cc = [((1.0 if j % 2 == 1 else -1.0) / (j * math.pi)) / ((j**2 * math.pi**2 + 1) / 2) for j in range(1, m + 1)]
    e = max(abs(sum(cc[j - 1] * math.sin(j * math.pi * x) for j in range(1, m + 1)) - uex27(x))
            for x in np.linspace(0, 1, 501))
    errs.append(e)
print(f"Ritz truncation errors n=2/4/8: {[f'{e:.3e}' for e in errs]}")
assert errs[2] < errs[1] / 2.5

def hat27(x, i, h):
    xi = i * h
    if x <= xi - h or x >= xi + h:
        return 0.0
    return (x - (xi - h)) / h if x <= xi else ((xi + h) - x) / h

def simpson(g, lo, hi, m=100):
    s = g(lo) + g(hi)
    for k in range(1, m):
        x = lo + (hi - lo) * k / m
        s += (4 if k % 2 == 1 else 2) * g(x)
    return s * (hi - lo) / (3 * m)

N = 40
h = 1.0 / N
nh = N - 1
A = np.zeros((nh, nh))
for i in range(1, nh + 1):
    if i > 1:
        A[i - 1, i - 2] = -1 / h + h / 6
    A[i - 1, i - 1] = 2 / h + 2 * h / 3
    if i < nh:
        A[i - 1, i] = -1 / h + h / 6
b = np.zeros(nh)
for i in range(1, nh + 1):
    lo = max((i - 1) * h, 0.0)
    hi = min((i + 1) * h, 1.0)
    b[i - 1] = simpson(lambda x: x * hat27(x, i, h), lo, hi)
ch = np.linalg.solve(A, b)
u_hat = lambda x: sum(ch[i - 1] * hat27(x, i, h) for i in range(1, nh + 1))
err_hat = max(abs(u_hat(x) - uex27(x)) for x in np.linspace(0, 1, 1001))
print(f"Galerkin (hat basis, N={N}): max err = {err_hat:.3e}")
assert err_hat < 2e-4
print("Ritz and Galerkin produce the same solution")

Ac = np.zeros((nh, nh))
bc = np.zeros(nh)
for i in range(1, nh + 1):
    xi = i * h
    for j in range(1, nh + 1):
        Ac[i - 1, j - 1] = (j * math.pi) ** 2 * math.sin(j * math.pi * xi) + math.sin(j * math.pi * xi)
    bc[i - 1] = xi
cc = np.linalg.solve(Ac, bc)
u_colloc = lambda x: sum(cc[j - 1] * math.sin(j * math.pi * x) for j in range(1, nh + 1))
err_c = max(abs(u_colloc(x) - uex27(x)) for x in np.linspace(0, 1, 1001))
print(f"collocation (sine, n={nh}): max err = {err_c:.3e}")
assert err_c < 5e-4

print("END ====")
