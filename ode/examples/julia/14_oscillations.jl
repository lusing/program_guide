println("==== 14 oscillations")

# 第 14 章：振动——三种阻尼、共振扫频、RLC。

function rk4_2(f, x, y, yp, h)
    k1y, k1v = yp, f(x, y, yp)
    k2y, k2v = yp + h * k1v / 2, f(x + h / 2, y + h * k1y / 2, yp + h * k1v / 2)
    k3y, k3v = yp + h * k2v / 2, f(x + h / 2, y + h * k2y / 2, yp + h * k2v / 2)
    k4y, k4v = yp + h * k3v, f(x + h, y + h * k3y, yp + h * k3v)
    (y + h * (k1y + 2k2y + 2k3y + k4y) / 6, yp + h * (k1v + 2k2v + 2k3v + k4v) / 6)
end
function integrate2(f, t0, y0, v0, t1; n = 24000)
    h = (t1 - t0) / n
    t, y, v = t0, y0, v0
    for _ in 1:n
        y, v = rk4_2(f, t, y, v, h)
        t += h
    end
    return y, v
end

w0 = 1.0    # 固有频率

# --- (a) 三种阻尼形态 ---
# 欠阻尼 δ=0.2：过零计数 ≥ 3
f_under(t, y, v) = -2 * 0.2 * v - w0^2 * y
t, y, v = 0.0, 1.0, 0.0
h = 30.0 / 240000
zeros_cnt = 0
prev = y
for _ in 1:240000
    global (y, v) = rk4_2(f_under, t, y, v, h)
    global t += h
    if prev * y < 0
        global zeros_cnt += 1
    end
    global prev = y
end
@assert zeros_cnt >= 3 "欠阻尼应振荡"
@assert abs(y) < 0.01 "欠阻尼衰减"
println("欠阻尼（δ=0.2ω₀）：30 秒内过零 $zeros_cnt 次，y(30) = ", round(y; digits=6))

# 临界阻尼 δ=1：无过零且最快回零
t, y, v = 0.0, 1.0, 0.0
zeros_c = 0
prev = y
for _ in 1:240000
    global (y, v) = rk4_2((t, y, v) -> -2v - w0^2 * y, t, y, v, h)
    global t += h
    prev * y < 0 && (global zeros_c += 1)
    global prev = y
end
@assert zeros_c == 0 "临界阻尼无振荡"
y_crit_end = y
# 过阻尼 δ=2：同样无过零，但更慢（同终点 |y| 更大）
t, y, v = 0.0, 1.0, 0.0
for _ in 1:240000
    global (y, v) = rk4_2((t, y, v) -> -4v - w0^2 * y, t, y, v, h)
    global t += h
end
@assert abs(y) > abs(y_crit_end) "过阻尼应比临界慢"
println("临界 vs 过阻尼：|y(30)| 临界 = ", round(abs(y_crit_end); digits=8), " < 过阻尼 = ", round(abs(y); digits=8))

# --- (b) 包络衰减：相邻峰比 ≈ e^{-δT} ---
δ = 0.2
T = 2pi / sqrt(w0^2 - δ^2)
t, y, v = 0.0, 1.0, 0.0
hh = T / 4000
peaks = Float64[]
for cyc in 1:6
    global t, y, v = t, y, v
    for _ in 1:4000
        global (y, v) = rk4_2(f_under, t, y, v, hh)
        global t += hh
    end
    push!(peaks, abs(y))
end
for i in 2:6
    ratio = peaks[i] / peaks[i-1]
    @assert abs(ratio - exp(-δ * T)) < 0.05 "包络应按 e^{-δT} 衰减"
end
println("欠阻尼包络：相邻峰比 ≈ e^{-δT} = ", round(exp(-δ * T); digits=4), "（5 组核对）")

# --- (c) 频率响应：数值扫频 vs 解析 X(ω) ---
X(w, δ, w0, F0) = F0 / sqrt((w0^2 - w^2)^2 + (2δ * w)^2)
# 数值稳态幅值：积 60 周期衰减瞬态，再取一个周期的峰
function steady_amp(w, dlt, w00)
    hstep = 2pi / w / 400
    t, y, v = 0.0, 0.0, 0.0
    f = (t, y, v) -> -2dlt * v - w00^2 * y + cos(w * t)
    for _ in 1:(60 * 400)
        y, v = rk4_2(f, t, y, v, hstep)
        t += hstep
    end
    peak = 0.0
    for _ in 1:400
        y, v = rk4_2(f, t, y, v, hstep)
        t += hstep
        peak = max(peak, abs(y))
    end
    peak
end
δf = 0.15
wr = sqrt(w0^2 - 2δf^2)
maxdev = 0.0
for w in [0.5wr, 0.8wr, wr, 1.2wr, 1.5wr]
    global maxdev = max(maxdev, abs(steady_amp(w, δf, w0) - X(w, δf, w0, 1.0)))
end
@assert maxdev < 0.03 "扫频幅值 vs 解析 X(ω)"
println("扫频：数值稳态幅值 vs X(ω) 最大偏差 = ", round(maxdev; digits=4), "（峰值在 ω_r = √(ω₀²−2δ²) = ", round(wr; digits=3), "）")

# --- (d) RLC 数字例：L=0.1, C=1e-3, R=2 ⟹ ω₀=100, δ=10, Q=5 ---
L, C, R = 0.1, 1e-3, 2.0
w0r = 1 / sqrt(L * C)
dr = R / (2L)
Q = w0r / (2dr)
@assert w0r == 100.0 && dr == 10.0 && Q == 5.0
@assert sqrt(w0r^2 - 2dr^2) ≈ 98.99494936611666 atol=1e-9
println("RLC：ω₀ = 100 s⁻¹，δ = 10，Q = 5，幅值共振 ω_r ≈ 98.99")

println("END ====")
