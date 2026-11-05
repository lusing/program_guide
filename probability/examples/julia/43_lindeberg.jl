# 第 43 章 Julia：Lindeberg 条件的三族对照（精确有理 + 固定种子模拟）。
# ① Lindeberg 商表：多项式方差族（民主：商归零）、几何方差族（独裁：商恒 3/4）、
#    有界族（注 5.3.2：商自动归零）；
# ② 峰度签名：独立两点变量的和峰度 = 3 − 2Σσ⁴/c⁴（精确 //），几何族恒趋 7/3、
#    多项式族趋 3——非正态性写在四阶矩里；
# ③ 例 5.3.1 的特征函数账：正态几何族的 |φ| = exp(−u²/2) 精确成立（CLT 有了），
#    两点几何族 |φ| = Πcos(uσₖ/cₙ) 严格更小；
# ④ 组合正态近似检查器：8 资产 vol² 中一个独大时商 0.70，等权时 0。
println("==== 43 lindeberg")
using Random, Statistics

# ---------- ① Lindeberg 商（全程 Rational） ----------
quot(sig2::Vector{Int}, eps::Rational{Int}) =
    let c2 = sum(sig2), thr = eps * eps * c2
        sum(s2 -> s2 >= thr ? s2 : 0, sig2) // c2
    end

poly(n) = collect(1:n)
geo(n) = vcat([1], [2^(k - 1) for k in 1:n-1])   # 1,1,2,4,...,2^(n-2)：例 5.3.1 的方差序列

println("① Lindeberg 商（ε = 1/2，两点分布 ±σ）：")
for n in [4, 7, 8, 12]
    println("   多项式 σ^2=k  n=", rpad(n, 2), "：商 = ", quot(poly(n), 1 // 2))
end
@assert quot(poly(7), 1 // 2) == 1 // 4      # 阈值 7 恰被末项踩线
@assert quot(poly(8), 1 // 2) == 0           # 阈值 9 越过全体——整数证书
for n in [4, 6, 8, 10]
    println("   几何 2^(k-2)   n=", rpad(n, 2), "：商 = ", quot(geo(n), 1 // 2))
    @assert quot(geo(n), 1 // 2) == 3 // 4   # 独裁不退位
end
println("   有界 σ^2=3     n=4 ：商 = ", quot(fill(3, 4), 1 // 2), "（阈值 3 被踩线）")
println("   有界 σ^2=3     n=5 ：商 = ", quot(fill(3, 5), 1 // 2), "（注 5.3.2：有界自动归零）")
@assert quot(fill(3, 4), 1 // 2) == 1 // 1
@assert quot(fill(3, 5), 1 // 2) == 0 // 1

# ---------- ② 峰度签名：kurt(T_n) = 3 - 2Σσ⁴/c⁴ ----------
kurt_exact(sig2::Vector{Int}) =
    let c2 = sum(sig2)
        3 - 2 * sum(s2 -> big(s2)^2, sig2) // big(c2)^2
    end
println("② 两点和的峰度（kurt = 3 - 2·Σσ⁴/c⁴，正态 = 3）：")
for n in [8, 16, 32]
    println("   多项式 n=", rpad(n, 2), "：kurt = ", float(kurt_exact(poly(n))))
end
for n in [8, 16]
    println("   几何   n=", rpad(n, 2), "：kurt = ", float(kurt_exact(geo(n))),
            "（恒差 2/3 量级——永不正态化）")
end
@assert abs(kurt_exact(geo(16)) - 7 // 3) < 1 // 100
@assert kurt_exact(poly(32)) > 29 // 10

rng = MersenneTwister(4301)
emp_kurt(sig2) =
    let c = sqrt(sum(sig2)), m = 100_000
        t = [sum((rand(rng) < 0.5 ? 1 : -1) * sqrt(Float64(s2)) for s2 in sig2) / c for _ in 1:m]
        mean(t .^ 4) / var(t)^2
    end
println("   MC（10^5 次，固定种子）：几何 n=8 经验峰度 = ", round(emp_kurt(geo(8)), digits=3),
        "（理论 7/3 ≈ 2.333）")
@assert abs(emp_kurt(geo(8)) - 7 / 3) < 0.08
println("   MC：多项式 n=32 经验峰度 = ", round(emp_kurt(poly(32)), digits=3), "（理论 > 2.9，贴近正态）")

# ---------- ③ 例 5.3.1 的特征函数账 ----------
println("③ 特征函数账（u = 1）：")
println("   正态几何族：|φ| = exp(-u^2/2) = ", exp(-0.5), "——对所有 n 精确成立（T_n ~ N(0,1)）")
for n in [8, 16]
    s2 = geo(n); c = sqrt(sum(s2))
    phi = prod(cos(sqrt(Float64(s)) / c) for s in s2)
    println("   两点几何族 n=", n, "：|φ| = Πcos(uσ/c) = ", round(phi, digits=6), " < exp(-1/2)（cos ≤ exp 半步）")
    @assert phi < exp(-0.5)
end

# ---------- ④ 组合正态近似检查器 ----------
println("④ 8 资产组合的 Lindeberg 体检（ε = 1/2）：")
vols_equal = fill(1, 8)
vols_one_big = vcat(fill(1, 7), 16)          # 一只高波动资产独大
share(v) = maximum(v) // sum(v)
println("   等权 vol=1：商 = ", quot(vols_equal, 1 // 2), "，最大份额 = ", share(vols_equal))
println("   独大 vol^2=16：商 = ", quot(vols_one_big, 1 // 2), "，最大份额 = ", share(vols_one_big))
@assert quot(vols_equal, 1 // 2) == 0
@assert quot(vols_one_big, 1 // 2) == 16 // 23
println("   -> 等权组合的正态近似有 Lindeberg 背书；独大组合的尾部由那只资产决定，")
println("      CLT 不再是合适的近似（这正是风险管理要抓的集中度）。")
println("END ====")
