println("==== 05 exact")

# 第 05 章：恰当方程——判据、势函数与积分因子的数值验证。

# --- (a) 书例 2.22：(3x²y²+7)dx + 2x³y dy = 0 恰当，F = x³y² + 7x ---
P(x, y) = 3x^2 * y^2 + 7
Q(x, y) = 2x^3 * y

# 判据：∂P/∂y = ∂Q/∂x（中心差分）
h = 1e-6
dPy(x, y) = (P(x, y + h) - P(x, y - h)) / 2h
dQx(x, y) = (Q(x + h, y) - Q(x - h, y)) / 2h
maxdev = maximum(abs(dPy(x, y) - dQx(x, y))
                 for x in 0.2:0.2:1.0, y in 0.2:0.2:1.0)
@assert maxdev < 1e-6 "判据 P_y = Q_x 应成立（差分精度内）"
println("判据 |P_y - Q_x| 最大偏差 = ", maxdev)

# 势函数核对：∂F/∂x = P、∂F/∂y = Q（解析导数精确核对）
F(x, y) = x^3 * y^2 + 7x
Fx(x, y) = 3x^2 * y^2 + 7
Fy(x, y) = 2x^3 * y
@assert all(Fx(x, y) == P(x, y) && Fy(x, y) == Q(x, y)
            for x in 0.2:0.2:1.0, y in 0.2:0.2:1.0) "F 的偏导应逐点等于 P、Q"
println("势函数 F = x³y² + 7x：∂F/∂x = P、∂F/∂y = Q 逐点精确成立")

# --- (b) 沿隐式解曲线 F = C 核对方程：y' = -P/Q ---
# C = 8：曲线 x³y² + 7x = 8 上（x ∈ [0.5, 0.85] 时 y² > 0），
# y' = -(3x²y²+7)/(2x³y)；用隐函数求导 + 数值微分双核对
C0 = 8.0
ycurve(x) = sqrt((C0 - 7x) / x^3)    # 上半支
for x in 0.5:0.1:0.85
    yy = ycurve(x)
    lhs = (ycurve(x + 1e-7) - ycurve(x - 1e-7)) / 2e-7      # 数值 y'
    rhs = -P(x, yy) / Q(x, yy)                               # 隐函数求导公式
    @assert abs(lhs - rhs) < 1e-5 "隐式解上 y' = -P/Q"
end
println("隐式解 F = 8 上 4 个采样点：y' = -P/Q 成立（差分精度内）")

# --- (c) 书例 2.23：不恰当 → 乘 μ = 1/(x²+y²) 变恰当 ---
P2(x, y) = x + x^2 * (x^2 + y^2)
Q2(x, y) = y
# 原方程不恰当：∂P/∂y = 2x²y ≠ 0 = ∂Q/∂x（取非零点验证"确实不等"）
@assert abs((P2(0.9, 0.6 + h) - P2(0.9, 0.6 - h)) / 2h) > 0.5 "原方程应不恰当"
mu(x, y) = 1 / (x^2 + y^2)
P3(x, y) = mu(x, y) * P2(x, y)
Q3(x, y) = mu(x, y) * Q2(x, y)
# 乘 μ 后：(μP)_y = (μQ)_x？ 直接用书给的势函数 F = (1/2)ln(x²+y²) + x³/3
F2(x, y) = 0.5 * log(x^2 + y^2) + x^3 / 3
Fx2(x, y) = x / (x^2 + y^2) + x^2        # 解析偏导
Fy2(x, y) = y / (x^2 + y^2)
maxdev2 = maximum(max(abs(Fx2(x, y) - P3(x, y)), abs(Fy2(x, y) - Q3(x, y)))
                  for x in 0.5:0.2:1.5, y in 0.5:0.2:1.5)
@assert maxdev2 < 1e-12 "乘 μ 后 μP = ∂F/∂x、μQ = ∂F/∂y"
println("乘 μ = 1/(x²+y²) 后：μP = F_x、μQ = F_y，最大偏差 ", maxdev2)

# 通解（书）：√(x²+y²)·e^{2x³/3} = C —— 记 G = e^H，
# H = (1/2)ln(x²+y²) + 2x³/3，核对 ∇G = G·∇H（链式法则）
G(x, y) = sqrt(x^2 + y^2) * exp(2x^3 / 3)
for (x, y) in [(0.5, 0.8), (1.0, 1.2)]
    Hx = x / (x^2 + y^2) + 2x^2
    Hy = y / (x^2 + y^2)
    Gx = (x / sqrt(x^2 + y^2)) * exp(2x^3 / 3) + sqrt(x^2 + y^2) * exp(2x^3 / 3) * 2x^2
    Gy = (y / sqrt(x^2 + y^2)) * exp(2x^3 / 3)
    @assert abs(Gx - G(x, y) * Hx) < 1e-10
    @assert abs(Gy - G(x, y) * Hy) < 1e-10
end
println("G = √(x²+y²)·e^{2x³/3} = e^H 的梯度 = G·∇H（链式法则核对）")

println("END ====")
