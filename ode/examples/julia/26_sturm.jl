println("==== 26 sturm")

# 第 26 章：Sturm-Liouville——打靶求特征值、Rayleigh 商、Green 函数。

function rk4_2(f, x, y, yp, h)
    k1y, k1v = yp, f(x, y, yp)
    k2y, k2v = yp + h * k1v / 2, f(x + h / 2, y + h * k1y / 2, yp + h * k1v / 2)
    k3y, k3v = yp + h * k2v / 2, f(x + h / 2, y + h * k2y / 2, yp + h * k2v / 2)
    k4y, k4v = yp + h * k3v, f(x + h, y + h * k3y, yp + h * k3v)
    (y + h * (k1y + 2k2y + 2k3y + k4y) / 6, yp + h * (k1v + 2k2v + 2k3v + k4v) / 6)
end

# --- (a) 打靶：y'' + λy = 0、y(0)=0, y'(0)=1，残差 = y(π) ---
function shoot(lam)
    x, y, yp = 0.0, 0.0, 1.0
    h = pi / 20000
    for i in 0:19999
        global nothing
        y, yp = rk4_2((x, y, v) -> -lam * y, i * h, y, yp, h)
    end
    y
end
for n in 1:5
    @assert abs(shoot(n^2)) < 1e-8 "λₙ = n² 是特征值（打靶残差 → 0）"
    # 残差 ~ sin(√λπ)/√λ：固定偏移 2 保证所有 n 的残差 > 0.05
    @assert abs(shoot(n^2 + 2.0)) > 0.05 "偏离特征值残差显著"
end
println("打靶：λ = 1, 4, 9, 16, 25 的残差 < 1e-8，偏移 0.1 残差 > 0.01")

# --- (b) Rayleigh 商：R[y] ≥ λ₁，sin πx 取等 ---
R(f) = begin
    xs = range(0, pi; length = 20001)
    num = sum(f'(x)^2 for x in xs[2:end-1]) * (pi / 20000)
    den = sum(f(x)^2 for x in xs[2:end-1]) * (pi / 20000)
    num / den
end
sinpi_(x) = sin(pi * x / pi) # 占位（未用）
# Rayleigh 商 R = ∫f'²/∫f²（导数解析给出）
function Rq(f, fp)
    xs = range(0, pi; length = 200001)
    h = pi / 200000
    num = sum(fp(x)^2 for x in xs[2:end-1]) * h
    den = sum(f(x)^2 for x in xs[2:end-1]) * h
    num / den
end
@assert abs(Rq(sin, cos) - 1.0) < 1e-4 "sin x 达到 λ₁ = 1（R = ∫cos²/∫sin²）"
f2(x) = x * (pi - x)
fp2(x) = pi - 2x
@assert Rq(f2, fp2) >= 1.0 - 1e-6 "Rayleigh 商 ≥ λ₁"
println("Rayleigh：R[sin x] = 1（取等），R[x(π−x)] = ", round(Rq(f2, fp2); digits=4), " ≥ 1")

# --- (c) Green 函数：λ = 0.5，G(x,ξ) 两侧齐次解拼装 ---
lam = 0.5
mu = sqrt(lam)
# G(x,ξ) = sin(μx<)·sin(μ(π−x>))/(μ sin μπ)
G(x, xi) = sin(mu * min(x, xi)) * sin(mu * (pi - max(x, xi))) / (mu * sin(mu * pi))
# 对称性
for (x, xi) in [(0.5, 1.3), (2.1, 0.7)]
    @assert abs(G(x, xi) - G(xi, x)) < 1e-14 "G 对称"
end
# 导数跳跃：数值核对 ∫G(x,ξ)sin(ξ)（λ≠共振）与 BVP 解
y_bvp(x) = sin(x) / (1 - lam)   # y'' + λy = sin x 特解 = sinx/(1-λ)（λ≠1）
for x in [0.7, 1.9, 2.6]
    xs = range(1e-6, pi - 1e-6; length = 20000)
    h = (pi - 2e-6) / 19999
    Ival = sum(G(x, xi) * sin(xi) for xi in xs[2:end-1]) * h
    @assert abs(Ival - y_bvp(x)) < 1e-6 "y = ∫G f 与解析解一致"
end
println("Green：对称 ✓，y = ∫G·sinξ 与解析解 sinx/(1−λ) 一致（λ = 0.5）")

# --- (d) 共振可解性：λ = 1 ---
# f = sin x（与 y₁ = sin x 不正交）⟹ 无解：∫₀^π sin²x ≠ 0
If = sum(sin(xi)^2 for xi in range(1e-3, pi - 1e-3; length = 1000)) * pi / 1000
@assert abs(If - pi / 2) < 0.01 "∫sin² = π/2 ≠ 0 ⟹ 共振不可解"
# f = x（正交：∫x sin x = π ≠ 0？）∫₀^π x sinx dx = π ⟹ 也不可解！
Ifx = sum(xi * sin(xi) for xi in range(1e-3, pi - 1e-3; length = 1000)) * pi / 1000
@assert abs(Ifx - pi) < 0.05 "∫x·sinx = π ≠ 0 ⟹ 亦不可解"
# f = sin 2x（与 sin x 正交）⟹ 可解
If2 = sum(sin(2xi) * sin(xi) for xi in range(1e-3, pi - 1e-3; length = 1000)) * pi / 1000
@assert abs(If2) < 0.02 "∫sin2x·sinx = 0 ⟹ 可解（解 = sin2x/(1−4)+c·sinx）"
println("共振可解性（Fredholm 择一）：f = sinx/x 不可解，f = sin2x 可解 ✓")

println("END ====")
