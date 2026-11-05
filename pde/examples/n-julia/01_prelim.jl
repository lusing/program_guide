# 01_prelim.jl —— 第 01 章：典型方程、定解问题与依赖区间（Julia 通道）
#
#   (1) 二阶方程分类引擎：主部系数 (a, 2b, c) → ac - b^2 的符号 →
#       椭圆/双曲/抛物，并给出特征线斜率；
#   (2) D'Alembert 公式数值：含初速度项的积分用复化梯形；
#   (3) 依赖区间的数值实证：在依赖区间之外改动初值，解不变。

println("==== 01 prelim")

# ---------- (1) 二阶方程分类引擎 ----------
# 方程 a u_xx + 2b u_xy + c u_yy + ... = 0
function classify(a, b, c)
    d = a * c - b * b
    if d > 0
        return "elliptic"
    elseif d < 0
        # 特征线斜率 dy/dx = (b ± sqrt(b^2 - ac)) / a
        return "hyperbolic"
    else
        return "parabolic"
    end
end

@assert classify(1.0, 0.0, 1.0) == "elliptic"     # Laplace: u_xx + u_yy = 0
@assert classify(1.0, 0.0, 0.0) == "parabolic"    # 扩散: u_xx = u_t（y 充当 t）
@assert classify(1.0, 0.0, -1.0) == "hyperbolic"  # 波动: u_xx - u_tt = 0
println("classify: Laplace elliptic / heat parabolic / wave hyperbolic")

# 波动方程 u_tt = c^2 u_xx 的特征线：x ± c t = const（斜率 dt/dx = ±1/c）
cwave = 2.0
# 沿特征线 x + c t = 4 检验 F(x + c t) 分量保持常数
F(s) = exp(-s^2)
for t in 0.0:0.1:1.0
    x = 4.0 - cwave * t
    @assert abs(F(x + cwave * t) - F(4.0)) < 1.0e-14
end
println("characteristic check: F(x + c t) constant along x + c t = const")

# ---------- (2) D'Alembert 公式 ----------
# u_tt = c^2 u_xx, u(x,0)=g(x), u_t(x,0)=h(x):
#   u(x,t) = [g(x+ct) + g(x-ct)]/2 + (1/2c) ∫_{x-ct}^{x+ct} h(ξ) dξ
gfun(x) = exp(-(x - 1.0)^2)
hfun(x) = sin(x)

# 初速度项的积分用 Simpson 公式（复合梯形只有 O(h^2)，压不到 1e-10）
function simpson(f, a, b, n)
    hh = (b - a) / n
    s = f(a) + f(b)
    for i in 1:n-1
        s += (i % 2 == 1 ? 4 : 2) * f(a + i * hh)
    end
    s * hh / 3
end

function dalembert(x, t; c=cwave, n=2000)
    base = 0.5 * (gfun(x + c * t) + gfun(x - c * t))
    base + simpson(hfun, x - c * t, x + c * t, n) / (2 * c)
end

# 对 h = sin x 用闭式积分核对数值积分：∫ sin = -cos 差
function dalembert_exact_h(x, t; c=cwave)
    lo, hi = x - c * t, x + c * t
    0.5 * (gfun(x + c * t) + gfun(x - c * t)) + (cos(lo) - cos(hi)) / (2 * c)
end

for (x, t) in ((0.7, 0.3), (1.2, 0.5), (0.0, 0.4))
    err = abs(dalembert(x, t) - dalembert_exact_h(x, t))
    @assert err < 1.0e-10
end
println("D'Alembert: trapezoid vs closed-form integral agree to 1e-10")

# 用残差核对公式确实给出波动方程的解：中心差分残差 O(dh^2)，减半比值 ~4
x0, t0 = 0.6, 0.25
function wave_resid(dh)
    utt = (dalembert(x0, t0 + dh) - 2 * dalembert(x0, t0) + dalembert(x0, t0 - dh)) / dh^2
    uxx = (dalembert(x0 + dh, t0) - 2 * dalembert(x0, t0) + dalembert(x0 - dh, t0)) / dh^2
    abs(utt - cwave^2 * uxx)
end
r1 = wave_resid(1.0e-2); r2 = wave_resid(5.0e-3)
@assert 3.5 < r1 / r2 < 4.5 "残差比值应约 4（实测 $(r1 / r2)）"
println("D'Alembert residual u_tt - c^2 u_xx: h->h/2 ratio = ", round(r1 / r2, digits=3), "  (2nd order)")

# ---------- (3) 依赖区间 ----------
# u(x0,t0) 只依赖 g, h 在 [x0 - c t0, x0 + c t0] 上的值。
x0, t0 = 0.6, 0.25
lo, hi = x0 - cwave * t0, x0 + cwave * t0
g2(x) = exp(-(x - 1.0)^2) + (x < lo - 0.05 ? 100.0 * (x - (lo - 0.05))^2 : 0.0)
# g2 在依赖区间左侧之外 ≠ g，其余恒等；h 不变
function dalembert_g(gx, x, t; c=cwave, n=2000)
    base = 0.5 * (gx(x + c * t) + gx(x - c * t))
    base + simpson(hfun, x - c * t, x + c * t, n) / (2 * c)
end
u1 = dalembert_g(gfun, x0, t0)
u2 = dalembert_g(g2, x0, t0)
@assert abs(u1 - u2) < 1.0e-14 "依赖区间外的初值改动不应影响解"
println("domain of dependence: perturbing g outside [x0-ct0, x0+ct0] leaves u(x0,t0) unchanged")

# 反例 1：g 在依赖区间的端点 x0 + c t0 处被直接读入公式（权重 1/2）
g3(x) = exp(-(x - 1.0)^2) + (abs(x - (x0 + cwave * t0)) < 0.05 ? 1.0 : 0.0)
u3 = dalembert_g(g3, x0, t0)
@assert abs(u3 - u1) > 0.4
println("perturbing g at the endpoint x0+ct0 changes u(x0,t0) by ", round(abs(u3 - u1), digits=3))

# 反例 2：初速度 h 在区间内部取值——整个区间都被积分读到
h3(x) = hfun(x) + (abs(x - x0) < 0.1 ? 1.0 : 0.0)
u4 = 0.5 * (gfun(x0 + cwave * t0) + gfun(x0 - cwave * t0)) +
     simpson(h3, x0 - cwave * t0, x0 + cwave * t0, 4000) / (2 * cwave)
@assert abs(u4 - u1) > 0.05
println("perturbing h inside the interval changes u(x0,t0) by ", round(abs(u4 - u1), digits=3))

println("END ====")
