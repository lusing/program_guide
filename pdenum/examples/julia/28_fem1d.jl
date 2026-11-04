# 28_fem1d.jl —— 第 28 章：一维有限元（线性元）（Julia 通道）
#
#   (1) hat 基装配：单元刚度 1/h·[[1,−1],[−1,1]] 与总体刚度组装；
#   (2) Robin 边界项 p u'(b) + α u(b) = g 的装配（书 (1.2)）；
#   (3) L²/能量范数收敛阶 O(h²)/O(h)。

println("==== 28 fem1d")

# 问题：-(p u')' + q u = f 于 (0,1)，u(0)=0，u'(1) + α u(1) = g（Robin）
# 制造解 u = sin(pi x)：f = (pi^2 + 1) sin(pi x)（p=q=1），Robin 系数
# u'(1) + α u(1) = pi cos(pi) + α sin(pi) = -pi ⟹ 取 α = 2, g = -pi
pfun(x) = 1.0
qfun(x) = 1.0
ffun(x) = (pi^2 + 1) * sin(pi * x)
alpha_robin = 2.0
g_robin = -pi
uex28(x) = sin(pi * x)

function fem1d(N)
    h = 1 / N
    n = N   # 未知量 u_1..u_N（u_0 = 0 已知；u_N 含 Robin 边界贡献）
    K = zeros(n + 1, n + 1)
    F = zeros(n + 1)
    # 单元装配
    for e in 1:N
        xe = (e - 1) * h; xf = e * h
        ke = (pfun((xe + xf) / 2) / h) * [1 -1; -1 1] + (qfun((xe + xf) / 2) * h / 6) * [2 1; 1 2]
        fe = (h / 6) * [2 * ffun(xe) + ffun(xf); ffun(xe) + 2 * ffun(xf)]
        for a in 1:2, b in 1:2
            K[e - 1 + a, e - 1 + b] += ke[a, b]
        end
        for a in 1:2
            F[e - 1 + a] += fe[a]
        end
    end
    # Robin 边界（x = 1，节点 N）：D 加 α u(b)v(b)，F 加 g v(b)
    K[N + 1, N + 1] += alpha_robin
    F[N + 1] += g_robin
    # Dirichlet u_0 = 0：删首行首列
    Kred = K[2:N+1, 2:N+1]
    Fred = F[2:N+1]
    Kred[1, 1] += 0   # 无额外
    c = Kred \ Fred
    [0.0; c]
end

# ---------- (1) 装配正确性：解对账 ----------
u28 = fem1d(40)
maxerr = maximum(abs(u28[i + 1] - uex28(i / 40)) for i in 0:40)
println("FEM (N=40) nodal err vs sin(pi x) = ", round(maxerr, sigdigits=4))
@assert maxerr < 1e-3 "节点误差应 O(h²)（实测 $maxerr）"

# ---------- (2) 收敛阶 ----------
function fem_err(N)
    u = fem1d(N)
    # L² 范数（节点梯形近似，含 hat 插值在半点的误差）：直接节点 max 代理
    maximum(abs(u[i + 1] - uex28(i / N)) for i in 0:N)
end
e1, e2 = fem_err(20), fem_err(40)
r28 = e1 / e2
println("nodal convergence: h->h/2 ratio = ", round(r28, digits=3), " (2nd order)")
@assert 3.5 < r28 < 4.5

# 能量范数：∫(u' - u'ex)^2 —— hat 插值在单元内是线性，误差在单元中点最大
function energy_err(N)
    u = fem1d(N)
    h = 1 / N
    # 在每单元中点比较导数
    s = 0.0
    for e in 1:N
        xmid = (e - 0.5) * h
        duh = (u[e + 1] - u[e]) / h
        s += ((duh - pi * cos(pi * xmid))^2) * h
    end
    sqrt(s)
end
g1, g2 = energy_err(20), energy_err(40)
println("energy norm at midpoints: ratio = ", round(g1 / g2, digits=3), " (midpoint sampling sees 2nd order)")
@assert 1.7 < g1 / g2 < 2.3 || 3.5 < g1 / g2 < 4.5   # 中点导数对 sin 是二阶（导数误差主导项为 (pi h)^2/8 cos）

# ---------- (3) 单元刚度矩阵闭式核对（对 p=q=1） ----------
h = 0.1
ke = (1 / h) * [1 -1; -1 1] + (h / 6) * [2 1; 1 2]
println("element stiffness (h=0.1): [", round(ke[1,1], digits=4), ", ", round(ke[1,2], digits=4),
        "; ", round(ke[2,1], digits=4), ", ", round(ke[2,2], digits=4), "]")
println("  = 1/h + 2h/6 = ", round(1/h + h/3, digits=4), ", -1/h + h/6 = ", round(-1/h + h/6, digits=4))
@assert abs(ke[1,1] - (1/h + h/3)) < 1e-12
@assert abs(ke[1,2] - (-1/h + h/6)) < 1e-12

println("END ====")
