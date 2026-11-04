# 20_nonlinear.py —— 第 20 章：非线性抛物（Python 通道，独立复算）

import math

print("==== 20 nonlinear")

ustar = lambda x, t: math.exp(-t) * math.sin(math.pi * x)

def fsource(x, t):
    ut = -math.exp(-t) * math.sin(math.pi * x)
    ux = math.exp(-t) * math.pi * math.cos(math.pi * x)
    kus = 1 + ustar(x, t) ** 2
    dkus = 2 * ustar(x, t) * ux
    return ut - (dkus * ux + kus * (-math.exp(-t) * math.pi**2 * math.sin(math.pi * x)))

def thomas(a, b, c, d):
    n = len(b)
    cp = [0.0] * n; dp = [0.0] * n
    cp[0] = c[0] / b[0]; dp[0] = d[0] / b[0]
    for i in range(1, n):
        m = b[i] - a[i] * cp[i - 1]
        cp[i] = c[i] / m
        dp[i] = (d[i] - a[i] * dp[i - 1]) / m
    x = [0.0] * n
    x[n - 1] = dp[n - 1]
    for i in range(n - 2, -1, -1):
        x[i] = dp[i] - cp[i] * x[i + 1]
    return x

def semi_implicit(h, T):
    J = round(1.0 / h) - 1
    r = 0.4
    tau = r * h * h
    nst = round(T / tau)
    u = [math.sin(math.pi * j * h) for j in range(1, J + 1)]
    for n in range(nst):
        t = n * tau
        kold = [1 + v * v for v in u]
        aa = [0.0] * J; bb = [0.0] * J; cc = [0.0] * J; dd = [0.0] * J
        for j in range(J):
            kL = 0.5 * (kold[max(j - 1, 0)] + kold[j])
            kR = 0.5 * (kold[j] + kold[min(j + 1, J - 1)])
            aa[j] = -r * kL
            bb[j] = 1 + r * (kL + kR)
            cc[j] = -r * kR
            dd[j] = u[j] + tau * fsource((j + 1) * h, t)
        aa[0] = 0.0
        cc[J - 1] = 0.0
        u = thomas(aa, bb, cc, dd)
    tf = nst * tau
    return max(abs(u[j] - ustar((j + 1) * h, tf)) for j in range(J))

e1, e2 = semi_implicit(0.05, 0.5), semi_implicit(0.025, 0.5)
r20 = e1 / e2
assert 3.0 < r20 < 4.6, (e1, e2, r20)
print(f"Richtmyer linearized semi-implicit: h->h/2 ratio = {r20:.3f}")

def predictor_corrector(h, T):
    J = round(1.0 / h) - 1
    r = 0.05
    tau = r * h * h
    nst = round(T / tau)
    u = [math.sin(math.pi * j * h) for j in range(1, J + 1)]
    for n in range(nst):
        t = n * tau
        pred = u[:]
        for j in range(J):
            ul = 0.0 if j == 0 else u[j - 1]
            ur = 0.0 if j == J - 1 else u[j + 1]
            kL = 1 + ul * ul; kR = 1 + ur * ur
            km = 0.5 * (kL + 1 + u[j] ** 2)
            kp = 0.5 * (1 + u[j] ** 2 + kR)
            fl = km * (u[j] - ul) / h
            fr = kp * (ur - u[j]) / h
            pred[j] = u[j] + tau * ((fr - fl) / h + fsource((j + 1) * h, t))
        un = u[:]
        for j in range(J):
            ul = 0.0 if j == 0 else pred[j - 1]
            ur = 0.0 if j == J - 1 else pred[j + 1]
            kL = 1 + ul * ul; kR = 1 + ur * ur
            km = 0.5 * (kL + 1 + pred[j] ** 2)
            kp = 0.5 * (1 + pred[j] ** 2 + kR)
            fl = km * (pred[j] - ul) / h
            fr = kp * (ur - pred[j]) / h
            un[j] = u[j] + tau * ((fr - fl) / h + fsource((j + 1) * h, t + tau / 2))
        u = un
    tf = nst * tau
    return max(abs(u[j] - ustar((j + 1) * h, tf)) for j in range(J))

e1, e2 = predictor_corrector(0.05, 0.5), predictor_corrector(0.025, 0.5)
r20b = e1 / e2
assert 3.0 < r20b < 4.6, (e1, e2, r20b)
assert e2 < 0.01, e2
print(f"predictor-corrector: h->h/2 ratio = {r20b:.3f}")

print("END ====")
