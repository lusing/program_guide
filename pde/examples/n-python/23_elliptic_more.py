# 23_elliptic_more.py —— 第 23 章：边界/变系数/特征值（Python 通道，独立复算）

import math

print("==== 23 elliptic more")

# ---------- (1) 变系数通量格式 O(h²) ----------
kfun = lambda x, y: 1 + x + y

def varcoeff_elliptic(N):
    h = 1.0 / N
    u = [[0.0] * (N + 1) for _ in range(N + 1)]
    for _ in range(300000):
        diff = 0.0
        for i in range(1, N):
            for j in range(1, N):
                x, y = i * h, j * h
                kE = kfun(x + h / 2, y)
                kW = kfun(x - h / 2, y)
                kN = kfun(x, y + h / 2)
                kS = kfun(x, y - h / 2)
                f = (2 * math.pi**2 * kfun(x, y) * math.sin(math.pi * x) * math.sin(math.pi * y)
                     - math.pi * math.cos(math.pi * x) * math.sin(math.pi * y)
                     - math.pi * math.sin(math.pi * x) * math.cos(math.pi * y))
                gs = (kE * u[i + 1][j] + kW * u[i - 1][j] + kN * u[i][j + 1]
                      + kS * u[i][j - 1] + h * h * f) / (kE + kW + kN + kS)
                diff = max(diff, abs(gs - u[i][j]))
                u[i][j] = gs
        if diff < 1e-11:
            break
    return max(abs(u[i][j] - math.sin(math.pi * i * h) * math.sin(math.pi * j * h))
               for i in range(1, N) for j in range(1, N))

e1, e2 = varcoeff_elliptic(20), varcoeff_elliptic(40)
r23 = e1 / e2
assert 3.4 < r23 < 4.6, (e1, e2, r23)
print(f"variable-coefficient flux form: h->h/2 ratio = {r23:.3f} (2nd order)")

# ---------- (2) 特征值 ----------
for N in (8, 16, 32):
    lam_h = 4 - 4 * math.cos(math.pi / N)
    lam = lam_h * N * N
    print(f"N = {N}: lambda_min*N^2 = {lam:.4f} (-> 2pi^2 = {2*math.pi**2:.4f})")
    if N == 32:
        assert abs(lam - 2 * math.pi**2) < 0.05, lam

# ---------- (3) 双调和 13 点系数核对 ----------
x, h4 = 0.3, 0.1
u0 = x**4
S1 = (x + h4)**4 + (x - h4)**4 + 2 * x**4
S2 = 2 * ((x + h4)**4 + (x - h4)**4)
far = (x + 2*h4)**4 + (x - 2*h4)**4 + 2 * x**4
resid = 20*u0 - 8*S1 + 2*S2 + far
print(f"biharmonic 13-point on x^4 (Delta^2 = 0): residual = {resid:.4f} (~O(h^6))")

print("END ====")
