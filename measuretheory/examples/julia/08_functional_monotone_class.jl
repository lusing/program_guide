println("==== 08 functional_monotone_class")
# 第 08 章：函数 λ-闭包的有限模型（Ω = {1,2,3,4}，整数值格 0..2）。
# λ-运算：非负数乘（标量 ∈ {0,1,2}）、优减劣（f ≥ g 逐点）、
#         有界加法（逐坐标 ≤ 2）。种子含常值 1。
# 对照 A（π-类 C = {∅, {1,2}, Ω}，种子 {1, I12}）：
#   闭包应恰为"按块 {1,2}|{3,4} 常数"的格点函数全体（M(C)=L_b(C) 的影子）。
# 对照 B（非 π 类 C' = {{1,2},{2,3}}，种子 {1, I23}）：
#   闭包严格小于 σ(C')-可测全体（σ(C') = 全幂集 → 格点全体）——
#   定理判据的 π-性条件不是摆设：I2 = I12·I23 需要乘法，λ-运算造不出。

const N = 4
const SCALARS = [0, 1, 2]

valid(f) = all(x -> 0 ≤ x ≤ 2, f)

"""λ-闭包：从 seeds 出发迭代数乘 / 优减劣 / 有界加法至不动点。"""
function lambda_closure(seeds)
    S = Set(Tuple.(seeds))
    changed = true
    while changed
        changed = false
        cur = collect(S)
        for c in SCALARS, f in cur
            t = c .* collect(f)
            if valid(t) && !(Tuple(t) in S)
                push!(S, Tuple(t)); changed = true
            end
        end
        for f in cur, g in cur
            fv = collect(f); gv = collect(g)
            if all(fv .>= gv)                       # 优减劣
                t = fv .- gv
                if valid(t) && !(Tuple(t) in S)
                    push!(S, Tuple(t)); changed = true
                end
            end
            t = fv .+ gv                            # 有界加
            if valid(t) && !(Tuple(t) in S)
                push!(S, Tuple(t)); changed = true
            end
        end
    end
    return S
end

# --- 对照 A：π-类 {∅, {1,2}, Ω} ---
I12 = (1, 1, 0, 0)
one = (1, 1, 1, 1)
closureA = lambda_closure([one, I12])
LbA = Set{NTuple{4,Int}}()                     # 按块常数的格点函数
for a in 0:2, b in 0:2
    push!(LbA, (a, a, b, b))
end
println("pi-case: |closure| = ", length(closureA), ", |L_b ∩ grid| = ", length(LbA))
@assert closureA == LbA                          # 有限模型上 M(C) = L_b(C)
@assert (0, 0, 1, 1) in closureA                 # I34 = 1 − I12 到场
println("pi-case: closure == L_b, I_{3,4} = 1 - I_{1,2} in closure: OK")

# --- 对照 B：非 π 类 {{1,2},{2,3}} ---
I23 = (0, 1, 1, 0)
closureB = lambda_closure([one, I23])
LbB = Set{NTuple{4,Int}}()                     # σ(C') = 幂集 → 一切格点函数
for a in 0:2, b in 0:2, c in 0:2, d in 0:2
    push!(LbB, (a, b, c, d))
end
println("non-pi: |closure| = ", length(closureB), ", |L_b ∩ grid| = ", length(LbB))
@assert issubset(closureB, LbB) && closureB != LbB
@assert (0, 1, 0, 0) ∉ closureB                  # I2（乘积指示）不在 λ-闭包
@assert length(closureB) == 9                    # 恰为 {a·I23 + b·I14} 的 9 元
println("non-pi: closure strictly smaller (", length(closureB), " < ", length(LbB),
        "), product indicator I_{2} missing: OK")

println("END ====")
