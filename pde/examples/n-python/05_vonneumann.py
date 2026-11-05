# 05_vonneumann.py —— 第 05 章：von Neumann 稳定性分析（Python 通道，独立复算）

import math
import numpy as np

print("==== 05 vonneumann")

thetas = np.linspace(1.0e-3, math.pi - 1.0e-3, 500)
s2 = lambda th: np.sin(th / 2) ** 2

maxG_adv = lambda mu: np.max(np.abs(1 - 1j * mu * np.sin(thetas)))
maxG_up = lambda mu: np.max(np.sqrt(1 - 4 * mu * (1 - mu) * s2(thetas)))
maxG_heat = lambda r: np.max(np.abs(1 - 4 * r * s2(thetas)))
maxG_btcs = lambda r: np.max(1 / (1 + 4 * r * s2(thetas)))

for mu in (0.3, 0.8, 1.0):
    assert maxG_adv(mu) > 1.0 + 1e-6, mu
print("FTCS-advection: max|G| = sqrt(1+mu^2) > 1 for every mu (unconditionally unstable)")

for mu in (0.5, 0.9, 1.0):
    assert maxG_up(mu) < 1.0 + 1e-9, mu
g15 = maxG_up(1.5)
assert g15 > 1.5, g15
print(f"upwind: max|G| <= 1 iff mu in [0,1]; at mu=1.5 max|G| = {g15:.4f}")

for r in (0.25, 0.5):
    assert maxG_heat(r) <= 1.0 + 1e-9, r
gr = maxG_heat(0.6)
assert abs(gr - (4 * 0.6 - 1)) < 1.0e-5, gr
print(f"FTCS heat: max|G| = 1-4r s^2; at r=0.6, max|G| = 4r-1 = {gr:.4f}")

for r in (0.25, 2.0, 50.0):
    assert maxG_btcs(r) < 1.0, r
print("BTCS heat: |G| = 1/(1+4r s^2) < 1 for every r (unconditionally stable)")

# ---------- Richardson 增长矩阵（书例 3.4） ----------
print("--- Richardson growth matrix (book Example 3.4) ---")
worst = 0.0
for r in np.arange(0.1, 1.01, 0.1):
    for th in thetas:
        s = math.sin(th / 2) ** 2
        mu2 = -4 * r * s - math.sqrt(16 * r * r * s * s + 1)
        worst = max(worst, abs(mu2))
assert worst > 4.9, worst
print(f"max over r in [0.1,1], theta of |mu_-| = {worst:.3f} > 1: always unstable")

# 矩阵特征值视角（numpy 对 2x2 增长矩阵直接求特征值）
for (r, th) in ((0.5, math.pi / 2), (0.3, math.pi), (0.8, 0.7)):
    s = math.sin(th / 2) ** 2
    G = np.array([[-8 * r * s, 1.0], [1.0, 0.0]])
    eig = np.linalg.eigvals(G)
    assert max(abs(eig)) > 1.0 + 1e-12, (r, th, eig)
print("eigvals of G=[[-8rs,1],[1,0]]: one root beyond unit circle at every (r,theta)")

# 数值迭代版：Richardson 在 r=0.5 爆掉
def richardson_run(h, r, nst):
    J = round(1.0 / h) - 1
    tau = r * h * h
    u_prev = [math.sin(math.pi * j * h) for j in range(1, J + 1)]
    u = [u_prev[j] + r * ((0.0 if j == 0 else u_prev[j - 1]) - 2 * u_prev[j]
                          + (0.0 if j == J - 1 else u_prev[j + 1])) for j in range(J)]
    for _ in range(2, nst + 1):
        u_new = u[:]
        for j in range(J):
            ul = 0.0 if j == 0 else u[j - 1]
            ur = 0.0 if j == J - 1 else u[j + 1]
            u_new[j] = u_prev[j] + 2 * r * (ul - 2 * u[j] + ur)
        u_prev = u
        u = u_new
        if max(abs(v) for v in u) > 1e8:
            break
    return max(abs(v) for v in u)

run_val = richardson_run(0.01, 0.5, 60)
assert run_val > 1e3, run_val
print(f"Richardson iterations at r=0.5: max|u| after ~60 steps = {run_val:.3g}")

# ---------- Parseval 闭环 ----------
def l2_growth(scheme, lam, h, nst):
    J = round(1.0 / h)
    u = [math.sin(2 * math.pi * 3 * (j - 1) * h) + 0.5 * math.sin(2 * math.pi * 7 * (j - 1) * h)
         for j in range(J)]
    n0 = math.sqrt(sum(v * v for v in u))
    jm = lambda j: J - 1 if j == 0 else j - 1
    jp = lambda j: 0 if j == J - 1 else j + 1
    for _ in range(nst):
        un = u[:]
        for j in range(J):
            if scheme == "ftbs":
                un[j] = u[j] - lam * (u[j] - u[jm(j)])
            else:
                un[j] = 0.5 * (u[jp(j)] + u[jm(j)]) - lam * 0.5 * (u[jp(j)] - u[jm(j)])
        u = un
    return math.sqrt(sum(v * v for v in u)) / n0

def predicted_growth(scheme, lam, h, nst):
    J = round(1.0 / h)
    total = 0.0
    for (k, amp) in ((3, 1.0), (7, 0.5)):
        th = 2 * math.pi * k / J
        if scheme == "ftbs":
            G2 = 1 - 4 * lam * (1 - lam) * math.sin(th / 2) ** 2
        else:
            G2 = math.cos(th) ** 2 + lam**2 * math.sin(th) ** 2
        total += amp**2 * G2**nst
    return math.sqrt(total / (1.0 + 0.25))

h, nst = 0.01, 60
for (scheme, lam) in (("ftbs", 0.8), ("lf", 0.9), ("ftbs", 1.1)):
    meas = l2_growth(scheme, lam, h, nst)
    pred = predicted_growth(scheme, lam, h, nst)
    rel = abs(meas - pred) / pred
    assert rel < 1.0e-8, (scheme, lam, meas, pred)
    print(f"l2 growth ({scheme}, lambda={lam}, n={nst}): measured = {meas:.6f}  predicted = {pred:.6f}")

print("END ====")
