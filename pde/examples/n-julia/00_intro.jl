# 00_intro.jl —— 第 00 章：对表基准与方法效率的威力（Julia 通道）
#
# 三件事：
#   (1) 三个精确解"对表"：热传导 / 波动 / 调和函数，中心差分残差随 h 的
#       收缩比应逼近 4（二阶差分算子）；
#   (2) 二次调和函数 x^2 - y^2 上五点 Laplace 算子残差恒为零（对多项式
#       精确）——"对表"函数要挑对；
#   (3) Jacobi / Gauss-Seidel / SOR 在同一五点方程上的迭代次数对比：
#       书引言"算法效率万亿倍提升"的具体而微。

println("==== 00 intro")

# ---------- (1) 三个精确解对表 ----------
u_heat(x, t) = exp(-pi^2 * t) * sin(pi * x)   # u_t = u_xx
u_wave(x, t) = sin(pi * x) * cos(pi * t)      # u_tt = u_xx（可分离模式解）
u_gen(x, t) = exp(x + t) + (x - t)^3          # u_tt = u_xx（一般 d'Alembert 解）
u_lap(x, y) = exp(x) * sin(y)                 # u_xx + u_yy = 0

# 热传导残差：中心差分 u_t - u_xx，误差主项 O(h^2)
resid_heat(h) = begin
    x, t = 0.5, 0.05
    dut = (u_heat(x, t + h) - u_heat(x, t - h)) / (2h)
    duxx = (u_heat(x + h, t) - 2 * u_heat(x, t) + u_heat(x - h, t)) / h^2
    abs(dut - duxx)
end
# 波动残差（τ = h 时可分离解上恒等相消——机器上只能看到舍入噪声）
resid_wave_canceled(h) = begin
    x, t = 0.3, 0.1
    dutt = (u_wave(x, t + h) - 2 * u_wave(x, t) + u_wave(x, t - h)) / h^2
    duxx = (u_wave(x + h, t) - 2 * u_wave(x, t) + u_wave(x - h, t)) / h^2
    abs(dutt - duxx)
end
# 波动残差（τ = h/2 打破相消，主项 (τ^2 - h^2)/12 * (F'''' + G'''') = O(h^2)）
resid_wave(h) = begin
    x, t = 0.3, 0.1
    tau = h / 2
    dutt = (u_gen(x, t + tau) - 2 * u_gen(x, t) + u_gen(x, t - tau)) / tau^2
    duxx = (u_gen(x + h, t) - 2 * u_gen(x, t) + u_gen(x - h, t)) / h^2
    abs(dutt - duxx)
end
# Laplace 残差：五点格式
resid_lap(h) = begin
    x, y = 0.2, 0.4
    du = (u_lap(x + h, y) + u_lap(x - h, y) + u_lap(x, y + h) + u_lap(x, y - h) - 4 * u_lap(x, y)) / h^2
    abs(du)
end

for (name, r) in (("heat", resid_heat), ("wave", resid_wave), ("laplace", resid_lap))
    r1, r2 = r(1.0e-1), r(5.0e-2)
    ratio = r1 / r2
    @assert 3.5 < ratio < 4.5 "残差收缩比应约 4（$name 实测 $ratio）"
    println("residual $name: h->h/2 ratio = ", round(ratio, digits=3), "  (2nd order)")
end

# τ = h 时可分离波动解的残差恒等相消（只剩舍入）
for h in (1.0e-1, 5.0e-2)
    @assert resid_wave_canceled(h) < 1.0e-9 "tau = h 时可分离解残差应恒为零"
end
println("wave residual with tau = h on separable mode: identically 0 (exact cancellation)")

# ---------- (2) 二次多项式上五点格式精确 ----------
x, y, h = 0.3, 0.7, 0.1
u2(s, t) = s^2 - t^2
lap5 = (u2(x + h, y) + u2(x - h, y) + u2(x, y + h) + u2(x, y - h) - 4 * u2(x, y)) / h^2
@assert abs(lap5) < 1.0e-13 "x^2 - y^2 上五点 Laplacian 应精确为零"
println("laplacian of x^2-y^2 via 5-point stencil: exactly 0 up to roundoff")

# ---------- (3) 迭代法效率：Jacobi / GS / SOR ----------
# 在单位正方形上解 Laplace 方程，边界值取自 u = e^x sin y。
# N 个内点，步长 hh = 1/(N+1)。
function iter_counts(N::Int; tol=1.0e-8, maxit=200000)
    hh = 1.0 / (N + 1)
    # 数组 1..N+2，网格坐标 (i-1)*hh；i in 2..N+1 为内点
    bval(i, j) = exp((i - 1) * hh) * sin((j - 1) * hh)
    f(z, t) = exp(z) * sin(t)
    u = [bval(i, j) for i in 1:N+2, j in 1:N+2]
    for i in 2:N+1, j in 2:N+1; u[i, j] = 0.0; end

    # Jacobi
    cnt_j = 0
    uj = copy(u)
    while cnt_j < maxit
        diff = 0.0
        un = copy(uj)
        for i in 2:N+1, j in 2:N+1
            un[i, j] = 0.25 * (uj[i+1, j] + uj[i-1, j] + uj[i, j+1] + uj[i, j-1])
            diff = max(diff, abs(un[i, j] - uj[i, j]))
        end
        uj .= un
        cnt_j += 1
        diff < tol && break
    end

    # Gauss-Seidel
    cnt_g = 0
    ug = copy(u)
    for i in 2:N+1, j in 2:N+1; ug[i, j] = 0.0; end
    while cnt_g < maxit
        diff = 0.0
        for j in 2:N+1, i in 2:N+1
            newv = 0.25 * (ug[i+1, j] + ug[i-1, j] + ug[i, j+1] + ug[i, j-1])
            diff = max(diff, abs(newv - ug[i, j]))
            ug[i, j] = newv
        end
        cnt_g += 1
        diff < tol && break
    end

    # SOR（最优 omega = 2 / (1 + sin(pi*hh))）
    omega = 2.0 / (1.0 + sin(pi * hh))
    cnt_s = 0
    us = copy(u)
    for i in 2:N+1, j in 2:N+1; us[i, j] = 0.0; end
    while cnt_s < maxit
        diff = 0.0
        for j in 2:N+1, i in 2:N+1
            gs = 0.25 * (us[i+1, j] + us[i-1, j] + us[i, j+1] + us[i, j-1])
            newv = us[i, j] + omega * (gs - us[i, j])
            diff = max(diff, abs(newv - us[i, j]))
            us[i, j] = newv
        end
        cnt_s += 1
        diff < tol && break
    end
    # 解的精度对账（五点格式误差 O(h^2)）
    err = maximum(abs(us[i, j] - f((i - 1) * hh, (j - 1) * hh)) for i in 2:N+1, j in 2:N+1)
    return cnt_j, cnt_g, cnt_s, err
end

cj, cg, cs, err = iter_counts(20)
println("iterations for N=20, tol=1e-8:  Jacobi = ", cj, "  GS = ", cg, "  SOR = ", cs)
@assert cs < cg < cj "SOR 应最快、Jacobi 最慢"
@assert cj / cs > 10 "SOR 相对 Jacobi 至少快一个数量级"
@assert err < 0.01 "五点格式 O(h^2) 误差应小于 0.01（h=1/21）"
println("SOR speedup vs Jacobi: ", round(cj / cs, digits=1), "x; discrete error = ", round(err, sigdigits=3))

println("END ====")
