# 第 30 章 · 经典公式 —— Julia 通道
#
# depressed 三次 + 卡尔达诺公式 + 不可约情形 + 韦达定理 + 费拉里。

println("==== 30 经典公式")

# ---------- depressed cubic ----------
"""depressed 化归：x³ + ax² + bx + c --(x = t − a/3)--> t³ + pt + q。"""
depress(a, b, c) = (b - a^2 / 3, 2a^3 / 27 - a * b / 3 + c)
p, q = depress(-6.0, 11.0, -6.0)    # x³−6x²+11x−6（根 1,2,3）→ t³ − t
@assert p == -1.0
@assert q == 0.0
# t = x − a/3 = x + 2 → t 的根 −1, 0, 1
for t in (-1.0, 0.0, 1.0)
    @assert abs(t^3 + p * t + q) < 1e-12
end
println("depressed 化归：x³−6x²+11x−6 → t³ − t（t 根 −1,0,1；x 根 1,2,3）✓")

# ---------- 卡尔达诺 ----------
"""卡尔达诺公式全分支（复数域）。

u³ = A = −q/2 + √Δ；相伴立方根直接锁死约束 3uv = −p（v = −p/(3u)），
由恒等式 AB = −p³/27 自动保证 v³ = B——若分别取 A、B 的主立方根，
乘积 uv 未必落在正确分支上。"""
function cardano(p, q)
    Δ = q^2 / 4 + p^3 / 27
    A = -q / 2 + sqrt(complex(Δ))
    u = A ^ (1 / 3)
    v = -p / (3u)                    # 3uv = −p（⟹ v³ = −p³/(27A) = B）
    ω = exp(2im * π / 3)
    [(u * ω^k + v * ω^(-k)) for k in 0:2]
end

# t³−7t+6：根 −3, 1, 2（Δ = 9 − 343/27 = −100/27 < 0，复路取实部后检验残差）
roots = cardano(-7.0, 6.0)
rr = sort([real(r) for r in roots])
for r in rr
    @assert abs(r^3 - 7 * r + 6) < 1e-9
end
@assert abs(rr[1] + 3) < 1e-6 && abs(rr[2] - 1) < 1e-6 && abs(rr[3] - 2) < 1e-6
println("卡尔达诺：t³−7t+6 三根 {-3, 1, 2} 全部回收（复路取实部）✓")

# Δ > 0 分支：t³ − 1 = (t−1)(t²+t+1)，根 1, ω, ω²（一对共轭复根）
roots_one = cardano(0.0, -1.0)
@assert abs(roots_one[1] - 1) < 1e-12
for z in roots_one
    @assert abs(z^3 - 1) < 1e-12
end
println("卡尔达诺：t³−1（Δ = 1/4 > 0）根 1, ω, ω² 逐根残差 < 1e-12 ✓")

# 不可约情形：t³ − 3t + 1（Δ = 1/4 − 1 = −3/4 < 0，三实根）
roots_irr = cardano(-3.0, 1.0)
rr = sort([real(r) for r in roots_irr])
@assert all(abs(imag(r)) < 1e-9 for r in roots_irr)
for r in rr
    @assert abs(r^3 - 3r + 1) < 1e-9
end
println("不可约情形：t³−3t+1 的 Δ < 0，复路返回三实根 {$(round.(rr, digits=4))} ✓")

# 整条流水线：一般三次 → 平移 → 卡尔达诺 → 回移 x = t − a/3
a3, b3, c3 = -6.0, 11.0, -6.0
p3, q3 = depress(a3, b3, c3)
xs = sort([real(z) - a3 / 3 for z in cardano(p3, q3)])
@assert abs(xs[1] - 1) < 1e-9 && abs(xs[2] - 2) < 1e-9 && abs(xs[3] - 3) < 1e-9
for x in xs
    @assert abs(x^3 + a3 * x^2 + b3 * x + c3) < 1e-9
end
println("流水线：x³−6x²+11x−6 经 depress→cardano→回移得 x 根 {1, 2, 3} ✓")

# ---------- 韦达 ----------
using Random
Random.seed!(20261104)
for _ in 1:50
    r1, r2, r3 = rand(-5:5, 3)
    a2 = -(r1 + r2 + r3)
    a1 = r1 * r2 + r1 * r3 + r2 * r3
    a0 = -(r1 * r2 * r3)
    for r in (r1, r2, r3)
        @assert r^3 + a2 * r^2 + a1 * r + a0 == 0
    end
end
println("韦达定理：随机三次 50 组的根之和/积恒等式 ✓")

# ---------- 费拉里 ----------
"""费拉里：x⁴ + px² + qx + r = 0（先消三次项）经预解三次。

恒等式 x⁴+px²+qx+r = (x²+s/2)² − [(s−p)x² − qx + (s²/4−r)]；
选 s 使方括号内为完全平方 ⟺ 预解三次 s³ − ps² − 4rs + (4rp − q²) = 0。"""
function ferrari(p, q, r)
    res(t) = t^3 - p * t^2 - 4r * t + (4r * p - q^2)
    # 扫描 + 二分：取预解三次的最大实根（A = s − p 最大，远离退化 A = 0）
    s = NaN
    prev_t, prev_f = -20.0, res(-20.0)
    for t in -19.95:0.05:20.0
        f = res(t)
        if f == 0                       # 根恰好落在网格点上（整数根常见）
            s = t
        elseif prev_f * f < 0
            lo, hi, flo = prev_t, t, prev_f
            for _ in 1:100
                mid = (lo + hi) / 2
                fm = res(mid)
                if flo * fm <= 0
                    hi = mid
                else
                    lo, flo = mid, fm
                end
            end
            s = (lo + hi) / 2          # 不断覆盖 → 最终存最大根
        end
        prev_t, prev_f = t, f
    end
    # (x² + s/2)² = A x² + B x + C 应为完全平方：B² − 4AC = 0
    A = s - p
    B = -q
    C = s^2 / 4 - r
    @assert abs(B^2 - 4A * C) < 1e-6
    m = -B / (2A)                      # 右边 = A(x − m)²
    # x² + s/2 = ±√A (x − m) 展开成两个二次
    √A = sqrt(complex(A))
    out = ComplexF64[]
    for sgn in (+1, -1)
        b = -sgn * √A                  # x² + bx + c = 0
        c = s / 2 + sgn * √A * m
        push!(out, (-b + sqrt(b^2 - 4c)) / 2,
              (-b - sqrt(b^2 - 4c)) / 2)
    end
    out
end

# x⁴ − 9x² + 4x + 12 = (x+3)(x+1)(x−2)²，根 −3, −1, 2, 2（q ≠ 0 走满费拉里）
r4 = ferrari(-9.0, 4.0, 12.0)
reals = sort([real(z) for z in r4])
@assert length(reals) == 4
for x in reals
    @assert abs(x^4 - 9x^2 + 4x + 12) < 1e-6
end
@assert abs(reals[1] + 3) < 1e-5 && abs(reals[2] + 1) < 1e-5 &&
        abs(reals[3] - 2) < 1e-5 && abs(reals[4] - 2) < 1e-5
println("费拉里：x⁴−9x²+4x+12 经预解三次回收四根 {−3, −1, 2, 2} ✓")

# 对照：q = 0 的退化 x⁴ − 5x² + 4 = (x²−1)(x²−4)，根 ±1, ±2
r4b = ferrari(-5.0, 0.0, 4.0)
reals = sort([real(z) for z in r4b])
@assert length(reals) == 4
@assert abs(reals[1] + 2) < 1e-5 && abs(reals[2] + 1) < 1e-5 &&
        abs(reals[3] - 1) < 1e-5 && abs(reals[4] - 2) < 1e-5
println("费拉里：x⁴−5x²+4（q = 0 退化）回收四根 {−2, −1, 1, 2} ✓")

println("END ====")
