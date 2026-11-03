# 第 37 章 Julia：三大检验精确账、区间对偶与固定种子覆盖率。
using Random
using Statistics
println("==== 37 asymptotic tests")

function bernoulli_wald(n, k, p0)
    phat = k // n
    n * (phat - p0)^2 / (phat * (1 - phat))
end
function bernoulli_score(n, k, p0)
    phat = k // n
    n * (phat - p0)^2 / (p0 * (1 - p0))
end
function bernoulli_lr(n, k, p0)
    phat = k / n
    2 * (k * log(phat / p0) + (n - k) * log((1 - phat) / (1 - p0)))
end

n, k, p0 = 20, 12, 1 // 2
wald = bernoulli_wald(n, k, p0)
score = bernoulli_score(n, k, p0)
lr = bernoulli_lr(n, k, Float64(p0))
@assert wald == 5 // 6
@assert score == 4 // 5
@assert abs(lr - 2 * (12 * log(6 / 5) + 8 * log(4 / 5))) < 1e-12
# chi^2_1 是标准正态平方，故三个 p 值都可由正态尾计算。
function simpson(f, a, b, n)
    h = (b - a) / n
    total = f(a) + f(b)
    for i in 1:n-1
        total += (isodd(i) ? 4 : 2) * f(a + i * h)
    end
    total * h / 3
end
phi(x) = exp(-x^2 / 2) / sqrt(2 * pi)
Phi(x) = simpson(phi, -10.0, x, 6000)
chi2_1_sf(x) = 2 * (1 - Phi(sqrt(x)))
p_wald, p_score, p_lr = chi2_1_sf(Float64(wald)), chi2_1_sf(Float64(score)), chi2_1_sf(lr)
@assert 0.35 < p_wald < 0.38
@assert 0.35 < p_score < 0.38
@assert 0.35 < p_lr < 0.38
w16, s16, lr16 = bernoulli_wald(20, 16, p0), bernoulli_score(20, 16, p0), bernoulli_lr(20, 16, 0.5)
@assert w16 == 45 // 4 && s16 == 36 // 5
@assert w16 > lr16 > s16 > 3.841458820694124
println("Bernoulli W/LM/LR = ", wald, ", ", score, ", ", lr)
println("chi-square p-values = ", p_wald, ", ", p_score, ", ", p_lr)
println("K=16 W/LM/LR = ", w16, ", ", s16, ", ", lr16)

# z 区间就是所有不被双侧 z 检验拒绝的 mu0。
z95 = 1.959963984540054
normal_mean_interval(xbar, sigma, n) = (xbar - z95 * sigma / sqrt(n),
                                        xbar + z95 * sigma / sqrt(n))
not_rejected(xbar, sigma, n, mu0) = normal_mean_interval(xbar, sigma, n)[1] <= mu0 <= normal_mean_interval(xbar, sigma, n)[2]
interval = normal_mean_interval(11.5, 4.0, 16)
@assert not_rejected(11.5, 4.0, 16, 10)
@assert not_rejected(11.5, 4.0, 16, 12)
@assert !not_rejected(11.5, 4.0, 16, 14)
t_half_width = 2.093024054408263 * 8 / sqrt(20)
t_interval = (48 - t_half_width, 48 + t_half_width)
@assert t_interval[1] < 45 < t_interval[2]
familywise = 1 - 0.95^20
@assert abs(familywise - 0.641514) < 0.00001
println("normal interval = ", interval, "; t interval = ", t_interval)
println("20-test familywise error = ", familywise, "; Bonferroni = ", 0.05 / 20)

# 固定种子只审计 n=16 的覆盖率，不证明一般的对偶定理。
Random.seed!(37)
function coverage_audit(reps, n)
    tcrit15 = 2.131449545257323
    t_covered = 0
    z_covered = 0
    for _ in 1:reps
        sample = 10 .+ 4 .* randn(n)
        xbar = mean(sample)
        z_covered += abs(xbar - 10) <= z95 * 4 / sqrt(n)
        t_covered += abs(xbar - 10) <= tcrit15 * std(sample, corrected=true) / sqrt(n)
    end
    z_covered / reps, t_covered / reps
end
z_coverage, t_coverage = coverage_audit(20_000, 16)
@assert 0.94 < z_coverage < 0.96
@assert 0.94 < t_coverage < 0.96
println("fixed-seed z/t interval coverage = ", z_coverage, ", ", t_coverage)
println("END ====")
