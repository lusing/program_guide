println("==== 04 linear")

# 第 04 章：一阶线性方程——公式解 vs RK4 交叉验证 + Bernoulli + 叠加原理。

# --- (a) 书例 2.16：y' + 5y = e^x，通解 y = C·e^{-5x} + e^x/6 ---
# 初值 y(0) = 1 定 C：1 = C + 1/6 ⟹ C = 5/6
C = 5 / 6
ysol(x) = C * exp(-5x) + exp(x) / 6
f(x, y) = exp(x) - 5y

# RK4 交叉验证
function rk4(g, x, y, h)
    k1 = g(x, y)
    k2 = g(x + h / 2, y + h * k1 / 2)
    k3 = g(x + h / 2, y + h * k2 / 2)
    k4 = g(x + h, y + h * k3)
    y + h * (k1 + 2k2 + 2k3 + k4) / 6
end
y = 1.0
for i in 0:999
    global y = rk4(f, i * 0.001, y, 0.001)
end
@assert abs(y - ysol(1.0)) < 1e-10 "公式解与 RK4 在 x=1 应一致"
println("例 2.16：y(1) 公式 = ", ysol(1.0), "，RK4 差 ", abs(y - ysol(1.0)))

# --- (b) 书例 2.17：y' - y/x = x（x>0），通解 y = Cx + x² ---
# 初值 y(1) = 2 定 C = 1
ysol17(x) = 1 * x + x^2
f17(x, y) = y / x + x
y = 2.0
for i in 0:999
    global y = rk4(f17, 1 + i * 0.001, y, 0.001)   # 从 x=1 积到 x=2
end
@assert abs(y - ysol17(2.0)) < 1e-10 "例 2.17 公式解与 RK4 应一致"
println("例 2.17：y(2) 公式 = ", ysol17(2.0), "，RK4 差 ", abs(y - ysol17(2.0)))

# --- (c) Bernoulli 书例 2.20：y' - y = 3/y，即 y² = C·e^{2x} - 3 ---
# 初值 y(0) = 2：4 = C - 3 ⟹ C = 7，隐式解 y = sqrt(7e^{2x} - 3)
ysolb(x) = sqrt(7 * exp(2x) - 3)
fb(x, y) = y + 3 / y
y = 2.0
for i in 0:999
    global y = rk4(fb, i * 0.001, y, 0.001)
end
@assert abs(y - ysolb(1.0)) < 1e-9 "Bernoulli 隐式解与 RK4 应一致"
println("Bernoulli：y(1) = ", ysolb(1.0), "，RK4 差 ", abs(y - ysolb(1.0)))

# --- (d) 隐藏线性 书例 2.19：(2e^y - x)y' = 1 ⟺ x' + x = 2e^y（x 为应变量）---
# 解 x = C·e^{-y} + e^y；取 C = 1：x = e^{-y} + e^y = 2cosh y ⟹ y = arccosh(x/2)
for yy in [0.5, 1.0, 1.5]
    xx = exp(-yy) + exp(yy)
    # 验证隐式解满足 dx/dy + x = 2e^y
    dxdy = -exp(-yy) + exp(yy)
    @assert abs(dxdy + xx - 2exp(yy)) < 1e-14 "隐藏线性解代入应恒等"
end
println("隐藏线性：x = e^{-y} + e^y 逐点满足 dx/dy + x = 2e^y")

# --- (e) 叠加原理：L[y] = y' + 5y 线性算子 ---
# y₁ = e^{-5x}（齐次解），y₂ = e^x/6（特解）：L[y₁] = 0，L[y₂] = e^x
# 任取组合 c₁y₁ + c₂y₂：L = c₂·e^x —— 数值核对线性性
L(y, x) = (y(x + 1e-6) - y(x - 1e-6)) / 2e-6 + 5y(x)
y1(x) = exp(-5x)
y2(x) = exp(x) / 6
for (c1, c2) in [(2.0, 3.0), (-1.0, 0.5), (7.0, -2.0)]
    lhs = L(x -> c1 * y1(x) + c2 * y2(x), 0.3)
    rhs = c1 * L(y1, 0.3) + c2 * L(y2, 0.3)
    @assert abs(lhs - rhs) < 1e-6 "L 的线性性（差商噪声内）"
end
@assert abs(L(y2, 0.3) - exp(0.3)) < 1e-5 "特解的 L = e^x"
@assert abs(L(y1, 0.3)) < 1e-5 "齐次解的 L = 0"
println("叠加原理：L[c₁y₁+c₂y₂] = c₁L[y₁]+c₂L[y₂] 数值成立")

println("END ====")
