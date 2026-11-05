# 14_diffusion.py —— 第 14 章：加权隐式家族（Python 通道，独立复算）

import math

print("==== 14 diffusion")

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

def weighted_solve(theta, lam, T):
    J = 10
    h = 1.0 / J
    tau = lam * h * h
    nst = round(T / tau)
    u = [math.sin(math.pi * j * h) for j in range(1, J)]
    a3 = [-lam * theta] * (J - 1)
    b3 = [1 + 2 * lam * theta] * (J - 1)
    c3 = [-lam * theta] * (J - 1)
    a3[0] = 0.0
    c3[-1] = 0.0
    for _ in range(nst):
        rhs = [0.0] * (J - 1)
        for j in range(J - 1):
            ul = 0.0 if j == 0 else u[j - 1]
            ur = 0.0 if j == J - 2 else u[j + 1]
            rhs[j] = u[j] + (1 - theta) * lam * (ul - 2 * u[j] + ur)
        u = thomas(a3, b3, c3, rhs)
        if max(abs(v) for v in u) > 1e10:
            return u
    return u

def table41(lam):
    v0 = weighted_solve(0.0, lam, 0.4)[3]
    v1 = weighted_solve(1.0, lam, 0.4)[3]
    vc = weighted_solve(0.5, lam, 0.4)[3]
    return v0, v1, vc

booktab = {0.25: (0.0180544, 0.0198705, 0.0189519),
           1.0: (None, 0.0226935, 0.0188963),
           2.0: (None, 0.0266211, 0.0187186),
           4.0: (None, 0.0349321, 0.0180093)}
print("lambda    theta=0     theta=1     theta=1/2")
for lam in (0.25, 0.5, 1.0, 2.0, 4.0, 8.0):
    v0, v1, vc = table41(lam)
    print(f"{lam:<8}  {v0:<12.7g}{v1:<12.7g}{vc:.7g}")
for lam, (b0, b1, bc) in booktab.items():
    v0, v1, vc = table41(lam)
    if b0 is not None:
        assert abs(v0 - b0) < 2e-6, (lam, v0, b0)
    assert abs(v1 - b1) < 2e-6, (lam, v1, b1)
    assert abs(vc - bc) < 2e-6, (lam, vc, bc)
assert table41(1.0)[0] > 1.0
print("clean rows match book Table 4.1 to 2e-6 (rows 0.5/8: column shift in book)")
_, v1_8, cn_8 = table41(8.0)
assert abs(v1_8 - 0.0183519) / 0.0183519 > 0.8
assert abs(cn_8 - 0.0183519) / 0.0183519 > 0.1

def cn_err(h):
    r, T = 0.4, 0.4
    J = round(1.0 / h)
    tau = r * h * h
    nst = round(T / tau)
    u = [math.sin(math.pi * j * h) for j in range(1, J)]
    a3 = [-r / 2] * (J - 1)
    b3 = [1 + r] * (J - 1)
    c3 = [-r / 2] * (J - 1)
    a3[0] = 0.0
    c3[-1] = 0.0
    for _ in range(nst):
        rhs = [0.0] * (J - 1)
        for j in range(J - 1):
            ul = 0.0 if j == 0 else u[j - 1]
            ur = 0.0 if j == J - 2 else u[j + 1]
            rhs[j] = u[j] + (r / 2) * (ul - 2 * u[j] + ur)
        u = thomas(a3, b3, c3, rhs)
    tf = nst * tau
    return max(abs(u[j] - math.exp(-math.pi**2 * tf) * math.sin(math.pi * (j + 1) * h))
               for j in range(J - 1))

e1, e2 = cn_err(0.1), cn_err(0.05)
r_ratio = e1 / e2
assert 3.5 < r_ratio < 4.5, r_ratio
print(f"CN convergence (r=0.4 fixed): h->h/2 error ratio = {r_ratio:.3f}")

def maxG(theta, r):
    return max(abs(1 - 4 * (1 - theta) * r * s2) / (1 + 4 * theta * r * s2)
               for s2 in [0.001 + 0.01 * k for k in range(100)])

for theta in (0.5, 0.75, 1.0):
    for r in (0.5, 5.0, 100.0):
        assert maxG(theta, r) <= 1.0 + 1e-12, (theta, r)
assert maxG(0.4, 2.0) <= 1.0 + 1e-12
assert maxG(0.4, 3.0) > 1.0
assert maxG(0.0, 0.5) <= 1.0 + 1e-12
assert maxG(0.0, 0.51) > 1.0
print("weighted implicit: |G| scan confirms 2r(1-2theta) <= 1; theta>=1/2 unconditional")

print("END ====")
