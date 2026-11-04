println("==== 25 fourier")

# 第 25 章：Fourier 级数——系数、Gibbs、Parseval、速率。

# --- (a) 方波系数：b_n = 4/(pi n)（奇 n） ---
sq(x) = x < 0 ? -1.0 : 1.0
for n in [1, 3, 5]
    # 数值积分 ∫_{-pi}^{pi} sq(x) sin(nx) dx / pi
    Nn = 200000
    h = 2pi / Nn
    s = 0.0
    for k in 1:Nn-1
        x = -pi + k * h
        s += sq(x) * sin(n * x)
    end
    bn = (s + 0.5 * (sq(-pi) * sin(-n * pi) + sq(pi) * sin(n * pi))) * h / pi
    @assert abs(bn - 4 / (pi * n)) < 1e-4 "b_n = 4/(pi n)"
end
println("方波系数：b_n = 4/(πn)（n = 1,3,5 数值积分复算）")

# --- (b) 部分和：跳跃点 → 0（中点），远点 → f ---
function sq_partial(x, N)
    s = 0.0
    for n in 1:2:N
        s += 4 / (pi * n) * sin(n * x)
    end
    s
end
@assert abs(sq_partial(0.0, 1001)) < 1e-12 "跳跃点收敛到中点 0"
@assert abs(sq_partial(pi / 2, 1001) - 1.0) < 5e-3 "远点收敛"
println("收敛：x = 0（跳跃点）→ 0（中点）；x = π/2 → 1（误差 O(1/N)）")

# --- (c) Gibbs 过冲：8.95%（数值搜索部分和的极大） ---
function gibbs_overshoot(N)
    # 搜索 (0, 2π/N) 内的部分和极大
    vmax = 0.0
    for k in 1:200
        x = k * (2pi / N) / 200
        v = abs(sq_partial(x, N))
        if v > vmax
            vmax = v
        end
    end
    vmax - 1.0
end
for N in [200, 1000]
    over = gibbs_overshoot(N)
    # 过冲 = 8.95% × 跳跃幅度（方波跳 2）⟹ ≈ 0.179
    @assert 0.15 < over < 0.19 "Gibbs 过冲 = 8.95% × 跳跃 2 ≈ 0.179（N=$N 得 $over）"
end
println("Gibbs：N = 200/1000 的过冲 ≈ 0.179（= 8.95% × 跳跃幅度 2，不随 N 消失）")

# --- (d) Parseval：(1/pi)∫f^2 = sum b_n^2（(1/π)∫_{-π}^{π}1 dx = 2） ---
sumsq = sum((4 / (pi * n))^2 for n in 1:2:2001)
@assert abs(sumsq - 2.0) < 0.005 "Parseval：Σb_n^2 = 2 = (1/π)∫f²"
println("Parseval：Σbₙ² = 2 = (1/π)∫f²（截断误差 O(1/N)）")

# --- (e) 速率：x^2 的余弦系数 ~ 1/n^2 ---
f2(x) = x^2
# a_n = (2/pi)∫₀^π x^2 cos nx dx = 4(-1)^n/n^2
for n in [3, 7]
    Nn = 100000
    h = pi / Nn
    s = sum(f2.((collect(1:Nn-1)) .* h) .* cos.(n .* (collect(1:Nn-1)) .* h))
    an = 2 / pi * (s + 0.5 * (0 + f2(pi) * cos(n * pi))) * h
    @assert abs(an - 4 * (-1.0)^n / n^2) < 1e-4 "a_n = 4(−1)^n/n^2"
end
println("速率：f = x² 的 aₙ = 4(−1)ⁿ/n²（1/n² 衰减，导数跳跃）")

println("END ====")
