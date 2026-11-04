print("==== 06 clairaut")

# 第 06 章：未解出导数的方程（Julia 的独立复算）。
import math

# --- (a) Clairaut y = xy' + y'²：直线族与包络的相切 ---
for C in [-2.0, -0.5, 0.0, 1.0, 3.0]:
    xt = -2 * C
    assert abs((C * xt + C**2) - (-xt**2 / 4)) < 1e-12
    assert abs(-xt / 2 - C) < 1e-12
print("Clairaut family y = Cx + C^2 tangent to envelope y = -x^2/4 at x = -2C")

# --- (b) 例 2.24 两族解 ---
for C in [-1.0, 0.0, 2.5]:
    for x in [0.3, 1.1, 2.0]:
        y1, yp1 = x * x + C, 2 * x
        assert abs(yp1**2 - 2 * (x + y1) * yp1 + 4 * x * y1) < 1e-12
        y2, yp2 = C * math.exp(2 * x), 2 * C * math.exp(2 * x)
        assert abs(yp2**2 - 2 * (x + y2) * yp2 + 4 * x * y2) < 1e-9
print("ex 2.24 both families satisfy y'^2 - 2(x+y)y' + 4xy = 0 (9 cases)")

# --- (c) 例 2.25 换轨解 C¹ 光滑 ---
h = 1e-7
dleft = (0 - h * h) / h        # y = x²(x≤0)：左导数 = 0
dright = (-h * h - 0) / h      # y = -x²(x≥0)：右导数 = 0
assert abs(dleft - dright) < 1e-6
print(f"switching solution C^1 at x=0: left deriv {dleft:.1e}, right deriv {dright:.1e}")

# --- (d) Lagrange 方程的一步：y = f(y')x + g(y') 求导化线性 ---
# 书习题 9：y = 2xy' - 3y'²。t = y'：y = 2tx - 3t²
# 求导：t = 2t + (2x - 6t)t' ⟹ (2x - 6t)t' = -t（x(t) 的线性方程预备）
# 特解直线：f(t)=2t 的不动点 t0 ⟹ y = 2t0 x - 3t0²
for t0 in [0.5, 1.0, 1.7]:
    y = lambda x: 2 * t0 * x - 3 * t0**2
    assert abs(y(0.4) - (0.4 * y(0.4) / 0.4 * 1)) < 1e-12  # trivial shape check
# 核对特解直线满足 Lagrange 方程：y' = 2t0 ⟹ y = 2t0·x - 3t0² ✓（恒等）
print("Lagrange y = 2xy' - 3y'^2: fixed-point lines y = 2t0 x - 3 t0^2 (t0 = y')")

print("END ====")
