# 16 示例测试：性能语义（只断言确定性事实，不断言机器速度）
using Test
include("main.jl")

@testset "16_performance" begin
    @testset "类型稳定性" begin
        @test Base.return_types(stable, (Float64,)) == [Float64]
        @test Base.return_types(unstable, (Float64,)) == [Union{Float64, Int64}]
        @test Base.return_types(x -> x^2, (Float64,)) == [Float64]
        @test stable(-2.0) == 0.0 && unstable(2.0) == 2.0
    end
    @testset "分配" begin
        @test (@allocated alloc_good()) == 0          # include 时已预热
        @test (@allocated alloc_bad()) > 0
        @test alloc_good() == 333_833_500
    end
    @testset "结果正确性" begin
        using LinearAlgebra
        v = randn(64)
        @test isapprox(sum_inbounds(v), sum(v))
        @test isapprox(colsums_view(big), colsums_copy(big))
        @test sum_const(100) == sum_global(100)
    end
    @testset "容器元素类型" begin
        @test eltype(v_any) == Any && eltype(v_f) == Float64
        @test !isconcretetype(eltype(v_any))
    end
end
