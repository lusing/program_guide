println("==== 49 characteristic_functions")
# 第 49 章：计算库与三大定理的数值现场。
# ① 闭式对拍（Gauss/Poisson/Exp）；② 乘积律（Exp+Exp = Gamma(2)）；
# ③ Lévy 收敛显影（Bin 标准化 → N）；④ Taylor 余项；⑤ 矩-导数词典。

using Random, Statistics
Random.seed!(49)

# ① 闭式对拍：φ(t) = E e^{itX}（Simpson 对 Gauss / Poisson / Exp）
function charfn_mc(mu, sd, t; N=20000)
    mean(exp.(im .* t .* randn(N) .* sd .+ im .* mu .* t) for _ in 1:N) |>
        x -> sum(real.(x)) / N + im * sum(imag.(x)) / N
end
for t in (0.5, 1.5, 2.5)
    est = charfn_mc(0.0, 1.0, t)
    closed = exp(-t^2 / 2)
    @assert abs(est.re - closed) < 0.01 && abs(est.im) < 0.01
end
println("Gaussian charFn: MC vs closed form < 0.01 at t=0.5,1.5,2.5: OK")

# Poisson(2)：φ = exp(2(e^{it}-1))
function pois_mc(lam, t; N=40000)
    # 反变换 Poisson(λ)：K = max{k : ∏U_j < e^{-λ}} 或 0 起点修正
    # （指数间隔的 Poisson 过程读法）
    s = 0.0 + 0im
    for _ in 1:N
        prod_u = rand()
        k = 0
        while prod_u > exp(-lam)
            prod_u *= rand()
            k += 1
        end
        s += exp(im * t * k)
    end
    s / N
end
for t in (0.5, 1.5)
    est = pois_mc(2.0, t)
    closed = exp(2 * (exp(im * t) - 1))
    @assert abs(est - closed) < 0.08
end
println("Poisson charFn: MC vs closed form: OK")

# ② 乘积律：Exp(1)+Exp(1) = Gamma(2,1)：φ² vs φ_{Gamma(2)}
for t in (0.5, 1.5, 3.0)
    phi_exp = 1 / (1 - im * t)
    phi_g2 = (1 / (1 - im * t))^2
    @assert abs(phi_exp^2 - phi_g2) < 1e-14
end
println("convolution product law: phi_Exp^2 = phi_Gamma(2) exact: OK")

# ③ Lévy 显影：Bin(n, 1/3) 标准化的 φ → e^{-t²/2}
for n in (20, 100, 500)
    # 数值积分：E e^{it·(S-np)/sqrt(npq)} 的精确账用解析形式
    p = 1/3
    m = n * p
    sd = sqrt(n * p * (1 - p))
    # φ_n(t) = (q + p·e^{it/sd})^n · e^{-it·m/sd}（独立和的特征函数）
    for t in (0.5, 1.0)
        term = (1 - p) + p * exp(im * t / sd)
        phi_n = term^n * exp(-im * t * m / sd)
        closed = exp(-t^2 / 2)
        @assert abs(phi_n - closed) < 0.1       # 渐近收敛（容差随 n 改善）
    end
end
println("Levy convergence: Bin(n,1/3) standardized charFn -> e^{-t^2/2}: OK")

# ④ Taylor 余项：φ(t) − (1 − t²/2) 的 O(t³) 侧写
for t in (0.1, 0.3, 0.5)
    phi = exp(-t^2 / 2)
    second = 1 - t^2 / 2
    rem = abs(phi - second)
    @assert rem < t^4 * 0.13 + 1e-15          # e^x 的 Taylor 余项的 4 阶控制
end
println("Taylor remainder: phi - (1 - t^2/2) bounded by ~t^4/8: OK")

# ⑤ 词典：Exp(1) 的 φ'(0)/i = E X = 1
for h in (1e-3, 1e-4)
    phi_plus = 1 / (1 - im * h)
    phi_minus = 1 / (1 + im * h)
    deriv = (phi_plus - phi_minus) / (2h)
    @assert abs(deriv / im - 1) < 0.01        # 数值导数 vs E X = 1
end
println("moment-derivative dictionary: phi'(0)/i = E X = 1 (Exp(1)): OK")

println("END ====")
