# 第 29 章 Julia：Delta 方差、Slutsky 插入与二阶退化。
using Random, Statistics

Random.seed!(29)
println("==== 29 asymptotic_tools")

# 一阶 Delta 的三个精确代数结果。
delta_variance(derivative, base_variance) = derivative^2 * base_variance
@assert delta_variance(2 * 3, 5) == 180       # g(mu)=mu^2, mu=3, sigma^2=5
@assert delta_variance(1 / (2 * sqrt(4)), 4) == 1 / 4  # Poisson sqrt
p = 1 // 4
logit_derivative = 1 / (p * (1 - p))
@assert delta_variance(logit_derivative, p * (1 - p)) == 1 / (p * (1 - p))
println("Delta variances: square, variance stabilization, logit: OK")

# Bernoulli logit 的有限样本方差与插入标准误。
true_p = 0.25
n = 400
reps = 50_000
logits = Float64[]
studentized = Float64[]
for _ in 1:reps
    phat = count(_ -> rand() < true_p, 1:n) / n
    push!(logits, log(phat / (1 - phat)))
    push!(studentized, sqrt(n) * (phat - true_p) / sqrt(phat * (1 - phat)))
end
predicted = 1 / (n * true_p * (1 - true_p))
@assert abs(var(logits) / predicted - 1) < 0.08
# Bernoulli 偏态与插入分母带来有限样本均值偏差，故不把均值硬设为零。
@assert abs(mean(studentized)) < 0.04
@assert abs(var(studentized) - 1) < 0.05
println("Slutsky plug-in SE and Delta variance simulation: OK")

# g'(0)=0：对 N(0,1) 样本，n*xbar^2 精确服从 chi^2_1。
for size in (1, 10, 100)
    q = [size * (sum(randn() for _ in 1:size) / size)^2
         for _ in 1:20_000]
    @assert abs(mean(q) - 1) < 0.05
    @assert abs(var(q) - 2) < 0.12
end
println("second-order Delta: chi-square_1 mean=1 and variance=2: OK")

# op(1) 与 Op(1) 的确定性原型。
scales = [1 / sqrt(k) for k in (1, 10, 100, 1000)]
@assert issorted(scales, rev=true)
@assert all(abs(2 + 3 * scale) <= 5 for scale in scales)
println("op(1) shrinkage and Op(1) bound: OK")

println("END ====")
