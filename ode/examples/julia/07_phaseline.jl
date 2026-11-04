println("==== 07 phaseline")

# 第 07 章：相线——平衡点、分类与轨道行为（书例 2.28–2.31）。

rk4(g, x, y, h) = begin
    k1 = g(y); k2 = g(y + h * k1 / 2)
    k3 = g(y + h * k2 / 2); k4 = g(y + h * k3)
    y + h * (k1 + 2k2 + 2k3 + k4) / 6
end
function integrate_to(g, y0, T; n = 24000)
    y = y0
    h = T / n
    for i in 0:(n-1)
        y = rk4(g, i * h, y, h)
    end
    y
end

# --- (a) 书例 2.29：y' = y(y-1)，平衡点 0（sink）与 1（source） ---
f29(y) = y * (y - 1)
# 符号分析：y>1 ↑、0<y<1 ↓、y<0 ↑ ⟹ 0 吸引、1 排斥
# 数值：sink 侧轨道 → 0，source 侧轨道离开 1
@assert abs(integrate_to(f29, 0.3, 12.0)) < 1e-4 "0.3 → sink 0"
@assert abs(integrate_to(f29, 0.7, 12.0)) < 1e-4 "0.7 → sink 0"
@assert integrate_to(f29, 1.3, 12.0) > 1e5 "1.3 上方轨道逃逸（source 上方）"
@assert abs(integrate_to(f29, -0.2, 12.0)) < 1e-4 "-0.2 自下方升向 sink 0（y<0 区间 ↑）"
println("y' = y(y-1)：0 是 sink（0.3/0.7/-0.2 → 0），1 是 source（上方逃逸）")

# 导数判据核对：f' = 2y-1，f'(0) = -1 < 0（sink），f'(1) = 1 > 0（source）
df29(y) = 2y - 1
@assert df29(0) < 0 && df29(1) > 0
println("导数判据：f'(0) = -1 < 0 sink，f'(1) = 1 > 0 source ✓")

# --- (b) 书例 2.30：y' = ky² 有限时间爆破，爆破时刻 t* = 1/(ky0) ---
f30(y) = 2y^2      # k = 2
# 解 y = 1/(1/y0 - 2t)，y0 = 1 ⟹ t* = 0.5
# Euler 步进找到数值越界点
yv, tv = 1.0, 0.0
h = 1e-5
while yv < 1e10 && tv < 1.0
    global yv += h * f30(yv)
    global tv += h
end
@assert abs(tv - 0.5) < 0.01 "数值爆破点应 ≈ t* = 0.5"
println("y' = 2y²、y(0)=1：数值爆破于 t = ", round(tv; digits=4), "（解析 t* = 0.5）")

# --- (c) 书例 2.31：y' = ky³ 导数判据失效、符号分析接管 ---
# k = -1：f'(0) = 0 但 y>0 ↓ → 0、y<0 ↑ → 0 ⟹ sink（幂式收敛 ~1/√(2t)）
f31(y) = -y^3
ysink = integrate_to(f31, 0.5, 200.0; n = 400000)
@assert abs(ysink) < 0.06 "0.5 应慢速收敛到 0（幂式 1/√(2t)）"
@assert abs(ysink - 1 / sqrt(2 * 200)) < 0.02 "收敛速率 ~ 1/√(2t)"
df31(y) = -3y^2
@assert df31(0) == 0 "f'(0) = 0：导数判据哑火"
println("y' = -y³：f'(0)=0 判据失效；符号分析 + 数值证实 sink，y(200) = ",
        round(ysink; digits=4), " ≈ 1/√(2·200) = ", round(1 / sqrt(400); digits=4))
# 反向对照：y' = +y³ 是 source，0.5 轨道有限时间爆破（解 1/√(4-2t)，t*=2）
f31p(y) = y^3
yv, tv = 0.5, 0.0
h = 1e-5
while yv < 1e10 && tv < 3.0
    global yv += h * f31p(yv)
    global tv += h
end
@assert abs(tv - 2.0) < 0.05 "source 情形爆破于 t* = 1/(2·y0²) = 2"
println("y' = +y³（source）：0.5 数值爆破于 t = ", round(tv; digits=3), "（解析 2.0）")

# --- (d) 相线构造器：f(y) = y(y-1)(y+2) 的平衡点与区间符号 ---
fex(y) = y * (y - 1) * (y + 2)
eqs = [-2.0, 0.0, 1.0]                       # 解析平衡点
# 区间符号采样（测试点 -3, -1, 0.5, 2）
signs = [sign(fex(y)) for y in (-3.0, -1.0, 0.5, 2.0)]
@assert signs == [-1.0, 1.0, -1.0, 1.0] "相线箭头方向：↓↑↓↑"
# 分类：-2 与 1 交替箭头（左入右出 = sink? 逐点判）
# y < -2: ↓（降向 -2）；-2<y<0: ↑（升离 -2）⟹ -2 是 source（下进上离）
# 修正读法：箭头指向平衡点 ⟹ sink。-2：左区箭头 ↓（向下远离 -2）、右区 ↑（向上远离）⟹ source
# 0：左区 ↑（升向 0）、右区 ↓（降向 0）⟹ sink；1：左 ↓ 右 ↑ ⟹ source
println("相线 f = y(y-1)(y+2)：平衡点 -2(source)、0(sink)、1(source)，区间符号 ↓↑↓↑")

println("END ====")
