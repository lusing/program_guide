# 13 示例测试：异常语义
using Test
include("main.jl")

@testset "13_errors" begin
    @testset "内建异常" begin
        @test throws_error(() -> UInt8(300)) === InexactError
        @test throws_error(() -> sqrt(-1)) === DomainError
        @test throws_error(() -> "a" * 1) === MethodError
        @test throws_error(() -> 1 // 0) === nothing       # 有理数：分母 0 直接报错？不——1//0 是合法的 Inf
    end
    @testset "try/catch/finally" begin
        @test safe_div(-6, 2) == -3
        @test safe_div(1, 2) == 0
        log = []
        result = try
            push!(log, :try)
            42
        finally
            push!(log, :finally)
        end
        @test result == 42 && log == [:try, :finally]
    end
    @testset "自定义异常" begin
        st = Dict("A1" => 5)
        @test Orders.place_order!(st, "A1", 5) == 5
        @test st["A1"] == 0
        @test_throws Orders.InsufficientStock Orders.place_order!(st, "A1", 1)
        @test_throws Orders.InvalidSku Orders.place_order!(st, "ZZ", 1)
        @test sprint(showerror, Orders.InsufficientStock("B2", 9, 1)) == "库存不足：B2 要 9 有 1"
    end
    @testset "nothing 语义" begin
        @test find_first_negative([0, 0]) === nothing
        @test find_first_negative([-1]) == 1
    end
end
