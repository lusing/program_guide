# 19 示例测试：文件 IO 语义（自建沙箱，不碰工作区）
using Test
include("main.jl")

@testset "19_files" begin
    @testset "CSV 解析" begin
        @test length(parse_csv(csv)) == 3
        @test parse_csv(csv)[3] == ["Carol", "95", "60"]
    end
    @testset "写入与回读" begin
        d = mktempdir()
        p = joinpath(d, "t.txt")
        open(p, "w") do io
            print(io, "无换行")
        end
        @test read(p, String) == "无换行"
        @test filesize(p) == sizeof("无换行")      # 字节数 = sizeof 字符串
        open(p, "a") do io                         # 追加用模式串 "a"（append=true 关键字不生效！）
            println(io, "追加")
        end
        @test readlines(p) == ["无换行追加"]        # 首次写入无换行符 → 追加内容接在同一行
        rm(d; recursive = true, force = true)      # 清理沙箱
    end
    @testset "路径族" begin
        @test splitext("a.b.c") == ("a.b", ".c")
        @test basename("/x/y/z.txt") == "z.txt"
        @test joinpath("a", "b", "c") == joinpath(joinpath("a", "b"), "c")
        @test tempdir() isa String && isdir(tempdir())
    end
    @testset "Serialization 往返" begin
        d = mktempdir()
        p = joinpath(d, "x.ser")
        serialize(p, Dict(:k => [1, 2, 3]))
        @test deserialize(p)[:k] == [1, 2, 3]
        rm(d; recursive = true, force = true)
    end
end
