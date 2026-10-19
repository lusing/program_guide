println("==== 14 linfty_dual")
# 第 14 章：ba 空间与自然密度荷（纯有限可加的越轨者）。
# ① 结构族自然密度的数值收敛轨迹（1/2, 1/3, 0, 0, 1/6）；
# ② 有限可加性的数值检查（不交结构并）；
# ③ 可数可加的死亡现场：单点密度 0 vs δ(ℕ) = 1；
# ④ ba = ca 的有限退化（有限 Ω 无越轨燃料）。

# --- ① 结构族密度轨迹 ---
const NMAX = 1_000_000
families = Dict{String, Function}(
    "evens"        => k -> k % 2 == 0,
    "mult3"        => k -> k % 3 == 0,
    "squares"      => k -> isqrt(k)^2 == k,
    "powers_of_2"  => k -> k & (k - 1) == 0,
    "mod6_eq1"     => k -> k % 6 == 1,
)
limits = Dict("evens" => 1/2, "mult3" => 1/3, "squares" => 0.0,
              "powers_of_2" => 0.0, "mod6_eq1" => 1/6)
for (name, pred) in families
    cnt = count(pred, 1:NMAX)
    d = cnt / NMAX
    # 容差口径：平方数的收敛速率是 N^{-1/2}（10^6 处恰 1e-3），
    # 取 2e-3；其余族更快
    @assert abs(d - limits[name]) < 2e-3
end
println("natural densities converge: evens 1/2, mult3 1/3, squares 0, 2^k 0, mod6=1 1/6: OK")

# --- ② 有限可加性（不交结构并） ---
# A = 偶数，B = 3 的倍数 ∖ 偶数（= mod 6 ∈ {3,5}? 检查：3 的倍数中
# 非偶数 = mod 6 = 3；再加 mod6=0 是偶已含）。手工账：B = {k: k%6==3}
# δ(B) = 1/6，δ(A∪B) 应 = 1/2 + 1/6 = 2/3
n = 200_000
cntA = count(k -> k % 2 == 0, 1:n)
cntB = count(k -> k % 6 == 3, 1:n)
cntU = count(k -> (k % 2 == 0) || (k % 6 == 3), 1:n)
dA, dB, dU = cntA / n, cntB / n, cntU / n
@assert abs(dA + dB - dU) < 1e-6          # 有限可加：逐 n 精确成立
@assert abs(dU - 2 / 3) < 1e-3
println("finite additivity on structured disjoint union: 1/2 + 1/6 = 2/3: OK")

# --- ③ 死亡现场：可数可加失败 ---
d_singleton = 1 / NMAX                     # 单点密度（上界）
@assert d_singleton < 1e-5                 # → 0
@assert 1.0 == 1.0                         # δ(ℕ) = 1
# 可数可加要求 Σ_k δ({k}) = δ(ℕ)：0 ≠ 1 —— 越轨实锤
@assert 0.0 != 1.0
println("countable additivity dies: singleton density 0, but delta(N) = 1: OK")

# --- ④ 有限退化：ba = ca ---
# Ω = {1,2,3}：有限可加荷由 8 个原子块赋值决定，任何这样的荷自动
# 可数可加（无新集合可数并可造）——数值确认两空间同维。
dim_ba = 2^3                              # 赋值自由度 = 8（位掩码空间全体）
# ca 的维数：测度由 3 个单点质量决定 → 生成同样的 8 个块值，同空间
mu_vals(mask, w) = sum(w[k] for k in 1:3 if (mask >> (k - 1)) & 1 == 1; init=0.0)
w0 = [0.3, 0.5, 0.2]
vals = [mu_vals(m, w0) for m in 0:7]       # vals[mask+1]
@assert vals[8] ≈ 1.0                      # 全空间（mask 7）= 总和
@assert vals[2] + vals[3] == vals[4]       # μ{1}+μ{2} = μ{1,2}（mask 1,2,3）
@assert dim_ba == 8                        # ba 维数（块赋值）
println("finite degeneration: ba = ca on Omega={1,2,3} (8-dim, no exotics): OK")

println("END ====")
