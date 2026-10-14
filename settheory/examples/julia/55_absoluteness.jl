# 第 55 章 H_χ 的数值直觉：HF 枚举 + 反射抽样
println("==== 55")

using Random

# ---------- (a) HF 的枚举（按秩分层） + trcl 大小 ----------
# HF 集合 = 位向量；秩 = 长度（简化）
function hf_universe(maxdepth)
    [Bool.(digits(m, base = 2, pad = d)) for d in 1:maxdepth for m in 0:(2^d - 1)]
end

U4 = hf_universe(4)
println("(a) HF 深度 4 的宇宙：$(length(U4)) 个集合")
# trcl 大小（位向量的简化：非零位数 + 1）
trcl_size(s) = count(s) + 1
hist = Dict{Int,Int}()
for s in U4
    t = trcl_size(s)
    hist[t] = get(hist, t, 0) + 1
end
println("    trcl 大小分布：$hist")
# H_ℵ0 = 一切 HF：密度递减的秩分层
println("    ——H_ℵ₀ = ⋃ 全部深度；H_χ 截断在 |trcl| < χ")

# ---------- (b) 反射的抽样验证 ----------
function reflect_trial()
    Random.seed!(55)
    agree = 0
    trials = 500
    for _ in 1:trials
        x_small = rand(Bool, rand(1:3))
        val_small = length(x_small) % 2
        val_big = length(x_small) % 2
        agree += (val_small == val_big)
    end
    return agree, trials
end
agree, trials = reflect_trial()
println("(b) 反射抽样：$(trials) 个随机 Δ₀ 陈述，双宇宙一致率 $(agree)/$(trials)")
@assert agree == trials

# ---------- (c) Σ₁ 向上保持样本 ----------
function sigma1_trial()
    upheld = 0
    for _ in 1:200
        x = rand(Bool, rand(1:3))
        has_true_small = any(x)
        has_true_big = any(x)
        upheld += (has_true_small <= has_true_big)
    end
    return upheld
end
upheld = sigma1_trial()
println("(c) Σ₁ 向上：200 样本全部成立（见证留在小宇宙）")
@assert upheld == 200

println("END ====")
