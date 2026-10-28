# 第 98 章：有限 L[U] 层级对拍——同一测度不同外延表示。
println("==== 98")

# 谓词 U 的两种外延表示：外延相等（都是 {0,3,6}），层级必须一致。
PA(x) = x % 3 == 0
PB(x) = x in (0, 3, 6)
@assert all(PA(x) == PB(x) for x in 0:7)

# 有限 Def 算子：D 上由 P-原子布尔项定义的子集。
# P-原子只有两种取值来源：{x∈D : P x} 与常值 D/∅（P a 真/假），
# 故可定义集恰为规范四元组 {∅, D, D∩P, D∖P}——有限影子。
function definable(D, P)
    SP = sort(collect(x for x in D if P(x)))
    SC = sort(collect(x for x in D if !P(x)))
    return Set([Int[], sort(collect(D)), SP, SC])
end

LU(n, P) = definable(collect(0:min(n - 1, 7)), P)

L1A, L1B = LU(1, PA), LU(1, PB)
L2A, L2B = LU(2, PA), LU(2, PB)
L3A, L3B = LU(3, PA), LU(3, PB)
@assert L1A == L1B && L2A == L2B && L3A == L3B

# 外延不同的谓词：层级必然不同（D∩P 集不同）。
PC(x) = x % 3 == 1
L3C = LU(3, PC)
@assert L3C != L3A

# 定义集含于全域幂集（DPow ⊆ Pow 的影子）。
D3 = collect(0:2)
allsub = Set(sort(collect(filter(i -> (mask >> i) & 1 == 1, D3)))
             for mask in 0:(2^3 - 1))
@assert LU(3, PA) ⊆ allsub

println("Julia：外延相等（PA=PB={0,3,6}）⟹ 三层 L[U] 层级逐层相同；")
println("外延不同（PC={1,4,7}）⟹ 层级不同；定义集 ⊆ 全域幂集")
println("END ====")
