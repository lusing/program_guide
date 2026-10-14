# 第 57 章：关系的机器化（Makinson Ch2）
# 三点集 512 关系普查 + Warshall 闭包 + 关系代数书本例子 + 等价类
println("==== 57")

const D3 = 0:2
allpairs3 = [(a, b) for a in D3 for b in D3]

# ---------- 一、512 个关系的普查 ----------
has(r, p) = p in r
refl(r) = all(has(r, (a, a)) for a in D3)
irrefl(r) = all(!has(r, (a, a)) for a in D3)
sym(r) = all(!has(r, p) || has(r, reverse(p)) for p in allpairs3)
trans(r) = all(!(has(r, p) && has(r, q) && p[2] == q[1]) || has(r, (p[1], q[2]))
              for p in allpairs3 for q in allpairs3)
antisym(r) = all(!(has(r, p) && has(r, q) && p[2] == q[1] && q[2] == p[1]) ||
                 p[1] == q[1]
                 for p in allpairs3 for q in allpairs3)
total(r) = all(has(r, p) || has(r, reverse(p)) for p in allpairs3)
equiv(r) = refl(r) && sym(r) && trans(r)
poset(r) = refl(r) && antisym(r) && trans(r)
linear(r) = poset(r) && total(r)

masks = 0:511
census_count(f) = Base.count(f, masks)
rel_of(m) = [allpairs3[i] for i in 1:9 if (m >> (i - 1)) & 1 == 1]
onmask(f) = m -> f(rel_of(m))

census = Dict(
    "自反"     => census_count(onmask(refl)),
    "对称"     => census_count(onmask(sym)),
    "非自反"   => census_count(onmask(irrefl)),
    "传递"     => census_count(onmask(trans)),
    "反对称"   => census_count(onmask(antisym)),
    "等价"     => census_count(onmask(equiv)),
    "偏序"     => census_count(onmask(poset)),
    "线性序"   => census_count(onmask(linear)),
)
println("  三点集关系普查（共 $(length(masks)) = 2^9 个）：")
for (k, v) in census
    println("    $(k)：$(v)")
end
@assert census["自反"] == 64 && census["对称"] == 64 && census["传递"] == 171 &&
        census["反对称"] == 216 && census["等价"] == 5 && census["偏序"] == 19 &&
        census["线性序"] == 6

# ---------- 二、Warshall 传递闭包（位矩阵） ----------
function warshall(adj::Matrix{Bool})
    n = size(adj, 1)
    cl = copy(adj)
    for k in 1:n, i in 1:n, j in 1:n
        cl[i, j] |= cl[i, k] && cl[k, j]
    end
    cl
end

# 三点环：闭包 = 全关系（不对称的反例：R 不对称但 R⁺ 全）
cycle = Bool[0 1 0; 0 0 1; 1 0 0]
cl = warshall(cycle)
println("  三点环的传递闭包 = 全关系：", all(cl))
@assert !all(cycle .== cl') # 原关系不对称（严格讲：逆不等）

# 迭代法（书本 bottom-up 定义）对照
function iter_close(adj::Matrix{Bool})
    cl = copy(adj)
    while true
        nxt = cl .| (cl * cl .> 0)
        nxt == cl && return cl
        cl = nxt
    end
end
@assert iter_close(cycle) == warshall(cycle)
println("  Warshall 与迭代法闭包一致 ✓")

# ---------- 三、关系代数：书本 2.3.2 数字例子 ----------
Aset, Bset, Cset = [2, 3, 13], [12, 15, 17], [11, 16, 21]
R = Set((a, b) for a in Aset, b in Bset if b % a == 0)
S = Set((b, c) for b in Bset, c in Cset if b % 2 == c % 2)
join = Set((a, b, c) for (a, b) in R, (b2, c) in S if b == b2)
comp = Set((a, c) for (a, b, c) in join)
println("  R（整除）= ", sort!(collect(R)))
println("  S（同奇偶）= ", sort!(collect(S)))
println("  join(R,S) 大小 = $(length(join))（书本答案 4）")
println("  S∘R（投影）= ", sort!(collect(comp)))
@assert length(join) == 4 && comp == Set([(2,16),(3,16),(3,11),(3,21)])

# ---------- 四、等价类：同素因子集（2..16） ----------
pf(n) = Set(p for p in 2:16 if n % p == 0 && all(p % d != 0 for d in 2:p-1))
classes = Dict{Set{Int},Vector{Int}}()
for n in 2:16
    key = pf(n)
    push!(get!(classes, key, Int[]), n)
end
println("  同素因子集的划分（2..16）：")
for v in sort!(collect(values(classes)))
    println("    ", sort!(v))
end
println("  共 $(length(classes)) 个类（书本答案 10 个，含单元素类）")

# ---------- 五、家族关系：复合与闭包 ----------
parents = Set([( :tom, :mary), (:mary, :ann), (:bob, :tom)])
comp_rel(r, s) = Set((a, c) for (a, x) in r, (x2, c) in s if x == x2)
grandp = comp_rel(parents, parents)
println("  P∘P（祖辈）= ", collect(grandp), "（tom 是 ann 的祖父）")
@assert (:tom, :ann) in grandp

function tc(r)
    cl = copy(r)
    while true
        nxt = union(cl, comp_rel(cl, r))
        nxt == cl && return cl
        cl = nxt
    end
end
anc = tc(parents)
println("  P⁺（先辈）= ", sort!(collect(anc)))
@assert Set([(:tom,:mary),(:mary,:ann),(:bob,:tom),(:tom,:ann),(:bob,:mary),(:bob,:ann)]) == anc

# ---------- 六、立即前驱（Hasse 骨架）：整除于 2..13 ----------
dom = collect(2:13)
dvd = Set((a, b) for a in dom, b in dom if a != b && b % a == 0)
covers = Set((a, b) for (a, b) in dvd
             if !any((a, x) in dvd && (x, b) in dvd for x in dom if x != a && x != b))
println("  整除于 2..13 的立即前驱（书本答案 9 对）：", sort!(collect(covers)))
@assert length(covers) == 9

println("END ====")
