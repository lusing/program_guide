# 21 示例测试：随机与统计语义（固定种子 → 全部确定性断言）
using Test
using Random
using Statistics
include("main.jl")

@testset "21_randomstats" begin
    @testset "可复现子流" begin
        r1, r2 = Xoshiro(7), Xoshiro(7)
        @test rand(r1, 100) == rand(r2, 100)
        @test rand(r1) != rand(r1)             # 推进
        r3 = Xoshiro(7)
        @test rand(r3, 3) == Xoshiro(7) |> (r -> rand(r, 3))
    end
    @testset "描述统计" begin
        d = [1, 2, 3, 4, 100]                   # 有离群点：中位数稳、均值被拉飞
        @test median(d) == 3 && mean(d) == 22
        @test quantile(d, 0.0) == 1 && quantile(d, 1.0) == 100
        @test cor(d, 2 .* d) ≈ 1.0
        @test abs(cor(d, shuffle(Xoshiro(1), d))) < 0.5   # 重排后相关性应弱
    end
    @testset "蒙特卡洛" begin
        @test abs(mc_pi(200_000, Xoshiro(5)) - π) < 0.02
        @test abs(mc_int(x -> x^2, 200_000, Xoshiro(6)) - 1 / 3) < 0.005   # ∫₀¹x² = 1/3
        # 同种子同结果；不同种子不同结果（但都收敛）
        @test mc_pi(1000, Xoshiro(3)) == mc_pi(1000, Xoshiro(3))
        @test mc_pi(1000, Xoshiro(4)) != mc_pi(1000, Xoshiro(3))
    end
    @testset "CLT 与采样" begin
        s = exp_sample(Xoshiro(9), 50_000)
        @test abs(mean(s) - 1.5) < 0.03
        @test minimum(s) > 0                    # 指数分布支撑在正半轴
        r = Xoshiro(11)                          # rng 提到循环外：每轮新建会拿到同一个样本！
        m = [mean(exp_sample(r, 100)) for _ in 1:1000]
        @test abs(std(m) - 1.5 / 10) < 0.03     # σ/√n
    end
end
