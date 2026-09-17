# 09 示例测试：数组语义
using Test
include("main.jl")

@testset "09_arrays" begin
    @testset "构造" begin
        @test zeros(Bool, 2) == [false, false]
        @test length(Vector{Int}(undef, 5)) == 5
        @test fill(0, (2, 2)) == [0 0; 0 0]
        @test collect(10:-3:1) == [10, 7, 4, 1]
    end
    @testset "索引" begin
        @test a[2:3] == [6, 7]
        @test a[[true, false, true, false]] == [5, 7]
        @test m[2, :] == [4, 5, 6]
        @test m[[2, 1], :] == [4 5 6; 1 2 3]     # 花式索引可重排
        @test_throws BoundsError a[5]            # 越界有检查（--check-bounds=yes 下必查）
    end
    @testset "视图" begin
        v2 = @view a[1:2]
        @test v2 == [5, 6] && v2 isa SubArray
        w = @view m[:, 2]
        w[1] = 50
        @test m[1, 2] == 50                      # 视图改，母体变
        m[1, 2] = 2                              # 恢复
    end
    @testset "增删" begin
        z = Int[]
        push!(z, 1); append!(z, [2, 3])
        @test z == [1, 2, 3]
        @test popat!(z, 2) == 2                  # popat!：按下标取走
        @test z == [1, 3]
        @test deleteat!(copy(z), 1) == [3]       # copy 后删，不动原数组
    end
    @testset "LinearAlgebra" begin
        @test [1.0 0.0; 0.0 1.0] \ [2.0, 3.0] == [2.0, 3.0]   # 单位阵方程
        @test inv([1.0 0.0; 0.0 2.0]) == [1.0 0.0; 0.0 0.5]
        @test [1.0, 2.0] ⋅ [3.0, 4.0] == 11.0                 # ⋅ (\cdot) = dot
        @test isdiag(Matrix{Float64}(I, 2, 2))                # 单位阵 I（UniformScaling）
    end
end
