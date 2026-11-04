# 08_cfl_leapfrog.py —— 第 08 章：CFL、特征线与蛙跳（Python 通道，独立复算）

import math

print("==== 08 cfl leapfrog")

# ---------- (1) 依赖域锥 ----------
J, h, lam, nst = 200, 1.0 / 200, 0.8, 30
u = [0.0] * J
u[99] = 1.0
for _ in range(nst):
    un = u[:]
    for j in range(J):
        jm = J - 1 if j == 0 else j - 1
        jp = 0 if j == J - 1 else j + 1
        un[j] = (u[j] - 0.5 * lam * (u[jp] - u[jm])
                 + 0.5 * lam**2 * (u[jp] - 2 * u[j] + u[jm]))
    u = un
supp = [j for j in range(J) if abs(u[j]) > 1e-50]
width = supp[-1] - supp[0] + 1
assert width == 2 * nst + 1, width
print(f"perturbation support after n = {nst} steps: exactly 2n+1 = {width} points")

# ---------- (2) CFL 违反 ----------
def lw_blow(lam2):
    uu = [math.sin(2 * math.pi * 5 * j / 128) for j in range(128)]
    for _ in range(200):
        unn = uu[:]
        for j in range(128):
            jm = 127 if j == 0 else j - 1
            jp = 0 if j == 127 else j + 1
            unn[j] = (uu[j] - 0.5 * lam2 * (uu[jp] - uu[jm])
                      + 0.5 * lam2**2 * (uu[jp] - 2 * uu[j] + uu[jm]))
        uu = unn
        if max(abs(v) for v in uu) > 1e4:
            return True
    return False

assert not lw_blow(0.9)
assert lw_blow(1.1)
print("CFL: LW lambda=0.9 stable; lambda=1.1 blows up")

# ---------- (3) 蛙跳 ----------
def leapfrog(g, lam, h, nst, start_order):
    J = round(1.0 / h)
    u0 = [g((j - 1) * h) for j in range(J)]
    u1 = [0.0] * J
    for j in range(J):
        jm = J - 1 if j == 0 else j - 1
        jp = 0 if j == J - 1 else j + 1
        if start_order == 1:
            u1[j] = u0[j] - 0.5 * lam * (u0[jp] - u0[jm])
        else:
            u1[j] = (u0[j] - 0.5 * lam * (u0[jp] - u0[jm])
                     + 0.5 * lam**2 * (u0[jp] - 2 * u0[j] + u0[jm]))
    up, uc = u0[:], u1[:]
    for _ in range(2, nst + 1):
        un = uc[:]
        for j in range(J):
            jm = J - 1 if j == 0 else j - 1
            jp = 0 if j == J - 1 else j + 1
            un[j] = up[j] - lam * (uc[jp] - uc[jm])
        up = uc[:]
        uc = un
        if max(abs(v) for v in uc) > 1e6:
            return uc
    return uc

gwave = lambda x: 1.0 if 0.3 < x < 0.6 else 0.0
u = leapfrog(gwave, 0.8, 0.005, 100, 2)
assert max(abs(v) for v in u) < 1.5 and min(u) > -0.5
print(f"leapfrog lambda=0.8: stable (max|u| = {max(abs(v) for v in u):.3f})")

J4 = 256
u0 = [1.0 if j % 4 == 1 else (-1.0 if j % 4 == 3 else 0.0) for j in range(J4)]
u1 = [u0[j] - 0.5 * (u0[(j + 1) % J4] - u0[(j - 1) % J4]) for j in range(J4)]
up, uc = u0[:], u1[:]
for _ in range(2, 201):
    un = uc[:]
    for j in range(J4):
        un[j] = up[j] - (uc[(j + 1) % J4] - uc[(j - 1) % J4])
    up = uc[:]
    uc = un
growth = max(abs(v) for v in uc)
assert growth > 100, growth
assert growth < 800, growth
print(f"leapfrog lambda=1 degenerate 4-mode: max|u| = {growth:.1f} after 200 steps (linear growth)")

# ---------- (4) 起步层精度 ----------
gk = lambda x: math.sin(2 * math.pi * 5 * x)
T = 0.5
def lf_err(h, start_order):
    lam = 0.8
    nst = round(T / (lam * h))
    tf = nst * lam * h
    u = leapfrog(gk, lam, h, nst, start_order)
    J = round(1.0 / h)
    uex = [gk(((j - 1) * h - tf) % 1.0) for j in range(J)]
    return max(abs(a - b) for a, b in zip(u, uex))

e1a, e2a = lf_err(2.0e-2, 1), lf_err(1.0e-2, 1)
e1b, e2b = lf_err(2.0e-2, 2), lf_err(1.0e-2, 2)
r1, r2 = e1a / e2a, e1b / e2b
assert 3.0 < r1 < 4.5, r1
assert 3.0 < r2 < 4.5, r2
assert e2b < e2a
print(f"leapfrog 1st-order start: ratio = {r1:.3f}, err(0.02/0.01) = {e1a:.5f} / {e2a:.5f}")
print(f"leapfrog 2nd-order start: ratio = {r2:.3f}, err(0.02/0.01) = {e1b:.5f} / {e2b:.5f}")

print("END ====")
