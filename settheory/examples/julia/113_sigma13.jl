# 第 113 章：Σ¹₃ 与广泛贝尔——布劳威尔-克林序、双树互补、外延稳定性
# 的有限对拍（与 Python 独立同账；四证明通道见 Lean/Coq/Agda/Isabelle）。
println("==== 113")

# ── 一、布劳威尔-克林序（引理 3.20 机制核） ──
# bkLT(s, t) ⟺ t ⊏ s（真前段）∨ 首异位 s(k) < t(k)。延伸者更小。
function bkLT(s::Vector{Int}, t::Vector{Int})::Bool
    if length(t) < length(s) && s[1:length(t)] == t
        return true
    end
    m = min(length(s), length(t))
    for k in 1:m
        if s[k] != t[k]
            return s[k] < t[k]
        end
    end
    return false
end

# 窗口 2^≤d 的全部节点（含空段）。
allnodes(d) = vcat([Int[]],
    [[(i >> (k - j)) & 1 for j in 1:k] for k in 1:d for i in 0:(2^k - 1)])

# 长度 d 的全部实数（细化宇宙）。
space(d) = [[(i >> (d - 1 - j)) & 1 for j in 0:(d - 1)] for i in 0:(2^d - 1)]

# 二元窗口 2^≤3：全 15 节点——BK 是线性序（书断言），逐对验证。
nodes3 = allnodes(3)
@assert length(nodes3) == 15
pairs = [(a, b) for a in nodes3 for b in nodes3 if a != b]
total = sum(bkLT(a, b) != bkLT(b, a) for (a, b) in pairs)
anti = sum(!bkLT(a, a) for a in nodes3)
transok = all(!(bkLT(a, b) && bkLT(b, c)) || bkLT(a, c)
             for a in nodes3 for b in nodes3 for c in nodes3)
nilmax = all(bkLT(s, Int[]) for s in nodes3 if !isempty(s))
println("[BK] 2^≤3 线性序: 节点 15, 完全对 $(length(pairs)) 中恰好一向 $(total), 无自环 $(anti)/15, 传递 $(transok), ε 最大元 $(nilmax)")
@assert total == length(pairs) && anti == 15 && transok && nilmax

# 全二叉树 depth d 的最长 BK 递降链（按线性序排序后 DP）。
function longest_chain(d::Int)::Int
    ns = allnodes(d)
    sorted = sort(ns, lt = (x, y) -> bkLT(x, y))
    len = Dict(n => 1 for n in ns)
    for s in sorted
        for t in ns
            if bkLT(t, s)
                len[s] = max(len[s], len[t] + 1)
            end
        end
    end
    maximum(values(len))
end
chains = [longest_chain(d) for d in 0:3]
println("[BK] 全二叉树最长递降链: d=0→$(chains[1]) d=1→$(chains[2]) d=2→$(chains[3]) d=3→$(chains[4])（= 2^(d+1)-1，线性序容纳全部节点）")
@assert chains == [2^(d + 1) - 1 for d in 0:3]

# 长度 4 的全部 16 条序列：前缀链逐对递降（树枝即递降链）。
branch_ok = sum(all(bkLT([(i >> (3 - j)) & 1 for j in 0:3][1:k+1],
                        [(i >> (3 - j)) & 1 for j in 0:3][1:k]) for k in 0:3)
                for i in 0:15)
println("[BK] 16 条长度 4 序列前缀链递降: $(branch_ok)/16")
@assert branch_ok == 16

# ── 二、双树互补（定理 3.19 机制核） ──
# caught(T, x)：x 的每一段前缀都在树 T 中（π[T] 的有限替身）。
caught(T, x) = all(x[1:k] in T for k in 0:length(x))

# 稳定对：首位分裂 T = {ε}∪0⌢2^<ω，T* = {ε}∪1⌢2^<ω（对一切深度成立）。
pT(s) = isempty(s) || s[1] == 0
pS(s) = isempty(s) || s[1] == 1

for d in 1:6
    cov = all(x -> pT(x) || pS(x), space(d))
    dis = all(x -> !(pT(x) && pS(x)), space(d))
    @assert cov && dis
end
println("[双树-稳定对] 深度 1..6 全覆盖 ✓ 不相交 ✓（对深度无量化限制=「广泛」的影子）")

# 投影不变（外延稳定性）：细化的实数被接住 ⟹ 截断（旧实数）仍被接住。
refine_ok = sum(begin
    x = y[1:d]
    (pT(y) ? pT(x) : true) && (pS(y) ? pS(x) : true)
end for d in 1:5 for y in space(d + 1))
nref = sum(1 for d in 1:5 for y in space(d + 1))
@assert refine_ok == nref
println("[双树-稳定对] 投影不变: $(refine_ok)/$(nref) 条细化路径的截断保持接住 ✓")

# 截断对（覆盖当前宇宙 ≠ 广泛贝尔）：T = {ε,0}，T* = {ε,1}。
tt(s) = s == Int[] || s == [0]
ts(s) = s == Int[] || s == [1]
cov1 = all(x -> tt(x) || ts(x), space(1))
cov2 = all(x -> tt(x) || ts(x), space(2))
fails = [x for x in space(2) if !(tt(x) || ts(x))]
println("[双树-截断对] 覆盖深度 1: $(cov1)；覆盖深度 2: $(cov2) — 失败见证 $(fails)")
@assert cov1 && !cov2 && length(fails) == 4

# ── 三、枚举反例（Julia/Python 独立对拍） ──
# 2^≤2 上含根前缀闭节点集共 25 个；根交仅 {ε} 的有序对中
# 覆盖@1 但不覆盖@2 者即「不稳定对」（当前宇宙成立 ≠ 扩张后成立）。
prefix_closed(sub) = all(s[1:k] in Set(sub) for s in sub for k in 0:length(s) - 1)
inner = [[0], [1], [0, 0], [0, 1], [1, 0], [1, 1]]
subsets = [Set(vcat([Int[]], [inner[i] for i in 1:6 if (mask >> (i - 1)) & 1 == 1]))
           for mask in 0:63]
closed = unique(Set, filter(prefix_closed, subsets))
@assert length(closed) == 25
println("[枚举] 2^≤2 前缀闭节点集(含根): $(length(closed)) 个")

root_only = [(A, B) for A in closed for B in closed if intersect(A, B) == Set([Int[]])]
cov1pairs = [(A, B) for (A, B) in root_only if all(x -> x in A || x in B, space(1))]
cov2pairs = [(A, B) for (A, B) in cov1pairs if all(x -> caught(A, x) || caught(B, x), space(2))]
unstable = setdiff(Set(cov1pairs), Set(cov2pairs))
println("[枚举] 根交={ε} 有序对 $(length(root_only))；覆盖@1 $(length(cov1pairs))；其中覆盖@2 $(length(cov2pairs))；不稳定 $(length(unstable))")
bytotal = sort(collect(unstable), by = AB -> length(AB[1]) + length(AB[2]))
A1, B1 = bytotal[1]
minimal = sort(collect(A1), by = length)
minimal2 = sort(collect(B1), by = length)
println("[枚举] 最小不稳定对: T=$(repr(minimal)) / T*=$(repr(minimal2))（覆盖@1、扩张后失守——见证 [0,0]）")

println("BK 序线性/最长链/树枝递降；稳定对全覆盖+投影不变；截断对反例；枚举 25/不稳定账")
println("END ====")
