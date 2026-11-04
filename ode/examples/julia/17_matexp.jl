println("==== 17 matexp")

# 第 17 章：矩阵指数——级数 vs 特征分解 vs Putzer 公式。
using LinearAlgebra

# --- (a) 级数定义的 e^{At} ---
function matexp_series(A, t; tol = 1e-16, maxterm = 40)
    n = size(A, 1)
    E = Matrix{Float64}(I, n, n)
    term = Matrix{Float64}(I, n, n)
    for k in 1:maxterm
        term = term * A * (t / k)
        E += term
        norm(term) < tol && break
    end
    E
end

# 实异根
A1 = [2.0 1.0; 1.0 2.0]
# 复根
A2 = [1.0 -2.0; 2.0 1.0]
# 重根 Jordan
A3 = [1.0 1.0; 0.0 1.0]
for (name, A) in [("实异根", A1), ("复根", A2), ("重根", A3)]
    Es = matexp_series(A, 0.7)
    Eb = exp(A * 0.7)
    @assert norm(Es - Eb) / norm(Eb) < 1e-12 "$(name)：级数 vs 内建"
end
println("三情形 e^{At}：级数（≤40 项）vs exp(A·t) 相对差 < 1e-12")

# --- (b) Putzer 2×2 公式：e^{At} = e^{τt/2}[cosh(κt)I + sinh(κt)/κ (A - τI/2)] ---
function putzer2(A, t)
    τ = tr(A)
    κ² = τ^2 / 4 - det(A)
    B = A - (τ / 2) * Matrix{Float64}(I, 2, 2)
    if κ² > 1e-14
        κ = sqrt(κ²)
        exp(τ * t / 2) * (cosh(κ * t) * Matrix{Float64}(I, 2, 2) + sinh(κ * t) / κ * B)
    elseif κ² < -1e-14
        κ = sqrt(-κ²)
        exp(τ * t / 2) * (cos(κ * t) * Matrix{Float64}(I, 2, 2) + sin(κ * t) / κ * B)
    else
        exp(τ * t / 2) * (Matrix{Float64}(I, 2, 2) + t * B)
    end
end
for A in [A1, A2, A3]
    @assert norm(putzer2(A, 0.9) - exp(A * 0.9)) / norm(exp(A * 0.9)) < 1e-12 "Putzer 公式"
end
println("Putzer 2×2 公式（cosh/sinh/cos/sin 三态）与 exp(A·t) 一致")

# --- (c) 解方程：x(t) = e^{At}x₀ ---
u0 = [1.0, -2.0]
xf = exp(A2 * 1.3) * u0
# RK4 数值
function rk4vec(f, t, u, h)
    k1 = f(t, u)
    k2 = f(t + h / 2, u .+ h .* k1 ./ 2)
    k3 = f(t + h / 2, u .+ h .* k2 ./ 2)
    k4 = f(t + h, u .+ h .* k3)
    u .+ h .* (k1 .+ 2 .* k2 .+ 2 .* k3 .+ k4) ./ 6
end
h = 1.3 / 13000
t, u = 0.0, copy(u0)
for _ in 1:13000
    global u = rk4vec((t, u) -> A2 * u, t, u, h)
    global t += h
end
@assert norm(u - xf) < 1e-8 "e^{At}x₀ vs RK4"
println("x = e^{At}x₀ 与 RK4 数值一致（差 ", norm(u - xf), "）")

# --- (d) 性质：det e^{At} = e^{tr(A)t}；不可交换反例 ---
for A in [A1, A2, A3]
    @assert abs(det(exp(A * 0.8)) - exp(tr(A) * 0.8)) < 1e-9 "det e^{At}"
end
println("det e^{At} = e^{tr(A)·t}（三例）")
B = [0.0 1.0; 0.0 0.0]
C = [0.0 0.0; 1.0 0.0]
gap = norm(exp(B + C) - exp(B) * exp(C))
@assert gap > 0.1 "不可交换反例"
println("反例：‖e^{B+C} − e^B e^C‖ = ", round(gap; digits=4), " > 0（B、C 不可交换）")

println("END ====")
