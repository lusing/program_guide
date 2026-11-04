# 25_twopoint.py —— 第 25 章：两点边值变分形式（Python 通道，独立复算）

import math
import numpy as np

print("==== 25 twopoint")

f25 = lambda x: (math.pi**2 + 1) * math.sin(math.pi * x)
uex = lambda x: math.sin(math.pi * x)

N = 8
h = 1.0 / N

def hat(x, i):
    xi = i * h
    if x <= xi - h or x >= xi + h:
        return 0.0
    return (x - (xi - h)) / h if x <= xi else ((xi + h) - x) / h

def dhat(x, i):
    xi = i * h
    if x < xi - h or x > xi + h:
        return 0.0
    return 1.0 / h if x <= xi else -1.0 / h

def simpson(g, lo, hi, n=200):
    s = g(lo) + g(hi)
    for k in range(1, n):
        x = lo + (hi - lo) * k / n
        s += (4 if k % 2 == 1 else 2) * g(x)
    return s * (hi - lo) / (3 * n)

d_ii = simpson(lambda x: dhat(x, 4)**2 + hat(x, 4)**2, 3 * h, 5 * h)
d_ij = simpson(lambda x: dhat(x, 4) * dhat(x, 5) + hat(x, 4) * hat(x, 5), 4 * h, 5 * h)
print(f"D(hat_4, hat_4) = {d_ii:.6f} closed {2/h + 2*h/3:.6f}")
print(f"D(hat_4, hat_5) = {d_ij:.6f} closed {-1/h + h/6:.6f}")
assert abs(d_ii - (2 / h + 2 * h / 3)) < 1e-9
assert abs(d_ij - (-1 / h + h / 6)) < 0.05

n = N - 1
A = np.zeros((n, n))
for i in range(1, n + 1):
    for j in range(max(1, i - 1), min(n, i + 1) + 1):
        lo = max((i - 1) * h, (j - 1) * h, 0.0)
        hi = min((i + 1) * h, (j + 1) * h, 1.0)
        A[i - 1, j - 1] = simpson(lambda x: dhat(x, i) * dhat(x, j)
                                  + hat(x, i) * hat(x, j), lo, hi)
evs = np.linalg.eigvalsh(A)
assert evs.min() > 0
print(f"stiffness matrix positive definite: min eig = {evs.min():.4f}, max = {evs.max():.4f}")

b = np.zeros(n)
for i in range(1, n + 1):
    lo = max((i - 1) * h, 0.0)
    hi = min((i + 1) * h, 1.0)
    b[i - 1] = simpson(lambda x: f25(x) * hat(x, i), lo, hi)

c = np.linalg.solve(A, b)
u_ritz = lambda x: sum(c[i - 1] * hat(x, i) for i in range(1, n + 1))
maxerr = max(abs(u_ritz(x) - uex(x)) for x in np.linspace(0, 1, 501))
print(f"Ritz (hat, N={N}): max err = {maxerr:.5f}")
assert maxerr < 0.08

c_interp = np.array([uex(i * h) for i in range(1, n + 1)])
energy = lambda cv: cv @ A @ cv
print(f"energy(ritz) = {energy(c):.6f} <= energy(interp) = {energy(c_interp):.6f}")
assert energy(c) <= energy(c_interp) + 1e-12

print("END ====")
