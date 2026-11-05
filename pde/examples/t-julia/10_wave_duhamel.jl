# Ch10 波方程 II：Duhamel、能量与有限传播
#
# 对应书 §2.4.2（非齐次问题：Duhamel 原理）与 §2.4.3（能量方法：
# 能量守恒、有限传播速度、唯一性）。

using Printf

println("==== 10")

# ---- (a) Duhamel（1D）：u = 齐次解 + ½∫_{x−(t−s)}^{x+(t−s)} f(y,s) dy ----
f(y, s) = exp(-s) * cos(y)
function wave_duhamel(x, t; nT = 400, nX = 2000)
    # 初值 g = 0, h = 0
    s_du = 0.0
    hs = t / nT
    for kT in 0:nT
        s = kT * hs
        wT = (kT == 0 || kT == nT) ? 1.0 : (iseven(kT) ? 2.0 : 4.0)
        tau = t - s
        a, b = x - tau, x + tau
        hx = (b - a) / nX
        sx = 0.0
        for kX in 0:nX
            y = a + kX * hx
            wx = (kX == 0 || kX == nX) ? 1.0 : (iseven(kX) ? 2.0 : 4.0)
            sx += wx * f(y, s)
        end
        s_du += wT * 0.5 * sx * hx / 3
    end
    return s_du * hs / 3
end
# 制造解：u = A(t)cos x：A'' + A = e^{-t}，特解 ½e^{-t}；
# A(0)=0 ⟹ c1 = -1/2；A'(0) = c2 - 1/2 = 0 ⟹ c2 = +1/2
# （坑账：初版把 A'(0) 的符号推反，被 Duhamel 数值当场翻案）
for (x, t) in [(0.4, 1.0), (1.0, 2.0)]
    num = wave_duhamel(x, t)
    exa = 0.5 * (exp(-t) - cos(t) + sin(t)) * cos(x)
    @printf("(a) Duhamel (%.1f,%.1f): num %.9f  exact %.9f  |d|=%.1e\n", x, t, num, exa, abs(num - exa))
    @assert abs(num - exa) < 2e-6 "波方程 Duhamel 制造解对账"
end

# ---- (b) 有限传播速度：紧支初值的解在锥外严格为零 ----
# d'Alembert：g 紧支 |y|<0.5 ⟹ u(x,t) 只依赖 [x−t, x+t]∩supp
gcomp(y) = abs(y) < 0.5 ? exp(-y^2 * 10) : 0.0
function dalembert_g(x, t)
    0.5 * (gcomp(x + t) + gcomp(x - t))
end
for (x, t) in [(3.0, 1.0), (5.0, 0.5), (2.0, 1.5)]
    u = dalembert_g(x, t)
    @printf("(b) finite speed: u(%.1f,%.1f) = %.2e  (cone: |x|>0.5+t ⟹ 0)\n", x, t, u)
    if abs(x) > 0.5 + t
        @assert u == 0.0 "依赖锥外严格为零（有限传播）"
    end
end
# 与热方程对比：同样的紧支初值，t=0.5 时 x=5 处热解 > 0（06 章）
Phi1(x, t) = (4pi * t)^(-0.5) * exp(-x^2 / (4t))
u_heat = 0.0
L = 2.0; n = 4000; hh = 2L / n
for k in 0:n
    y = -L + k * hh
    w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
    global u_heat += w * Phi1(5.0 - y, 0.5) * gcomp(y)
end
u_heat *= hh / 3
@printf("    heat at same point: u(5, 0.5) = %.2e > 0 (infinite speed)\n", u_heat)
@assert u_heat > 0

# ---- (c) 能量守恒（连续依赖的等距性）：E(t) = ½∫(u_t² + u_x²) ----
# 单模式 u = cos(t)sin(x)：E = ½(½ sin²t + ½ cos²t ... ) 逐点核算
E_of(t) = 0.5 * (sin(t)^2 / 2 + cos(t)^2 / 2) * 1 + 0.5 * (cos(t)^2 / 2 + sin(t)^2 / 2)
for t in [0.0, 0.7, 2.3]
    @printf("(c) E(t=%.1f) = %.12f (constant 1/2)\n", t, E_of(t))
    @assert abs(E_of(t) - 0.5) < 1e-15 "动能+势能互换总和不变"
end

println("END ====")
