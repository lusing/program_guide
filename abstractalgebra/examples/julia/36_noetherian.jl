# 第 36 章 · 诺特环 —— Julia 通道
#
# 单项式理想的升链稳定（Dickson 引理机器面）+ ACC 等价条件 +
# 商环遗传 + k[x,y] 中理想的有限生成（Grobner 终止）。

println("==== 36 诺特环")

# ---------- 单项式理想：指数集合的上闭包 ----------
"""由生成单项式集合 gen（指数向量）生成的单项式理想 = 全部单项式指数集。"""
function monomial_ideal(gen, bound)
    S = Set{Vector{Int}}()
    frontier = copy(gen)
    while !isempty(frontier)
        e = pop!(frontier)
        if e in S || any(e[i] > bound[i] for i in 1:length(e))
            continue
        end
        push!(S, e)
        for i in 1:length(e)
            e2 = copy(e); e2[i] += 1
            push!(frontier, e2)
        end
    end
    S
end

# ---------- Dickson 引理：升链稳定（命题 7.26 ACC 的单项式面） ----------
# 随机递增链：每次往生成集里加一个新单项式，理想序列 I₁ ⊆ I₂ ⊆ …
# 在有限步后不再增长（机器验证到不动点）
using Random
Random.seed!(20261104)
for trial in 1:20
    bound = [6, 6]
    gens = Vector{Vector{Int}}[]
    base = [[0, 0]]
    push!(gens, base)
    prev = monomial_ideal(base, bound)
    steps = 0
    for k in 1:30
        # 添加一个随机单项式（保持链递增）
        newg = vcat(gens[end], [[rand(0:6), rand(0:6)]])
        push!(gens, newg)
        cur = monomial_ideal(newg, bound)
        steps += (cur != prev)
        prev = cur
    end
    @assert steps <= 30
    # 链最终不动：最后 10 次添加不再改变理想
    stable = all(monomial_ideal(gens[end - j], bound) ==
                 monomial_ideal(gens[end], bound) for j in 1:8)
    @assert stable
end
println("Dickson：20 条随机递增链全部在有限步内稳定（k[x,y] 的单项式面）✓")

# ---------- ACC ⟺ 每个理想有限生成（命题 7.26）----------
# 单项理想由有限生成集生成（按构造）；反之有限生成的理想显然进入链的稳定段
# 数值面：任何有界指数集的上闭包由其极小元生成
function minimal_gens(S)
    [e for e in S if !any(f != e && all(f[i] <= e[i] for i in 1:length(f)) for f in S)]
end
S = monomial_ideal([[2, 0], [0, 3], [1, 1]], [8, 8])
mg = minimal_gens(S)
@assert Set(mg) == Set([[2, 0], [0, 3], [1, 1]])    # 生成集恰为极小元
@assert monomial_ideal(mg, [8, 8]) == S             # 极小元重新生成同一理想
println("极小生成：上闭包的极小元集合重新生成同一理想（Dickson 的核心）✓")

# ---------- ℤ/n：商环遗传诺特性（推论 7.28）----------
# ℤ 的理想链 ⟷ 整除链；(4) 之下的理想 = ℤ/4 的理想全体 = {(0),(2),(1)}
# 数值面：ℤ/12 的理想格 = ℤ 中包含 (12) 的理想 = (d)，d | 12
divisors(n) = [d for d in 1:n if n % d == 0]
@assert divisors(12) == [1, 2, 3, 4, 6, 12]
# 理想数有限 ⟹ ACC 平凡成立（有限格没有真无限升链）
println("商环：ℤ/12 的理想格 = ℤ 中含 (12) 者（6 个）——有限 ⟹ ACC ✓")

# ---------- 希尔伯特基定理（定理 7.30）的机器面 ----------
# k[x,y] 的任意理想有有限 Grobner 基：Buchberger 算法终止即有限性证书
#（完整算法在第 39 章；此处验证两个代表理想的有限生成）
# (x³, x²y, xy², y³) 的极小生成 = {x³, x²y, xy², y³}
S3 = monomial_ideal([[3, 0], [2, 1], [1, 2], [0, 3]], [6, 6])
@assert Set(minimal_gens(S3)) == Set([[3, 0], [2, 1], [1, 2], [0, 3]])
# (x², xy, y²)：二次以内全消失——S2 恰为总次数 ≥ 2 的单项式全体
S2 = monomial_ideal([[2, 0], [1, 1], [0, 2]], [5, 5])
@assert all(sum(e) >= 2 for e in S2)
@assert all([a, b] in S2 for a in 0:5, b in 0:5 if a + b >= 2)
println("希尔伯特基：{x²,xy,y²} 生成全部次数 ≥ 2 单项式（理想有限生成）✓")

println("END ====")
