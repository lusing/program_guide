# 第 08 章 · 置换 —— Julia 通道
#
# 复合/逆/循环分解/逆序数符号 + S₃/S₄ 级全量断言（命题 2.24/2.32/2.39/2.55）。

println("==== 08 置换")

compose(α::Vector{Int}, β::Vector{Int}) = [α[β[i]] for i in eachindex(β)]
function perminv(α::Vector{Int})
    r = similar(α)
    for (i, ai) in enumerate(α); r[ai] = i; end
    r
end

"""循环分解：只列长度 ≥ 2 的循环（命题 2.24 的"跟着走"）。"""
function cycles(α::Vector{Int})
    n = length(α)
    seen = falses(n)
    out = Vector{Int}[]
    for i in 1:n
        (seen[i] || α[i] == i) && continue
        c = Int[]; j = i
        while !seen[j]
            seen[j] = true; push!(c, j); j = α[j]
        end
        push!(out, c)
    end
    out
end

"""逆序数 → 符号。"""
signum(α::Vector{Int}) =
    (count(i < j && α[i] > α[j] for i in eachindex(α), j in eachindex(α)) % 2 == 0) ? 1 : -1

"""置换的阶：最小 k 使 α^k = id（用于对拍 lcm 公式）。"""
function perm_order(α::Vector{Int})
    k, cur = 1, copy(α)
    while cur != collect(1:length(α))
        cur = compose(α, cur)
        k += 1
    end
    k
end

"""全部置换（自实现字典序生成，无第三方包）。"""
function all_perms(n::Int)
    out = Vector{Int}[]
    p = collect(1:n)
    while true
        push!(out, copy(p))
        k = 0
        for i in n-1:-1:1
            if p[i] < p[i+1]; k = i; break; end
        end
        k == 0 && break
        l = 0
        for j in n:-1:1
            if p[k] < p[j]; l = j; break; end
        end
        p[k], p[l] = p[l], p[k]
        reverse!(p, k + 1)
    end
    out
end

# ---------- S₃ 手算对照 ----------
S3 = all_perms(3)
@assert length(S3) == 6
@assert cycles([2, 3, 1]) == [[1, 2, 3]]
@assert cycles([2, 1, 3]) == [[1, 2]]
@assert compose([2, 1, 3], [1, 3, 2]) == [2, 3, 1]   # (12)∘(23)：先 (23) 后 (12) = (123)
println("S₃ 循环分解与复合从右向左：手算一致 ✓")

# ---------- 命题 2.54：阶 = lcm(循环长度)，S₄ 全量 ----------
for α in all_perms(4)
    @assert perm_order(α) == foldl(lcm, length.(cycles(α)); init=1)
end
println("命题 2.54（阶 = lcm 循环长）：S₄ 全部 24 个置换 ✓")

# ---------- 定理 2.39：sgn 乘法性，S₄ 全对 ----------
for α in all_perms(4), β in all_perms(4)
    @assert signum(compose(α, β)) == signum(α) * signum(β)
end
@assert count(α -> signum(α) == 1, all_perms(4)) == 12
println("定理 2.39（sgn(αβ) = sgn(α)sgn(β)）：S₄ 全部 576 对 ✓；|A₄| = 12 ✓")

# ---------- 命题 2.32：共轭保持循环结构 ----------
for α in all_perms(4), γ in all_perms(4)
    δ = compose(compose(α, γ), perminv(α))     # αγα⁻¹
    @assert sort(map(sort, cycles(δ))) ==
          sort(map(c -> sort([α[i] for i in c]), cycles(γ)))
end
println("命题 2.32（αγα⁻¹ 与 γ 循环结构同）：S₄ 全对 ✓")

# ---------- 循环结构类大小（推论 2.144 的实例） ----------
struct_count(n, lens) =
    count(all_perms(n)) do α
        sort(length.(cycles(α))) == sort(lens)
    end
@assert struct_count(5, [2, 3]) == 20 "(abc)(de) 型 = 5!/6 = 20"
@assert struct_count(5, [5]) == 24
@assert struct_count(5, [2]) == 10
println("S₅ 循环结构类：(abc)(de) 20 个、(abcde) 24 个、(ab) 10 个 ✓")

# ---------- 15-字谜判定器（例 2.42） ----------
"""可解性判定（4×4）：不含空格的逆序数 + 空格自底行号之和为奇 ⟺ 可解。"""
function fifteen_solvable(board::Vector{Int})
    tiles = [x for x in board if x != 0]
    inv = count(tiles[i] > tiles[j] for i in eachindex(tiles), j in eachindex(tiles) if i < j)
    blank_pos = findfirst(==(0), board)
    row_from_bottom = 4 - div(blank_pos - 1, 4)
    (inv + row_from_bottom) % 2 == 1
end
goal = vcat(collect(1:15), 0)
@assert fifteen_solvable(goal)
# 水平滑一步（15 与空格交换）：仍可解
h = copy(goal); h[15], h[16] = h[16], h[15]
@assert fifteen_solvable(h)
# 垂直滑一步（12 与空格交换）：仍可解
v = copy(goal); v[12], v[16] = v[16], v[12]
@assert fifteen_solvable(v)
# 14-15 互换：不可解（Sam Loyd 的经典骗局）
sw = copy(goal); sw[14], sw[15] = sw[15], sw[14]
@assert !fifteen_solvable(sw)
println("15-字谜判定器：目标/水平滑/垂直滑可解；14-15 互换不可解 ✓")

println("END ====")
