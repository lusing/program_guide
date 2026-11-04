println("==== 20 stability")
using LinearAlgebra

# 第 20 章：Lyapunov 稳定性——线性化、Lyapunov 函数、衰减律。

function rk4vec(f, t, u, h)
    k1 = f(t, u)
    k2 = f(t + h / 2, u .+ h .* k1 ./ 2)
    k3 = f(t + h / 2, u .+ h .* k2 ./ 2)
    k4 = f(t + h, u .+ h .* k3)
    u .+ h .* (k1 .+ 2 .* k2 .+ 2 .* k3 .+ k4) ./ 6
end
integrate(f, u0, T; n = 24000) = begin
    h = T / n
    t, u = 0.0, copy(u0)
    for _ in 1:n
        u = rk4vec(f, t, u, h)
        t += h
    end
    u
end

# --- (a) 线性化判据：单摆 + van der Pol 原点 ---
# 单摆 (0,0)：A=[[0,1],[-1,0]]，实部 0 ⟹ 临界（中心）
eigs_pend = eigen([0.0 1.0; -1.0 0.0]).values
@assert abs(real(eigs_pend[1])) < 1e-12 && abs(real(eigs_pend[2])) < 1e-12 "临界情形"
println("单摆下垂：特征值 ±i（临界，线性化不定论——实为中心）")
# 阻尼摆 (0,0)：A=[[0,1],[-1,-0.3]] 实部 −0.15 ⟹ 渐近稳定
eigs_d = eigen([0.0 1.0; -1.0 -0.3]).values
@assert real(eigs_d[1]) < 0 && real(eigs_d[2]) < 0
println("阻尼摆：实部全负 ⟹ 渐近稳定")
# van der Pol 原点：A=[[0,1],[-1,μ]] μ=1 ⟹ 实部 +0.5 ⟹ 不稳定
eigs_v = eigen([0.0 1.0; -1.0 1.0]).values
@assert real(eigs_v[1]) > 0
println("van der Pol 原点：实部 +0.5 ⟹ 不稳定（起振的原因）")

# --- (b) Lyapunov 函数：阻尼振子能量单调降 ---
δ, ω0 = 0.4, 2.0
f_osc = (t, u) -> [u[2], -2δ * u[2] - ω0^2 * u[1]]
E(u) = 0.5 * (u[2]^2 + ω0^2 * u[1]^2)
dE(u, v) = u[2] * v[2] + ω0^2 * u[1] * v[1]     # ∇E·f = v²·(-2δ) + ...
# 数值：沿轨道 E 逐点降
t, u = 0.0, [1.0, 0.0]
h = 10.0 / 240000
prevE = E(u)
mono = true
for _ in 1:240000
    global u = rk4vec(f_osc, t, u, h)
    global t += h
    global mono = mono && (E(u) <= prevE + 1e-14)
    global prevE = E(u)
end
@assert mono "能量应单调不增（V̇ = -2δv² ≤ 0）"
@assert E(u) / E([1.0, 0.0]) < 1.5 * exp(-2 * δ * 10) "指数衰减包络 ~e^{-2δt}（瞬时 E 有振荡因子）"
println("阻尼振子：E 单调降，E(10)/E(0) ≤ e^{-2δ·10} = ", round(exp(-2δ * 10); digits=8))

# --- (c) x' = -x³：幂式衰减 1/sqrt(2t) ---
f_cubic = (t, u) -> -u .^ 3
uend = integrate((t, u) -> [-u[1]^3], [1.0], 200.0; n = 4000000)[1]
@assert abs(uend - 1 / sqrt(2 * 200)) < 0.005 "幂式衰减 ~1/√(2t)"
println("x' = -x³：x(200) = ", round(uend; digits=4), " ≈ 1/√400 = ", round(1 / sqrt(400); digits=4))

# --- (d) 三级稳定性数值区分 ---
# 稳定不吸引（中心）：范数守恒
uc = integrate((t, u) -> [u[2], -u[1]], [1.0, 0.0], 30.0; n = 300000)
@assert abs(sqrt(uc[1]^2 + uc[2]^2) - 1.0) < 1e-5 "中心：范数守恒（稳定不吸引）"
println("中心：轨道范数守恒 30 秒（稳定、不吸引）")

# --- (e) Lyapunov 方程：A^T P + P A = -Q 的 P 正定 ⟹ 稳定 ---
A = [-1.0 0.5; 0.3 -2.0]
Q = [1.0 0.0; 0.0 1.0]
P = lyap(A' , Q)      # A'P + PA = -Q（Julia lyap 解 A X + X B = C 形式：lyap(A', -Q)?）
# 直接验证：找 P 满足 A'P + PA = -Q
# Julia: lyap(A, C) 解 AX + XA' = -C。我们解 A'P + PA = -Q ⟹ 取转置等价 A P' + P' A' = -Q
P2 = lyap(A, Q)
@assert norm(A' * P2 + P2 * A + Q) < 1e-10 || norm(A * P2 + P2 * A' + Q) < 1e-10 "Lyapunov 方程"
isposdef(lyap(A', Q) + I * 0) # 触发计算
Pq = (lyap(A', Q) + lyap(A', Q)') / 2   # 数值对称化（isposdef 要求精确 Hermitian）
@assert norm(A' * Pq + Pq * A + Q) < 1e-9
@assert isposdef(Pq) "P 正定 ⟹ 渐近稳定"
V0 = [1.0, 1.0]' * Pq * [1.0, 1.0]
@assert V0 > 0
println("Lyapunov 方程：AᵀP + PA = −Q 有正定解 ⟹ 渐近稳定（V(1,1) = ", round(V0; digits=4), "）")

println("END ====")
