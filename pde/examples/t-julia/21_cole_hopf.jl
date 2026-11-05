# Ch21 解的表示 V：非线性 → 线性（Cole-Hopf、位势、hodograph）
#
# 对应书 §4.4：Cole-Hopf 变换把 Burgers 化为热方程、位势函数法、
# hodograph/Legendre 变换。

using Printf

println("==== 21")

# ---- (a) Cole-Hopf 数值对账：u = -2ν(ln φ)_x，φ 解热方程 ⟹ u 解粘性 Burgers ----
# 制造解：取 φ = 1 + e^{-(x-t/2)²/4ν·?}… 更直接：取 φ = 1 + 0.5e^{-(x-0.3)²/4ν - t}
# 满足 φ_t = νφ_xx？检查：e^{-(x-a)²/(4ν) - t}：φ_t 分量 = -e^{-...}；
# νφ_xx 分量：ν·d²/dx²[0.5e^{-(x-a)²/4ν}]e^{-t} = 0.5e^{-t}·(-(x-a)²/(8ν²)·?...
# 干净做法：Gauss 核族 G(x-a, t)：φ = 1 + 0.5·G(x-a, t+1)（热核平移）
# 则 φ_t = νφ_xx 精确。u = -2ν φ_x/φ。
nu = 0.5
Gk(x, t) = (4pi * nu * t)^(-0.5) * exp(-x^2 / (4nu * t))
phi(x, t) = 1 + 0.5 * Gk(x - 0.3, t + 1)
# φ_x 解析闭式（热核导数）：G'(y,t) = G·(−y/(2νt))——差分套差分噪声大
phix(x, t) = 0.5 * Gk(x - 0.3, t + 1) * (-(x - 0.3) / (2nu * (t + 1)))
u_b(x, t) = -2nu * phix(x, t) / phi(x, t)
# 验证 u_t + u u_x = ν u_xx（数值差分）
for (x, t) in [(0.0, 0.5), (0.5, 1.0)]
    d = 2e-4
    ut = (u_b(x, t + d) - u_b(x, t - d)) / (2d)
    ux = (u_b(x + d, t) - u_b(x - d, t)) / (2d)
    uxx = (u_b(x + d, t) - 2u_b(x, t) + u_b(x - d, t)) / d^2
    r = ut + u_b(x, t) * ux - nu * uxx
    @printf("(a) Cole-Hopf at (%.1f,%.1f): resid = %.2e\n", x, t, r)
    @assert abs(r) < 2e-4 "变换后的 u 满足粘性 Burgers"
end

# ---- (b) 无粘极限：ν→0 时解趋于激波解（熵解）----
# 初值 uL|uR = 1|0 的粘性激波：u = 1/(1 + e^{(x - t/2)/(2ν)})（行波）
# 15 章 RH 速度 1/2
function viscous_shock(x, t, nu)
    1 / (1 + exp((x - 0.5 * t) / (2nu)))
end
for nu2 in [0.4, 0.1, 0.02]
    mid = viscous_shock(0.5, 1.0, nu2)
    @printf("(b) viscous shock profile at x=0.5 (t=1, nu=%.2f): u = %.4f -> 1/2 (kink sharpens)\n",
            nu2, mid)
end
@assert abs(viscous_shock(0.5, 1.0, 0.02) - 0.5) < 0.02 "剖面中心恒 1/2，宽度 → 0"
# 行波满足 ODE：验证 u_t + u u_x = νu_xx（行波自代入）
for (x, t, nu3) in [(0.3, 0.7, 0.1), (1.1, 0.2, 0.3)]
    d = 1e-5
    vs(x, t) = viscous_shock(x, t, nu3)
    ut = (vs(x, t + d) - vs(x, t - d)) / (2d)
    ux = (vs(x + d, t) - vs(x - d, t)) / (2d)
    uxx = (vs(x + d, t) - 2vs(x, t) + vs(x - d, t)) / d^2
    r = ut + vs(x, t) * ux - nu3 * uxx
    @printf("    traveling wave resid at (%.1f,%.1f,nu=%.1f): %.2e\n", x, t, nu3, r)
    @assert abs(r) < 1e-6 "行波是粘性 Burgers 解"
end

# ---- (c) 位势函数法（§4.4.2）：守恒律 ⟹ 势的 HJ ----
# u = w_x 满足 u_t + (u²/2)_x = 0 ⟺ w_t + (w_x)²/2 = 0（13 章）
# 数值：用 13 章 Hopf-Lax 的 w，差分求 u，验证守恒律
G16(y) = 0.5 * (sqrt(pi) / (2 * sqrt(6))) * (1 .+ erf.(sqrt(6) .* (y .+ 0.5)))
using SpecialFunctions
Gpot(y) = 0.5 * (sqrt(pi) / (2 * sqrt(6))) * (1 + erf(sqrt(6) * (y + 0.5)))
function w_hl(x, t; n = 100001)
    lo, hi = x - 4 * sqrt(t) - 2, x + 4 * sqrt(t) + 2
    best = Inf
    for k in 0:n-1
        y = lo + (hi - lo) * k / n
        best = min(best, (y - x)^2 / (2t) + Gpot(y))
    end
    return best
end
for (x, t) in [(0.2, 0.8), (1.0, 1.5)]
    d = 1e-3
    ux = (w_hl(x + d, t) - w_hl(x - d, t)) / (2d)
    ut = (w_hl(x, t + d) - w_hl(x, t - d)) / (2d)
    @printf("(c) potential form at (%.1f,%.1f): w_t + w_x²/2 = %.4f\n", x, t, ut + ux^2 / 2)
    @assert abs(ut + ux^2 / 2) < 0.02 "势的 HJ 形式（差分精度）"
end

println("END ====")
