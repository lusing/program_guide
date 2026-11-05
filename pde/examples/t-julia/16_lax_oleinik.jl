# Ch16 守恒律 II：Lax-Oleinik 公式、Riemann 问题与长时行为
#
# 对应书 §3.4.2-3.4.5：Lax-Oleinik 显式公式（u = Hopf-Lax 的导数）、
# 弱解唯一性、Riemann 问题全解、长时 N 波行为。

using Printf

println("==== 16")

# ---- (a) Lax-Oleinik：u(x,t) = (x − y*)/t，y* 最小化 (y−x)²/2t + G(y) ----
# 坑账：被最小化的是**势 G(y) = ∫_{-∞}^y g**（Hopf-Lax 作用在势上），
# 不是 g 本身——初版直接用 g，与 Godunov 差到 0.97，当场暴露。
using SpecialFunctions
g16(y) = 0.5 * exp(-(y + 0.5)^2 * 6)   # 光滑包
G16(y) = 0.5 * (sqrt(pi) / (2 * sqrt(6))) * (1 + erf(sqrt(6) * (y + 0.5)))  # 势（erf 闭式）
function lax_oleinik(x, t; n = 400001)
    lo, hi = x - 4 * sqrt(t) - 2, x + 4 * sqrt(t) + 2
    best = Inf; by = lo
    for k in 0:n-1
        y = lo + (hi - lo) * k / n
        v = (y - x)^2 / (2t) + G16(y)
        if v < best
            best = v; by = y
        end
    end
    return (x - by) / t
end
# 与数值守恒律解（Godunov 细网格）对照
function godunov16(u0, T; N = 1600)
    h = 10.0 / N
    dt = 0.4 * h
    x = [(i - N / 2) * h for i in 0:N-1]
    u = [u0(xi) for xi in x]
    nt = round(Int, T / dt)
    for _ in 1:nt
        flux = zeros(N + 1)
        for i in 0:N
            ul = u[mod1(i, N)]
            ur = u[mod1(i + 1, N)]
            flux[i+1] = ul > ur ? max(ul^2 / 2, ur^2 / 2) : min(ul^2 / 2, ur^2 / 2)
        end
        for i in 1:N
            u[i] -= dt / h * (flux[i+1] - flux[i])
        end
    end
    return x, u
end
xg, ug = godunov16(xi -> 0.5 * exp(-(xi + 0.5)^2 * 6), 0.8)
err = 0.0
for j in 1:length(xg)
    abs(xg[j]) > 3 && continue
    global err = max(err, abs(ug[j] - lax_oleinik(xg[j], 0.8)))
end
@printf("(a) Lax-Oleinik vs Godunov at t=0.8: max err = %.4f (O(h) smearing)\n", err)
@assert err < 0.2 "Lax-Oleinik 显式公式与数值守恒律解一致"

# ---- (b) Riemann 问题全解核对：三种情形 ----
# (i) uL > uR：激波 s = (uL+uR)/2；(ii) uL < uR：稀疏 u = x/t 截断
function riemann_exact(x, t, uL, uR)
    if uL > uR
        s = (uL + uR) / 2
        return x < s * t ? uL : uR
    else
        # 稀疏：u = x/t 于 uL·t < x < uR·t
        x / t < uL ? uL : (x / t > uR ? uR : x / t)
    end
end
for (uL, uR, tag) in [(1.0, 0.0, "shock"), (0.0, 1.0, "rarefaction"), (0.5, 0.5, "constant")]
    @printf("(b) Riemann (%.1f, %.1f) [%s]: u(-0.6,1)=%.2f u(0,1)=%.2f u(0.6,1)=%.2f\n",
            uL, uR, tag, riemann_exact(-0.6, 1.0, uL, uR),
            riemann_exact(0.0, 1.0, uL, uR), riemann_exact(0.6, 1.0, uL, uR))
end
@assert riemann_exact(-0.6, 1.0, 1.0, 0.0) == 1.0 && riemann_exact(0.6, 1.0, 1.0, 0.0) == 0.0
@assert riemann_exact(0.5, 1.0, 0.0, 1.0) == 0.5 "稀疏波内部 u = x/t"

# ---- (c) 长时行为：N 波（书 §3.4.5 定理：u → N 波形状）----
# 初值 g 有正负部分 → 解收敛到三角形 N 波：中心速度不动、宽度 ~ √t
# 简化数值：单正包 → 质量守恒、支撑增长
gN(y) = abs(y) < 0.5 ? 0.7 * (1 - 2abs(y)) : 0.0   # 帐篷（质量 0.35）
mass = sum(gN(y) for y in -5:0.001:5) * 0.001
@printf("(c) initial mass = %.6f\n", mass)
# t 大时解是"三角 N 波"：前激波后激波夹住稀疏内部
# 前激波位置（质量守恒的 Rankine-Hugoniot 全局匹配）：
# N 波解：u = (x+√(2M t))/t 于 [−√(2Mt), √(2Mt)]（M = 0.35）
M = mass
for t in [4.0, 16.0]
    edge = sqrt(2 * M * t)
    @printf("    t=%.0f: N-wave support edges ≈ ±%.4f (= sqrt(2Mt))\n", t, edge)
    # 验证边缘处 Lax-Oleinik 给 ~0
    ue = lax_oleinik(edge + 0.01, t, n = 100001)
    @printf("      u at edge+0.01: %.4f (approaching 0)\n", ue)
    @assert abs(ue) < 0.12
end

println("END ====")
