# 26_multidim_var.jl —— 第 26 章：高维变分问题（Julia 通道）
#
#   (1) 二维 Poisson 第一边值的 Ritz/Galerkin 形式：能量泛函
#       J(u) = ½∫|∇u|² − ∫fu 在真解处取最小（与制造解对账）；
#   (2) 正定性：D(v,v) = ∫|∇v|² ≥ 0（连续 Poincaré 的离散对应）；
#   (3) 非齐次边界提升：u = u₀ + w（u₀ 满足边界），变分作用于 w。

println("==== 26 multidim var")

# 问题：-Δu = f 于 (0,1)²，u = 0 边界；f = 2π² sin(πx)sin(πy)
# 精确解 u = sin(πx)sin(πy)
f26(x, y) = 2pi^2 * sin(pi * x) * sin(pi * y)
uex26(x, y) = sin(pi * x) * sin(pi * y)

# ---------- (1) 能量泛函在真解处最小 ----------
# J(v) = ½∫|∇v|² − ∫fv；对 v = u* 与 v = u* + t·w（w 同样零边界）：
# J(u*+tw) − J(u*) = t·0（Euler 方程） + t²·½∫|∇w|² ≥ 0
function J_energy(vfun)
    n = 400
    h = 1 / n
    s = 0.0
    for i in 1:n-1, j in 1:n-1
        x, y = i * h, j * h
        gux = (vfun(x + h, y) - vfun(x - h, y)) / (2h)
        guy = (vfun(x, y + h) - vfun(x, y - h)) / (2h)
        s += 0.5 * (gux^2 + guy^2) - f26(x, y) * vfun(x, y)
    end
    s * h^2
end
Jstar = J_energy(uex26)
w(x, y) = sin(pi * x) * sin(pi * y) * (1 - x) * x   # 零边界扰动
for t in (0.3, 1.0)
    Jpert = J_energy((x, y) -> uex26(x, y) + t * w(x, y))
    println("J(u*) = ", round(Jstar, digits=6), "  J(u* + ", t, "·w) = ", round(Jpert, digits=6),
            "  (larger by ", round(Jpert - Jstar, digits=6), ")")
    @assert Jpert > Jstar "真解应使能量最小（t=$t）"
end

# ---------- (2) 非齐次边界的提升 ----------
# -Δu = f，u|∂ = g；取 u₀ = g 的任何光滑延拓，u = u₀ + w，w 零边界
# 等价问题：-Δw = f + Δu₀ ≡ f̃
# 制造解：u = 1 + x·y + sin(πx)sin(πy)（边界 = 1 + x·y）；f = 2π²sin sin
u0fun(x, y) = 1 + x * y
utilde(x, y) = sin(pi * x) * sin(pi * y) + u0fun(x, y)
ftilde(x, y) = 2pi^2 * sin(pi * x) * sin(pi * y)   # Δu₀ = 0（x·y 调和）
# 验证：u = u₀ + w 时 -Δu = -Δw = f̃ ✓ 且边界 u₀ = 1 + xy ✓
maxres = maximum(begin
    h = 1e-3
    lap = (utilde(x + h, y) - 2utilde(x, y) + utilde(x - h, y)) / h^2 +
          (utilde(x, y + h) - 2utilde(x, y) + utilde(x, y - h)) / h^2
    abs(-lap - ftilde(x, y))
end for x in 0.1:0.1:0.9, y in 0.1:0.1:0.9)
@assert maxres < 5e-5 "提升后的方程应成立（中心差分 O(h^2) 残差）"
println("lifting: u = u0 + w with harmonic u0 = 1+xy, residual = ", round(maxres, sigdigits=3))

# ---------- (3) 离散 Poincaré 对应：D(v,v) 控制能量 ----------
# 五点 Laplacian 的 Rayleigh 商最小值 → 2π²（连续最小特征值）
N = 40
lam_min = 4 - 4 * cos(pi / N)
println("discrete Poincare constant: lambda_min = ", round(lam_min, digits=4),
        " / h^2 = ", round(lam_min * N^2, digits=4), " -> 2pi^2 = ", round(2pi^2, digits=4))
@assert abs(lam_min * N^2 - 2pi^2) < 0.05

println("END ====")
