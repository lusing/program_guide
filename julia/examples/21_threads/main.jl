# 21 多线程：-t 启动、线程池、@threads 调度、@spawn、数据竞争与三种修复（锁/原子/分块聚合）
# 运行：julia --startup-file=no -t 4 main.jl（build.ps1 自动加 -t 4）

using Random                               # shuffle 在 Random 里（Base 不导出）

println("默认线程池 nthreads(:default) = ", Threads.nthreads(:default),
        "；交互池 nthreads(:interactive) = ", Threads.nthreads(:interactive),
        "；本进程总线程 = ", Threads.nthreads())

# ═══ 21.1 @threads：把循环分片到多线程（:dynamic 默认，允许调度器移动迭代）
function threaded_sum(xs)
    acc = Threads.Atomic{Float64}(0.0)         # 原子累加：多线程安全
    Threads.@threads for i in eachindex(xs)
        Threads.atomic_add!(acc, Float64(xs[i]))
    end
    acc[]
end
const N = 1_000_000
data = collect(1:N)
@assert threaded_sum(data) == sum(data)        # 浮点原子加可能有舍入差？整数验证更稳：
@assert threaded_sum(collect(1:1000)) == 500_500

# ═══ 21.2 分块聚合（chunked reduction）：无锁最快的模式——每线程私有部分和，最后合并
function chunked_sum(xs; nchunks = Threads.nthreads())
    partial = zeros(Float64, nchunks)
    Threads.@threads for c in 1:nchunks
        # 每线程只写自己的槽位——无竞争、无原子开销
        lo = floor(Int, (c - 1) * length(xs) / nchunks) + 1
        hi = floor(Int, c * length(xs) / nchunks)
        s = 0.0
        @inbounds for i in lo:hi
            s += xs[i]
        end
        partial[c] = s
    end
    sum(partial)
end
@assert chunked_sum(data) == sum(data)
@assert chunked_sum(data; nchunks = 7) == sum(data)

# ═══ 21.3 数据竞争：这个版本"看起来对"，多线程下会丢更新
function racy_sum(xs)
    s = Ref(0.0)                                # 共享可变状态
    Threads.@threads for x in xs
        s[] += x                                # 读-改-写不是原子的：并发下互相覆盖
    end
    s[]
end
# 结果不确定：本机多次运行通常 < 正确值；断言只验证"偶尔丢"，不用精确值
racy = racy_sum(shuffle(collect(1:100_000)))
println("racy_sum(1:100000 洗牌) = ", racy, "（正确 = ", sum(1:100_000), "）——并发下不可复现")

# ═══ 21.4 修复一：ReentrantLock——通用互斥（临界区串行化）
function locked_sum(xs)
    s = 0.0
    lock_obj = ReentrantLock()
    Threads.@threads for x in xs
        lock(lock_obj) do                       # Base.lock 的 do 块形式，自动解锁
            s += x
        end
    end
    s
end
@assert locked_sum(data) == sum(data)

# ═══ 21.5 修复二：@spawn + fetch——任务级并行（比 @threads 更灵活的分治）
function spawn_sum(xs; ntasks = 4)
    chunks = [xs[floor(Int, (k - 1) * length(xs) / ntasks) + 1:floor(Int, k * length(xs) / ntasks)]
              for k in 1:ntasks]
    tasks = map(chunks) do chunk
        Threads.@spawn sum(chunk)               # 每块一个任务，调度到各线程
    end
    sum(fetch.(tasks))                          # fetch 收集
end
@assert spawn_sum(data) == sum(data)

# ═══ 21.6 顶层作用域坑：@threads 直接写在顶层时，循环体内赋值全局会 UndefVarError
# （04 章的 soft scope 坑在多线程宏里同样存在）——写进函数即可，如上所有示例。
# ── 下面这行如果取消注释会报错：
# s = 0.0; Threads.@threads for i in 1:2; global s += i; end   # global 修复也行，但别这么写

# ═══ 21.7 线程安全容器选择：Channel 是现成的多生产者-多消费者队列
function parallel_fill(n)
    results = Vector{Int}(undef, n)
    ch = Channel{Int}(n)
    producers = [Threads.@spawn(put!(ch, k^2)) for k in 1:n]   # 宏调用加括号，否则吞掉 for
    for i in 1:n                                # 单消费者收集
        results[i] = take!(ch)
    end
    foreach(fetch, producers)
    sort!(results)
end
@assert parallel_fill(20) == sort!([k^2 for k in 1:20])

println("chunked = ", chunked_sum(data), "；locked = ", locked_sum(data), "；spawn = ", spawn_sum(data))
println("==== 21 结束 ====")
