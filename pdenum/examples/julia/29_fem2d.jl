# 29_fem2d.jl —— 第 29 章：二维三角形线性元（Julia 通道）
#
#   (1) 单元剖分：单位正方形一致三角化（每矩形两三角形）；
#   (2) 单元刚度：面积坐标下 b_i = y_j − y_k、c_i = x_k − x_j，
#       k^e = (b bᵀ + c cᵀ)/(4A)；
#   (3) Poisson 第一边值求解 + 收敛阶。

println("==== 29 fem2d")

# Poisson：-Δu = f，u = 0 边界；f = 2π² sin(πx) sin(πy)；解 u = sin sin
f29(x, y) = 2pi^2 * sin(pi * x) * sin(pi * y)
uex29(x, y) = sin(pi * x) * sin(pi * y)

"""生成一致三角化：节点 (i,j) 全网格，每矩形 [i,i+1]x[j,j+1] 分两三角形。"""
function mesh_square(N)
    nodes = [(i / N, j / N) for j in 0:N for i in 0:N]   # 节点编号 = j*(N+1)+i+1
    node_id(i, j) = j * (N + 1) + i + 1
    elems = Tuple{Int,Int,Int}[]
    for j in 0:N-1, i in 0:N-1
        n1 = node_id(i, j); n2 = node_id(i + 1, j)
        n3 = node_id(i + 1, j + 1); n4 = node_id(i, j + 1)
        push!(elems, (n1, n2, n3))
        push!(elems, (n1, n3, n4))
    end
    nodes, elems
end

function fem2d_solve(N)
    nodes, elems = mesh_square(N)
    nn = length(nodes)
    h = 1 / N
    # 装配（稠密演示；N 小）
    K = zeros(nn, nn)
    F = zeros(nn)
    for (n1, n2, n3) in elems
        x1, y1 = nodes[n1]; x2, y2 = nodes[n2]; x3, y3 = nodes[n3]
        # 面积坐标系数
        b1 = y2 - y3; b2 = y3 - y1; b3 = y1 - y2
        c1 = x3 - x2; c2 = x1 - x3; c3 = x2 - x1
        A2 = x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2)   # 2×面积
        ke = zeros(3, 3)
        for a in 1:3, b in 1:3
            ba = (a == 1 ? b1 : a == 2 ? b2 : b3)
            ca = (a == 1 ? c1 : a == 2 ? c2 : c3)
            bb = (b == 1 ? b1 : b == 2 ? b2 : b3)
            cb = (b == 1 ? c1 : b == 2 ? c2 : c3)
            ke[a, b] = (ba * bb + ca * cb) / (4 * (A2 / 2))
        end
        ns = (n1, n2, n3)
        # 载荷：顶点贡献 A/3·f(重心)
        xm = (x1 + x2 + x3) / 3; ym = (y1 + y2 + y3) / 3
        area = A2 / 2
        for a in 1:3
            F[ns[a]] += area / 3 * f29(xm, ym)
            for b in 1:3
                K[ns[a], ns[b]] += ke[a, b]
            end
        end
    end
    # Dirichlet：边界节点直接置值（罚 1e20 技巧或划行划列——这里划）
    is_boundary(i) = begin
        (x, y) = nodes[i]
        x ≈ 0.0 || x ≈ 1.0 || y ≈ 0.0 || y ≈ 1.0
    end
    free = [i for i in 1:nn if !is_boundary(i)]
    Kff = K[free, free]
    Ff = F[free]
    c = Kff \ Ff
    u = zeros(nn)
    u[free] = c
    u
end

function fem2d_err(N)
    u = fem2d_solve(N)
    nodes, _ = mesh_square(N)
    maximum(abs(u[i] - uex29(nodes[i][1], nodes[i][2])) for i in 1:length(nodes))
end

e1 = fem2d_err(8)
e2 = fem2d_err(16)
r29 = e1 / e2
println("P1 triangle FEM on unit square: err(8) = ", round(e1, sigdigits=4),
        ", err(16) = ", round(e2, sigdigits=4))
println("  h->h/2 ratio = ", round(r29, digits=3), " (2nd order at nodes)")
@assert r29 > 3.0 "线性元节点误差应约二阶（实测 $r29）"

# 单元刚度闭式核对：直角三角形（0,0),(1,0),(0,1) 面积 1/2
# b = (y2-y3, y3-y1, y1-y2) = (-1, 1, 0); c = (x3-x2, x1-x3, x2-x1) = (-1, 0, 1)
# ke = (bb + cc)/(4A) with 4A = 2: ke = [[1, -1/2? ...]] 直接算
ke_ref = zeros(3, 3)
b = (-1.0, 1.0, 0.0); c = (-1.0, 0.0, 1.0)
for a in 1:3, bb in 1:3
    ke_ref[a, bb] = (b[a] * b[bb] + c[a] * c[bb]) / 2
end
println("unit right triangle stiffness: [", round.(ke_ref[1, :], digits=4), "; ",
        round.(ke_ref[2, :], digits=4), "; ", round.(ke_ref[3, :], digits=4), "]")
println("  (row 1 = [1, -0.5, -0.5]: centroid load A/3 each vertex)")

println("END ====")
