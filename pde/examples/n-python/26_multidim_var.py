# 26_multidim_var.py —— 第 26 章：高维变分（Python 通道，独立复算）

import math

print("==== 26 multidim var")

f26 = lambda x, y: 2 * math.pi**2 * math.sin(math.pi * x) * math.sin(math.pi * y)
uex26 = lambda x, y: math.sin(math.pi * x) * math.sin(math.pi * y)

def J_energy(vfun):
    n = 400
    h = 1.0 / n
    s = 0.0
    for i in range(1, n):
        for j in range(1, n):
            x, y = i * h, j * h
            gux = (vfun(x + h, y) - vfun(x - h, y)) / (2 * h)
            guy = (vfun(x, y + h) - vfun(x, y - h)) / (2 * h)
            s += 0.5 * (gux**2 + guy**2) - f26(x, y) * vfun(x, y)
    return s * h * h

Jstar = J_energy(uex26)
w = lambda x, y: math.sin(math.pi * x) * math.sin(math.pi * y) * x * (1 - x)
for t in (0.3, 1.0):
    Jpert = J_energy(lambda x, y, t=t: uex26(x, y) + t * w(x, y))
    print(f"J(u*) = {Jstar:.6f}  J(u* + {t}w) = {Jpert:.6f} (larger by {Jpert - Jstar:.6f})")
    assert Jpert > Jstar

u0fun = lambda x, y: 1 + x * y
utilde = lambda x, y: math.sin(math.pi * x) * math.sin(math.pi * y) + u0fun(x, y)
ftilde = lambda x, y: 2 * math.pi**2 * math.sin(math.pi * x) * math.sin(math.pi * y)

maxres = 0.0
hh = 1e-3
for k in range(1, 9):
    for m in range(1, 9):
        x, y = 0.1 * k, 0.1 * m
        lap = ((utilde(x + hh, y) - 2 * utilde(x, y) + utilde(x - hh, y)) / hh**2
               + (utilde(x, y + hh) - 2 * utilde(x, y) + utilde(x, y - hh)) / hh**2)
        maxres = max(maxres, abs(-lap - ftilde(x, y)))
assert maxres < 5e-5, maxres
print(f"lifting: u = u0 + w with harmonic u0 = 1+xy, residual = {maxres:.2e}")

N = 40
lam_min = 4 - 4 * math.cos(math.pi / N)
print(f"discrete Poincare: lambda_min*N^2 = {lam_min * N * N:.4f} -> 2pi^2 = {2*math.pi**2:.4f}")
assert abs(lam_min * N * N - 2 * math.pi**2) < 0.05

print("END ====")
