# 02 示例测试：先 include 主文件（会执行演示体），再对关键行为断言
using Test
include("main.jl")

@testset "02_hello" begin
    @test greet("Julia") == "你好，Julia！"
    @test greet("") == "你好，！"
    @test "a" * "b" == "ab"
    @test "ab" ^ 3 == "ababab"
    @test string(3) * "x" == "3x"
    @test length("你好") == 2          # 字符数（码点），不是字节数
    @test occursin("Julia", "Hello, Julia")
end
