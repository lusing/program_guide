# 03 示例测试：数值语义断言（覆盖最容易写错的分支）
using Test
include("main.jl")

@testset "03_numbers" begin
    @testset "整型与溢出" begin
        @test typemax(Int8) + Int8(1) == typemin(Int8)
        @test UInt8(200) + UInt8(100) == UInt8(44)
        @test big"10" ^ 20 == BigInt(10)^20
    end
    @testset "浮点" begin
        @test 0.1 + 0.2 != 0.3
        @test isapprox(0.1 + 0.2, 0.3; atol = 1e-12)
        @test isnan(NaN - NaN)
        @test !isnan(Inf)
        @test 1 / Inf == 0
    end
    @testset "整除家族" begin
        @test (7 ÷ 2, -7 ÷ 2) == (3, -3)
        @test (fld(-7, 2), cld(7, 2)) == (-4, 4)
        @test (rem(-7, 2), mod(-7, 2)) == (-1, 1)
        @test mod(7, -2) == -1
    end
    @testset "有理数与复数" begin
        @test 1 // 2 + 1 // 3 == 5 // 6
        @test 6 // 4 == 3 // 2
        @test (1 + im)^2 == 2im
        @test abs(im) == 1
    end
    @testset "提升与转换" begin
        @test promote(Int8(1), UInt8(2)) == (1, 2)
        @test typeof(2 * 3.0) == Float64
        @test_throws InexactError Int(3.99)       # Int() 不接受非精确值
        @test trunc(Int, -3.99) == -3              # trunc 向零截断
        @test round(Int, 2.5) == 2                # ties to even：2.5 → 2、3.5 → 4
        @test parse(Int, "-7") == -7
    end
    @testset "数值稳定性" begin
        @test abs(bad_cancellation(1e-6) - 0.5) > 1e-6    # 朴素式在 1e-6 已丢掉一半有效位
        @test stable_cancellation(1e-6) ≈ 0.5
        @test kahan_sum([1e16; ones(5)]) == Float64(big(1e16) + 5)
        @test naive_sum([1e16; ones(5)]) != Float64(big(1e16) + 5)
        q1, q2 = stable_quad(1.0, 1e8, 1.0)               # b 为正：根是 -1e8 与 -1e-8
        @test abs(q1 + 1e8) < 1e-7 && q1 * q2 ≈ 1.0
        @test stable_quad(2.0, 0.0, -8.0) == (-2.0, 2.0)  # b=0 分支（sign(0)==0 的坑已绕开）
        @test_throws ErrorException stable_quad(1.0, 0.0, 1.0)
    end
end
