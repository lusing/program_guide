# 18_variable.py —— 第 18 章：变系数/界面/Keller 盒式（Python 通道，独立复算）

import math

print("==== 18 variable")

kfun = lambda x: 1 + 0.5 * x

def source(x, t):
    et = math.exp(-t)
    return (-et * math.sin(math.pi * x)
            - et * math.pi * (0.5 * math.cos(math.pi * x) - kfun(x) * math.pi * math.sin(math.pi * x)))

def varcoef_ftcs(h, T):
    J = round(1.0 / h)
    tau = 0.4 * h * h / max(kfun(j * h) for j in range(J + 1))
    nst = round(T / tau)
    u = [math.sin(math.pi * j * h) for j in range(J + 1)]
    for n in range(nst):
        t = n * tau
        un = u[:]
        for j in range(1, J):
            xj = j * h
            fr = 0.5 * (kfun(xj) + kfun(xj + h)) * (u[j + 1] - u[j]) / h
            fl = 0.5 * (kfun(xj - h) + kfun(xj)) * (u[j] - u[j - 1]) / h
            un[j] = u[j] + tau * ((fr - fl) / h + source(xj, t))
        u = un
    tf = nst * tau
    return max(abs(u[j] - math.exp(-tf) * math.sin(math.pi * j * h)) for j in range(1, J))

e1, e2 = varcoef_ftcs(0.05, 0.5), varcoef_ftcs(0.025, 0.5)
r = e1 / e2
assert 3.0 < r < 4.6, r
print(f"variable-k FTCS: h->h/2 ratio = {r:.3f}")

k1, k2 = 1.0, 10.0
q_exact = 1.0 / (0.5 / k1 + 0.5 / k2)
def uexact_disc(x):
    return q_exact * x / k1 if x <= 0.5 else q_exact * (0.5 / k1 + (x - 0.5) / k2)

def kmat(x):
    return k1 if x < 0.5 else k2

def kface(xf):
    kl, kr = kmat(xf - 1e-9), kmat(xf + 1e-9)
    return kl if kl == kr else 2 * kl * kr / (kl + kr)

def steady_fv(J):
    h = 1.0 / J
    n = J - 1
    aa = [0.0] * n; bb = [0.0] * n; cc = [0.0] * n; dd = [0.0] * n
    for j in range(1, n + 1):
        kL = kface(j * h - h / 2)
        kR = kface(j * h + h / 2)
        aa[j - 1] = -kL
        bb[j - 1] = kL + kR
        cc[j - 1] = -kR
    aa[0] = 0.0
    cc[n - 1] = 0.0
    dd[n - 1] = kface(1 - h / 2) * 1.0
    cp = [0.0] * n; dp = [0.0] * n
    cp[0] = cc[0] / bb[0]; dp[0] = dd[0] / bb[0]
    for i in range(1, n):
        m = bb[i] - aa[i] * cp[i - 1]
        cp[i] = cc[i] / m
        dp[i] = (dd[i] - aa[i] * dp[i - 1]) / m
    x = [0.0] * n
    x[n - 1] = dp[n - 1]
    for i in range(n - 2, -1, -1):
        x[i] = dp[i] - cp[i] * x[i + 1]
    return [0.0] + x + [1.0]

for J in (10, 40, 160):
    u = steady_fv(J)
    err = max(abs(u[j] - uexact_disc(j / J)) for j in range(J + 1))
    print(f"FV harmonic-face J={J}: err = {err:.2e}, u(0.5) = {u[J // 2]:.5f}")
    if J == 160:
        assert err < 1e-3, err

def keller_box(J):
    h = 1.0 / J
    n = J - 1
    aa = [-1.0 / h**2] * n; bb = [2.0 / h**2 + 1.0] * n; cc = [-1.0 / h**2] * n
    dd = [(1 + math.pi**2) * math.sin(math.pi * j * h) for j in range(1, J)]
    cp = [0.0] * n; dp = [0.0] * n
    cp[0] = cc[0] / bb[0]; dp[0] = dd[0] / bb[0]
    for i in range(1, n):
        m = bb[i] - aa[i] * cp[i - 1]
        cp[i] = cc[i] / m
        dp[i] = (dd[i] - aa[i] * dp[i - 1]) / m
    x = [0.0] * n
    x[n - 1] = dp[n - 1]
    for i in range(n - 2, -1, -1):
        x[i] = dp[i] - cp[i] * x[i + 1]
    return max(abs(x[j] - math.sin(math.pi * (j + 1) * h)) for j in range(n))

e1, e2 = keller_box(20), keller_box(40)
rk = e1 / e2
assert rk > 3.5, rk
print(f"box-scheme compact form O(h^2): ratio = {rk:.3f}")

print("END ====")
