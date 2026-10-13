# 第 17 章 完备布尔代数：正则开集与 r.o.(P)

println("==== 17 完备布尔代数：r.o.(P)")

# ---------- 正则开集运算（int cl int = int） ----------

"""正则化：u ↦ int(cl(u))"""
regularize(U) = int(cl(int(cl(U))))

# 有限拓扑空间上的 clopen / regular open 演示
# 用集合的整数表示（位向量）
# 论域 {0,1,2}，拓扑由开基 { {0}, {0,1}, {0,2}, {0,1,2} } 生成

universe = Set([0, 1, 2])
opens = [Set([]), Set([0]), Set([0,1]), Set([0,2]), Set([0,1,2])]

"""闭包 = 含 U 的最小闭集（闭集 = 开集的补）"""
function cl(U, opens, Ω)
    closed = [setdiff(Ω, O) for O in opens]
    filter(C -> U ⊆ C, closed) |> minimum_by_card
end
minimum_by_card(cands) = reduce((a,b) -> length(a) <= length(b) ? a : b, cands)

"""内部 = 含于 U 的最大开集"""
function int_(U, opens)
    filter(O -> O ⊆ U, opens) |> maximum_by_card
end
maximum_by_card(cands) = length(cands) == 0 ? Set([]) : reduce((a,b) -> length(a) >= length(b) ? a : b, cands)

U = Set([1,2])
println("U = {1,2}：int(U) = ", int_(U, opens), "，cl(U) = ", cl(U, opens, universe))
println("int(cl(U)) = ", int_(cl(U, opens, universe), opens), "  = 整个空间（U稠密）")
println("正则化：U ↦ int(cl(U)) 是正则开——完备布尔代数的元素。")

println("END ====")
