print("==== 31 pde")

# 第 31 章：分离变量（scipy 对照版）。
import math
import numpy as np
from scipy.integrate import quad

# (a) 热方程模式衰减
cn = lambda n: 2 * quad(lambda x: x * (1 - x) * math.sin(n * math.pi * x), 0, 1)[0]
t = 0.1
c1, c2 = cn(1) * math.exp(-math.pi**2 * t), cn(2) * math.exp(-4 * math.pi**2 * t)
assert abs(c1 / c2) > 100
print(f"heat: mode1/mode2 = {abs(c1/c2):.1e} at t = 0.1 (high modes die first)")

# (b) 波方程：cos(pi t) sin(pi x) 半离散（solve_ivp 大系统）
N = 40
dx = 1 / N
A = np.zeros((N + 1, N + 1))
for i in range(1, N):
    A[i, i - 1]  = 1 / dx**2
    A[i, i]      = -2 / dx**2
    A[i, i + 1]  = 1 / dx**2
u0 = np.sin(math.pi * np.arange(N + 1) * dx)
sol_state = np.concatenate([u0, np.zeros(N + 1)])
def rhs(t, s):
    u, v = s[:N+1], s[N+1:]
    return np.concatenate([v, A @ u])
from scipy.integrate import solve_ivp
sol = solve_ivp(rhs, [0, 1], sol_state, rtol=1e-10, atol=1e-12, method="RK45")
uend = sol.y[:N+1, -1]
assert abs(uend[N // 2] - math.cos(math.pi)) < 1e-3
print(f"wave: u(0.5, 1) = {uend[N//2]:.6f} ~ cos(pi) = -1")

# (c) FTCS 稳定性
def ftcs(r, nsteps, u0):
    u = u0.copy()
    for _ in range(nsteps):
        un = u.copy()
        un[1:N] = u[1:N] + r * (u[2:] - 2 * u[1:N] + u[:-2])
        u = un
    return u

N = 50
dx = 1 / N
r = 0.4
dt = r * dx**2
u0 = np.sin(math.pi * np.arange(N + 1) * dx)
uftcs = ftcs(r, round(0.05 / dt), u0)
for i in [10, 25, 40]:
    x = i * dx
    assert abs(uftcs[i] - math.sin(math.pi * x) * math.exp(-math.pi**2 * 0.05)) < 1e-3
print("FTCS (r=0.4): matches eigenmode solution at t = 0.05")

# 不稳定演示 r = 0.6（增长因子 1-4·0.6·sin²>1 每步放大）
uftcs_bad = ftcs(0.6, round(0.2 / (0.6 * dx**2)), u0)
assert abs(uftcs_bad).max() > abs(u0).max() * 1.5
print(f"FTCS (r=0.6): max|u| = {abs(uftcs_bad).max():.3f} grows (unstable)")

# (d) Laplace 极值原理
u = lambda x, y: math.sin(math.pi * x) * math.sinh(math.pi * y) / math.sinh(math.pi)
h = 1e-5
for x, y in [(0.5, 0.5), (0.3, 0.7)]:
    lap = (u(x+h, y) + u(x-h, y) + u(x, y+h) + u(x, y-h) - 4*u(x, y)) / h**2
    assert abs(lap) < 1e-5
assert 0 < u(0.5, 0.5) < 1
print(f"Laplace: harmonic residual < 1e-5, interior {u(0.5,0.5):.4f} < boundary max 1")

print("END ====")
