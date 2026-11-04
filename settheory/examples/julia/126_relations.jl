# 第 126 章 Julia：关系与函数的计算面。
# ① 关系（元组列表）上的 dom/ran/像/逆像/复合/逆，与书 2.5.2/2.5.9
#    的定律对账；② 幂和三兄弟的闭式精确核对（书 2.2.2 例）；
# ③ 相容函数系统：可并（书 2.2.10）与冲突检测；④ Y^X 计数与
# 一般卡氏积的投影。
println("==== 126 relations")

# ① 关系代数
rdom(R) = Set(x for (x, y) in R)
rran(R) = Set(y for (x, y) in R)
rimg(R, A) = Set(y for (x, y) in R if x in A)
rinv(R) = Set((y, x) for (x, y) in R)
function rcomp(S, R)                                   # S∘R：先 R 后 S
    out = Set{Tuple{Any,Any}}()
    for (x, y) in R, (y2, z) in S
        y == y2 && push!(out, (x, z))
    end
    out
end

R = Set([(0, 'a'), (1, 'a'), (1, 'b'), (2, 'c')])
S = Set([('a', 'x'), ('b', 'y'), ('c', 'z')])
A, B = Set([0, 1]), Set([1, 2])
@assert rimg(R, A ∪ B) == rimg(R, A) ∪ rimg(R, B)      # 并律等式
@assert rimg(R, A ∩ B) ⊆ rimg(R, A) ∩ rimg(R, B)       # 交律单向
@assert rinv(rinv(R)) == R
@assert rdom(rinv(R)) == rran(R)
println("relation algebra: union law, one-way intersection, inv laws: OK")

# ② 幂和三兄弟（书 2.2.2）：闭式精确核对
s1(n) = n * (n + 1) ÷ 2
s2(n) = n * (n + 1) * (2n + 1) ÷ 6
s3(n) = (n * (n + 1) ÷ 2)^2
for n in 0:60    # n=0 时 sum(1:0) 空——用 init=0 兜底
    @assert sum(1:n; init=0) == s1(n)
    @assert sum(k -> k^2, 1:n; init=0) == s2(n)
    @assert sum(k -> k^3, 1:n; init=0) == s3(n)                # Nicomachus：S3 = S1²
end
println("power sums: S1,S2,S3 closed forms exact for n=0..60: OK")

# ③ 相容函数系统（书 2.2.8-2.2.10）
compatible(f, g) = all(f[k] == g[k] for k in intersect(keys(f), keys(g)))
function merge_or_nothing(f, g)
    compatible(f, g) || return nothing
    Dict(pairs(f)..., pairs(g)...)
end
f1 = Dict(0 => 'a', 1 => 'b')
f2 = Dict(1 => 'b', 2 => 'c')
f3 = Dict(1 => 'x')                                    # 与 f1 在 1 上冲突
@assert merge_or_nothing(f1, f2) == Dict(0 => 'a', 1 => 'b', 2 => 'c')
@assert isnothing(merge_or_nothing(f1, f3))
merged = merge_or_nothing(f1, f2)
@assert length(merged) == length(keys(f1) ∪ keys(f2))  # 并的定义域（2.2.10）
println("compatible systems: union is a function iff compatible: OK")

# ④ Y^X 计数 + 一般卡氏积（书 2.2.11/2.2.14）
for (n, m) in ((0, 2), (2, 2), (3, 2))
    dom = fill(0:m-1, n)                               # n 个 Y 的拷贝
    @assert length(collect(Iterators.product(dom...))) == m ^ n
end
Xs = [1 => ["a", "A"], 2 => ["b", "B"], 3 => ["c", "C"]]   # 指标系统 {X_1,X_2,X_3}
prod_all = vec(collect(Iterators.product(last.(Xs)...))) # Π X_i 的元素表
@assert length(prod_all) == 8
@assert ("a", "b", "c") in prod_all                    # 逐位取自各 X_i
@assert ("A", "B", "C") in prod_all
@assert !(("a", "b", "A") in prod_all)                 # 第三位必须来自 X_3
println("indexed families: |Y^X| counted, general product enumerated: OK")
println("END ====")
