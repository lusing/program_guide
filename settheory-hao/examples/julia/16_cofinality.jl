# 第 16 章 Julia：共尾映射的显式构造（书 5.3.3 的构造演示）。
# ① ω² 的共尾映射：f(n) = ω·n——严格递增、无界（cf(ω²)=ω）；
# ② 定理 5.3.3 的"磨光"构造：任意共尾 g → 严格递增共尾 f
#    （f(n) = max(g(n), ⋃_{ξ<n}(f(ξ)+1))）——窗口演示；
# ③ 正则基数的刻画 5.4.7(2)：<cf(κ) 个 <κ 之并的窗口影子。
println("==== 16 cofinality")

canon(v) = begin
    i = findlast(!=(0), v)
    i === nothing ? Int[] : v[1:i]
end

function olt(a, b)
    a, b = canon(a), canon(b)
    n = max(length(a), length(b))
    a = vcat(a, zeros(Int, n - length(a)))
    b = vcat(b, zeros(Int, n - length(b)))
    for k in n:-1:1                    # 高位先比（CNF）
        a[k] != b[k] && return a[k] < b[k]
    end
    false
end

# ω² 的 CNF 比较下 ω·n < ω² 的显式核对
w_n(n) = n == 0 ? Int[] : [0, n]
w_sq = [0, 0, 1]
@assert all(olt(w_n(n), w_sq) for n in 1:10)         # ω·n 无界于 ω²？——
@assert !olt(w_sq, w_n(10^6))                        # ω² ≤ ω·n 永假（n 有限）
# "无界"的窗口含义：每个 < ω² 的序数（c2 < 1 即 c2 = 0）被某 ω·n 超越
bounded_check(a, seq) = any(olt(a, s) for s in seq)
for c1 in 0:8, c0 in 0:8
    α = canon([c0, c1, 0])
    @assert bounded_check(α, [w_n(n) for n in 0:10]) # ω·n 序列无界
end
println("cofinal map: w*n is unbounded in w*w window (cf = omega): OK")

# ② 磨光构造（5.3.11 式）：g(n) = n·ω 的 CNF 平凡版——窗口里以
# 自然数序列演示：任意无界 g → 严格递增 f = running max of (g(n)+1)
g(n) = (n * 7) % 13                                   # "乱序"的无界序列
f = Int[]
for n in 0:20
    cand = g(n)
    isempty(f) || (cand = max(cand, f[end] + 1))
    push!(f, cand)
end
@assert all(f[i] < f[i+1] for i in 1:length(f)-1)     # 严格递增
@assert maximum(g.(0:20)) <= maximum(f)               # f 仍无界 ≥ g
println("smoothing (5.11): any cofinal g -> strictly increasing f: OK")

# ③ 5.4.7(2) 影子：有限个有限集之并 < 任何无穷（ℵ₀ 正则的窗口形态）
finite_union_stays_finite(Ss) = sum(length, Ss) < Inf
sets = [[rand(1:100) for _ in 1:rand(1:10)] for _ in 1:20]
@assert length(union(sets...)) <= sum(length, sets) < 1000000
println("regular cardinal shadow: finite union of finite sets is finite: OK")
println("END ====")
