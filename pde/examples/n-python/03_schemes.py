# 03_schemes.py —— 第 03 章：差分格式的构造（Python 通道，独立复算）

import math

print("==== 03 schemes")

# ---------- (1) 差商精度表 ----------
f = lambda x: math.sin(x)
df = lambda x: math.cos(x)
d2f = lambda x: -math.sin(x)

fwd_err = lambda h: abs((f(1 + h) - f(1)) / h - df(1))
bwd_err = lambda h: abs((f(1) - f(1 - h)) / h - df(1))
ctr_err = lambda h: abs((f(1 + h) - f(1 - h)) / (2 * h) - df(1))
sec_err = lambda h: abs((f(1 + h) - 2 * f(1) + f(1 - h)) / h**2 - d2f(1))

def measured_order(fn, h1, h2):
    return math.log(fn(h1) / fn(h2)) / math.log(h1 / h2)

orders = [measured_order(fn, 1.0e-2, 5.0e-3) for fn in (fwd_err, bwd_err, ctr_err, sec_err)]
for name, o in zip(("forward", "backward", "central", "2nd-central"), orders):
    print(f"{name} difference: measured order = {o:.3f}")
assert all(0.9 < o < 1.1 for o in orders[:2]), "forward/backward should be 1st order"
assert all(1.9 < o < 2.1 for o in orders[2:]), "central/2nd-central should be 2nd order"

# ---------- (2) 对流方程三格式 ----------
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
        u = un
        if max(abs(v) for v in u) > 1e6:
            return u
    return u

g0 = lambda x: math.exp(-100 * (x - 0.5) ** 2)
h, Tend, lam = 0.01, 0.4, 0.8
nst = round(Tend / (lam * h))
J = round(1.0 / h)
u_ex = [g0(((j - 1) * h - Tend) % 1.0) for j in range(J)]
u_num = advect("ftbs", g0, lam, h, nst)
err1 = max(abs(a - b) for a, b in zip(u_num, u_ex))
print(f"FTBS advection lambda=0.8: max error = {err1:.3g}")

def ftbs_err(h):
    nst = round(Tend / (lam * h))
    J = round(1.0 / h)
    u_num = advect("ftbs", g0, lam, h, nst)
    u_ex = [g0(((j - 1) * h - Tend) % 1.0) for j in range(J)]
    return max(abs(a - b) for a, b in zip(u_num, u_ex))

e1, e2 = ftbs_err(2.0e-2), ftbs_err(1.0e-2)
ratio = e1 / e2
assert 1.7 < ratio < 2.3, f"FTBS should be 1st order (ratio {ratio})"
print(f"FTBS convergence: h->h/2 error ratio = {ratio:.3f}  (1st order)")

u_ftcs = advect("ftcs", g0, 1.0, h, 6 * nst)
u_ftfs = advect("ftfs", g0, 1.0, h, 6 * nst)
assert max(abs(v) for v in u_ftcs) > 10, "FTCS-advection should be unstable"
assert max(abs(v) for v in u_ftfs) > 10, "FTFS(a>0) should be unstable"
print("FTCS-advection and FTFS(a>0): max|u| blows past 10 (unstable)")

# ---------- (3) 扩散方程显式 FTCS ----------
def heat_ftcs_err(h, r, Tend):
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
    t = nst * tau
    u_ex = [math.exp(-math.pi**2 * t) * math.sin(math.pi * j * h) for j in range(1, J + 1)]
    return max(abs(a - b) for a, b in zip(u, u_ex))

e1 = heat_ftcs_err(2.0e-2, 0.25, 0.1)
e2 = heat_ftcs_err(1.0e-2, 0.25, 0.1)
ratio = e1 / e2
assert 3.5 < ratio < 4.5, f"FTCS heat should be O(h^2) (ratio {ratio})"
print(f"FTCS heat r=0.25: h->h/2 error ratio = {ratio:.3f}  (2nd order)")

def heat_ftcs_max(h, r, nst):
    J = round(1.0 / h) - 1
    u = [math.sin(math.pi * j * h) for j in range(1, J + 1)]
    for _ in range(nst):
        un = u[:]
        for j in range(J):
            ul = 0.0 if j == 0 else u[j - 1]
            ur = 0.0 if j == J - 1 else u[j + 1]
            un[j] = u[j] + r * (ul - 2 * u[j] + ur)
        u = un
        if max(abs(v) for v in u) > 1e6:
            return 1e6
    return max(abs(v) for v in u)

assert heat_ftcs_max(0.02, 0.6, 200) > 10, "r=0.6 should be unstable"
print("FTCS heat r=0.6: unstable (max|u| exceeds 10)")

# ---------- (4) 隐式 BTCS + 追赶法 ----------
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

def heat_btcs_err(h, r, Tend):
    J = round(1.0 / h) - 1
    tau = r * h * h
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
    u_ex = [math.exp(-math.pi**2 * t) * math.sin(math.pi * j * h) for j in range(1, J + 1)]
    return max(abs(x - y) for x, y in zip(u, u_ex))

e1 = heat_btcs_err(2.0e-2, 5.0, 0.1)
e2 = heat_btcs_err(1.0e-2, 5.0, 0.1)
ratio = e1 / e2
assert 3.5 < ratio < 4.5, f"BTCS should be O(h^2) (ratio {ratio})"
print(f"BTCS heat r=5: h->h/2 error ratio = {ratio:.3f}  (2nd order, unconditionally stable)")

print("END ====")
