# 04_ccs.py —— 第 04 章：相容/收敛/稳定（Python 通道，独立复算）

import math

print("==== 04 ccs")

def advect(scheme, g, lam, h, nsteps):
    J = round(1.0 / h)
    u = [g((j - 1) * h) for j in range(J)]
    jm = lambda j: J - 1 if j == 0 else j - 1
    jp = lambda j: 0 if j == J - 1 else j + 1
    for _ in range(nsteps):
        un = u[:]
        for j in range(J):
            if scheme == "ftbs":
                un[j] = u[j] - lam * (u[j] - u[jm(j)])
            elif scheme == "ftfs":
                un[j] = u[j] - lam * (u[jp(j)] - u[j])
            elif scheme == "ftcs":
                un[j] = u[j] - lam * 0.5 * (u[jp(j)] - u[jm(j)])
            elif scheme == "lf":
                un[j] = 0.5 * (u[jp(j)] + u[jm(j)]) - lam * 0.5 * (u[jp(j)] - u[jm(j)])
        u = un
        if max(abs(v) for v in u) > 1e8:
            return u
    return u

g0 = lambda x: math.exp(-100 * (x - 0.5) ** 2)
def adv_err(scheme, g, lam, h, Tend):
    nst = round(Tend / (lam * h))
    J = round(1.0 / h)
    u = advect(scheme, g, lam, h, nst)
    uex = [g(((j - 1) * h - Tend) % 1.0) for j in range(J)]
    return max(abs(a - b) for a, b in zip(u, uex))

# ---------- (1) 稳定性的本义：θ=π/2 模式扰动的传播 ----------
def perturb_growth(scheme, lam, h, nsteps):
    J = round(1.0 / h)
    eps0 = 1.0e-6
    u = [eps0 * math.sin(math.pi * (j - 1) / 2) for j in range(J)]
    jm = lambda j: J - 1 if j == 0 else j - 1
    jp = lambda j: 0 if j == J - 1 else j + 1
    for _ in range(nsteps):
        un = u[:]
        for j in range(J):
            if scheme == "ftbs":
                un[j] = u[j] - lam * (u[j] - u[jm(j)])
            else:
                un[j] = u[j] - lam * 0.5 * (u[jp(j)] - u[jm(j)])
        u = un
    return max(abs(v) for v in u) / eps0

h, lam = 0.01, 0.8
n = round(0.4 / (lam * h))
grow_ftbs = perturb_growth("ftbs", lam, h, n)
grow_ftcs = perturb_growth("ftcs", lam, h, n)
print(f"theta=pi/2 mode perturbation after n = {n} steps:")
print(f"  FTBS (lambda=0.8): amplitude ratio = {grow_ftbs:.3g}")
print(f"  FTCS:             amplitude ratio = {grow_ftcs:.3g}")
assert grow_ftbs < 1.0e-3, "stable scheme should damp the perturbation"
assert grow_ftcs > 100.0, "unstable scheme should amplify exponentially"

e1 = adv_err("ftbs", g0, 0.8, 2.0e-2, 0.4)
e2 = adv_err("ftbs", g0, 0.8, 1.0e-2, 0.4)
assert 1.7 < e1 / e2 < 2.3, f"FTBS should be 1st order (ratio {e1/e2})"
print(f"FTBS (stable): h->h/2 error ratio = {e1/e2:.3f}  (convergent)")

# ---------- (2) FTCS 热传导：条件不可省 ----------
def heat_err(h, r, Tend):
    J = round(1.0 / h) - 1
    tau = r * h * h
    u = [math.sin(math.pi * j * h) for j in range(1, J + 1)]
    nst = round(Tend / tau)
    for _ in range(nst):
        un = u[:]
        for j in range(J):
            ul = 0.0 if j == 0 else u[j - 1]
            ur = 0.0 if j == J - 1 else u[j + 1]
            un[j] = u[j] + r * (ul - 2 * u[j] + ur)
        u = un
        if max(abs(v) for v in u) > 1e8:
            return 1e8
    t = nst * tau
    uex = [math.exp(-math.pi**2 * t) * math.sin(math.pi * j * h) for j in range(1, J + 1)]
    return max(abs(a - b) for a, b in zip(u, uex))

e_stable = heat_err(0.01, 0.25, 0.1)
e_unstable = heat_err(0.01, 0.6, 0.1)
assert e_stable < 1e-4, "r=0.25 error should be O(h^2)"
assert e_unstable > 1e3, "r=0.6 should blow up"
print(f"FTCS heat: r=0.25 error = {e_stable:.3g}; r=0.6 error = {e_unstable:g} (condition indispensable)")

# ---------- (3) 书图 2.11 的数字版：Lax-Friedrichs ----------
print("--- Lax-Friedrichs (book Fig 2.11): lambda = 0.9 / 1.0 / 1.1 ---")
gsq = lambda x: 1.0 if 0.25 < x < 0.75 else 0.0
for lam2 in (0.9, 1.0, 1.1):
    u = advect("lf", gsq, lam2, 0.02, 40)
    print(f"  lambda = {lam2}  max|u| after 40 steps = {max(abs(v) for v in u):.4f}")
u9 = advect("lf", gsq, 0.9, 0.02, 40)
u10 = advect("lf", gsq, 1.0, 0.02, 40)
u11 = advect("lf", gsq, 1.1, 0.02, 40)
assert max(abs(v) for v in u9) <= 1.0 + 1e-10
assert max(abs(v) for v in u10) <= 1.0 + 1e-10
assert max(abs(v) for v in u11) > 5, "lambda=1.1 should grow"
print(f"LF: lambda<=1 bounded; lambda=1.1 grows to {max(abs(v) for v in u11):.1f}")

# ---------- (4) 收敛阶 = 精度组合 ----------
def thomas(a, b, c, d):
    n = len(b)
    cp = [0.0] * n
    dp = [0.0] * n
    cp[0] = c[0] / b[0]
    dp[0] = d[0] / b[0]
    for i in range(1, n):
        m = b[i] - a[i] * cp[i - 1]
        cp[i] = c[i] / m
        dp[i] = (d[i] - a[i] * dp[i - 1]) / m
    x = [0.0] * n
    x[n - 1] = dp[n - 1]
    for i in range(n - 2, -1, -1):
        x[i] = dp[i] - cp[i] * x[i + 1]
    return x

def heat_btcs_err_tau(h, tau, Tend):
    J = round(1.0 / h) - 1
    r = tau / h**2
    u = [math.sin(math.pi * j * h) for j in range(1, J + 1)]
    nst = round(Tend / tau)
    a = [-r] * J
    b = [1 + 2 * r] * J
    c = [-r] * J
    a[0] = 0.0
    c[J - 1] = 0.0
    for _ in range(nst):
        u = thomas(a, b, c, u)
    t = nst * tau
    uex = [math.exp(-math.pi**2 * t) * math.sin(math.pi * j * h) for j in range(1, J + 1)]
    return max(abs(x - y) for x, y in zip(u, uex))

ea = heat_btcs_err_tau(2.0e-2, 2.0e-2, 0.1)
eb = heat_btcs_err_tau(1.0e-2, 1.0e-2, 0.1)
ratio1 = ea / eb
assert 1.7 < ratio1 < 2.3, f"tau=h should give 1st order (ratio {ratio1})"
print(f"BTCS with tau=h:     h->h/2 error ratio = {ratio1:.3f}  (1st order)")

ea = heat_btcs_err_tau(2.0e-2, 5 * 2.0e-2**2, 0.1)
eb = heat_btcs_err_tau(1.0e-2, 5 * 1.0e-2**2, 0.1)
ratio2 = ea / eb
assert 3.5 < ratio2 < 4.5, f"tau=5h^2 should give 2nd order (ratio {ratio2})"
print(f"BTCS with tau=5h^2:  h->h/2 error ratio = {ratio2:.3f}  (2nd order)")

# ---------- (5) FTFS(a>0)：依赖域错配 ----------
print("--- FTFS (a>0): dependence-domain mismatch ---")
gbump = lambda x: math.exp(-((x - 0.2) / 0.01) ** 2)
g1f = lambda x: math.exp(-100 * (x - 0.5) ** 2)
g2f = lambda x: g1f(x) + gbump(x)
xstar, tstar = 0.6, 0.4
for h2 in (4.0e-2, 2.0e-2, 1.0e-2, 5.0e-3):
    nst = round(tstar / (0.8 * h2))
    jstar = round(xstar / h2)
    u1 = advect("ftfs", g1f, 0.8, h2, nst)
    u2 = advect("ftfs", g2f, 0.8, h2, nst)
    ev1 = abs(u1[jstar] - g1f((xstar - tstar) % 1.0))
    ev2 = abs(u2[jstar] - g2f((xstar - tstar) % 1.0))
    print(f"  h = {h2}  e(g1) = {ev1:.3g}  e(g2) = {ev2:.3g}  sum = {ev1+ev2:.3g}")
    assert ev1 + ev2 > 0.9, "two exact solutions differ by ~1; FTFS cannot converge for both"

print("END ====")
