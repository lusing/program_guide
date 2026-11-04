# 07_advection.py —— 第 07 章：迎风、LF、LW、BW（Python 通道，独立复算）

import math
import cmath

print("==== 07 advection")

def step_scheme(u, scheme, lam):
    J = len(u)
    jm = lambda j: J - 1 if j == 0 else j - 1
    jp = lambda j: 0 if j == J - 1 else j + 1
    un = u[:]
    for j in range(J):
        if scheme == "upwind":
            un[j] = u[j] - lam * (u[j] - u[jm(j)])
        elif scheme == "lf":
            un[j] = 0.5 * (u[jp(j)] + u[jm(j)]) - 0.5 * lam * (u[jp(j)] - u[jm(j)])
        elif scheme == "lw":
            un[j] = (u[j] - 0.5 * lam * (u[jp(j)] - u[jm(j)])
                     + 0.5 * lam**2 * (u[jp(j)] - 2 * u[j] + u[jm(j)]))
        elif scheme == "bw":
            un[j] = (u[j] - 0.5 * lam * (3 * u[j] - 4 * u[jm(j)] + u[jm(jm(j))])
                     + 0.5 * lam**2 * (u[j] - 2 * u[jm(j)] + u[jm(jm(j))]))
    return un

def run_scheme(scheme, g, lam, h, T):
    J = round(1.0 / h)
    u = [g((j - 1) * h) for j in range(J)]
    nst = round(T / (lam * h))
    for _ in range(nst):
        u = step_scheme(u, scheme, lam)
        if max(abs(v) for v in u) > 1e6:
            return u
    return u

gwave = lambda x: 1.0 if 0.3 < x < 0.6 else 0.0
h, lam, T = 0.005, 0.8, 0.5
print("--- book Fig 3.7 (h=0.005, lambda=0.8, T=0.5): square pulse ---")
res = {}
for scheme in ("upwind", "lf", "lw", "bw"):
    u = run_scheme(scheme, gwave, lam, h, T)
    res[scheme] = u
    print(f"  {scheme:8s} min = {min(u):.4f}  max = {max(u):.4f}")
assert min(res["upwind"]) >= -1e-12
assert min(res["lf"]) >= -1e-12
assert min(res["lw"]) < -0.05, "LW should oscillate"
assert min(res["bw"]) < -0.05, "BW should oscillate"
print("one-sided schemes monotone; LW/BW oscillate")

kmode = 8
gk = lambda x: math.sin(2 * math.pi * kmode * x)
J = 256
h2 = 1.0 / J
lam2 = 0.8
T2 = 0.5
nst2 = round(T2 / (lam2 * h2))

def amp_of(scheme):
    u = [gk((j - 1) * h2) for j in range(J)]
    for _ in range(nst2):
        u = step_scheme(u, scheme, lam2)
    z = sum(u[j] * cmath.exp(-2j * math.pi * kmode * j / J) for j in range(J))
    return abs(z) * 2 / J

amps = {s: amp_of(s) for s in ("upwind", "lf", "lw", "bw")}
for s, a in amps.items():
    print(f"  {s:8s} amplitude = {a:.4f}")
assert amps["lw"] > amps["lf"] and amps["lw"] > amps["upwind"]
print(f"amplitude ranking: lw = {amps['lw']:.4f} > lf = {amps['lf']:.4f}, upwind = {amps['upwind']:.4f}")

for lam3 in (0.8, 1.5, 1.9):
    u = run_scheme("bw", gk, lam3, h2, T2)
    assert max(abs(v) for v in u) < 1.5, lam3
u_bad = run_scheme("bw", gwave, 2.2, h2, T2)
assert max(abs(v) for v in u_bad) > 10, "BW lambda=2.2 should be unstable"
print(f"BW stability: lambda = 0.8/1.5/1.9 bounded; lambda = 2.2 max|u| = {max(abs(v) for v in u_bad):.3g}")

print("END ====")
