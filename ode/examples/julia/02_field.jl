println("==== 02 field")

# 第 02 章：方向场、等斜线与三方法收敛阶。

f(x, y) = x + y
ysol(x) = 2exp(x) - x - 1

# --- (a) 方向场数值重建：斜率矩阵文本图 ---
println("方向场 y' = x + y（行=y 自上而下 2..-2，列=x 自左而右 -2..2）：")
xs = -2.0:0.5:2.0
ys = 2.0:-0.5:-2.0
for y in ys
    row = String[]
    for x in xs
        s = f(x, y)
        push!(row, s > 0.05 ? "/" : (s < -0.05 ? "\\" : "-"))
    end
    println(join(row, " "))
end
# 结构断言：对角线 x+y=0 处斜率为 0；右上角最陡
@assert abs(f(1.0, -1.0)) < 1e-15
@assert f(2.0, 2.0) == 4.0

# --- (b) 等斜线核对：f(x,y) = k 上斜率全为 k ---
# y' = x + y 的等斜线 x + y = k：取 k = 1，即 y = 1 - x
for x in -1.5:0.3:1.5
    y = 1 - x
    @assert abs(f(x, y) - 1.0) < 1e-15 "等斜线 f=k 上斜率恒为 k"
end
println("等斜线 x + y = 1 上 11 个采样点斜率全部 = 1 ✓")

# --- (c) 三方法收敛阶测量 ---
function euler_step(g, x, y, h)
    y + h * g(x, y)
end
function heun_step(g, x, y, h)
    k1 = g(x, y)
    k2 = g(x + h, y + h * k1)
    y + h * (k1 + k2) / 2
end
function rk4_step(g, x, y, h)
    k1 = g(x, y)
    k2 = g(x + h / 2, y + h * k1 / 2)
    k3 = g(x + h / 2, y + h * k2 / 2)
    k4 = g(x + h, y + h * k3)
    y + h * (k1 + 2k2 + 2k3 + k4) / 6
end

function err_at_x1(step, h)
    n = round(Int, 1 / h)
    y = 1.0
    for i in 0:(n-1)
        y = step(f, i * h, y, h)
    end
    abs(y - ysol(1.0))
end

slope(loghs, logerrs) = begin
    # 最小二乘拟合斜率
    n = length(loghs)
    mx = sum(loghs) / n
    my = sum(logerrs) / n
    sum((loghs .- mx) .* (logerrs .- my)) / sum((loghs .- mx) .^ 2)
end

hs = [0.5^k for k in 4:9]   # 误差未触底的中段
for (name, step, lo, hi) in (("Euler", euler_step, 0.85, 1.15),
                             ("Heun", heun_step, 1.85, 2.15),
                             ("RK4", rk4_step, 3.7, 4.3))
    errs = [err_at_x1(step, h) for h in hs]
    p = slope(log.(hs), log.(errs))
    println(name, " 误差表: ", round.(errs; sigdigits=3), " 拟合阶 p = ", round(p; digits=3))
    @assert lo < p < hi "$name 收敛阶应在 ($lo, $hi)"
end

println("END ====")
