# 第 28 章 · 码：分组码、线性码与译码 —— Julia 通道
#
# [7,4] 汉明码全流程：编码/伴随式/译码/完全码计数。

println("==== 28 码：分组码、线性码与译码")

# [7,4] 汉明码校验矩阵：列 j = j 的二进制（GF(2)³ 非零向量）
const H74 = Int[1 0 1 1 0 1 1;
               0 1 1 1 1 0 0;
               0 0 0 0 1 1 1]
# 校验：每列 = (j 的二进制 001,010,100 排布)。用标准列 = 1..7 的二进制：
const H = Int[0 0 0 1 1 1 1;
              0 1 1 0 0 1 1;
              1 0 1 0 1 0 1]

syndrome(y) = map(x -> mod(x, 2), H * y)

"""伴随式译码：s = 0 无错；s = 列 j ⟹ 翻转第 j 位。"""
function decode74(y)
    s = syndrome(y)
    all(iszero, s) && return copy(y)
    for j in 1:7
        s == H[:, j] || continue
        z = copy(y); z[j] = 1 - z[j]
        return z
    end
    error("伴随式不在列中")
end

# ---------- 码字清单（H·x = 0 的全部解）----------
codewords = Vector{Int}[]
for code in 0:127
    y = digits(Int, code, base=2, pad=7)
    all(iszero, syndrome(y)) && push!(codewords, y)
end
@assert length(codewords) == 16
# 最小重量 = 3
minwt = minimum(count(!=(0), c) for c in codewords if any(!=(0), c))
@assert minwt == 3
# 重量谱 {0,3,4,7}
wts = sort(unique(count(!=(0), c) for c in codewords))
@assert wts == [0, 3, 4, 7]
println("码字清单：16 个、最小距离 3、重量谱 {0,3,4,7} ✓")

# ---------- 完全码：128 = 16 × 8 ----------
"""最近码字索引（汉明距离）。"""
function nearest_idx(y)
    best, bd = 1, typemax(Int)
    for (i, c) in enumerate(codewords)
        d = count(!=(0), y - c)
        if d < bd
            best, bd = i, d
        end
    end
    best
end
covered_class = Set{Int}()
for code in 0:127
    y = digits(Int, code, base=2, pad=7)
    idx = nearest_idx(y)
    push!(covered_class, idx)
    @assert count(!=(0), y - codewords[idx]) <= 1
end
@assert length(covered_class) == 16               # 最近邻分类 16 类
println("完全码：128 = 16 × (1+7)——每个向量到最近码字距离 ≤ 1，恰 16 类 ✓")

# ---------- 全错误模拟 ----------
for (ci, c) in enumerate(codewords), j in 1:7
    y = copy(c); y[j] = 1 - y[j]
    z = decode74(y)
    @assert z == c "码字 $ci 位 $j 译码失败"
end
println("译码：16 码字 × 7 位单错 = 112 个受损字全部恢复 ✓")

# ---------- 汉明界 ----------
# 纠一码需 M(1+n) ≤ 2ⁿ：n = 7 取等
@assert 16 * (1 + 7) == 2^7
# n = 6：无完全码（7 ∤ 64 结构性）
println("汉明界：n=7 取等（完全码）；一般 M(1+n) ≤ 2ⁿ ✓")

# ---------- GF(3) [4,2,3] 汉明码 ----------
H3 = Int[1 0 1 1;
         0 1 1 2]
cw3 = Vector{Int}[]
for code in 0:(3^4 - 1)
    y = digits(Int, code, base=3, pad=4)
    s = map(x -> mod(x, 3), H3 * y)
    all(iszero, s) && push!(cw3, y)
end
@assert length(cw3) == 9
minwt3 = minimum(count(!=(0), c) for c in cw3 if any(!=(0), c))
@assert minwt3 == 3
println("GF(3) [4,2,3] 汉明码：9 码字、最小距离 3 ✓")

println("END ====")
