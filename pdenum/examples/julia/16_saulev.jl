# 16_saulev.jl —— 第 16 章：边界处理、Saul'ev 算法与分组显式（Julia 通道）
#
#   (1) 边界处理对内部解的全局影响（书例 2.2 的精神）：Neumann 左边界
#       用一阶单侧差 vs 二阶对称处理，同一 FTCS 内点，整体精度对比；
#   (2) Saul'ev 算法（书 (2.16)(2.17)）：左右交替扫描的半隐格式，
#       r = 5 无条件稳定、不解线性方程组；
#   (3) 分组显式 GE（书 (2.19)(2.20)）：成对显式更新，适合并行。

println("==== 16 saulev")

# ---------- (1) Neumann 边界的一阶/二阶处理 ----------
# 问题：u_t = u_xx, u(x,0) = cos(pi x/2), u_x(0,t) = 0, u(1,t) = 0
# 精确解：e^{-pi^2 t/4} cos(pi x/2)。
function neumann_bc_err(J, order)
    h = 1 / J
    r = 0.45
    tau = r * h * h
    nst = round(Int, 0.5 / tau)
    u = [cos(pi * j * h / 2) for j in 0:J]
    for _ in 1:nst
        un = similar(u)
        for j in 2:J
            un[j] = u[j] + r * (u[j-1] - 2u[j] + u[j+1])
        end
        if order == 1
            # 一阶（书 (2.5) 型）：前差 u_1 - u_0 = 0 ⟹ 直接转移 u_0^{n+1} = u_1^{n+1}
            un[1] = un[2]
        else
            # 二阶（书 (2.9) 型）：对称差 u_1 - u_{-1} = 0 ⟹ u_{-1} = u_1 消虚拟点，
            # 边界点用内点格式：u_0^{n+1} = u_0 + r(2u_1 - 2u_0)
            un[1] = u[1] + r * (2u[2] - 2u[1])
        end
        un[J+1] = 0.0     # Dirichlet 直接转移 (2.2)
        u = un
    end
    tf = nst * tau
    maximum(abs.(u[j+1] - exp(-pi^2 * tf / 4) * cos(pi * j * h / 2)) for j in 0:J)
end

e20a = neumann_bc_err(20, 1)
e40a = neumann_bc_err(40, 1)
e20b = neumann_bc_err(20, 2)
e40b = neumann_bc_err(40, 2)
println("1st-order BC: err(J=20) = ", round(e20a, digits=5), ", err(J=40) = ", round(e40a, digits=5))
println("2nd-order BC: err(J=20) = ", round(e20b, digits=5), ", err(J=40) = ", round(e40b, digits=5))
@assert e40b < e40a "二阶边界处理应更精确（同 FTCS 内点）"
println("boundary treatment matters globally: 2nd-order BC err/1st-order err = ",
        round(e40b / e40a, digits=3))

# ---------- (2) Saul'ev ----------
function saulev(r, h, T)
    J = round(Int, 1 / h)
    tau = r * h * h
    nst = round(Int, T / tau)
    u = [sin(pi * j * h) for j in 0:J]
    for n in 1:nst
        un = similar(u)
        un[1] = 0.0; un[J+1] = 0.0
        if n % 2 == 1
            # (2.16) 从左向右：-r u_{j-1}^{n+1} + (1+r)u_j^{n+1} = (1-r)u_j^n + r u_{j+1}^n
            for j in 1:J-1
                un[j+1] = ((1 - r) * u[j+1] + r * u[j+2] + r * un[j]) / (1 + r)
            end
        else
            # (2.17) 从右向左：(1+r)u_j^{n+1} - r u_{j+1}^{n+1} = (1-r)u_j^n + r u_{j-1}^n
            for j in J-1:-1:1
                un[j+1] = ((1 - r) * u[j+1] + r * u[j] + r * un[j+2]) / (1 + r)
            end
        end
        u = un
    end
    u, nst * tau
end
us, tfs = saulev(5.0, 0.01, 0.4)
errs = maximum(abs.(us[j+1] - exp(-pi^2 * tfs) * sin(pi * j * 0.01)) for j in 0:100)
@assert errs < 0.03 "Saul'ev r=5 应稳定（误差 $errs）"
println("Saul'ev r=5 (sweeps, no linear systems): err = ", round(errs, digits=5),
        " (unconditionally stable)")

# ---------- (3) 分组显式 GE ----------
function ge(r, h, T)
    J = round(Int, 1 / h)
    tau = r * h * h
    nst = round(Int, T / tau)
    u = [sin(pi * j * h) for j in 0:J]
    for _ in 1:nst
        un = similar(u)
        un[1] = 0.0; un[J+1] = 0.0
        j = 1
        while j + 3 <= J + 1
            # 组 (j+1, j+2)：书 (2.19)(2.20)，分母 1+2r
            a = u[j]; b = u[j+1]; cc = u[j+2]; d = u[j+3]
            un[j+1] = (r * (1 + r) * a + (1 - r ^ 2) * b + r * (1 - r) * cc + r ^ 2 * d) / (1 + 2 * r)
            un[j+2] = (r ^ 2 * a + r * (1 - r) * b + (1 - r ^ 2) * cc + r * (1 + r) * d) / (1 + 2 * r)
            j += 2
        end
        if j <= J   # 剩余单点：Saul'ev 单点式
            un[j+1] = ((1 - r) * u[j+1] + r * u[j] + r * u[j+2]) / (1 + r)
        end
        u = un
    end
    u, nst * tau
end
ug, tfg = ge(0.45, 0.01, 0.4)
errg = maximum(abs.(ug[j+1] - exp(-pi^2 * tfg) * sin(pi * j * 0.01)) for j in 0:100)
@assert errg < 0.02 "GE r=0.45 应稳定（误差 $errg）"
println("GE r=0.45 (grouped explicit, parallel-friendly): err = ", round(errg, digits=5))

println("END ====")
