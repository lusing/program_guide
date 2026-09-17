# 11 示例测试：集合与迭代语义
using Test
include("main.jl")

@testset "11_collections" begin
    @testset "元组" begin
        @test () isa Tuple && (1,) isa Tuple{Int}
        @test t[2] == "二"
        @test nt.year == 2012
        @test keys(nt) == (:name, :year)
        @test minmax_avg([2, 4]) == (2, 4, 3.0)
    end
    @testset "Dict" begin
        @test length(d) == 2                       # main 里最终剩 apple、date
        @test get(d, "nope", -1) == -1
        d2[:c] = 3
        @test haskey(d2, :c)
        @test merge(Dict(:a => 1), Dict(:a => 2))[:a] == 2   # 后者覆盖
        @test_throws KeyError d["nope"]            # 裸取不存在键 → KeyError
    end
    @testset "Set" begin
        @test length(Set("aabbc")) == 3            # 字符串也是可迭代物
        @test symdiff(Set(1:3), Set(2:4)) == Set([1, 4])
        @test ⊆(Set([1]), Set(1:3))                # 子集（\subseteq）
    end
    @testset "sort" begin
        @test sort([3, 1, 2]; lt = (x, y) -> x > y) == [3, 2, 1]
        @test sortperm(["c", "a", "b"]) == [2, 3, 1]
        @test sort!([2, 1]) == [1, 2]
        @test sort(words; by = length)[1] == "fig"
        @test issorted(sort(words; by = length); by = length)   # issorted 也要传 by
    end
    @testset "迭代器与推导" begin
        @test collect(zip(1:0, 'a':'z')) == []          # 空 range 的 zip 是空
        @test sum(x + y for (x, y) in zip(1:3, 10:10:30)) == 66
        @test [i == j for i in 1:2, j in 1:2] == Bool[1 0; 0 1]
        @test Dict(i => 1 for i in 1:2) isa Dict{Int, Int}
        @test collect(Iterators.drop(1:5, 2)) == [3, 4, 5]
        @test sum(i for i in 1:3 if isodd(i)) == 4   # generator + if 过滤
    end
end
