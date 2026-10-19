println("==== 04 extension")

# 第 04 章：外测度的数值构造（Carathéodory 机器）。
# 在 [0,1) 的二进网格上：用区间覆盖定义外测度 m*，
# 验证单调性与次可加性，并对照真 Lebesgue 测度。

using Random
Random.seed!(11)

# 深度 d 的二进网格：区间 (k/2^d, (k+1)/2^d]，长度 2^{-d}
function outer_measure(S, dmax)
    # S 是网格点的集合（用 0/1 长度 2^d 的位串表示集合）
    n = length(S)
    n == 0 && return 0.0
    # 直接法：最小覆盖 = 连续 1 游程的长度和（区间覆盖的最优解）
    total = 0.0
    i = 1
    while i <= n
        if S[i] == 1
            j = i
            while j <= n && S[j] == 1
                j += 1
            end
            total += (j - i) / 2^dmax
            i = j
        else
            i += 1
        end
    end
    total
end

d = 8
N = 2^d

# --- 验证 1：单调性（随机 A ⊆ B）---
function mono_experiment()
    ok = true
    for _ in 1:500
        A = rand(0:1, N)
        B = [max(a, rand(0:1)) for a in A]   # B ⊇ A
        ok &= outer_measure(A, d) ≤ outer_measure(B, d) + 1e-15
    end
    ok
end
@assert mono_experiment() "外测度单调性 500 次随机实验全过"
println("单调性：500 次随机实验全过")

# --- 验证 2：次可加性 ---
function subadd_experiment()
    ok = true
    for _ in 1:500
        A = rand(0:1, N)
        B = rand(0:1, N)
        ok &= outer_measure([max(A[i], B[i]) for i in 1:N], d) ≤
              outer_measure(A, d) + outer_measure(B, d) + 1e-15
    end
    ok
end
@assert subadd_experiment() "外测度次可加性 500 次随机实验全过"
println("次可加性：500 次随机实验全过")

# --- 验证 3：真子集对照——稠密但零测的格点影子 ---
# 二进有理点的"网格影子"测度 vs 真值 0：网格上单点测度 = 2^{-d}
# Cantor 集深度 3 的格点近似（ternary 无 1 数位）
cantor_pts = UInt16[]
for k in 0:(3^3 - 1)
    s = ""; okk = true
    x = k
    for _ in 1:3
        x, r = divrem(x, 3)
        if r == 1; okk = false; break; end
        s = string(r) * s
    end
    okk && push!(cantor_pts, parse(UInt16, s == "" ? "0" : s, base = 3))
end
# 映射到二进网格：占据的格点数 × 格长
occupied = fill(0, N)
for p in cantor_pts
    lo = floor(Int, p * N / 27)
    hi = ceil(Int, (p + 1) * N / 27)
    for g in max(lo, 1):min(hi, N)
        occupied[g] = 1
    end
end
mc = outer_measure(occupied, d)
true_c3 = (2 / 3)^3   # 深度 3 Cantor 块总长 (2/3)^3
@assert abs(mc - true_c3) ≤ true_c3 * 0.35 "Cantor 深度 3 的格点外测度应接近 (2/3)^3（网格效应允许偏差）"
println("Cantor 集深度 3：格点外测度 = $(round(mc, digits=4))，真值 (2/3)^3 = $(round(true_c3, digits=4))")

# --- 验证 4：Carathéodory 可测性的影子——二进区间是可测的 ---
# 对可测集 A（二进区间）与任意试验集 T：m*(T) = m*(T∩A) + m*(T\A)
function infty_check(A_lo, A_hi)   # A = 网格区间 [A_lo, A_hi]
    okk = true
    for _ in 1:300
        T = rand(0:1, N)
        TA = [T[i] * ((A_lo ≤ i ≤ A_hi) ? 1 : 0) for i in 1:N]
        TcA = [T[i] * ((A_lo ≤ i ≤ A_hi) ? 0 : 1) for i in 1:N]
        okk &= abs(outer_measure(T, d) - outer_measure(TA, d) - outer_measure(TcA, d)) < 1e-12
    end
    okk
end
@assert infty_check(101, 200) "二进区间应对任意试验集可加（Carathéodory 可测）"
println("Carathéodory 判据：二进区间对 300 个随机试验集全部精确可加")

# --- 验证 5：非可测的（网格）反例不存在——有限网格上外测度限制总是完备可加？---
# 有限网格上按游程定义的外测度其实对所有集合都 Carathéodory 可测（平凡 σ-代数是全幂集）
# 真正的 Vitali 反例需要不可数结构——正文说明，此处验证有限影子的事实：
function full_measurable_experiment()
    allm = true
    for _ in 1:200
        A = rand(0:1, N)
        T = rand(0:1, N)
        TA = T .* A
        TcA = T .* (1 .- A)
        allm &= abs(outer_measure(T, d) - outer_measure(TA, d) - outer_measure(TcA, d)) < 1e-9
    end
    allm
end
@assert full_measurable_experiment() "网格外测度限制在有限宇宙上全体可测（离散测度完备）"
println("有限影子：网格外测度限制是完备测度（Vitali 反例本质上是不可数现象）")

println("END ====")
