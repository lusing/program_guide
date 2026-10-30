# 第 104 章：Prikry 条件的纯延长序与有限纯决策穷举。
println("==== 104")

# ── 一、条件与序（定义 2.6 的有限影子）──
# stem = 严格递增有限序列；big = 测度一集的影子（含尾核 CORE 的集合）。
const CORE = Set(5:9)
isbig(A) = CORE ⊆ A

isPrefix(t, s) = length(t) <= length(s) && t == s[1:length(t)]

# 纯延长（更强方向）：不动 stem、收窄测度一集——p ≤ q 要求 p.big ⊆ q.big。
ple(p, q) = p[1] == q[1] && issubset(p[2], q[2])

prikryLe(p, q) =
    isPrefix(q[1], p[1]) &&
    issubset(p[2], q[2]) &&
    issubset(Set(p[1][length(q[1])+1:end]), q[2])

# 纯延长的自反/传递（Task 19 Step 2 指定件）。
for A in [Set(5:9), Set(4:9)]
    @assert ple(("s", A), ("s", A))
end
p = ("s", Set(5:9)); q = ("s", Set(4:9)); r = ("s", Set(3:9))
@assert ple(p, q) && ple(q, r) && ple(p, r)   # 传递样本（5:9 ⊆ 4:9 ⊆ 3:9）

# 全序自反 + 事实 2.3.1 前半（交条件双侧纯延长）。
s = [2, 5, 7]
for A in [Set(5:9), Set(3:9)]
    @assert prikryLe((s, A), (s, A))
end
A, B = Set(5:9), Set([3, 5, 6, 7, 8, 9])
@assert ple((s, intersect(A, B)), (s, A)) && ple((s, intersect(A, B)), (s, B))

# ── 二、有限纯决策穷举：Prikry 判定性的 Ramsey 内核 ──
# 引理 2.4 的证明用「可测 ⟹ κ-Ramsey」（定理 1.6）取整齐集。
# 有限影子 = R(3,3)=6：对 {0..5} 的递增对 2-染色穷举，
# 每个染色都有同色三元组——「不动 stem 地判定语句」的组合内核。
const U6 = collect(0:5)
pairs = [(i, j) for i in U6, j in U6 if i < j]   # 15 对

function homo_triple(color)
    for a in 0:3, b in (a+1):4, c in (b+1):5
        if color[(a,b)] == color[(b,c)] == color[(a,c)]
            return (a, b, c)
        end
    end
    return nothing
end

n_homo6 = 0
for mask in 0:(2^15 - 1)
    global n_homo6
    color = Dict(pairs[k] => (mask >> (k-1)) & 1 for k in 1:15)
    ht = homo_triple(color)
    ht !== nothing || error("R(3,3)=6 失败于 mask=$mask")
    n_homo6 += 1
end
@assert n_homo6 == 2^15

# ── 三、泛型序列候选（Mathias 定理 2.7 的影子）──
# 测度一集 = 含尾核 CORE 的集合；X 是 Prikry 序列候选 ⟺
# X 递增无界且对一切 A ⊇ CORE 有 |X∖A| < ω（影子：尾段落入 CORE）。
function is_prikry_candidate(X)
    all(X[i] < X[i+1] for i in 1:length(X)-1) || return false
    k = findlast(x -> !(x in CORE), X)
    return k === nothing || k <= 4   # 非核元素至多出现在前 4 位
end

@assert is_prikry_candidate([1, 2, 5, 6, 7, 8, 9])
@assert !is_prikry_candidate([5, 1, 6, 7, 8])          # 非递增
@assert is_prikry_candidate([3, 4, 5, 6, 7, 8, 9])     # 前段非核、尾段入核
@assert !is_prikry_candidate([5, 6, 7, 8, 9, 2])       # 非递增（尾混低值）

# G(X) 的成员判定（定理 2.7）：(s,A) ∈ G(X) ⟺ s = X∩α ∧ X∖s ⊆ A。
function in_GX(s, A, X)
    α = length(s)
    s == X[1:α] && issubset(setdiff(Set(X), Set(s)), A)
end
X = [1, 2, 5, 6, 7, 8, 9]
@assert in_GX([1, 2], Set(5:9), X)          # s = X∩2, 尾在核中
@assert !in_GX([1, 5], Set(5:9), X)         # s ≠ X∩α（跳过 2）
@assert !in_GX([1, 2], Set([6,7,8,9]), X)   # A 缺 5：X∖s ⊄ A
@assert in_GX(X, Set(5:9), X)               # 整序列即 stem

println("Julia：纯延长自反/传递、事实 2.3.1、R(3,3)=6 全染色穷举（$n_homo6 例）；")
println("Prikry 序列候选与 G(X) 成员判定——判定性 Ramsey 内核 + Mathias 影子")
println("END ====")
