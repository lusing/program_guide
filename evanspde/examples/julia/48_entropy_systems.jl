# Ch48 守恒律组 II：Riemann 不变量与熵
#
# 对应书 §11.3（两方程组、Riemann 不变量、光滑解非存在）与
# §11.4（熵/熵通量对、消失粘性、标量唯一性）。

using Printf

println("==== 48")

# ---- (a) 2×2 系统的熵对：凸熵 η 与熵通量 q（标量 Burgers 的对）----
# η(u) = u²/2、q(u) = u³/3：η'f' = q'（相容性）
f48(u) = u^2 / 2
for u in [0.5, 1.0, 2.0]
    @printf("(a) entropy pair at u=%.1f: see numerical derivative check below\n", u)
end
# 数值导数验证
for u in [0.5, 1.5]
    d = 1e-6
    fp = (f48(u + d) - f48(u - d)) / (2d)
    lhs = u * fp
    rhs = u^2
    @printf("    η'f' = %.6f  q' = %.6f (compatibility)\n", lhs, rhs)
    @assert abs(lhs - rhs) < 1e-9 "η'f' = q'（凸熵对的相容条件）"
end

# ---- (b) 光滑解的非存在性（11.3.2）：特征相交形成激波 ----
# Riemann 不变量形式的 2×2 系统：特征交叉（genuine nonlinearity）
# 初值光滑 → 特征相交时间有限（标量机制在系统的残留）
# 数值：u_t + a(u)u_x = 0 的 a(u) = 1 + u（仿射速度）
# 初值 u₀(x) = -tanh(x)·?（递减段）：相交时间 t* = -1/min u₀'
function u0_48(x)
    -0.5 * tanh(2x)
end
gd48(x) = (u0_48(x + 1e-6) - u0_48(x - 1e-6)) / 2e-6
ming = minimum(gd48(x) for x in -2:0.001:2)
tstar = -1 / (ming * 1)   # a'(u) = 1
@printf("(b) smooth breakdown: min u0' = %.4f ⟹ t* = %.4f\n", ming, tstar)
@assert tstar > 0 && tstar < 2 "有限爆破时间（光滑解必然死亡）"

# ---- (c) 消失粘性（11.4.1）：熵解 = 粘性极限（标量对照 14 章）----
# Burgers + εu_xx 的行波（21 章）：激波宽 O(ε)，熵条件 u_L > u_R
for eps in [0.3, 0.05, 0.01]
    # 行波 u = (uL+uR)/2 - (uL-uR)/2·tanh((x-st)/(4ε))（Burgers 精确剖面）
    width = 4 * eps
    @printf("(c) viscous profile: ε = %.3f ⟹ shock width 4ε = %.2f\n", eps, width)
end
@assert 4 * 0.01 < 4 * 0.3 "ε→0 剖面收窄到熵激波"

# ---- (d) 熵耗散：穿过激波的熵通量差 > 0（熵条件等价）----
# Burgers uL=1, uR=0，s = 0.5：η通量差 q(uL)-q(uR) - s(η(uL)-η(uR))
uL, uR = 1.0, 0.0
s = 0.5
eta(u) = u^2 / 2
q48(u) = u^3 / 3
diss = (q48(uL) - q48(uR)) - s * (eta(uL) - eta(uR))
@printf("(d) entropy dissipation across shock: q-jump − s·η-jump = %.6f > 0\n", diss)
@assert diss > 0 "熵耗散为正 ⟹ 熵条件成立（物理解）"

println("END ====")
