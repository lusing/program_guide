print("==== 18 apps")

# 第 18 章：方程组应用（solve_ivp 版）。
import math
import numpy as np
from scipy.integrate import solve_ivp

# (a) 带电粒子：螺旋运动
wc = 2.0
v0 = (1.0, 0.5, 0.3)
f = lambda t, s: [s[3], s[4], s[5], wc * s[4], -wc * s[3], 0.0]
T = 2 * math.pi / wc
sol = solve_ivp(f, [0, T], [0, 0, 0, *v0], rtol=1e-12, atol=1e-12)
end = sol.y[:, -1]
assert math.hypot(end[0], end[1]) < 1e-7, "returns to start in xy"
assert abs(end[2] - 0.3 * T) < 1e-8, "z drift = v_z * T"
assert abs(math.hypot(end[3], end[4]) - math.hypot(v0[0], v0[1])) < 1e-9, "|v_perp| conserved"
print(f"helix: one cyclotron period, xy back to start, z drift {end[2]:.6f}, r = v_perp/wc = {math.hypot(v0[0],v0[1])/wc:.4f}")

# (b) 磁矩进动
gB = 3.0
M0 = np.array([0.8, 0.3, 0.5])
sol = solve_ivp(lambda t, M: [-gB * M[1], gB * M[0], 0.0], [0, 2 * math.pi / gB],
                M0, rtol=1e-12, atol=1e-12)
M = sol.y[:, -1]
assert np.linalg.norm(M - M0) < 1e-7
assert abs(np.linalg.norm(M) - np.linalg.norm(M0)) < 1e-9
assert abs(M[2] - M0[2]) < 1e-10
print("Larmor precession: full period return, |M| and M_z conserved")

# (c) 耦合振子：简正模 + 能量守恒
fc = lambda t, s: [s[2], s[3], -2 * s[0] + s[1], s[0] - 2 * s[1]]
sol = solve_ivp(fc, [0, 4 * math.pi], [1.0, 1.0, 0.0, 0.0], rtol=1e-12, atol=1e-12)
assert abs(sol.y[0, -1] - 1) < 1e-6 and abs(sol.y[1, -1] - 1) < 1e-6
print("in-phase mode: w = 1, synchronized motion preserved")

Tanti = 2 * math.pi / math.sqrt(3)
sol = solve_ivp(fc, [0, Tanti], [1.0, -1.0, 0.0, 0.0], rtol=1e-12, atol=1e-12)
assert abs(sol.y[0, -1] - 1) < 1e-6 and abs(sol.y[1, -1] + 1) < 1e-6
print("anti-phase mode: w = sqrt(3), periodic return")

energy = lambda s: 0.5 * (s[2]**2 + s[3]**2) + 0.5 * (s[0]**2 + s[1]**2) + 0.5 * (s[0] - s[1])**2
sol = solve_ivp(fc, [0, 20], [1.0, 0.0, 0.0, 0.0], rtol=1e-12, atol=1e-12,
                dense_output=True)
E0 = energy([1.0, 0.0, 0.0, 0.0])
maxdev = max(abs(energy(sol.sol(t)) - E0) for t in np.linspace(0, 20, 2000))
assert maxdev < 1e-8
print(f"general initial data: total energy conserved (max dev {maxdev:.2e}); beats exchange energy")

print("END ====")
