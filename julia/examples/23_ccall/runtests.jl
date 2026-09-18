# 22 示例测试：C 互操作语义
using Test
include("main.jl")

@testset "23_ccall" begin
    @testset "基础调用" begin
        x = -2.5                                    # @ccall 的 name::T 传的是变量值
        @test ccall((:strlen, CLIB), Csize_t, (Cstring,), "abc") == 3
        @test ccall((:abs, CLIB), Cint, (Cint,), -7) == 7
        @test (@ccall CLIB.fabs(x::Cdouble)::Cdouble) == 2.5
        @test_throws ErrorException @ccall "不存在的库".nope(("x"::Cstring))::Cint
    end
    @testset "回调排序" begin
        @test qsort_ints(Cint[3, 1, 2]) == Cint[1, 2, 3]
        @test qsort_ints(Cint[]) == Cint[]
        @test qsort_ints(Cint[7, 7, 7]) == Cint[7, 7, 7]     # 相等元素稳定通过
    end
    @testset "指针语义" begin
        w = Cint[4, 5, 6]
        @test unsafe_load(pointer(w), 1) == 4
        unsafe_store!(pointer(w), 9, 3)
        @test w[3] == 9                          # 写指针即写数组（同一内存）
    end
end
