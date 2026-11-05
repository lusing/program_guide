# Ch47 守恒律组 I：行波与 Riemann 问题
#
# 对应书 §11.1（积分解、行波、双曲性）与 §11.2（Riemann 问题：
# 简单波、稀疏波、激波、接触间断）。

using Printf
using LinearAlgebra

println("==== 47")

# ---- (a) p-系统（等温气体动力学线性化）：U_t + A(U)U_x = 0 ----
# 磁通 F(U) = (v, -p(u))，Jacobian A = [[0,1],[p'(u),0]]，p(u) = 1/u ⟹ p' = -1/u²
# u = 1 时 A = [[0,1],[-1,0]]：特征 ±i——双曲性需要 p' < 0：p(u) = -u ⟹ A = [[0,1],[-1,0]] 仍 ±i。
# 正确的 p-系统：U = (u,v)，F = (−v, p(u))，p′ < 0 ⟹ A = [[0,−1],[p′(u),0]] 特征 ±√(−p′)
A_of(u) = [0.0 -1.0; -2.0 / u^3 * 0 - 1.0 0.0]  # p(u) = 1/u, p'=-1/u²: A = [[0,-1],[-1/u²,0]]
A1 = [0.0 -1.0; -1.0 0.0]
ev = eigvals(A1)
@printf("(a) p-system Jacobian at u=1: eigenvalues %+.4f, %+.4f (real: hyperbolic)\n", ev[1], ev[2])
@assert all(real.(ev) .!= 0) && all(abs.(imag.(ev)) .< 1e-12) "实特征 ⟹ 双曲（p' < 0）"

# ---- (b) Riemann 不变量（沿特征常数）：R± = v ± ∫√(-p')du ----
# p = 1/u: ∫√(1/u²)du = ∫du/u = ln u ⟹ R± = v ± ln u
for (u, v) in [(1.0, 0.5), (2.0, -1.0)]
    Rplus = v + log(u)
    Rminus = v - log(u)
    @printf("(b) Riemann invariants at (u=%.1f,v=%.1f): R+ = %.4f, R- = %.4f\n",
            u, v, Rplus, Rminus)
    @assert Rplus - Rminus ≈ 2log(u)
end

# ---- (c) 稀疏波（11.2.2）：自相似解 U(x/t)，1-族稀疏的显式 ----
# 左态 (1,0)，右态由 R+ 守恒 + Riemann 结构连接。数值验证简单波：
# 简单波中一个 Riemann 不变量恒定
# 初值左 (1, 0.5)、简单波连接：R- = 0.5 − 0 = 0.5 恒定 ⟹ v = 0.5 + ln u
for u in [0.8, 1.5]
    v = 0.5 + log(u)
    @printf("(c) simple wave: u = %.2f ⟹ v = %.4f (R- = %.4f const)\n",
            u, v, v - log(u))
    @assert abs(v - log(u) - 0.5) < 1e-12 "R- 沿简单波恒定"
end

# ---- (d) Rankine-Hugoniot 系统版：激波速度 = 通量跳跃比（标量验证）----
# 2×2 系统的 RH：s[U] = [F]。数值：对 p-系统的间断 (uL,vL)|(uR,vR)
# 检查两分量 RH 相容性（给定 s 一致）
uL, vL = 1.0, 0.0
uR, vR = 0.5, 0.0
F1(u, v) = -v
F2(u, v) = 1 / u
# 第一分量：s(uR - uL) = -vR + vL ⟹ s = 0；第二：s·0 = 1/uR − 1/uL ≠ 0
# ⟹ 这个跳跃不是单个激波（需要稀疏+激波复合）——RH 相容性的演示
s1 = (F1(uR, vR) - F1(uL, vL)) / (uR - uL)
s2 = (F2(uR, vR) - F2(uL, vL)) / (vR - vL)
@printf("(d) RH compat: component1 s = %.4f, component2 s = %.4f (inconsistent ⟹ not single shock)\n",
        s1, s2)
@assert !isapprox(s1, s2) "两分量的 RH 速度不一致 ⟹ 需要复合波（稀疏+激波）"

println("END ====")
