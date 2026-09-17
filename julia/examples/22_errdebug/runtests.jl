# 22 示例测试：异常与调试语义
using Test
include("main.jl")

@testset "22_errdebug" begin
    @testset "内建异常" begin
        @test throws_type(() -> UInt8(300)) === InexactError
        @test throws_type(() -> sqrt(-1)) === DomainError
        @test throws_type(() -> "a" * 1) === MethodError
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
    @testset "栈跟踪" begin
        @test length(frames) >= 2
        @test occursin("inner", join((string(f.func) for f in frames), " "))
        deep() = error("x")
        fs = try; deep(); catch; stacktrace(Base.current_exceptions()[end][2]); end
        @test any(f -> f.func === :deep, fs)
        err = try; throw(KeyError(:k)); catch e; e; end
        @test occursin("k", sprint(showerror, err))
    end
    @testset "即时工具与 nothing 语义" begin
        @test where_am_i(2) == (true, 4)
        @test find_first_negative([0, 0]) === nothing
        @test find_first_negative([-1]) == 1
        @test (@allocated probe_me(v1)) == 0
    end
end
