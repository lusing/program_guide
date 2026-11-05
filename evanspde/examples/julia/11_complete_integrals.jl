# Ch11 非线性一阶 I：完全积分与包络
#
# 对应书 §3.1：完全积分（complete integral）概念、从包络造新解
# （envelope）、eikonal 方程 |Du| = 1 的距离函数解族与包络。

using Printf

println("==== 11")

# ---- (a) eikonal |u_x| = 1 的完全积分：u = ±(x - a)（a 参数）----
# 单参数族 u_a(x) = |x - a| 的每一段都是解（除角点）
u_a(x, a) = abs(x - a)
for (x, a) in [(0.3, 1.0), (2.5, 1.0)]
    d = 1e-6
    du = (u_a(x + d, a) - u_a(x - d, a)) / (2d)
    @printf("(a) eikonal |u'|: at x=%.1f (a=1.0): |u'| = %.4f\n", x, abs(du))
    @assert abs(abs(du) - 1) < 1e-4 "x ≠ a 处 |u'| = 1"
end

# ---- (b) 包络：u(x) = min_a u_a(x) 是新解（下包络）----
# min_a |x-a| = 0 在 a=x 取到——退化。改用两参数完全积分演示包络：
# eikonal 的完全积分 u = (x-a)/1 + b 的下包络 min over b...
# 经典演示：u_a(x) = a·x − a²/2（Hamiltonian H(p)=p²/2 的 Lagrange 完全积分）。
# 族关于 a 是凹的（−a²/2 主导）：**下包络**（min）在区间端点退化取 −6，
# 切包络是**上包络** max_a —— 在切点 a = x 处（坑账：包络方向要看凹凸性）
u_envelope(x) = maximum(a -> a * x - a^2 / 2, range(-3, 3, length = 1201))
# 解析包络：max_a (ax - a²/2) 在 a = x 取到 = x²/2
for x in [0.5, 1.2, -0.8]
    num = u_envelope(x)
    exa = x^2 / 2
    d = 1e-5
    du_env = (u_envelope(x + d) - u_envelope(x - d)) / (2d)
    @printf("(b) envelope at x=%+.2f: min_a u_a = %.8f  x^2/2 = %.8f  u'=%.4f (=x)\n",
            x, num, exa, du_env)
    @assert abs(num - exa) < 1e-6 "包络闭式 x²/2"
    @assert abs(du_env - x) < 1e-3 "包络的导数 = 切点处的 a = x"
end
# 包络是 HJ 方程 u + H(∇u)... 的解：验证 u = x²/2 满足 u + ...
# 这里 u 满足 u = x·u_x/... 即 2u = x·u_x（Euler 齐次性）
for x in [0.5, 1.2]
    @assert abs(2 * (x^2 / 2) - x * x) < 1e-15 "包络满足 2u = x u_x（Legendre 对偶）"
end

# ---- (c) 特征线相交 → 解的梯度爆破（§3.2 的前奏）----
# u_t + u u_x = 0（Burgers）：解 u = g(x - u t)，特征线 x = ξ + g(ξ)t
g(x) = exp(-(x + 1)^2 * 4)          # 右高斯包：左侧陡（g' > 0 侧）
# 特征线相交条件：1 + g'(ξ)t = 0 首次在 t* = -1/min g'(ξ)
gd(ξ) = -8(ξ + 1) * exp(-(ξ + 1)^2 * 4)
# min g' 数值扫描
ming = minimum(gd, range(-3, 1, length = 4001))
tstar = -1 / ming
@printf("(c) Burgers gradient catastrophe: t* = -1/min g' = %.6f\n", tstar)
# 数值验证：隐式解 u(ξ + g(ξ)t) = g(ξ) 的 Jacobian 在 t* 处为零
function jac(t)
    # x(ξ) = ξ + g(ξ)t 的导数 1 + g'(ξ)t 的最小值
    minimum(ξ -> 1 + gd(ξ) * t, range(-3, 1, length = 4001))
end
for t in [0.0, 0.5 * tstar, tstar, 1.5 * tstar]
    @printf("    t=%.4f: min Jacobian = %+.6f %s\n", t, jac(t),
            t < tstar ? "(>0 invertible)" : t == tstar ? "(=0 catastrophe)" : "(<0 crossed)")
end
@assert jac(0.5 * tstar) > 0 && jac(tstar) < 1e-3 && jac(1.5 * tstar) < 0
# 理论：g' = -8s·e^{-4s²}（s = ξ+1）最小在 s = 1/(2√2)，
# g'min = -2√2·e^{-1/2} ⟹ t* = e^{1/2}/(2√2) = √(e/8)（初版笔误 √e/4 被数值翻案）
@assert abs(tstar - sqrt(exp(1) / 8)) < 1e-4 "理论值 t* = √(e/8)"

println("END ====")
