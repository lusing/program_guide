print("==== 21 bifurcation")

# 第 21 章：分岔（solve_ivp 版）。
import math
import numpy as np
from scipy.integrate import solve_ivp

def final(f, u0, T, rtol=1e-11):
    sol = solve_ivp(f, [0, T], u0, rtol=rtol, atol=1e-13)
    return sol.y[0, -1]

# (a) 鞍结：mu > 0 两奇点（上稳下不稳），mu < 0 无奇点
for mu in [0.1, 0.5, 1.0]:
    f = lambda t, u: [mu - u[0]**2]
    assert abs(final(f, [math.sqrt(mu) + 0.1], 30) - math.sqrt(mu)) < 1e-3
y = final(lambda t, u: [-0.2 - u[0]**2], [0.5], 9)
assert y < -5 or math.isnan(y)
print("saddle-node: upper equilibrium stable, mu<0 escape to -inf")

# (b) 跨临界：稳定性交换
for mu, stable_at in [(-0.5, 0.0), (0.5, 0.5)]:
    f = lambda t, u: [mu * u[0] - u[0]**2]
    assert abs(final(f, [stable_at + 0.05], 25) - stable_at) < 1e-3
print("transcritical: stability exchanges between y=0 and y=mu")

# (c) 叉式：对称破缺 ±sqrt(mu)
for mu in [0.5, 1.0, 2.0]:
    f = lambda t, u: [mu * u[0] - u[0]**3]
    assert abs(final(f, [0.05], 20) - math.sqrt(mu)) < 1e-2
assert abs(final(lambda t, u: [-0.5 * u[0] - u[0]**3], [0.05], 25)) < 1e-4
print("pitchfork: broken branches +-sqrt(mu), y=0 stable for mu<0")

# (d) Hopf：r' = r(mu - r^2) 的环半径 sqrt(mu) + 标度律
def hopf_final(mu, T=60):
    f = lambda t, u: [u[0] * (mu - (u[0]**2 + u[1]**2)) - u[1],
                      u[0] + u[1] * (mu - (u[0]**2 + u[1]**2))]
    sol = solve_ivp(f, [0, T], [0.1, 0.1], rtol=1e-11, atol=1e-13)
    return sol.y[:, -1]

for mu in [0.3, 1.0, 2.0]:
    u = hopf_final(mu)
    r = np.linalg.norm(u)
    assert abs(r - math.sqrt(mu)) < 5e-3
print("Hopf: limit cycle radius sqrt(mu) at three mu values")

u = hopf_final(-0.3, T=30)
assert np.linalg.norm(u) < 1e-4
print("Hopf: mu<0 origin asymptotically stable")

mus = [0.3, 0.5, 1.0, 2.0, 3.0]
rs = [np.linalg.norm(hopf_final(m)) for m in mus]
lm, lr = np.log(mus), np.log(rs)
slope = np.sum((lm - lm.mean()) * (lr - lr.mean())) / np.sum((lm - lm.mean())**2)
assert abs(slope - 0.5) < 0.02
print(f"scaling law: dlog r/dlog mu = {slope:.4f} (theory 0.5)")

print("END ====")
