# MiniODE 包自身的测试（Pkg.test 入口；两个入口跑的是上级 runtests.jl）
using Test
using MiniODE

@testset "MiniODE" begin
    @testset "固定步长收敛阶" begin
        prob = ODEProblem((u, t) -> -u, 1.0, (0.0, 1.0))
        exact = exp(-1.0)
        eerr(dt) = abs(solve(prob, Euler(dt)).u[end] - exact)
        rerr(dt) = abs(solve(prob, RK4(dt)).u[end] - exact)
        @test 1.8 < eerr(0.01) / eerr(0.005) < 2.2          # Euler：一阶
        @test 12 < rerr(0.05) / rerr(0.025) < 20            # RK4：四阶（比值 ≈ 16）
    end
    @testset "自适应" begin
        prob = ODEProblem((u, t) -> -u, 1.0, (0.0, 1.0))
        sol = solve(prob, RKF45(0.01, 1e-8))
        @test abs(sol.u[end] - exp(-1.0)) < 1e-6
        @test sol == solve(prob, RKF45(0.01, 1e-8))          # 确定性（== 是自定义值语义）
    end
    @testset "泛型状态" begin
        prob = ODEProblem((u, t) -> [u[2], -u[1]], [0.0, 1.0], (0.0, π / 2))  # u''=-u
        sol = solve(prob, RK4(0.001))
        @test sol.u[end][1] ≈ sin(π / 2) atol = 1e-6          # 精确解 sin(t)
    end
end
