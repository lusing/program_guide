# 第 99 章：有限滤基扩展与有限子句集可满足性搜索。
println("==== 99")

# ── 一、滤基扩展：subsets 上的 κ-完全滤子有限影子 ──
# 全集 {0,1,2,3}；F_k = 全体 ≥k 元子集。F_3 ⊆ F_2——「κ-完全
# 滤子扩展」的骨架是层间包含：放宽阈值即得更大的滤子，且两层
# 各自对超集封闭（向上封闭在层内成立）。
univ4 = Set(0:3)
maskset(S) = Set(i for i in 0:3 if (S >> i) & 1 == 1)
F0 = Set(maskset(S) for S in 0:15 if count(i -> (S >> i) & 1 == 1, 0:3) >= 3)
F2 = Set(maskset(S) for S in 0:15 if count(i -> (S >> i) & 1 == 1, 0:3) >= 2)

@assert issubset(F0, F2)
# 层内向上封闭：任一成员的超集（仍在全集内）在同一层。
for F in (F0, F2), S in collect(F)
    for T in collect(F2)
        issubset(S, T) && @assert T in F
    end
end
@assert !any(length(S) <= 1 for S in collect(F0))
# F_2 中新加入的成员：恰 2 元集（4 元全集已在 F_0）。
@assert all(length(S) == 2 for S in collect(setdiff(F2, F0)))

# ── 二、有限子句集可满足性：暴力搜索 ──
function sat_search(clauses, nvars)
    for mask in 0:(1 << nvars - 1)
        v = p -> (mask >> p) & 1 == 1
        ok = all(any(l -> l[2] ? v(l[1]) : !v(l[1]), c) for c in clauses)
        ok && return true, mask
    end
    return false, -1
end

# 样本 1：{{p0∨¬p1}, {p1∨p2}} 可满足
c1 = [Set([(0, true), (1, false)]), Set([(1, true), (2, true)])]
ok1, w1 = sat_search(c1, 3)
@assert ok1

# 样本 2：{{p0}, {¬p0}} 不可满足
c2 = [Set([(0, true)]), Set([(0, false)])]
ok2, _ = sat_search(c2, 1)
@assert !ok2

# 紧致性骨架：{p0,¬p0} 的每个真子集可满足而整体不可满足。
for i in 1:2
    sub = [c2[j] for j in 1:2 if j != i]
    ok, _ = sat_search(sub, 1)
    @assert ok
end

println("Julia：滤基 F_3 ⊆ F_2 向上生成、小集不在滤中；")
println("2 样本可满足性 + {p0,¬p0} 真子集可满足而整体不可满足")
println("END ====")
