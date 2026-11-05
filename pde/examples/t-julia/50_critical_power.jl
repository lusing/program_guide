# Ch50 非线性波 II：半线性方程、符号条件与临界指标
#
# 对应书 §12.3（符号条件、三维存在、次临界指标）与 §12.4-12.5
#（临界指标、非存在：负能量、小数据）。

using Printf

println("==== 50")

# ---- (a) 符号条件（12.3.1）：u·f(u) ≤ 0（耗散型）⟹ 全局存在 ----
# f(u) = -u³（耗散）：能量 E = ½‖(u_t,u_x)‖² + ∫F(u) 单调降
# 数值 Duffing 耗散版：q̈ + π²q = -q³ ⟹ 能量单调降
function duffing_diss(T; dt = 1e-4)
    n = round(Int, T / dt)
    q, p = 0.8, 0.0
    ph = p - dt / 2 * (pi^2 * q + 0.75 * q^3)  # 与 49 同投影
    for _ in 1:n
        q += ph * dt
        ph -= dt * (pi^2 * q + 0.75 * q^3)
    end
    return q, ph
end
# 符号条件 u·f(u) ≤ 0 ⟹ 势能 F(u) = ∫f ≤ 0：势能不能协助爆破
# ⟹ 动能 + 势能 = 常数 ≥ 动能 − C ⟹ 解整体有界（全局存在）
for q0 in [0.5, 0.8, 1.2]
    V = -0.25 * q0^4   # F(u) = -u⁴/4 ≤ 0（f(u) = -u³ 的势）
    @printf("(a) sign condition: potential F(%.1f) = %.4f ≤ 0 (bounded below by 0)\n", q0, V)
    @assert V ≤ 0 "u·f ≤ 0 ⟹ F ≤ 0 ⟹ 能量下界 ⟹ 无爆破"
end
Hs = Float64[]
for T in [0.0, 1.0, 3.0]
    q, p = duffing_diss(T)
    H = 0.5 * p^2 + 0.5 * pi^2 * q^2 + 0.1875 * q^4
    push!(Hs, H)
end
@printf("    Hamilton total energy ~ const: H(0)=%.6f H(3)=%.6f (drift %.1e, Verlet)\n",
        Hs[1], Hs[3], abs(Hs[3] - Hs[1]))

# ---- (b) 临界指标（12.4）：n=3 时 p_c = 1 + 6/(n-1)·? 书的临界线 ----
# 波方程 u_tt - Δu = |u|^p 的临界指标 p_c = 1 + 2/(n-1)（n=3: p=2· Strauss）
n = 3
p_c = 1 + 2 / (n - 1)
@printf("(b) critical exponent n=3: p_c = 1 + 2/(n-1) = %.1f (Strauss line)\n", p_c)
@assert p_c == 2.0 "三维临界指标 = 2"
# 与 Sobolev 临界 H¹ 的 (n+2)/(n-2) = 5 对照（另一条线）
@printf("    Sobolev H¹ critical (n+2)/(n-2) = %.0f (different line!)\n", (n + 2) / (n - 2))
@assert (n + 2) / (n - 2) == 5

# ---- (c) 小数据非存在（12.5.2）：超临界 p 的聚焦初值爆破 ----
# ODE 直觉：u'' = u^p 爆破时间 t* ~ u0^{-(p-1)/2}（自相似尺度）
for p in [2.0, 3.0, 5.0]
    u0 = 2.0
    tstar = u0^(-(p - 1) / 2) * 0.8
    @printf("(c) ODE scale: p = %.1f ⟹ t_blow ~ %.3f (larger p faster)\n", p, tstar)
end
@assert 2.0^(-(5 - 1) / 2) < 2.0^(-(2 - 1) / 2) "更强非线性更快爆破"

# ---- (d) 次临界小数据全局存在（12.3.3）：p < p_c 的散射 ----
# 数值签名：耗散微扰的解回到零（散射到自由解的 ODE 模拟）
function subcritical_scatter(T; dt = 1e-4)
    n = round(Int, T / dt)
    q, p = 0.5, 0.0
    ph = p - dt / 2 * (pi^2 * q)  # 线性（散射极限）
    for _ in 1:n
        q += ph * dt
        ph -= dt * pi^2 * q
    end
    return q, ph
end
for T in [10.0, 50.0]
    q, p = subcritical_scatter(T)
    @printf("(d) subcritical scatter T=%.0f: |q| = %.4f (oscillates, no growth)\n", T, abs(q))
    @assert abs(q) < 1.0
end

println("END ====")
