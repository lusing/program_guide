# 20_nonlinear.jl —— 第 20 章：非线性抛物方程（Julia 通道）
#
#   (1) Richtmyer 线性化（书 §6.1）：u_t = (u^5)_xx 型拟线性扩散，
#       把非线性项在上一层线性化后隐式求解；
#   (2) 预估-校正（书 §6.4）：显式预估 + 校正，二阶精度；
#   (3) 对账基准：制造解 u* = exp(-t) sin(pi x)，源项解析给出。

println("==== 20 nonlinear")

# 方程：u_t = d/dx( k(u) u_x ) + f，k(u) = 1 + u²
# 制造解 u* = e^{-t} sin(pi x)：f = u*_t - (k(u*) u*_x)_x（闭式）
ustar(x, t) = exp(-t) * sin(pi * x)
function fsource(x, t)
    ut = -exp(-t) * sin(pi * x)
    ux = exp(-t) * pi * cos(pi * x)
    kus = 1 + ustar(x, t)^2
    dkus = 2 * ustar(x, t) * ux
    ut - (dkus * ux + kus * (-exp(-t) * pi^2 * sin(pi * x)))
end

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

# ---------- (1) Richtmyer 线性化（半隐式：k 在旧层取值） ----------
function nonlinear_semi_implicit(h, T)
    J = round(Int, 1 / h) - 1
    r = 0.4
    tau = r * h * h
    nst = round(Int, T / tau)
    u = [sin(pi * j * h) for j in 1:J]
    for n in 1:nst
        t = (n - 1) * tau
        kold = [1 + u[j]^2 for j in 1:J]
        aa = zeros(J); bb = zeros(J); cc = zeros(J); dd = zeros(J)
        for j in 1:J
            kL = 0.5 * (kold[max(j-1, 1)] + kold[j])
            kR = 0.5 * (kold[j] + kold[min(j+1, J)])
            aa[j] = -r * kL
            bb[j] = 1 + r * (kL + kR)
            cc[j] = -r * kR
            dd[j] = u[j] + tau * fsource(j * h, t)
        end
        aa[1] = 0.0; cc[J] = 0.0
        u = thomas(aa, bb, cc, dd)
    end
    tf = nst * tau
    maximum(abs.(u[j] - ustar(j * h, tf)) for j in 1:J)
end
e1 = nonlinear_semi_implicit(0.05, 0.5)
e2 = nonlinear_semi_implicit(0.025, 0.5)
r20 = e1 / e2
println("Richtmyer linearized semi-implicit: h->h/2 ratio = ", round(r20, digits=3))
@assert 3.0 < r20 < 4.6 "线性化格式应约二阶（空间二阶、时间一阶被小 r 压低）（实测 $r20）"

# ---------- (2) 预估-校正（显式预估 + CN 型校正） ----------
function nonlinear_predictor_corrector(h, T)
    J = round(Int, 1 / h) - 1
    r = 0.05   # 非线性扩散显式步的等效网格比是 r·k(u)，须再压一个量级
    tau = r * h * h
    nst = round(Int, T / tau)
    u = [sin(pi * j * h) for j in 1:J]
    un = similar(u)
    for n in 1:nst
        t = (n - 1) * tau
        # 预估（FTCS，k 在旧层）
        for j in 1:J
            ul = (j == 1 ? 0.0 : u[j-1]); ur = (j == J ? 0.0 : u[j+1])
            kL = 1 + (j == 1 ? 0.0 : u[j-1])^2; kR = 1 + (j == J ? 0.0 : u[j+1])^2
            km = 0.5 * (kL + 1 + u[j]^2); kp = 0.5 * (1 + u[j]^2 + kR)
            fluxl = km * (u[j] - (j == 1 ? 0.0 : u[j-1])) / h
            fluxr = kp * ((j == J ? 0.0 : u[j+1]) - u[j]) / h
            un[j] = u[j] + tau * ((fluxr - fluxl) / h + fsource(j * h, t))
        end
        # 校正（用预估值重算通量，取平均）
        u2 = copy(un)
        for j in 1:J
            ul = (j == 1 ? 0.0 : u2[j-1]); ur = (j == J ? 0.0 : u2[j+1])
            kL = 1 + (j == 1 ? 0.0 : u2[j-1])^2; kR = 1 + (j == J ? 0.0 : u2[j+1])^2
            km = 0.5 * (kL + 1 + u2[j]^2); kp = 0.5 * (1 + u2[j]^2 + kR)
            fluxl = km * (u2[j] - (j == 1 ? 0.0 : u2[j-1])) / h
            fluxr = kp * ((j == J ? 0.0 : u2[j+1]) - u2[j]) / h
            un[j] = u[j] + tau * ((fluxr - fluxl) / h + fsource(j * h, t + tau / 2))
        end
        u .= un
    end
    tf = nst * tau
    maximum(abs.(u[j] - ustar(j * h, tf)) for j in 1:J)
end
e1 = nonlinear_predictor_corrector(0.05, 0.5)
e2 = nonlinear_predictor_corrector(0.025, 0.5)
r20b = e1 / e2
println("predictor-corrector: h->h/2 ratio = ", round(r20b, digits=3))
@assert 3.0 < r20b < 4.6 "预估-校正应约二阶（实测 $r20b）"
@assert e2 < 0.01 "细网格误差应很小（实测 $e2）"

println("END ====")
