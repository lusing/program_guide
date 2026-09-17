# 07 示例测试：类型系统语义
using Test
include("main.jl")

@testset "07_typesystem" begin
    @testset "类型树" begin
        @test chain(Float16) == [Any, Number, Real, AbstractFloat, Float16]
        @test supertype(Bool) === Integer
        @test Triangle(3, 4, 5) isa Shape
        @test isabstracttype(Shape) && !isconcretetype(Shape)
    end
    @testset "Union" begin
        @test Union{Int, String} <: Any
        @test Int <: Union{Int, String}
        @test !(String <: Union{Int, Float64})
        @test typejoin(String, Int) === Any
        @test promote_type(Int, String) === Any       # 无提升规则时退化为 typejoin
    end
    @testset "nothing 与 missing" begin
        @test (1 == missing) === missing
        @test (missing == missing) === missing
        @test isequal(missing, missing)
        @test isequal(sort([2, missing, 1]), [1, 2, missing])  # missing 排最大；== 会被传染，须 isequal
        @test coalesce(missing, 42) == 42               # missing 兜底
        @test something(nothing, 7) == 7                # nothing 兜底
        @test skipmissing([1, missing, 2]) |> collect == [1, 2]
    end
    @testset "类型是值" begin
        @test nameof_type(Vector{Int}) == "Vector{Int64}"
        @test types[Float64] == "浮点"
        @test typeof(Union{Int, Float64}) === Union     # 单成员 Union{Int} 会坍缩成 Int 本身
    end
end
