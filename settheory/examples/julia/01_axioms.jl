# 第 01 章 公理：公理即程序——Julia 世界的 ZFC 操作
#
# 每条"存在公理"在程序世界对应一个构造子；每条"唯一性"对应
# 外延性（Julia 的 Set 是按内容比较的——哈希集合天然外延）。
# 本文件把七条公理逐一"运行"，并验证它们相互配合的小定理。

println("==== 01 公理：公理即程序")

# ---------- 配对 / 单点 / 有序对 ----------

pair(a, b) = Set([a, b])                 # 配对公理
singleton(a) = Set([a])                  # 单点：{a,a} 的元素条件退化为 u=a

# Kuratowski 有序对 (a,b) = {{a},{a,b}}
opair(a, b) = Set([singleton(a), pair(a, b)])

println("pair(1,2) = ", pair(1, 2), "  singleton(3) = ", singleton(3))
println("opair(1,2) = ", opair(1, 2))
@assert pair(1, 2) == pair(2, 1)         # 配对的对称性（ST01 的 pair_commute）
@assert singleton(1) ⊆ pair(1, 2)

# ---------- 分离 / 并 / 幂集 / 替换 ----------

X = Set(1:6)
separate(X, p) = Set(x for x in X if p(x))   # 分离：性质在已有集合内划出子集

println("separate(X, 偶数) = ", separate(X, iseven))
@assert separate(X, iseven) == Set([2, 4, 6])

union_axiom(XS) = reduce(union, XS, init=Set())   # 并公理：⋃XS
println("⋃{ {1,2},{2,3},{5} } = ", union_axiom([Set([1,2]), Set([2,3]), Set([5])]))
@assert union_axiom([Set([1,2]), Set([2,3]), Set([5])]) == Set([1,2,3,5])

powerset(X) = begin                          # 幂集公理：枚举 2^n 个子集
    n = length(X)
    els = collect(X)
    Set(Set(els[i] for i in 1:n if (k >> (i-1)) & 1 == 1) for k in 0:(2^n-1))
end
P3 = powerset(Set(1:3))
println("|P({1,2,3})| = ", length(P3), "（应为 2³ = 8）")
@assert length(P3) == 8
@assert length(powerset(Set(1:4))) == 16

# 替换公理：函数像限制在集合上是集合——map 就是它的程序形态
replace(X, F) = Set(F(x) for x in X)
println("replace(X, x↦x²) = ", replace(X, x -> x^2))
@assert replace(X, x -> x^2) == Set([1, 4, 9, 16, 25, 36])

# ---------- Russell 集的程序形态 ----------
# 在"所有 Julia 对象"这个真类上做分离是不合法的；
# 程序世界只能在给定集合 X 内做。对角线化留给 X 的幂集：
# Y = {x ∈ X : x ∉ x} 永远不是 f : X → P(X) 的像（Cantor）。

cantor_escape(X) = Set(x for x in X if !(x in x))
# Julia 的整数不含自身（整数不是集合），所以逃逸集=X；
# 真正的对角线在 powerset 上：任何 g : X → P(X) 都漏掉
#   D = {x ∈ X : x ∉ g(x)}
g_missing(X, g) = Set(x for x in X if !(x in g[x]))
g = Dict(1 => Set(1:2), 2 => Set(2:3), 3 => Set([1]))
D = g_missing(Set(keys(g)), g)
println("对角线集 D = ", D, "（不在 g 的像中）")
@assert !(D in Set(Set(g[k]) for k in keys(g)))

# ---------- 无穷公理：von Neumann 数列 ----------
# n+1 = n ∪ {n}：每个自然数是所有前驱的集合。
# 用不可变元组编码（嵌套 frozenset 在 Julia 里无直接对应），
# 增长是指数级的：|n| = n，但树形展开的"地址数"按 Fibonacci 增长。

vn_succ(n) = (n..., n)                  # n+1 = n ∪ {n}（元组的并）

v0 = ()                                  # 0 = ∅
v1 = vn_succ(v0)                         # 1 = {∅}
v2 = vn_succ(v1)                         # 2 = {∅,{∅}}
v3 = vn_succ(v2)                         # 3 = {∅,{∅},{∅,{∅}}}
println("von Neumann 数：0=∅, 1={∅}, 2={∅,{∅}}")
println("  3 的第 k 个元素恰是 k（k=0,1,2）：", [v3[i] == v2[i] for i in 1:2])
@assert v3[3] == v2                      # 3 的最后一个元素是 2
@assert length(v1) == 1 && length(v2) == 2 && length(v3) == 3

println("要点：公理 = 允许的构造；程序世界的构造子即公理的化身。")

println("END ====")
