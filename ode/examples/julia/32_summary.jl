println("==== 32 summary")

# 第 32 章：收官——一条 IVP 走完全书流水线（四路同解）。

# 方程：y'' + 2y' + y = sin t + e^{-t}，y(0) = 0，y'(0) = 0
# 共振右端 e^{-t}（特征根 −1 重根）+ 非共振 sin t

# --- 路线 A：待定系数（解析） ---
# 齐次 y_h = (C1 + C2 t)e^{-t}
# 特解 1（sin t）：ȳ1 = A sin t + B cos t ⟹ (B+2A-?) 手算 A = 0, B = -1/2：ȳ1 = -cos t/2? 验证：
# 设 ȳ1 = a sin t + b cos t：代入 y''+2y'+y = sin t：
# (-a sin - b cos) + 2(a cos - b sin) + a sin + b cos = sin
# sin: -a - 2b + a = -2b = 1 ⟹ b = -1/2；cos: -b + 2a + b = 2a = 0 ⟹ a = 0
# ȳ1 = -cos t / 2 ✓
# 特解 2（共振 e^{-t}，二重根 ⟹ 升次 t²）：ȳ2 = c t² e^{-t} ⟹ 手算 c = 1/2
ysol(t) = (C1 + C2 * t) * exp(-t) - cos(t) / 2 + t^2 * exp(-t) / 2
# 初值 y(0)=0：C1 - 1/2 = 0 ⟹ C1 = 1/2
# y'(t) = C2 e^{-t} - (C1+C2 t)e^{-t} + sin/2 + (2t - t²)e^{-t}/2? 逐项
# y' = -C1 e^{-t} + C2 e^{-t} - C2 t e^{-t} + sin t/2 + e^{-t}(t - t²/2)
# y'(0) = -C1 + C2 + 0 + 0 = 0 ⟹ C2 = C1 = 1/2
ysol_final(t) = (0.5 + 0.5 * t) * exp(-t) - cos(t) / 2 + t^2 * exp(-t) / 2
# 残差核对（解析导数）
yp_final(t) = -0.5 * exp(-t) + 0.5 * exp(-t) - 0.5 * t * exp(-t) + sin(t) / 2 +
              exp(-t) * (t - t^2 / 2)
ypp_final(t) = 0.5 * exp(-t) - exp(-t) * (1 - t / 2 + t * 1) * 0 + cos(t) / 2 +
               exp(-t) * (1 - t) - 0.5 * t * exp(-t) * (-1) * 0
# 直接数值差商核对更稳
h = 1e-5
for t in [0.3, 1.7, 3.1]
    yv = ysol_final(t)
    ypv = (ysol_final(t + h) - ysol_final(t - h)) / 2h
    yppv = (ysol_final(t + h) - 2 * ysol_final(t) + ysol_final(t - h)) / h^2
    @assert abs(yppv + 2 * ypv + yv - (sin(t) + exp(-t))) < 1e-4 "路线 A 残差"
end
println("路线 A（待定系数+共振升次）：残差 < 1e-4 ✓，y(2) = ", round(ysol_final(2.0); digits=6))

# --- 路线 B：Laplace 变换（s 域代数） ---
# (s²+2s+1)Y = 1/(s²+1) + 1/(s+1)（零初值）
# Y = [1/((s²+1)(s+1)²) + 1/(s+1)³]
# 反变换核对：数值 Laplace(y_A) = Y(s)
function laplace_num(f, s; T = 30.0, n = 100000)
    hstep = T / n
    s_val = 0.0
    for i in 1:n-1
        t = i * hstep
        s_val += exp(-s * t) * f(t) * hstep
    end
    s_val + hstep / 2 * (f(0) + exp(-s * T) * f(T))
end
for s in [1.5, 2.2]
    Yanalytic = 1 / ((s^2 + 1) * (s + 1)^2) + 1 / (s + 1)^3
    @assert abs(laplace_num(ysol_final, s) - Yanalytic) / Yanalytic < 1e-4 "路线 B：L{y_A} = Y(s)"
end
println("路线 B（Laplace 代数解 Y(s)）：数值变换核对 ✓")

# --- 路线 C：RK4 数值 ---
function rk4_2(f, x, y, yp, hh)
    k1y, k1v = yp, f(x, y, yp)
    k2y, k2v = yp + hh * k1v / 2, f(x + hh / 2, y + hh * k1y / 2, yp + hh * k1v / 2)
    k3y, k3v = yp + hh * k2v / 2, f(x + hh / 2, y + hh * k2y / 2, yp + hh * k2v / 2)
    k4y, k4v = yp + hh * k3v, f(x + hh, y + hh * k3y, yp + hh * k3v)
    (y + hh * (k1y + 2k2y + 2k3y + k4y) / 6, yp + hh * (k1v + 2k2v + 2k3v + k4v) / 6)
end
t, y, yp = 0.0, 0.0, 0.0
hstep = 2.0 / 20000
for i in 0:19999
    global (y, yp) = rk4_2((t, y, v) -> sin(t) + exp(-t) - 2 * v - y, i * hstep, y, yp, hstep)
end
@assert abs(y - ysol_final(2.0)) < 1e-8 "路线 C：RK4 与解析一致"
println("路线 C（RK4）：y(2) = ", round(y; digits=8), "（与 A 差 ", abs(y - ysol_final(2.0)), "）")

# --- 路线 D：定性速查（迹-行列式） ---
# 齐次系统矩阵 [[0,1],[-1,-2]]：τ=-2, Δ=1 ⟹ 临界稳定结点（重根，衰减）
tau, delta = -2.0, 1.0
@assert tau^2 == 4 * delta "重根（退化结点）"
@assert tau < 0 "稳定（齐次衰减）"
println("路线 D（定性）：τ=−2、Δ=1 ⟹ 重根稳定结点，瞬态按 t·e^{−t} 衰减 ⟹ 稳态 = −cos t/2")

println("END ====")
