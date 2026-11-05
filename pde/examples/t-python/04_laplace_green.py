# Ch04 Laplace 方程 II（Python 交叉）：镜像法与 Poisson 核
#
# 与 julia/04_laplace_green.jl 双通道交叉：
#   (a) 半平面 Poisson 核的归一性与重构（julia 做球核，python 做半平面）；
#   (b) 镜像恒等式 |y-x|^2 = |x|^2 |y-x*|^2 的数值对账（Lean 已完整证明）；
#   (c) Kelvin 反演：u(x) = |x|^{2-n} v(x/|x|^2) 保调和性（2D 数值核）。

import math

print("==== 04")

# ---- (a) 半平面 Poisson 核：P(x, y) = (1/pi) x2 / ((x1-y1)^2 + x2^2) ----
def poisson_halfplane(x1, x2, g, L=60.0, n=20000):
    """u(x) = ∫ P(x,y1) g(y1) dy1，截断 [-L,L] 复化 Simpson。"""
    h = 2 * L / n
    s = 0.0
    for k in range(n + 1):
        y1 = -L + k * h
        w = 1.0 if k in (0, n) else (2.0 if k % 2 == 0 else 4.0)
        s += w * (x2 / (math.pi * ((x1 - y1) ** 2 + x2 ** 2))) * g(y1)
    return s * h / 3

# 归一性：g = 1 时 u = 1。截断尾段有闭式（补缺失质量）：
#   tail = 1 - (1/pi)[arctan((L-x1)/x2) + arctan((L+x1)/x2)]
def tail_g1(x1, x2, L):
    return 1 - (1 / math.pi) * (math.atan((L - x1) / x2) + math.atan((L + x1) / x2))

val_raw = poisson_halfplane(0.3, 0.2, lambda t: 1.0)
val = val_raw + tail_g1(0.3, 0.2, 60.0)
print(f"(a) normalization (raw {val_raw:.9f} + analytic tail): u = {val:.12f}")
assert abs(val - 1) < 1e-10

# 重构：g = cos 的有界调和延拓是 u = e^{-x2} cos x1（书 §2.2.4 半空间理论）
for (x1, x2) in [(0.4, 0.3), (-0.2, 0.5)]:
    u = poisson_halfplane(x1, x2, math.cos)
    ex = math.exp(-x2) * math.cos(x1)
    print(f"    g=cos at ({x1},{x2}): integral {u:.9f}  exact {ex:.9f}")
    assert abs(u - ex) < 5e-3  # 有界 g 下截断 O(1/L) 尾段
# 收敛签名：L 翻倍，误差减半（1/L 律）
u60 = poisson_halfplane(0.4, 0.3, math.cos, L=60.0)
u120 = poisson_halfplane(0.4, 0.3, math.cos, L=120.0)
ex0 = math.exp(-0.3) * math.cos(0.4)
e60, e120 = abs(u60 - ex0), abs(u120 - ex0)
print(f"    truncation law: err(L=60)={e60:.2e} err(L=120)={e120:.2e} ratio={e60/e120:.2f}")
assert 1.5 < e60 / e120 < 2.5

# ---- (b) 镜像恒等式数值（Lean: image_identity 完整证明）----
x = (0.3, 0.4)
s = x[0] ** 2 + x[1] ** 2
xs = (x[0] / s, x[1] / s)
import math as m
worst = 0.0
for k in range(12):
    th = 2 * m.pi * k / 12
    y = (m.cos(th), m.sin(th))
    lhs = (y[0] - x[0]) ** 2 + (y[1] - x[1]) ** 2
    rhs = s * ((y[0] - xs[0]) ** 2 + (y[1] - xs[1]) ** 2)
    worst = max(worst, abs(lhs - rhs))
print(f"(b) image identity: worst |lhs-rhs| on 12 boundary points = {worst:.2e}")
assert worst < 1e-14

# ---- (c) Kelvin 反演保调和（2D 数值核）----
# u(x) = |x|^{2-n} v(x/|x|^2)；n=2 时 u(x) = v(x*)。
# 取 v = x^2 - y^2（调和），则 u = (x* )^2 - (y* )^2 调和——数值 Laplacian 核对。
def lap5(f, x, y, h=1e-3):
    return (f(x + h, y) + f(x - h, y) + f(x, y + h) + f(x, y - h) - 4 * f(x, y)) / h**2

def kelvin_v(px, py):
    s2 = px * px + py * py
    return (px / s2) ** 2 - (py / s2) ** 2

r = lap5(kelvin_v, 0.9, 0.7)
# 截断 (h^2/12)·|∂^4|：v(x*) 的四阶导 ~ 4!/s^6（s=|x|^2≈1.3），预测 ~5e-6 量级
print(f"(c) Kelvin inversion Laplacian at (0.9,0.7): {r:.2e} (truncation-dominated)")
assert abs(r) < 5e-5, "v(x*) harmonic away from origin"

print("END ====")
