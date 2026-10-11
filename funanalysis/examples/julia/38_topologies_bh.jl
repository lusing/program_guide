using LinearAlgebra, Random
println("==== 38 topologies_bh (Julia) ====")
Random.seed!(3838)
# B(H) 拓扑层级：范数 ⊃ 强(SOT) ⊃ 弱算子(WOT)
# 单侧移位 S 的幂：SOT 发散（保范），WOT 收敛到 0
m, pad = 300, 60
x = zeros(m + pad)
x[1:m-pad] = randn(m - pad) .* exp.(-(1:m-pad) ./ 20)
y = randn(m + pad) .* exp.(-(1:m+pad) ./ 20)
shift(v, k) = [zeros(k); v[1:end-k]]
println("移位幂序列 Sᵏ（SOT vs WOT）：")
for k in [10, 30, 60]
    Sk = shift(x, k)
    println("  k = $k : ‖Sᵏx‖ = $(round(norm(Sk), digits=6))  |⟨Sᵏx,y⟩| = $(round(abs(dot(Sk, y)), digits=8))")
end
@assert abs(norm(shift(x, 30)) - norm(x)) < 1e-12
@assert abs(dot(shift(x, 60), y)) < abs(dot(shift(x, 10), y)) / 2
println("‖Sᵏx‖ 不变（SOT 不收敛 0）而 ⟨Sᵏx,y⟩ → 0（WOT → 0）：✓")

# 秩一投影 Pₖ = eₖeₖ*：SOT → 0 但范数恒 1
N = 1000
xd = 1.0 ./ (1:N)
xd ./= norm(xd)
for k in [10, 100, 1000]
    println("  ‖P_$(k) x‖ = $(round(abs(xd[k]), digits=6))，但 ‖P_$(k)‖ = 1")
end
@assert abs(xd[1000]) < abs(xd[10]) < 0.5
println("SOT 收敛到 0 未必范数收敛：✓")
println("==== 38 topologies_bh END ====")
