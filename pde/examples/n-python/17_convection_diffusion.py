# 17_convection_diffusion.py —— 第 17 章：对流扩散（Python 通道，独立复算）

import math

print("==== 17 convection diffusion")

def central_cd(lam, mu, nst):
    J = 128
    u = [math.exp(-200 * ((j - 1) / J - 0.3) ** 2) for j in range(J)]
    for _ in range(nst):
        un = u[:]
        for j in range(J):
            jp = (j + 1) % J
            jm = (j - 1) % J
            un[j] = u[j] - 0.5 * lam * (u[jp] - u[jm]) + mu * (u[jp] - 2 * u[j] + u[jm])
        u = un
        if max(abs(v) for v in u) > 1e4:
            return 1e4
    return max(abs(v) for v in u)

assert central_cd(0.6, 0.4, 400) < 1.001
print(f"central: lam=0.6 mu=0.4 (lam^2 <= 2mu <= 1): max|u| = {central_cd(0.6, 0.4, 400):.4f}")
assert central_cd(0.6, 0.15, 400) > 1.01
print(f"central: lam=0.6 mu=0.15 (lam^2 > 2mu): max|u| = {central_cd(0.6, 0.15, 400):.4f}")

a, nu = 1.0, 0.05
Pe = a / nu
def uexact(x):
    return (math.exp(Pe * x) - math.exp(Pe)) / (1 - math.exp(Pe))

def thomas_v(aa, bb, cc, dd):
    n = len(bb)
    cp = [0.0] * n
    dp = [0.0] * n
    cp[0] = cc[0] / bb[0]
    dp[0] = dd[0] / bb[0]
    for i in range(1, n):
        m = bb[i] - aa[i] * cp[i - 1]
        cp[i] = cc[i] / m
        dp[i] = (dd[i] - aa[i] * dp[i - 1]) / m
    x = [0.0] * n
    x[n - 1] = dp[n - 1]
    for i in range(n - 2, -1, -1):
        x[i] = dp[i] - cp[i] * x[i + 1]
    return x

def steady(J, kind):
    h = 1.0 / J
    if kind == "center":
        al, be, ga = nu + 0.5 * a * h, 2 * nu, nu - 0.5 * a * h
    else:
        al, be, ga = nu + a * h, 2 * nu + a * h, nu
    n = J - 1
    aa = [-al] * n
    bb = [be] * n
    cc = [-ga] * n
    dd = [0.0] * n
    aa[0] = 0.0
    dd[0] = al
    cc[-1] = 0.0
    return [1.0] + thomas_v(aa, bb, cc, dd) + [0.0]

def is_monotone(u):
    d = [u[i + 1] - u[i] for i in range(len(u) - 1)]
    return all(x >= -1e-12 for x in d) or all(x <= 1e-12 for x in d)

pe_cell = a * (1 / 8) / nu
assert pe_cell > 2
uc = steady(8, "center")
uu = steady(8, "upwind")
print(f"pe = ah/nu = {pe_cell}: center monotone? {is_monotone(uc)}; upwind monotone? {is_monotone(uu)}")
assert not is_monotone(uc)
assert is_monotone(uu)

u50c = steady(50, "center")
u50u = steady(50, "upwind")
errc = max(abs(u50c[j] - uexact(j / 50)) for j in range(51))
erru = max(abs(u50u[j] - uexact(j / 50)) for j in range(51))
print(f"pe=1 (J=50): center err = {errc:.5f}, upwind err = {erru:.5f}")
assert errc < erru

print("END ====")
