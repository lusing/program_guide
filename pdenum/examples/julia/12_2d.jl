# 12_2d.jl —— 第 12 章：二维问题与分数步长法（Julia 通道）
#
#   (1) 二维 LF 格式 (6.3)：稳定条件 λ²(a²+b²) ≤ 1/2（a=b=1 时 λ ≤ 1/2，
#       比一维严一倍）——λ=0.45 稳、λ=0.55 爆；
#   (2) 分数步长法（LOD）：x、y 方向各用一维 LW (6.5)(6.6)——
#       稳定条件回到 |a|λ ≤ 1 且 |b|λ ≤ 1：λ=0.8（二维 LF 早已爆）稳定
#       且对角平移问题二阶收敛；
#   (3) 二维 Crank–Nicolson (6.17) 的增长因子 |G| = 1（公式扫描，无条件稳定）。

println("==== 12 2d")

# ---------- (1) 二维 LF ----------
function lf2d_run(lam, nst)
    N = 64
    h = 1 / N
    # 高斯脉冲 + 微小 4 周期乘积模式种子：增长峰在 θ₁=θ₂=π/2（|G| = 2λ），
    # 纯光滑数据激发不出它，须显式播种（舍入迟早也会注入同形态噪声）
    u = [(exp(-100 * ((i - 1) * h - 0.5)^2 - 100 * ((j - 1) * h - 0.5)^2)
          + 1.0e-8 * sin(pi * (i - 1) / 2) * sin(pi * (j - 1) / 2))
         for i in 1:N, j in 1:N]
    un = similar(u)
    for _ in 1:nst
        for j in 1:N, i in 1:N
            im = (i == 1 ? N : i - 1); ip = (i == N ? 1 : i + 1)
            jm = (j == 1 ? N : j - 1); jp = (j == N ? 1 : j + 1)
            un[i, j] = 0.25 * (u[ip, j] + u[im, j] + u[i, jp] + u[i, jm]) -
                       0.5 * lam * (u[ip, j] - u[im, j]) -
                       0.5 * lam * (u[i, jp] - u[i, jm])
        end
        u .= un
        maximum(abs.(u)) > 1e6 && return 1e6
    end
    maximum(abs.(u))
end

@assert lf2d_run(0.45, 300) < 1.001 "二维 LF λ=0.45（λ²·2 < 1/2）应稳定"
println("2D LF lam=0.45: stable (max|u| = ", round(lf2d_run(0.45, 300), digits=4), ")")
@assert lf2d_run(0.55, 300) > 10 "二维 LF λ=0.55（λ²·2 > 1/2，|G|=2λ>1）应爆"
println("2D LF lam=0.55: unstable (max|u| = ", round(lf2d_run(0.55, 300), digits=3), ")")

# ---------- (2) 分数步长法（LOD：x 向一维 LW，再 y 向一维 LW） ----------
function lod_lw2d(lam, h, T)
    N = round(Int, 1 / h)
    nst = round(Int, T / (lam * h))
    u = [exp(-100 * ((i - 1) * h - 0.5)^2 - 100 * ((j - 1) * h - 0.5)^2)
         for i in 1:N, j in 1:N]
    half = similar(u)
    for _ in 1:nst
        # 第一步：x 方向 LW
        for j in 1:N, i in 1:N
            im = (i == 1 ? N : i - 1); ip = (i == N ? 1 : i + 1)
            half[i, j] = u[i, j] - 0.5 * lam * (u[ip, j] - u[im, j]) +
                         0.5 * lam^2 * (u[ip, j] - 2u[i, j] + u[im, j])
        end
        # 第二步：y 方向 LW
        for j in 1:N, i in 1:N
            jm = (j == 1 ? N : j - 1); jp = (j == N ? 1 : j + 1)
            u[i, j] = half[i, j] - 0.5 * lam * (half[i, jp] - half[i, jm]) +
                      0.5 * lam^2 * (half[i, jp] - 2half[i, j] + half[i, jm])
        end
    end
    u
end

# 最近周期距离（坑账：% 回绕会选错周期像，Julia 负数 % 保号只是侥幸蒙对）
periodic_dist(d) = d - round(d)

function lod_err(h)
    lam, T = 0.8, 0.25
    nst = round(Int, T / (lam * h))
    tf = nst * lam * h
    N = round(Int, 1 / h)
    u = lod_lw2d(lam, h, T)
    uex = [exp(-100 * periodic_dist((i - 1) * h - 0.5 - tf)^2
               - 100 * periodic_dist((j - 1) * h - 0.5 - tf)^2)
           for i in 1:N, j in 1:N]
    maximum(abs.(u .- uex))
end

u08 = lod_lw2d(0.8, 0.02, 0.25)
@assert maximum(abs.(u08)) < 1.01 "LOD λ=0.8（二维 LF 的禁区 λ>1/2）应稳定"
println("LOD-LW lam=0.8 (2D-LF-forbidden zone lambda>1/2): stable, max|u| = ",
        round(maximum(abs.(u08)), digits=4))
e1 = lod_err(2.0e-2)
e2 = lod_err(1.0e-2)
r = e1 / e2
@assert 3.2 < r < 4.6 "LOD-LW 应二阶（实测比 $r）"
println("LOD-LW convergence: h->h/2 error ratio = ", round(r, digits=3), " (2nd order)")

# ---------- (3) 二维 CN 增长因子（公式扫描） ----------
maxdev = maximum(abs(abs((1 - 0.5im * lam * sin(th1)) / (1 + 0.5im * lam * sin(th1))) *
                     abs((1 - 0.5im * lam * sin(th2)) / (1 + 0.5im * lam * sin(th2))) - 1.0)
                 for th1 in 0.05:0.1:3.1, th2 in 0.05:0.1:3.1, lam in (0.5, 2.0, 10.0))
@assert maxdev < 1.0e-12 "二维 CN 的 |G| 应恒等于 1"
println("2D Crank-Nicolson: |G| = 1 over theta1 x theta2 x lambda scan (unconditionally stable)")

println("END ====")
