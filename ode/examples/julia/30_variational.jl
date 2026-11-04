println("==== 30 variational")

function quad_num(f, a, b; n = 200000)
    h = (b - a) / n
    s = f(a) + f(b)
    for i in 1:n-1
        s += (i % 2 == 0 ? 2 : 4) * f(a + i * h)
    end
    s * h / 3
end

# 第 30 章：变分法——Euler 方程、brachistochrone、Ritz。

# --- (a) Euler 方程核对：J = ∫(y'² - y²)dx ⟹ y'' + y = 0（sin 支） ---
J(y, yp, a, b; n = 2000) = begin
    h = (b - a) / n
    s = 0.0
    for i in 0:n
        x = a + i * h
        w = (i == 0 || i == n) ? 0.5 : 1.0
        s += w * (yp(x)^2 - y(x)^2)
    end
    s * h
end
ysin(x) = sin(x)
ypsin(x) = cos(x)
eta(x) = x * (pi - x)          # 扰动（两端为零）
etap(x) = pi - 2x
J0 = J(ysin, ypsin, 0, pi)
for eps in [1e-3, -1e-3, 5e-3]
    Je = J(x -> ysin(x) + eps * eta(x), x -> ypsin(x) + eps * etap(x), 0, pi)
    @assert abs(Je - J0) < 50 * eps^2 + 1e-10 "一阶变分为零（响应 O(ε²)）"
end
println("驻定核对：J[sin x + εη] − J[sin x] = O(ε²)（一阶变分 = 0，三个 ε 核对）")

# --- (b) brachistochrone：摆线 vs 直线 vs 抛物线 ---
# A = (0,0)，B = (1, -1)（y 向下为正取绝对值）；g = 1
# 时间 T = ∫ sqrt((1+y'^2)/(2gy)) ds 沿曲线 y(x)
# 摆线参数：x = a(θ - sinθ)/2? 用标准式 x = r(θ−sinθ), y = r(1−cosθ)
# B 点：r(θB − sinθB) = 1, r(1−cosθB) = 1 ⟹ θB ≈ 2.412, r = 0.835
function cyclo_time()
    # 数值解 r, θB
    tb = 2.4
    for _ in 1:60
        F = (1 - cos(tb)) - (tb - sin(tb))     # y/x = 1 ⟹ tan?
        # 解 (1−cosθ)/(θ−sinθ) = 1
        dF = sin(tb) - (1 - cos(tb))
        tb -= F / dF
    end
    r = 1.0 / (tb - sin(tb))
    # T = sqrt(r/g)·θB（摆线等时性公式：T = θB·sqrt(r/g)）
    tb * sqrt(r)
end
Tcyc = cyclo_time()
# 直线：y = x，T = ∫₀¹ sqrt(2/(2gy))·sqrt(1+1)dx = ∫ sqrt(1/y)dy... 手算
Tline = quad_num(x -> sqrt(2 * (1 + 1) / (2 * x)), 1e-8, 1.0)
# 抛物线 y = x²：y' = 2x
Tpar = quad_num(x -> sqrt(2 * (1 + 4x^2) / (2 * x * x)), 1e-8, 1.0)
println("brachistochrone：摆线 T = ", round(Tcyc; digits=4),
        "，直线 T = ", round(Tline; digits=4), "（慢 ", round(Tline / Tcyc - 1; digits=3), "）")
@assert Tcyc < Tline && Tcyc < Tpar "摆线最快"

# --- (c) Beltrami 核对：摆线满足 1/(sqrt(y) sqrt(1+y'^2)) = 常数 ---
# 摆线上 y = r(1−cosθ)，y' = sinθ/(1−cosθ)：1+y'^2 = 2/(1−cosθ)
# ⟹ sqrt(y)sqrt(1+y'^2) = sqrt(r)·(1−cosθ)·sqrt(2/(1−cosθ)) = sqrt(2r)·常数 ✓
r0 = 0.835
for th in [0.8, 1.5, 2.2]
    y = r0 * (1 - cos(th))
    yp = sin(th) / (1 - cos(th))
    c = 1 / (sqrt(y) * sqrt(1 + yp^2))
    @assert abs(c - 1 / sqrt(2 * r0)) < 1e-10 "Beltrami 常数"
end
println("Beltrami：1/√(y(1+y'²)) = 1/√(2r) 沿摆线常数 ✓")

# --- (d) Ritz：J = ∫(½y'² − ½y² + f y)dx，y(0)=y(1)=0，f = x ---
# 基 sin(nπx)：系数方程 (nπ)²/2·c_n − 1/2·c_n = f_n/2 ⟹ c_n = f_n/(n²π² − 1)
xs = range(0, 1; length = 2000)
h = 1 / 2000
fn(n) = sum(x * sin(n * pi * x) for x in xs[2:end-1]) * h * 2   # ∫x·sin nπx ×2
cs = [-fn(n) / (n^2 * pi^2 - 1) for n in 1:3]   # c_n = −f_n/(n²π²−1)（变分方程 ∂J/∂c = 0）
# 与精确解 y'' + y = x、y(0)=y(1)=0 的 Fourier 系数一致：
# y = x − sin x/sin 1 的 sin 展开系数
yexact(x) = x - sin(x) / sin(1.0)
for n in 1:3
    cn = 2 * sum(yexact(x) * sin(n * pi * x) for x in xs[2:end-1]) * h
    @assert abs(cs[n] - cn) < 1e-3 "Ritz 系数 = 精确解 Fourier 系数"
end
println("Ritz：三基系数与精确解 y = x − sinx/sin1 的 Fourier 系数一致 ✓")

# --- (e) 氢原子试探：E(β) = β²/2 − β 最小在 β=1 给 −0.5 ---
Eb(b) = b^2 / 2 - b
β = 0.5
hβ = 0.1
for _ in 1:100
    global β -= hβ * (β - 1)     # 梯度下降（精确梯度 β−1）
end
@assert abs(Eb(β) + 0.5) < 1e-6 "E_min = −0.5 Hartree"
println("氢原子：E(β) = β²/2 − β 最小 E = −0.5 Hartree（β = 1）✓")

println("END ====")

function quad_num(f, a, b; n = 200000)
    h = (b - a) / n
    s = f(a) + f(b)
    for i in 1:n-1
        s += (i % 2 == 0 ? 2 : 4) * f(a + i * h)
    end
    s * h / 3
end
