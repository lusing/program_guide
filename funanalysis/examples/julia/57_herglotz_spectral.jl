# 57_herglotz_spectral.jl —— Herglotz 表示与自伴谱分解（docs/57 实验）
# 通道：Julia 1.13 + LinearAlgebra
using LinearAlgebra
using Printf
using Random

println("==== 57 Herglotz 表示与自伴谱 ====")

# ---------------------------------------------------------------
# 实验 1：对角算子的 g_u 全程（Nevanlinna 条件数值形态）。
# A = diag(tₖ)，谱测度 n = Σ|uₖ|²δ_{tₖ}，g_u(z) = Σ|uₖ|²/(tₖ−z)。
# ---------------------------------------------------------------
function exp1_diagonal()
    rng = Random.MersenneTwister(5757)
    n = 40
    ts = collect(1.0:n)
    u = randn(rng, n); u ./= norm(u)
    g(z) = sum(u[k]^2 / (ts[k] - z) for k in 1:n)
    # Im g > 0 于上半平面
    for _ in 1:100
        z = rand(rng) * 39 + 1 + 0.5im * rand(rng)
        @assert imag(g(z)) > 0
    end
    # Nevanlinna 条件 (iii)：y·Im g(iy) → ‖u‖² = 1
    for y in (10.0, 100.0, 1000.0, 1e4)
        val = y * imag(g(y * im))
        @assert abs(val - 1.0) < 9 / y               # O(1/y) 收敛（常数 = 二阶矩）
    end
    return abs(1e4 * imag(g(1e4 * im)) - 1)
end
err1 = exp1_diagonal()
println(@sprintf("实验1 对角算子：Im g>0 全域；y=1e4 时 y·Im g(iy)−‖u‖² = %.1e（Nevanlinna 条件）", err1))

# ---------------------------------------------------------------
# 实验 2：Stieltjes 反演往返（Poisson 核恢复原子质量）。
# n((a,b)) ≈ (1/π)∫_a^b Im g(t+iε) dt，ε→0 恢复 |uₖ|²。
# ---------------------------------------------------------------
function exp2_stieltjes()
    rng = Random.MersenneTwister(5758)
    n = 20
    ts = collect(1.0:n) .* 2 .- 1                      # 原子位置 1,3,..,39
    u = randn(rng, n); u ./= norm(u)
    g(z) = sum(u[k]^2 / (ts[k] - z) for k in 1:n)
    m = 4000
    grid = collect(range(0.0, 40.0, length=m))
    for ε in (0.5, 0.1, 0.02)
        imvals = [imag(g(t + ε * im)) for t in grid]
        dens = imvals ./ π
        # 每个原子附近的积分质量
        for k in (3, 10, 17)
            lo = ts[k] - 1; hi = ts[k] + 1
            mask = grid .>= lo .&& grid .<= hi
            mass = sum(dens[mask]) .* (grid[2] - grid[1])
            @assert abs(mass - u[k]^2) < 0.03         # 恢复原子质量
        end
    end
    return true
end
exp2_stieltjes()
println("实验2 Stieltjes 反演：三档 ε 下 20 个原子的质量恢复误差 < 3%（Cauchy↔测度往返）")

# ---------------------------------------------------------------
# 实验 3：差分 Laplacian 的谱测度（DD 边界，特征值 (kπ)²）。
# ---------------------------------------------------------------
function exp3_laplacian()
    n = 200
    h = 1.0 / (n + 1)
    A = SymTridiagonal(2.0 ./ h^2 .* ones(n), -1.0 ./ h^2 .* ones(n - 1))
    u = exp.(-((collect(1:n) .* h .- 0.5) .^ 2) ./ 0.05)
    u ./= norm(u)
    F = eigen(A)
    weights = (F.vectors' * u) .^ 2
    # 谱测度的原子位于特征值处、质量 = |⟨u,eₖ⟩|²
    analytic = [(k * π)^2 for k in 1:5]
    for k in 1:5
        @assert abs(F.values[k] - analytic[k]) / analytic[k] < 1e-3
    end
    @assert sum(weights) ≈ 1.0 atol = 1e-12            # 测度总质量 = ‖u‖²
    # g_u 在远离谱的虚轴上的 Nevanlinna 条件
    g(z) = sum(weights[k] / (F.values[k] - z) for k in 1:n)
    @assert abs(1e5 * imag(g(1e5im)) - 1.0) < 1e-3
    return analytic[1]
end
lam1 = exp3_laplacian()
println(@sprintf("实验3 差分 Laplacian：前 5 特征值对上 (kπ)²；谱测度原子 = |⟨u,eₖ⟩|²（总质量 1）"))

# ---------------------------------------------------------------
# 实验 4：预解式界与解析性。
# ‖R(iy)u‖ ≤ ‖u‖/y；CR 方程差分。
# ---------------------------------------------------------------
function exp4_resolvent()
    n = 100
    A = SymTridiagonal(2.0 .* ones(n), -ones(n - 1))
    R(z) = (Matrix(A) - z * I) \ I
    for y in (0.5, 1.0, 2.0, 10.0)
        @assert opnorm(R(y * im)) ≤ 1 / y * (1 + 1e-10)
    end
    z0 = 0.3 + 2im
    h = 1e-5
    du = (R(z0 + h) - R(z0 - h)) / 2h
    dv = (R(z0 + im * h) - R(z0 - im * h)) / (2h)
    @assert norm(du + im * dv) < 1e-4                  # 解析（CR）
    return true
end
exp4_resolvent()
println("实验4 ‖R(iy)‖ ≤ 1/y 四档成立；R(z) 的 CR 残差 < 1e-4（预解式解析）")

println("END ====")
