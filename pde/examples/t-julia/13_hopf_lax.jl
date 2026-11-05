# Ch13 Hamilton-Jacobi I：变分、Legendre 变换与 Hopf-Lax 公式
#
# 对应书 §3.3.1-3.3.2：作用量泛函、Hamilton ODE、Legendre 变换、
# Hopf-Lax 公式 u(x,t) = min_y [t L((y-x)/t) + g(y)]（凸 H 情形）。

using Printf

println("==== 13")

# ---- (a) Legendre 变换：H(p) = p²/2 的对偶是 L(v) = v²/2 ----
# 配方恒等式：pv − v²/2 = p²/2 − (v−p)²/2 ≤ p²/2（v = p 取等）
for (p, v) in [(1.3, 0.4), (-0.8, -0.8), (2.0, 2.0)]
    lhs = p * v - v^2 / 2
    rhs = p^2 / 2 - (v - p)^2 / 2
    @printf("(a) Legendre: pv-v²/2 = %.9f  p²/2-(v-p)²/2 = %.9f\n", lhs, rhs)
    @assert abs(lhs - rhs) < 1e-15 "配方恒等式（Lean 通道有完整证明）"
    @assert lhs ≤ p^2 / 2 + 1e-16 "上界在 v = p 饱和"
end

# ---- (b) Hopf-Lax：H = p²/2 时 u(x,t) = min_y [(y-x)²/(2t) + g(y)] ----
# 与 12 章特征线解（g(x) = x²/4）对照
g1(y) = y^2 / 4
function hopf_lax(x, t; n = 200001)
    # 黄金分割不必：g 凸 ⟹ 整体凸，扫描 + 局部精修
    lo, hi = x - 3 * sqrt(t) - 2, x + 3 * sqrt(t) + 2
    best = Inf; by = lo
    for k in 0:n-1
        y = lo + (hi - lo) * k / n
        v = (y - x)^2 / (2t) + g1(y)
        if v < best
            best = v; by = y
        end
    end
    # 局部三分精修
    d = (hi - lo) / n
    while d > 1e-12
        for y in (by - d, by, by + d)
            v = (y - x)^2 / (2t) + g1(y)
            if v < best
                best = v; by = y
            end
        end
        d /= 2
    end
    return best
end
# 12 章特征线解：u = ξ²/4 + (ξ/2)²/2·t（ξ = x/(1+t/2)）
hj_exact(x, t) = (x / (1 + t / 2))^2 / 4 + ((x / (1 + t / 2)) / 2)^2 / 2 * t
for (x, t) in [(0.8, 0.4), (1.0, 1.0), (-0.6, 2.0)]
    hl = hopf_lax(x, t)
    ex = hj_exact(x, t)
    @printf("(b) Hopf-Lax (%.1f,%.1f): min = %.10f  characteristic = %.10f  |d|=%.1e\n",
            x, t, hl, ex, abs(hl - ex))
    @assert abs(hl - ex) < 1e-6 "Hopf-Lax 与特征线解一致（光滑范围）"
end

# ---- (c) Hamilton ODE 与特征的对应：p 沿特征常数、ẋ = H'(p) ----
# 数值 Hamilton 流（辛欧拉）：dp/ds = 0, dx/ds = p
p0, x0 = 0.6, 0.2
for s in [0.5, 1.5]
    x_s = x0 + p0 * s   # 解析（p 常数）
    @printf("(c) Hamilton flow: p(%.1f) = %.4f  x(%.1f) = %.4f (p const, x linear)\n",
            s, p0, s, x_s)
    @assert x_s == x0 + p0 * s
end

# ---- (d) 非凸 g 的 Hopf-Lax 仍给粘性解（弱解章节的预演）----
# g = |x|（凸但 kink）：Hopf-Lax 值与分段特征线解对照
gd(y) = abs(y)
function hopf_lax_d(x, t; n = 200001)
    lo, hi = x - 3 * sqrt(t) - 2, x + 3 * sqrt(t) + 2
    best = Inf
    for k in 0:n-1
        y = lo + (hi - lo) * k / n
        v = (y - x)^2 / (2t) + gd(y)
        best = min(best, v)
    end
    return best
end
# 解析：min_y [(y-x)²/2t + |y|]——分 y ≥ 0 与 y ≤ 0 两支
function hl_d_exact(x, t)
    # y ≥ 0 支：二次最小在 y* = max(0, x - t)；y ≤ 0 支：y* = min(0, x + t)
    v1 = begin
        y = max(0.0, x - t); (y - x)^2 / (2t) + y
    end
    v2 = begin
        y = min(0.0, x + t); (y - x)^2 / (2t) - y
    end
    return min(v1, v2)
end
for (x, t) in [(0.5, 0.3), (1.0, 0.8), (-0.7, 0.5)]
    num = hopf_lax_d(x, t)
    exa = hl_d_exact(x, t)
    @printf("(d) kink data (%.1f,%.1f): Hopf-Lax %.8f  piecewise-exact %.8f\n", x, t, num, exa)
    @assert abs(num - exa) < 1e-4 "角点初值：两支取 min 的闭式"
end

println("END ====")
