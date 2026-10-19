println("==== 28 product_topological")
# 第 28 章：拓扑乘积的正则传递。
# ① 紧矩形账与挖洞紧集的精确账；
# ② 截口一致连续引理显影：sup_y |f(s,y)−f(s₀,y)| → 0（T 紧）；
# ③ 反例：T 非紧时不一致（f = xy/(x²+y²) 在 s→0）；
# ④ 开集外逼近：圆盘账 = π/4。

# ① 紧矩形与挖洞
mu_rect(x1, x2, y1, y2) = (x2 - x1) * (y2 - y1)
@assert mu_rect(0, 1, 0, 1) == 1.0
@assert abs(mu_rect(0, 1, 0, 1) - mu_rect(0, 0.4, 0, 0.4) - mu_rect(0, 0.4, 0.6, 1)
            - mu_rect(0.6, 1, 0, 0.4) - mu_rect(0.6, 1, 0.6, 1)
            - mu_rect(0.4, 0.6, 0, 0.4) - mu_rect(0.4, 0.6, 0.6, 1)
            - mu_rect(0, 0.4, 0.4, 0.6) - mu_rect(0.6, 1, 0.4, 0.6)) - 0.04 < 1e-12  # 挖洞分解账：剩余 0.96
println("compact rectangles: unit square minus open hole = exact 0.96: OK")

# ② 截口一致连续（T = [0,π] 紧）：f(x,y) = sin(xy)
f(x, y) = sin(x * y)
s0 = 0.7
for dx in (1e-1, 1e-2, 1e-3)
    supdiff = 0.0
    for k in 0:9999
        y = π * k / 10000
        supdiff = max(supdiff, abs(f(s0 + dx, y) - f(s0, y)))
    end
    # Lipschitz 上界：|f(s,y)−f(s₀,y)| ≤ |y|·dx ≤ π·dx
    @assert supdiff ≤ π * dx + 1e-12
end
# 收敛速率 ~ O(dx)（一致），打印一个样本
println("section-uniform-continuity: sup_y diff <= pi*|dx| (compact T): OK")

# ③ 反例：T = (0,1] 非紧，g(s,y) = s·y/(s²+y²) 在 (s,y)→(0,0) 方向依赖路径
g(s, y) = s == 0 && y == 0 ? 0.0 : (s * y) / (s^2 + y^2)
# 沿固定 s → 0：对 y 一致吗？sup_y |g(dx,y) − g(0,y)| = sup_y g(dx,y) = 1/2（y=dx 处）
for dx in (1e-2, 1e-4)
    supv = 0.0
    for k in 1:10000
        y = k / 10000
        supv = max(supv, abs(g(dx, y) - g(0.0, y)))
    end
    @assert supv > 0.49              # 一致性破产：sup 不随 dx → 0
end
println("non-compact T: uniform control fails (sup stays 1/2): OK")

# ④ 开集外逼近：1/4 圆盘（r = 0.9，全含于单位方格）的开/闭双向账
function quarter_disk(radius, n)
    cnt = 0
    for i in 1:n, j in 1:n
        x = (i - 0.5) / n; y = (j - 0.5) / n
        x^2 + y^2 < radius^2 && (cnt += 1)
    end
    cnt / (n * n)
end
const R = 0.9
closed_m = quarter_disk(R - 0.005, 700)   # 内缩（紧）账
open_m = quarter_disk(R + 0.005, 700)     # 膨胀（开）账
target = π * R^2 / 4
@assert closed_m ≤ target + 1e-3 ≤ open_m + 1e-3   # 三明治夹住真值
@assert open_m - closed_m < 0.02                   # 三明治宽度受 margin 控制
println("outer approximation of quarter-disk: sandwich around pi r^2/4: OK")

println("END ====")
