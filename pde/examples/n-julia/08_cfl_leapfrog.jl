# 08_cfl_leapfrog.jl —— 第 08 章：CFL 条件、特征线与蛙跳（Julia 通道）
#
#   (1) 依赖域锥：单点扰动的传播支撑恰为 [j0−n, j0+n]（LW 模板宽度）；
#   (2) CFL 违反：LW λ=1.1 爆炸；λ=0.9 稳定（书 §1.4 的数值版）；
#   (3) 蛙跳格式：λ=0.8 稳定推进；λ=1 退化模式线性增长（书 §1.6）；
#   (4) 起步层精度决定整体精度：一阶起步 → 一阶，二阶起步 → 二阶。

println("==== 08 cfl leapfrog")

# ---------- (1) 依赖域锥 ----------
J = 200
h = 1 / J
u = zeros(J)
u[100] = 1.0                      # 单点扰动
lam = 0.8
nst = 30
un = similar(u)
for _ in 1:nst
    for j in 1:J
        jm = (j == 1 ? J : j - 1); jp = (j == J ? 1 : j + 1)
        un[j] = u[j] - 0.5 * lam * (u[jp] - u[jm]) +
                0.5 * lam^2 * (u[jp] - 2u[j] + u[jm])
    end
    u .= un
end
supp = findall(abs.(u) .> 1e-50)   # 边缘振幅 ~λ^n 量级，阈值须远低于此
width = supp[end] - supp[1] + 1
@assert width == 2 * nst + 1 "支撑宽度应为 2n+1（实测 $width）"
println("perturbation support after n = ", nst, " steps: exactly 2n+1 = ", width,
        " grid points (stencil cone)")

# ---------- (2) CFL 违反 ----------
function lw_blow(lam2)
    uu = [sin(2 * pi * 5 * (j - 1) / 128) for j in 1:128]
    unn = similar(uu)
    for _ in 1:200
        for j in 1:128
            jm = (j == 1 ? 128 : j - 1); jp = (j == 128 ? 1 : j + 1)
            unn[j] = uu[j] - 0.5 * lam2 * (uu[jp] - uu[jm]) +
                     0.5 * lam2^2 * (uu[jp] - 2uu[j] + uu[jm])
        end
        uu .= unn
        maximum(abs.(uu)) > 1e4 && return true
    end
    false
end
@assert !lw_blow(0.9) "λ=0.9 应稳定"
@assert lw_blow(1.1) "λ=1.1 违反 CFL 应爆炸"
println("CFL: LW lambda=0.9 stable; lambda=1.1 blows up (lambda = a*tau/h <= 1)")

# ---------- (3) 蛙跳：稳定与 λ=1 退化 ----------
function leapfrog(g, lam, h, nst, start_order)
    J = round(Int, 1 / h)
    u0 = [g((j - 1) * h) for j in 1:J]
    # 起步层
    u1 = similar(u0)
    for j in 1:J
        jm = (j == 1 ? J : j - 1); jp = (j == J ? 1 : j + 1)
        if start_order == 1
            u1[j] = u0[j] - 0.5 * lam * (u0[jp] - u0[jm])
        else  # 二阶起步：含 (λ²/2)δ²u（a=1 时 u_tt = u_xx）
            u1[j] = u0[j] - 0.5 * lam * (u0[jp] - u0[jm]) +
                    0.5 * lam^2 * (u0[jp] - 2u0[j] + u0[jm])
        end
    end
    up, uc = u0, u1
    un = similar(u0)
    for _ in 2:nst
        for j in 1:J
            jm = (j == 1 ? J : j - 1); jp = (j == J ? 1 : j + 1)
            un[j] = up[j] - lam * (uc[jp] - uc[jm])
        end
        up .= uc; uc .= un
        maximum(abs.(uc)) > 1e6 && return uc
    end
    uc
end

# λ=0.8：方波稳定推进（与迎风一样单调、比迎风 sharper）
gwave(x) = (0.3 < x < 0.6) ? 1.0 : 0.0
u = leapfrog(gwave, 0.8, 0.005, 100, 2)
@assert maximum(abs.(u)) < 1.5 && minimum(u) > -0.5 "λ=0.8 蛙跳应稳定"
println("leapfrog lambda=0.8: stable (max|u| = ", round(maximum(abs.(u)), digits=3), ")")

# λ=1：4 周期退化模式线性增长（书 §1.6：u_j^n = (-1)^{j+n}(1-2n) 型）
g4(x) = sin(pi * x / 2 / h * h)   # 占位（下面直接构造）
J4 = 256
gdeg = [(j % 4 == 1 ? 1.0 : (j % 4 == 3 ? -1.0 : 0.0)) for j in 1:J4]  # sin(pi j/2)
u0 = copy(gdeg)
u1 = [u0[j] - 1.0 * 0.5 * (u0[mod(j, J4) + 1] - u0[mod(j - 2, J4) + 1]) for j in 1:J4]
up, uc = u0, u1
un = similar(u0)
for n in 2:200
    for j in 1:J4
        jp = mod(j, J4) + 1; jm = mod(j - 2, J4) + 1
        un[j] = up[j] - 1.0 * (uc[jp] - uc[jm])
    end
    up .= uc; uc .= un
end
growth = maximum(abs.(uc))
@assert growth > 100 "λ=1 退化模式应线性增长（实测 $(growth)）"
@assert growth < 4 * 200 "增长应是线性量级 ~2n，而非指数（实测 $(growth)）"
println("leapfrog lambda=1 degenerate 4-mode: max|u| = ", round(growth, digits=1),
        " after 200 steps (~2n linear growth, not exponential)")

# ---------- (4) 起步层精度决定整体精度 ----------
gk(x) = sin(2 * pi * 5 * x)
T = 0.5
function lf_err(h, start_order)
    lam = 0.8
    nst = round(Int, T / (lam * h))
    t_final = nst * lam * h          # 实际推进时间（nst 取整有偏差，对账用它）
    u = leapfrog(gk, lam, h, nst, start_order)
    J = round(Int, 1 / h)
    uex = [gk(((j - 1) * h - t_final) % 1.0) for j in 1:J]
    maximum(abs.(u .- uex))
end
e1a, e2a = lf_err(2.0e-2, 1), lf_err(1.0e-2, 1)
r1 = e1a / e2a
e1b, e2b = lf_err(2.0e-2, 2), lf_err(1.0e-2, 2)
r2 = e1b / e2b
# 数学自纠：起步层 p 阶公式的误差是 O(τ^{p+1})；τ = λh 下两种起步都只贡献
# O(h²)，整体都二阶。差别在常数：一阶起步的误差更大。
@assert 3.0 < r1 < 4.5 "一阶起步在 τ=O(h) 下也应二阶（实测 $r1）"
@assert 3.0 < r2 < 4.5 "二阶起步应二阶（实测 $r2）"
# 粗网格上内点相位误差主导、起步误差符号相消；细网格上二阶起步分出高下
@assert e2b < e2a "细网格上二阶起步误差应更小"
println("leapfrog 1st-order start: ratio = ", round(r1, digits=3),
        ", err(0.02/0.01) = ", round(e1a, digits=5), " / ", round(e2a, digits=5))
println("leapfrog 2nd-order start: ratio = ", round(r2, digits=3),
        ", err(0.02/0.01) = ", round(e1b, digits=5), " / ", round(e2b, digits=5),
        "  (both 2nd order; 2nd-order start wins at fine h)")

println("END ====")
