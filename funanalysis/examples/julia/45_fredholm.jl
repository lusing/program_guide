using LinearAlgebra, Random
println("==== 45 fredholm (Julia) ====")
Random.seed!(4545)
n = 6
I6 = Matrix{Float64}(I, n, n)

# 秩一摄动的行列式引理：det(I + t·uv') = 1 + t·v'u
u = randn(n); v = randn(n)
println("t        det(I+tuv')   1+t·v'u")
ts = [0.1, 0.5, 1.0, 2.0]
dets = [det(I6 + t * u * v') for t in ts]
rhss = [1 + t * dot(v, u) for t in ts]
for (t, lhs, rhs) in zip(ts, dets, rhss)
    println("$(rpad(t, 6))  $(rpad(round(lhs, digits=8), 14)) $(round(rhs, digits=8))")
end
@assert all(abs.(dets .- rhss) .< 1e-8 .* (1 .+ abs.(rhss)))
println("行列式引理（Fredholm 摄动的解析原型）：✓")

# Fredholm 二择一：u'v = -1 时 I + uv' 奇异，且指标 = 0
w = randn(n)
v0 = -w / dot(w, u)                # 保证 u'v0 = -1
M = I6 + u * v0'
kerdim = size(nullspace(M), 2)
cokerdim = size(nullspace(M'), 2)
println("奇异情形：dim ker = $(kerdim)，dim coker = $(cokerdim)")
@assert kerdim == 1
@assert cokerdim == 1
@assert kerdim - cokerdim == 0
println("有限维恒有 index = dim ker - dim coker = 0（rank-nullity）：✓")

# 无穷维指标：单侧移位 index(S) = -1 是纯无穷维现象
# 有限截断 Fₙ（前移，F eₙ = 0）：ker = 1 维，余核 = 1 维，指标 0
Fn = zeros(n, n)
for i in 1:n-1
    Fn[i+1, i] = 1.0
end
println("截断前移：dim ker = $(size(nullspace(Fn), 2))，rank = $(rank(Fn))（缺 e₁，coker = 1）")
@assert size(nullspace(Fn), 2) == 1
@assert rank(Fn) == n - 1
println("无穷维极限：ker(S)=0 且 ran(S) 缺 e₁ ⟹ index(S) = 0-1 = -1（解析事实）")

# 谱在紧摄动下：I + 紧 的特征值只能聚在 1
i6 = collect(1.0:30.0)
H30 = [1.0 / (i + j - 1) for i in i6, j in i6]      # 紧算子截断
for t in [0.5, 0.1, 0.02]
    λ = eigvals(I + t * H30)
    println("t = $t ：max|λ - 1| = $(round(maximum(abs.(λ .- 1)), sigdigits=3))（上界 t·‖H‖ = $(round(t * opnorm(H30), sigdigits=3))）")
end
@assert maximum(abs.(eigvals(I + 0.02 * H30) .- 1)) < 0.02 * opnorm(H30) + 1e-9
println("紧摄动把谱锁在 1 附近：σ_ess(I + K) = {1}：✓")
println("==== 45 fredholm END ====")
