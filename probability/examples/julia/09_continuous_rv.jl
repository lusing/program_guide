# -*- coding: utf-8 -*-
println("==== 09 continuous_rv")
# 第 09 章 Julia：连续随机变量的模拟对拍。
# ① 密度 2x 的逆变换采样（X = √U）：P(X ≤ 1/4) ≈ 1/16、
#    均值 ≈ 2/3；② 多项式密度 (6/11)(2+3x-5x²) 的拒绝采样：
#    均值 ≈ 9/22、P(X ≤ 1/2) ≈ 7/11；③ 均匀的区间账（长度比）；
# ④ 单点概率为零：10⁶ 样本中恰等于目标值的个数 = 0。
using Random, Statistics

Random.seed!(9)

# ① 逆变换采样：F(x) = x² ⟹ X = √U
X = sqrt.(rand(1_000_000))
@assert abs(count(<=(0.25), X) / length(X) - 1 / 16) < 0.002
@assert abs(mean(X) - 2 / 3) < 0.003
println("f(x)=2x via X=sqrt(U): P(X<=1/4)≈1/16, mean≈2/3: OK")

# ② 多项式密度的拒绝采样（包络常数 1.5 ≥ max f ≈ 1.336）
fpoly(x) = (6 / 11) * (2 + 3x - 5x^2)
function sample_poly(n)
    out = Float64[]
    while length(out) < n
        x, u = rand(), rand()
        u * 1.5 <= fpoly(x) && push!(out, x)
    end
    out
end
Y = sample_poly(200_000)
@assert 0 <= minimum(Y) && maximum(Y) <= 1       # 支撑集 [0,1]
@assert abs(mean(Y) - 9 / 22) < 0.003            # E[X] = 9/22 ≈ 0.409
@assert abs(count(<=(0.5), Y) / length(Y) - 7 / 11) < 0.005  # F(1/2) = 7/11
println("poly density by rejection: mean≈9/22, F(1/2)≈7/11: OK")

# ③ 均匀 U[0,1]：P(1/4 ≤ X ≤ 3/4) = 长度比 1/2
U = rand(2_000_000)
@assert abs(count(x -> 0.25 <= x <= 0.75, U) / length(U) - 0.5) < 0.003
println("uniform interval probability = length ratio 1/2: OK")

# ④ 单点概率为零：连续样本恰命中 0.3 的次数
Z = rand(1_000_000)
@assert count(==(0.3), Z) == 0
println("P(X = 0.3) empirically 0/10^6 (point mass = 0): OK")

println("END ====")
