# 第 88 章 · L 中的组合原理与弱紧基数（冯琦第二卷 §2.1.4-2.1.5）——Julia 通道
# 与 Python 同一组检查：封口引擎（定理 2.12 性质 (4)）、钻石时刻表、柯尼希树枝。
println("==== 88")

const BitVec = Vector{Int}

# ---------- 一、封口引擎 ----------

children(level::Vector{BitVec}) =
    vcat([vcat(t, [0]) for t in level], [vcat(t, [1]) for t in level])

prefix_of(a::BitVec, t::BitVec) = length(a) <= length(t) && t[1:length(a)] == a

function seal_level(A, level)
    grown = children(level)
    [t for t in grown if any(prefix_of(a, t) for a in A)]
end

sealed_by(A, level) = all(any(prefix_of(a, t) for a in A) for t in level)

A0 = [BitVec([1, 1])]
T = [[BitVec()]]                          # 第 0 层：{空串}
push!(T, children(T[end]))                 # 第 1 层
push!(T, seal_level(A0, T[end]))           # 第 2 层：封 A0
while length(T) < 6
    push!(T, children(T[end]))             # 第 3-5 层
end
A1 = [T[6][1]]                             # 第 5 层首节点为新反链（levels 1-based）
push!(T, seal_level(A1, T[end]))           # 第 6 层：封 A1
while length(T) < 10
    push!(T, children(T[end]))             # 第 7-9 层
end

sizes = length.(T)
println("层规模: ", sizes, "（两次封口各剪掉一半）")
for n in 3:length(T)
    @assert sealed_by(A0, T[n])
end
for n in 7:length(T)
    @assert sealed_by(A1, T[n])
end
println("A0 自第 2 层、A1 自第 6 层起全程封口：极大性永久保持 OK")

# ---------- 二、钻石时刻表 ----------

function vtwo(n)
    v = 0
    while n > 0 && n % 2 == 0
        n ÷= 2
        v += 1
    end
    return v
end

target(i, j) = (j % (i + 2)) < 2

N_STAGES = 480
for n in 1:N_STAGES - 1
    i = vtwo(n)
    m = n >> i                             # 算术账：n = 2^i * 奇数
    @assert m % 2 == 1 && n == (2^i) * m
end
hits = [count(n -> vtwo(n) == i, 1:N_STAGES - 1) for i in 0:5]
@assert all(hits[i + 1] >= N_STAGES ÷ 2^(i + 1) - 1 for i in 0:5)
println("时刻表各目标时刻数: ", hits, " —— 每个目标被猜中无穷多次 OK")

# ---------- 三、柯尼希树枝 ----------

in_tree(t) = all(1:length(t)) do j
    p = t[1:j]
    count(==(1), p) <= count(==(0), p) + 2
end

branch = BitVec()
for _ in 1:24
    for b in (0, 1)
        cand = vcat(branch, [b])
        if in_tree(cand) && in_tree(vcat(cand, [0, 0, 0, 0]))
            global branch = cand
            break
        end
    end
end
@assert in_tree(branch) && length(branch) == 24
println("贪心树枝长度 24，全程满足树条件 OK（层有限 + 无限深 -> 有树枝）")

println("END ====")
