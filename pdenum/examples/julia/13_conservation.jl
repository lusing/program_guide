# 13_conservation.jl —— 第 13 章：守恒律与守恒型差分格式（Julia 通道）
#
#   (1) Burgers 激波 Riemann 问题（u_L=1, u_R=0）：Rankine–Hugoniot
#       给激波速度 s = (f(u_L)−f(u_R))/(u_L−u_R) = 1/2；
#       守恒型 LF 与守恒型 LW 都以正确速度行进；非守恒离散
#       （u_t = −u·D u 的迎风）给出错误速度；
#   (2) 稀疏波（u_L=−1, u_R=1）：熵解 u = x/t（|x|<t）；LF 收敛到稀疏波；
#   (3) 熵条件判据 a(u_L) ≥ s ≥ a(u_R)（特征走向间断）的数值表现。

println("==== 13 conservation")

flux(u) = 0.5 * u^2          # Burgers 守恒律 u_t + f(u)_x = 0

# ---------- 守恒型格式（周期域，网格比 λ = τ/h） ----------
function conservative_scheme(kind, uL, uR, lam, h, T)
    J = 512
    nst = round(Int, T / (lam * h))
    u = [((j - 1) * h < 0.5 ? uL : uR) for j in 1:J]   # 间断在 x=0.5
    un = similar(u)
    for _ in 1:nst
        for j in 1:J
            jp = (j == J ? 1 : j + 1); jm = (j == 1 ? J : j - 1)
            if kind == :lf
                # Lax-Friedrichs：u^{n+1} = ½(u_+ + u_-) − (λ/2)(f(u_+) − f(u_-))
                un[j] = 0.5 * (u[jp] + u[jm]) - 0.5 * lam * (flux(u[jp]) - flux(u[jm]))
            elseif kind == :lw
                # Lax-Wendroff（守恒形式）：
                # u_{j+1/2} = ½(u_j+u_{j+1}) − (λ/2)(f(u_{j+1})−f(u_j))；两次半步通量
                uhalf_r = 0.5 * (u[j] + u[jp]) - 0.5 * lam * (flux(u[jp]) - flux(u[j]))
                uhalf_l = 0.5 * (u[jm] + u[j]) - 0.5 * lam * (flux(u[j]) - flux(u[jm]))
                un[j] = u[j] - lam * (flux(uhalf_r) - flux(uhalf_l))
            else  # 非守恒迎风：u_t = −u·u_x，把 a = u 冻结在格点上
                if u[j] >= 0
                    un[j] = u[j] - lam * u[j] * (u[j] - u[jm])
                else
                    un[j] = u[j] - lam * u[j] * (u[jp] - u[j])
                end
            end
        end
        u .= un
    end
    u
end

# ---------- (1) 激波速度：RH 判据 ----------
# RH: s = (f(uL) − f(uR))/(uL − uR) = (0.5·1 − 0)/(1 − 0) = 0.5
uL, uR = 1.0, 0.0
s_exact = (flux(uL) - flux(uR)) / (uL - uR)
@assert s_exact == 0.5
h = 1 / 512
lam = 0.4
T = 0.4
# 激波定位：中值等值线 u = 0.5 的线性插值位置
function front_position(u, h)
    J = length(u)
    pos = 0.0
    for j in 1:J
        jp = mod1(j + 1, J)
        if u[j] >= 0.5 > u[jp]
            # 线性插值等值线位置
            frac = (u[j] - 0.5) / (u[j] - u[jp])
            pos = ((j - 1) + frac) * h
            return pos % 1.0
        end
    end
    return pos
end

for kind in (:lf, :lw)
    u = conservative_scheme(kind, uL, uR, lam, h, T)
    pos = front_position(u, h)
    err = abs(pos - (0.5 + s_exact * T))
    @assert err < 5 * h "守恒格式 $(kind) 的激波速度应正确（位置误差 $(err)）"
    println("conservative ", rpad(string(kind), 4), ": shock at ", round(pos, digits=4),
            ", exact ", round(0.5 + s_exact * T, digits=4),
            " (err ", round(err, digits=5), " < 5h)")
end
u_nc = conservative_scheme(:noncons, uL, uR, lam, h, T)
pos_nc = front_position(u_nc, h)
err_nc = abs(pos_nc - (0.5 + s_exact * T))
@assert err_nc > 10 * h "非守恒格式应给出错误速度（误差 $(err_nc)）"
println("non-conservative upwind: shock at ", round(pos_nc, digits=4),
        " (err ", round(err_nc, digits=4), " >> 10h: WRONG SPEED)")

# ---------- (2) 稀疏波 ----------
uL2, uR2 = -1.0, 1.0
T2 = 0.25
u = conservative_scheme(:lf, uL2, uR2, lam, h, T2)
# 熵解（以 x=0.5 为中心）：u = uL (xx < −t), xx/t (|xx| < t), uR (xx > t)。
# 周期域在对边 x=0/1 处还有第二个 Riemann 问题（驻定激波），对账只看中心区。
function rarefaction_err(u, h, T2, uL2, uR2)
    maxerr = 0.0
    for j in 1:length(u)
        x = (j - 1) * h
        xx = x - 0.5
        (abs(xx) > 0.35) && continue     # 只对账中心区 [|xx|<0.35]
        ex = xx < -T2 ? uL2 : (xx > T2 ? uR2 : xx / T2)
        maxerr = max(maxerr, abs(u[j] - ex))
    end
    maxerr
end
maxerr = rarefaction_err(u, h, T2, uL2, uR2)
@assert maxerr < 0.12 "LF 应收敛到稀疏波（熵解）（实测误差 $(maxerr)）"
println("rarefaction (uL=-1,uR=1): LF matches entropy solution u=x/t, max err = ",
        round(maxerr, digits=4))

# ---------- (3) 熵条件 ----------
a_of(u) = u                      # a(u) = f'(u) = u
check_entropy(uL, uR) = a_of(uL) >= ((flux(uR) - flux(uL)) / (uR - uL)) >= a_of(uR)
@assert check_entropy(1.0, 0.0) "激波 (1,0) 满足熵条件（特征走向间断）"
@assert !check_entropy(-1.0, 1.0) "稀疏数据 (−1,1) 不满足熵条件（等熵解为稀疏波）"
println("entropy check: shock (1,0) satisfies a(uL) >= s >= a(uR); (-1,1) does not (rarefaction)")

println("END ====")
