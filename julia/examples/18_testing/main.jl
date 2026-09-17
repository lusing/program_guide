# 18 测试：@test 家族、@testset 嵌套、随机测试、@test_broken/@test_logs
# 运行：julia --startup-file=no main.jl（测试层：julia --startup-file=no runtests.jl）

using Test

# ═══ 18.1 被测对象：一个小的"分词器"
function tokenize(s::AbstractString)
    s = strip(s)
    isempty(s) && return String[]
    split(lowercase(s), r"\s+")
end

function wordcount(s::AbstractString)
    length(tokenize(s))
end

# ═══ 18.2 @test 家族：值、近似、抛错、布尔语义
@testset "tokenize" begin
    @test tokenize("Hello World") == ["hello", "world"]
    @test tokenize("") == String[]
    @test tokenize("  A\tB  ") == ["a", "b"]      # 空白归一
    @test wordcount("a b c") == 3
    @test wordcount("") == 0
end

@testset "近似与身份" begin
    @test sqrt(2)^2 ≈ 2                            # ≈ (\approx)：默认 rtol=√eps
    @test sqrt(2)^2 ≈ 2 atol = 1e-12              # atol/rtol 关键字
    @test 0.1 + 0.2 != 0.3                         # 精确不等
    @test 0.1 + 0.2 ≉ 0.3 atol = 0 rtol = 0       # ≉ (\neapprox)：零容差下才"不近似"
    @test [1, 2] == [1, 2]                         # 数组 == 逐元素
    @test isequal(missing, missing) && missing === missing
end

function must_positive(n)
    n > 0 || error("n 必须为正，得到 $(n)")
    √n
end

@testset "抛错断言" begin
    @test_throws DomainError sqrt(-1)              # 必须抛指定类型
    @test_throws BoundsError [1, 2][3]
    # 精确匹配异常消息：@test_throws "消息子串" ——匹配 Exception 的 message
    @test_throws "n 必须为正" must_positive(-1)
end

# ═══ 18.3 @testset 嵌套与汇总：失败即标红、汇总表在末尾
@testset "分词器全套" begin
    @testset "英文" begin
        @test tokenize("The Quick") == ["the", "quick"]
    end
    @testset "边界" begin
        @test tokenize(" ") == String[]
        @test wordcount("one") == 1
    end
end

# ═══ 18.4 随机数据测试：固定 seed 保证可复现（1.13 测试失败会打印 RNG 状态）
using Random
using Statistics
@testset "随机性质" begin
    Random.seed!(20260918)
    xs = randn(1000)
    @test length(xs) == 1000
    @test abs(sum(xs) / length(xs)) < 0.1          # 大数定律：均值近 0
    @test std(xs) ≈ 1 rtol = 0.1
end

# ═══ 18.5 @test_broken / @test_skip：记录已知问题
@testset "已知问题" begin
    @test_broken tokenize("A") == ["A"]            # 实现会转小写 → 表达式为假 → "确实坏着"
    @test_skip wordcount("未定义行为")               # 跳过不计
end

# ═══ 18.6 @test_nowarn / @test_logs：断言日志行为
function warn_once(s)
    @warn "丢弃一行" input = s
    nothing
end

@testset "日志断言" begin
    @test_nowarn tokenize("clean")                 # 不产生警告
    @test_logs (:warn, "丢弃一行") warn_once("x")   # 期望一条 warn 日志
end

println("tokenize(\"Hello World\") = ", tokenize("Hello World"), "；wordcount = ", wordcount("a b c"))
println("==== 18 结束 ====")
