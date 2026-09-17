# 24 示例测试：收敛阶 / 自适应 / 泛型状态 / 端到端（--project=env 由 build.ps1 传入）
using Test
include("main.jl")

@testset "24_miniode" begin
    @testset "收敛阶（decay 有解析锚）" begin
        prob = ODEProblem((u, t) -> -u, 1.0, (0.0, 1.0))
        exact = exp(-1.0)
        eerr(dt) = abs(solve(prob, Euler(dt)).u[end] - exact)
        rerr(dt) = abs(solve(prob, RK4(dt)).u[end] - exact)
        @test 1.8 < eerr(0.01) / eerr(0.005) < 2.2          # Euler：一阶
        @test 12 < rerr(0.05) / rerr(0.025) < 20            # RK4：四阶（比值 ≈ 16）
        @test eerr(0.005) < 2e-3 && rerr(0.05) < 1e-5       # 绝对量级
        s3 = solve(prob, RK4(0.3))
        @test s3.naccept == 4 && length(s3.u) == 5          # 步数对齐：ceil(1/0.3)=4 段 5 点
    end

    @testset "RKF45 自适应" begin
        prob = ODEProblem((u, t) -> -u, 1.0, (0.0, 1.0))
        sol = solve(prob, RKF45(0.01, 1e-8))
        @test abs(sol.u[end] - exp(-1.0)) < 1e-6
        @test sol.naccept > 10 && sol.naccept >= sol.nreject
        @test sol.t[end] == 1.0                             # 收尾精确落在 tspan[2]
        errs = [abs(solve(prob, RKF45(0.01, tol)).u[end] - exp(-1.0)) for tol in (1e-3, 1e-6, 1e-9)]
        @test errs[1] > errs[2] > errs[3]                   # tol 收紧误差单调下降
        @test sol == solve(prob, RKF45(0.01, 1e-8))         # 确定性（自定义 == 值语义）
    end

    @testset "向量状态（单摆能量守恒）" begin
        prob = ODEProblem((u, t) -> [u[2], -sin(u[1])], [2.5, 0.0], (0.0, 10.0))
        sol = solve(prob, RK4(0.01))
        energy(u) = u[2]^2 / 2 + (1 - cos(u[1]))
        @test length(sol.u) == sol.naccept + 1 == 1001
        drift = maximum(abs.(energy.(sol.u) .- energy(prob.u0)))
        drift_e = maximum(abs.(energy.(solve(prob, Euler(0.01)).u) .- energy(prob.u0)))
        @test drift < 1e-8                                  # RK4 长积分能量漂移
        @test drift_e > 100 * drift                          # Euler 攒误差快几个量级
    end

    @testset "洛伦兹（自适应混沌）" begin
        f(u, t) = [10 * (u[2] - u[1]), u[1] * (28 - u[3]) - u[2], u[1] * u[2] - 8u[3] / 3]
        prob = ODEProblem(f, [1.0, 1.0, 1.0], (0.0, 20.0))
        sol = solve(prob, RKF45(0.01, 1e-6))
        @test all(isfinite, sol.u[end])
        @test sol.naccept > 200
        @test maximum(u -> abs(u[3] - 27), sol.u[200:end]) < 40   # 轨迹被吸引子约束（z 围绕 ρ-1=27）
    end

    @testset "CLI 端到端" begin
        @test (@test_nowarn run_cli(["decay"])) == 1
        @test run_cli(["decay", "lorenz"]) == 2
        @test run_cli(["nope"]) == 0                          # 未知演示：提示并计 0
    end
end
