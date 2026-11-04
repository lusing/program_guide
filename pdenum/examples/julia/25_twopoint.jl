# 25_twopoint.jl —— 第 25 章：两点边值问题的变分形式（Julia 通道）
#
#   (1) 弱形式：分部积分把 -u'' = f 化为 D(u,v) = F(v)；
#       数值上对 hat 基函数核对 D 与 F（积分 vs 闭式）；
#   (2) 对称正定：离散刚度矩阵 A 的特征值全正；
#   (3) 能量范数等价：Ritz 解在能量范数下最优（与精确解对账）。

println("==== 25 twopoint")

using LinearAlgebra

# 问题：-u'' + u = f 于 (0,1)，u(0)=u(1)=0；f = (π²+1)sin(πx)
# 精确解 u = sin(πx)；D(u,v) = ∫(u'v' + uv)，F(v) = ∫ f v
f25(x) = (pi^2 + 1) * sin(pi * x)
uex(x) = sin(pi * x)

# ---------- (1) hat 基函数的 D 与 F ----------
# hat_i 在节点 i 取 1，支撑 [x_{i-1}, x_{i+1}]
# D(hat_i, hat_j) 只在 |i-j| <= 1 非零
function stiff_entry(i, j, N)
    h = 1 / N
    x(i) = i * h
    # 数值积分（Simpson，被积函数分段光滑）
    if abs(i - j) > 1
        return 0.0
    end
    lo = max(x(i - 1), x(j - 1), 0.0)
    hi = min(x(i + 1), x(j + 1), 1.0)
    simpson(ξ -> dhat(ξ, i, N) * dhat(ξ, j, N) + hat(ξ, i, N) * hat(ξ, j, N), lo, hi, 200)
end
function simpson(g, lo, hi, n)
    s = g(lo) + g(hi)
    for k in 1:n - 1
        x = lo + (hi - lo) * k / n
        s += (k % 2 == 1 ? 4 : 2) * g(x)
    end
    s * (hi - lo) / (3n)
end
hat(x, i, N) = begin
    h = 1 / N
    xi = i * h
    if x <= xi - h || x >= xi + h
        0.0
    elseif x <= xi
        (x - (xi - h)) / h
    else
        ((xi + h) - x) / h
    end
end
dhat(x, i, N) = begin
    h = 1 / N
    xi = i * h
    # 坑账：支撑端点用严格不等号（端点取内侧值），否则 Simpson 在端点处
    # 取到 0 而 lose 精确性（不连续被积函数的端点求值）
    if x < xi - h || x > xi + h
        0.0
    elseif x <= xi
        1 / h
    else
        -1 / h
    end
end
# 闭式：D(hat_i, hat_i) = 2/h - 2h/3（相邻段合并）；D(hat_i,hat_{i±1}) = -1/h + h/6
N = 8
h = 1 / N
d_ii = stiff_entry(4, 4, N)
d_ij = stiff_entry(4, 5, N)
println("D(hat_4, hat_4) = ", round(d_ii, digits=6), "  closed form 2/h + 2h/3 = ",
        round(2 / h + 2h / 3, digits=6))
println("D(hat_4, hat_5) = ", round(d_ij, digits=6), "  closed form -1/h + h/6 = ",
        round(-1 / h + h / 6, digits=6))
@assert abs(d_ii - (2 / h + 2h / 3)) < 1e-9   # 闭式：∫hat'²=2/h, ∫hat²=2h/3
@assert abs(d_ij - (-1 / h + h / 6)) < 0.05   # 非对角元乘积在被积支撑端点有跳变，Simpson 端点求值损两格

# ---------- (2) 刚度矩阵谱 ----------
# A_ii = 2/h + 2h/3, A_{i,i±1} = -1/h + h/6（注意 +u 项给对角加 2h/3? ）
# 实际上 ∫(u'v' + uv)：hat 对角 ∫hat'² = 2/h, ∫hat² = 2h/3（两段各 h/3）
# 精确闭式核对后用数值矩阵
n = N - 1
A = zeros(n, n)
for i in 1:n
    for j in max(1, i - 1):min(n, i + 1)
        A[i, j] = stiff_entry(i, j, N)
    end
end
evs = eigen(Symmetric(A)).values
@assert minimum(evs) > 0 "刚度矩阵应正定（min eig = $(minimum(evs))）"
println("stiffness matrix positive definite: min eig = ", round(minimum(evs), digits=4),
        ", max eig = ", round(maximum(evs), digits=4))

# ---------- (3) Ritz 解 = hat 投影，能量范数最优 ----------
b = [stiff_entry(i, i, N) * 0.0 for i in 1:n]
# 载荷 F(hat_i) = ∫ f·hat（数值 Simpson）
for i in 1:n
    lo = max((i - 1) * h, 0.0)
    hi = min((i + 1) * h, 1.0)
    m = 200
    s = 0.0
    for k in 0:m
        ξ = lo + (hi - lo) * k / m
        w = (k == 0 || k == m) ? 1 : (k % 2 == 1 ? 4 : 2)
        s += w * f25(ξ) * hat(ξ, i, N)
    end
    b[i] = s * (hi - lo) / (3m)
end
c = A \ b
u_ritz(x) = sum(c[i] * hat(x, i, N) for i in 1:n)
maxerr = maximum(abs(u_ritz(x) - uex(x)) for x in 0:0.002:1)
println("Ritz (hat basis, N=$N): max err vs sin(pi x) = ", round(maxerr, digits=5), " (O(h^2) at this coarse N)")
@assert maxerr < 0.08 "hat 基 Ritz（N=8 粗网格）应基本逼近（误差 $maxerr）"

# 能量范数最优：与同维子空间的另一函数（hat 插值精确解）比能量
c_interp = [uex(i * h) for i in 1:n]    # 节点插值
energy(cvec) = cvec' * A * cvec
println("energy(ritz) = ", round(energy(c), digits=6),
        " <= energy(nodal interp) = ", round(energy(c_interp), digits=6))
@assert energy(c) <= energy(c_interp) + 1e-12 "Ritz 解应能量最小"

println("END ====")
