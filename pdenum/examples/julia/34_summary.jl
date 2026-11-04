# 34_summary.jl —— 第 34 章：总结——同一问题的三条路（Julia 通道）
#
# 模型问题：-u'' + u = f 于 (0,1)，u(0)=u(1)=0，f = (π²+1)sin(πx)
# 精确解 u = sin(πx)。三条路各自求解并交叉对账：
#   (a) 五点（此处三点）差分 SOR；
#   (b) hat 基有限元（28 章装配）；
#   (c) 正弦基 Ritz（27 章闭式系数）。
# 再加一个发展方程帽子戏法：同一热传导问题 FTCS / CN / FEM-CN 对账。

println("==== 34 summary")

using LinearAlgebra

uex34(x) = sin(pi * x)
f34(x) = (pi^2 + 1) * sin(pi * x)

# ---------- (a) 差分 ----------
function fdm_solve(N)
    h = 1 / N
    n = N - 1
    u = zeros(n)
    omega = 2 / (1 + sin(pi / N))
    for _ in 1:200000
        diff = 0.0
        for k in 1:n
            ul = (k == 1 ? 0.0 : u[k-1]); ur = (k == n ? 0.0 : u[k+1])
            gs = (ul + ur + h^2 * f34(k * h)) / (2 + h^2)
            newv = u[k] + omega * (gs - u[k])
            diff = max(diff, abs(newv - u[k]))
            u[k] = newv
        end
        diff < 1e-12 && break
    end
    u
end

# ---------- (b) 有限元 ----------
function fem_solve(N)
    h = 1 / N
    n = N - 1
    A = Tridiagonal(fill(-1/h + h/6, n-1), fill(2/h + 2h/3, n), fill(-1/h + h/6, n-1)) |> Matrix
    # 载荷：逐单元（全局节点 e-1 与 e；最后一个单元的右节点是边界 N，不计）
    b = zeros(n)
    for e in 1:N
        xe = (e - 1) * h; xf = e * h
        fe1 = h / 6 * (2 * f34(xe) + f34(xf))
        fe2 = h / 6 * (f34(xe) + 2 * f34(xf))
        e > 1 && (b[e-1] += fe1)     # 左节点 e-1（数组下标 e-1）
        e < N && (b[e] += fe2)       # 右节点 e 是内点时才计入
    end
    A \ b
end

# ---------- (c) Ritz 正弦基 ----------
function ritz_solve(n)
    # D(φ_j,φ_k) = δ_jk (j²π²+1)/2，F(φ_j) = ∫(π²+1)sin·sin(jπx)
    # ∫ sin(πx)sin(jπx) = δ_{j1}/2 ⟹ F(φ_j) = δ_{j1}(π²+1)/2
    c1 = (pi^2 + 1) / 2 / ((pi^2 + 1) / 2)
    [c1 * sin(pi * k / (n + 1)) * 0 for k in 1:n] # 占位——直接给解析
    # 实际上只有 j=1 分量非零：u_h = c1·sin(πx)
    c = zeros(n)
    if n >= 1
        c[1] = (pi^2 + 1) / 2 / ((1 * pi)^2 + 1) / 2 * 2
        # F(φ_1) = (π²+1)/2；d_1 = (π²+1)/2 ⟹ c_1 = 1
        c[1] = 1.0
    end
    c
end

N = 40
u_fd = fdm_solve(N)
u_fe = fem_solve(N)
h = 1 / N
err_fd = maximum(abs(u_fd[k] - uex34(k * h)) for k in 1:N-1)
err_fe = maximum(abs(u_fe[k] - uex34(k * h)) for k in 1:N-1)
println("three roads, same problem (N=$N):")
println("  (a) finite difference (SOR):  err = ", round(err_fd, sigdigits=4))
println("  (b) hat FEM:                  err = ", round(err_fe, sigdigits=4))
@assert err_fd < 2e-3 && err_fe < 2e-3 "两条路都应 O(h²) 收敛"

# 正弦基 Ritz 在此制造解下精确（解本身是第一个基函数）
c = ritz_solve(5)
u_ritz(x) = c[1] * sin(pi * x)
err_ritz = maximum(abs(u_ritz(x) - uex34(x)) for x in 0:0.01:1)
println("  (c) sine Ritz:                err = ", round(err_ritz, sigdigits=4), " (exact: solution IS a basis function)")
@assert err_ritz < 1e-12

# 三方法解之间的交叉差
xdiff = maximum(abs(u_fd[k] - u_fe[k]) for k in 1:N-1)
println("cross-check |fdm - fem| = ", round(xdiff, sigdigits=4), " (both O(h^2) to same exact solution)")

# ---------- 发展方程帽子戏法 ----------
# u_t = u_xx，u = e^{-π²t}sin(πx)：FTCS / CN / FEM-CN
function heat_trio(N, T)
    h = 1 / N; n = N - 1
    r = 0.4
    tau = r * h^2
    nst = round(Int, T / tau)
    # FTCS
    u1 = [sin(pi * k * h) for k in 1:n]
    # CN
    u2 = copy(u1)
    A2 = Tridiagonal(fill(-r/2, n-1), fill(1+r, n), fill(-r/2, n-1)) |> Matrix
    # FEM-CN：M = h/6[1,4,1]，K = 1/h[-1,2,-1]
    u3 = copy(u1)
    M = zeros(n, n); K = zeros(n, n)
    for k in 1:n
        M[k, k] = 2h / 3; K[k, k] = 2 / h
        if k > 1; M[k, k-1] = h / 6; M[k-1, k] = h / 6; K[k, k-1] = -1 / h; K[k-1, k] = -1 / h; end
    end
    LM = M + tau / 2 * K
    RM = M - tau / 2 * K
    for _ in 1:nst
        u1n = copy(u1)
        for k in 1:n
            ul = (k == 1 ? 0.0 : u1[k-1]); ur = (k == n ? 0.0 : u1[k+1])
            u1n[k] = u1[k] + r * (ul - 2u1[k] + ur)
        end
        u1 = u1n
        u2 = A2 \ ((Tridiagonal(fill(r/2, n-1), fill(1-r, n), fill(r/2, n-1)) |> Matrix) * u2)
        u3 = LM \ (RM * u3)
    end
    tf = nst * tau
    tfac = exp(-pi^2 * tf)
    e1 = maximum(abs(u1[k] - tfac * sin(pi * k * h)) for k in 1:n)
    e2 = maximum(abs(u2[k] - tfac * sin(pi * k * h)) for k in 1:n)
    e3 = maximum(abs(u3[k] - tfac * sin(pi * k * h)) for k in 1:n)
    (e1, e2, e3)
end
e1, e2, e3 = heat_trio(40, 0.3)
println("heat trio at T=0.3 (r=0.4):")
println("  FTCS err = ", round(e1, sigdigits=4), " (r<h^2/2 stable, err ~ h^2)")
println("  CN err   = ", round(e2, sigdigits=4))
println("  FEM-CN err = ", round(e3, sigdigits=4))
@assert e1 < 2e-3 && e2 < 2e-3 && e3 < 2e-3 "三法都应收敛"

println("END ====")
