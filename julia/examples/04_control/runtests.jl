# 04 示例测试：控制流语义断言
using Test
include("main.jl")

@testset "04_control" begin
    @testset "if 是表达式" begin
        @test classify(9) == "其他"
        @test classify(30) == "三五公倍"
        @test (1 > 2 ? "a" : "b") == "b"
    end
    @testset "循环" begin
        @test countdown(10) == 55
        @test [i^2 for i in 1:4] == [1, 4, 9, 16]      # comprehension 属 11 章，这里先混个脸熟
        @test sum(1:100) == 5050
        @test collect(3:2:9) == [3, 5, 7, 9]
        @test collect('a':'c') == ['a', 'b', 'c']
    end
    @testset "break/continue/goto" begin
        @test firstnegrow([1 1; 2 2]) == 0
        @test firstnegrow([-1 1; 2 2]) == 1
        @test countodd(1:9) == 5
        @test countodd(2:2:8) == 0
        @test collatz_len(27) == 111
        @test collatz_len(1) == 0
    end
    @testset "作用域" begin
        y = 7
        for y in 1:5; end
        @test y == 7                                  # 循环变量独立作用域
        let y = 1
            y += 1
        end
        @test y == 7                                  # let 也不污染
    end
end
