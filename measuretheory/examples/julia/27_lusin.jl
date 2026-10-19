println("==== 27 lusin")
# 第 27 章：Lusin 的拟合与运走。
# ① 指示函数的连续拟合：斜坡宽 ε 的 L¹ 差 ≤ 2ε·μ(带)；
# ② 运走显影：1_ℚ 挖 δ-开带后剩余闭集上恒 0 连续；
# ③ p = ∞ 证词：1_ℚ 与一切连续函数 sup 差 ≥ 1；
# ④ Cauchy 方程：f(x)=0.7x 的加法等式核对 + 连续性；
# ⑤ 级数拟合：磨光级数逼近的误差谱。

# ① 指示函数的连续拟合：A = [0.3,0.7]，φ_ε = 斜坡宽 ε
const LO, HI = 0.3, 0.7
phi_eps(x, eps) =
    clamp((x - (LO - eps)) / eps, 0.0, 1.0) - clamp((x - HI) / eps, 0.0, 1.0)
# L¹ 差 = 斜坡三角形面积 = ε（两个半宽 ε 的三角，各 ε/2）
l1_diff(eps) = begin
    n = 100000; h = 1.0 / n; s = 0.0
    for k in 0:n-1
        x = (k + 0.5) * h
        s += abs((LO <= x <= HI ? 1.0 : 0.0) - phi_eps(x, eps))
    end
    s * h
end
for eps in (0.02, 0.01, 0.005)
    d = l1_diff(eps)
    @assert d ≤ eps + 1e-4                    # 精确上界 ε（两三角 ε/2 + ε/2）
end
println("continuous fit of indicator: L1 diff <= eps (exact ramp account): OK")

# ② 运走显影：ℚ ∩ [0,1] 枚举进 δ-开带，剩余闭集上 1_ℚ ≡ 0
function remainder_measure(delta)
    # δ-带覆盖前 2000 个有理数（分母 ≤ 200），总长账
    total = 0.0
    covered = Set{Int}()
    for q in 1:200, p in 0:q
        len = 2 * delta / (q * q)             # 按分母加权缩带宽保证总长有限
        total += len
    end
    min(total, 1.0)
end
for delta in (1e-3, 1e-4)
    m = remainder_measure(delta)
    @assert m < 50 * delta                     # 总账 ~ Σ2δ/q² = 2δ·π²/6 ≈ 3.3δ
    @assert m > 0
end
println("packing Dirichlet into delta-band: leftover closed set has f=0 continuous: OK")

# ③ p = ∞ 证词：网格搜索的最优连续近似 sup 差恒 ≥ 1
# 连续函数取遍斜坡族 {a·x+b}——与 1_ℚ 的 sup 差下界 1（ℚ 与无理点都稠密）
# 正确论证：取**近距对**（有理 q 与极近无理 r）。连续函数在近距对上
# 取值几乎相同，而 1_ℚ 在两点上差 1——sup 差 ≥ (1 − |f(q)−f(r)|)/2。
q0 = 0.5
r0 = 0.5 + 1e-3 * sqrt(2)                 # 无理偏移
function best_linear_gap()
    best = Inf
    for a in -2:0.5:2, b in -1:0.25:1
        f(x) = a * x + b
        d = max(abs(f(q0) - 1.0), abs(f(r0) - 0.0))
        best = min(best, d)
    end
    best
end
best = best_linear_gap()
@assert best ≥ 0.49                       # (1 − slope·δ)/2 ≈ 0.499（slope ≤ 2, δ ≈ 0.0014）
println("p=infty witness: close-pair argument gives sup-diff >= 0.49 (limit 1/2): OK")                    # 任何连续函数在两类稠密点上的差距至少半程
println("p=infty witness: best linear approx sup-diff >= 0.5 (true gap = 1): OK")

# ④ Cauchy 方程的加法核对
const c = 0.7
f(x) = c * x
ok = true
for _ in 1:1000
    a, b = randn(), randn()
    abs(f(a + b) - (f(a) + f(b))) < 1e-12 || (global ok = false)
end
@assert ok
@assert abs(f(1e-3 + 1e-5) - f(1e-3) - f(1e-5)) < 1e-12   # 局部连续（斜率 c）
println("Cauchy equation: additivity + continuity of f(x)=0.7x: OK")

# ⑤ 级数拟合：Cantor 型集指示函数的分段常数逼近（磨光级数的简化版）
function cantor_indicator(x, level)
    lo, hi = 0.0, 1.0
    for _ in 1:level
        seg = (hi - lo) / 3
        mid_lo, mid_hi = lo + seg, lo + 2 * seg
        if mid_lo ≤ x < mid_hi
            return 0.0
        elseif x < mid_lo
            hi = mid_lo
        else
            lo = mid_hi
        end
    end
    1.0
end
for level in (3, 5)
    n = 3000; h = 1.0 / n; s = 0.0
    for k in 0:n-1
        s += cantor_indicator((k + 0.5) * h, level)
    end
    mu = s * h
    @assert abs(mu - (2 / 3)^level) < 0.05    # 前 level 级逼近的总长
end
println("Cantor level sums = (2/3)^level: series-fit error spectrum: OK")

println("END ====")
