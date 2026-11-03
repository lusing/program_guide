# 第 36 章 Julia：精确 NP 尾概率、正态功效与固定种子审计。
using Random
using Statistics
println("==== 36 hypothesis testing")

function binomial_tail(n, k, p)
    sum(binomial(n, j) * p^j * (1 - p)^(n - j) for j in k:n)
end

# 五点 Bernoulli 样本，拒绝 K>=4。
n, p0, p1 = 5, 1 // 4, 3 // 4
@assert 3^(2 * 4 - n) == 27
size = binomial_tail(n, 4, p0)
power = binomial_tail(n, 4, p1)
@assert size == 1 // 64
@assert power == 81 // 128
@assert 1 - power == 47 // 128
@assert binomial_tail(n, 3, p0) == 53 // 512
boundary_reject = 1 // 5
randomized_size = size + boundary_reject * (binomial_tail(n, 3, p0) - size)
randomized_power = power + boundary_reject * (binomial_tail(n, 3, p1) - power)
@assert randomized_size == 17 // 512
@assert randomized_power == 351 // 512
println("Bernoulli NP: size/power = ", size, ", ", power,
        "; randomized = ", randomized_size, ", ", randomized_power)

# Simpson 积分只用于正态/t 的连续尾概率；离散账保持有理数。
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

zcrit = 1.6448536269514722
z95 = 1.959963984540054
noncentrality = (12 - 10) * sqrt(16) / 4
power_at_12 = Phi(noncentrality - zcrit)
@assert noncentrality == 2
@assert abs(power_at_12 - 0.63876) < 0.0001
zobs = (11.5 - 10) / (4 / sqrt(16))
p_upper = 1 - Phi(zobs)
@assert zobs == 1.5
@assert abs(p_upper - 0.0668072) < 0.0001
ci = (11.5 - z95, 11.5 + z95)
@assert ci[1] < 10 < ci[2] && ci[1] < 12 < ci[2]
println("normal critical/power = ", zcrit, ", ", power_at_12)
println("z=1.5 upper p = ", p_upper, "; CI = ", ci)
println("power curve = ", [round(Phi(mu - 10 - zcrit), digits=6)
                           for mu in (10, 10.5, 11, 12, 13)])

# 旧章 z/t 对照与 Welch 自由度迁移。
tstat = (48 - 45) / (8 / sqrt(20))
function t19_pdf(x)
    # Γ(10)=9!，Γ(19/2)=(17!!/2^9)sqrt(pi)，避免额外包依赖。
    c = factorial(9) / (sqrt(19 * pi) * (prod(1:2:17) / 2^9 * sqrt(pi)))
    c * (1 + x^2 / 19)^(-10)
end
p_z = 1 - Phi(tstat)
p_t = simpson(t19_pdf, tstat, 15.0, 6000)
@assert p_z < 0.05 < p_t < 0.06
xbar, ybar, sx2, sy2, nx, ny = 83.5, 75.4, 168.6, 73.32, 14, 14
welch_nu = ((sx2 / nx + sy2 / ny)^2 /
            (sx2^2 / (nx^2 * (nx - 1)) + sy2^2 / (ny^2 * (ny - 1))))
@assert abs(welch_nu - 22.5) < 0.15
@assert min(nx - 1, ny - 1) <= welch_nu <= nx + ny - 2
println("z/t p-values = ", p_z, ", ", p_t, "; Welch nu = ", welch_nu)

# 每个重复重新生成 16 个正态观测；模拟不是 NP 或功效公式的证明。
Random.seed!(36)
function rejection_rate(mu, reps)
    rejections = 0
    for _ in 1:reps
        xbar = mu + 4 * mean(randn(16))
        rejections += xbar - 10 > zcrit
    end
    rejections / reps
end
empirical_size = rejection_rate(10.0, 20_000)
empirical_power = rejection_rate(12.0, 20_000)
@assert 0.045 < empirical_size < 0.055
@assert 0.61 < empirical_power < 0.67
println("fixed-seed size/power audit = ", empirical_size, ", ", empirical_power)
println("END ====")
