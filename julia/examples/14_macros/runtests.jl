# 14 示例测试：元编程语义
using Test
include("main.jl")

@testset "14_macros" begin
    @testset "Expr 是数据" begin
        e = :(f(x, 1))
        @test e.head == :call && e.args == [:f, :x, 1]
        @test Expr(:call, :+, 1, 2) == :(1 + 2)
        @test eval(Expr(:call, :*, 6, 7)) == 42
        @test :(a = 1) isa Expr && :a isa Symbol
    end
    @testset "宏" begin
        @test @twice(4) == 8
        @test_throws MethodError @twice("ab")     # 字符串拼接是 * 不是 +（12 章）
        @test occursin("+", string(macroexpand(Main, :(@twice x))))
        ran2 = Ref(false)
        @unless false begin
            ran2[] = true
        end
        @test ran2[]
    end
    @testset "卫生" begin
        @test (@setvar z 11) == 11 && z == 11
        a1, b1 = 100, 200
        @swap_vars a1 b1
        @test (a1, b1) == (200, 100)
    end
    @testset "世界年龄" begin
        @test call_via_invokelatest() == 99
        # 注意：new_fn 已在 include main.jl 时首次定义——重复 @eval 同一定义不产生新世界，
        # 因此这里 try_call_new() 能成功；MethodError 只在"首次定义后的旧世界调用"出现（main 演示已验证）。
        @test try_call_new() == 99
    end
    @testset "@generated" begin
        @test myzero(Float64) == 0.0
        @test myzero(Vector) == "无零值"
    end
end
