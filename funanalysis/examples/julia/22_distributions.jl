# 第 22 章 · 分布的数值实验（Conway IV.5*）
using LinearAlgebra, Random
println("==== 22 distributions (Julia) ====")
Random.seed!(2222)
n = 200; xs = range(0, 1; length=n); h = 1/(n-1)
φ = x -> exp(-100*(x - 0.5)^2)
φv = φ.(xs)
δφ = φ(0.5)
println("<δ_{1/2}, φ> = φ(1/2) = $(round(δφ, digits=6))")
for σ in [0.1, 0.05, 0.02]
    g = x -> exp(-(x-0.5)^2/(2*σ^2)) / (σ*sqrt(2*pi))
    approx = sum(g.(xs) .* φv) * h
    println("  σ=$σ: ∫g·φ ≈ $(round(approx, digits=4))")
end
println("(narrow Gaussians → δ: values should approach $(round(δφ, digits=4)))")
println("==== 22 distributions END ====")
