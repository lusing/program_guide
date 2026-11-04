print("==== 20 stability")

# 第 20 章：Lyapunov 稳定性（solve_ivp + scipy.linalg 版）。
import math
import numpy as np
from scipy.integrate import solve_ivp
from scipy.linalg import solve_lyapunov, eigvals

# (a) 线性化判据三例
eig_pend = eigvals(np.array([[0.0, 1.0], [-1.0, 0.0]]))
assert abs(eig_pend.real).max() < 1e-12
print("undamped pendulum: eigenvalues +-i (critical, linearization inconclusive)")

eig_damped = eigvals(np.array([[0.0, 1.0], [-1.0, -0.3]]))
assert eig_damped.real.max() < 0
print("damped pendulum: real parts negative -> asymptotically stable")

eig_vdp = eigvals(np.array([[0.0, 1.0], [-1.0, 1.0]]))
assert eig_vdp.real.min() > 0
print("van der Pol origin: real parts positive -> unstable (start of oscillation)")

# (b) Lyapunov 函数：能量单调降 + 衰减包络
delta, w0 = 0.4, 2.0
f_osc = lambda t, u: [u[1], -2 * delta * u[1] - w0**2 * u[0]]
E = lambda u: 0.5 * (u[1]**2 + w0**2 * u[0]**2)
sol = solve_ivp(f_osc, [0, 10], [1.0, 0.0], rtol=1e-12, atol=1e-14, dense_output=True)
ts = np.linspace(0, 10, 5000)
Es = np.array([E(sol.sol(t)) for t in ts])
assert np.all(np.diff(Es) <= 1e-10), "energy non-increasing (Vdot = -2 delta v^2 <= 0)"
assert Es[-1] / Es[0] < 1.5 * math.exp(-2 * delta * 10)
print(f"damped oscillator: E non-increasing, E(10)/E(0) = {Es[-1]/Es[0]:.2e} ~ e^-0.8w0 scale")

# (c) x' = -x^3 幂式衰减
sol = solve_ivp(lambda t, u: [-u[0]**3], [0, 200], [1.0], rtol=1e-12, atol=1e-14)
assert abs(sol.y[0, -1] - 1 / math.sqrt(400)) < 5e-3
print(f"cubic decay: x(200) = {sol.y[0,-1]:.4f} ~ 1/sqrt(2t) = {1/math.sqrt(400):.4f}")

# (d) 三级稳定性：中心范数守恒
sol = solve_ivp(lambda t, u: [u[1], -u[0]], [0, 30], [1.0, 0.0], rtol=1e-12, atol=1e-14)
assert abs(np.linalg.norm(sol.y[:, -1]) - 1) < 1e-8
print("center: orbit norm conserved (stable but not attracting)")

# (e) Lyapunov 方程：A^T P + P A = -Q 有正定解 ⟹ 渐近稳定
A = np.array([[-1.0, 0.5], [0.3, -2.0]])
Q = np.eye(2)
P = solve_lyapunov(A.T, -Q)
assert np.linalg.norm(A.T @ P + P @ A + Q) < 1e-9
assert np.linalg.eigvalsh(P).min() > 0
V0 = np.array([1.0, 1.0]) @ P @ np.array([1.0, 1.0])
print(f"Lyapunov equation: positive definite P found, V(1,1) = {V0:.4f} -> asymptotic stability")

print("END ====")
