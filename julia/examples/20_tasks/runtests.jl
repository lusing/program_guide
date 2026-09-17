# 20 示例测试：任务与通道语义
using Test
include("main.jl")

@testset "20_tasks" begin
    @testset "Task 基础" begin
        t = @async 1 + 1
        @test fetch(t) == 2
        @test istaskdone(t)
        @test !istaskfailed(t)
        t2 = @task "later"
        @test !istaskstarted(t2)
        schedule(t2)
        @test fetch(t2) == "later"
    end
    @testset "Channel" begin
        ch = Channel{Int}(1)
        put!(ch, 7)
        @test isready(ch)
        @test take!(ch) == 7
        close(ch)
        t = @async put!(ch, 8)             # 关闭后 put! 抛 InvalidStateException
        @test_throws TaskFailedException fetch(t)   # fetch 包一层：原始异常在 e.task.exception
    end
    @testset "生产者消费者" begin
        squares = Channel(8) do ch
            for i in 1:5
                put!(ch, i * i)
            end
        end
        @test collect(squares) == [1, 4, 9, 16, 25]
        @test pipeline() == [2, 5, 10, 17, 26, 37]
    end
    @testset "异常传播" begin
        t = @async throw(DomainError(-1))
        @test_throws TaskFailedException fetch(t)
        @test istaskfailed(t)
    end
end
