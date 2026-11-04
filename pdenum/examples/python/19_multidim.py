# 19_multidim.py —— 第 19 章：二维热传导 ADI/LOD（Python 通道，独立复算）

import math

print("==== 19 multidim")

def ftcs2d(r, nst):
    N = 64
    u = [[math.sin(math.pi * i / N) * math.sin(math.pi * j / N)
          + 1.0e-6 * ((-1.0) ** (i + j)) for j in range(1, N)] for i in range(1, N)]
    for _ in range(nst):
        un = [[0.0] * (N - 1) for _ in range(N - 1)]
        for i in range(N - 1):
            for j in range(N - 1):
                ul = 0.0 if i == 0 else u[i - 1][j]
                ur = 0.0 if i == N - 2 else u[i + 1][j]
                ud = 0.0 if j == 0 else u[i][j - 1]
                uu = 0.0 if j == N - 2 else u[i][j + 1]
                un[i][j] = u[i][j] + r * (ul + ur + ud + uu - 4 * u[i][j])
        u = un
        if max(abs(v) for row in u for v in row) > 1e6:
            return 1e6
    return max(abs(v) for row in u for v in row)

assert ftcs2d(0.24, 400) < 1.001
assert ftcs2d(0.26, 400) > 10
print("2D FTCS: r=0.24 stable, r=0.26 blows (condition r <= 1/4)")

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

def adi_err(h, rr):
    J = round(1.0 / h) - 1
    r = rr
    tau = r * h * h
    T = 0.1
    nst = round(T / tau)
    u = [[math.sin(math.pi * i * h) * math.sin(math.pi * j * h) for j in range(1, J + 1)]
         for i in range(1, J + 1)]
    a = [-r / 2] * J
    b = [1 + r] * J
    c = [-r / 2] * J
    a[0] = 0.0
    c[J - 1] = 0.0
    for _ in range(nst):
        half = [[0.0] * J for _ in range(J)]
        for j in range(J):
            d = [(1 - r) * u[i][j]
                 + (r / 2) * ((0.0 if i == 0 else u[i - 1][j])
                              + (0.0 if i == J - 1 else u[i + 1][j])) for i in range(J)]
        # 注意：上面 d 在 i 的列表推导里引用 u —— 半步 1 为 x 方向
            col = thomas(a, b, c, d)
            for i in range(J):
                half[i][j] = col[i]
        for i in range(J):
            d = [(1 - r) * half[i][j]
                 + (r / 2) * ((0.0 if j == 0 else half[i][j - 1])
                              + (0.0 if j == J - 1 else half[i][j + 1])) for j in range(J)]
            row = thomas(a, b, c, d)
            u[i] = row[:]
    tf = nst * tau
    return max(abs(u[i][j] - math.exp(-2 * math.pi**2 * tf) * math.sin(math.pi * (i + 1) * h)
                   * math.sin(math.pi * (j + 1) * h)) for i in range(J) for j in range(J))

e1 = adi_err(0.05, 1.0)
e2 = adi_err(0.025, 1.0)
r19 = e1 / e2
assert 3.4 < r19 < 4.6, (e1, e2, r19)
print(f"PR-ADI (r=1): h->h/2 ratio = {r19:.3f}")
u5 = adi_err(0.05, 5.0)
assert u5 < 0.05, u5
print(f"PR-ADI at r=5 (explicit-forbidden): stable, err = {u5:.4f}")

def lod_err(h):
    J = round(1.0 / h) - 1
    r = 5.0
    tau = r * h * h
    T = 0.1
    nst = round(T / tau)
    u = [[math.sin(math.pi * i * h) * math.sin(math.pi * j * h) for j in range(1, J + 1)]
         for i in range(1, J + 1)]
    a = [-r] * J
    b = [1 + 2 * r] * J
    c = [-r] * J
    a[0] = 0.0
    c[J - 1] = 0.0
    for _ in range(nst):
        for j in range(J):
            col = thomas(a, b, c, [u[i][j] for i in range(J)])
            for i in range(J):
                u[i][j] = col[i]
        for i in range(J):
            row = thomas(a, b, c, u[i][:])
            u[i] = row[:]
    tf = nst * tau
    return max(abs(u[i][j] - math.exp(-2 * math.pi**2 * tf) * math.sin(math.pi * (i + 1) * h)
                   * math.sin(math.pi * (j + 1) * h)) for i in range(J) for j in range(J))

e1 = lod_err(0.05)
e2 = lod_err(0.025)
print(f"LOD (BTCS split, r=5): err(0.05) = {e1:.6f}, ratio = {e1/e2:.3f}")
assert e2 < 5e-3, e2

print("END ====")
