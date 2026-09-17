# 18 示例测试：对测试工具本身的测试
using Test
include("main.jl")

# 只在 runtests 里定义的小工具（注意：顶层代码按顺序执行，函数要先定义再使用）
tryparse_nothing(x) = x == 1 ? throw(ArgumentError("一号不许")) : x

@testset "18_testing" begin
    @testset "tokenize 补充" begin
        @test tokenize("A B C") == ["a", "b", "c"]
        @test wordcount("Hello,  World") == 2      # 标点属于词（当前实现的边界）
        @test_throws ArgumentError tryparse_nothing(1)
        @test tryparse_nothing(2) == 2
    end
    @testset "测试基建类型" begin
        @test Test.DefaultTestSet <: Test.AbstractTestSet
        @test Test.Pass <: Test.Result              # 三种结果类型：过/挂/异常
        @test Test.Fail <: Test.Result
        @test Test.Error <: Test.Result
    end
    @testset "seed 可复现" begin
        Random.seed!(42)
        a = rand(5)
        Random.seed!(42)
        b = rand(5)
        @test a == b                               # 同 seed 同序列
    end
end
