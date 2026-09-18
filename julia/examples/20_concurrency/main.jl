# 20 并发与并行：Task/@async、Channel 流水线、线程池、@threads/@spawn、竞争三板斧
# 运行：julia --startup-file=no -t 4 main.jl（两个入口自动加 -t 4）
# 心法：IO 并发用 @async + Channel（协作调度）；计算并行用 @threads/@spawn（真并行）

using Random                                # shuffle 在 Random 里（Base 不导出）

println("默认线程池 nthreads(:default) = ", Threads.nthreads(:default),
        "；交互池 nthreads(:interactive) = ", Threads.nthreads(:interactive),
        "；本进程总线程 = ", Threads.nthreads())

# ═══ 20.1 Task：一等公民的"协作式线程"（默认单线程调度，只在 yield 点切换）
function slow_id(x)
    sleep(0.01)                     # sleep 是 yield 点：任务让出调度
    x * 10
end
t1 = @task slow_id(1)               # @task：构造不运行
@assert istaskstarted(t1) == false  # 还没调度，自然没启动
schedule(t1)                        # 手动调度
@assert fetch(t1) == 10             # fetch：等结果（阻塞至完成）

t2 = @async slow_id(2)              # @async：构造 + 立即调度（最常用）
@assert fetch(t2) == 20 && istaskdone(t2)

# ═══ 20.2 并发等待：多个 @async 任务交叠推进（总时长 ≈ 最长单个）
function run_all()
    ts = [@async slow_id(i) for i in 1:5]
    fetch.(ts)
end
run_all()                           # 预热：把编译时间排除在测量外
elapsed = @elapsed results = run_all()
@assert results == [10, 20, 30, 40, 50]
@assert elapsed < 0.045             # 协作调度下 5 个 sleep 并发等待（串行则 ≈50ms；Windows 计时粒度放宽上限）
println("5 个并发任务总耗时 $(round(elapsed * 1000; digits = 1)) ms（串行则 ≈50ms）")

# ═══ 20.3 Channel：类型化的阻塞队列（生产者-消费者的一等工具）
function producer(ch::Channel)
    for i in 1:4
        put!(ch, i)                 # 缓冲满则阻塞
    end
    close(ch)                       # 关闭：消费者的 for 循环正常结束
end
got = Int[]
for x in Channel(producer)          # Channel(f)：绑定生产者的通道，可直接迭代
    push!(got, x)
end
@assert got == [1, 2, 3, 4]

ch = Channel{Int}(2)                # 显式类型 + 容量
put!(ch, 100); put!(ch, 200)
@assert take!(ch) == 100 && take!(ch) == 200
@assert isready(ch) == false
close(ch)

# ═══ 20.4 两级流水线：消费者也要在任务里（否则自己塞死自己）
function pipeline()
    src = Channel(32) do ch         # do 块版 Channel(f)：生产者任务自动绑定
        for i in 1:6
            put!(ch, i^2)
        end
    end
    sink = Channel(4)               # 中间缓冲：限制"在制品"数量
    worker = @async begin           # ★ 加工者在任务里并发消费 src
        for x in src
            put!(sink, x + 1)
        end
        close(sink)
    end
    out = collect(sink)             # 主任务同时收集 sink（不等待填满）
    fetch(worker)
    out
end
@assert pipeline() == [2, 5, 10, 17, 26, 37]

# ═══ 20.5 任务异常：fetch 时重抛（包在 TaskFailedException 里）
boom = @async error("任务内炸了")
caught = try
    fetch(boom)
    false
catch e
    inner = e isa TaskFailedException ? e.task.exception : e   # 原始异常藏在 .task.exception
    inner isa ErrorException && occursin("任务内炸了", sprint(showerror, inner))
end
@assert caught && istaskfailed(boom)

# ═══ 20.6 @threads：把循环分片到多线程（:dynamic 默认，允许调度器移动迭代）
function threaded_sum(xs)
    acc = Threads.Atomic{Float64}(0.0)         # 原子累加：多线程安全
    Threads.@threads for i in eachindex(xs)
        Threads.atomic_add!(acc, Float64(xs[i]))
    end
    acc[]
end
const N = 1_000_000
data = collect(1:N)
@assert threaded_sum(data) == sum(data)

# ═══ 20.7 分块聚合（chunked reduction）：无锁最快的模式——每线程私有部分和，最后合并
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

# ═══ 20.8 数据竞争：这个版本"看起来对"，多线程下会丢更新
function racy_sum(xs)
    s = Ref(0.0)                                # 共享可变状态
    Threads.@threads for x in xs
        s[] += x                                # 读-改-写不是原子的：并发下互相覆盖
    end
    s[]
end
racy = racy_sum(shuffle(collect(1:100_000)))
println("racy_sum(1:100000 洗牌) = ", racy, "（正确 = ", sum(1:100_000), "）——并发下不可复现")

# ═══ 20.9 修复一：ReentrantLock——通用互斥（临界区串行化）
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

# ═══ 20.10 修复二：@spawn + fetch——任务级并行（比 @threads 更灵活的分治）
function spawn_sum(xs; ntasks = 4)
    chunks = [xs[floor(Int, (k - 1) * length(xs) / ntasks) + 1:floor(Int, k * length(xs) / ntasks)]
              for k in 1:ntasks]
    tasks = map(chunks) do chunk
        Threads.@spawn sum(chunk)               # 每块一个任务，调度到各线程
    end
    sum(fetch.(tasks))
end
@assert spawn_sum(data) == sum(data)

# ═══ 20.11 Channel 是现成的多生产者-多消费者队列（内部自带锁）
function parallel_fill(n)
    results = Vector{Int}(undef, n)
    ch = Channel{Int}(n)
    producers = [Threads.@spawn(put!(ch, k^2)) for k in 1:n]   # 宏调用加括号，否则吞掉 for
    for i in 1:n
        results[i] = take!(ch)
    end
    foreach(fetch, producers)
    sort!(results)
end
@assert parallel_fill(20) == sort!([k^2 for k in 1:20])

# ═══ 20.12 选型速查
# | 需求                         | 工具                            |
# |------------------------------|---------------------------------|
# | IO 并发（网络/磁盘等待交叠）  | @async + Channel               |
# | 流水线（生产-加工-收集）      | Channel + @async 任务           |
# | 数据并行循环                  | @threads（配分块聚合/原子/锁）  |
# | 任务级分治                    | @spawn + fetch                  |
# | 跨线程传数据                  | Channel（无脑安全）或锁保护     |
# 顶层注意：@threads/@async 直接写在顶层并给全局赋值会叠加 soft scope 坑（04 章）——并发逻辑一律进函数

println("chunked = ", chunked_sum(data), "；locked = ", locked_sum(data), "；spawn = ", spawn_sum(data))
println("==== 20 结束 ====")
