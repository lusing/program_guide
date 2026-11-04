println("==== 23 series")

# 第 23 章：幂级数解法——Airy 递推、收敛半径、Frobenius。

# --- (a) Airy y'' - xy = 0 递推：(n+2)(n+1) a_{n+2} = a_{n-1} ---
# a₀ 支：a0, 0, 0, a0/12, 0, 0, a0/504, ...
# a₁ 支：0, a1, 0, 0, a1/60, 0, 0, a1/3960, ...
function airy_coeffs(N, a0, a1)
    a = zeros(Rational{Int}, N + 1)
    a[1] = a0      # a_0
    a[2] = a1      # a_1
    if N >= 3
        a[3] = 0   # a_2 = 0（n=0：2·1·a2 = 0）
    end
    for n in 1:(N-2)
        # (n+2)(n+1) a_{n+2} = a_{n-1}（y'' 的 x^n 项 = x·y 的 x^n 项 = a_{n-1}）
        if n - 1 >= 0 && n + 2 <= N
            a[n + 3] = (n - 1 >= 1 ? a[n - 1] : 0) // ((n + 2) * (n + 1))
        end
    end
    # 修正：n 从 1 开始：x^n 项：y'' 给 (n+2)(n+1)a_{n+2}；xy 给 a_{n-1}
    # n=1: 6 a3 = a0 ⟹ a3 = a0/6；n=2: 12 a4 = a1 ⟹ a4 = a1/12；
    # n=3: 20 a5 = a2 = 0；n=4: 30 a6 = a3 = a0/6 ⟹ a6 = a0/180
    a = zeros(Rational{Int}, N + 1)
    a[1] = a0; a[2] = a1; a[3] = 0
    for n in 1:(N-2)
        # a_{n+2} = a_{n-1} / ((n+2)(n+1))；a_{n-1} 存在下标 n（n-1 次幂在 a[n]）
        src = n == 1 ? a0 : (n == 2 ? a1 : a[n])
        a[n + 3] = src // ((n + 2) * (n + 1))
    end
    a
end
a = airy_coeffs(8, 1, 0)
@assert a[1] == 1 && a[4] == 1 // 6 && a[7] == 1 // 180 "a0 支：a3 = 1/6, a6 = 1/180"
b = airy_coeffs(8, 0, 1)
@assert b[2] == 1 && b[5] == 1 // 12 "a1 支：a4 = 1/12"
println("Airy 递推（a₀ 支）：a₃ = 1/6、a₆ = 1/180 ✓（精确有理数）")

# --- (b) 数值对照：部分和 vs scipy airy（此处用三阶递推数值自举 + RK4 对照）---
# 用级数（20 项）与 RK4 数值解对照（Ai 型初值 a0=1, a1=0 的解）
airy_part(x, a0, a1; N = 20) = begin
    s = 0.0
    for n in 0:N
        c = n == 0 ? 1.0 : (n == 1 ? (a1 / a0) : 0.0)
        # 用精确递推
    end
    # 直接重新生成浮点系数
    cf = zeros(N + 1)
    cf[1] = a0; cf[2] = a1; cf[3] = 0.0
    for n in 1:(N-2)
        src = n == 1 ? a0 : (n == 2 ? a1 : cf[n])
        cf[n + 3] = src / ((n + 2) * (n + 1))
    end
    s = 0.0
    for n in 0:N
        s += cf[n + 1] * x^n
    end
    s
end
# RK4 积分 y'' = xy
function rk4_2(f, x, y, yp, h)
    k1y, k1v = yp, f(x, y, yp)
    k2y, k2v = yp + h * k1v / 2, f(x + h / 2, y + h * k1y / 2, yp + h * k1v / 2)
    k3y, k3v = yp + h * k2v / 2, f(x + h / 2, y + h * k2y / 2, yp + h * k2v / 2)
    k4y, k4v = yp + h * k3v, f(x + h, y + h * k3y, yp + h * k3v)
    (y + h * (k1y + 2k2y + 2k3y + k4y) / 6, yp + h * (k1v + 2k2v + 2k3v + k4v) / 6)
end
x, y, yp = 0.0, 1.0, 0.0
h = 1.5 / 3000
for i in 0:2999
    global (y, yp) = rk4_2((x, y, v) -> x * y, x, y, yp, h)
    global x += h
end
@assert abs(airy_part(1.5, 1.0, 0.0; N = 20) - y) < 1e-8 "级数 20 项 vs RK4"
println("Airy：级数（20 项）与 RK4 在 x = 1.5 处一致（差 < 1e-8）")

# --- (c) Euler-Frobenius：x²y'' + 4xy' - 4y = 0 指标根 1、-4 ---
# 指标方程 k(k-1) + 4k - 4 = 0
r1, r2 = 1.0, -4.0
@assert abs(r1 * (r1 - 1) + 4 * r1 - 4) < 1e-12 && abs(r2 * (r2 - 1) + 4 * r2 - 4) < 1e-12
println("Frobenius 指标：k(k−1)+4k−4 = (k−1)(k+4)，根 1 与 −4 ✓")

# --- (d) 常点：y'' + y = 0 递推重新发明 sin/cos ---
function trig_coeffs(N, a0, a1)
    c = zeros(Float64, N + 1)
    c[1] = a0; c[2] = a1
    for n in 0:(N-2)
        c[n + 3] = -c[n + 1] / ((n + 2) * (n + 1))
    end
    c
end
cc = trig_coeffs(10, 1.0, 0.0)
# cos x 的泰勒：1, 0, -1/2, 0, 1/24, ...
@assert cc[1] == 1.0 && cc[3] == -0.5 && cc[5] ≈ 1/24 atol = 1e-15
ss = trig_coeffs(10, 0.0, 1.0)
@assert ss[2] == 1.0 && ss[4] == -1/6 && ss[6] ≈ 1/120 atol = 1e-15
println("y''+y=0 递推：a₀ 支重新发明 cos、a₁ 支重新发明 sin（系数 1/n! 交替）")

println("END ====")
