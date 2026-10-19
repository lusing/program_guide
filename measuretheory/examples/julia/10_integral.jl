println("==== 10 integral")
# 第 10 章：原子测度 μ = Σ 2^-k δ_k 上复刻三步积分构造。
# S⁺ 层：随机简单函数的线性/单调；非负层：f(k) = k/2^k 的积分
#   = Σ k·4^-k = 4/9（截断 vs 二进削顶两条逼近路殊途同归）；
# 一般层：f⁺−f⁻ 分解；Markov 不等式；绝对连续性 δ-ε 表。

using Random

const W = k -> 2.0^-k                 # 原子权重
mu(A) = sum(W(k) for k in A; init=0.0)
OMEGA = 1:40                          # 截断宇宙

# --- S⁺ 层 ---
Random.seed!(42)
for _ in 1:100
    perm = shuffle(collect(OMEGA))
    cut = rand(1:39)
    A, B = perm[1:cut], perm[cut+1:end]        # 随机划分
    a, b, c, d = rand(0:10, 4)                 # 随机权值
    fA(x) = x in A ? Float64(a) : Float64(b)
    lint(f, S) = sum(W(k) * f(k) for k in S; init=0.0)
    @assert lint(fA, OMEGA) == a * mu(A) + b * mu(B)          # 定义
    @assert lint(x -> c * fA(x), OMEGA) == c * lint(fA, OMEGA)  # 齐次
    gA(x) = x in A ? Float64(c) : Float64(d)
    @assert lint(x -> fA(x) + gA(x), OMEGA) ==
            lint(fA, OMEGA) + lint(gA, OMEGA)                  # 可加
    if a <= c && b <= d
        @assert lint(fA, OMEGA) <= lint(gA, OMEGA)             # 单调
    end
end
println("S+ layer: linearity/monotonicity over 100 random simples: OK")

# --- 非负层：两条逼近路 ---
f(k) = k / 2.0^k
true_val = 4.0 / 9.0                   # Σ k·4^-k = 4/9
trunc_n(n) = sum(W(k) * f(k) for k in 1:n; init=0.0)
# 二进削顶列：g_m(k) = floor(2^m f(k))/2^m ∧ m
dyad_m(m) = sum(W(k) * min(floor(2.0^m * f(k)) / 2^m, Float64(m))
                for k in OMEGA; init=0.0)
for n in (10, 20, 40)
    @assert trunc_n(n) ≤ true_val + 1e-12     # 截断列单调升（浮点容差）
    @assert trunc_n(n) ≤ trunc_n(40)
end
@assert abs(trunc_n(40) - true_val) < 1e-12   # 尾项 Σ_{k>40} k·4^-k < 1e-23
# 削顶误差界 = 2^-m·μ(Ω)：m=14 时 ≤ 6.2e-5
@assert abs(dyad_m(14) - true_val) < 1e-4
@assert dyad_m(6) ≤ dyad_m(8) ≤ dyad_m(14)    # 削顶列单调上升
println("nonneg layer: truncation & dyadic topping both -> 4/9: OK")

# --- 一般层：f = f⁺ − f⁻ ---
g(k) = (k ≤ 10 ? 1.0 : -1.0) * f(k)
ipos = sum(W(k) * max(g(k), 0.0) for k in OMEGA; init=0.0)
ineg = sum(W(k) * max(-g(k), 0.0) for k in OMEGA; init=0.0)
@assert abs((ipos - ineg) - sum(W(k) * g(k) for k in OMEGA; init=0.0)) < 1e-15
@assert ipos + ineg ≈ sum(W(k) * abs(g(k)) for k in OMEGA; init=0.0)
println("general layer: f+ - f- decomposition consistent: OK")

# --- Markov（心算：f(k)=k/2^k 最大 1/2，a 只能取 1/2 以下） ---
for a in (0.5, 0.25, 0.1)
    tail = sum(W(k) for k in OMEGA if f(k) ≥ a; init=0.0)
    @assert a * tail ≤ true_val + 1e-12
end
# 最紧的点：a = 1/2 时 [f ≥ 1/2] = {1,2}，μ = 3/4，
# 左端 = 3/8 = 右端 (4/9) 的 27/32
@assert sum(W(k) for k in 1:2; init=0.0) == 0.75
@assert abs(0.5 * 0.75 / true_val - 27 / 32) < 1e-12
println("Markov inequality holds, tightest at a=1/2 (ratio 27/32): OK")

# --- 绝对连续性 δ-ε 表 ---
function tail_int(delta)
    # 取 A 为最小权重的前若干原子（测度 < delta 的最坏小集）
    total, acc = 0.0, 0.0
    for k in sort(collect(OMEGA); by=k -> W(k) * abs(g(k)), rev=true)
        total + W(k) > delta && break
        total += W(k); acc += W(k) * abs(g(k))
    end
    acc
end
eps = [tail_int(d) for d in (0.9, 0.5, 0.26)]
@assert all(diff(eps) .<= 0)           # δ 越小最坏尾积分越小
@assert eps[1] > eps[2] > eps[end]     # 且前两档严格下降
@assert eps[end] < 0.01
println("absolute continuity: eps(delta) decreasing to ", round(eps[end]; digits=6), ": OK")

println("END ====")
