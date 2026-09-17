# 05 示例测试：函数定义/参数/高阶函数语义
using Test
include("main.jl")

@testset "05_functions" begin
    @testset "定义与返回" begin
        @test add(-1, 1) == 0
        @test square(1 // 2) == 1 // 4            # 泛型：对有理数也成立
        @test minmax(2, 2) == (2, 2)
        @test toint(2.4) == 2
        @test_throws InexactError toint(2.5e19)   # 超出 Int64 的浮点无四舍五入可言
    end
    @testset "参数族" begin
        @test charge(200) ≈ 226.0
        @test charge(200; tax = 0.5) ≈ 300.0
        @test powsum(1) == 3
        @test varsum() == 0
        @test varsum([5, 5]...) == 10
        @test charge(10; (tax = 0.1,)...) ≈ 11.0
    end
    @testset "高阶函数" begin
        @test map(x -> x + 1, [1, 2]) == [2, 3]
        @test filter(iseven, 1:6) == [2, 4, 6]
        @test reduce(max, [3, 1, 4, 1, 5]) == 5
        @test [op(10, 2) for op in [+, -, *, ÷]] == [12, 8, 20, 5]
        @test (5 |> x -> x^2 |> x -> x - 1) == 24
        @test (abs ∘ (-))(3) == 3                 # (-)(3) = -3 → abs → 3
        @test normalize([3, 3]) == [1.0, 1.0]
    end
    @testset "do 块" begin
        @test map(1:3) do x; x^2; end == [1, 4, 9]
        @test sort(["ccc", "a", "bb"]; by = length) == ["a", "bb", "ccc"]
        @test sort([2, 3, 1]; lt = (a, b) -> a > b) == [3, 2, 1]   # lt= 自定义比较
    end
end
