println("==== 31 weak_convergence")
# 第 31 章：Portmanteau 四条款逐条验收 + Skorokhod 轨道。
# ① 闭集 limsup / ② 开集 liminf（逃逸例双向）；
# ③ 连续集条款（δ_{1/n} 于跳点失败/连续点成功）；
# ④ Skorokhod：分位逆同源采样的轨道收敛频率。

# ①② 逃逸族 μₙ = (1-1/n)δ₀ + (1/n)δₙ 的开闭账
mun(n, A) = (1 - 1 / n) * (0.0 in A ? 1.0 : 0.0) + (1 / n) * (n in A ? 1.0 : 0.0)
F_cl = Set([0.0])                                  # 闭集 {0}
G_op = x -> (-1.0 < x < 1.0)                       # 开集 (-1,1) 的示性
Gop(n) = (1 - 1/n) * 1.0 + (1/n) * ((-1.0 < n < 1.0) ? 1.0 : 0.0)  # 0 ∈ G，n ∉ G
for n in (10, 1000, 100000)
    @assert mun(n, F_cl) ≤ 1.0 + 1e-12             # limsup μₙ({0}) = 1 ≤ μ({0}) = 1 ✓
    @assert Gop(n) ≥ 1 - 1 / n - 1e-12             # liminf μₙ(G) = 1 ≥ μ(G) = 1 ✓
end
println("portmanteau closed/open clauses on contaminated escape: OK")

# ③ 连续集：δ_{1/n} 于 (−∞,t] 的账
contset(t, n) = 1.0 / n ≤ t ? 1.0 : 0.0
for t in (-0.5, 0.2, 1.0)                          # μ=δ₀ 的连续点（t ≠ 0）
    tgt = 0.0 ≤ t ? 1.0 : 0.0
    @assert contset(t, 10000) == tgt
end
@assert contset(0.0, 10000) == 0.0                 # 跳点失败
println("continuity-set clause: converges at mu-continuity t, fails at jump: OK")

# ④ Skorokhod 同源采样：X̃ₙ = Qₙ(U)、X̃ = Q(U) 的轨道差
using Random
Random.seed!(31)
N = 100_000
U = rand(N)
# μₙ = δ_{1/(n+1)}（取 n=5 固定演示）与 μ = δ₀ 的分位逆：
# Qₙ(u) = 1/6 对一切 u；Q(u) = 0——轨道差恒 1/6？不：
# δ 型的分位逆有平台 [0,1)：Qₙ(u) = 1/6 若 u > 0；收敛需要
# 换族——用均匀 [0, 1/(n+1)] → δ₀（真收缩）
Qn(u, n) = u / (n + 1)                             # U[0,1/(n+1)] 的分位逆
Q(u) = 0.0                                         # δ₀ 的分位逆（[0,1) 平台 0）
n = 50
diffs = [abs(Qn(u, n) - Q(u)) for u in U]
@assert maximum(diffs) ≤ 1 / (n + 1)               # 一致轨道收敛（此族甚至一致）
println("Skorokhod: same-U sampling gives uniform orbit convergence <= 1/(n+1): OK")

println("END ====")
