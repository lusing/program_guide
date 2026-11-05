# 19_multidim.jl —— 第 19 章：多维抛物方程的 ADI 与 LOD（Julia 通道）
#
#   (1) 二维 FTCS：稳定条件 r ≤ 1/4（比一维再严一半）——两侧数值确认；
#   (2) Peaceman–Rachford ADI（书 (5.2)）：两个三对角半步，r = 5 无条件
#       稳定且二阶收敛；
#   (3) LOD（书 (5.3)）：局部一维分裂。

println("==== 19 multidim")

function thomas(a, b, c, d)
    n = length(b)
    cp = zeros(n); dp = zeros(n)
    cp[1] = c[1] / b[1]; dp[1] = d[1] / b[1]
    for i in 2:n
        m = b[i] - a[i] * cp[i-1]
        cp[i] = c[i] / m
        dp[i] = (d[i] - a[i] * dp[i-1]) / m
    end
    x = zeros(n); x[n] = dp[n]
    for i in n-1:-1:1
        x[i] = dp[i] - cp[i] * x[i+1]
    end
    x
end

# ---------- (1) 二维 FTCS 稳定条件 r <= 1/4 ----------
function ftcs2d(r, nst)
    N = 64
    # 内点数组 2..N（下标 1..N-2），邻居通 ip/im 映射（1↔0 边界值 0 不存）
    u = [sin(pi * i / N) * sin(pi * j / N) + 1.0e-6 * ((-1.0)^(i + j)) for i in 1:N-1, j in 1:N-1]
    un = similar(u)
    ip(i) = (i == N - 1 ? 0 : i + 1)   # 0 表示边界值 0（下用 getb 取）
    im(i) = (i == 1 ? 0 : i - 1)
    getb(U, i, j) = (i == 0 || j == 0) ? 0.0 : U[i, j]
    un = similar(u)
    for _ in 1:nst
        for i in 1:N-1, j in 1:N-1
            un[i, j] = u[i, j] + r * (getb(u, i+1 > N-1 ? 0 : i+1, j) + getb(u, im(i), j)
                                       + getb(u, i, j+1 > N-1 ? 0 : j+1) + getb(u, i, im(j)) - 4u[i, j])
        end
        u .= un
        maximum(abs.(u)) > 1e6 && return 1e6
    end
    maximum(abs.(u))
end
@assert ftcs2d(0.24, 400) < 1.001 "r=0.24 ≤ 1/4 应稳定"
@assert ftcs2d(0.26, 400) > 10 "r=0.26 > 1/4 应爆"
println("2D FTCS: r=0.24 stable, r=0.26 blows (condition r <= 1/4, twice stricter than 1D)")

# ---------- (2) Peaceman-Rachford ADI ----------
function adi_err(h, rr)
    J = round(Int, 1 / h) - 1
    r = rr
    tau = r * h * h
    T = 0.1
    nst = round(Int, T / tau)
    u = [sin(pi * i * h) * sin(pi * j * h) for i in 1:J, j in 1:J]   # 边界 0
    half = similar(u)
    a = fill(-r / 2, J); b = fill(1 + r, J); c = fill(-r / 2, J)
    a[1] = 0.0; c[J] = 0.0
    for _ in 1:nst
        # 半步 1：(I - r/2 δx²)u* = (I + r/2 δx²)uⁿ —— 纯 x 方向（逐列三对弓）
        for j in 1:J
            d = zeros(J)
            for i in 1:J
                ux = (i == 1 ? 0.0 : u[i-1, j]); uw = (i == J ? 0.0 : u[i+1, j])
                d[i] = (1 - r) * u[i, j] + (r / 2) * (ux + uw)
            end
            half[:, j] .= thomas(a, b, c, d)
        end
        # 半步 2：(I - r/2 δy²)uⁿ⁺¹ = (I + r/2 δy²)u* —— 纯 y 方向（逐行）
        for i in 1:J
            d = zeros(J)
            for j in 1:J
                uy = (j == 1 ? 0.0 : half[i, j-1]); uz = (j == J ? 0.0 : half[i, j+1])
                d[j] = (1 - r) * half[i, j] + (r / 2) * (uy + uz)
            end
            u[i, :] .= thomas(a, b, c, d)
        end
    end
    tf = nst * tau
    maximum(abs.(u[i, j] - exp(-2pi^2 * tf) * sin(pi * i * h) * sin(pi * j * h)) for i in 1:J, j in 1:J)
end
# 收敛阶在适度 r=1 下测量（大 r 时 (λτ)³ 的时间误差污染测阶）
e1 = adi_err(0.05, 1.0)
e2 = adi_err(0.025, 1.0)
r19 = e1 / e2
println("PR-ADI (r=1): h->h/2 ratio = ", round(r19, digits=3))
@assert 3.4 < r19 < 4.6 "PR-ADI 应二阶（实测 $r19）"
# 无条件稳定性在 r=5（显式禁区）验证
u5err = adi_err(0.05, 5.0)
@assert u5err < 0.05 "PR-ADI r=5 应稳定收敛（误差 $u5err）"
println("PR-ADI at r=5 (explicit-forbidden zone): stable, err = ", round(u5err, digits=4))

# ---------- (3) LOD ----------
function lod_err(h)
    J = round(Int, 1 / h) - 1
    r = 5.0
    tau = r * h * h
    T = 0.2
    nst = round(Int, T / tau)
    u = [sin(pi * i * h) * sin(pi * j * h) for i in 1:J, j in 1:J]
    a = fill(-r, J); b = fill(1 + 2r, J); c = fill(-r, J)
    a[1] = 0.0; c[J] = 0.0
    for _ in 1:nst
        for j in 1:J
            u[:, j] .= thomas(a, b, c, copy(u[:, j]))
        end
        for i in 1:J
            u[i, :] .= thomas(a, b, c, copy(u[i, :]))
        end
    end
    tf = nst * tau
    maximum(abs.(u[i, j] - exp(-2pi^2 * tf) * sin(pi * i * h) * sin(pi * j * h)) for i in 1:J, j in 1:J)
end
e1 = lod_err(0.05)
e2 = lod_err(0.025)
rl = e1 / e2
println("LOD (BTCS split, r=5): err(0.05) = ", round(e1, digits=6), ", ratio = ", round(rl, digits=3))
@assert e2 < 5e-3 "LOD r=5 应稳定收敛（误差 $e2）"

println("END ====")
