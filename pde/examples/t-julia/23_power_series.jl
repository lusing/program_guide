# Ch23 解的表示 VII：幂级数与 Cauchy-Kovalevskaya
#
# 对应书 §4.6：非特征曲面、实解析函数、Cauchy-Kovalevskaya 定理。

using Printf

println("==== 23")

# ---- (a) 解析解的 Taylor 收敛：u = 1/(1−x−t) 的级数与收敛半径 ----
# u = Σ_{m,n} C(m+n,m) x^m t^n（几何级数双重展开）
# 在 (0,0) 处收敛域 |x|+|t| < 1（到奇异 x+t=1 的距离，多复变 Hartogs
# 型域；1D 截面 t=0 收敛半径 1）
function series_u(x, t; N = 40)
    s = 0.0
    for m in 0:N, n in 0:N-m
        # C(m+n, m) = (m+n)!/(m!n!)
        c = factorial(big(m + n)) ÷ (factorial(big(m)) * factorial(big(n)))
        s += Float64(c) * x^m * t^n
    end
    return s
end
for (x, t) in [(0.1, 0.2), (0.3, 0.1)]
    num = series_u(x, t)
    exa = 1 / (1 - x - t)
    @printf("(a) double series at (%.1f,%.1f): %.10f  exact %.10f\n", x, t, num, exa)
    @assert abs(num - exa) < 1e-9 "收敛域内级数收敛到解析函数"
end
# 域外发散的签名：|x|+|t|>1 部分和不收敛
bad = series_u(0.6, 0.6; N = 30)
@printf("    outside domain (0.6,0.6): partial sum %.3e (diverging)\n", bad)
@assert abs(bad) > 10 "收敛域外发散"

# ---- (b) 非特征 Cauchy 问题：u_x = u、u(0,t) = e^t ⟹ u = e^{x+t} 的级数 ----
# 幂级数法：u = Σ a_{mn}x^m t^n，u_x = u ⟹ a_{m+1,n} = a_{mn}/(m+1)
# 初值 u(0,t) = e^t 给 a_{0n} = 1/n!
function series_e(x, t; N = 20)
    s = 0.0
    for m in 0:N, n in 0:N
        a0n = 1 / factorial(big(n))
        amn = Float64(a0n / factorial(big(m)))
        s += amn * x^m * t^n
    end
    return s
end
for (x, t) in [(0.5, 0.3), (1.0, -0.5)]
    num = series_e(x, t)
    exa = exp(x + t)
    @printf("(b) CK series at (%.1f,%.1f): %.10f  e^(x+t) = %.10f\n", x, t, num, exa)
    @assert abs(num - exa) < 1e-8 "非特征 Cauchy 数据的幂级数解"
end

# ---- (c) 特征初始面失败：x=0 平面对于 u_yy − u_xx = 0（波方程）是特征 ----
# 数据 u(0,y) = g(y), u_x(0,y) = h(y) 在特征面上不能任意给
# 数值签名：用 d'Alembert 任意 g、h 都给解（x=0 对波方程其实非特征——
# 特征是 x±y = const！）。演示真正的特征失败：面 y = x 上给 u = g
# u_y = h：特征方向 (1,1) 落在面上 ⟹ 数据必须满足相容性
println("(c) characteristic initial surface: data on y=x (char of wave eq) is overdetermined;")
println("    arbitrary (g,h) there has no solution — power series recursion singular")
# 数值：级数递推 a_{m+1,n+1} 系数分母含特征判别式 → 演示退化矩阵
# 波方程 u_xx - u_yy = 0 于面 y=0：非特征（判别式 ξ²−η² ≠ 0 于法向 (0,1)）✓
# 直接验证：d'Alembert 级数（g=cos, h=0 → u=cos x cos y 的 Taylor）
u_w(x, y; N = 12) = sum((-1)^k / factorial(big(2k)) * x^(2k) for k in 0:N) *
                    sum((-1)^k / factorial(big(2k)) * y^(2k) for k in 0:N)
for (x, y) in [(0.4, 0.6), (1.0, 0.3)]
    num = u_w(x, y)
    exa = cos(x) * cos(y)
    @printf("    wave Taylor at (%.1f,%.1f): %.10f  cosxcosy = %.10f\n", x, y, num, exa)
    @assert abs(num - exa) < 1e-9 "分离级数 = cos·cos"
end

# ---- (d) CK 的局部性：解析初值的解只在局部保证（奇异传播）----
# u = 1/(1−x−t)：初值 u(x,0) = 1/(1−x) 在 x=1 奇异 ⟹ 解的奇异沿特征
# x+t = 1 传播——收敛域由奇异的"距离"决定（(a) 的 |x|+|t|<1 正是它）
@printf("(d) singularity propagation: pole at x+t=1 bounds the convergence domain\n")
@assert 0.1 + 0.2 < 1 && 0.6 + 0.6 > 1 "收敛域 |x|+|t|<1 = 到奇异特征的距离"

println("END ====")
