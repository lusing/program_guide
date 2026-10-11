using LinearAlgebra, Random
println("==== 34 cstar-algebra (Julia) ====")
Random.seed!(3434)
A = randn(5, 5) + im * randn(5, 5)
lhs = opnorm(A' * A)
rhs = opnorm(A)^2
println("C* identity: ||A*A|| = $(round(lhs, digits=8))  ||A||² = $(round(rhs, digits=8))")
@assert abs(lhs - rhs) < 1e-10
println("==== 34 cstar-algebra END ====")
