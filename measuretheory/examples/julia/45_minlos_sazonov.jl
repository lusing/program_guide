println("==== 45 minlos_sazonov")
# 第 45 章：迹收敛与白噪声柱面。
# ① λₙ = 1/n² vs λₙ = 1 的部分和；② 柱面一致性（换基）；
# ③ 截断能量收敛；④ 临界例 1/n（HS ✓ S₁ ✗）。

using Random, LinearAlgebra, Statistics
Random.seed!(45)

# ① 特征值账
for n in (100, 1000, 10000)
    s_n2 = sum(1.0 / k^2 for k in 1:n)
    @assert s_n2 < pi^2 / 6 + 0.01               # 收敛（π²/6）
end
s_inf = sum(1.0 for _ in 1:1000)                  # λₙ ≡ 1 发散
@assert s_inf == 1000.0
println("eigenvalue account: sum 1/n^2 converges to pi^2/6, sum 1 diverges: OK")

# ② 柱面一致性：i.i.d. N(0,1) 在正交基变换后仍 i.i.d.
n = 50
Z = randn(n, 500)                                 # n 坐标 × 500 采样
Q = qr(randn(n, n)).Q                             # 随机正交阵
Zt = Q * Z                                        # 变换后
C_before = cov(Z, dims = 2)
C_after = cov(Zt, dims = 2)
@assert maximum(abs.(C_before - I)) < 0.25        # ~单位阵（采样噪声）
@assert maximum(abs.(C_after - I)) < 0.25         # 同样 ~单位阵（正交不变性）
println("cylindrical consistency: iid normal invariant under orthogonal change: OK")

# ③ 迹类 Gauss 的截断能量：‖X_n‖² → Tr A
for n_max in (100, 1000, 5000)
    energies = [sum((1.0 / k) * z^2 for (k, z) in enumerate(randn(n_max))) for _ in 1:200]
    m = mean(energies)
    @assert abs(m - sum(1.0 / k for k in 1:n_max)) < 0.35  # E‖X‖² = Tr A
end
println("trace-class energy: E||X_n||^2 = partial trace A: OK")

# ④ 临界例：λₙ = 1/n——S₂ ✓（Σλₙ² = π²/6）但 S₁ ✗（Σλₙ = ∞）
s2 = sum(1.0 / k^2 for k in 1:10^6)
s1_partial = sum(1.0 / k for k in 1:10^4)
@assert s2 < 2.0                                 # HS 收费可付
@assert s1_partial > 9.0                         # 迹收费无着（Harmonic 发散）
println("critical lambda=1/n: HS^2 sum converges, trace sum diverges (two-tier): OK"

)
println("END ====")
