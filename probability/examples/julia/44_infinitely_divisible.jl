# 第 44 章 Julia：无穷可分的机器账（固定种子）。
# ① 谱字典：三大律特征函数的 n 次根封闭性（数值全等，Lean 已全证）；
# ② 小数律：Bin(n, λ/n) -> Poisson(λ) 的逐点概率对账（定理 5.5.5）；
# ③ Cauchy 稳定性：样本 (X1+X2)/2 与 X 的分位数对账（重尾无矩，用中位数刻度）；
# ④ 复合 Poisson：经验特征函数 vs exp(λ(cos t - 1))——Lévy 测度的字典在行动。
println("==== 44 infinitely_divisible")
using Random, Statistics

const I = im

# ---------- ① 谱字典：n 次根封闭 ----------
println("① 特征函数 n 次根封闭（|φ(t) - ψ(t)^n| 的最大偏差）：")
ts = collect(0.0:0.3:6.0)
phi_poi(t, lam) = exp(lam * (exp(I * t) - 1))
psi_poi(t, lam, n) = exp((lam / n) * (exp(I * t) - 1))
phi_nor(t, mu, s2) = exp(I * mu * t - s2 * t^2 / 2)
psi_nor(t, mu, s2, n) = exp(I * (mu / n) * t - (s2 / n) * t^2 / 2)
phi_cau(t, del, gam) = exp(I * del * t - gam * abs(t))
psi_cau(t, del, gam, n) = exp(I * (del / n) * t - (gam / n) * abs(t))
for n in [2, 3, 5]
    d1 = maximum(abs(phi_poi(t, 2.0) - psi_poi(t, 2.0, n)^n) for t in ts)
    d2 = maximum(abs(phi_nor(t, 1.0, 4.0) - psi_nor(t, 1.0, 4.0, n)^n) for t in ts)
    d3 = maximum(abs(phi_cau(t, 0.5, 3.0) - psi_cau(t, 0.5, 3.0, n)^n) for t in ts)
    println("   n=$(n)：Poisson $(round(d1, digits=12))，Normal $(round(d2, digits=12))，Cauchy $(round(d3, digits=12))")
    @assert d1 < 1e-10 && d2 < 1e-10 && d3 < 1e-10
end

# ---------- ② 小数律：Bin(n, λ/n) -> Poisson(λ) ----------
println("② 小数律（λ = 2，P(Bin(n,2/n)=k) vs Poisson(2)）：")
lam = 2.0
for n in [5, 20, 100, 500]
    diffs = [abs(binomial(big(n), k) * (lam / n)^k * (1 - lam / n)^(n - k)
              - exp(-lam) * lam^k / factorial(big(k))) for k in 0:4]
    println("   n=$(n)：max|diff| (k=0..4) = ", round(maximum(diffs), digits=5))
    if n >= 20
        @assert maximum(diffs) < 0.03
    else
        println("   （n=5 远未收敛：Bin(5,0.4) 与 Poisson(2) 还差 7 个百分点——收敛是渐进的）")
    end
end

# ---------- ③ Cauchy 稳定性：分位数对账 ----------
println("③ Cauchy 稳定性（(X1+X2)/2 与 X 同尺度，20000 样本分位数）：")
rng = MersenneTwister(4401)
cauchy_draw(g) = g * tan(pi * (rand(rng) - 0.5))
X = [cauchy_draw(2.0) for _ in 1:20000]
Y = [cauchy_draw(2.0) + cauchy_draw(2.0) for _ in 1:20000] ./ 2
for q in [0.25, 0.5, 0.75]
    qx = quantile(X, q)
    qy = quantile(Y, q)
    println("   分位数 q=$(q)：|X| 轴 $(qx) vs (X1+X2)/2 轴 $(qy)（同刻度 2γ tan(π(q-1/2))）")
    @assert abs(qx - qy) < 0.6
end
println("   （Cauchy 无矩：均值方差不存在，对账只能用分位数——这正是重尾律的体检方式）")

# ---------- ④ 复合 Poisson 的经验特征函数 ----------
println("④ 复合 Poisson（N~Poisson(2)，跳跃 ±1）：经验 CF vs exp(λ(cos t - 1))：")
function poisson_draw(lam)
    s, k = -log(rand(rng)), 0
    while s <= lam
        k += 1
        s += -log(rand(rng))
    end
    return k
end
X = [sum((rand(rng) < 0.5 ? 1 : -1) for _ in 1:poisson_draw(2.0); init = 0) for _ in 1:30000]
for t in [0.5, 1.0, 1.5]
    ecf = abs(mean(exp.(I * t * X)))
    th = exp(2.0 * (cos(t) - 1.0))
    println("   t=$(t)：|ECF| = $(round(ecf, digits=4)) vs 理论 $(round(th, digits=4))")
    @assert abs(ecf - th) < 0.01
end
println("   （跳跃部分只贡献 cos t 因子——Lévy 测度 ν = 2·δ₁ 的读法）")
println("END ====")
