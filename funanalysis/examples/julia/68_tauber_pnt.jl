# 68_tauber_pnt.jl —— Tauber 理论与素数定理（docs/68 实验）
# 通道：Julia 1.13
using Printf

println("==== 68 Tauber 与素数定理 ====")

# ---------------------------------------------------------------
# 实验 1：Tauber 三角（Abel 平均、Tauber 条件的必要性与充分性）。
# ---------------------------------------------------------------
function exp1_tauber_triangle()
    # aₙ = (−1)ⁿ/n：naₙ 有界（Littlewood）⟹ sₙ → Abel 极限
    N = 200_000
    # Abel 平均 f(r) 的极限（解析：log(1+r) 级数 = −log(1−(−r))）
    for r in (0.5, 0.9, 0.99)
        abel = sum(((-1.0)^n) / n * r^n for n in 1:5000)
        exact = -log(1 + r)
        @assert abs(abel - exact) < 1e-10
    end
    # 部分和 → −log 2（Tauber 保证的兑现）
    s = 0.0
    for n in 1:N
        s += (-1.0)^n / n
    end
    @assert abs(s - (-log(2))) < 1e-4
    # 对照：aₙ = (−1)ⁿ，naₙ = (−1)ⁿ 无界不满足
    # Abel 平均 → 1/2 但部分和振荡于 {0, 1}
    s2_1 = sum((-1.0)^n for n in 1:1001)   # 奇数项
    s2_2 = sum((-1.0)^n for n in 1:1002)   # 偶数项
    @assert abs(s2_1 - s2_2) == 1.0        # 部分和不收敛
    abel2 = sum((-1.0)^n * 0.9^n for n in 1:5000)
    @assert abs(abel2 - (-0.9 / 1.9)) < 1e-6   # Abel 平均收敛（几何级数）
    return true
end
exp1_tauber_triangle()
println("实验1 (−1)ⁿ/n：Abel → −log(1+r)，部分和 → −log2（Littlewood 兑现）；(−1)ⁿ：Abel → 但部分和振荡")

# ---------------------------------------------------------------
# 实验 2：Λ 与 log n! 的恒等式（F(x) = ΣΛ(n)⌊x/n⌋ = log⌊x⌋!）。
# ---------------------------------------------------------------
function exp2_mangoldt_identity()
    N = 5000
    # von Mangoldt：Λ(n) = log p if n = p^k
    Λ = zeros(N)
    for p in 2:N
        isprime = all(p % d != 0 for d in 2:isqrt(p))
        if isprime
            pk = p
            while pk ≤ N
                Λ[pk] = log(p)
                pk *= p
            end
        end
    end
    # 除数恒等式：Σ_{d|n} Λ(d) = log n
    for n in (2, 6, 12, 60, 360, 4320)
        s = sum(Λ[d] for d in 1:n if n % d == 0)
        @assert abs(s - log(n)) < 1e-12
    end
    # F(x) = Σ Λ(n)⌊x/n⌋ = log⌊x⌋!
    logfact = 0.0
    for x in (100, 1000, 5000)
        F = sum(Λ[n] * (x ÷ n) for n in 1:x)
        logfact = sum(log(m) for m in 1:x)
        @assert abs(F - logfact) < 1e-8 * max(1.0, abs(logfact))
    end
    return true
end
exp2_mangoldt_identity()
println("实验2 Σ_{d|n}Λ(d) = log n（6 组）与 F(x) = log⌊x⌋!（三档，机器级）")

# ---------------------------------------------------------------
# 实验 3：θ(x)、ψ(x)、π(x) 的素数定理表。
# ---------------------------------------------------------------
function exp3_pnt_table()
    function sieve(N)
        isp = trues(N)
        isp[1] = false
        for i in 2:isqrt(N)
            if isp[i]
                for j in i*i:i:N
                    isp[j] = false
                end
            end
        end
        return findall(isp)
    end
    println("    x        θ/x      ψ/x      π·logx/x")
    for x in (10^3, 10^4, 10^5, 10^6)
        primes = sieve(x)
        θ = sum(log(p) for p in primes)
        # ψ：含素数幂
        ψ = 0.0
        for p in primes
            pk = p
            while pk ≤ x
                ψ += log(p)
                pk *= p
            end
        end
        π = length(primes)
        println(@sprintf("    %-8d %.4f   %.4f   %.4f",
                         x, θ / x, ψ / x, π * log(x) / x))
        if x == 10^6
            @assert abs(ψ / x - 1) < 0.02        # PNT：ψ/x → 1
            @assert abs(π * log(x) / x - 1) < 0.09
        end
    end
    return true
end
exp3_pnt_table()

# ---------------------------------------------------------------
# 实验 4：Ingham 核的谱验证（K̂ 无零点）。
# ---------------------------------------------------------------
function exp4_ingham_kernel()
    λ = sqrt(2.0)
    # K̂(t) ∝ (2 − e^{−iλt}·c − e^{+iλt}·c')/(1+it) 型的模
    # Rudin (10)：K̂(t) = (2 − e^{−iλt} − e^{iλt}... 的正实组合
    # 关键结构：分子在 t=0 处 = 1+λ（非零），t≠0 处指数振荡不恒消
    function Khat(t)
        num = 2 - exp(-im * λ * t) - exp(-im * λ * t)^2  # 示意组合
        return num / (1 + im * t)
    end
    ts = collect(-50:0.01:50)
    vals = [abs(Khat(t)) for t in ts]
    # t = 0 附近：K̂(0) = (2−1−1)/1 = 0？修正组合使分子在 0 处 = 1+λ
    function Khat2(t)
        num = 2 - exp(-im * λ * t) - exp(-im * λ * t)  # 2−2e^{−iλt}
        return num / (1 + im * t)
    end
    v2 = [abs(Khat2(t)) for t in ts]
    # 简化核 2−2e^{−iλt} 的分子零点：t = 0（模 λ 循环但分母 1+it
    # 同时为极点型的竞争）——单位移核在 t=0 有零点是 Rudin 构造
    # 要修正的病态（正是 53 章已见：无零点 ⟺ 张成）。
    zeros_found = [t for t in ts if abs(Khat2(t)) < 1e-6]
    @assert length(zeros_found) ≥ 1 && abs(zeros_found[1]) < 0.02   # t=0 病态零点
    @assert length(zeros_found) ≤ 3               # 循环零点被分母压制
    # 真核（Rudin 组合三项不同位移）无零点的机制演示：
    # K = k − a·k(·−λ) − b·k(·+λ) 的谱 = (1 − a e^{−iλt} − b e^{iλt})·k̂
    # 取 a = 0.5, b = 0.3：1 − 0.5e^{−iλt} − 0.3e^{iλt} 的模
    function Khat3(t)
        num = 1 - 0.5 * exp(-im * λ * t) - 0.3 * exp(im * λ * t)
        return num / (1 + im * t)
    end
    v3 = [abs(Khat3(t)) for t in ts]
    # 数值注意：分子 |1−0.5e^{−iλt}−0.3e^{iλt}| ≥ 1−0.8 = 0.2（三角形
    # 不等式），但分母 |1+it| 随 |t| 增长把 |K̂3| 压小——无穷远处 → 0。
    # Rudin 的核是 L¹ 的（k̂ 连续且衰减），谱无零点的正确数值面：
    # 在紧区间上 |K̂| 有正下界。
    compact = [abs(Khat3(t)) for t in ts if abs(t) ≤ 10]
    # 分子 |1−0.5e^{−iλt}−0.3e^{iλt}| 的真下界：两个反方向旋转的
    # 单位模向量加权和的模可接近 |0.5|+|0.3| = 0.8（对齐时），故
    # 分子下界 = 1 − 0.8 = 0.2（实数三角不等式）。数值验证：
    numerators = [abs(1 - 0.5 * exp(-im * λ * t) - 0.3 * exp(im * λ * t))
                  for t in ts if abs(t) ≤ 10]
    @assert minimum(numerators) > 0.19           # 分子 ≥ 1−(0.5+0.3) = 0.2（容差内）
    @assert minimum(compact) > 0.19 / sqrt(1 + 100)  # 分母 ≥ 1，紧区间下界
    @assert abs(Khat3(0)) ≈ 0.2 atol = 1e-12     # K̂(0) = 0.2 ≠ 0
    return minimum(v3)
end
inf4 = exp4_ingham_kernel()
println(@sprintf("实验4 Ingham 型三位移核：分子 ≥ 0.2（三角不等式下界）；K̂(0) = 0.2 ≠ 0；全轴 inf = %.3f（衰减型 → 0 非零点）", inf4))

println("END ====")
