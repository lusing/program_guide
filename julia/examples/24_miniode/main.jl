# 24 实战：迷你 ODE 求解器——包工程（MiniODE 包 + 演示 CLI）
# 结构：MiniODE/（src + test）+ env/（环境）+ 本入口
# 运行（两个入口自动加 --project=env；env/Manifest.toml 已入库，直接跑即可）：
#   julia --project=env main.jl               # 三个演示：decay / pendulum / lorenz
#   julia --project=env main.jl lorenz        # 只跑某一个
# 求解器为纯数值串行内核——多线程旗标不影响结果（不同于 21 章的并行搜索）

using MiniODE
using Printf

const DEMOS = ("decay", "pendulum", "lorenz")

# ── 演示 1：指数衰减 u' = -u——有解析锚，验证收敛阶（误差随 dt 减半的比值 ≈ 阶数）
function demo_decay()
    println("── 演示 1：u' = -u, u(0)=1，t ∈ [0,1]（解析解 exp(-t)）")
    prob = ODEProblem((u, t) -> -u, 1.0, (0.0, 1.0))
    exact = exp(-1.0)
    @printf("   %-7s %8s %14s %12s\n", "方法", "dt", "末端误差", "比值")
    for (name, Alg, dts, order) in (("Euler", Euler, (0.1, 0.05, 0.025), 1),
                                     ("RK4", RK4, (0.2, 0.1, 0.05), 4))
        prev = 0.0
        for dt in dts
            err = abs(solve(prob, Alg(dt)).u[end] - exact)
            ratio = prev > 0 ? prev / err : NaN
            @printf("   %-7s %8.4g %14.4e %12s\n", name, dt, err,
                    isfinite(ratio) ? "×$(round(ratio; digits = 1))" : "—")
            prev = err
        end
        println("   ↑ dt 减半误差比值 ≈ 2^$(order)（$(name) 是 $(order) 阶方法）")
    end
    sol = solve(prob, RKF45(0.01, 1e-8))
    @printf("   RKF45 自适应 tol=1e-8：末端误差 %.2e，接受 %d 步 / 拒绝 %d 步\n",
            abs(sol.u[end] - exact), sol.naccept, sol.nreject)
    @assert abs(solve(prob, RK4(0.025)).u[end] - exact) < 1e-5
end

# ── 演示 2：单摆 u'' = -sin(u)——向量状态 [θ, ω]，RK4 的能量漂移作性质检验
function demo_pendulum()
    println("── 演示 2：单摆 u'' = -sin(u)（大摆幅 2.5 rad，状态 [θ, ω]）")
    prob = ODEProblem((u, t) -> [u[2], -sin(u[1])], [2.5, 0.0], (0.0, 10.0))
    energy(u) = u[2]^2 / 2 + (1 - cos(u[1]))
    sol4 = solve(prob, RK4(0.01))
    drift4 = maximum(abs.(energy.(sol4.u) .- energy(prob.u0)))
    sole = solve(prob, Euler(0.01))
    drifte = maximum(abs.(energy.(sole.u) .- energy(prob.u0)))
    @printf("   RK4(0.01)：1000 步，能量漂移 %.2e\n", drift4)
    @printf("   Euler(0.01)：1000 步，能量漂移 %.2e（差 ~%d 倍——低阶方法在守恒系统上攒误差）\n",
            drifte, round(Int, drifte / drift4))
    @assert drift4 < 1e-8
end

# ── 演示 3：洛伦兹系统——RKF45 在混沌轨道上自动伸缩步长
function demo_lorenz()
    println("── 演示 3：洛伦兹系统（σ=10, ρ=28, β=8/3，混沌）")
    f(u, t) = [10 * (u[2] - u[1]), u[1] * (28 - u[3]) - u[2], u[1] * u[2] - 8u[3] / 3]
    prob = ODEProblem(f, [1.0, 1.0, 1.0], (0.0, 20.0))
    sol = solve(prob, RKF45(0.01, 1e-6))
    dts = diff(sol.t)
    @printf("   接受 %d 步 / 拒绝 %d 步；步长范围 [%.2e, %.2e]（快变段自动收紧）\n",
            sol.naccept, sol.nreject, minimum(dts), maximum(dts))
    println("   t=20 末端点 = ", round.(sol.u[end]; digits = 3))
    @assert all(isfinite, sol.u[end])
    @assert sol == solve(prob, RKF45(0.01, 1e-6))   # 同参数逐位复现
end

const DEMO_FN = Dict("decay" => demo_decay, "pendulum" => demo_pendulum, "lorenz" => demo_lorenz)

"""CLI 主逻辑（可被测试直接调用）：返回成功运行的演示数"""
function run_cli(args)::Int
    names = isempty(args) ? collect(DEMOS) : args
    count = 0
    for name in names
        fn = get(DEMO_FN, name, nothing)
        if fn === nothing
            println("未知演示：$(name)（可选 decay / pendulum / lorenz）")
        else
            fn()
            count += 1
        end
    end
    count
end

function @main(args)                    # 入口容忍空参数（02 章约定：-e include 也触发）
    isempty(args) && println("（无参数：跑全部演示——$(join(DEMOS, " / "))）")
    run_cli(args)
    println("==== 24 结束 ====")
end
