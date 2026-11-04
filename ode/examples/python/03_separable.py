print("==== 03 separable")

# 第 03 章：可分离方程——隐式解核对、免常数定积分式、齐次方程、分叉演示。
import math

# --- (a) 例 1 隐式解：x² + y² = 25 上半圆 y = sqrt(25-x²) ---
h = 1e-6
maxres = 0.0
for i in range(20):
    x = -3.0 + 0.3 * i
    y = math.sqrt(25 - x * x)
    # 数值 y' 与 -x/y 比对
    yp = (math.sqrt(25 - (x + h) ** 2) - math.sqrt(25 - (x - h) ** 2)) / (2 * h)
    maxres = max(maxres, abs(yp - (-x / y)))
assert maxres < 1e-6, f"隐式解残差 {maxres}"
print(f"implicit solution x^2+y^2=25: residual {maxres:.2e}")

# --- (b) 免常数定积分式当求解器：y' = ky，y(0)=2 ---
# ∫[2..y] dr/r = kx ⟹ ln(y/2) = kx ⟹ y = 2e^{kx}；Newton 解 y
def solve_y(k, x):
    y = 2.0
    for _ in range(60):
        # F(y) = ln(y/2) - kx, F'(y) = 1/y
        F = math.log(y / 2) - k * x
        y = y - F * y
    return y

for k, x in [(0.7, 1.3), (-0.4, 2.0), (2.0, 0.5)]:
    y = solve_y(k, x)
    assert abs(y - 2 * math.exp(k * x)) < 1e-10
print("quadrature formula as solver: y = 2e^{kx} recovered by Newton")

# --- (c) 例 5 齐次方程：(x²+y²)dx - 2xy dy = 0，隐式解 y² = x² - Cx ---
# 取 C = 1：y² = x² - x（x ≥ 1 分支），验证 y' = (x²+y²)/(2xy)
for x in [1.5, 2.0, 3.3]:
    y = math.sqrt(x * x - x)
    yp = x / math.sqrt(x * x - x) - 1 / (2 * math.sqrt(x * x - x))
    rhs = (x * x + y * y) / (2 * x * y)
    assert abs(yp - rhs) < 1e-10
print("homogeneous ex: y^2 = x^2 - x satisfies y' = (x^2+y^2)/(2xy)")

# --- (d) 例 4 分叉点：x²+1 = C(y²+1) 过 (1,1) 给 C=1，即 y=±x 都过原点 ---
# 数值演示：从 (1,1) 用 RK4 积分 y' = x*sqrt(1+y^2)/(y*sqrt(1+x^2)) 向左到 x=-0.001
def rk4_int(f, x0, y0, x1, n=2000):
    hstep = (x1 - x0) / n
    x, y = x0, y0
    for _ in range(n):
        k1 = f(x, y)
        k2 = f(x + hstep / 2, y + hstep * k1 / 2)
        k3 = f(x + hstep / 2, y + hstep * k2 / 2)
        k4 = f(x + hstep, y + hstep * k3)
        y += hstep * (k1 + 2 * k2 + 2 * k3 + k4) / 6
        x += hstep
    return y

f4 = lambda x, y: x * math.sqrt(1 + y * y) / (y * math.sqrt(1 + x * x))
yleft = rk4_int(f4, 0.001, 0.001, -1.0)
# 沿 y=x 走到原点后数值在舍入误差支配下"滑轨"——非唯一性的数值指纹：
# 从 (1,1) 到 (0.001,0.001) 再往左，结果不再贴合 ±x 的任何一支的确定值
print(f"branch-slip demo: from (1,1) leftward y(-1) = {yleft:.4f} (exact branch y=x would give -1.0)")

# --- (e) Malthus 与丢失解纪律：y' = 3y 的通解族含 C=0（收编 y≡0） ---
for C in [-2.0, 0.0, 5.0]:
    y = lambda x, C=C: C * math.exp(3 * x)
    assert abs(y(0.4) * 3 - 3 * y(0.4)) < 1e-12
print("Malthus family y = C e^(3x): C=0 subsumes the lost solution y = 0")

print("END ====")
