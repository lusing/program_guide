# 21 示例测试：多线程语义（build.ps1 以 -t 4 运行本文件）
using Test
include("main.jl")

@testset "21_threads" begin
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
    @testset "Channel 并行" begin
        @test parallel_fill(50) == [k^2 for k in 1:50]
    end
    @testset "@spawn 与原子" begin
        a = Threads.Atomic{Int}(0)
        ts = [Threads.@spawn(Threads.atomic_add!(a, 1)) for _ in 1:1000]
        foreach(fetch, ts)
        @test a[] == 1000                        # 原子操作下不丢
    end
end
