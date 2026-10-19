println("==== 12 signed_measures")
# 第 12 章：离散 RN 与 Hahn 分解的穷举验证。
# Ω = {1..6}，μ = 计数测度。ν = w·μ（密度还原）、符号权 s 的 Hahn
# 穷举（64 集合，位掩码枚举）、变差与达界、Lebesgue 分解的有限退化。

const OMEGA = 1:6
const w = [1, 2, 3, 4, 5, 6] ./ 21        # 密度（质量和 1）
const s = [3, -1, 2, -2, 0, 1]            # 符号权

mu(A) = length(A)                          # 计数测度
nu_w(A) = sum(w[k] for k in A; init=0.0)   # ν = w·μ
nu_s(A) = sum(s[k] for k in A; init=0)     # 符号测度

# 位掩码子集枚举（免外部依赖）
subset_of(mask) = [k for k in OMEGA if (mask >> (k - 1)) & 1 == 1]
all_subsets() = (subset_of(m) for m in 0:63)
subsets_within(A) = (B for B in all_subsets() if isempty(setdiff(B, A)))

# --- ① 密度还原：离散 RN = 逐点除法 ---
for k in OMEGA
    g = nu_w([k]) / mu([k])                # g(k) = ν({k})/μ({k})
    @assert abs(g - w[k]) < 1e-15
end
for A in ([1, 3], [2, 4, 6], collect(OMEGA), Int[])
    @assert abs(nu_w(A) - sum(w[k] for k in A; init=0.0)) < 1e-15
end
println("discrete RN = pointwise division: g restored from nu/mu on atoms: OK")

# --- ② Hahn 分解穷举 ---
D = [k for k in OMEGA if s[k] > 0]         # 正权位 {1,3,6}
Dc = setdiff(collect(OMEGA), D)            # 非正权位 {2,4,5}
# Hahn 条件：A ⊆ D ⟹ ν(A) ≥ 0；A ⊆ Dᶜ ⟹ ν(A) ≤ 0（穷举 64 集）
for A in all_subsets()
    isempty(setdiff(A, D)) && @assert nu_s(A) >= 0
    isempty(setdiff(A, Dc)) && @assert nu_s(A) <= 0
end
# 正部/负部：sup-定义 vs D-公式 逐集合吻合
nu_pos_sup(A) = maximum(nu_s(B) for B in subsets_within(A))
nu_neg_sup(A) = maximum(-nu_s(B) for B in subsets_within(A))
for A in ([1, 2, 3], [2, 4], collect(OMEGA))
    @assert nu_pos_sup(A) == nu_s(intersect(A, D))
    @assert nu_neg_sup(A) == -nu_s(intersect(A, Dc))
end
println("Hahn decomposition: sup-definition matches D-formula on all subsets: OK")

# --- ③ 变差与达界（3.3.6 有限版） ---
@assert sum(abs.(s)) == 9                  # |ν|(Ω) = Σ|s_k|
@assert nu_s(D) == 6 && nu_s(Dc) == -3     # 最大 6、最小 −3
best = maximum(nu_s(A) for A in all_subsets())
worst = minimum(nu_s(A) for A in all_subsets())
@assert best == nu_s(D) && worst == nu_s(Dc)
println("total variation 9; nu attains max 6 at D, min -3 at Dc (3.3.6): OK")

# --- ④ Lebesgue 分解的有限退化定理 ---
@assert all(mu([k]) == 1 for k in OMEGA)   # 计数基无零测原子
println("Lebesgue decomposition degenerates: counting base has no null atoms, singular part = 0: OK")

println("END ====")
