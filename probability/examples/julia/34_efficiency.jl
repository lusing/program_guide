# 第 34 章 Julia：条件化改进与信息下界的精确枚举。
println("==== 34 efficiency")

function mean_and_variance(values)
    @assert sum(weight for (_, weight) in values) == 1
    mean = sum(value * weight for (value, weight) in values)
    second = sum(value^2 * weight for (value, weight) in values)
    mean, second - mean^2
end

# 对充分统计量 K 条件化：E[X1|K]=K/n。
n, p = 4, 1 // 3
raw = Tuple{Rational{Int}, Rational{Int}}[]
improved = Tuple{Rational{Int}, Rational{Int}}[]
for mask in 0:(2^n - 1)
    bits = digits(mask, base=2, pad=n)
    k = sum(bits)
    weight = p^k * (1 - p)^(n - k)
    push!(raw, (bits[1] // 1, weight))
    push!(improved, (k // n, weight))
end
raw_mean, raw_variance = mean_and_variance(raw)
rb_mean, rb_variance = mean_and_variance(improved)
@assert raw_mean == rb_mean == p
@assert raw_variance == p * (1 - p)
@assert rb_variance == p * (1 - p) / n
@assert rb_variance < raw_variance
println("Rao-Blackwell variances: ", raw_variance, " -> ", rb_variance)

# Bernoulli 均值达到 Cramer–Rao 下界。
n, p = 8, 1 // 4
weights = [(k, Rational{Int}(binomial(n, k)) * p^k * (1 - p)^(n - k))
           for k in 0:n]
phat_values = [(k // n, weight) for (k, weight) in weights]
mean_phat, var_phat = mean_and_variance(phat_values)
information = n / (p * (1 - p))
cr_bound = 1 / information
@assert mean_phat == p
@assert var_phat == cr_bound == p * (1 - p) / n
println("Bernoulli variance and CR bound: ", var_phat, ", ", cr_bound)

# 正态方差：未达到下界不妨碍 S^2 是 UMVU。
n, v = 10, 3 // 1
var_s2 = 2 * v^2 / (n - 1)
cr_v = 2 * v^2 / n
@assert var_s2 == 2
@assert cr_v == 9 // 5
@assert var_s2 - cr_v == 2 * v^2 / (n * (n - 1)) == 1 // 5
@assert cr_v / var_s2 == (n - 1) // n == 9 // 10
println("normal variance: Var(S^2), CR, efficiency: ",
        var_s2, ", ", cr_v, ", ", cr_v / var_s2)
println("END ====")
