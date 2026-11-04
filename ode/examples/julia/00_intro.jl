println("==== 00 intro")

# 第 00 章：解的核对——y = 2eˣ - x - 1 是 y' = x + y、y(0) = 1 的解。
# 数值证据版：中心差商算 y'，与右端 x + y 的残差应趋零。

ysol(x) = 2exp(x) - x - 1
rhs(x, y) = x + y

# --- 验证 1：代入残差（中心差商，误差 O(h²)）---
h = 1e-5
resid = maximum(abs((ysol(x + h) - ysol(x - h)) / 2h - rhs(x, ysol(x)))
                for x in -1.0:0.1:1.0)
@assert resid < 1e-4 "代入残差应为 0（差商精度内）"
println("y' = x + y 代入残差（x∈[-1,1]，h=1e-5）: ", resid)

# --- 验证 2：解析导数核对（精确等式：y' = 2eˣ - 1 = x + y 化简后同式）---
dysol(x) = 2exp(x) - 1
resid2 = maximum(abs(dysol(x) - rhs(x, ysol(x))) for x in -1.0:0.1:1.0)
@assert resid2 < 1e-14 "解析导数与右端应逐点相等"
println("解析导数核对残差: ", resid2)

# --- 验证 3：初值条件 ---
@assert abs(ysol(0) - 1.0) < 1e-15 "y(0) = 1"
println("初值 y(0) = ", ysol(0))

# --- 验证 4：反例——错解的残差立刻暴露 ---
wrong(x) = 2exp(x) - x          # 少了 -1
resid_w = maximum(abs((wrong(x + h) - wrong(x - h)) / 2h - rhs(x, wrong(x)))
                  for x in -1.0:0.1:1.0)
@assert resid_w > 0.5 "错解残差必须显著非零"
println("错解 2eˣ - x 的残差（应 ~1）: ", resid_w)

# --- 验证 5：RK4 数值解与解析解交叉验证 ---
function rk4(f, x, y, h)
    k1 = f(x, y)
    k2 = f(x + h / 2, y + h * k1 / 2)
    k3 = f(x + h / 2, y + h * k2 / 2)
    k4 = f(x + h, y + h * k3)
    y + h * (k1 + 2k2 + 2k3 + k4) / 6
end
f(x, y) = x + y
y = 1.0
for i in 0:999
    global y = rk4(f, i * 0.001, y, 0.001)
end
@assert abs(y - ysol(1.0)) < 1e-10 "RK4 到 x=1 应咬住解析解"
println("RK4(1000 步) 与解析解在 x=1 的差: ", abs(y - ysol(1.0)))

println("END ====")
