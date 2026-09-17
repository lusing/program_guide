# 06 示例测试：多重派发语义
using Test
include("main.jl")

@testset "06_dispatch" begin
    @testset "方法选择" begin
        @test collide(1.5, 2) == "未知 × 未知"          # Float × Int 无具体方法
        @test collide(true, false) == "数 × 数"          # 注意：Bool <: Integer！
        @test collide(0x01, 2) == "数 × 数"             # UInt8 <: Integer 也命中
    end
    @testset "按全部实参" begin
        @test overlap(Circle(1), Circle(1)) == "两圆：圆心距判交"
        @test overlap(Rect(1, 1), Rect(1, 1)) == "两矩形：投影判交"
        @test_throws MethodError overlap(Rect(1, 1), Circle(1))   # 无方法也无兜底 → MethodError
    end
    @testset "内省" begin
        @test length(methods(shape_area)) == 3
        @test which(meets, (Int, Int)).sig == Tuple{typeof(meets), Integer, Integer}
        @test occursin("AbstractString", string(which(collide, (Int, String))))  # which 可打印
    end
    @testset "歧义消除" begin
        @test amb(Int32(1), 2.0) == "Int × Float64（消除歧义的桥方法）"
        @test amb(1.5, 2.0) == "Number × Float64"
    end
    @testset "收窄与扩展 Base" begin
        @test toint8(255) == Int8(-1)                   # UInt8 风格环绕
        @test toint8(127) == Int8(127)
        @test (Circle(0.5) + Circle(0.5)) == Circle(1.0)
        @test sprint(show, Circle(1.0)) == "⚪(r=1.0)"
    end
end
