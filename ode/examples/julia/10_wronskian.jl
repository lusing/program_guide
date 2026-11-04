println("==== 10 wronskian")

# 第 10 章：Wronskian / Abel / 参数变易。

rk4_2(f, x, y, yp, h) = begin
    k1y, k1v = yp, f(x, y, yp)
    k2y, k2v = yp + h * k1v / 2, f(x + h / 2, y + h * k1y / 2, yp + h * k1v / 2)
    k3y, k3v = yp + h * k2v / 2, f(x + h / 2, y + h * k2y / 2, yp + h * k2v / 2)
    k4y, k4v = yp + h * k3v, f(x + h, y + h * k3y, yp + h * k3v)
    (y + h * (k1y + 2k2y + 2k3y + k4y) / 6, yp + h * (k1v + 2k2v + 2k3v + k4v) / 6)
end
# 基本组轨道：从 (1,0) 与 (0,1) 出发积分齐次方程，返回 (y1, y1', y2, y2')
function fundamental(f, x0, x1; n = 24000)
    h = (x1 - x0) / n
    x = x0
    y1, v1 = 1.0, 0.0
    y2, v2 = 0.0, 1.0
    for _ in 1:n
        y1, v1 = rk4_2(f, x, y1, v1, h)
        y2, v2 = rk4_2(f, x, y2, v2, h)
        x += h
    end
    (y1, v1, y2, v2)
end

# --- (a) Abel 三例：W 数值 vs e^{-∫p} ---
# 例 A：y'' - y = 0（p=0），W 恒 -2
fA(x, y, v) = y
y1, v1, y2, v2 = fundamental(fA, 0.0, 1.7)
Wnum = y1 * v2 - y2 * v1
@assert abs(Wnum - 1.0) < 1e-9 "例 A：W(cosh, sinh) = W(0) = 1（p = 0 守恒）"
println("例 A：W(cosh x, sinh x)(1.7) = ", round(Wnum; digits=8), "（恒 1，p = 0）")

# 例 B：y'' + 2y' + y = 0（p=2），W = e^{-2x}
fB(x, y, v) = -2v - y
y1, v1, y2, v2 = fundamental(fB, 0.0, 1.3)
@assert abs((y1 * v2 - y2 * v1) - exp(-2 * 1.3)) < 1e-9 "例 B W = e^{-2x}"
println("例 B：W(1.3) = ", round(y1 * v2 - y2 * v1; digits=8), " vs e^{-2.6} = ", round(exp(-2.6); digits=8))

# 例 C：x²y'' + 4xy' - 4y = 0（p = 4/x），W ∝ x^{-4}
fC(x, y, v) = (-4x * v + 4y) / x^2
y1, v1, y2, v2 = fundamental(fC, 1.0, 3.0)
W3 = y1 * v2 - y2 * v1                    # 基组从 (1,0),(0,1) 出发：W(1) = 1
@assert abs(W3 - 3.0^-4) < 1e-8 "例 C Abel：W(3) = e^{-∫4/x dx} = 3⁻⁴"
println("例 C：W(3) = ", round(W3; digits=8), " vs Abel 3⁻⁴ = ", round(3.0^-4; digits=8))

# --- (b) 线性无关实验：2×2 方程组只有零解（系数行列式 = W ≠ 0）---
# 数值上：对随机 (a,b) ≠ 0，函数 a·y₁ + b·y₂ 在 x₀ 的 (值,导数) 不可能同时为零
using Random
Random.seed!(11)
fBsol(x) = exp(-x)
gBsol(x) = x * exp(-x)
ok = true
for _ in 1:500
    a, b = randn(), randn()
    (a == 0 && b == 0) && continue
    W = fBsol(1.0) * (gBsol(1.0) + 1 * gBsol(1.0) * 0) - gBsol(1.0) * fBsol(1.0)  # 占位
    # 真正的判据：|a y1(1) + b y2(1)| + |a y1'(1) + b y2'(1)| > 0
    v = a * exp(-1.0) + b * 1.0 * exp(-1.0)
    d = a * (-exp(-1.0)) + b * (exp(-1.0) - 1.0 * exp(-1.0))
    global ok = ok && ((abs(v) + abs(d)) > 1e-12)
end
@assert ok "非零组合的 (值,导数) 不得同时为零"
println("线性无关：500 组随机非零组合的 (值, 导数) 不同时为零")

# --- (c) 参数变易：y'' + y = tan x，特解 -cos x·ln|sec x + tan x| ---
ysol(x) = -cos(x) * log(sec(x) + tan(x))
for x in [0.3, 0.8, 1.1]
    h = 1e-5
    ypp = (ysol(x + h) - 2ysol(x) + ysol(x - h)) / h^2
    @assert abs(ypp + ysol(x) - tan(x)) < 1e-4 "参数变易特解残差（O(h²) 差商）"
end
println("参数变易：ȳ = -cos x·ln|sec x + tan x| 满足 y''+y = tan x（3 点核对）")

# --- (d) 叠加原理：g₁+g₂ 的特解 = 特解之和 ---
# y'' + y = sin x 的特解 -x cos x/2；y'' + y = x 的特解 x；之和满足 y''+y = sin x + x
yp(x) = -x * cos(x) / 2 + x
for x in [0.5, 1.5, 2.5]
    h = 1e-5
    ypp = (yp(x + h) - 2yp(x) + yp(x - h)) / h^2
    @assert abs(ypp + yp(x) - (sin(x) + x)) < 1e-4 "叠加特解残差"
end
println("叠加：ȳ = -xcosx/2 + x 满足 y''+y = sin x + x（3 点核对）")

println("END ====")
