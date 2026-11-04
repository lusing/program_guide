# 第 138 章 Julia：κ·κ = κ 的标准序现场（书 5.2.5 图 5.1）。
# 标准序 ≺：先比 max(α,β)，再字典序。按层枚举 ω×ω 的元素：
# 第 n 层（max = n）有 ≤ 2n+1 个元素——每层有限，层内字典序，
# 这正是书 5.2.5 证明的"按层计数"骨架：κ×κ 是 κ 个"小于 κ"的层
# 之并，归纳假设把它们全部吃掉。
println("==== 138 cardinal arith")

# 标准序（书 5.4 式）
function std_lt(p, q)
    (a1, b1), (a2, b2) = p, q
    m1, m2 = max(a1, b1), max(a2, b2)
    m1 != m2 && return m1 < m2
    a1 != a2 && return a1 < a2
    return b1 < b2
end

# 按标准序枚举 [0,N)² 的全部元素：层 n = max(α,β) = n 的方框边
function std_enum(N)
    out = Tuple{Int,Int}[]
    for n in 0:N-1
        layer = [(a, n) for a in 0:n-1]                  # 边的上半（α<n, β=n）
        append!(layer, [(n, b) for b in 0:n])            # 边的下半含角 (n,n)
        append!(out, layer)                              # 层内已是字典序
    end
    out
end

E = std_enum(100)
@assert length(E) == 100 * 100                           # 全覆盖
@assert length(unique(E)) == length(E)                   # 不重
# 标准序在枚举中严格递增：E[k] ≺ E[k+1]
@assert all(std_lt(E[k], E[k+1]) for k in 1:length(E)-1)
println("standard order: (w x w, prec) enumerates 10000 pairs layer by layer: OK")

# 每层的大小：第 n 层恰 2n+1 个元素——"小于 κ"的层（κ=ω 时有限）
layers = [length(std_enum(n+1)) - length(std_enum(n)) for n in 0:8]
@assert layers == [1, 3, 5, 7, 9, 11, 13, 15, 17]
println("layer sizes: shell n has exactly 2n+1 elements: OK")

# κ+κ=κ 的现场：偶数 ∪ 奇数 = ω 的两个 ω-块
evens = 0:2:198
odds = 1:2:199
@assert length(collect(evens)) == length(collect(odds)) == 100
@assert isdisjoint(collect(evens), collect(odds))
@assert sort(vcat(collect(evens), collect(odds))) == collect(0:199)  # ⊞ = ω（union 无序，排序后核对）
println("kappa + kappa = kappa: evens + odds = omega (window): OK")

# 有限对照：3+3 = 6 ≠ 3
@assert 3 + 3 == 6 && 3 * 3 == 9
println("finite contrast: 3+3=6, 3*3=9 -- absorption is infinite-only: OK")
println("END ====")
