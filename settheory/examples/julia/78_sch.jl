# 第 78 章：奇异基数假设——银杰与嘎尔文-海纳（冯琦 §2.4）——Julia 通道
# 四个实验：monus 递减链与尾集之交为空（ω 处 club 滤子退化）；n=12 全部 4096
# 个子集的截断码穷举（单射 + 相等坐标被第一个分歧位封顶）；单点底空间的玩具
# 范数阶梯 ‖const v‖=v；定理 2.39 实例的指标记账。
println("==== 78")

# ---------- 实验一：monus 递减链与尾集之交为空 ----------
# f_n(k)=max(k−n,0)。{k : f_{n+1}(k)<f_n(k)} = {k≥n+1}（补集 {0..n} 有限），
# 故 f_{n+1} <_cofinite f_n，f₀>f₁>⋯ 是 cofinite 滤子下的无穷递减链。
# 但 ⋂_n {k≥n}=∅：cofinite 只 ω-完全而非 ℵ₁-完全，κ-完全性在 ω 处失效。
function exp1()
    f(n, k) = max(k - n, 0)
    N = 200
    for n in 0:20
        decrease = [k for k in 0:N if f(n + 1, k) < f(n, k)]
        @assert decrease == collect((n + 1):N)          # 恰是尾集 {k≥n+1}
        complement = [k for k in 0:N if !(f(n + 1, k) < f(n, k))]
        @assert complement == collect(0:n)              # 补集 {0..n} 有限
    end
    # ⋂_n {k : n ≤ k} = ∅：每个 k 都被第 k+1 个尾集甩掉
    @assert all(k -> !all(n -> n <= k, 0:(k + 1)), 0:N)
    return N
end
N1 = exp1()
println("实验一（monus 链）：{k:f_{n+1}(k)<f_n(k)}={k≥n+1} 补集有限，但 ⋂尾集=∅（验到 N=$N1）✓")

# ---------- 实验二：n=12 全部 4096 个子集的截断码穷举 ----------
# trunc(X,m)=X 的低 m 位 = X & (2^m−1) = X mod 2^m（与 Coq 通道同一定义）。
# (1) 编码 X↦(trunc(X,0),…,trunc(X,12)) 单射；
# (2) 对每对 X≠Y，第一个分歧位 γ=trailing_zeros(X⊻Y)，相等坐标恰是 {m≤γ}。
function exp2()
    n = 12
    N = 1 << n                                          # 4096 个子集
    codes = [Tuple(X & ((1 << m) - 1) for m in 0:n) for X in 0:N-1]
    @assert length(Set(codes)) == N                     # 单射：4096 个不同码
    pairs = 0
    for X in 0:N-1, Y in (X+1):N-1
        d = X ⊻ Y
        γ = trailing_zeros(d)                           # 最低分歧位
        mγ = (1 << γ) - 1
        @assert (X & mγ) == (Y & mγ)                    # m=γ：低 γ 位相同
        if γ + 1 <= n
            mγ1 = (1 << (γ + 1)) - 1
            @assert (X & mγ1) != (Y & mγ1)              # m=γ+1：含分歧位故不同
        end
        pairs += 1
    end
    return N, pairs
end
N2, pairs2 = exp2()
println("实验二（截断码穷举）：n=12 的 $N2 个子集编码单射；$pairs2 对 X≠Y 相等坐标均被第一个分歧位 γ 封顶为 {m≤γ} ✓")

# ---------- 实验三：单点底空间的玩具范数阶梯 ----------
# 底空间退化到一点时函数即自然数，g<f ⟺ g<f（数值）。定义 2.30 的
# ‖f‖=sup{‖g‖+1 : g<f} 变成 ghNorm(v)=max{ghNorm(g)+1 : g<v}，解出 ‖const v‖=v。
function ghnorm(v)
    v == 0 && return 0
    return maximum(ghnorm(g) + 1 for g in 0:(v - 1))
end
function exp3()
    for v in 0:6
        @assert ghnorm(v) == v                          # 与 Agda norm-const 一致
    end
    return [ghnorm(v) for v in 0:6]
end
ladder = exp3()
println("实验三（玩具范数阶梯）：单点底空间 ‖const v‖=v（v=0..6 → $ladder），与 Agda norm-const 一致 ✓")

# ---------- 实验四：定理 2.39 实例的指标记账 ----------
# α=ω₁、2^{ℵ₁}=ℵ₂ ⟹ ζ=(ℵ₂)⁺=ℵ₃。‖φ‖≤ω₂ 时 ω₁+‖φ‖≤ω₁+ω₂=ω₂<ω₃（ω₂ 吸收
# ω₁），故 ω₁+‖φ‖<ζ；且 ℵ_{ω₁}<ℵ_{ω₃}（指标 1<3）。用指标运算记账。
function exp4()
    idx_ω1, idx_ω2, idx_ω3 = 1, 2, 3                    # ω_n ↔ 指标 n
    two_pow_aleph1 = idx_ω2                             # 假设 2^{ℵ₁}=ℵ₂
    ζ_idx = two_pow_aleph1 + 1                          # ζ=(ℵ₂)⁺=ℵ₃
    @assert ζ_idx == idx_ω3
    for phi_idx in 0:idx_ω2                             # ‖φ‖ 指标 0..2（≤ω₂）
        sum_idx = max(idx_ω1, phi_idx)                  # ω₁+‖φ‖ 的指标上界（吸收律）
        @assert sum_idx < ζ_idx                         # ω₁+‖φ‖ < ω₃ = ζ
    end
    @assert idx_ω1 < idx_ω3                             # ℵ_{ω₁} < ℵ_{ω₃}
    return ζ_idx
end
ζ = exp4()
println("实验四（定理 2.39 记账）：2^{ℵ₁}=ℵ₂ ⟹ ζ=ℵ₃（指标 $ζ）；ω₁+‖φ‖<ω₃ 对 ‖φ‖≤ω₂；ℵ_{ω₁}<ℵ_{ω₃} ✓")

println("END ====")
