# 00_intro.py —— 第 00 章：对表基准与方法效率的威力（Python 通道，独立复算）
#
# 与 Julia 通道同一实验的第二实现：残差阶数测量 + 二次多项式精确性 +
# Jacobi/GS/SOR 迭代次数对比。两通道数字各自独立算出、互相对账。

import math

print("==== 00 intro")

# ---------- (1) 三个精确解对表 ----------
def u_heat(x, t):
    return math.exp(-math.pi**2 * t) * math.sin(math.pi * x)

def u_wave(x, t):
    return math.sin(math.pi * x) * math.cos(math.pi * t)

def u_gen(x, t):
    return math.exp(x + t) + (x - t) ** 3

def u_lap(x, y):
    return math.exp(x) * math.sin(y)

def resid_heat(h):
    x, t = 0.5, 0.05
    dut = (u_heat(x, t + h) - u_heat(x, t - h)) / (2 * h)
    duxx = (u_heat(x + h, t) - 2 * u_heat(x, t) + u_heat(x - h, t)) / h**2
    return abs(dut - duxx)

def resid_wave_canceled(h):
    x, t = 0.3, 0.1
    dutt = (u_wave(x, t + h) - 2 * u_wave(x, t) + u_wave(x, t - h)) / h**2
    duxx = (u_wave(x + h, t) - 2 * u_wave(x, t) + u_wave(x - h, t)) / h**2
    return abs(dutt - duxx)

def resid_wave(h):
    x, t = 0.3, 0.1
    tau = h / 2
    dutt = (u_gen(x, t + tau) - 2 * u_gen(x, t) + u_gen(x, t - tau)) / tau**2
    duxx = (u_gen(x + h, t) - 2 * u_gen(x, t) + u_gen(x - h, t)) / h**2
    return abs(dutt - duxx)

def resid_lap(h):
    x, y = 0.2, 0.4
    du = (u_lap(x + h, y) + u_lap(x - h, y) + u_lap(x, y + h)
          + u_lap(x, y - h) - 4 * u_lap(x, y)) / h**2
    return abs(du)

for name, r in (("heat", resid_heat), ("wave", resid_wave), ("laplace", resid_lap)):
    r1, r2 = r(1.0e-1), r(5.0e-2)
    ratio = r1 / r2
    assert 3.5 < ratio < 4.5, f"residual ratio should be ~4 ({name}: {ratio})"
    print(f"residual {name}: h->h/2 ratio = {ratio:.3f}  (2nd order)")

for h in (1.0e-1, 5.0e-2):
    assert resid_wave_canceled(h) < 1.0e-9, "residual should vanish identically when tau = h"
print("wave residual with tau = h on separable mode: identically 0 (exact cancellation)")

# ---------- (2) 二次多项式上五点格式精确 ----------
x, y, h = 0.3, 0.7, 0.1
u2 = lambda s, t: s * s - t * t
lap5 = (u2(x + h, y) + u2(x - h, y) + u2(x, y + h) + u2(x, y - h) - 4 * u2(x, y)) / h**2
assert abs(lap5) < 1.0e-13, "5-point laplacian of x^2-y^2 should be exact"
print("laplacian of x^2-y^2 via 5-point stencil: exactly 0 up to roundoff")

# ---------- (3) 迭代法效率 ----------
def iter_counts(N, tol=1.0e-8, maxit=200000):
    hh = 1.0 / (N + 1)
    exact = lambda i, j: math.exp(i * hh) * math.sin(j * hh)

    # Jacobi
    uj = [[0.0] * (N + 2) for _ in range(N + 2)]
    for i in range(N + 2):
        for j in range(N + 2):
            if i in (0, N + 1) or j in (0, N + 1):
                uj[i][j] = math.exp(i * hh) * math.sin(j * hh)
    cnt = 0
    while cnt < maxit:
        diff = 0.0
        un = [row[:] for row in uj]
        for i in range(1, N + 1):
            for j in range(1, N + 1):
                un[i][j] = 0.25 * (uj[i+1][j] + uj[i-1][j] + uj[i][j+1] + uj[i][j-1])
                diff = max(diff, abs(un[i][j] - uj[i][j]))
        uj = un
        cnt += 1
        if diff < tol:
            break
    cnt_j = cnt

    # Gauss-Seidel
    ug = [row[:] for row in uj]
    # restart from zero interior for fair comparison
    for i in range(1, N + 1):
        for j in range(1, N + 1):
            ug[i][j] = 0.0
    cnt = 0
    while cnt < maxit:
        diff = 0.0
        for j in range(1, N + 1):
            for i in range(1, N + 1):
                newv = 0.25 * (ug[i+1][j] + ug[i-1][j] + ug[i][j+1] + ug[i][j-1])
                diff = max(diff, abs(newv - ug[i][j]))
                ug[i][j] = newv
        cnt += 1
        if diff < tol:
            break
    cnt_g = cnt

    # SOR
    omega = 2.0 / (1.0 + math.sin(math.pi * hh))
    us = [row[:] for row in ug]
    for i in range(1, N + 1):
        for j in range(1, N + 1):
            us[i][j] = 0.0
    cnt = 0
    while cnt < maxit:
        diff = 0.0
        for j in range(1, N + 1):
            for i in range(1, N + 1):
                gs = 0.25 * (us[i+1][j] + us[i-1][j] + us[i][j+1] + us[i][j-1])
                newv = us[i][j] + omega * (gs - us[i][j])
                diff = max(diff, abs(newv - us[i][j]))
                us[i][j] = newv
        cnt += 1
        if diff < tol:
            break
    cnt_s = cnt

    err = max(abs(us[i][j] - exact(i, j)) for i in range(1, N + 1) for j in range(1, N + 1))
    return cnt_j, cnt_g, cnt_s, err

cj, cg, cs, err = iter_counts(20)
print(f"iterations for N=20, tol=1e-8:  Jacobi = {cj}  GS = {cg}  SOR = {cs}")
assert cs < cg < cj, "SOR should be fastest, Jacobi slowest"
assert cj / cs > 10, "SOR speedup should exceed 10x"
assert err < 0.01, "five-point O(h^2) error should stay below 0.01 (h=1/21)"
print(f"SOR speedup vs Jacobi: {cj / cs:.1f}x; discrete error = {err:.4g}")

print("END ====")
