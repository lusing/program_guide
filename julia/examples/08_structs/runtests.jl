# 08 示例测试：struct 语义断言
using Test
include("main.jl")

@testset "08_structs" begin
    @testset "不可变与可变" begin
        @test isbitstype(Point)
        @test p.x == 1.0                       # include 后顶层变量仍可用
        @test Counter(5).n == 5
        @test Point(0.5, 0.5) === Point(0.5, 0.5)
        @test Counter(0) !== Counter(0)        # 可变对象按身份区分
    end
    @testset "转换与 @kwdef" begin
        @test NamedPoint("a", 2).x === 2.0
        @test ServerConfig(debug = true).debug
        @test ServerConfig().host == "localhost"
    end
    @testset "构造器" begin
        @test Point((1.0, 2.0)) == Point(1.0, 2.0)
        @test origen() == Point(0.0, 0.0)
        @test Email("X@Y.Z").addr == "x@y.z"
        @test_throws ArgumentError Email("bad")
        @test_throws ArgumentError Meter(-2)
        @test Meter(2.5) isa Meter{Float64}
    end
    @testset "参数化" begin
        @test Box(2im).value == 2im            # Complex 也能装
        @test unwrap(Box(1.5)) == (1.5, Float64)
        @test !(Box{Real} <: Box{Int}) && Box{Real} <: Box
        @test Box(1) isa Box{<:Integer}
        @test Unit() === Unit()
    end
end
