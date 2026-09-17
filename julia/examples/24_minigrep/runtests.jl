# 24 示例测试：端到端 + 单元（--project=env 由 build.ps1 传入）
using Test
include("main.jl")

@testset "24_minigrep" begin
    # ── 构造已知内容的目录树
    tree = mktempdir()
    mkpath(joinpath(tree, "b"))
    write(joinpath(tree, "a.txt"), "alpha julia beta\nno match here\njulia again\n")
    write(joinpath(tree, "b", "c.md"), "Julia 大写不命中\njulia 小写命中\n")
    write(joinpath(tree, "b", "skip.bin"), "julia")          # 扩展名过滤

    @testset "单元：search_file" begin
        hits = search_file(r"julia", joinpath(tree, "a.txt"))
        @test length(hits) == 2
        @test hits[1].lineno == 1 && hits[2].lineno == 3
        @test hits[1].line == "alpha julia beta"
        @test length(hits[1].ranges) == 1
    end

    @testset "串行 vs 多线程一致" begin
        s = search_dir(r"julia", tree)
        t = search_dir_threads(r"julia", tree)
        @test s == t                                   # 确定性：排序后完全一致
        @test length(s) == 3                           # a.txt×2 + b/c.md×1
        @test all(h -> endswith(h.path, ".txt") || endswith(h.path, ".md"), s)
    end

    @testset "高亮" begin
        @test highlight("xx julia yy", MiniGrep.match_ranges(r"julia", "xx julia yy")) ==
              "xx \e[1;31mjulia\e[0m yy"
        @test highlight("a julia b julia c", MiniGrep.match_ranges(r"julia", "a julia b julia c")) ==
              "a \e[1;31mjulia\e[0m b \e[1;31mjulia\e[0m c"   # 多段命中
        @test highlight("julia 行首", MiniGrep.match_ranges(r"julia", "julia 行首")) ==
              "\e[1;31mjulia\e[0m 行首"                 # 行首命中（空前置段边界）
        @test highlight("中文 julia", MiniGrep.match_ranges(r"julia", "中文 julia")) ==
              "中文 \e[1;31mjulia\e[0m"                 # 多字节前置段（字节下标切分正确）
    end

    @testset "CLI 端到端" begin
        n = @test_nowarn run_cli(["julia", tree])       # 带参调用：打印但不产生警告
        @test n == 3
        @test run_cli(["(?i)julia", tree]) == 4         # 忽略大小写（含 Julia 大写行）
        @test run_cli(["nothing", tree]) == 0
        @test_throws ErrorException Regex("(")          # 坏正则在构造处抛（run_cli 内部已消化）
    end
end
