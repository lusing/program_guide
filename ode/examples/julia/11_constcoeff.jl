println("==== 11 constcoeff")

# 第 11 章：常系数二阶——三情形 + 共振 + 待定系数。

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

# --- (a) 三情形通解代入残差（解析导数精确核对）---
# D>0：y'' + y' - 6y = 0，根 2、-3：y = C₁e^{2x} + C₂e^{-3x}
resid1(x) = let y = 1.2 * exp(2x) - 0.7 * exp(-3x),
    yp = 2.4 * exp(2x) + 2.1 * exp(-3x),
    ypp = 4.8 * exp(2x) - 6.3 * exp(-3x)
    ypp + yp - 6y
end
@assert maximum(abs(resid1(x)) for x in 0.0:0.3:3.0) < 1e-10
println("D>0：y = 1.2e^{2x} - 0.7e^{-3x} 满足 y''+y'-6y = 0")
# D=0：y'' - 2y' + y = 0 重根 1：y = (C₁ + C₂x)e^x
resid2(x) = let y = (2 + 0.5x) * exp(x),
    yp = (2.5 + 0.5x) * exp(x),
    ypp = (3.0 + 0.5x) * exp(x)
    ypp - 2yp + y
end
@assert maximum(abs(resid2(x)) for x in 0.0:0.3:3.0) < 1e-10
println("D=0：y = (2+0.5x)eˣ 满足 y''-2y'+y = 0")
# D<0：y'' + 2y' + 5y = 0 根 -1±2i：y = e^{-x}(C₁cos2x + C₂sin2x)
resid3(x) = let y = exp(-x) * (cos(2x) + 2sin(2x)),
    yp = exp(-x) * (3cos(2x) - 4sin(2x)),
    ypp = exp(-x) * (-11cos(2x) - 2sin(2x))
    ypp + 2yp + 5y
end
@assert maximum(abs(resid3(x)) for x in 0.0:0.3:3.0) < 1e-10
println("D<0：y = e^{-x}(cos2x + 2sin2x) 满足 y''+2y'+5y = 0")

# --- (b) 共振：y'' + y = sin x 解振幅线性增长 ---
yend = integrate2((x, y, v) -> -y + sin(x), 0.0, 0.0, 0.0, 20pi; n = 480000)
# 真解 y = -x cos x / 2：x = 20π 时 = -10π·cos(20π) = -10π
@assert abs(yend - (-10pi)) < 5e-3 "共振解 y(20π) ≈ -10π"
println("共振：y(20π) = ", round(yend; digits=3), " ≈ -10π = ", round(-10pi; digits=3))

# --- (c) 待定系数例 B：y'' + y = sin x + x 的 IVP y(0)=1, y'(0)=0 ---
yexact(x) = cos(x) - sin(x) / 2 - x * cos(x) / 2 + x
yend2 = integrate2((x, y, v) -> -y + sin(x) + x, 0.0, 1.0, 0.0, 5.0)
@assert abs(yend2 - yexact(5.0)) < 1e-8
println("书例 3.23：y(5) = ", round(yexact(5.0); digits=6), "，RK4 差 ", abs(yend2 - yexact(5.0)))

# --- (d) 稳定性：p=5,q=6（根 -2,-3），任意初值 x(5) → 0 ---
yend3 = integrate2((x, y, v) -> -5v - 6y, 0.0, 3.0, -2.0, 5.0)
@assert abs(yend3 - 7 * exp(-10.0) + 4 * exp(-15.0)) < 1e-10 "真解 y = 7e^{-2x} - 4e^{-3x}，RK4 应咬住"
println("稳定：y''+5y'+6y=0 从 (3,-2) 出发 y(5) = ", yend3, "（→0）")

# --- (e) 书例 3.22 特解：ȳ = xeˣ(3/4 cos2x + 1/4 sin2x) ---
ypart(x) = x * exp(x) * (0.75cos(2x) + 0.25sin(2x))
# 数值核对：y''-2y'+5y = e^x(cos2x - 3sin2x)
for x in [0.4, 1.2, 2.2]
    h = 1e-5
    ypp = (ypart(x + h) - 2ypart(x) + ypart(x - h)) / h^2
    yp_ = (ypart(x + h) - ypart(x - h)) / 2h
    @assert abs(ypp - 2yp_ + 5ypart(x) - exp(x) * (cos(2x) - 3sin(2x))) < 1e-3
end
println("书例 3.22 特解代入残差 < 1e-3（差商精度内）")

println("END ====")
