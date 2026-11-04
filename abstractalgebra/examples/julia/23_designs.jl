# 第 23 章 · 一个数学旅程 —— Julia 通道
#
# 暹罗法幻方 + GF(q) 正交拉丁方 + Fano/仿射设计 + 射影平面。

println("==== 23 一个数学旅程")

# ---------- (1) 暹罗法造奇数阶幻方 ----------
function siam_magic(n::Int)
    n % 2 == 1 || error("奇数阶")
    M = zeros(Int, n, n)
    i, j = 1, (n + 1) ÷ 2
    for k in 1:n^2
        M[i, j] = k
        i2, j2 = mod1(i - 1, n), mod1(j + 1, n)
        if M[i2, j2] != 0
            i2, j2 = mod1(i + 1, n), j
        end
        i, j = i2, j2
    end
    M
end

magic_sum(n) = n * (n^2 + 1) ÷ 2
for n in (3, 5, 7)
    M = siam_magic(n)
    @assert all(sum(M[r, :]) == magic_sum(n) for r in 1:n)     # 行
    @assert all(sum(M[:, c]) == magic_sum(n) for c in 1:n)     # 列
    @assert sum(M[d, d] for d in 1:n) == magic_sum(n)          # 主对角
    @assert sum(M[d, n + 1 - d] for d in 1:n) == magic_sum(n)  # 副对角
    @assert sort(vec(M)) == collect(1:n^2)                     # 1..n² 各一次
end
println("暹罗法：n = 3, 5, 7 幻方全查（行列对角和 = $(magic_sum(5)) 型）✓")

# ---------- (2) GF(5) 的 4 个 MOLS 两两正交 ----------
n = 5
pairs_ok = true
for a1 in 1:n-1, a2 in a1+1:n-1
    seen = Set{Tuple{Int,Int}}()
    for i in 0:n-1, j in 0:n-1
        push!(seen, ((a1 * i + j) % n, (a2 * i + j) % n))
    end
    length(seen) == n^2 || (global pairs_ok = false)
end
@assert pairs_ok
println("GF(5)：L_a(i,j) = ai+j 的 4 个拉丁方两两正交（25 序对无重复）✓")

# ℤ₆ 上线性构造破产（36 军官阴影）
seen6 = Set{Tuple{Int,Int}}()
for i in 0:5, j in 0:5
    push!(seen6, ((1 * i + j) % 6, (5 * i + j) % 6))
end
@assert length(seen6) < 36
println("ℤ₆：同型线性构造序对重复（36 军官阴影的机器侧写）✓")

# ---------- (3) STS(7) = Fano 平面 ----------
fano_lines = [[0,1,3],[1,2,4],[2,3,5],[3,4,6],[4,5,0],[5,6,1],[6,0,2]]
for l in fano_lines, m in fano_lines
    l === m && continue
    @assert length(intersect(l, m)) == 1   # 两线恰交一点
end
# 每对点恰共一线
for p1 in 0:6, p2 in p1+1:6
    cnt = count(l -> p1 in l && p2 in l, fano_lines)
    @assert cnt == 1
end
println("Fano 平面：7 线两两交一点；21 对点各恰共一线（STS(7)）✓")

# STS(9)：ℤ₃² 的 12 条仿射直线（点编号 = 3y + x）
ag_lines = Set{Vector{Int}}()
for a in 0:2, b in 0:2                     # y = ax + b
    push!(ag_lines, sort([3 * ((a * x + b) % 3) + x for x in 0:2]))
end
for c in 0:2                               # x = c（竖线）
    push!(ag_lines, sort([3 * y + c for y in 0:2]))
end
@assert length(ag_lines) == 12
for p1 in 0:8, p2 in p1+1:8
    cnt = count(l -> p1 in l && p2 in l, ag_lines)
    @assert cnt == 1 "点对 ($(p1),$(p2)) 共线 $(cnt) 条"
end
println("STS(9)（仿射平面 AG(2,3)）：12 条线、36 对点各恰共一线 ✓")

# ---------- (4) PG(2,5)：31 点 31 线每线 6 点 ----------
# 齐素坐标 [a:b:c] 的代表：非零三元组模 (ℤ₅)* 缩放
function proj_points(q)
    pts = Vector{Vector{Int}}()
    seen = Set{Vector{Int}}()
    for a in 0:q-1, b in 0:q-1, c in 0:q-1
        (a == 0 && b == 0 && c == 0) && continue
        # 规范代表：首个非零分量化为 1
        rep = if a != 0; inv = modinv(a, q); [1, b * inv % q, c * inv % q]
        elseif b != 0; inv = modinv(b, q); [0, 1, c * inv % q]
        else; [0, 0, 1] end
        push!(pts, rep)
    end
    unique(pts)
end
modinv(a, q) = (for b in 1:q-1; a * b % q == 1 && return b; end; error())
pts5 = proj_points(5)
@assert length(pts5) == 31                 # 5² + 5 + 1
# 线 = 满足 αa + βb + γc = 0 的点集；由对偶也 31 条
lines5 = Set{Vector{Int}}()
for alpha in pts5
    line = sort([i for (i, pt) in enumerate(pts5)
                 if (alpha[1]*pt[1] + alpha[2]*pt[2] + alpha[3]*pt[3]) % 5 == 0])
    push!(lines5, line)
end
@assert length(lines5) == 31
@assert all(length(l) == 6 for l in lines5)
println("PG(2,5)：31 点 31 线、每线恰 6 点（齐次坐标生成）✓")

println("END ====")
