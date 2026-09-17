# 10 示例测试：广播语义
using Test
include("main.jl")

@testset "10_broadcast" begin
    @testset "广播基础" begin
        @test sin.(0:1) ≈ [0.0, sin(1)]
        @test [1, 2] .* [3, 4] == [3, 8]
        @test "x" .* ["a", "b"] == ["xa", "xb"]
        @test [0.5, 1.5] .|> round == [0.0, 2.0]      # .|> 向量化管道
    end
    @testset "维度扩展" begin
        @test [1, 2] .+ [10 20 30] == [11 21 31; 12 22 32]
        @test zeros(Int, 2, 2) .+ [1, 2] == [1 1; 2 2]   # (2,) 对齐第一维（行）
    end
    @testset "融合与就地" begin
        a = [1.0, 2.0, 3.0]
        b = @. a * 2 + 1
        @test b == [3.0, 5.0, 7.0]
        a .= 0                                        # 就地清零（不新建数组）
        @test a == [0.0, 0.0, 0.0] && a === a
        c = [1, 2]
        c .*= 5
        @test c == [5, 10]
    end
    @testset "陷阱" begin
        @test_throws TypeError [true, false] && [true, true]   # && 只吃标量
        @test ([true, false] .& [true, true]) == [true, false]
        @test floor.([1.7]) == [1.0]
        @test round.(Int, [1.6, 1.4]) == [2, 1]       # round.(Int, xs) 带类型的广播
    end
end
