# 第 00 章 · 数值通道总览：浮点眼里的泛函分析
# 对应 docs/00-intro.md。本文件是数值双通道（Julia + Python/scipy）的热身：
# 用随机向量验证 CBS 不等式与三角不等式在浮点世界中的形态，
# 并建立本教程数值实验的断言纪律（每个实验都带容差断言）。

using LinearAlgebra
using Random

println("==== 00 intro (Julia) ====")
println("julia version: ", VERSION)

Random.seed!(42)

# --- CBS 不等式的随机验证 ---------------------------------------------
# |<x,y>|^2 <= <x,x> * <y,y> 在浮点下应满足（左边是精确表达时必 <= 右边；
# 浮点误差可能让两边几乎相等，但不会让右边系统性小于左边超过容差）
function cbs_check(x::Vector{Float64}, y::Vector{Float64})
    lhs = abs(dot(x, y))^2
    rhs = dot(x, x) * dot(y, y)
    return lhs <= rhs + eps(rhs) * 8   # 容差：几个 ulp
end

function cbs_trial()
    n = rand(1:50)
    cbs_check(randn(n), randn(n))
end

function cbs_trials(n::Int)
    all(_ -> cbs_trial(), 1:n)
end

ok1 = cbs_trials(1000)
println("CBS random check (1000 trials): ", ok1 ? "PASS" : "FAIL")
@assert ok1

# --- 三角不等式：||x+y|| <= ||x|| + ||y|| ------------------------------
function triangle_check(x::Vector{Float64}, y::Vector{Float64})
    norm(x + y) <= norm(x) + norm(y) + 1e-12
end

function triangle_trials(n::Int)
    k = rand(1:50)
    all(triangle_check(randn(k), randn(k)) for _ in 1:n)
end

ok2 = triangle_trials(1000)
println("triangle random check (1000 trials): ", ok2 ? "PASS" : "FAIL")
@assert ok2

# --- 平行四边形恒等式：Hilbert 空间的"指纹" ----------------------------
# ||x+y||^2 + ||x-y||^2 == 2(||x||^2 + ||y||^2) 对内积范数严格成立。
# 它是"范数来自内积"的充要条件（第 14 章将回来讨论这一点），
# 用一个非内积范数（L1）做反例对照。
function para_ratio(normf::Function, x::Vector{Float64}, y::Vector{Float64})
    a = normf(x + y)^2 + normf(x - y)^2
    b = 2 * (normf(x)^2 + normf(y)^2)
    return a / b   # 内积范数应恒等于 1
end

x = [1.0, 1.0]; y = [1.0, -1.0]        # 对抗样本：L1 下偏差最大
r2 = para_ratio(norm, x, y)             # 欧氏范数
r1 = para_ratio(v -> sum(abs, v), x, y) # L1 范数：不是内积范数！
println("parallelogram ratio, L2: ", round(r2, digits=12))
println("parallelogram ratio, L1: ", round(r1, digits=12))
@assert abs(r2 - 1.0) < 1e-12
@assert abs(r1 - 0.5) < 1e-12   # L1 在此样本上比值恰 1/2：不可能来自任何内积

println("==== 00 intro END ====")
