println("==== 16 eigen")

# 第 16 章：特征值方法——三情形 + 消元 + 稳定性。
using LinearAlgebra

function rk4vec(f, t, u, h)
    k1 = f(t, u)
    k2 = f(t + h / 2, u .+ h .* k1 ./ 2)
    k3 = f(t + h / 2, u .+ h .* k2 ./ 2)
    k4 = f(t + h, u .+ h .* k3)
    u .+ h .* (k1 .+ 2 .* k2 .+ 2 .* k3 .+ k4) ./ 6
end
function integrate_sys(f, u0, T; n = 24000)
    h = T / n
    t, u = 0.0, copy(u0)
    for _ in 1:n
        u = rk4vec(f, t, u, h)
        t += h
    end
    u
end

# --- (a) 消元 vs 特征多项式：A = [[2,1],[1,2]] ---
A1 = [2.0 1.0; 1.0 2.0]
# 消元：x'' = 4x' - 3x ⟹ 特征多项式 λ² - 4λ + 3
# det(A - λI) = (2-λ)² - 1 = λ² - 4λ + 3 ✓
for λ in [0.0, 1.5, 3.7]
    @assert abs((2 - λ)^2 - 1 - (λ^2 - 4λ + 3)) < 1e-12 "消元 = det(A-λI)"
end
eigvals1 = sort(collect(eigvals(A1)))
@assert eigvals1 ≈ [1.0, 3.0] atol = 1e-12
println("A=[[2,1],[1,2]]：特征值 1、3（消元多项式 = det(A−λI)）")

# --- (b) 三情形解析解 vs 数值 ---
# 实异根：x' = Ax，A1；特征向量 λ=1 ↦ (1,-1)、λ=3 ↦ (1,1)
# 初值 (1,2) = a(1,-1) + b(1,1)：a+b=1, -a+b=2 ⟹ a=-0.5, b=1.5
xsol1(t) = -0.5 * exp(t) * [1.0, -1.0] + 1.5 * exp(3t) * [1.0, 1.0]
u = integrate_sys((t, u) -> A1 * u, [1.0, 2.0], 0.8)
@assert norm(u - xsol1(0.8)) < 1e-8 "实异根解析 vs RK4"
println("实异根：x(0.8) 数值 vs 解析一致（差 ", norm(u - xsol1(0.8)), "）")

# 复根：A = [[1, -2], [2, 1]]（1 ± 2i）：解 = e^t(cos2t u - sin2t w) 组合
A2 = [1.0 -2.0; 2.0 1.0]
xsol2(t, c) = exp(t) * (c[1] * [cos(2t); sin(2t)] + c[2] * [-sin(2t); cos(2t)])
u0 = [1.0, 0.5]
# 初值系数就是 u0（t=0 时基为 I）
u2 = integrate_sys((t, u) -> A2 * u, u0, 1.2)
@assert norm(u2 - xsol2(1.2, u0)) < 1e-8 "复根解析 vs RK4"
println("复根：x(1.2) 数值 vs 解析一致")

# 重根：Jordan [[1,1],[0,1]]：x = e^t (a + bt, c + dt...)，解 (1+t)e^t 支
A3 = [1.0 1.0; 0.0 1.0]
# 解曲线：x1 = e^t(1 + t)（初值 (1,0)），x2 = 0... 核对：u = (e^t(1+t), 0)?
# x2' = x2 ⟹ x2 = 0；x1' = x1 + x2 = x1 ⟹ x1 = e^t —— 等等 Jordan: x1' = x1 + x2
u3 = integrate_sys((t, u) -> A3 * u, [1.0, 0.0], 1.5)
# x2 = 0, x1 = e^t
@assert norm(u3 - [exp(1.5), 0.0]) < 1e-9 "初值在特征方向的解"
u4 = integrate_sys((t, u) -> A3 * u, [1.0, 1.0], 1.5)
# 广义方向：x2 = e^t, x1' = x1 + e^t ⟹ x1 = e^t(1 + t)
@assert norm(u4 - [exp(1.5) * 2.5, exp(1.5)]) < 1e-8 "重根 t·e^t 升次"
println("重根：初值 (1,1) 给 x(1.5) = e^t(1+t, 1)（t·e^{λt} 升次核对）")

# --- (c) 非齐次：x' = Ax + e^{γt}b，γ=0（常向量 b）特解 -A⁻¹b ---
b = [1.0, -1.0]
xs = -inv(A1) * b
# 残差：A·xs + b = 0
@assert norm(A1 * xs + b) < 1e-12 "常向量特解 -A⁻¹b"
u5 = integrate_sys((t, u) -> A1 * u + b, [0.0, 0.0], 3.0)
# 理论：x → 特解（齐次部分 e^{3t} 增长？初值 0 ⟹ x = ∫e^{A(3-s)}b ds）
# 数值核对用 t·e 公式复杂——直接验证解满足方程的终值行为：跳过
println("非齐次：常向量特解 −A⁻¹b 代入残差 = 0")

# --- (d) 稳定性：特征值实部全负 ⟹ x(t) → 0 ---
A5 = [-2.0 0.5; 0.3 -3.0]
u6 = integrate_sys((t, u) -> A5 * u, [2.0, -1.0], 8.0)
@assert norm(u6) < 1e-4 "稳定矩阵的解衰减"
println("稳定：A 特征值 −2.x/−3.x ⟹ x(8) 范数 = ", norm(u6))

println("END ====")
