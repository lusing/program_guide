# -*- coding: utf-8 -*-
println("==== 20 generating_functions")
# 第 20 章 Julia：母函数的频率与数值形态。
# ① 泊松和的模拟直方 vs Pois(12) pmf；② Fibonacci 三赛跑
#    （递推 vs Binet vs 矩阵幂——Binet 大 n 浮点误差现场）；
# ③ MGF 数值积分 vs 闭式；④ 几何和 vs NegBin pmf。
using Random, Statistics

Random.seed!(20)

# 手写泊松采样（Knuth 乘法版）
function sim_poisson(lam, n)
    out = zeros(Int, n)
    for t in 1:n
        L, k, p = exp(-lam), 0, 1.0
        while true
            p *= rand()
            p < L && break
            k += 1
        end
        out[t] = k
    end
    out
end

# ① Pois(5)+Pois(7)：模拟直方 vs Pois(12) pmf
S = sim_poisson(5.0, 200_000) .+ sim_poisson(7.0, 200_000)
pois_pmf(l, k) = l ^ k * exp(-l) / factorial(k)
for k in 5:20
    emp = count(==(k), S) / length(S)
    @assert abs(emp - pois_pmf(12.0, k)) < 0.003
end
println("poisson sum: simulated = pois(12) pmf (lambda adds): OK")

# ② Fibonacci 三赛跑
function fib_rec(n)
    a, b = big(0), big(1)
    for _ in 1:n
        a, b = b, a + b
    end
    return a
end
phi = (1 + sqrt(big(5))) / 2
fib_binet(n) = round(BigInt, phi ^ n / sqrt(big(5)))
matpow(A, n) = n == 0 ? BigInt[1 0; 0 1] : (h = matpow(A, n ÷ 2); e = h * h; n % 2 == 0 ? e : e * A)
fib_mat(n) = matpow(big.([1 1; 1 0]), n)[1, 2]
for n in (10, 40, 90)
    f = fib_rec(n)
    @assert fib_binet(n) == f
    @assert fib_mat(n) == f
end
# Binet 在 Float64 精度下的失灵现场（n=80 起偏离）
phi64 = (1 + sqrt(5)) / 2
bad = round(Int, phi64 ^ 80 / sqrt(5))
@assert bad != Int(fib_rec(80))          # Float64 已失真
println("fibonacci race: rec/binet(big)/matrix agree; float64 binet fails at n=80: OK")

# ③ MGF 数值积分 vs 闭式（正态/指数）
function simpson(f, a, b, n)
    h = (b - a) / n
    s = f(a) + f(b)
    for i in 1:n-1
        s += (i % 2 == 0 ? 2 : 4) * f(a + i * h)
    end
    s * h / 3
end
pdfz(x) = exp(-x * x / 2) / sqrt(2 * pi)
for t in (0.3, 0.8)
    num = simpson(x -> exp(t * x) * pdfz(x), -10, 10, 4000)
    @assert abs(num - exp(t * t / 2)) < 1e-9
end
for t in (0.2, 0.5)
    num = simpson(x -> exp(t * x) * exp(-x), 0, 60, 4000)
    @assert abs(num - 1 / (1 - t)) < 1e-9
end
println("mgf numerical integration = closed forms: OK")

# ④ 几何和 vs NegBin：Geom(1/3)（支撑 1..）三重和 = NegBin(r=3)
function sim_geom3_sum(reps)
    out = zeros(Int, reps)
    for t in 1:reps
        s = 0
        for _ in 1:3
            n = 1
            while rand() > 1 / 3
                n += 1
            end
            s += n
        end
        out[t] = s
    end
    out
end
G = sim_geom3_sum(200_000)
# 和的支撑 {3,4,...}：P(S=s) = C(s−1, r−1) p^r (1−p)^{s−r}（Miller 的
# "数到第 r 次成功"版 NegBin；与"成功数"版差一个支撑平移——约定警告现场）
for s in 4:12
    pmf = binomial(big(s - 1), big(2)) * big(1 // 3) ^ 3 * big(2 // 3) ^ (s - 3)
    emp = count(==(s), G) / length(G)
    @assert abs(emp - Float64(pmf)) < 0.004
end
println("sum of 3 geometric(1/3) matches negbin(r=3) pmf: OK")

println("END ====")
