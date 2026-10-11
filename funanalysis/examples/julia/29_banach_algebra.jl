using LinearAlgebra, Random
println("==== 29 banach_algebra (Julia) ====")
Random.seed!(2929)
n = 5

# Neumann 级数：‖A‖ < 1 ⟹ (I-A)⁻¹ = Σₖ Aᵏ
A = randn(n, n)
A = 0.5 * A / opnorm(A)          # 归一化到 ‖A‖ = 0.5 < 1
@assert opnorm(A) < 1
function neumann(A; K = 80)
    S = Matrix{Float64}(I, size(A, 1), size(A, 1))
    term = copy(S)
    for _ in 1:K
        term = term * A
        S += term
    end
    return S
end
S = neumann(A)
println("‖Σ Aᵏ - (I-A)⁻¹‖ = $(round(norm(S - inv(I - A)), digits=12))")
@assert norm(S - inv(I - A)) < 1e-10
println("Neumann 级数收敛到 (I-A)⁻¹：✓")

# Gelfand 谱半径公式：r(A) = lim ‖Aᵏ‖^{1/k}
Random.seed!(29290)                 # 固定本实验的随机状态，与上文解耦
V = Matrix{Float64}(I, n, n) + 0.2 * randn(n, n)
d = [0.9, 0.7, 0.5, 0.3, 0.1]
B = V * Diagonal(d) / V
println("Gelfand 公式 r(B) = lim ‖Bᵏ‖^(1/k)（真值 0.9）：")
for k in [1, 2, 5, 10, 50, 200]
    r = opnorm(B^k)^(1 / k)
    println("  k = $k : ‖Bᵏ‖^(1/k) = $(round(r, digits=6))")
end
@assert abs(opnorm(B^200)^(1 / 200) - 0.9) < 3e-3

# 预解式 λ ↦ (λI - B)⁻¹ 在谱附近爆破
println("预解式范数趋近谱时爆破：")
ts = [1.0, 0.2, 0.05, 0.01]
res = [opnorm(inv(t * I - B)) for t in ts]
for (t, nR) in zip(ts, res)
    println("  λ = 0.9 + $t : ‖(λI-B)⁻¹‖ = $(round(nR, sigdigits=4))")
end
@assert minimum(res) > 10
@assert maximum(res) > 15
println("==== 29 banach_algebra END ====")
