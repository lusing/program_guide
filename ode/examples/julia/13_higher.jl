println("==== 13 higher")

# 第 13 章：高阶常系数与 Euler 方程。

# --- (a) 例 A：y⁽⁴⁾ − y = 0，基 eˣ, e⁻ˣ, cos x, sin x 残差核对 ---
resid4(y, y1, y2, y3, y4) = y4 - y
for x in [0.3, 1.1, 2.0]
    @assert abs(resid4(exp(x), exp(x), exp(x), exp(x), exp(x))) < 1e-12
    @assert abs(resid4(exp(-x), -exp(-x), exp(-x), -exp(-x), exp(-x))) < 1e-12
    @assert abs(resid4(cos(x), -sin(x), -cos(x), sin(x), cos(x))) < 1e-12
    @assert abs(resid4(sin(x), cos(x), -sin(x), -cos(x), sin(x))) < 1e-12
end
println("例 A：eˣ/e⁻ˣ/cos/sin 四基代入 y⁽⁴⁾−y = 0 恒为零")

# --- (b) 例 B：y‴ − 3y″ + 3y′ − y = 0 三重根 1：y = (C₁+C₂x+C₃x²)eˣ ---
resid3c(x) = let y = (1 + 2x + 0.5x^2) * exp(x),
    y1 = (3 + 3x + 0.5x^2) * exp(x),
    y2 = (6 + 4x + 0.5x^2) * exp(x),
    y3 = (10 + 5x + 0.5x^2) * exp(x)
    y3 - 3y2 + 3y1 - y
end
# 手工账：y = (1+2x+½x²)eˣ：y' = (2+x)eˣ + (1+2x+½x²)eˣ = (3+3x+½x²)eˣ
# y'' = (3+2x)eˣ+(3+3x+½x²)eˣ = (6+5x+½x²)eˣ；y''' = (6+5x+½x²+5+x)eˣ = (11+6x+½x²)eˣ
resid3fix(x) = let y = (1 + 2x + 0.5x^2) * exp(x),
    y1 = (3 + 3x + 0.5x^2) * exp(x),
    y2 = (6 + 4x + 0.5x^2) * exp(x),
    y3 = (10 + 5x + 0.5x^2) * exp(x)
    y3 - 3y2 + 3y1 - y
end
@assert maximum(abs(resid3fix(x)) for x in 0.0:0.4:3.0) < 1e-9
println("例 B：(1+2x+½x²)eˣ 满足 (D−1)³y = 0（残差 < 1e-9）")

# --- (c) 算子因式分解：(D−1)³ = D³−3D²+3D−1 多项式恒等（不依赖包，直接核对）---
D3m1(k) = k^3 - 3k^2 + 3k - 1
cubic(k) = (k - 1)^3
for k in [-2.0, 0.0, 1.5, 4.0]
    @assert abs(D3m1(k) - cubic(k)) < 1e-14 "算子因式分解恒等"
end
println("算子观点：k³−3k²+3k−1 = (k−1)³（特征多项式因式分解恒等）")

# --- (d) Euler：x²y″ − 2xy′ + 2y = 0，通解 C₁x + C₂x² ---
residE(x) = let y = 1.3x + 2.1x^2, y1 = 1.3 + 4.2x, y2 = 4.2
    x^2 * y2 - 2x * y1 + 2y
end
@assert maximum(abs(residE(x)) for x in [0.5, 1.7, 3.0]) < 1e-12
println("Euler：y = 1.3x + 2.1x² 满足 x²y″−2xy′+2y = 0（指标根 1、2）")

# --- (e) 复根 Euler：x²y″ + xy′ + y = 0 ⟹ y = cos(ln x)/sin(ln x) ---
# 换元 t = ln x 化 y_tt + y = 0：数值对照
function rk4_2(f, x, y, yp, h)
    k1y, k1v = yp, f(x, y, yp)
    k2y, k2v = yp + h * k1v / 2, f(x + h / 2, y + h * k1y / 2, yp + h * k1v / 2)
    k3y, k3v = yp + h * k2v / 2, f(x + h / 2, y + h * k2y / 2, yp + h * k2v / 2)
    k4y, k4v = yp + h * k3v, f(x + h, y + h * k3y, yp + h * k3v)
    (y + h * (k1y + 2k2y + 2k3y + k4y) / 6, yp + h * (k1v + 2k2v + 2k3v + k4v) / 6)
end
t0, t1 = 0.0, 4pi
n = 24000
h = (t1 - t0) / n
tt, y, v = t0, 1.0, 0.0          # y(t=0) = 1, y'(0) = 0 ⟹ y = cos t
for _ in 1:n
    global y, v = rk4_2((t, yy, vv) -> -yy, tt, y, v, h)
    global tt += h
end
xend = exp(4pi)
@assert abs(y - cos(log(xend))) < 1e-8 "复根 Euler：y = cos(ln x) 与数值解一致"
println("复根 Euler：x=e^{4π} 处 y = ", round(y; digits=6), " vs cos(ln x) = ", round(cos(log(xend)); digits=6))

println("END ====")
