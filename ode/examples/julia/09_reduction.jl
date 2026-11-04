println("==== 09 reduction")

# 第 09 章：降阶法——四类可积型 + 首次积分的数值核对。

rk4_2(f, x, y, yp, h) = begin
    k1y, k1v = yp, f(x, y, yp)
    k2y, k2v = yp + h * k1v / 2, f(x + h / 2, y + h * k1y / 2, yp + h * k1v / 2)
    k3y, k3v = yp + h * k2v / 2, f(x + h / 2, y + h * k2y / 2, yp + h * k2v / 2)
    k4y, k4v = yp + h * k3v, f(x + h, y + h * k3y, yp + h * k3v)
    (y + h * (k1y + 2k2y + 2k3y + k4y) / 6, yp + h * (k1v + 2k2v + 2k3v + k4v) / 6)
end
function integrate2(f, x0, y0, yp0, x1; n = 24000)
    h = (x1 - x0) / n
    x, y, yp = x0, y0, yp0
    for _ in 1:n
        y, yp = rk4_2(f, x, y, yp, h)
        x += h
    end
    y
end

# --- (a) 例 A 首次积分：yy'' + y'^2 = 0 ⟺ d(yy')/dx = 0 ⟹ y² = C₁x + C₂ ---
# 隐式解 y = sqrt(2x + 3)（C₁=2, C₂=3 支）数值核对
ysol(x) = sqrt(2x + 3)
for x in [0.5, 1.2, 2.0]
    h = 1e-4
    yp = (ysol(x + h) - ysol(x - h)) / 2h
    ypp = (ysol(x + h) - 2ysol(x) + ysol(x - h)) / h^2
    @assert abs(ysol(x) * ypp + yp^2) < 1e-5 "例 A 隐式解残差（O(h²) 差商）"
end
println("例 A：y² = 2x+3 支满足 yy'' + y'^2 = 0（3 点差商核对）")
# 首次积分守恒：yy' 沿数值轨道恒定
y, yp = 1.0, 2.0
fA(x, y, v) = -(v^2) / y
h = 1e-4
x = 0.0
cons0 = y * yp
for _ in 1:20000
    global (y, yp) = rk4_2(fA, x, y, yp, h)
    global x += h
end
@assert abs(y * yp - cons0) < 1e-6 "yy' 应守恒（首次积分）"
println("首次积分 yy' = $cons0 沿 RK4 轨道守恒（误差 < 1e-6）")

# --- (b) 例 B 缺 y 型：y'' - y'/x = x，通解 y = x³/3 + C₁x²/2 + C₂ ---
yB(x) = x^3 / 3 + 1.5 * x^2 / 2 + 2.0    # C₁ = 1.5, C₂ = 2
yBp(x) = x^2 + 1.5 * x
yend = integrate2((x, y, v) -> v / x + x, 1.0, yB(1.0), yBp(1.0), 3.0)
@assert abs(yend - yB(3.0)) < 1e-8 "例 B 通解与 RK4 应一致"
println("例 B：y(3) 公式 = ", round(yB(3.0); digits=6), "，RK4 差 ", abs(yend - yB(3.0)))

# --- (c) 例 D 缺 x 型：yy'' - 2y'^2 = 0，通解 y = 1/(C₁x+C₂) ---
yD(x) = 1 / (0.5x + 2.0)
yend2 = integrate2((x, y, v) -> 2v^2 / y, 1.0, yD(1.0), -0.5 / 2.5^2, 4.0)
@assert abs(yend2 - yD(4.0)) < 1e-8 "例 D 通解与 RK4 应一致"
println("例 D：y = 1/(C₁x+C₂) 与 RK4 一致（差 ", abs(yend2 - yD(4.0)), "）")

# --- (d) 例 E 已知一解：x²y'' + 4xy' - 4y = 0 通解 C₁x + C₂x⁻⁴ ---
# Wronskian: W(x, x⁻⁴) = -5x⁻⁴ ≠ 0（线性无关）
for x in [0.7, 1.3, 2.5]
    W = x * (-4 * x^-5) - (x^-4) * 1
    @assert abs(W - (-5 * x^-4)) < 1e-14
end
println("例 E：W(x, x⁻⁴) = −5x⁻⁴ ≠ 0，两解线性无关")
# IVP 数值：y(1) = 1, y'(1) = 0 ⟹ C₁ = 4/5... 解 y = 0.8x + 0.2x⁻⁴
yE(x) = 0.8x + 0.2 * x^-4
yend3 = integrate2((x, y, v) -> (-4x * v + 4y) / x^2, 1.0, 1.0, 0.8 - 0.8, 3.0)
# y'(1) = 0.8 - 0.8 = 0 ✓
@assert abs(yend3 - yE(3.0)) < 1e-8
println("例 E IVP：y(3) 公式 = ", round(yE(3.0); digits=6), "，RK4 差 ", abs(yend3 - yE(3.0)))

# --- (e) 牛顿抛物线：x(0)=1, v(0)=2, a=3 ⟹ x(t) = 1.5t² + 2t + 1 ---
yend4 = integrate2((t, x, v) -> 3.0, 0.0, 1.0, 2.0, 5.0)
@assert abs(yend4 - (1.5 * 25 + 10 + 1)) < 1e-9
println("牛顿：x(5) = ", yend4, " = 1.5·25 + 10 + 1 ✓")

println("END ====")
