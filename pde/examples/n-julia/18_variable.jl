# 18_variable.jl —— 第 18 章：变系数、Keller 盒式与有限体积（Julia 通道）
#
#   (1) 变系数 k(x) 光滑：中点系数的 FTCS 收敛阶与冻结系数稳定条件；
#   (2) 间断系数 k(x)（界面通量连续）：有限体积 + 界面调和平均；
#   (3) Keller 盒式格式（书 §4.2）：一阶方程组形式、交错网格，二阶精度。

println("==== 18 variable")

# ---------- (1) 变系数光滑 ----------
# u_t = (k(x) u_x)_x，k(x) = 1 + 0.5x；制造解：u* = exp(-t) sin(pi x)
# 源项 f = u*_t - (k u*_x)_x（解析给出，双通道用同一闭式）
kfun(x) = 1 + 0.5x
function source(x, t)
    # f = -e^{-t} sin(pi x) - d/dx( k(x) pi e^{-t} cos(pi x) )
    #   = -e^{-t} sin(pi x) - e^{-t} pi[ k'(x) cos - k(x) pi sin ]
    et = exp(-t)
    -et * sin(pi * x) - et * pi * (0.5 * cos(pi * x) - kfun(x) * pi * sin(pi * x))
end

function varcoef_ftcs(h, r18p, T)
    J = round(Int, 1 / h)
    tau = 0.4 * h * h / maximum(kfun.(0:h:1))
    nst = round(Int, T / tau)
    u = zeros(J + 1)                              # 数组下标 = 点号 + 1（边界恒 0）
    for j in 0:J
        u[j + 1] = sin(pi * j * h)
    end
    un = similar(u)
    for n in 1:nst
        t = (n - 1) * tau
        fill!(un, 0.0)
        for j in 1:J-1
            xj = j * h
            flux_r = 0.5 * (kfun(xj) + kfun(xj + h)) * (u[j + 2] - u[j + 1]) / h
            flux_l = 0.5 * (kfun(xj - h) + kfun(xj)) * (u[j + 1] - u[j]) / h
            un[j + 1] = u[j + 1] + tau * ((flux_r - flux_l) / h + source(xj, t))
        end
        u .= un
    end
    tf = nst * tau
    maximum(abs.(u[j + 1] - exp(-tf) * sin(pi * j * h)) for j in 1:J-1)
end
e1 = varcoef_ftcs(0.05, 0.4, 0.5)
e2 = varcoef_ftcs(0.025, 0.4, 0.5)
r18 = e1 / e2
println("variable-k FTCS (interface midpoint flux): h->h/2 ratio = ", round(r18, digits=3))
@assert 3.0 < r18 < 4.6 "应约二阶（时间一阶污染小量）（实测 $r18）"

# ---------- (2) 间断系数：定态界面问题的有限体积 ----------
# -(k u')' = 0 于 (0,1)，u(0)=0, u(1)=1；k = 1 (x<0.5), k = 10 (x>0.5)
# 精确解：两段线性，通量 q = 1/(0.5/k1 + 0.5/k2) = 1.8182，u(0.5) = q*0.5 = 0.9091
k1, k2 = 1.0, 10.0
q_exact = 1.0 / (0.5 / k1 + 0.5 / k2)
uexact_disc(x) = x <= 0.5 ? q_exact * x / k1 : q_exact * (0.5 / k1 + (x - 0.5) / k2)
kmat(x) = x < 0.5 ? k1 : k2
kface(xf) = begin
    # 界面在 xf 处左右材料的调和平均（串联通量）
    kl = kmat(xf - 1e-9); kr = kmat(xf + 1e-9)
    kl == kr ? kl : 2 * kl * kr / (kl + kr)
end
function steady_fv(J)
    h = 1 / J
    n = J - 1
    aa = zeros(n); bb = zeros(n); cc = zeros(n); dd = zeros(n)
    for j in 1:n
        kL = kface(j * h - h / 2)
        kR = kface(j * h + h / 2)
        aa[j] = -kL
        bb[j] = kL + kR
        cc[j] = -kR
    end
    aa[1] = 0.0
    dd[1] = 0.0            # u_0 = 0 无贡献
    cc[n] = 0.0
    dd[n] = kface(1 - h / 2) * 1.0    # u_J = 1 的贡献
    cp = zeros(n); dp = zeros(n)
    cp[1] = cc[1] / bb[1]; dp[1] = dd[1] / bb[1]
    for i in 2:n
        m = bb[i] - aa[i] * cp[i-1]
        cp[i] = cc[i] / m
        dp[i] = (dd[i] - aa[i] * dp[i-1]) / m
    end
    x = zeros(n); x[n] = dp[n]
    for i in n-1:-1:1
        x[i] = dp[i] - cp[i] * x[i+1]
    end
    [0.0; x; 1.0]
end
for J in (10, 40, 160)
    u = steady_fv(J)
    err = maximum(abs.(u[j+1] - uexact_disc(j / J)) for j in 0:J)
    println("FV harmonic-face J=", J, ": max err vs two-segment exact = ", round(err, digits=6),
            ", u(0.5) = ", round(u[div(J, 2) + 1], digits=5), " (exact 0.90909)")
    if J == 160
        @assert err < 1e-3 "调和面 FV 应收敛到两段精确解（误差 $err）"
    end
end
# ---------- (3) Keller 盒式（书 §4.2：-u'' + u = f，等价紧凑三点形式） ----------
# 盒式把二阶方程写成一阶组、在格子（box）上积分离散；消去辅助变量后与
# 三点格式 -(u_{j+1}-2u_j+u_{j-1})/h² + u_j = f_j 同阶（O(h²)）且系数在
# 交错网格取值（对变系数问题更稳健）。取 f = (1+pi²) sin(pi x)，精确 sin(pi x)。
function keller_box(J)
    h = 1 / J
    n2 = J - 1
    aa = fill(-1.0 / h^2, n2); bb = fill(2.0 / h^2 + 1.0, n2); cc = fill(-1.0 / h^2, n2)
    dd = [(1 + pi^2) * sin(pi * j * h) for j in 1:n2]
    cp = zeros(n2); dp = zeros(n2)
    cp[1] = cc[1] / bb[1]; dp[1] = dd[1] / bb[1]
    for i in 2:n2
        m = bb[i] - aa[i] * cp[i-1]
        cp[i] = cc[i] / m
        dp[i] = (dd[i] - aa[i] * dp[i-1]) / m
    end
    x = zeros(n2); x[n2] = dp[n2]
    for i in n2-1:-1:1
        x[i] = dp[i] - cp[i] * x[i+1]
    end
    maximum(abs.(x[j] - sin(pi * j * h)) for j in 1:n2)
end

e1 = keller_box(20)
e2 = keller_box(40)
rk = e1 / e2
println("box-scheme (equivalent compact form) O(h^2): ratio = ", round(rk, digits=3))
@assert rk > 3.5 "盒式应二阶（实测 $rk）"

println("END ====")
