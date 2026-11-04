print("==== 22 vanderpol")

# 第 22 章：van der Pol 极限环（solve_ivp 版）。
import math
import numpy as np
from scipy.integrate import solve_ivp

vdp = lambda mu: (lambda t, u: [u[1], mu * (1 - u[0]**2) * u[1] - u[0]])

def envelope(mu, u0, T=120):
    sol = solve_ivp(vdp(mu), [0, T], u0, rtol=1e-11, atol=1e-13, dense_output=True)
    ts = np.linspace(T / 2, T, 2000)
    return max(abs(sol.sol(t)[0]) for t in ts)

# (a) 内外初值贴环
xin = envelope(1.0, [0.1, 0.0])
xout = envelope(1.0, [5.0, 5.0])
assert abs(xin - xout) < 0.02
assert abs(xin - 2.0) < 0.15
print(f"limit cycle: inner/outer envelopes max|x| = {xin:.4f}/{xout:.4f} (same cycle, ~2)")

# (b) 振幅律
for mu in [0.2, 1.0, 2.0]:
    xm = envelope(mu, [1.0, 0.0])
    assert abs(xm - 2.0) < 0.25
print("amplitude law: max|x| ~ 2 for mu in {0.2, 1, 2}")

# (c) 能量账：谐波平衡 x = 2 cos t 的净能量
mu = 1.0
n = 20000
h = 2 * math.pi / n
Iv = sum((0.5 if k in (0, n) else 1.0) *
         mu * (1 - (2 * math.cos(k * h))**2) * (2 * math.sin(k * h))**2 * h
         for k in range(n + 1))
assert abs(Iv) < 0.05
print(f"harmonic balance: oint mu(1-x^2)y^2 dt = {Iv:.2e} ~ 0 for x = 2cos t")

# (d) 恒等式 + 有界性（Poincare-Bendixson 素材）
for r in [0.5, 1.0, 1.8, 2.5]:
    for k in range(8):
        th = k * math.pi / 4
        p = np.array([r * math.cos(th), r * math.sin(th)])
        fv = np.array(vdp(1.0)(0.0, p))
        lhs = p @ fv
        rhs = (1 - p[0]**2) * p[1]**2
        assert abs(lhs - rhs) < 1e-12
print("identity: x*x' + y*y' = mu(1-x^2)y^2 at 32 points (energy in/out mechanism)")

sol = solve_ivp(vdp(1.0), [0, 300], [0.1, 0.1], rtol=1e-11, atol=1e-13, dense_output=True)
ts = np.linspace(200, 300, 2000)
rs = np.array([np.linalg.norm(sol.sol(t)) for t in ts])
assert rs.max() < 3.0
assert rs.min() > 0.5
print(f"bounded orbit: r in [{rs.min():.3f}, {rs.max():.3f}] late-time -> compact trapping set")

print("END ====")
