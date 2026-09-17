# 15 示例测试：参数化与接口
using Test
include("main.jl")

@testset "15_generics" begin
    @testset "where 与约束" begin
        @test firstel(["a"]) == ("a", String)
        @test same_type(1.0, 2.0)
        @test !same_type(Int8(1), Int16(1))
        @test_throws MethodError pairsum("a", "b")
    end
    @testset "Type{T} 与 Val" begin
        @test whattype(Float64) == "浮点"
        @test whattype(Bool) == "其他：Bool"
        @test zero_like(Complex{Int}) == 0 + 0im
        @test vec_of(Float64, 1) == [0.0]
        @test valmirror(Val(2)) == "二"
    end
    @testset "SVec 接口" begin
        sv2 = SVec([2.0, 4.0])
        @test length(sv2) == 2 && eltype(sv2) == Float64
        @test sv2 == [2.0, 4.0]                    # AbstractVector 的 == 免费得到
        @test sum(sv2 ./ 2) == 3.0
        @test maximum(SVec([5, 9])) == 9
        @test sort(SVec([3, 1, 2]); rev = true) == [3, 2, 1]
        @test map(+, SVec([1, 2]), SVec([10, 20])) == [11, 22]
    end
    @testset "泛型算法" begin
        @test fillall(zeros(Int, 3), 2) == [2, 2, 2]
        @test mydot([2.0], [3.0]) == 6.0
        @test mydot2([1, 1], [1, 1]) == 2
    end
end
