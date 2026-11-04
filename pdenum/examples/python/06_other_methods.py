# 06_other_methods.py —— 第 06 章：Hirt / 矩阵法 / 能量法（Python 通道，独立复算）

import math
import numpy as np

print("==== 06 other methods")

# ---------- (1) Hirt：修正方程的耗散率 ----------
a, h, lam = 1.0, 0.01, 0.8
kmode = 10 * math.pi
Tend = 0.1
J = round(1.0 / h)
tau = lam * h / a
u = [math.cos(kmode * (j - 1) * h) for j in range(J)]
nst = round(Tend / tau)
for _ in range(nst):
    un = u[:]
    for j in range(J):
        jm = J - 1 if j == 0 else j - 1
        un[j] = u[j] - lam * (u[j] - u[jm])
    u = un
amp = max(abs(v) for v in u)
nu = (a * h / 2) * (1 - lam)
pred = math.exp(-nu * kmode**2 * Tend)
rel = abs(amp - pred) / pred
assert rel < 5.0e-3, rel
print(f"Hirt: numerical amplitude = {amp:.6f}  modified-eq prediction = {pred:.6f}  rel diff = {rel:.2g}")

u = [math.cos(kmode * (j - 1) * h) for j in range(J)]
for _ in range(nst):
    un = u[:]
    for j in range(J):
        jp = 0 if j == J - 1 else j + 1
        un[j] = u[j] - lam * (u[jp] - u[j])
    u = un
print(f"Hirt (reversed): FTFS amplitude after same time = {max(abs(v) for v in u):.4f}  (negative diffusion)")

# ---------- (2) 矩阵法 ----------
Jm1 = 39
hh = 1 / (Jm1 + 1)
for r in (0.25, 0.49, 0.51, 5.0):
    main = np.full(Jm1, 1 - 2 * r)
    off = np.full(Jm1 - 1, r)
    ev = np.linalg.eigvalsh(np.diag(main) + np.diag(off, 1) + np.diag(off, -1))
    theory = np.sort(np.array([1 - 4 * r * math.sin(k * math.pi * hh / 2) ** 2 for k in range(1, Jm1 + 1)]))
    assert np.max(np.abs(ev - theory)) < 1.0e-9, r
print("matrix method: eigvals of FTCS growth matrix match 1-4r sin^2(k pi h/2) to 1e-9")

def rho(r):
    main = np.full(Jm1, 1 - 2 * r)
    off = np.full(Jm1 - 1, r)
    A = np.diag(main) + np.diag(off, 1) + np.diag(off, -1)
    return max(abs(np.linalg.eigvalsh(A)))

assert rho(0.5) < 1.0
assert rho(0.51) > 1.0
print(f"rho(A): r=0.5 -> {rho(0.5):.4f}; r=0.51 -> {rho(0.51):.4f} (>1)")

r5 = 5.0
B = np.diag(np.full(Jm1, 1 + 2 * r5)) + np.diag(np.full(Jm1 - 1, -r5), 1) + np.diag(np.full(Jm1 - 1, -r5), -1)
rhoB = max(abs(np.linalg.eigvalsh(np.linalg.inv(B))))
assert rhoB < 1.0
print(f"BTCS r=5: rho(B^-1) = {rhoB:.4f} < 1 (unconditionally stable)")

# ---------- (3) 能量法 ----------
def l2_evolve(lams, u0, nst):
    J = len(u0)
    u = list(u0)
    norms = [math.sqrt(sum(v * v for v in u))]
    for _ in range(nst):
        un = u[:]
        for j in range(J):
            jm = J - 1 if j == 0 else j - 1
            un[j] = (1 - lams[j]) * u[j] + lams[j] * u[jm]
        u = un
        norms.append(math.sqrt(sum(v * v for v in u)))
    return norms

uf = [math.sin(2 * math.pi * 5 * j / 64) + 0.3 * math.sin(2 * math.pi * 13 * j / 64) for j in range(64)]
norms = l2_evolve([0.9] * 64, uf, 50)
assert all(norms[i + 1] <= norms[i] + 1e-12 for i in range(len(norms) - 1))
print(f"energy method: l2 norm non-increasing for lambda=0.9 ({norms[0]:.3f} -> {norms[-1]:.3f})")

norms_bad = l2_evolve([1.05] * 64, uf, 50)
assert norms_bad[-1] > 2 * norms_bad[0]
print(f"lambda=1.05: l2 grows {norms_bad[0]:.3f} -> {norms_bad[-1]:.3f} (violating (4.19))")

hh2 = 1 / 64
ax = lambda x: 1 + 0.5 * x
tau2 = 0.9 * hh2 / max(ax(j * hh2) for j in range(65))
lams_var = [ax(j * hh2) * tau2 / hh2 for j in range(64)]
norms_var = l2_evolve(lams_var, uf, 50)
bound = (1 + 0.9 * 0.5 * hh2) ** 50
assert norms_var[-1] <= norms_var[0] * bound + 1e-10
print(f"a(x)=1+0.5x: growth {norms_var[-1]/norms_var[0]:.4f} <= telescoping bound {bound:.4f}")

print("END ====")
