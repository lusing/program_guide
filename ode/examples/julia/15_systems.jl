println("==== 15 systems")
using LinearAlgebra

# 第 15 章：方程组——高阶⟺一阶组互化、基本矩阵与 Abel。

# --- (a) 弹簧振子两形态：二阶标量 vs 二元组 ---
function rk4vec(f, t, u, h)
    k1 = f(t, u)
    k2 = f(t + h / 2, u .+ h .* k1 ./ 2)
    k3 = f(t + h / 2, u .+ h .* k2 ./ 2)
    k4 = f(t + h, u .+ h .* k3)
    u .+ h .* (k1 .+ 2 .* k2 .+ 2 .* k3 .+ k4) ./ 6
end
# 形态 1：x'' + 2δx' + ω0²x = 0
f2(t, u) = [u[2], -2 * 0.3 * u[2] - 4.0 * u[1]]
# 形态 2：同一方程当一阶组（就是 f2 本身）——对照对象是解析解
δ, ω0 = 0.3, 2.0
yexact(t) = exp(-δ * t) * (cos(sqrt(ω0^2 - δ^2) * t) + 0.5 * sin(sqrt(ω0^2 - δ^2) * t))
t, u = 0.0, [1.0, -δ + 0.5 * sqrt(ω0^2 - δ^2)]
h = 10.0 / 240000
for _ in 1:240000
    global u = rk4vec(f2, t, u, h)
    global t += h
end
@assert abs(u[1] - yexact(10.0)) < 1e-8 "二阶组数值 vs 解析解"
println("振子两形态：x(10) = ", round(u[1]; digits=8), " vs 解析 ", round(yexact(10.0); digits=8))

# --- (b) 基本矩阵 Abel：Airy 型 A(t) = [[0,1],[-t,0]]（tr = 0 ⟹ det X = 1）---
function fundamental_matrix(t1; n = 24000)
    h = t1 / n
    X = [1.0 0.0; 0.0 1.0]     # 列是解：x1=(1,0), x2=(0,1)
    t = 0.0
    for _ in 1:n
        # 每列独立积分（RK4 对矩阵按列作用）
        X = rk4vec((t, u) -> [u[1, 1] u[1, 2]; u[2, 1] u[2, 2]] |> Z -> nothing, t, X, h) # 占位——下面真算
    end
    X
end
# 真算：直接对两列分别积分
function fundamental_matrix2(t1; n = 24000)
    h = t1 / n
    fA(t, u) = [u[2], -t * u[1]]
    c1, c2 = [1.0, 0.0], [0.0, 1.0]
    t = 0.0
    for _ in 1:n
        c1 = rk4vec(fA, t, c1, h)
        c2 = rk4vec(fA, t, c2, h)
        t += h
    end
    [c1[1] c2[1]; c1[2] c2[2]]
end
X = fundamental_matrix2(2.0)
@assert abs(det(X) - 1.0) < 1e-9 "Abel：tr A = 0 ⟹ det X ≡ 1"
println("Airy 型基本矩阵：det X(2) = ", round(det(X); digits=8), "（Abel 预言 1）")

# --- (c) 常系数基本矩阵与 e^{tr A t} ---
A = [1.0 2.0; 0.5 3.0]     # tr = 4
function fundamental_matrix2c(A, t1; n = 24000)
    h = t1 / n
    fA(t, u) = A * u
    c1, c2 = [1.0, 0.0], [0.0, 1.0]
    t = 0.0
    for _ in 1:n
        c1 = rk4vec(fA, t, c1, h)
        c2 = rk4vec(fA, t, c2, h)
        t += h
    end
    [c1[1] c2[1]; c1[2] c2[2]]
end
Xc = fundamental_matrix2c(A, 1.5)
@assert abs(det(Xc) - exp(4.0 * 1.5)) < 1e-6 "det X = e^{tr A · t}"
println("常系数组：det X(1.5) = ", round(det(Xc); digits=4), " vs e^{4·1.5} = ", round(exp(6.0); digits=4))

# --- (d) 参数变易：x' = Ax + g 的解 = X(t)(X(0)^{-1}x0 + ∫X^{-1}g) ---
# 数值直接积分 vs 公式（数值积分内层）对照
g(t) = [cos(t); 0.0]
fN(t, u) = A * u + g(t)
t, u = 0.0, [1.0, -1.0]
h = 2.0 / 24000
for _ in 1:24000
    global u = rk4vec(fN, t, u, h)
    global t += h
end
# 公式：x = X(t)·X(0)^{-1}·(x0 + ∫₀ᵗ X(s)^{-1}g(s)ds)（X(0) = I）
# 用数值：把 X(s)^{-1}g(s) 用两条解曲线的朗斯基结构算——直接复用 Xc 的列
# 简化核对：比较 RK4 结果与常微分直接积分一致（同一路径）+ Xc 的正确性已证
# 此处用矩阵指数路线核对：x(2) = e^{A·2}x0 + ∫e^{A(2-s)}g(s)ds（数值梯形）
using LinearAlgebra
E2 = exp(A * 2.0)
# ∫₀² e^{A(2-s)} g(s) ds 数值（梯形，500 点）
Iv = zeros(2)
ns = 8000
hs = 2.0 / ns
for k in 0:ns
    s = k * hs
    w = exp(A * (2.0 - s)) * g(s)
    Iv .+= (k == 0 || k == ns ? 0.5 : 1.0) .* w .* hs
end
xf = E2 * [1.0, -1.0] + Iv
@assert norm(xf - u) / norm(u) < 1e-5 "参数变易公式 vs 直接积分（相对误差）"
println("参数变易：公式 x(2) = [", round(xf[1]; digits=4), ", ", round(xf[2]; digits=4),
        "]，RK4 差 ", norm(xf - u))

println("END ====")
