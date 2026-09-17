# 20 任务与通道：Task/@async、Channel 生产者-消费者、take!/put!/fetch、yield/sleep
# 运行：julia --startup-file=no main.jl（并发章与本机单线程调度下结果确定）

# ═══ 20.1 Task：一等公民的"协作式线程"（默认单线程调度，只在 yield 点切换）
function slow_id(x)
    sleep(0.01)                     # sleep 是 yield 点：任务让出调度
    x * 10
end
t1 = @task slow_id(1)               # @task：构造不运行
@assert istaskstarted(t1) == false  # 还没调度，自然没启动
schedule(t1)                        # 手动调度
@assert fetch(t1) == 10             # fetch：等结果（阻塞至完成）

# @async：构造 + 立即调度（最常用）
t2 = @async slow_id(2)
@assert fetch(t2) == 20
@assert istaskdone(t2)              # 完成态

# ═══ 20.2 并发等待：多个 @async 任务并发推进（协作式：总时长 ≈ 最长单个）
function run_all()
    ts = [@async slow_id(i) for i in 1:5]
    fetch.(ts)                      # 逐个取结果
end
run_all()                           # 预热：把编译时间排除在测量外
elapsed = @elapsed results = run_all()
@assert results == [10, 20, 30, 40, 50]
# 单线程协作调度下，5 个 sleep(0.01) 并发等待，总时长接近 0.01s 而非 0.05s
# （Windows 计时器粒度约 15ms，上限放宽到 45ms）
@assert elapsed < 0.045
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

# 手工版：显式 put!/take!
ch = Channel{Int}(2)                # 容量 2：第三个 put! 阻塞直到有消费者
put!(ch, 100)
put!(ch, 200)
@assert take!(ch) == 100            # 空了则 take! 阻塞
@assert take!(ch) == 200
@assert isready(ch) == false
close(ch)

# ═══ 20.4 两级流水线：生产者 → 加工者 → 收集者（背压由阻塞自动实现）
# 关键：消费者必须也在任务里跑——否则"先填满 sink 再 collect"会自己卡死自己
function pipeline()
    src = Channel(32) do ch         # do 块版 Channel(f)：生产者任务自动绑定
        for i in 1:6
            put!(ch, i^2)
        end
    end
    sink = Channel(4)               # 中间缓冲：限制"在制品"数量
    worker = @async begin           # 加工者：另一个任务里并发消费 src
        for x in src
            put!(sink, x + 1)       # 加工：x² + 1
        end
        close(sink)
    end
    out = collect(sink)             # 主任务同时收集 sink（不等待填满）
    fetch(worker)                   # 确认加工者干净退出
    out
end
@assert pipeline() == [2, 5, 10, 17, 26, 37]

# ═══ 20.5 异常与取消：任务里的异常在 fetch 时重抛（包在 TaskFailedException 里）
boom = @async error("任务内炸了")
caught = try
    fetch(boom)
    false
catch e
    inner = e isa TaskFailedException ? e.task.exception : e   # 原始异常藏在 .task.exception
    inner isa ErrorException && occursin("任务内炸了", sprint(showerror, inner))
end
@assert caught
# istaskfailed / istaskfailednotstuck：状态查询
@assert istaskfailed(boom)

# ═══ 20.6 yield / sleep / 当前任务
before = @async begin
    yield()                         # 主动让出：给其他任务跑一步
    "resumed"
end
@assert fetch(before) == "resumed"
@assert current_task() isa Task

# ═══ 20.7 @async vs Threads.@spawn（21 章）
# @async：单线程协作调度——任务不并行，只在等待点交错；共享状态零竞争风险（但仍要小心 yield 间的交错）
# Threads.@spawn：真并行——必须处理数据竞争（锁/原子/通道）
# 经验法则：IO 并发用 @async + Channel；计算并行用 @spawn/@threads
println("pipeline = ", pipeline(), "；任务异常可被 fetch 捕获 = ", caught)
println("==== 20 结束 ====")
