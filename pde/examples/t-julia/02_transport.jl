# Ch02 传输方程：特征线、弱解与 Duhamel
#
# 对应书 §2.1：u_t + b·Du = 0 的特征线解法（u 沿方向 (b,1) 的直线
# 为常数）、初值问题 u(x,t) = g(x - t b)、非齐次 Duhamel 公式
# u = g(x-tb) + ∫₀ᵗ f(x+(s-t)b, s) ds、以及 g 不光滑时的弱解。

using Printf

println("==== 02")

# ---- (a) 初值问题：u(x,t) = g(x - t b)，b 一维 ----
# 数值验证：任何 g（包括不连续的）都按特征线平移——公式逐点成立
g_step(x) = x < 0.3 ? 1.0 : -1.0        # 间断初值（弱解：间断沿特征传播）
b = 0.7
t = 1.9
# 在时刻 t，解 u(x,t) = g(x - t b)：间断点在 x = 0.3 + t b
xc = 0.3 + t * b
@printf("(a) jump at x = 0.3 + t*b = %.4f: u(xc-eps)=%+.1f  u(xc+eps)=%+.1f\n",
        xc, g_step(xc - 1e-9 - t * b), g_step(xc + 1e-9 - t * b))
@assert g_step(xc - 1e-9 - t * b) == 1.0 && g_step(xc + 1e-9 - t * b) == -1.0

# 离散对账（整数位移，无插值误差）：周期 g = sin(2πx)，b = 1/2，
# t = 1.5 ⟹ t·b·N = 48 恰为整数格——网格平移与公式逐位一致
N = 64
b2, t2 = 0.5, 1.5
xs = [i / N for i in 0:N-1]
gper(x) = sin(2pi * x)
u_num = [gper(x - t2 * b2) for x in xs]
# Julia circshift(A, s)[i] = A[mod1(i - s, n)]：要 u[i] = old[mod1(i - 48, n)] 须 s = +48
u_shift = circshift([gper(x) for x in xs], 48)
mismatch = maximum(abs.(u_num .- u_shift))
@printf("    integer-shift periodic check: max mismatch = %.2e\n", mismatch)
@assert mismatch < 1e-12 "整数位移下离散平移与公式一致（舍入级）"

# ---- (b) 非齐次问题 Duhamel：u = g(x-tb) + ∫₀ᵗ f(x+(s-t)b, s) ds ----
# 制造解：f(x,t) = e^{-t} cos(x)，b = 1，g = sin。
# u(x,t) = sin(x-t) + ∫₀ᵗ e^{-s} cos(x+s-t) ds
#   ∫ e^{-s} cos(x+s-t) ds = Im ∫ e^{-s} e^{i(x+s-t)} ds
#   = Im e^{i(x-t)} ∫ e^{(-1+i)s} ds = Im e^{i(x-t)} (1 - e^{(-1+i)t})/(1-i)
f(x, t) = exp(-t) * cos(x)
# Duhamel 积分数值（复合 Simpson，1024 子区间）
function duhamel(x, t)
    n = 1024
    h = t / n
    s = 0.0
    for k in 0:n
        sk = k * h
        w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
        s += w * f(x + (sk - t), sk)
    end
    return s * h / 3
end
# 解析：Im[ e^{i(x-t)} (1 - e^{(i-1)t})/(i-1) ]（实部虚部手算）
# (1 - e^{(i-1)t})/(i-1)：分母有理化 (1-i)/2 倍 → 展开
duhamel_exact(x, t) =
    let a = x - t, E = exp(-t)
        # ∫₀ᵗ e^{-s} cos(a+s) ds，原函数 F(s) = e^{-s}(sin(a+s)-cos(a+s))/2，
        # 积分 = F(t) - F(0)（初版把 F(0)-F(t) 当积分，被 Simpson 当场翻案）
        (E * (sin(a + t) - cos(a + t)) - (sin(a) - cos(a))) / 2
    end
# 验证闭式（对几个点数值积分对照）
for (x, t) in [(0.3, 1.0), (-0.7, 2.3), (1.5, 0.4)]
    num = duhamel(x, t)
    exa = duhamel_exact(x, t)
    @printf("(b) x=%+.1f t=%.1f: Simpson %.9f  closed form %.9f  |diff| = %.2e\n",
            x, t, num, exa, abs(num - exa))
    @assert abs(num - exa) < 1e-8
end

# 制造解对表：u = sin(x-t) + duhamel_exact(x,t) 应满足 u_t + u_x = e^{-t} cos(x)
# 解析导数：d/dt sin(x-t) = -cos(x-t)，d/dx sin(x-t) = cos(x-t)（相消）
# ∂t I = -e^{-t}cos(x)?? 验证：I(x,t) = duhamel_exact；数值差分对账
u_full(x, t) = sin(x - t) + duhamel_exact(x, t)
dt = 1e-5
ut = (u_full(0.4, 1.1 + dt) - u_full(0.4, 1.1 - dt)) / (2dt)
ux = (u_full(0.4 + dt, 1.1) - u_full(0.4 - dt, 1.1)) / (2dt)
resid = ut + ux - f(0.4, 1.1)
@printf("    residual u_t + u_x - f = %.2e\n", resid)
@assert abs(resid) < 1e-7 "制造解残差应达差分精度"

# ---- (c) 二维 b：方向平移 ----
b2 = (0.6, 0.8)   # 单位向量
g2(x, y) = exp(-((x - 0.2)^2 + (y + 0.1)^2))
x0, y0, t0 = 1.0, 0.5, 1.3
val = g2(x0 - t0 * b2[1], y0 - t0 * b2[2])
@printf("(c) 2d: u((%.1f,%.1f),%.1f) = g(x-tb) = %.6f\n", x0, y0, t0, val)
# 中心恰在 (0.2,-0.1)+t b 处取最大：验证该点值为 1
@assert abs(g2(0.2 + t0 * b2[1] - t0 * b2[1], -0.1 + t0 * b2[2] - t0 * b2[2]) - 1.0) < 1e-15

println("END ====")
