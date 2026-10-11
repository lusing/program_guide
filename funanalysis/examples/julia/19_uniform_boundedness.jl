# 第 19 章 · 一致有界原理的数值实验（Conway III.14）
using LinearAlgebra, Random
println("==== 19 uniform-boundedness (Julia) ====")
Random.seed!(1919)
n, m = 20, 100
Ts = [randn(n, n) / sqrt(n) for _ in 1:m]
function pw_bound(Ts, pts)
    best = 0.0
    for p in pts
        for T in Ts
            v = norm(T * p)
            v > best && (best = v)
        end
    end
    return best
end
raw = [randn(n) for _ in 1:100]; pts = [v / norm(v) for v in raw]
pb = pw_bound(Ts, pts)
ub = maximum(opnorm(T) for T in Ts)
println("pointwise sup = $(round(pb, digits=4))")
println("uniform sup = $(round(ub, digits=4))")
@assert ub >= pb
@assert ub < 10.0
println("finite dim: both bounded (theorem matters in infinite dim)")
println("==== 19 uniform-boundedness END ====")
