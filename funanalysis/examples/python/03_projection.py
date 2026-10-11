"""第 03 章 · 正交投影的数值实验（Conway I.2）——scipy 通道。

对应 docs/03-orthogonality.md。
- 闭凸集（球）上的最近点：显式公式 vs scipy 优化器；
- 超平面上的最近点（Conway 2.6 刻画的数值形态）；
- 勾股分解与范数压缩。
"""

import numpy as np
from scipy import optimize

rng = np.random.default_rng(314)

print("==== 03 projection (Python) ====")

# --- 实验 1：闭球上的最近点（Conway 2.5 的最简闭凸集）--------------------
# 到原点距离最近的球外点方向收缩：p = c + r*(x-c)/||x-c||
x = rng.standard_normal(5)
c = rng.standard_normal(5)
r = 0.3
p_ball = c + r * (x - c) / np.linalg.norm(x - c)
# 用 SLSQP 数值求 min ||x - z|| s.t. ||z - c|| <= r 对照
res = optimize.minimize(
    lambda z: np.linalg.norm(x - z),
    x0=c.copy(),
    jac=lambda z: (z - x) / np.linalg.norm(x - z),
    constraints={"type": "ineq", "fun": lambda z: r - np.linalg.norm(z - c)},
    method="SLSQP",
)
err = np.linalg.norm(res.x - p_ball)
print("ball projection: analytic vs SLSQP error =", f"{err:.2e}")
assert err < 1e-6

# --- 实验 2：闭凸集无最近点的反例空间？（教学：Hilbert 完备性不可少）-----
# 在不完备内积空间中闭凸集可以没有最近点——构造性的反例在 docs 中详述；
# 这里演示：完备空间中"闭"是关键。R^3 中取非闭凸集 (0,1)^3 的闭包边界点。
# 数值上：把 (1,1,1) 到开立方 (0,1)^3 的距离下确界 0 不可达——
# 任何内点距离 > 0。用一串趋近点展示下确界可达性的破缺。
target = np.array([1.0, 1.0, 1.0])
dists = [np.linalg.norm(target - np.array([1 - 1 / n] * 3)) for n in range(1, 200)]
print("dist to open cube inf ≈", f"{min(dists):.6f}", "> 0 for every interior point")
assert min(dists) > 0  # 每个内点都严格正距离；下确界 0 不可达

# --- 实验 3：勾股分解（Conway 2.7）----------------------------------------
A = rng.standard_normal((8, 3))
Q, _ = np.linalg.qr(A)          # 正交列
v = np.arange(1, 9) / 3
Pv = Q @ (Q.T @ v)
err = v - Pv
print("orthogonality <Pv, v-Pv> =", f"{Pv @ err:.2e}")
print("||v||^2 =", f"{v @ v:.6f}", " ||Pv||^2+||err||^2 =",
      f"{Pv @ Pv + err @ err:.6f}")
assert abs(Pv @ err) < 1e-10
assert abs(v @ v - Pv @ Pv - err @ err) < 1e-10
assert np.linalg.norm(Pv) <= np.linalg.norm(v)

print("==== 03 projection END ====")
