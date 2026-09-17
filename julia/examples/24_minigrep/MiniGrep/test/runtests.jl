# MiniGrep 包自身的测试（Pkg.test 入口；本教程的 build.ps1 跑的是上级 runtests.jl）
using Test
using MiniGrep

@testset "MiniGrep" begin
    d = mktempdir()
    write(joinpath(d, "a.txt"), "hello world\njulia hello\n")
    mkpath(joinpath(d, "sub"))
    write(joinpath(d, "sub", "b.md"), "hello again\n")

    hits = search_dir(r"hello", d)
    @test length(hits) == 3
    @test hits[1].lineno == 1
    @test search_dir(r"nothing", d) == MiniGrep.Hit[]
    @test search_dir_threads(r"hello", d) == hits   # 多线程版结果与串行一致
    @test occursin("\e[1;31mhello\e[0m",
                   highlight("hello world", MiniGrep.match_ranges(r"hello", "hello world")))
    @test highlight("abc", MiniGrep.match_ranges(r"z", "abc")) == "abc"
end
