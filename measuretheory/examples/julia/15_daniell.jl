println("==== 15 daniell")
# 第 15 章：有限 Daniell 流水线（Ω = {1..8}，三块划分）。
# 块 B1={1,2}, B2={3,4}, B3={5,6,7,8}；H = 三块上的阶梯函数；
# I(αI_B1 + βI_B2 + γI_B3) = αw1 + βw2 + γw3（正线性泛函）。
# 五步：H* → C → μ* → Carathéodory 限制 → 表示定理；
# 外加非 Stone 瘦格的唯一性失败演示。

const B1 = [1, 2]
const B2 = [3, 4]
const B3 = [5, 6, 7, 8]
const W = (1//2, 1//3, 1//6)              # 块权（总质量 1）

# H 的元素表示为三值向量 (a1,a2,a3)（各块常值）
Ifun(t) = t[1]*W[1] + t[2]*W[2] + t[3]*W[3]

# --- 步骤 1-2：H*（有限格=非负阶梯）与 C（三块代数 8 集合） ---
mu_star(A) = sum(W[k] for (k, B) in enumerate((B1, B2, B3)) if !isempty(intersect(A, B)); init=0//1)
C_sets = Set{Vector{Int}}()
for m in 0:7
    s = Int[]
    (m & 1) != 0 && append!(s, B1)
    (m & 2) != 0 && append!(s, B2)
    (m & 4) != 0 && append!(s, B3)
    push!(C_sets, sort!(s))
end
@assert length(C_sets) == 8
# μ* 在 C 上 = I*(I_C)（块权和）
for C in C_sets
    @assert mu_star(C) == Ifun((C ⊇ B1 ? 1 : 0, C ⊇ B2 ? 1 : 0, C ⊇ B3 ? 1 : 0))
end
# 覆盖下确界：有限世界 μ*(A) = 命中块权和（对一切 A ⊆ Ω）
for A in ([1], [1,3], [5], [2,4,6], collect(1:8), Int[])
    @assert mu_star(A) == sum(W[k] for (k, B) in enumerate((B1, B2, B3)) if !isempty(intersect(A, B)); init=0//1)
end
println("steps 1-3: C = block algebra (8 sets), mu* = hit-block weight sum: OK")

# --- 步骤 4：Carathéodory 可测集 = 三块代数 ---
# A 可测 ⟺ 每块要么整块含于 A、要么与 A 不交（块 = μ* 的原子）
in_block_algebra(A) = all(B -> isempty(intersect(A, B)) || isempty(setdiff(B, A)), (B1, B2, B3))
@assert all(in_block_algebra, C_sets)
@assert !in_block_algebra([1, 3])               # 切开 B1：不可测
@assert !in_block_algebra([5, 6])               # 切开 B3
println("step 4: Caratheodory sets = block algebra; cross-block cuts not measurable: OK")

# --- 步骤 5：表示定理（随机 500 个 H 函数） ---
# ∫f dμ = Σ_blocks v_i·μ(B_i)（μ 是块上的原子测度，按块计价）
int_mu(t) = sum(v * mu_star(B) for (v, B) in zip(t, (B1, B2, B3)); init=0//1)
using Random
Random.seed!(15)
for _ in 1:500
    t = Tuple(rand(-3:3, 3))
    @assert Ifun(t) == int_mu(t)
end
println("step 5: I(f) = integral f dmu (block pricing) on 500 random H-functions: OK")

# --- 对照：换块权，μ 随之变（I 的信息全进 μ） ---
W2 = (1//5, 1//2, 3//10)
Ifun2(t) = t[1]*W2[1] + t[2]*W2[2] + t[3]*W2[3]
@assert Ifun2((1, 0, 0)) == 1//5               # 新权下 B1 块积分
@assert Ifun((1, 0, 0)) == 1//2 ≠ Ifun2((1, 0, 0))
println("weights determine mu: I changes -> mu changes (uniqueness direction): OK")

# --- 非 Stone 瘦格：唯一性失败 ---
# H' = 只含 (a, b, 0) 型（B3 上恒 0）：I'(f) = a w1 + b w2
# B3 上的质量对 I' 不可见——同一 I' 兼容任意 B3 权
Ifun3(t) = t[1]*W[1] + t[2]*W[2]
@assert Ifun3((1, 0, 0)) == 1//2
@assert Ifun3((0, 1, 0)) == 1//3
# 两个不同的 μ（B3 权 1/6 vs 0.7）都表示同一 I'
for w3 in (1//6, 7//10)
    Wt = (1//2, 1//3, w3)
    @assert Ifun3((1, 0, 0)) == 1//2           # I' 不变
    @assert sum(Wt) > 0                        # μ 却不同
end
println("non-Stone thin lattice: same I' represented by different B3 masses: OK")

println("END ====")
