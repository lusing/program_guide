println("==== 18 apps")
using LinearAlgebra

# 第 18 章：方程组应用——螺旋运动、磁矩进动、耦合振子。

function rk4vec(f, t, u, h)
    k1 = f(t, u)
    k2 = f(t + h / 2, u .+ h .* k1 ./ 2)
    k3 = f(t + h / 2, u .+ h .* k2 ./ 2)
    k4 = f(t + h, u .+ h .* k3)
    u .+ h .* (k1 .+ 2 .* k2 .+ 2 .* k3 .+ k4) ./ 6
end

# --- (a) 带电粒子：v̇ = (qB/m)(v_y, -v_x, 0)，B 沿 z ---
ωc = 2.0          # qB/m
v0 = [1.0, 0.5, 0.3]
# 状态 (x, y, z, vx, vy, vz)
f(t, s) = [s[4], s[5], s[6], ωc * s[5], -ωc * s[4], 0.0]
h = 2pi / ωc / 4000
t, s = 0.0, [0.0, 0.0, 0.0, v0...]
for _ in 1:4000       # 一个回旋周期
    global s = rk4vec(f, t, s, h)
    global t += h
end
# 断言：回到 (x,y) 起点（圆）、z 漂移 v_z·T、能量守恒
@assert hypot(s[1], s[2]) < 1e-6 "回旋一周回到起点（xy 投影圆）"
@assert abs(s[3] - 0.3 * (2pi / ωc)) < 1e-8 "z 漂移 = v_z·T"
@assert abs(hypot(s[4], s[5]) - hypot(v0[1], v0[2])) < 1e-9 "|v_⊥| 守恒"
@assert abs(s[6] - 0.3) < 1e-12 "v_z 守恒"
println("螺旋运动：回旋周期后 xy 回到起点，z 漂移 v_z·T，|v| 守恒")
# 回旋半径 r = v_⊥/ωc
r = hypot(v0[1], v0[2]) / ωc
println("回旋半径 v_⊥/ωc = ", round(r; digits=4))

# --- (b) 磁矩进动：Ṁ = -γ B × M，B 沿 z：M 绕 z 进动，|M|、M_z 守恒 ---
γB = 3.0
M0 = [0.8, 0.3, 0.5]      # |M0| = √(0.98)
fM(t, M) = [-γB * M[2], γB * M[1], 0.0]
h = 2pi / γB / 4000
t, M = 0.0, copy(M0)
for _ in 1:4000
    global M = rk4vec(fM, t, M, h)
    global t += h
end
@assert norm(M - M0) < 1e-7 "拉莫尔周期后回到初值"
@assert abs(norm(M) - norm(M0)) < 1e-9 "|M| 守恒"
@assert abs(M[3] - M0[3]) < 1e-10 "M_z 守恒"
println("磁矩进动：拉莫尔周期 2π/γB 后复位，|M| 与 M_z 守恒")

# --- (c) 耦合振子：m x_i'' = -k x_i - k(x_i - x_j)，k/m = 1 ---
# x'' = [[-2, 1], [1, -2]] x；简正模 (1,1): ω²=1；(1,-1): ω²=3
fc(t, s) = [s[3], s[4], -2s[1] + s[2], s[1] - 2s[2]]
# 同相模初值 (1,1,0,0)：能量不交换
t, s = 0.0, [1.0, 1.0, 0.0, 0.0]
h = 2pi / 4000
for _ in 1:8000          # 两个"同相周期"（ω=1）
    global s = rk4vec(fc, t, s, h)
    global t += h
end
@assert abs(s[1] - 1.0) < 1e-6 && abs(s[2] - 1.0) < 1e-6 "同相模保持同相（ω=1）"
# 同相模下中间弹簧不吃力：x1 - x2 = 0 恒成立
println("同相模 (1,1)：频率 ω=1，两质量同步（中间弹簧不吃力）")
# 反相模 (1,-1)：ω=√3
t, s = 0.0, [1.0, -1.0, 0.0, 0.0]
h = (2pi / sqrt(3.0)) / 4000
for _ in 1:4000
    global s = rk4vec(fc, t, s, h)
    global t += h
end
@assert abs(s[1] - 1.0) < 1e-6 && abs(s[2] + 1.0) < 1e-6 "反相模周期 √3·2π 复位"
println("反相模 (1,-1)：频率 √3·ω（周期核对复位）")
# 拍：一般初值 (1, 0, 0, 0)，总能量守恒，两质量能量互补
function energy(s)
    0.5 * (s[3]^2 + s[4]^2) + 0.5 * (s[1]^2 + s[2]^2) + 0.5 * (s[1] - s[2])^2
end
t, s = 0.0, [1.0, 0.0, 0.0, 0.0]
E0 = energy(s)
h2 = 0.001
maxEdev = 0.0
for _ in 1:20000
    global s = rk4vec(fc, t, s, h2)
    global t += h2
    global maxEdev = max(maxEdev, abs(energy(s) - E0))
end
@assert maxEdev < 1e-6 "总能量守恒（RK4 精度内）"
println("一般初值：总能量守恒（最大偏差 ", maxEdev, "），两质量能量往复交换（拍）")

println("END ====")
