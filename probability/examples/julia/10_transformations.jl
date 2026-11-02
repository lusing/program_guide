# -*- coding: utf-8 -*-
println("==== 10 transformations")
using Random, Statistics
Random.seed!(10)

# 单调平方：X~U[0,2]，Y=X^2，F_Y(y)=sqrt(y)/2。
U = rand(400_000)
X = 2 .* U
Y = X .^ 2
for (lo, hi) in ((0.01, 0.04), (0.25, 0.64), (1.0, 4.0))
    empirical = count(y -> lo <= y <= hi, Y) / length(Y)
    exact = (sqrt(hi) - sqrt(lo)) / 2
    @assert abs(empirical - exact) < 0.005
end
@assert abs(mean(Y) - 4/3) < 0.01
println("increasing square transform: CDF intervals and LOTUS: OK")

# 减函数 Y=3-2X，X~U[0,1]；Y 仍在 [1,3] 上均匀。
D = 3 .- 2 .* U
@assert abs(count(<=(2.0), D) / length(D) - 0.5) < 0.005
@assert abs(mean(D) - 2.0) < 0.01
println("decreasing affine transform: endpoint reversal checked: OK")

# 非单调平方：X~U[-1,1]，F_Y(y)=sqrt(y)。
S = 2 .* rand(400_000) .- 1
Q = S .^ 2
for y in (0.04, 0.25, 0.64)
    empirical = count(<=(y), Q) / length(Q)
    @assert abs(empirical - sqrt(y)) < 0.005
end
println("nonmonotone square: two inverse branches give F(y)=sqrt(y): OK")

# 广义逆采样混合分布：u<=1/2 落在原子 0，其余在连续斜坡。
M = [u <= 0.5 ? 0.0 : 2 * (u - 0.5) for u in U]
@assert abs(count(==(0.0), M) / length(M) - 0.5) < 0.003
@assert abs(mean(M) - 0.25) < 0.003
println("generalized inverse reproduces atom and continuous part: OK")

# 逆变换采样不是证明；上面的核心断言均由 CDF 精确式给出目标。
println("END ====")
