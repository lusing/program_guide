# 第 111 章：有限树秩递归、完美子树与截面投影——余解析集树表示的影子。
println("==== 111")

# ── 一、树（堆编码：根 1，子点 2c / 2c+1；深度上限 2） ──
child(c::Int, b::Int) = 2c + b
parent(c::Int) = c ÷ 2
depthd(c::Int) = (d = 0; cc = c; while cc > 1; cc ÷= 2; d += 1; end; d)
const MAXD = 2

# 秩：叶 0、内部点 = 子最大 + 1（引理 3.5 的赋秩机制）。
function rho(T::Set{Int}, c::Int = 1)
    c ∈ T || return 0
    depthd(c) >= MAXD && return 0
    c0, c1 = 2c, 2c + 1
    c0 ∉ T && c1 ∉ T && return 0
    return 1 + max(c0 ∈ T ? rho(T, c0) : 0, c1 ∈ T ? rho(T, c1) : 0)
end

# 有树枝（无秩）⟺ 存在长度 MAXD 的路径（引理 3.3 的良基判定）。
has_branch(T::Set{Int}, c::Int = 1, d::Int = 0) =
    c ∈ T && (d == MAXD || has_branch(T, 2c, d + 1) || has_branch(T, 2c + 1, d + 1))

# ── 二、三棵样本树的秩账 ──
const T0 = Set([1, 2, 3])          # 根+两子：有秩，根秩 1
const T1 = Set([1, 2, 3, 4])       # 左枝到底：无秩，根秩 2 = 深度
const T2 = Set([1, 2, 3, 4, 5])    # 左右皆底：无秩，根秩 2

@assert rho(T0) == 1 && !has_branch(T0)
@assert rho(T1) == MAXD && has_branch(T1)
@assert rho(T2) == MAXD && has_branch(T2)

# 秩 ≤ 剩余深度（秩有界部分博雷尔的机制件）。
for T in (T0, T1, T2), c in collect(T)
    @assert rho(T, c) <= MAXD - depthd(c)
end

# ── 三、完美子树构造（开区分特性断言二：双子延伸） ──
function perfect_subtree(T::Set{Int}, c::Int = 1, d::Int = 0)
    c ∈ T || return Set{Int}()
    d >= MAXD && return Set{Int}([c])
    c0, c1 = 2c, 2c + 1
    if c0 ∈ T && c1 ∈ T
        return union(Set{Int}([c]),
                     perfect_subtree(T, c0, d + 1),
                     perfect_subtree(T, c1, d + 1))
    end
    return Set{Int}([c])           # 此处不再二叉分裂：子树在此封顶
end

P2 = perfect_subtree(T2)
@assert P2 == Set([1, 2, 3, 4, 5]) # 全树都是完美二叉（到深度 2）
P0 = perfect_subtree(T0)
@assert 2 in P0 && 3 in P0         # 根层分裂
@assert !(4 in P0)                 # 深度 1 层无分裂（叶）

# ── 四、二维树与截面投影（引理 3.3：A = p[S] ⟺ S(α) 无秩） ──
# 二维树 S：等长位串对（xs, ys）的前段封闭集。
# 截面 S(α) = {ys | (α[1:len(ys)], ys) ∈ S}；截面有树枝 ⟺
# ∃ y（全长）使一切前段对都在 S。
branches2() = [[a, b] for a in 0:1 for b in 0:1]

function section_has_branch(S::Set{Tuple{Vector{Int},Vector{Int}}}, α::Vector{Int})
    for y in branches2()
        ok = all((α[1:k], y[1:k]) in S for k in 0:MAXD)
        ok && return true
    end
    return false
end

projection(S) = Set(α for α in branches2() if section_has_branch(S, α))

# 对角二维树：xs = ys 的全部前段对——每个 α 都有树枝（对角线见证）。
S_diag = Set{Tuple{Vector{Int},Vector{Int}}}()
for n in 0:MAXD
    for (a, b) in ((0, 0), (0, 1), (1, 0), (1, 1))
        p = [a, b][1:n]
        push!(S_diag, (p, copy(p)))
    end
end
@assert length(S_diag) == 1 + 2 + 4    # n=0 一个、n=1 两个、n=2 四个
@assert projection(S_diag) == Set(branches2())

# 单侧二维树：只允许 x 首位为 0 的 α 有见证。
S_side = Set{Tuple{Vector{Int},Vector{Int}}}([(Int[], Int[])])
push!(S_side, ([0], [0]))
push!(S_side, ([0], [1]))
push!(S_side, ([1], [0]))
for b in 0:1, c in 0:1
    push!(S_side, ([0, b], [c, b]))
end
@assert projection(S_side) == Set([[0, 0], [0, 1]])
@assert !([1, 0] in projection(S_side))

println("Julia：三树秩账（1/2/2）+树枝判定；秩≤剩余深度；")
println("完美子树（T2 全二叉/T0 根层即叶）；对角与单侧二维树的投影账")
println("END ====")
