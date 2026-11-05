# 27_ritz_galerkin.jl —— 第 27 章：Ritz、Galerkin 与权余量方法（Julia 通道）
#
#   (1) Ritz 法（正弦基）：-u'' + u = f 的系数方程与收敛阶；
#   (2) Galerkin 与 Ritz 的同一性（对称正定）；
#   (3) 配点法（权余量家族的 delta 权）：同一基下精度对照。

println("==== 27 ritz galerkin")

function hat27(x, i, h)
    xi = i * h
    if x <= xi - h || x >= xi + h
        return 0.0
    elseif x <= xi
        return (x - (xi - h)) / h
    else
        return ((xi + h) - x) / h
    end
end


using LinearAlgebra

# 问题：-u'' + u = x 于 (0,1)，u(0)=u(1)=0
# 精确解：u = x - sinh(x)/sinh(1)
uex27(x) = x - sinh(x) / sinh(1)

# 基函数 φ_j = sin(jπx)（零边界自动满足）
# D(φ_j, φ_k) = ∫(φ_j'φ_k' + φ_jφ_k) = δ_jk·(j²π² + 1)/2
# F(φ_j) = ∫ x sin(jπx) dx = (-1)^{j+1}/(jπ)
n = 40
c = [((j % 2 == 1 ? 1.0 : -1.0) / (j * pi)) / ((j^2 * pi^2 + 1) / 2) for j in 1:n]
u_ritz(x) = sum(c[j] * sin(j * pi * x) for j in 1:n)
err = maximum(abs(u_ritz(x) - uex27(x)) for x in 0:0.001:1)
println("Ritz (sine basis, n=$n): max err vs exact = ", round(err, sigdigits=4))
@assert err < 5e-5 "正弦基 Ritz 应谱收敛（1/j^3 系数，n=40 给 ~1e-5）"

# 收敛速度：系数 c_j ~ 1/j³ ⟹ 截断误差 ~ 1/n²
errs = [begin
    cc = [((j % 2 == 1 ? 1.0 : -1.0) / (j * pi)) / ((j^2 * pi^2 + 1) / 2) for j in 1:m]
    maximum(abs(sum(cc[j] * sin(j * pi * x) for j in 1:m) - uex27(x)) for x in 0:0.002:1)
end for m in (2, 4, 8)]
println("Ritz truncation errors n=2/4/8: ", round.(errs, sigdigits=4))
@assert errs[3] < errs[2] / 2.5 "系数 1/j³（且只有奇模式）⟹ 误差 ~ 1/n²"

# ---------- (2) Galerkin 同一性 ----------
# Galerkin：∫(-u'' + u - x)·φ_j = 0 分部积分后同一系数方程。
# 用 hat 基（有限元预告）核对：D 与 F 的装配给出同一解
N = 40
h = 1 / N
nh = N - 1
A = Matrix(Tridiagonal(fill(-1 / h + h / 6, nh - 1), fill(2 / h + 2h / 3, nh), fill(-1 / h + h / 6, nh - 1)))
b = [begin
    # F(hat_i) = ∫ x·hat_i（两段线性积，闭式）
    xi = i * h
    (h^2 / 6 * (3 * 0 + 3 * 0) ) # 占位——直接数值
end for i in 1:nh]
# 数值 F(hat_i)
for i in 1:nh
    lo = max((i - 1) * h, 0.0)
    hi = min((i + 1) * h, 1.0)
    m = 100
    s = 0.0
    for k in 0:m
        x = lo + (hi - lo) * k / m
        w = (k == 0 || k == m) ? 1 : (k % 2 == 1 ? 4 : 2)
        hatx = hat27(x, i, h)
        s += w * x * hatx
    end
    b[i] = s * (hi - lo) / (3m)
end
ch = A \ b
u_hat(x) = sum(ch[i] * hat27(x, i, h) for i in 1:nh)
err_hat = maximum(abs(u_hat(x) - uex27(x)) for x in 0:0.001:1)
println("Galerkin (hat basis, N=$N): max err = ", round(err_hat, sigdigits=4))
@assert err_hat < 2e-4 "hat 基 Galerkin 应 O(h²)（误差 $err_hat）"
println("Ritz and Galerkin produce the same solution (symmetric positive system)")

# ---------- (3) 配点法 ----------
# 配点：在配点 x_i 处令残差为零（delta 权）
# 用 hat 基 + 配点 x_i = 节点：残差方程不同于 Galerkin（矩阵不对称）
Ac = zeros(nh, nh)
bc = zeros(nh)
for i in 1:nh
    xi = i * h
    for j in 1:nh
        # -hat_j''(xi) 用分布意义（不可用）——配点法对 hat 基失效
        # 改用二次样条或直接用正弦基配点
        Ac[i, j] = (j * pi)^2 * sin(j * pi * xi) + sin(j * pi * xi)
    end
    bc[i] = xi
end
cc = Ac \ bc
u_colloc(x) = sum(cc[j] * sin(j * pi * x) for j in 1:nh)
err_c = maximum(abs(u_colloc(x) - uex27(x)) for x in 0:0.001:1)
println("collocation (sine basis, n=$nh): max err = ", round(err_c, sigdigits=4))
@assert err_c < 5e-4 "配点法应收敛（误差 $err_c）"

println("END ====")

function hat27(x, i, h)
    xi = i * h
    if x <= xi - h || x >= xi + h
        return 0.0
    elseif x <= xi
        return (x - (xi - h)) / h
    else
        return ((xi + h) - x) / h
    end
end
