# 第 49 章 布尔补全：V 形偏序的 RO(Q) 实操（Lemma 4.2.5 可执行版）

println("==== 49")

# ---------- V 形偏序：c ≤ a, c ≤ b（1=c 底、2=a、3=b） ----------
le(x, y) = (x == y) || (x == 1)
P = [1, 2, 3]
down(p) = Set(q for q in P if le(q, p))

# 序拓扑的开集 = 下闭集
function downclosed(S)
    return all(!(p in S) || (down(p) ⊆ S) for p in P)
end
opens = Set{Set{Int}}()
for mask in 0:(2^3 - 1)
    S = Set(P[i] for i in 1:3 if (mask >> (i - 1)) & 1 == 1)
    downclosed(S) && push!(opens, S)
end
println("序拓扑开集（下闭集）：", sort.(sort.(collect.(collect(opens)))))

# 闭包：含 U 的最小闭集（闭集 = 开集之补 = 上闭集）
function closedset(U)
    cands = [setdiff(Set(P), O) for O in opens]
    contain = filter(C -> U ⊆ C, cands)
    return reduce((x, y) -> length(x) <= length(y) ? x : y, contain)
end
function int_(U)
    out = Set{Int}()
    for O in opens
        O ⊆ U && union!(out, O)
    end
    return out
end
reg(U) = int_(closedset(U))

# ---------- j(p) = Reg(↓p)（Lemma 4.2.5 的构造） ----------
j = Dict(p => reg(down(p)) for p in P)
for p in P
    println("j($p) = Reg(↓$p) = ", sort(collect(j[p])))
end

# ---------- 三断言 ----------
# (1) 保序：p ≤ q ⟹ j(q) ⊆ j(p)
ok_order = all(!le(p, q) || (j[q] ⊆ j[p]) for p in P for q in P)
println("(1) j 保序：", ok_order ? "✓" : "✗")
@assert ok_order

# (2) 保不相容：↓p ∩ ↓q = ∅ ⟹ j(p) ∩ j(q) = ∅
#    V 形中 a、b 都触及 c——无不相容对，断言空真验证：
ok_incompat = true  # 检查所有 p,q：若 ↓ 交空则 j 交空
for p in P, q in P
    if isempty(intersect(down(p), down(q)))
        global ok_incompat &= isempty(intersect(j[p], j[q]))
    end
end
println("(2) j 保不相容（V 形空真 + 逻辑检查）：", ok_incompat ? "✓" : "✗")
println("    ↓a ∩ ↓b = ", sort(collect(intersect(down(2), down(3)))), " ≠ ∅——a、b 相容")

# (3) 稠密像：每个非空正则开 A 被 j(p) 精化
ROs = Set{Set{Int}}()
for O in opens
    push!(ROs, reg(O))
end
ROlist = sort.(collect.(collect(ROs)))
println("RO(Q) = ", ROlist, "（", length(ROlist), " 元）")
ok_dense = all(isempty(A) || any(j[p] ⊆ Set(A) for p in P) for A in ROlist)
println("(3) j[Q] 稠密：", ok_dense ? "✓" : "✗")
@assert ok_dense

# ---------- 结果解读 ----------
println("补全 B_Q 是 ", length(ROlist), " 元布尔代数")
println("V 形偏序无相对不相容对——一切触及 c 的开集被缝合成 {c}，B_Q = 2 元链")
@assert length(ROlist) == 2

println("END ====")
