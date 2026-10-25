# 第 90 章 · 力迫基本理论与 CH/AC 独立性（冯琦第二卷 §3.1-3.3）——Julia 通道
# 与 Python 同一组检查：相遇链引擎、泛型对角避让、Fn(3,2) 的
# 27 条件与 8 全函数（ccc 计数）、力迫关系原子形态。
println("==== 90")

# ---------- 一、相遇链（定理 3.1 的递归引擎） ----------

# q 延拓 p（更强）：p 是 q 的前缀。
ext(p, q) = length(p) <= length(q) && q[1:length(p)] == p

# 决定型稠密集 D_n 的选择函数：把 p 延拓到第 n 位被决定（补 0）。
decider(n) = p -> n < length(p) ? copy(p) : vcat(p, fill(0, n + 1 - length(p)))

function chain(ds)
    p = Int[]; out = [Int[]]
    for extf in ds
        p = extf(p); push!(out, copy(p))
    end
    out
end

ch = chain([decider(n) for n in 0:3])
@assert length.(ch) == [0, 1, 2, 3, 4]
@assert all(ext(ch[k], ch[k + 1]) for k in 1:4)
println("相遇链：决定型稠密集逐层相遇，链长 ", length.(ch))

# ---------- 二、泛型对角避让（例 3.3 的对角稠密集） ----------

# Julia 1 基索引：第 k 个分支在第 k 位被翻转（对应 0 基的位置 k-1）。
gen_build_from(bs) = [1 - b[k] for (k, b) in enumerate(bs)]

ground = [[1,0,1,0], [0,0,0,0], [1,1,0,0], [0,1,1,1]]
g = gen_build_from(ground)
@assert g == [0, 1, 1, 0]
@assert all(g[k] != ground[k][k] for k in 1:length(ground))
@assert all(g != b for b in ground)
println("泛型分支 ", g, "：与每个地基分支恰在位置 k-1 不同")

# ---------- 三、Fn(3,2) 计数（ccc 有限引擎） ----------

# 相容：公共定义域上取值一致（nothing = 未定义）。
compat(f, g) = all(!(a isa Int && b isa Int && a != b) for (a, b) in zip(f, g))

conds = vec(collect(Iterators.product((nothing, 0, 1), (nothing, 0, 1), (nothing, 0, 1))))
conds = [collect(t) for t in conds]
@assert length(conds) == 27

fill0(f) = Tuple(x isa Int ? x : 0 for x in f)
totals = unique(fill0(f) for f in conds)
@assert length(totals) == 8

# 相冲 => 填充不同（反链经零填充单射进 2^3）。
for f in conds, h in conds
    if !compat(f, h)
        @assert fill0(f) != fill0(h)
    end
end
println("Fn(3,2)：27 个条件，零填充像至多 2^3 = 8 个（ccc 计数账）")

# A_f：与 f 首次分歧的各长度前缀，两两相冲的极大反链。
antichain_A(f) = [vcat(f[1:n-1], [1 - f[n]]) for n in 1:length(f)]
Af = antichain_A([1, 0, 1])
@assert all(!compat(a, b) for a in Af, b in Af if a != b)
println("A_f 反链（n 个两两相冲条件，与 f 首次分歧于各位）：", Af)

# ---------- 四、力迫关系的原子形态（真值引理的原子条款） ----------

# p 力迫「第 n 位（0 基）= b」：p 已决定该位。
forces_bit(p, n, b) = n + 1 <= length(p) && p[n + 1] == b

# 串式条件空间：2^omega 的各层前缀。
strconds = [collect(t) for k in 0:3 for t in Iterators.product(fill((0, 1), k)...)]

# 决定集稠密 + 前缀保持。
for p in strconds
    for n in 0:2
        q = decider(n)(p)
        @assert any(forces_bit(q, n, b) for b in (0, 1))
    end
end
for p in strconds, q in strconds
    if ext(p, q)
        for n in 1:length(p)
            @assert q[n] == p[n]
        end
    end
end
println("决定集稠密 + 前缀保持：p 力迫 g(n)=b 时一切泛型满足 OK")

println("END ====")
