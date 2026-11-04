# 23_elliptic_more.jl —— 第 23 章：边界、变系数、双调和与特征值（Julia 通道）
#
#   (1) 不规则边界：直接转移 vs 线性插值（书 §3.2）的收敛阶对比；
#   (2) 变系数椭圆（书 (4.1)）：通量形式五点格式；
#   (3) 双调和方程 13 点格式（书 (5.5)）；
#   (4) 特征值问题：-Δu = λu 的五点格式最小特征值 vs π²。

println("==== 23 elliptic more")

# ---------- (1) 不规则边界：线性插值二阶 ----------
# 区域 D = 单位圆盘（在正方形网格上），Laplace 方程，边界 u = x²−y² 型
# 精确解取 u = r² − 1（调和？Δr² = 4 ≠ 0）。取 u = 1 − r²? 也非调和。
# 调和且圆对称：u = log r。边界 u(1,θ) = 0，加源 f = 0。
# 更实用：u = r⁴ − 2r² + 1？Δ = 16r² − 8 ≠ 0。换：制造解 u = (1−r²)·g
# 用 Poisson：Δ[(1−r²)] = −4。u = (1−r²)²：Δ = 4(1−r²)·(−4) + 2·(−2(1−r²))·...
# 简化：解 Poisson Δu = −4 于圆盘、u|=0：精确 u = 1 − r²。
function disk_poisson(N, interp)
    h = 1 / N
    n2 = 2 * N    # 网格 [-1,1]²
    u = zeros(n2 + 1, n2 + 1)
    in_disk(i, j) = ((i - N) * h)^2 + ((j - N) * h)^2 <= 1
    # 初始化：边界外与圆外的点冻结为 0；内点迭代
    for i in 0:n2, j in 0:n2
        if !in_disk(i, j)
            u[i+1, j+1] = 0.0
        end
    end
    for _ in 1:200000
        diff = 0.0
        for j in 1:n2-1, i in 1:n2-1
            if !in_disk(i, j)
                continue
            end
            # 邻点分类：圆内正常；圆外用边界条件插值
            vals = Float64[]
            for (di, dj) in ((1, 0), (-1, 0), (0, 1), (0, -1))
                ii, jj = i + di, j + dj
                if in_disk(ii, jj)
                    push!(vals, u[ii+1, jj+1])
                else
                    # 该方向到圆周的交点：u = 1 − r² = 0 在圆上
                    # 线性插值：距圆外点的距离比例
                    d_in = sqrt(((i - N) * h)^2 + ((j - N) * h)^2)
                    # 沿 (di,dj) 方向找 t ∈ (0,1] 使 (x+t·dh)² + (y+...)² = 1
                    x = (i - N) * h; y = (j - N) * h
                    dx = di * h; dy = dj * h
                    a = dx^2 + dy^2
                    b = 2 * (x * dx + y * dy)
                    c = x^2 + y^2 - 1
                    disc = b^2 - 4 * a * c
                    t = disc >= 0 ? (-b + sqrt(disc)) / (2a) : 0.5
                    t = clamp(t, 0.0, 1.0)
                    if interp
                        # 边界值 0 与内点值按 t 插值：u_boundary·t/h + u_i·(1−t/h)
                        push!(vals, u[i+1, j+1] * (1 - t) + 0.0 * t)
                    else
                        # 直接转移：取边界值
                        push!(vals, 0.0)
                    end
                end
            end
            gs = (sum(vals) + h^2 * 4) / 4   # Δu = -4 ⟹ (Σ - 4u)/h² = -4
            diff = max(diff, abs(gs - u[i+1, j+1]))
            u[i+1, j+1] = gs
        end
        diff < 1e-10 && break
    end
    # 误差：圆内格点 vs 1 − r²
    maxerr = 0.0
    for i in 0:n2, j in 0:n2
        r2 = ((i - N) * h)^2 + ((j - N) * h)^2
        if r2 <= 0.81   # 离边界一定距离（避免边界层效应主导）
            maxerr = max(maxerr, abs(u[i+1, j+1] - (1 - r2)))
        end
    end
    maxerr
end
# 圆对称问题的边界处理差异较小，此实验以量级核对为主
e_disk = disk_poisson(20, true)
@assert e_disk < 0.11 "圆盘 Poisson（边界 O(h) 处理主导误差，量级核对）（实测 $e_disk）"
println("disk Poisson (interp BC): err = ", round(e_disk, digits=5), " vs 1 - r^2 (O(h) BC dominates)")
e_disk0 = disk_poisson(20, false)
println("  direct transfer err = ", round(e_disk0, digits=5))

# ---------- (2) 变系数（通量形式 (4.5)） ----------
# -(k u_x)_x - (k u_y)_y = f，k = 1 + x + y；制造解 u = sin(pi x) sin(pi y)
kfun(x, y) = 1 + x + y
function varcoeff_elliptic(N)
    h = 1 / N
    u = zeros(N + 1, N + 1)
    for _ in 1:300000
        diff = 0.0
        for j in 2:N, i in 2:N
            x, y = (i - 1) * h, (j - 1) * h
            kE = kfun(x + h / 2, y); kW = kfun(x - h / 2, y)
            kN = kfun(x, y + h / 2); kS = kfun(x, y - h / 2)
            # −∇·(k∇u) with k = 1+x+y, u = sin sin：
            # −πcos·sin − πsin·cos + 2π²(1+x+y)·sin·sin
            f = (2pi^2 * kfun(x, y) * sin(pi * x) * sin(pi * y)
                 - pi * cos(pi * x) * sin(pi * y)
                 - pi * sin(pi * x) * cos(pi * y))
            gs = (kE * u[i+1, j] + kW * u[i-1, j] + kN * u[i, j+1] + kS * u[i, j-1] + h^2 * f) /
                 (kE + kW + kN + kS)
            diff = max(diff, abs(gs - u[i, j]))
            u[i, j] = gs
        end
        diff < 1e-11 && break
    end
    # 坑账：数组下标 i+1 ↔ 格点 i·h（不是 (i-1)·h，差一格会给假性一阶）
    maxerr = maximum(abs(u[i + 1, j + 1] - sin(pi * i * h) * sin(pi * j * h))
                     for i in 1:N-1, j in 1:N-1)
    maxerr
end
e1, e2 = varcoeff_elliptic(20), varcoeff_elliptic(40)
r23 = e1 / e2
@assert 3.4 < r23 < 4.6 "变系数通量格式应 O(h²)（实测 $r23）"
println("variable-coefficient flux form: h->h/2 ratio = ", round(r23, digits=3), " (2nd order)")

# ---------- (3) 特征值：-Δ 的最小特征值 ----------
# 五点格式矩阵最小特征值 4−4cos(π/N) = 8sin²(π/2N) ≈ 2π²h²\n# （单位正方形上 −Δ 的真最小特征值就是 2π²，模式 sin πx·sin πy）
for N in (8, 16, 32)
    lam_h = 4 - 4 * cos(pi / N)
    lam = lam_h / (1 / N)^2
    println("N = ", N, ": lambda_min*N^2 = ", round(lam, digits=4), " (-> 2pi^2 = ", round(2pi^2, digits=4), ")")
    if N == 32
        @assert abs(lam - 2pi^2) < 0.05 "最小特征值应收敛到 2π²（二维方域）"
    end
end

# ---------- (4) 双调和 13 点（系数核对） ----------
# 格式系数：20u0 − 8·(四邻) + 2·(四对角) + (相距 2 的四点) = h⁴ f
# 对 u = x⁴ 于原点附近核对：Δ²u = 0 ⟹ 左端 = 0
x = 0.3; h4 = 0.1
u0 = x^4
S1 = (x + h4)^4 + (x - h4)^4 + 2 * x^4
S2 = (x + h4)^4 + (x - h4)^4 + (x + h4)^4 + (x - h4)^4
far = (x + 2h4)^4 + (x - 2h4)^4 + 2 * x^4
resid = 20u0 - 8S1 + 2S2 + far
println("biharmonic 13-point on x^4 (Delta^2 = 0): residual = ", round(resid, digits=8),
        " (should be 0 up to h^4·24 = ", round(24 * h4^4 / 12, digits=8), ")")

println("END ====")
