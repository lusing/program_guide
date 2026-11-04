print("==== 19 phase")

# 第 19 章：相平面（solve_ivp 版）。
import math
import numpy as np
from scipy.integrate import solve_ivp

def final(f, u0, T):
    sol = solve_ivp(f, [0, T], u0, rtol=1e-11, atol=1e-13)
    return sol.y[:, -1]

# (a) 迹-行列式六情形
tests = [
    ("saddle", 0.0, -1.0), ("stable_node", -3.0, 2.0), ("stable_spiral", -1.0, 1.0),
    ("center", 0.0, 1.0), ("unstable_spiral", 1.0, 1.0), ("unstable_node", 3.0, 2.0),
]
for name, tau, delta in tests:
    f = lambda t, u, tau=tau, delta=delta: [u[1], -delta * u[0] + tau * u[1]]
    u = final(f, [1.0, 0.0], 10.0)
    r = np.linalg.norm(u)
    if name == "saddle":
        assert r > 10
    elif name == "center":
        assert abs(r - 1) < 1e-6
    elif "unstable" in name:
        assert r > 10
    else:
        assert r < 0.05
    print(f"{name} (tau={tau}, Delta={delta}): |x(10)| = {r:.4g}")

# (b) 单摆：小幅闭轨 + 线性化分类
pend = lambda t, u: [u[1], -math.sin(u[0])]
u0 = [0.5, 0.0]
T1 = 2 * math.pi * (1 + 0.5**2 / 16)
u1 = final(pend, u0, T1)
assert np.linalg.norm(u1 - u0) < 5e-3
print("pendulum small amplitude: period 2pi(1+theta^2/16) returns to start")

# 线性化：下垂中心、倒立鞍点
A1 = np.array([[0.0, 1.0], [-1.0, 0.0]])
A2 = np.array([[0.0, 1.0], [1.0, 0.0]])
assert abs(np.trace(A1)) < 1e-12 and np.linalg.det(A1) == 1
assert np.linalg.det(A2) == -1
print("pendulum: hanging = center (tau=0, Delta=1), inverted = saddle (Delta=-1)")

# (c) 零斜线：Lotka-Volterra，x 的极值点在 y = 2 上
lv = lambda t, u: [u[0] * (1 - u[1] / 2), u[1] * (u[0] / 2 - 1 / 3)]
sol = solve_ivp(lv, [0, 40], [1.0, 1.0], rtol=1e-11, atol=1e-13, dense_output=True)
ts = np.linspace(0, 40, 20000)
xs, ys = sol.sol(ts)
checked = 0
for i in range(1, len(ts) - 1):
    if (xs[i] - xs[i-1]) * (xs[i+1] - xs[i]) < 0 and checked < 3:
        assert abs(ys[i] - 2.0) < 0.02, "x-extrema lie on nullcline y=2"
        checked += 1
assert checked >= 2
print(f"nullclines: {checked} x-extrema on the f1=0 line (y=2)")

print("END ====")
