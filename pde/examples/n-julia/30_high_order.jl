# 30_high_order.jl —— 第 30 章：高次插值与等参元（Julia 通道）
#
#   (1) 一维二次元（Lagrange）：三节点单元 [x1, x2, x3]，节点基
#       （端点 + 中点），装配与 O(h³) 收敛；
#   (2) 矩形双线性元：张量积基，单元刚度 = (1/3)[[2,-1,-1/2? ...]]
#       书 (3.3.1) 双线性插值；
#   (3) 面积坐标规则核对（三角形二次元 6 节点：顶点 + 边中点）。

println("==== 30 high order")

# ---------- (1) 一维二次元 ----------
# 问题同 28：-(u'') + u = f（p=q=1），u(0)=0，u'(1)+2u(1)=-π
ffun(x) = (pi^2 + 1) * sin(pi * x)
uex30(x) = sin(pi * x)

function fem1d_quadratic(N)
    # 每单元 3 节点：x_{e-1}, 中点, x_e；单元长度 h = 1/N
    h = 1 / N
    # 总节点：单元端点 N+1 个 + 中点 N 个 = 2N+1
    # 编号：端点 i ↔ 节点 2i+1（数组下标），中点 i ↔ 2i+2
    nn = 2 * N + 1
    K = zeros(nn, nn)
    F = zeros(nn)
    xnode(k) = (k == 1 ? 0.0 : (iseven(k) ? (k ÷ 2 - 1) * h + h / 2 : (k ÷ 2) * h))
    for e in 1:N
        x1 = (e - 1) * h; x2 = (e - 1) * h + h / 2; x3 = e * h
        n1 = 2 * (e - 1) + 1; n2 = 2 * (e - 1) + 2; n3 = 2 * e + 1
        # 参考单元 [-1,1] 上的二次 Lagrange 基：L1 = ξ(ξ-1)/2, L2 = 1-ξ², L3 = ξ(ξ+1)/2
        # ∫L_i'L_j' dξ * (2/h)（Jacobi = h/2）与 ∫L_i L_j dξ * (h/2)
        # 闭式（参考元）：
        ke = [ 7/6  -4/3  1/6;
              -4/3   8/3 -4/3;
               1/6  -4/3  7/6] / h + (h / 30) * [4 2 -1; 2 16 2; -1 2 4] / 2
        # 修正：刚度 = (2/h)·∫L'L'，即除以 h 后系数 ... 直接用参考元数值积分更稳
        ke = zeros(3, 3)
        me = zeros(3, 3)
        for i in 1:3, j in 1:3
            Li(xi) = (i == 1 ? xi * (xi - 1) / 2 : i == 2 ? 1 - xi^2 : xi * (xi + 1) / 2)
            dLi(xi) = (i == 1 ? (2xi - 1) / 2 : i == 2 ? -2xi : (2xi + 1) / 2)
            Lj(xi) = (j == 1 ? xi * (xi - 1) / 2 : j == 2 ? 1 - xi^2 : xi * (xi + 1) / 2)
            dLj(xi) = (j == 1 ? (2xi - 1) / 2 : j == 2 ? -2xi : (2xi + 1) / 2)
            # 刚度：(2/h)∫_{-1}^1 L_i'L_j' dξ（+质量 (h/2)∫L_iL_j·q）
            ke[i, j] = 0.0
            me[i, j] = 0.0
            for k in 0:200
                xi = -1 + 2k / 200
                w = (k == 0 || k == 200) ? 1 : (k % 2 == 1 ? 4 : 2)
                ke[i, j] += w * dLi(xi) * dLj(xi)
                me[i, j] += w * Li(xi) * Lj(xi)
            end
            ke[i, j] *= (2 / 200 / 3) * (2 / h)
            me[i, j] *= (2 / 200 / 3) * (h / 2)
        end
        ns = (n1, n2, n3)
        xs = (x1, x2, x3)
        for a in 1:3
            # 载荷：(h/2)∫f·L_a（Simpson 于参考元）
            fa = 0.0
            for k in 0:200
                xi = -1 + 2k / 200
                w = (k == 0 || k == 200) ? 1 : (k % 2 == 1 ? 4 : 2)
                La(xi) = (a == 1 ? xi * (xi - 1) / 2 : a == 2 ? 1 - xi^2 : xi * (xi + 1) / 2)
                xphys = xs[1] + (xi + 1) / 2 * h
                fa += w * ffun(xphys) * La(xi)
            end
            F[ns[a]] += fa * (2 / 200 / 3) * (h / 2)
            for b in 1:3
                K[ns[a], ns[b]] += ke[a, b] + me[a, b]
            end
        end
    end
    # Robin at x=1（最后一个端点节点 nn）
    K[nn, nn] += 2.0
    F[nn] += -pi
    # Dirichlet u(0)=0：节点 1 划去
    Kred = K[2:nn, 2:nn]
    Fred = F[2:nn]
    c = Kred \ Fred
    u = zeros(nn)
    u[2:nn] = c
    u
end

function quad_err(N)
    u = fem1d_quadratic(N)
    h = 1 / N
    maxerr = 0.0
    # 全部节点位置对账
    for k in 1:2 * N + 1
        x = (k == 1 ? 0.0 : (iseven(k) ? (k ÷ 2 - 1) * h + h / 2 : (k ÷ 2) * h))
        maxerr = max(maxerr, abs(u[k] - uex30(x)))
    end
    maxerr
end
e1 = quad_err(5)
e2 = quad_err(10)
r30 = e1 / e2
println("quadratic FEM: err(5) = ", round(e1, sigdigits=4), ", err(10) = ", round(e2, sigdigits=4))
println("  h->h/2 ratio = ", round(r30, digits=2), " (cubic at nodes)")
@assert r30 > 6 "二次元节点误差应约 O(h³)（实测比 $r30）"

# ---------- (2) 双线性矩形元（系数表核对） ----------
# 参考正方形 [-1,1]²，双线性基 N1=(1-ξ)(1-η)/4 等
# ∫∫∇Ni·∇Nj 给出（除以边长后）的经典 4x4：
bilin = [ 2/3 -1/6 -1/3 -1/6;
         -1/6  2/3 -1/6 -1/3;
         -1/3 -1/6  2/3 -1/6;
         -1/6 -1/3 -1/6  2/3]
println("bilinear quad element stiffness row1 = ", round.(bilin[1, :], digits=4))

# ---------- (3) 面积坐标（三角形二次元节点表） ----------
# 6 节点：3 顶点 (L_i=1) + 3 边中点 (L_i=L_j=1/2)
println("area coordinates: L1+L2+L3 = 1 everywhere; vertex i has L_i=1,")
println("  edge midpoints have L_i = L_j = 1/2 — quadratic basis has 6 dofs")

println("END ====")
