module MiniODE

# 唯一依赖：norm——标量/向量通吃的范数（泛型状态的误差度量）
using LinearAlgebra: norm

export ODEProblem, Euler, RK4, RKF45, solve, ODESolution

# ═══ 问题：把"求什么"打包成值（SciML 三件套之一）
"""常微分方程初值问题：u' = f(u, t)，t ∈ tspan，u(tspan[1]) = u0。

`f` 接收 `(u, t)` 两个参数；`u0` 标量或向量皆可——状态类型是泛型参数，
同一套求解器对衰减方程（标量）和洛伦兹系统（三维向量）零改动成立。
"""
struct ODEProblem{F, U}
    f::F                    # 右端函数
    u0::U                   # 初始状态（标量 / Vector / 任意支持 +.* 的类型）
    tspan::Tuple{Float64, Float64}
end
ODEProblem(f, u0, tspan) = ODEProblem(f, u0, (Float64(tspan[1]), Float64(tspan[2])))

# ═══ 算法：空 struct 当"派发标记"（SciML 同款设计——类型当值用）
"""算法抽象层：子类通常是空 struct 或只带超参，专职多重派发。"""
abstract type AbstractODEAlgorithm end

"""显式欧拉：一阶精度，每步 1 次右端求值——教学基线与对照项。"""
struct Euler <: AbstractODEAlgorithm
    dt::Float64
end

"""经典四阶 Runge-Kutta：每步 4 次求值，全局误差 O(dt⁴)。"""
struct RK4 <: AbstractODEAlgorithm
    dt::Float64
end

"""Runge-Kutta-Fehlberg 4(5)：嵌入式自适应——同一次六级求值给出 4/5 阶两个解，
差值即局部误差估计；据此接受/拒绝并伸缩步长。tol 同时当 atol 与 rtol 用。"""
struct RKF45 <: AbstractODEAlgorithm
    dt0::Float64            # 初始步长
    tol::Float64            # 容差
end

# ═══ 解：轨迹 + 步数统计
"""数值解：接受步的时间/状态序列与步数统计。"""
struct ODESolution{U}
    t::Vector{Float64}
    u::Vector{U}
    naccept::Int
    nreject::Int
end

# struct 含 Vector 字段：默认 == 按身份（===）——两次求解"长得一样"也不相等；
# 值语义（测试里比较两次运行的确定性）必须自己定义（08 章坑位的正面用法）
Base.:(==)(a::ODESolution, b::ODESolution) =
    a.t == b.t && a.u == b.u && a.naccept == b.naccept && a.nreject == b.nreject

# ═══ solve：按算法类型多重派发——问题 × 算法的组合爆炸交给方法表（06 章）
"""solve(prob, alg)：按算法类型派发到对应求解器。"""
function solve(::ODEProblem, ::AbstractODEAlgorithm)
    error("未知算法：用 Euler(dt)、RK4(dt) 或 RKF45(dt0, tol)")
end

# —— 固定步长的公共骨架：n 步均匀划分（收尾精确落在 tspan[2]）——
function fixed_steps(prob, dt)
    t0, tf = prob.tspan
    n = max(1, ceil(Int, (tf - t0) / dt))
    h = (tf - t0) / n
    t = collect(t0 .+ (0:n) .* h)   # 必须 collect：范围字面量是惰性 StepRangeLen，不可 setindex!
    t[end] = tf                     # 消除浮点累积的末端毛刺
    n, h, t
end

function solve(prob::ODEProblem, alg::Euler)
    n, h, t = fixed_steps(prob, alg.dt)
    u = [prob.u0]
    for k in 1:n
        push!(u, u[end] + h * prob.f(u[end], t[k]))
    end
    ODESolution(t, u, n, 0)
end

function solve(prob::ODEProblem, alg::RK4)
    n, h, t = fixed_steps(prob, alg.dt)
    u = [prob.u0]
    for k in 1:n
        uk, tk = u[end], t[k]
        k1 = prob.f(uk, tk)
        k2 = prob.f(uk .+ (h / 2) .* k1, tk + h / 2)
        k3 = prob.f(uk .+ (h / 2) .* k2, tk + h / 2)
        k4 = prob.f(uk .+ h .* k3, tk + h)
        push!(u, uk .+ (h / 6) .* (k1 .+ 2 .* k2 .+ 2 .* k3 .+ k4))
    end
    ODESolution(t, u, n, 0)
end

# —— RKF45 的 Butcher 表（Fehlberg 系数；a=级间权重，c=时间节点，b4/b5=两套解权重）
const A21 = 1 / 4
const A31, A32 = 3 / 32, 9 / 32
const A41, A42, A43 = 1932 / 2197, -7200 / 2197, 7296 / 2197
const A51, A52, A53, A54 = 439 / 216, -8.0, 3680 / 513, -845 / 4104
const A61, A62, A63, A64, A65 = -8 / 27, 2.0, -3544 / 2565, 1859 / 4104, -11 / 40
const C2, C3, C4, C6 = 1 / 4, 3 / 8, 12 / 13, 1 / 2
const B41, B43, B44, B45 = 25 / 216, 1408 / 2565, 2197 / 4104, -1 / 5
const B51, B53, B54, B55, B56 = 16 / 135, 6656 / 12825, 28561 / 56430, -9 / 50, 2 / 55

function solve(prob::ODEProblem, alg::RKF45)
    t0, tf = prob.tspan
    f, tol = prob.f, alg.tol
    t = Float64[t0]
    u = [prob.u0]
    dt = alg.dt0
    naccept = nreject = 0
    while t[end] < tf - 1e-12
        t[end] + dt > tf && (dt = tf - t[end])            # 收尾对齐
        tk, uk = t[end], u[end]
        k1 = f(uk, tk)
        k2 = f(uk .+ dt .* (A21 .* k1), tk + dt * C2)
        k3 = f(uk .+ dt .* (A31 .* k1 .+ A32 .* k2), tk + dt * C3)
        k4 = f(uk .+ dt .* (A41 .* k1 .+ A42 .* k2 .+ A43 .* k3), tk + dt * C4)
        k5 = f(uk .+ dt .* (A51 .* k1 .+ A52 .* k2 .+ A53 .* k3 .+ A54 .* k4), tk + dt)
        k6 = f(uk .+ dt .* (A61 .* k1 .+ A62 .* k2 .+ A63 .* k3 .+ A64 .* k4 .+ A65 .* k5),
               tk + dt * C6)
        u4 = uk .+ dt .* (B41 .* k1 .+ B43 .* k3 .+ B44 .* k4 .+ B45 .* k5)   # 4 阶解（接受它）
        u5 = uk .+ dt .* (B51 .* k1 .+ B53 .* k3 .+ B54 .* k4 .+ B55 .* k5 .+ B56 .* k6)  # 5 阶解（只用来估误差）
        err = norm(u5 .- u4) / (tol * (1 + norm(u5)))     # 归一化误差：≤ 1 即接受
        if err <= 1
            newt = min(tk + dt, tf)
            push!(t, newt)
            push!(u, u4)
            naccept += 1
            dt *= min(5.0, max(0.2, 0.9 * err^(-1 / 5)))  # 5 阶误差尺度定步长增速
        else
            nreject += 1
            dt *= min(1.0, max(0.2, 0.9 * err^(-1 / 5)))  # 拒绝只收缩
        end
        dt < 1e-14 && error("步长塌缩：问题可能刚性过头（换隐式法，超出本教程）")
    end
    ODESolution(t, u, naccept, nreject)
end

end # module
