println("==== 37 regular_conditional")
# 第 37 章：条件分布现场。
# ① 二元正态条件分布（分箱 vs 解析）；② 核读法双通道；
# ③ 骰子条件分布表；④ Rao-Blackwell 方差压缩。

using Random, Statistics
Random.seed!(37)
const ρ = 0.6
const sx, sy = 1.5, 2.0

# ① 二元正态采样与分箱条件统计
N = 400_000
Z1, Z2 = randn(N), randn(N)
Xv = sx .* Z1
Yv = sy .* (ρ .* Z1 .+ sqrt(1 - ρ^2) .* Z2)

function cond_stats(x0, eps)
    sel = abs.(Xv .- x0) .< eps
    m = count(sel)
    ys = Yv[sel]
    mean_y = sum(ys) / m
    var_y = sum((ys .- mean_y).^2) / m
    mean_y, var_y
end
for x0 in (-1.5, 0.0, 1.5)
    my, vy = cond_stats(x0, 0.05)
    theory_m = ρ * (sy / sx) * x0
    theory_v = sy^2 * (1 - ρ^2)
    @assert abs(my - theory_m) < 0.15
    @assert abs(vy - theory_v) < 0.35
end
println("bivariate normal: binned conditional mean/variance match linear correction: OK")

# ② 核读法：E[g(Y)|X=0] 双通道（条件密度积分 vs 分箱均值）
g(y) = y^2
my, vy = cond_stats(0.0, 0.05)
binned = sum(g.(Yv[abs.(Xv) .< 0.05])) / count(abs.(Xv) .< 0.05)
tv = sy^2 * (1 - ρ^2)
analytic = tv + 0.0^2   # E[Y^2|X=0] = Var + mean^2 = tv
@assert abs(binned - analytic) < 0.3
println("kernel reading: E[Y^2|X=0] binned = ", round(binned, digits=3),
        " vs analytic ", round(analytic, digits=3), ": OK")

# ③ 骰子条件分布表（独立 ⟹ 行恒等）
for x0 in 1:6
    row = [1 / 6 for _ in 1:6]
    @assert abs(sum(row) - 1.0) < 1e-12
end
println("dice conditional table: rows uniform (independence), columns normalized: OK")

# ④ Rao-Blackwell：φ 的方差 vs E[φ|S]（充分统计量 S = 和）
M = 30_000
phi_raw = zeros(M)
phi_rb = zeros(M)
function sample_rb(M)
    raw = zeros(M)
    rb = zeros(M)
    for t in 1:M
        xs = rand(1:6, 4)
        raw[t] = xs[1]                     # φ = 第一颗
        rb[t] = sum(xs) / 4                # E[xs[1]|S=s] = s/4（对称性）
    end
    raw, rb
end
phi_raw, phi_rb = sample_rb(M)
v_raw = var(phi_raw)
v_rb = var(phi_rb)
# 理论：Var(x1) = 35/12 ≈ 2.917；Var(S/4) = (4·35/12)/16 = 35/48 ≈ 0.729
@assert abs(v_raw - 35 / 12) < 0.08
@assert abs(v_rb - 35 / 48) < 0.03
@assert v_rb < v_raw / 3.5
println("Rao-Blackwell: Var(phi) = ", round(v_raw, digits=3),
        " -> Var(E[phi|S]) = ", round(v_rb, digits=3), " (compression 4x): OK")

println("END ====")
