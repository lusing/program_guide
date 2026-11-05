# Ch38 线性发展 V：半群理论（Hille-Yosida）
#
# 对应书 §7.4：压缩半群、无穷小生成元、Hille-Yosida 定理、应用
#（热半群/波群/传输半群的统一框架）。

using Printf
using LinearAlgebra

println("==== 38")

# ---- (a) 半群律与收缩：S(t) = e^{-tA}（A = diag 特征值 ≥ 0）----
# 数值：对角半群 S(t)S(s) = S(t+s) 与 ‖S(t)‖ ≤ 1
A_diag = [pi^2, 4pi^2, 9pi^2]
for (t, s) in [(0.3, 0.7), (1.5, 2.5)]
    prod = exp.(-t .* A_diag) .* exp.(-s .* A_diag)
    direct = exp.(-(t + s) .* A_diag)
    @printf("(a) semigroup law: max|S(t)S(s) − S(t+s)| = %.1e\n",
            maximum(abs.(prod .- direct)))
    @assert maximum(abs.(prod .- direct)) < 1e-15 "半群律逐位"
end
for t in [0.1, 1.0, 5.0]
    norm = maximum(exp.(-t .* A_diag))
    @printf("    ||S(%.1f)|| = %.6f ≤ 1 (contraction)\n", t, norm)
    @assert norm ≤ 1.0 + 1e-15 "压缩半群"
end

# ---- (b) 生成元：A = lim (S(h) − I)/h 的数值微分 ----
for lam in [pi^2]
    h = 1e-6
    gen = (exp(-lam * h) - 1) / h
    @printf("(b) generator: (S(h)-1)/h = %.6f  -λ = %.6f\n", gen, -lam)
    @assert abs(gen + lam) < 1e-4 "生成元恢复 -A"
end

# ---- (c) 耗散性：⟨Au,u⟩ ≤ 0（Hille-Yosida 的 dissipative 条件）----
for lam in A_diag
    @printf("(c) dissipative: λ = %.2f ⟹ ⟨Au,u⟩ = -λ||u||² ≤ 0\n", lam)
end
@assert all(A_diag .> 0) "正谱 ⟹ 耗散 ⟹ 压缩半群（Hille-Yosida 的正向）"

# ---- (d) 三大半群对照：热（压缩解析）、波（等距群）、传输（等距群）----
println("(d) three semigroups:")
println("    heat:  S(t) = e^{-tA}, ||S(t)|| = e^{-λ₁t} ≤ 1 (analytic, contractive)")
println("    wave:  S(t) = [cos tA^{1/2}, ...] (unitary group, ||S|| = 1 exactly)")
println("    transport: S(t)g = g(·-tb) (isometry group on L²)")
for t in [0.5, 2.0]
    @printf("    t=%.1f: heat norm = %.6f, wave norm = %.6f, transport norm = %.6f\n",
            t, exp(-pi^2 * t), 1.0, 1.0)
end
@assert exp(-pi^2 * 0.5) < 1.0 "热压缩；波/传输等距（群——可逆）"

# ---- (e) 波的半群形式：U = (u, u_t)，U_t = [[0,I],[A,0]]U 的群 ----
# 矩阵生成元的特征 ±i√λ（纯虚 ⟹ 等距群，无耗散）
Bgen = [0.0 1.0; -pi^2 0.0]
evs = eigvals(Bgen)
@printf("(e) wave generator eigenvalues: %+.4f, %+.4f (pure imaginary ⟹ group)\n",
        real(evs[1]), real(evs[2]))
@assert maximum(abs.(real.(evs))) < 1e-12 "谱在虚轴 ⟹ 等距群（Hille-Yosida: 群条件）"

println("END ====")
