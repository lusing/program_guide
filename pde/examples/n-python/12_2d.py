# 12_2d.py —— 第 12 章：二维问题与分数步长法（Python 通道，独立复算）

import math

print("==== 12 2d")

def lf2d_run(lam, nst):
    N = 64
    h = 1.0 / N
    u = [[math.exp(-100 * ((i - 1) * h - 0.5) ** 2 - 100 * ((j - 1) * h - 0.5) ** 2)
          + 1.0e-8 * math.sin(math.pi * (i - 1) / 2) * math.sin(math.pi * (j - 1) / 2)
          for j in range(1, N + 1)] for i in range(1, N + 1)]
    for _ in range(nst):
        un = [[0.0] * N for _ in range(N)]
        for i in range(N):
            for j in range(N):
                im = N - 1 if i == 0 else i - 1
                ip = 0 if i == N - 1 else i + 1
                jm = N - 1 if j == 0 else j - 1
                jp = 0 if j == N - 1 else j + 1
                un[i][j] = (0.25 * (u[ip][j] + u[im][j] + u[i][jp] + u[i][jm])
                            - 0.5 * lam * (u[ip][j] - u[im][j])
                            - 0.5 * lam * (u[i][jp] - u[i][jm]))
        u = un
        if max(abs(v) for row in u for v in row) > 1e6:
            return 1e6
    return max(abs(v) for row in u for v in row)

assert lf2d_run(0.45, 300) < 1.001
print(f"2D LF lam=0.45: stable (max|u| = {lf2d_run(0.45, 300):.4f})")
assert lf2d_run(0.55, 300) > 10
print(f"2D LF lam=0.55: unstable (max|u| = {lf2d_run(0.55, 300):.3g})")

def lod_lw2d(lam, h, T):
    N = round(1.0 / h)
    nst = round(T / (lam * h))
    u = [[math.exp(-100 * ((i - 1) * h - 0.5) ** 2 - 100 * ((j - 1) * h - 0.5) ** 2)
          for j in range(1, N + 1)] for i in range(1, N + 1)]
    for _ in range(nst):
        half = [[0.0] * N for _ in range(N)]
        for i in range(N):
            for j in range(N):
                im = N - 1 if i == 0 else i - 1
                ip = 0 if i == N - 1 else i + 1
                half[i][j] = (u[i][j] - 0.5 * lam * (u[ip][j] - u[im][j])
                              + 0.5 * lam**2 * (u[ip][j] - 2 * u[i][j] + u[im][j]))
        for i in range(N):
            for j in range(N):
                jm = N - 1 if j == 0 else j - 1
                jp = 0 if j == N - 1 else j + 1
                u[i][j] = (half[i][j] - 0.5 * lam * (half[i][jp] - half[i][jm])
                           + 0.5 * lam**2 * (half[i][jp] - 2 * half[i][j] + half[i][jm]))
    return u

def periodic_dist(d):
    # 最近周期距离（坑账：% 回绕会选错周期像——d 为负小时 Python 映到 1+d）
    return d - round(d)

def lod_err(h):
    lam, T = 0.8, 0.25
    nst = round(T / (lam * h))
    tf = nst * lam * h
    N = round(1.0 / h)
    u = lod_lw2d(lam, h, T)
    err = 0.0
    for i in range(N):
        for j in range(N):
            ex = math.exp(-100 * periodic_dist(i * h - 0.5 - tf) ** 2
                          - 100 * periodic_dist(j * h - 0.5 - tf) ** 2)
            err = max(err, abs(u[i][j] - ex))
    return err

u08 = lod_lw2d(0.8, 0.02, 0.25)
assert max(abs(v) for row in u08 for v in row) < 1.01
print(f"LOD-LW lam=0.8 (2D-LF-forbidden): stable, max|u| = {max(abs(v) for row in u08 for v in row):.4f}")
e1, e2 = lod_err(2.0e-2), lod_err(1.0e-2)
r = e1 / e2
assert 3.2 < r < 4.6, r
print(f"LOD-LW convergence: h->h/2 error ratio = {r:.3f} (2nd order)")

maxdev = 0.0
for th1 in [0.05 + 0.1 * k for k in range(31)]:
    for th2 in [0.05 + 0.1 * k for k in range(31)]:
        for lam in (0.5, 2.0, 10.0):
            g = abs((1 - 0.5j * lam * math.sin(th1)) / (1 + 0.5j * lam * math.sin(th1)))
            g *= abs((1 - 0.5j * lam * math.sin(th2)) / (1 + 0.5j * lam * math.sin(th2)))
            maxdev = max(maxdev, abs(g - 1.0))
assert maxdev < 1e-12
print("2D Crank-Nicolson: |G| = 1 over scan (unconditionally stable)")

print("END ====")
