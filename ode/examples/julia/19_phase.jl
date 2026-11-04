println("==== 19 phase")

# 第 19 章：相平面——迹-行列式分类 + 单摆 + 零斜线。
using LinearAlgebra

function rk4vec(f, t, u, h)
    k1 = f(t, u)
    k2 = f(t + h / 2, u .+ h .* k1 ./ 2)
    k3 = f(t + h / 2, u .+ h .* k2 ./ 2)
    k4 = f(t + h, u .+ h .* k3)
    u .+ h .* (k1 .+ 2 .* k2 .+ 2 .* k3 .+ k4) ./ 6
end
integrate(f, u0, T; n = 24000) = begin
    h = T / n
    t, u = 0.0, copy(u0)
    for _ in 1:n
        u = rk4vec(f, t, u, h)
        t += h
    end
    u
end

# (a) 迹-行列式七情形：A = [[0,1],[-Delta, Tau]]
cases = [
    ("saddle", -1.0, 2.0, 1.0),         # τ=-1, Δ=-2? 调整：直接给 (τ, Δ)
]
# 直接按 (τ, Δ) 构造伴随形
function mkA(tau, delta)
    [0.0 1.0; -delta tau]
end
tests = [
    ("saddle", 0.0, -1.0),          # 鞍点
    ("stable_node", -3.0, 2.0),     # τ<0, τ²>4Δ
    ("stable_spiral", -1.0, 1.0),   # τ<0, τ²<4Δ
    ("center", 0.0, 1.0),
    ("unstable_spiral", 1.0, 1.0),
    ("unstable_node", 3.0, 2.0),
]
for (name, tau, delta) in tests
    A = mkA(tau, delta)
    f = (t, u) -> A * u
    uend = integrate(f, [1.0, 0.0], 10.0; n = 100000)
    r = norm(uend)
    if name == "saddle"
        @assert r > 10 "鞍点轨道离开"
    elseif name == "center"
        @assert abs(r - 1.0) < 1e-6 "中心轨道范数守恒"
    elseif occursin("unstable", name)
        @assert r > 10 "不稳定轨道发散"
    else
        @assert r < 0.05 "稳定轨道收敛（e^{-0.5·10} ≈ 7e-3 量级）"
    end
    println(name, "（τ=", tau, ", Δ=", delta, "）：终态范数 ", round(r; sigdigits=4))
end

# (b) 单摆：x' = y, y' = -sin x。奇点 (0,0) 中心、(π,0) 鞍点
pend = (t, u) -> [u[2], -sin(u[1])]
# 小幅闭轨：初值 (0.5, 0)，一个周期后回到起点
u0 = [0.5, 0.0]
# 小幅周期 T ≈ 2π(1 + θ0²/16 + ...)
T1 = 2pi * (1 + 0.5^2 / 16)
u1 = integrate(pend, u0, T1; n = 24000)
@assert norm(u1 - u0) < 5e-3 "小幅闭轨周期复现（含幅修正常数）"
println("单摆小幅（0.5 rad）：周期 2π(1+θ²/16) 修正后复现")
# 大幅绕圈：初值 (0, 2.2)（能量 > 2 ⟹ 绕圈）
uend = integrate(pend, [0.0, 2.2], 10.0; n = 100000)
# 绕圈轨道：x 单调增（穿越 ±π）
println("单摆大幅：x(10) = ", round(uend[1]; digits=2), "（绕圈运动，穿越 π）")
# 线性化分类：奇点 (0,0) A=[[0,1],[-1,0]] τ=0,Δ=1 中心；(π,0) A=[[0,1],[1,0]] Δ=-1 鞍点
A1 = [0.0 1.0; -1.0 0.0]
A2 = [0.0 1.0; 1.0 0.0]
@assert tr(A1) == 0 && det(A1) == 1 "下垂：中心"
@assert det(A2) == -1 "倒立：鞍点"
println("线性化：下垂 (0,0) 是中心，倒立 (π,0) 是鞍点（τ=0/Δ=1 与 Δ=−1）")

# (c) 零斜线：f1 = y = 0 上轨道竖直（dx/dt = 0 ⟹ x 取极值）
# 取捕食模型 x' = x(1 - y/2), y' = y(x/2 - 1/3)（Lotka-Volterra）
lv = (t, u) -> [u[1] * (1 - u[2] / 2), u[2] * (u[1] / 2 - 1 / 3)]
# 数值轨道上 x 的极值点应满足 y ≈ 2（f1 = 0 线）
h = 0.002
t, u = 0.0, [1.0, 1.0]
xs, ys = [u[1]], [u[2]]
for _ in 1:20000
    global u = rk4vec(lv, t, u, h)
    global t += h
    push!(xs, u[1]); push!(ys, u[2])
end
# 找 x 的局部极值，断言该处 y ≈ 2
checked = 0
for i in 2:(length(xs)-1)
    if (xs[i] - xs[i-1]) * (xs[i+1] - xs[i]) < 0 && checked < 3
        @assert abs(ys[i] - 2.0) < 0.02 "x 极值点应落在零斜线 y = 2 上"
        global checked += 1
    end
end
@assert checked >= 2
println("零斜线：x 极值点落在 f₁=0（y=2）线上（", checked, " 组核对）")

println("END ====")
