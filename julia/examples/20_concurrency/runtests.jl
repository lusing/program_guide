# 20 示例测试：任务/通道/线程语义（两个入口以 -t 4 运行本文件）
using Test
include("main.jl")

@testset "20_concurrency" begin
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
    @testset "流水线" begin
        squares = Channel(8) do ch
            for i in 1:5
                put!(ch, i * i)
            end
        end
        @test collect(squares) == [1, 4, 9, 16, 25]
        @test pipeline() == [2, 5, 10, 17, 26, 37]
    end
    @testset "线程池" begin
        @test Threads.nthreads(:default) >= 1
        @test Threads.nthreads() >= Threads.nthreads(:default)
        @test Threads.nthreads(:interactive) >= 1
    end
    @testset "求和三式" begin
        xs = Float64.(1:10_000)
        for f in (threaded_sum, chunked_sum, locked_sum, spawn_sum)
            @test f(xs) == sum(xs)
        end
        @test chunked_sum(xs; nchunks = 3) == sum(xs)
        @test spawn_sum(xs; ntasks = 10) == sum(xs)
    end
    @testset "@spawn 与原子" begin
        a = Threads.Atomic{Int}(0)
        ts = [Threads.@spawn(Threads.atomic_add!(a, 1)) for _ in 1:1000]
        foreach(fetch, ts)
        @test a[] == 1000                        # 原子操作下不丢
        @test parallel_fill(50) == [k^2 for k in 1:50]
    end
end
