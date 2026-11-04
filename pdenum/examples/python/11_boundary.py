# 11_boundary.py —— 第 11 章：初边值与数值边界（Python 通道，独立复算）

import math

print("==== 11 boundary")

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

def wave_weighted_err(h, lam, T):
    J = round(1.0 / h) - 1
    tau = lam * h
    theta = 0.5
    nst = round(T / tau)
    u_prev = [math.sin(math.pi * j * h) for j in range(1, J + 1)]
    u = [math.cos(math.pi * tau) * math.sin(math.pi * j * h) for j in range(1, J + 1)]
    a3 = [-theta * lam**2] * J
    b3 = [1 + 2 * theta * lam**2] * J
    c3 = [-theta * lam**2] * J
    a3[0] = 0.0
    c3[J - 1] = 0.0
    for _ in range(nst - 1):
        rhs = [0.0] * J
        for j in range(J):
            ul = 0.0 if j == 0 else u[j - 1]
            ur = 0.0 if j == J - 1 else u[j + 1]
            d2n = ul - 2 * u[j] + ur
            ulp = 0.0 if j == 0 else u_prev[j - 1]
            urp = 0.0 if j == J - 1 else u_prev[j + 1]
            d2p = ulp - 2 * u_prev[j] + urp
            rhs[j] = 2 * u[j] - u_prev[j] + lam**2 * ((1 - 2 * theta) * d2n + theta * d2p)
        un = thomas(a3, b3, c3, rhs)
        u_prev, u = u, un
    tf = nst * tau
    uex = [math.cos(math.pi * tf) * math.sin(math.pi * j * h) for j in range(1, J + 1)]
    return max(abs(x - y) for x, y in zip(u, uex))

e1 = wave_weighted_err(2.0e-2, 2.0, 0.5)
e2 = wave_weighted_err(1.0e-2, 2.0, 0.5)
r = e1 / e2
assert 3.4 < r < 4.5, r
print(f"weighted implicit theta=1/2 at lam=2: h->h/2 error ratio = {r:.3f} (2nd order)")

def leapfrog_bc(bckind, nst):
    J = 200
    h = 1.0 / J
    lam = 0.8
    g = lambda x: math.exp(-100 * (x - 0.4) ** 2) + 1.0e-3 * math.sin(math.pi * x / h)
    u0 = [g((j - 1) * h) for j in range(1, J + 1)]
    u0[0] = 0.0
    u1 = [u0[j] - 0.5 * lam * ((0.0 if j == J - 1 else u0[j + 1])
                               - (0.0 if j == 0 else u0[j - 1])) for j in range(J)]
    up, uc = u0[:], u1[:]
    for _ in range(2, nst + 1):
        un = uc[:]
        for j in range(1, J - 1):
            un[j] = up[j] - lam * (uc[j + 1] - uc[j - 1])
        un[0] = 0.0
        if bckind == "extrap":
            un[J - 1] = 2 * un[J - 2] - un[J - 3]
        else:
            un[J - 1] = uc[J - 1] - lam * (uc[J - 1] - uc[J - 2])
        up, uc = uc, un
        if max(abs(v) for v in uc) > 1e8:
            return 1e8
    return max(abs(v) for v in uc)

long_ex = leapfrog_bc("extrap", 4000)
long_up = leapfrog_bc("upwind", 4000)
print(f"leapfrog + extrapolation BC: 4000 steps max|u| = {long_ex:.3g}")
print(f"leapfrog + upwind BC:        4000 steps max|u| = {long_up:.3g}")
assert long_ex > 1.0
assert long_up < 0.01

def boundary_count(a, side):
    return (1 if a > 0 else 0) if side == "left" else (0 if a > 0 else 1)

assert boundary_count(1.0, "left") == 1 and boundary_count(1.0, "right") == 0
print("a>0: 1 condition at inflow x=0, 0 at outflow x=1")

print("END ====")
