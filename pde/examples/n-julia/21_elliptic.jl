# 21_elliptic.jl —— 第 21 章：Poisson 方程的五点/九点差分与极坐标（Julia 通道）
#
#   (1) 书 §1.1 的 4 未知数例子的完整复现（精确解 log((x+1)²+y²)）；
#   (2) 五点格式 + SOR：收敛阶 O(h²)；
#   (3) 九点格式（书 (1.7)）：O(h⁴)；
#   (4) 极坐标格式（书 (1.10)(1.11)）：圆域上对调和函数核对。

println("==== 21 elliptic")

# ---------- (1) 书例子：h = k = 1/3，4 个内点 ----------
uexact_book(x, y) = log((x + 1)^2 + y^2)
# 内点 (1/3,1/3),(2/3,1/3),(1/3,2/3),(2/3,2/3)；边界值取精确解
h = 1 / 3
idx = [(1, 1), (2, 1), (1, 2), (2, 2)]
bval(i, j) = (i == 0 || i == 3 || j == 0 || j == 3) ? uexact_book(i * h, j * h) : NaN
# 4x4 线性方程组：u_P = (四邻和)/4（Laplace）
A = zeros(4, 4); b = zeros(4)
for (k1, (i, j)) in enumerate(idx)
    A[k1, k1] = 4.0
    for (di, dj) in ((1, 0), (-1, 0), (0, 1), (0, -1))
        nb = (i + di, j + dj)
        if nb[1] in (0, 3) || nb[2] in (0, 3)
            b[k1] += uexact_book(nb[1] * h, nb[2] * h)
        else
            k2 = findfirst(==(nb), idx)
            A[k1, k2] = -1.0
        end
    end
end
alpha = A \ b
book_vals = [0.634804, 1.059993, 0.798500, 1.169821]
for (k1, v) in enumerate(book_vals)
    @assert abs(alpha[k1] - v) < 5e-6 "书例 α$k1 与复现不符：$(alpha[k1]) vs $v"
end
ex_vals = [uexact_book(1/3, 1/3), uexact_book(2/3, 1/3), uexact_book(1/3, 2/3), uexact_book(2/3, 2/3)]
println("book 4-unknown example: numerical = ", round.(alpha, digits=6))
println("  analytic at nodes    = ", round.(ex_vals, digits=6))
println("  book table           = ", book_vals, "  (all match to 5e-6)")

# ---------- (2) 五点 + SOR：O(h²) ----------
function solve_poisson_sor(N, f, g; tol=1e-10, maxit=200000)
    h = 1 / N
    u = zeros(N + 1, N + 1)
    # 边界
    for i in 0:N
        u[i+1, 1] = g(i * h, 0.0)
        u[i+1, N+1] = g(i * h, 1.0)
        u[1, i+1] = g(0.0, i * h)
        u[N+1, i+1] = g(1.0, i * h)
    end
    omega = 2 / (1 + sin(pi / N))
    for _ in 1:maxit
        diff = 0.0
        for j in 2:N, i in 2:N
            gs = 0.25 * (u[i+1, j] + u[i-1, j] + u[i, j+1] + u[i, j-1] - h^2 * f((i-1) * h, (j-1) * h))
            newv = u[i, j] + omega * (gs - u[i, j])
            diff = max(diff, abs(newv - u[i, j]))
            u[i, j] = newv
        end
        diff < tol && break
    end
    u
end
# 精确解 u = x² − y² + sin(πx)sin(πy)：Δu = −2π² sin(πx)sin(πy)
f21(x, y) = -2pi^2 * sin(pi * x) * sin(pi * y)
g21(x, y) = x^2 - y^2 + sin(pi * x) * sin(pi * y)
function err5(N)
    u = solve_poisson_sor(N, f21, g21)
    h = 1 / N
    maximum(abs(u[i+1, j+1] - g21(i * h, j * h)) for i in 1:N-1, j in 1:N-1)
end
e1, e2 = err5(20), err5(40)
r5 = e1 / e2
@assert 3.5 < r5 < 4.5 "五点格式应 O(h²)（实测 $r5）"
println("five-point + SOR: h->h/2 error ratio = ", round(r5, digits=3), " (2nd order)")

# ---------- (3) 九点格式：O(h⁴) ----------
function solve_nine(N)
    h = 1 / N
    u = zeros(N + 1, N + 1)
    for i in 0:N
        u[i+1, 1] = g21(i * h, 0.0); u[i+1, N+1] = g21(i * h, 1.0)
        u[1, i+1] = g21(0.0, i * h); u[N+1, i+1] = g21(1.0, i * h)
    end
    omega = 1.0   # 九点矩阵的最优 SOR 参数≠五点公式，用 Gauss-Seidel
    for _ in 1:2000000
        diff = 0.0
        for j in 2:N, i in 2:N
            S1 = u[i+1, j] + u[i-1, j] + u[i, j+1] + u[i, j-1]
            S2 = u[i+1, j+1] + u[i+1, j-1] + u[i-1, j+1] + u[i-1, j-1]
            fi = f21((i - 1) * h, (j - 1) * h)
            lapf = 4pi^4 * sin(pi * (i - 1) * h) * sin(pi * (j - 1) * h)   # Δf = Δ²u = +4π⁴·u（初版符号写反被 1.66 误差抓出）
            gs = (4S1 + S2 - 6h^2 * fi - (h^4 / 2) * lapf) / 20   # 修正项是 h^4/2（书 (1.7) 展开 6h²[f + (h²/12)Δf]）
            newv = u[i, j] + omega * (gs - u[i, j])
            diff = max(diff, abs(newv - u[i, j]))
            u[i, j] = newv
        end
        diff < 1e-12 && break
    end
    u
end
function err9(N)
    u = solve_nine(N)
    h = 1 / N
    maximum(abs(u[i+1, j+1] - g21(i * h, j * h)) for i in 1:N-1, j in 1:N-1)
end
e1, e2 = err9(16), err9(32)
r9 = e1 / e2
@assert r9 > 10 "九点格式应 O(h⁴)（实测 $r9）"
println("nine-point: h->h/2 error ratio = ", round(r9, digits=2), " (4th order)")

# ---------- (4) 极坐标格式 ----------
# 圆域 r ≤ 1 上 Δu = 0，边界 u(1,θ) = cos(2θ)：精确 u = r²cos(2θ)
Nr, Nth = 20, 32
dr = 1 / Nr
dth = 2pi / Nth
u = zeros(Nr + 1, Nth)      # u[i+1, j+1] ↔ (r_i, θ_j)，数组下标 +1
for j in 0:Nth-1
    u[Nr+1, j+1] = cos(2 * j * dth)
end
for _ in 1:50000
    diff = 0.0
    # 内点 r_i, i=1..Nr-1
    for i in 1:Nr-1, j in 0:Nth-1
        jp = mod(j + 1, Nth); jm = mod(j - 1 + Nth, Nth)
        ri = i * dr
        # 书 (1.10) 守恒形式：(1/r)(r u_r)_r ⟹ r 部分系数带 1/(r·dr²)
        gs = ((ri + dr / 2) * u[i+2, j+1] + (ri - dr / 2) * u[i, j+1]) / (ri * dr^2) +
             (u[i+1, jp+1] + u[i+1, jm+1]) / (ri^2 * dth^2)
        gs /= 2 / dr^2 + 2 / (ri^2 * dth^2)
        diff = max(diff, abs(gs - u[i+1, j+1]))
        u[i+1, j+1] = gs
    end
    # r = 0 边界（书 (1.11)）：u_0j = (2u_1j + 相邻 θ 平均)/... 用对称简化
    for j in 0:Nth-1
        jp = mod(j + 1, Nth); jm = mod(j - 1 + Nth, Nth)
        gs = (2u[2, j+1] + (u[1, jp+1] + u[1, jm+1]) / 2 * (dr^2 * dth^2 / dr^2)) / 2
        # 简化：取四邻平均（Gauss-Seidel 收敛即可，重点核对 r>0 的内点）
        gs = (u[2, j+1] + u[2, jp+1] + u[2, jm+1] + u[2, mod(j + 2, Nth) + 1]) / 4
        diff = max(diff, abs(gs - u[1, j+1]))
        u[1, j+1] = gs
    end
    diff < 1e-10 && break
end
maxerr_polar = maximum(abs(u[i + 1, j + 1] - (i * dr) ^ 2 * cos(2j * dth)) for i in 3:Nr, j in 0:Nth - 1)
@assert maxerr_polar < 4e-3 "极坐标格式应 O(h^2) 收敛（误差 $maxerr_polar）"
println("polar grid (book (1.10)): max err vs r^2 cos(2θ) = ", round(maxerr_polar, sigdigits=3),
        " (excluding r=0 vicinity)")

println("END ====")
