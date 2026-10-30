# 第 108 章：可数支撑迭代的有限影子——积序证书复合、支撑拼接与稠密集相遇。
println("==== 108")

# ── 一、坐标偏序（沿 107 章 extT）与两步积序 ──
const EXT = Dict{Int,Set{Int}}(
    0 => Set([0, 1, 2]),
    1 => Set([1]),
    2 => Set([2]),
)

compat(r, p) = !isempty(EXT[r] ∩ EXT[p])
ext_of(q) = get(EXT, q, Set{Int}())
predense1(A, q) = all(any(compat(r, p) for p in A) for r in ext_of(q))

const U2 = vec([(a, b) for a in 0:2, b in 0:2])   # 两步迭代的 9 个条件
ext2(p) = Set((r, s) for r in ext_of(p[1]), s in ext_of(p[2]))
compat2(p, q) = !isempty(ext2(p) ∩ ext2(q))
predense2(A, q) = all(any(compat2(r, p) for p in A) for r in ext2(q))

A12 = Set([1, 2])
P12 = Set([(a, b) for a in A12, b in A12])        # A12 × A12（4-反链）

@assert compat2((1, 1), (1, 1))
@assert !compat2((1, 1), (1, 2))                  # 第二分量 1 与 2 不相容
@assert predense2(P12, (0, 0))                    # 4-反链在顶条件下准稠密

# 证书复合（引理 2.26 影子）：分量准稠密 ⟹ 积序准稠密（全域对拍）。
for q0 in 0:2, q1 in 0:2
    if predense1(A12, q0) && predense1(A12, q1)
        @assert predense2(P12, (q0, q1))
    end
end

# 反链相乘：积序极大反链规模 = 4 = 2×2（cc 保持影子；位掩码穷举）。
is_antichain2(A) = all(!compat2(p, q) for p in A, q in A if p != q)
function max_antichain_size2(universe)
    us = collect(universe)
    best = 0
    for mask in 0:(2^length(us) - 1)
        A = Set(us[i] for i in 1:length(us) if (mask >> (i - 1)) & 1 == 1)
        if is_antichain2(A)
            best = max(best, length(A))
        end
    end
    return best
end
@assert max_antichain_size2(U2) == 4

# ── 二、支撑限制与拼接（引理 2.27 的协调条款） ──
supp(q) = [i - 1 for (i, c) in enumerate(q) if c != 0]   # 0 基坐标
restrict(q, k) = q[1:min(k, length(q))]
glue(q, r) = vcat(q, r[length(q) + 1:end])

qA = [0, 1, 0, 2]
rB = [1, 1, 0, 0, 3]
G = glue(qA, rB)
@assert G == [0, 1, 0, 2, 3]
@assert restrict(G, length(qA)) == qA                  # 拼接协调
@assert issubset(supp(G), union(supp(qA), supp(rB)))    # 支撑并集
@assert supp(G) == [1, 3, 4]
@assert issubset(supp(restrict(rB, 2)), supp(rB))       # 限制只缩不小

# ── 三、RS 构造：有限稠密集族相遇滤子（PFA 引擎影子） ──
# 稠密：∀p ∃d∈D（d ≤ p）。积序宇宙上 d ≤ p 即 d ∈ ext2(p)。
is_dense2(D) = all(any(d ∈ ext2(p) for d in D) for p in U2)
D12 = sort(collect(P12))
@assert is_dense2(D12)
@assert !is_dense2([(0, 0)])                            # 单点顶层不稠密

# RS 递归：从 p0 起逐个稠密集取更强条件，得下降链与向上闭包滤子。
function rsi_filter(denses, p0)
    p = p0
    chain = [p0]
    for D in denses
        d = first(d for d in D if d ∈ ext2(p))
        push!(chain, d)
        p = d
    end
    F = Set(q for q in U2 if p ∈ ext2(q))
    return chain, F
end

function is_filter2(F)
    pairwise = all(compat2(p, q) for p in F, q in F)
    upward = all(q ∈ F for p in F for q in U2 if p ∈ ext2(q))
    return pairwise && upward
end

chain, F = rsi_filter([D12, D12], (0, 0))
@assert is_filter2(F)
@assert !isempty(F ∩ Set(D12))                          # 相遇两个稠密集

# 穷举账：全部 32 个稠密集（⊇ P12）的 1024 个二元族——RS 构造全部成功。
rest = [q for q in U2 if q ∉ P12]
dense_sets = [sort(vcat(D12, [rest[i] for i in 1:5 if (m >> (i - 1)) & 1 == 1]))
              for m in 0:31]
@assert length(dense_sets) == 32 && all(is_dense2, dense_sets)
for m1 in 0:31, m2 in 0:31
    _, Fi = rsi_filter([dense_sets[m1 + 1], dense_sets[m2 + 1]], (0, 0))
    @assert is_filter2(Fi)
    @assert !isempty(Fi ∩ Set(dense_sets[m1 + 1]))
    @assert !isempty(Fi ∩ Set(dense_sets[m2 + 1]))
end

println("Julia：积序证书复合 + 反链 4=2×2；支撑拼接协调与并集；")
println("RS 构造穷举 32 稠密集×32 稠密集全部相遇")
println("END ====")
