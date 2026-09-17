# 24 · 实战：迷你 ODE 求解器（SciML 三件套）

> 对应示例：`examples/24_miniode/`（包工程：MiniODE 包 + env 环境 + 演示 CLI）
>
> 24 章集大成：**问题-算法-解三件套（多重派发 06/08）、泛型状态（15）、数值验证（18）、包工程（17）、广播（10）、异常（13）**。C++/Zig 的实战写 grep 是因为它们是通用系统语言；Julia 的招牌是科学计算——我们的压轴是**微分方程求解器**，并且直接照搬 Julia 旗舰生态 SciML（DifferentialEquations.jl）的架构。

## 24.1 为什么是 ODE 求解器

`DifferentialEquations.jl` 是 Julia 最著名的库，它的设计就是 Julia 语言优势的展示窗：

- 同一个 `solve` 调用，后面换算法（Euler/Tsit5/ODE23……）零改动——**多重派发**；
- 标量方程、电路方程、化学反应网络——**状态类型泛型**通吃；
- 算法是"空 struct 标记 + 超参"——**类型当值用**的工程化形态。

本章把这套设计缩到一个 200 行的包里：三个算法（Euler、RK4、RKF45 自适应）× 任意问题。

## 24.2 问题-算法-解：三件套结构

```text
examples/24_miniode/
├── MiniODE/               ← 可独立发布的包
│   ├── Project.toml       # [deps] LinearAlgebra（唯一依赖：norm）
│   ├── src/MiniODE.jl     # 问题/算法/解 + solve 派发
│   └── test/runtests.jl   # 包级测试（Pkg.test 入口）
├── env/                   # 环境（[sources] 路径依赖，17 章）
├── main.jl                # 演示 CLI（decay / pendulum / lorenz）
└── runtests.jl            # 端到端测试
```

```julia
# 问题：把"求什么"打包成值（f、初值、区间）——状态类型 U 是泛型参数
struct ODEProblem{F, U}
    f::F                   # 右端 f(u, t)
    u0::U                  # 标量（衰减）或 Vector（单摆/洛伦兹）——同一套代码
    tspan::Tuple{Float64, Float64}
end

# 算法：空 struct / 超参 struct 当派发标记（SciML 的 Euler()/Tsit5() 就是这个）
abstract type AbstractODEAlgorithm end
struct Euler <: AbstractODEAlgorithm; dt::Float64; end
struct RK4   <: AbstractODEAlgorithm; dt::Float64; end
struct RKF45 <: AbstractODEAlgorithm; dt0::Float64; tol::Float64; end

# 解：轨迹 + 步数统计（== 自己定义——见 24.8 坑位）
struct ODESolution{U}
    t::Vector{Float64}
    u::Vector{U}
    naccept::Int
    nreject::Int
end
```

**关键洞察**：如果用 OOP，`Euler` 和 `RK4` 会是两个类，各自带 solve 方法（单分发）；问题 × 算法 × 输出格式（数组/插值/绘图）的组合会逼你写 N 层继承。Julia 的答案是：**三样东西都是普通类型，`solve` 按第二实参派发**——组合爆炸交给方法表（06 章）。

## 24.3 solve 按算法派发

```julia
solve(::ODEProblem, ::AbstractODEAlgorithm) = error("未知算法：……")   # 兜底
solve(prob::ODEProblem, alg::Euler) = ...
solve(prob::ODEProblem, alg::RK4)   = ...
solve(prob::ODEProblem, alg::RKF45) = ...

# 调用方视角：换算法就是换个第二参数
solve(prob, Euler(0.01))
solve(prob, RK4(0.01))
solve(prob, RKF45(0.01, 1e-6))
```

固定步长公共骨架（收尾精确落在 `tspan[2]`，用乘法而不是累加避免漂移）：

```julia
function fixed_steps(prob, dt)
    t0, tf = prob.tspan
    n = max(1, ceil(Int, (tf - t0) / dt))
    h = (tf - t0) / n
    t = collect(t0 .+ (0:n) .* h)   # 必须 collect：范围是惰性 StepRangeLen，不可 setindex!
    t[end] = tf
    n, h, t
end
```

RK4 主体是四级公式，全部用**广播**写——所以标量状态和向量状态同一份代码（10/15 章）：

```julia
k1 = f(uk, tk)
k2 = f(uk .+ (h / 2) .* k1, tk + h / 2)
k3 = f(uk .+ (h / 2) .* k2, tk + h / 2)
k4 = f(uk .+ h .* k3, tk + h)
push!(u, uk .+ (h / 6) .* (k1 .+ 2 .* k2 .+ 2 .* k3 .+ k4))
```

## 24.4 RKF45：嵌入式自适应步长

Runge-Kutta-Fehlberg 4(5)：**一次六级求值同时给出 4 阶解 u4 和 5 阶解 u5**——差值就是免费的局部误差估计（嵌入式对，Dormand-Prince/ode45 同族）：

```julia
u4 = uk .+ dt .* (B41 .* k1 .+ B43 .* k3 .+ B44 .* k4 .+ B45 .* k5)        # 接受这个
u5 = uk .+ dt .* (B51 .* k1 .+ B53 .* k3 .+ B54 .* k4 .+ B55 .* k5 .+ B56 .* k6)
err = norm(u5 .- u4) / (tol * (1 + norm(u5)))    # 归一化误差（atol=rtol=tol 合并控制）
if err <= 1                                       # 误差达标 → 接受，步长可放大
    push!(t, min(tk + dt, tf)); push!(u, u4); naccept += 1
    dt *= min(5.0, max(0.2, 0.9 * err^(-1 / 5)))  # 5 阶误差尺度：err^(-1/5)
else                                              # 不达标 → 拒绝，只收缩
    nreject += 1
    dt *= min(1.0, max(0.2, 0.9 * err^(-1 / 5)))
end
```

细节：`norm` 对标量和向量都成立（`LinearAlgebra.norm(5) == 5`）——泛型误差度量的最后一块拼图；步长伸缩限幅 [0.2, 5] 防振荡；`dt < 1e-14` 抛错（步长塌缩 = 问题可能刚性，该换隐式法——教程边界）。

## 24.5 数值验证：收敛阶是可断言的性质（18 章三件套的完整体现）

**收敛阶**：dt 减半，一阶方法误差减半（比值 2），四阶方法误差除以 16：

```julia
prob = ODEProblem((u, t) -> -u, 1.0, (0.0, 1.0))    # 解析解 exp(-t)
eerr(dt) = abs(solve(prob, Euler(dt)).u[end] - exp(-1.0))
@test 1.8 < eerr(0.01) / eerr(0.005) < 2.2          # Euler：一阶
@test 12 < rerr(0.05) / rerr(0.025) < 20            # RK4：四阶（比值 ≈ 16）
```

实测输出（main.jl 演示 1）：

```text
Euler    0.1   1.9201e-02      —
Euler    0.05  9.3935e-03    ×2.0
Euler    0.025 4.6470e-03    ×2.0
RK4      0.2   5.7970e-06      —
RK4      0.1   3.3324e-07    ×17.4
RK4      0.05  1.9976e-08    ×16.7
RKF45 自适应 tol=1e-8：末端误差 5.55e-08，接受 12 步 / 拒绝 0 步
```

**能量守恒**（单摆，守恒系统的性质测试）：

```julia
energy(u) = u[2]^2 / 2 + (1 - cos(u[1]))
drift = maximum(abs.(energy.(sol.u) .- energy(prob.u0)))
@test drift < 1e-8                 # RK4 实测 1.12e-10
@test drift_e > 100 * drift        # Euler 同步长 5.95e-02——差 5×10⁸ 倍
```

**混沌系统**（洛伦兹）：不能断言"接近某条轨迹"（Lyapunov 指数放大一切），断言的是**性质**——有限性、确定性（同参数逐位复现）、轨迹有界（z 围绕 ρ-1=27）：

```julia
sol = solve(prob, RKF45(0.01, 1e-6))
@test sol == solve(prob, RKF45(0.01, 1e-6))              # 确定性
@test maximum(u -> abs(u[3] - 27), sol.u[200:end]) < 40   # 被吸引子约束
# 实测：接受 717 步 / 拒绝 87 步，步长范围 [1.0e-2, 4.3e-2]——快变段自动收紧
```

## 24.6 CLI 与演示入口（02/17 章）

`main.jl` 无参数跑全部三个演示（`@main` 空参数约定），带参选演示：

```julia
const DEMO_FN = Dict("decay" => demo_decay, "pendulum" => demo_pendulum, "lorenz" => demo_lorenz)
function run_cli(args)::Int
    names = isempty(args) ? collect(DEMOS) : args
    count = 0
    for name in names
        fn = get(DEMO_FN, name, nothing)
        fn === nothing ? println("未知演示：$(name)") : (fn(); count += 1)
    end
    count
end
function @main(args)
    isempty(args) && println("（无参数：跑全部演示）")
    run_cli(args)
    println("==== 24 结束 ====")
end
```

测试端到端直接调 `run_cli(["decay"]) == 1`、`run_cli(["nope"]) == 0`——不经过子进程。

## 24.7 运行与验证

```powershell
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 24_miniode   # instantiate + 运行 + 测试
julia --project=examples/24_miniode/env examples/24_miniode/main.jl lorenz
```

## 24.8 坑位清单

1. **`t0 .+ (0:n) .* h` 是惰性范围**：`setindex!` 直接 CanonicalIndexError——先 `collect`（24.3 实测；范围默认不可变，11 章惰性美德的另一面）。
2. **ODESolution 的 `==` 要自定义**：含 Vector 字段的 struct 默认 `==` 落到 `===`（身份）——"两次求解逐位相同"的断言会挂；值语义自己写（08 章坑位在本章的正面应用）。
3. **混沌系统别断言轨迹逼近**：Lyapunov 放大让任何参考值失效——断言有限性/确定性/有界性这类**性质**（24.5）。
4. **收敛阶断言留余量**：比值是 2/16 加 O(dt) 修正项——区间 (1.8, 2.2)/(12, 20) 而不是精确等式（18 章性质测试的分寸）。
5. **浮点末端漂移**：`t0 + n*h` ≠ `tf`（哪怕数学上相等）——显式 `t[end] = tf` 或 `min(tk + dt, tf)` 收口（24.3/24.4）。
6. **步长塌缩要报错而不是死循环**：刚性问题上显式法会 dt→0——设下限并抛错，提示换隐式法（24.4）。

## 24.9 延伸方向

- 更多算法：Heun（二阶）、Dormand-Prince（ode45 的 DP 表）、隐式 Euler（刚性问题入门）；
- 事件函数与回调（SciML 的 `ContinuousCallback` 思路：过零检测 + 状态跳变）；
- dense output（步内插值）与绘制（Plots.jl/Makie.jl）；
- 性能：与 DifferentialEquations.jl 的 Tsit5 对比步数/耗时（16 章方法）；
- 包装成微分方程之外的同类问题：`solve(QuadratureProblem(...), GaussKronrod())`——三件套架构的复用边界。
