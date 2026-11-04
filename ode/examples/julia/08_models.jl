println("==== 08 models")

# 第 08 章：一阶模型合集——摩擦、火箭、冷却、半衰期、复利、盐水、RL。

# --- (a) 摩擦减速（书例 2.32）：v' = -(k/m)v，总滑行距离 = v0·m/k ---
m, k, v0 = 2.0, 3.0, 4.0
v(t) = v0 * exp(-k * t / m)
x(t) = (v0 * m / k) * (1 - exp(-k * t / m))
# 数值积分总距离 vs v0·m/k
T = 30.0
n = 3_000_000
total = sum(v(i * T / n) for i in 1:n) * (T / n)
@assert abs(total - v0 * m / k) < 1e-4 "总距离应 = v0m/k = 8/3（矩形和误差 O(h)=1e-5）"
println("摩擦：数值总距离 ", total, " vs v0·m/k = ", v0 * m / k)

# --- (b) 火箭方程（书例 2.33）：Δv = ve·ln(m0/mf) ---
ve = 3.0                                  # km/s
dv1 = ve * log(7.0)                       # mp/mf = 6 ⟹ m0/mf = 7
@assert abs(dv1 - 5.8377) < 1e-3 "单级 Δv ≈ 5.85 km/s"
dv2 = 2ve * log(7.0)                      # 两级各抛一半干重
@assert dv2 > 11.2 "两级 Δv ≈ 11.68 > 逃逸速度 11.2"
println("火箭：单级 Δv = ", round(dv1; digits=3), " km/s（<11.2 逃逸），两级 = ",
        round(dv2; digits=3), " km/s（>11.2 ✓）")

# --- (c) 牛顿冷却（书例 2.34）：T = Tenv + (T0-Tenv)e^{-kt}，3τ 衰减到 e^{-3} ---
Tenv, T0, kc = 20.0, 90.0, 0.5
tau = 1 / kc
excess(t) = (T0 - Tenv) * exp(-kc * t)
@assert abs(excess(3tau) / excess(0) - exp(-3)) < 1e-12
println("冷却：t = 3τ 时温差衰减到 e^{-3} = ", round(exp(-3); digits=5))

# --- (d) 半衰期（书例 2.35）：λ = ln2/30，N(30) = N0/2、N(60) = N0/4 ---
lam = log(2) / 30
@assert abs(exp(-lam * 30) - 0.5) < 1e-12
@assert abs(exp(-lam * 60) - 0.25) < 1e-12
println("衰变：30 天余 1/2，60 天余 1/4（λ = ln2/30）")

# --- (e) 复利（书例 2.39）：$100000、6%、15 年 ---
S = 100000.0
yearly = S * 1.06^15
monthly = S * (1 + 0.06 / 12)^(12 * 15)
cont = S * exp(0.06 * 15)
@assert abs(yearly - 239655.82) < 0.5 "年末复利 ≈ 239655.82"
@assert abs(cont - 245960.31) < 0.5 "连续复利 = 100000·e^{0.9} ≈ 245960.31"
diff = cont - yearly
@assert 6000 < diff < 6500 "差 ≈ 6304"
println("复利：年末 ", round(yearly; digits=2), "，月度 ", round(monthly; digits=2),
        "，连续 ", round(cont; digits=2), "（连续 vs 年末差 ", round(diff; digits=1), "）")

# --- (f) 盐水冲洗（书例 2.36）：V' = -6V/(150-2t)，V(0)=6 ---
# 解 V = 6·(150-2t)³/150³；t=60（体积 30L）时 V = 6·(1/5)³ = 0.048
Vsol(t) = 6 * (150 - 2t)^3 / 150^3
@assert abs(Vsol(60) - 0.048) < 1e-12
# RK4 数值核对（体积守恒地缩小的线性方程）
function rk4(g, t, y, h)
    k1 = g(t, y); k2 = g(t + h / 2, y + h * k1 / 2)
    k3 = g(t + h / 2, y + h * k2 / 2); k4 = g(t + h, y + h * k3)
    y + h * (k1 + 2k2 + 2k3 + k4) / 6
end
y = 6.0
n = 60000
h = 60.0 / n
for i in 0:(n-1)
    global y = rk4((t, v) -> -6v / (150 - 2t), i * h, y, h)
end
@assert abs(y - Vsol(60)) < 1e-10 "RK4 应咬住解析解"
println("盐水：60 分钟后剩盐 ", y, " L（解析 0.048）")

# --- (g) RL 电路（书例 2.41）：i = (E/R)(1 - e^{-t/τ})，τ = L/R ---
E, R, L = 12.0, 4.0, 2.0
tauRL = L / R
iInf = E / R
@assert abs(iInf * (1 - exp(-1)) - iInf * 0.6321206) < 1e-6
@assert iInf == 3.0 && tauRL == 0.5
println("RL：i(∞) = E/R = 3 A，τ = L/R = 0.5 s，t=τ 时到 63.2%")

println("END ====")
