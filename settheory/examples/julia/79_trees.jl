# 第 79 章：树、苏斯林树、马丁公理与划分定理（冯琦 §2.5–2.6）——Julia 通道
# 三个实验。实验一：穷举 K5/K6 的全部边二染色，精确锁定 5 < R(3,3) <= 6：
#   K5 有 12 种染色不含单色三角形（标号五循环），K6 的 32768 种染色全部含；
# 实验二：有限 Ramsey 上界递归 R(s,t) <= R(s-1,t)+R(s,t-1)（R(2,t)=t）；
# 实验三：定理 2.44 的构造性内容——有限偏序上逐次加强必能相遇全部稠密集：
#   二叉前缀树上相遇 D_n={长度>=n} 得等高枝；下降序列树（例 2.17(3) 有限版）
#   的最大枝长恰为字母表大小。
println("==== 79")

# ---------- 实验一：K5/K6 二染色穷举 ----------
edges(n) = Tuple{Int,Int}[(i, j) for i in 0:n-1 for j in (i+1):n-1]
triples(n) = Tuple{Int,Int,Int}[(i, j, k)
              for i in 0:n-1 for j in (i+1):n-1 for k in (j+1):n-1]

# 第 k 种染色：每条边的颜色取 k 的二进制位（0/1），与边表字典序对齐。
colorings(n) = (begin
    es = edges(n)
    ([((k >> i) & 1) for i in 0:length(es)-1] for k in 0:(1<<length(es))-1)
end)

function mono_triangle(c, idx, tris)
    for (i, j, k) in tris
        a, b, d = c[idx[(i,j)]], c[idx[(i,k)]], c[idx[(j,k)]]
        if (a == b == d == 0) || (a == b == d == 1)
            return true
        end
    end
    return false
end

function scan(n)
    es = edges(n)
    idx = Dict(e => i for (i, e) in enumerate(es))
    total = clean = 0
    witness = nothing
    for c in colorings(n)
        total += 1
        if !mono_triangle(c, idx, triples(n))
            clean += 1
            witness = c
        end
    end
    return total, clean, witness
end

# 显式五循环见证：红边 0-1-2-3-4-0，蓝边为补（也是五循环）。
es5 = edges(5)
red5 = Set([(0,1),(1,2),(2,3),(3,4),(0,4)])
w5 = [in(e, red5) ? 0 : 1 for e in es5]
idx5 = Dict(e => i for (i, e) in enumerate(es5))
@assert !mono_triangle(w5, idx5, triples(5))

t5, clean5, _ = scan(5)
@assert t5 == 1024 && clean5 == 12          # 12 个标号五循环
t6, clean6, _ = scan(6)
@assert t6 == 32768 && clean6 == 0          # 全部含单色三角形
println("实验一（Ramsey 穷举）：K5 共 $t5 种染色，$clean5 种无单色三角形（五循环）")
println("  K6 共 $t6 种染色，无单色三角形者 $clean6 种 ⟹ 5 < R(3,3) ≤ 6（与 Coq/Python 对账）✓")

# ---------- 实验二：有限 Ramsey 上界递归 ----------
# R(2,t)=R(t,2)=t；R(s,t) <= R(s-1,t)+R(s,t-1)（任取一点，其同色邻接边
# 按鸽子笼必有一色达到对应阈值）。这是定理 2.51 证明中的 l=R(l1,l2;n)+1 账。
const memo = Dict{Tuple{Int,Int},Int}()
function ramsey_upper(s, t)
    s == 2 && return t
    t == 2 && return s
    return get!(memo, (s, t)) do
        ramsey_upper(s-1, t) + ramsey_upper(s, t-1)
    end
end
@assert ramsey_upper(3, 3) == 6
@assert ramsey_upper(3, 4) == 10       # 原始递归界；偶数和再 sharpen 到 9（精确值）
@assert ramsey_upper(3, 5) == 15
@assert ramsey_upper(4, 4) == 20       # 偶数和再 sharpen 到 18（经典界）
println("实验二（Ramsey 上界递归）：R(3,3)≤$(ramsey_upper(3,3))、" *
        "R(3,4)≤$(ramsey_upper(3,4))（偶数和→9）、R(3,5)≤$(ramsey_upper(3,5))、" *
        "R(4,4)≤$(ramsey_upper(4,4))（偶数和→18）；上界 6 与穷举恰中 R(3,3)=6 ✓")

# ---------- 实验三：有限泛善子集（定理 2.44）与等高枝 ----------
# 例 2.17(3) 的有限版：字母表 {0,...,m} 上的严格下降序列树。
# 每个节点对应一个子集按降序排列；最大枝长 = m+1（取尽全部字母），
# 树高 m+1 但无更长枝——阿朗谢树「每层不大却无等高枝」的有限直觉原型。
function decreasing_nodes(m)
    nodes = Vector{Int}[]
    for submask in 0:(1<<(m+1))-1
        push!(nodes, [x for x in m:-1:0 if (submask >> x) & 1 == 1])
    end
    return nodes
end
function max_branch(m)
    return maximum(length(n) for n in decreasing_nodes(m))
end

# 偏序 P = {0,1}^<=K，按前缀序；D_n = {长度 ≥ n} 稠密。
# 从空串出发逐次补 0 相遇 D_1,...,D_K，取全部前缀得滤子 G。
function exp3(K)
    p = Int[]
    G = [Int[]]
    for n in 1:K
        p = vcat(p, 0)
        push!(G, copy(p))
    end
    isprefix(a, b) = length(a) <= length(b) && b[1:length(a)] == a
    @assert length(G) == K + 1
    @assert all(n -> any(length(q) >= n for q in G), 1:K)        # 相遇每个 D_n
    @assert all(q -> all(m -> any(r == q[1:m] for r in G), 0:length(q)), G)   # 下闭
    @assert all(q1 -> all(q2 -> isprefix(q1, q2) || isprefix(q2, q1), G), G)  # 两两相容
    return all(max_branch(m) == m+1 for m in 0:6)
end
K3 = 6
@assert exp3(K3)
println("实验三（有限泛善/等高枝）：二叉树深 $K3 上逐次加强相遇 D_1..D_$K3 得滤子（下闭、定向、全相遇）")
println("  下降序列树 m=0..6 的最大枝长恰为 m+1：有限版无等高枝原型（无穷阿朗谢树须正文构造）✓")

println("END ====")
