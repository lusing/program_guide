# 第 02 章 · 内积空间初步的数值实验（Conway I.1）
# 对应 docs/02-inner-product.md。
# 四个实验：CBS 的"等号条件"逼近、Bergman 空间范数的精确值、
# ℓ² 的完备性（平方可和列的极限仍在 ℓ²）、半内积商结构的数值预演。

using LinearAlgebra
using Random

println("==== 02 inner (Julia) ====")
Random.seed!(2026)

# --- 实验 1：CBS 的等号条件 ---------------------------------------------
# 等号 iff x 与 y 线性相关。让 y = t*x 看比值 |<x,y>|/(||x||·||y||) 恒为 1，
# 随机不相关向量则严格小于 1（且维数越高越接近 1——这是个著名的现象）。
x = randn(30)
t = 0.7
y_dep = t .* x
y_ind = randn(30)
r_dep = abs(dot(x, y_dep)) / (norm(x) * norm(y_dep))
r_ind = abs(dot(x, y_ind)) / (norm(x) * norm(y_ind))
println("CBS ratio dependent: ", round(r_dep, digits=12))
println("CBS ratio random   : ", round(r_ind, digits=12))
@assert abs(r_dep - 1.0) < 1e-12
@assert r_ind < 1.0

# --- 实验 2：Bergman 空间 A²(G) 的范数（Conway 1.10-1.12） ---------------
# 单位圆盘上 f(z) = z^k 的 Bergman 范数平方 = pi/(k+1)（精确）。
# 用数值积分对照。Bergman 空间是"解析函数 + L² 内积"的 Hilbert 空间，
# Conway 1.13 用均值性质+CBS 证明了它的完备性。
function bergman_normsq(k::Int; n::Int = 2_000_000)
    # 极坐标采样蒙特卡洛：均匀撒点（密度 1/π），积分 = π × 平均|z^k|²
    s = 0.0
    for _ in 1:n
        r = sqrt(rand()); θ = 2π * rand()
        s += abs((r * exp(im * θ))^k)^2
    end
    return (s / n) * π
end
exact(k) = π / (k + 1)
for k in [0, 2, 5]
    num = bergman_normsq(k)
    println("Bergman ||z^$k||^2: numeric=", round(num, digits=4), " exact=", round(exact(k), digits=4))
    @assert abs(num - exact(k)) < 0.02
end

# --- 实验 3：ℓ² 的完备性（Conway 1.6/1.7 的数值化身）---------------------
# 取 ℓ² 中柯西列的部分和：s_N = Σ_{n<=N} (1/n) e_n。
# 极限是 (1/n)_n ∈ ℓ²（Σ 1/n² < ∞），部分和的 ℓ² 范数单调趋近 π/√6。
N = 200_000
s2 = sum(1.0 / n^2 for n in 1:N)
println("partial ||s_N||^2 = ", round(s2, digits=6), "  pi^2/6 = ", round(π^2 / 6, digits=6))
@assert abs(s2 - π^2 / 6) < 1e-4

# --- 实验 4：半内积与商空间（Conway 1.1 与习题 1.6 的预演）----------------
# 在 F = R^3 上定义 u(x,y) = x1*y1 + x2*y2（忽略第三坐标）：
# 半内积（u(x,x)=0 未必 x=0）。退化子空间 M = {x : x1=x2=0}。
# 商掉 M 之后 u 恢复成正定：这正是"半内积 -> 商空间内积"的构造。
u(x, y) = x[1] * y[1] + x[2] * y[2]
deg = [0.0, 0.0, 5.0]
println("semi-inner u(deg,deg) = ", u(deg, deg), "  (deg != 0 但 u=0：半内积！)")
@assert u(deg, deg) == 0.0
@assert deg != zeros(3)
# 两个仅差退化向量的代表元给出相同的"商内积"
a = [1.0, 2.0, 0.0]; b = [1.0, 2.0, 7.0]   # a - b ∈ M
println("u(a,a) == u(b,b) : ", u(a, a) == u(b, b))
@assert u(a, a) == u(b, b)

println("==== 02 inner END ====")
