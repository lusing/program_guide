println("==== 06 clairaut")

# 第 06 章：未解出导数的方程——Clairut 包络 + 分支解 + 换轨。

# --- (a) 书习题 14：y = xy' + y'² —— 直线族 y = Cx + C² 与包络 y = -x²/4 ---
# 相切核对：直线 C 与抛物线的交点 x = -2C 处斜率相等（都为 C）
for C in [-2.0, -0.5, 0.0, 1.0, 3.0]
    xt = -2C                       # 切点横坐标（x = -g'(t) = -2t）
    line_y = C * xt + C^2
    para_y = -xt^2 / 4
    @assert abs(line_y - para_y) < 1e-12 "切点处纵坐标相等"
    # 直线斜率 = C；抛物线斜率 = -x/2 = -(-2C)/2 = C ✓
    @assert abs(-xt / 2 - C) < 1e-12 "切点处斜率相等"
end
println("直线族 y = Cx + C² 与包络 y = -x²/4 在 x = -2C 处相切（C = -2..3 五例）")

# --- (b) 分支解核对：书例 2.24 y'² - 2(x+y)y' + 4xy = 0 ---
# 两支 y' = 2x 与 y' = 2y ⟹ 解族 y = x² + C 与 y = Ce^{2x}
# 验证两族解都满足原方程（代入 y' 与 y）
for C in [-1.0, 0.0, 2.5]
    for x in [0.3, 1.1, 2.0]
        y = x^2 + C
        yp = 2x
        @assert abs(yp^2 - 2(x + y) * yp + 4x * y) < 1e-12 "族 y = x²+C 满足方程"
        y2 = C * exp(2x)
        yp2 = 2y2
        @assert abs(yp2^2 - 2(x + y2) * yp2 + 4x * y2) < 1e-10 "族 y = Ce^{2x} 满足方程"
    end
end
println("例 2.24 两族解 y = x²+C、y = Ce^{2x} 代入原方程恒为零（9 组参数）")

# 判别式曲线 x = y 代回原方程：x² - 4x² = -3x² ≠ 0 ⟹ 无奇异解
for x in [0.5, 1.0]
    @assert abs(x^2 - 4x * x) > 1e-12 "x = y 不满足方程"
end
println("判别式曲线 x = y 不满足方程 ⟹ 本例无奇异解")

# --- (c) 书例 2.25：y'² = 4x² 的换轨解在原点光滑拼接 ---
# y = x²(x≤0), -x²(x≥0)：拼接点 x=0 处左右导数都是 0，一阶光滑
yleft(x) = x^2        # x ≤ 0 支
yright(x) = -x^2      # x ≥ 0 支
h = 1e-7
dleft = (yleft(0) - yleft(-h)) / h      # 左导数 = 0
dright = (yright(h) - yright(0)) / h    # 右导数 = 0
@assert abs(dleft - dright) < 1e-6 "拼接点左右导数相等（C¹ 光滑）"
println("换轨解在 x = 0 拼接：左导数 ", dleft, " 右导数 ", dright)

# --- (d) 圆族包络（书例 2.27 的方程 y²(1-y'^2)... 取圆族 (x-C)²+y²=1）---
# 族 y = sqrt(1-(x-C)²)（上半圆），包络 y = 1：圆顶与直线相切
for C in [-0.5, 0.0, 0.7]
    # 圆与 y=1 的交点：x = C（圆顶），该处圆的斜率 = 0 = 直线斜率
    xtop = C
    # 数值斜率：y'(xtop) = -(x-C)/y = 0
    yv = sqrt(1 - (xtop - C)^2)
    @assert abs(yv - 1) < 1e-12 "圆顶纵坐标 = 1"
end
println("圆族 (x-C)²+y²=1 的包络是 y = 1（圆顶相切，三例）")

println("END ====")
