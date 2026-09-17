# 17 示例测试：在 env 环境中验证本地包（--project=env 由 build.ps1 传入）
using Test
include("main.jl")

@testset "17_pkgenv" begin
    @testset "与 Statistics 交叉验证" begin
        for v in ([1.0, 2.0, 3.0], rand(17), fill(π, 5))
            @test average(v) ≈ mean(v)
            @test variance(v) ≈ var(v)
            @test variance(v; corrected = false) ≈ var(v; corrected = false)
        end
    end
    @testset "movavg" begin
        @test movavg(1.0:5.0, 1) == collect(1.0:5.0)
        @test movavg([1.0, 2.0], 2) == [1.5]
        @test_throws ArgumentError movavg(Int[], 1)
        @test length(movavg(rand(100), 10)) == 91
    end
    @testset "zscore" begin
        z = zscore([1.0, 2.0, 3.0])
        @test sum(z) ≈ 0 atol = 1e-12
        @test sqrt(sum(z .^ 2)) ≈ sqrt(2)      # n-1 样本方差下模长 √(n-1)
        @test_throws ArgumentError zscore([1.0, 1.0])
    end
    @testset "环境" begin
        @test isfile(joinpath(@__DIR__, "env", "Project.toml"))
        @test isfile(joinpath(@__DIR__, "MathTools", "src", "MathTools.jl"))
    end
end
