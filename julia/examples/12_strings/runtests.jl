# 12 示例测试：字符串语义
using Test
include("main.jl")

@testset "12_strings" begin
    @testset "Char 与编码" begin
        @test Int('0') == 48
        @test '0' + 1 == '1'                       # Char 与整数运算得 Char
        @test codeunit("中", 1) == 0xE4            # UTF-8 首字节
        @test sizeof("é") == 2 && length("é") == 1
        @test_throws StringIndexError "aé中"[3]    # 第 3 字节不是码点边界
    end
    @testset "常用函数" begin
        @test strip("xxhix", 'x') == "hi"          # 指定字符时两端都剥；单侧用 lstrip/rstrip
        @test split("2026-09-18", '-') == ["2026", "09", "18"]
        @test join(1:3, ", ") == "1, 2, 3"
        @test replace("aaa", "a" => "b", count = 2) == "bba"
        @test findnext("a", "banana", 3) == 4:4
        @test chop("abcd") == "abc" && chop("abcd"; head = 2, tail = 1) == "c"
    end
    @testset "正则" begin
        @test match(r"a(\d)b", "x a7b") !== nothing
        @test match(r"a(\d)b", "x ab") === nothing
        @test match(r"a(\d)b", "x a7b")[1] == "7"
        @test [m.match for m in eachmatch(r"\d+", "12 ab 3")] == ["12", "3"]
        @test replace("a1b2", r"\d+" => "N") == "aNbN"
    end
    @testset "Printf" begin
        using Printf
        @test @sprintf("%+d", 7) == "+7"
        @test @sprintf("%.0f", 0.5) == "0"         # ties to even
        @test @sprintf("%s and %s", "a", 'b') == "a and b"
    end
end
