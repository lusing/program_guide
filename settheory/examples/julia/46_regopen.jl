# 第 46 章 Viale 路线第一站：正则开集与 ⊥ 五律的有限验证

println("==== 46")

# ---------- 有限拓扑：4 点空间 Ω = {0,1,2,3} ----------
# 拓扑 τ 由开集族直接给出（含 ∅ 与 Ω，对任意并、有限交封闭）
# 选一个非平凡拓扑：{0} 开、{0,1} 开、{2,3} 开
Ω = Set([0, 1, 2, 3])
opens = Set{Set{Int}}([
    Set{Int}(), Set([0]), Set([0,1]), Set([2,3]),
    Set([0,2,3]), Set([0,1,2,3])
])
# 自检：拓扑公理（任意并 + 有限交封闭）
for A in opens, B in opens
    @assert union(A, B) in opens
    @assert intersect(A, B) in opens
end

"""闭包：含 U 的最小闭集（闭集 = 开集的补）"""
function cl(U, opens, Ω)
    closed = [setdiff(Ω, O) for O in opens]
    cands = filter(C -> U ⊆ C, closed)
    return reduce((a, b) -> length(a) <= length(b) ? a : b, cands)
end

"""内部：含于 U 的最大开集"""
function int_(U, opens)
    cands = filter(O -> O ⊆ U, collect(opens))
    return reduce((a, b) -> length(a) >= length(b) ? a : b, cands)
end

"""正则化 Reg(U) = int(cl(U))（Viale Def 2.1.9）"""
reg(U, opens, Ω) = int_(cl(U, opens, Ω), opens)

"""补运算 U⊥ = Ω ∖ cl(U)（Viale Notation 2.1.9）"""
perp(U, opens, Ω) = setdiff(Ω, cl(U, opens, Ω))

println("拓扑 τ 的开集数：", length(opens))
println("正则开集族 RO(X)：")
ros = Set{Set{Int}}()
for U in opens
    push!(ros, reg(U, opens, Ω))
end
for r in sort(collect(ros); by = x -> collect(x))
    println("  Reg 开集 = ", sort(collect(r)))
end

# ---------- ⊥ 五律逐条验证（Viale Fact 2.1.10） ----------
sub(A, B) = A ⊆ B

println("验证五律（对全部 16 个子集两两组合）：")

# 五律主检查：封装成函数避免顶层 for 的软作用域歧义
function check_laws(opens, Ω)
    n_check = 0
    allsubsets = union(Set{Set{Int}}([Set{Int}()]), Set{Set{Int}}([Set([x]) for x in Ω]),
        Set{Set{Int}}([Set([x, y]) for x in Ω for y in Ω if x < y]),
        Set{Set{Int}}([Set([x, y, z]) for x in Ω for y in Ω for z in Ω if x < y < z]),
        Set{Set{Int}}([Ω]))

    for U in allsubsets, V in allsubsets
    # (1) 反单调：U ⊆ V ⟹ V⊥ ⊆ U⊥
    if sub(U, V)
        @assert sub(perp(V, opens, Ω), perp(U, opens, Ω)); n_check += 1
    end
    # (2) De Morgan 并律：(U ∪ V)⊥ = U⊥ ∩ V⊥
    @assert perp(union(U, V), opens, Ω) ==
            intersect(perp(U, opens, Ω), perp(V, opens, Ω)); n_check += 1
    # (3) Reg(V) = V⊥⊥（双 ⊥ 就是正则化；任意 V）
    @assert reg(V, opens, Ω) == perp(perp(V, opens, Ω), opens, Ω); n_check += 1
    # (4) 开集上 U⊥⊥ = Reg(U) 且 U⊥⊥⊥ = U⊥（一次 ⊥ 已正则）
    if U in opens
        @assert perp(perp(U, opens, Ω), opens, Ω) == reg(U, opens, Ω); n_check += 1
        @assert perp(perp(perp(U, opens, Ω), opens, Ω), opens, Ω) ==
                perp(U, opens, Ω); n_check += 1
    end
    # (5) 开集上 (U ∩ V)⊥⊥ = U⊥⊥ ∩ V⊥⊥（正则开对交封闭的 ⊥ 形态）
    if U in opens && V in opens
        @assert perp(perp(intersect(U, V), opens, Ω), opens, Ω) ==
                intersect(perp(perp(U, opens, Ω), opens, Ω),
                          perp(perp(V, opens, Ω), opens, Ω)); n_check += 1
    end
end
    return n_check
end

n_total = check_laws(opens, Ω)
println("五律断言全部通过，共 $(n_total) 条。")

# ---------- 引理 2.1.4 的点态刻画 ----------
# x ∈ Reg(A) ⟺ 存在开 U ∋ x 使 A ∩ U 在 U 中稠密
# 有限空间中"A∩U 在 U 稠密"⟺ cl(A∩U) ⊇ U
dense_in(A, U, opens, Ω) = U ⊆ cl(intersect(A, U), opens, Ω)

println("引理 2.1.4 点态刻画：")
for A in opens, x in Ω
    lhs = x in reg(A, opens, Ω)
    rhs = any(U in opens for U in opens if x in U && dense_in(A, U, opens, Ω))
    @assert lhs == rhs
end
println("  点态刻画逐点核对通过。")

# ---------- Fact 2.1.8：U∩V ≠ ∅ ⟺ U∩Reg(V) ≠ ∅（U,V 开） ----------
for U in opens, V in opens
    @assert !isempty(intersect(U, V)) == !isempty(intersect(U, reg(V, opens, Ω)))
end
println("Fact 2.1.8（相交判据）验证通过。")

println("END ====")
