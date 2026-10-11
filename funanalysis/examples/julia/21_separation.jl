# 第 21 章 · 分离定理的数值实验（Conway IV.3）
using LinearAlgebra, Random
println("==== 21 separation (Julia) ====")
Random.seed!(2121)
center_B = [3.0, 0.0]; rB = 0.5
n_vec = center_B / norm(center_B)
c = 1.0 + (norm(center_B) - rB - 1.0) / 2
println("separating hyperplane: <x, n> = c = $(round(c, digits=4))")
function checkA()
    v = randn(2); pA = v / norm(v)
    return dot(pA, n_vec) < c
end
function checkB()
    v = randn(2); pB = center_B + rB * v / norm(v)
    return dot(pB, n_vec) > c
end
okA = all(checkA() for _ in 1:500)
okB = all(checkB() for _ in 1:500)
println("all ball A points < c: $okA")
println("all ball B points > c: $okB")
@assert okA && okB
println("==== 21 separation END ====")
