# 第 31 章 Julia：风险排序、偏差—方差分解与有限样本审计。
using Random, Statistics

Random.seed!(31)
println("==== 31 estimation_models")

scaled_variance_risk(c, n) = (1 + 2 // (n - 1)) * c^2 - 2 * c + 1
n = 10
coefficients = Dict(
    "unbiased" => 1 // 1,
    "mle" => (n - 1) // n,
    "risk_optimal" => (n - 1) // (n + 1),
)
risks = Dict(name => scaled_variance_risk(c, n) for (name, c) in coefficients)
@assert risks["unbiased"] == 2 // (n - 1)
@assert risks["mle"] == (2n - 1) // n^2
@assert risks["risk_optimal"] == 2 // (n + 1)
@assert risks["risk_optimal"] < risks["mle"] < risks["unbiased"]
println("exact normalized risks: ", risks)

# a*xbar 的 MSE = ((a-1)mu)^2 + a^2 sigma^2/n。
a, mu, sigma2, size = 3 // 4, 2 // 1, 5 // 1, 10
bias = (a - 1) * mu
variance = a^2 * sigma2 / size
@assert bias^2 + variance == 17 // 32

# 只有 a+b 进入模型，单独的分量不可识别。
linked_bernoulli_probability(a, b) = 1 / (1 + exp(-(a + b)))
@assert linked_bernoulli_probability(0.2, 0.3) == linked_bernoulli_probability(0.5, 0.0)
@assert linked_bernoulli_probability(0.2, 0.3) != linked_bernoulli_probability(0.2, 0.4)
println("identification and bias-variance decomposition: OK")

# 固定种子只检查有限样本风险，不代替上面的精确公式。
reps, sigma = 100_000, 2.0
simulated = Dict(name => 0.0 for name in keys(coefficients))
for _ in 1:reps
    s2 = var(3.0 .+ sigma .* randn(n), corrected=true)
    for (name, c) in coefficients
        simulated[name] += (Float64(c) * s2 - sigma^2)^2 / sigma^4
    end
end
for name in keys(coefficients)
    @assert abs(simulated[name] / reps - Float64(risks[name])) < 0.012
end
println("fixed-seed n=10 risk simulation: OK")
println("END ====")
