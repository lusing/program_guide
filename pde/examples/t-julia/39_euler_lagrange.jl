# Ch39 非线性 I：Euler-Lagrange 方程与二阶变分
#
# 对应书 §8.1：泛函 I[w] = ∫L(∇w, w, x)、一阶变分（E-L 方程）、
# 二阶变分（Legendre 条件/稳定性）。

using Printf
using LinearAlgebra

println("==== 39")

# ---- (a) 一阶变分消失 = E-L 方程（数值：扰动能量的导数在解处为 0）----
# I[w] = ∫(½|∇w|² − w³/3)，E-L：−Δw = w² 于 (0,1) 零边值
# 数值解（牛顿迭代有限差分）；然后扰动能量导数核对
function solve_el(; N = 200, maxit = 40)
    h = 1 / (N + 1)
    w = fill(0.1, N)   # 初值（正解分支）
    for _ in 1:maxit
        # 牛顿：−w'' − w² = 0：J = T/h² − 2diag(w)
        r = [2w[i] / h^2 - w[i-1+1] / h^2 - (i > 1 ? w[i-1] / h^2 : 0) - w[i]^2 for i in 1:N]
        # 简化残差：-(w_{i-1} - 2w_i + w_{i+1})/h² - w_i²（边界项 0）
        r = [-(0 - 2w[1] + w[2]) / h^2 - w[1]^2;
             [-(w[i-1] - 2w[i] + w[i+1]) / h^2 - w[i]^2 for i in 2:N-1];
             -(w[N-1] - 2w[N] + 0) / h^2 - w[N]^2]
        # Jacobian（三对角）
        J = zeros(N, N)
        for i in 1:N
            J[i, i] = 2 / h^2 - 2w[i]
            i > 1 && (J[i, i-1] = -1 / h^2)
            i < N && (J[i, i+1] = -1 / h^2)
        end
        dw = J \ r
        w .-= dw
        norm(dw) < 1e-12 && break
    end
    return w, h
end
w, h = solve_el()
# 残差
res = maximum(abs.([-(0 - 2w[1] + w[2]) / h^2 - w[1]^2;
                    [-(w[i-1] - 2w[i] + w[i+1]) / h^2 - w[i]^2 for i in 2:length(w)-1];
                    -(w[length(w)-1] - 2w[length(w)] + 0) / h^2 - w[length(w)]^2]))
@printf("(a) Newton solve -w'' = w²: residual = %.2e\n", res)
@assert res < 1e-10 "E-L 方程的离散解"

# 扰动能量导数核对：dI[u+εv]/dε|₀ = 0（v 零边值）
xs = [(i + 1) * h for i in 0:length(w)-1]
I_of(uv) = sum(0.5 * ((uv[i+1] - uv[i]) / h)^2 - uv[i]^3 / 3 for i in 1:length(uv)-1) * h +
           0 * (0.5 * (uv[end]^2) * 0)
v = sin.(pi .* xs)
eps = 1e-6
up = w + eps * v
um = w - eps * v
dI = (I_of([0.0; up; 0.0]) - I_of([0.0; um; 0.0])) / (2eps)
@printf("    first variation dI/deps = %.2e (zero at solution)\n", dI)
@assert abs(dI) < 1e-4 "一阶变分在解处消失（数值 E-L）"

# ---- (b) 二阶变分：d²I/dε² = ∫(|∇v|² − 2uv²)——解小于第一特征值阈值时正 ----
d2I = (I_of([0.0; up; 0.0]) - 2I_of([0.0; w; 0.0]) + I_of([0.0; um; 0.0])) / eps^2
# 理论：∫|∇v|² − 2∫uv²（符号依赖解大小）
@printf("(b) second variation = %.4f\n", d2I)
# L²·2 项 vs 梯度项：w 峰值小时正（局部极小）
@assert d2I > 0 "此解是局部极小（小解分支稳定）"

println("END ====")

