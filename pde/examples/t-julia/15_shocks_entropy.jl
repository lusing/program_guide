# Ch15 守恒律：激波、Rankine-Hugoniot 与熵条件
#
# 对应书 §3.4.1：积分（弱）形式、特征线、激波与 RH 条件、熵条件、
# Riemann 问题初见。Burgers 方程 u_t + (u²/2)_x = 0 为主角。

using Printf

println("==== 15")

# ---- (a) RH 条件：激波速度 = 通量跳跃/状态跳跃 ----
# uL=1、uR=0 的 Riemann 数据：激波速度 s = (f(uL)-f(uR))/(uL-uR) = 1/2
f(u) = u^2 / 2
uL, uR = 1.0, 0.0
s_shock = (f(uL) - f(uR)) / (uL - uR)
@printf("(a) RH: shock speed = (%.1f-%.1f)/(1-0) = %.4f\n", f(uL), f(uR), s_shock)
@assert s_shock == 0.5 "RH 速度（Lean 通道有恒等式证明）"

# 精确激波解 u(x,t) = uL (x < st) / uR (x > st)，数值验证弱形式：
# ∮ (u dx − f dt) 沿绕激波的矩形回路 = 0
function weak_circulation(t0, t1, xL0, xR0)
    # 回路：(xL0,t0) → (xR0,t0) → (xR1,t1) → (xL1,t1) → close
    # 其中激波线 x = 0.5t 在内部。环量 ∮ u dx - f(u) dt：
    # 底边（dt=0）：∫u dx = uL·(s t0 − xL0) + uR·(xR0 − s t0)
    # 顶边同理（反向），侧边（dx=0）：-∫f dt
    s = 0.5
    bot = uL * (s * t0 - xL0) + uR * (xR0 - s * t0)
    top = -(uL * (s * t1 - xL0) + uR * (xR0 - s * t1))
    side = (f(uL) - f(uR)) * (t1 - t0)   # 左边 +f(uL)dt、右边 −f(uR)dt（逆时针）
    return bot + top + side
end
c = weak_circulation(0.3, 1.1, -2.0, 2.0)
@printf("    weak circulation around shock: %.2e (zero ⟺ RH holds)\n", c)
@assert abs(c) < 1e-12 "弱形式的环量守恒 ⟺ RH 速度正确"

# ---- (b) Godunov 方法数值：激波位置与 RH 对账 ----
function godunov(u0, T; N = 400, tend = T)
    h = 8.0 / N
    dt = 0.4 * h          # CFL
    x = [(i - N / 2) * h for i in 0:N-1]
    u = [u0(xi) for xi in x]
    nt = round(Int, tend / dt)
    dt = tend / nt
    for _ in 1:nt
        # Godunov 通量（凸标量、f' 递增）：ul > ur（激波段）取 max(f(ul),f(ur))，
        # ul ≤ ur（稀疏段）取 min——初版统一用 min 把激波通量算成 0，
        # 激波原地不动（数值位置 0.0 vs 0.5 当场暴露）
        flux = zeros(N + 1)
        for i in 0:N
            ul = u[mod1(i, N)]
            ur = u[mod1(i + 1, N)]
            flux[i+1] = ul > ur ? max(f(ul), f(ur)) : min(f(ul), f(ur))
        end
        for i in 1:N
            u[i] -= dt / h * (flux[i+1] - flux[i])
        end
    end
    return x, u
end
x, u_num = godunov(xi -> xi < 0 ? 1.0 : 0.0, 1.0)
# 激波应位于 x = 0.5（s=0.5, t=1）。周期域在 x=±4 有同一间断的周期像
# （副激波行至 4.5 ≡ −3.5），只在主窗口 [-2,2] 内搜索过渡
idx = findfirst(i -> -2 < x[i] < 2 && u_num[i] < 0.5, 1:length(u_num))
shock_x = x[idx]
@printf("(b) Godunov shock at t=1: numerical x ≈ %.4f  RH predicts 0.5\n", shock_x)
@assert abs(shock_x - 0.5) < 0.05 "数值激波位置与 RH 对账"

# ---- (c) 熵条件：激波必须"特征线进入"（uL > s > uR）----
u_char_L, u_char_R = uL, uR
@printf("(c) entropy: uL=%.1f > s=%.4f > uR=%.1f ⟹ admissible shock\n",
        u_char_L, s_shock, u_char_R)
@assert u_char_L > s_shock > u_char_R "Lax 熵条件 f'(uL) > s > f'(uR)"
# 反例：uL=0、uR=1（特征线发散）⟹ 稀疏波，不是激波
uL2, uR2 = 0.0, 1.0
s_fake = (f(uL2) - f(uR2)) / (uL2 - uR2)
@printf("    reversed data: f'(uL)=%.1f < s=%.2f < f'(uR)=%.1f ⟹ entropy VIOLATED ⟹ rarefaction\n",
        uL2, s_fake, uR2)
@assert !(uL2 > s_fake > uR2) "熵条件排除非物理解"

# ---- (d) 稀疏波：uL=0, uR=1 的连续自相似解 u = x/t 于 0<x<t ----
# 数值 Godunov 对照
x2, u2 = godunov(xi -> xi < 0 ? 0.0 : 1.0, 1.0)
err = 0.0
for (xi, ui) in zip(x2, u2)
    abs(xi) > 2 && continue          # 周期副激波（x≈−3.5）不在统计窗口
    exact = xi < 0 ? 0.0 : (xi > 1.0 ? 1.0 : xi)   # u = x/t, t=1
    global err = max(err, abs(ui - exact))
end
@printf("(d) rarefaction: max error of Godunov vs u=x/t at t=1: %.4f (smearing O(h))\n", err)
@assert err < 0.25 "稀疏波数值解 smeared 一两格"

println("END ====")
