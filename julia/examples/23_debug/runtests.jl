# 23 示例测试：调试工具语义
using Test
include("main.jl")

@testset "23_debug" begin
    @testset "栈跟踪" begin
        @test length(frames) >= 2
        @test occursin("inner", join((string(f.func) for f in frames), " "))
        deep() = error("x")
        fs = try; deep(); catch; stacktrace(Base.current_exceptions()[end][2]); end
        @test any(f -> f.func === :deep, fs)
    end
    @testset "异常格式化" begin
        @test sprint(showerror, DomainError(-1, "sqrt 将抛")) isa String
        err = try; throw(KeyError(:k)); catch e; e; end
        @test err isa KeyError
        @test occursin("k", sprint(showerror, err))
    end
    @testset "@locals 与计时" begin
        @test where_am_i(2) == (true, 4)
        @test (@elapsed probe_me(v1)) >= 0
        @test (@allocated probe_me(v1)) == 0
    end
end
