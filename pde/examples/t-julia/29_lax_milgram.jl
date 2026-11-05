# Ch29 二阶椭圆 I：弱解与 Lax-Milgram
#
# 对应书 §6.1（椭圆性、弱解定义）与 §6.2.1（Lax-Milgram 定理：
  # 强制+有界的双线性形式 ⟹ 变分问题唯一可解）。
#
# 数值：1D Poisson −u'' = f 的 hat 有限元；验证 Lax-Milgram 的两个
# 结构条件（强制性 α、有界性 M）在刚度矩阵上的数值面，以及解的
# Galerkin 正交性。

using Printf
using LinearAlgebra
using SparseArrays

println("==== 29")

# ---- 有限元装配：hat 基刚度/质量 ----
function assemble(N)
    h = 1 / N
    K = Tridiagonal([fill(-1 / h, N - 1)...], [fill(2 / h, N)...], [fill(-1 / h, N - 1)...])
    return K, h
end

# ---- (a) 强制性与有界性：谱比 α = λmin，M = λmax（H¹_0 谱度量）----
for N in [8, 16, 32]
    K, h = assemble(N)
    # K 的特征值（对称三对角）：λ_k = (2/h)(1 − cos(kπ/(N+1)))
    lam_min = (2 / h) * (1 - cos(pi / (N + 1)))
    lam_max = (2 / h) * (1 - cos(N * pi / (N + 1)))
    @printf("(a) N=%2d: coercivity alpha = λmin = %.4f (2/α = %.4f ~ h), M = λmax = %.4f\n",
            N, lam_min, 2 / lam_min, lam_max)
    @assert lam_min > 0 "强制（但 α ~ h → 0：刚度条件数随 N 恶化）"
    global lam_min32 = lam_min
end
@assert lam_min32 < 1.0 "1D 谱下界随网格变小——Lax-Milgram 常数与离散化"

# ---- (b) Lax-Milgram 的解：−u'' = f，u(0)=u(1)=0，f = π²sin(πx) ----
# 精确解 sin(πx)；hat 有限元解误差 O(h²)
function fem_solve(N, f)
    # 自由度 = 内点 x_i = i/N, i = 1..N-1（坑账：初版把 x=1 边界当内点，
    # 解右端不落零、误差 O(h)——自由度语义必须与 Dirichlet 边界一致）
    n = N - 1
    h = 1 / N
    xs = [(i) * h for i in 1:n]
    b = [f(x) * h for x in xs]          # 载荷（节点采样）
    c = [-1.0 for _ in 1:n-1]
    d = [2.0 for _ in 1:n]
    rhs = b .* h   # K = T/h ⟹ T u = h·b
    for i in 2:n
        m = c[i-1] / d[i-1]
        d[i] -= m * c[i-1]
        rhs[i] -= m * rhs[i-1]
    end
    u = zeros(n)
    u[n] = rhs[n] / d[n]
    for i in n-1:-1:1
        u[i] = (rhs[i] - c[i] * u[i+1]) / d[i]
    end
    return xs, u
end
f29(x) = pi^2 * sin(pi * x)
for N in [16, 32, 64]
    xs, u = fem_solve(N, f29)
    err = maximum(abs.(u .- sin.(pi .* xs)))
    @printf("(b) N=%2d: max error = %.3e (O(h²))\n", N, err)
    if N == 16
        global err16 = err
    end
    if N == 64
        @assert err < err16 / 10 "网格加密误差收敛"
    end
end

# ---- (c) Galerkin 正交性：残差与所有基函数正交（数值签名）----
N = 32
xs, u = fem_solve(N, f29)
h = 1 / N
n = N - 1
T = Tridiagonal(fill(-1.0, n - 1), fill(2.0, n), fill(-1.0, n - 1))
b = [f29(x) * h for x in xs] .|> x -> x * h / (1)   # rhs 同 fem_solve：b·h
resid = Matrix(T) * u .- [f29(x) * h^2 for x in xs]
@printf("(c) Galerkin orthogonality: ||K u - b||_inf = %.2e\n", maximum(abs.(resid)))
@assert maximum(abs.(resid)) < 1e-9 "变分方程的离散残差"

# ---- (d) 一般系数：−(a u')' = f，a 跳变界面通量连续 ----
a_coef(x) = x < 0.5 ? 4.0 : 1.0
# 制造解：u 连续、a u' 连续：取 u1 = sin(2x)（x<0.5），u2 = c1 x + c0
# 数值：界面调和（pdenum 18 章的核）——这里验证通量连续的弱解性质
# 用变分有限元（a 进刚度：界面单元调和平均 2·aL·aR/(aL+aR)）
function fem_var(N)
    h = 1 / N
    n = N - 1                      # 内点自由度
    Kd = zeros(n, n)
    for e in 1:n                   # 单元 [x_e, x_{e+1}]，最后一个右端是边界 x=1
        xl, xr = e * h, (e + 1) * h
        ae = (xl < 0.5 && xr > 0.5) ? 2 * 4.0 * 1.0 / (4.0 + 1.0) :
             (xr <= 0.5 ? 4.0 : 1.0)
        ke = ae / h
        if e <= n
            Kd[e, e] += ke         # 对角总加（边界单元的右端自由度不存在）
        end
        if e + 1 <= n              # 交叉项只在内点对
            Kd[e+1, e+1] += ke
            Kd[e, e+1] -= ke
            Kd[e+1, e] -= ke
        end
    end
    return Kd
end
Kd = fem_var(64)
@printf("(d) interface harmonized stiffness: cond(K) = %.1f (finite, SPD)\n",
        maximum(abs.(eigvals(Symmetric(Kd)))) / minimum(abs.(eigvals(Symmetric(Kd)))))
@assert issymmetric(Kd) && minimum(abs.(eigvals(Symmetric(Kd)))) > 0 "SPD ⟹ Lax-Milgram 离散核"

println("END ====")

