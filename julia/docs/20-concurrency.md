# 20 · 并发与并行

> 对应示例：`examples/20_concurrency/`（build.ps1 以 `-t 4` 运行）
>
> Task 是协作式调度的"轻量线程"，`Threads` 是真并行——一章讲全：**IO 并发用 @async + Channel；计算并行用 @threads/@spawn**。

## 20.1 Task：构造、调度、取结果

```julia
slow_id(x) = (sleep(0.01); x * 10)     # sleep 是 yield 点：任务让出调度
t1 = @task slow_id(1)                  # 只构造，不运行
istaskstarted(t1)                      # false
schedule(t1); fetch(t1)                # 手动入队；fetch 阻塞等结果 → 10
t2 = @async slow_id(2)                 # 构造 + 立即调度（最常用）
fetch(t2) == 20 && istaskdone(t2)
```

## 20.2 并发等待：sleep 们交叠着过

```julia
run_all() = fetch.([@async slow_id(i) for i in 1:5])
run_all()                              # 预热（排除编译时间）
@elapsed run_all()                     # 实测 ~15 ms（串行 ≈50ms）
```

单线程协作调度下任务不并行，但**等待交叠**。注意计时前预热（16 章纪律）。

## 20.3 Channel：类型化阻塞队列

```julia
for x in Channel(producer)             # Channel(f)：绑定生产者，可直接迭代
    push!(got, x)                      # put! 满则阻塞（背压）；close 后循环正常结束
end
ch = Channel{Int}(2)
put!(ch, 100); take!(ch)               # 显式类型 + 容量 + 手工操作
isready(ch); close(ch)
```

## 20.4 两级流水线：消费者也要在任务里（实测死锁教训）

```julia
function pipeline()
    src = Channel(32) do ch; for i in 1:6; put!(ch, i^2); end; end   # 生产者
    sink = Channel(4)                                                 # 中间缓冲
    worker = @async begin            # ★ 加工者在任务里并发消费
        for x in src; put!(sink, x + 1); end
        close(sink)
    end
    out = collect(sink)              # 主任务同时收集
    fetch(worker); out               # [2, 5, 10, 17, 26, 37]
end
```

**反例（实测死锁）**：主任务自己"先填满 sink 再 collect"——容量 4、共 6 件、无消费者——第 5 个 `put!` 永塞。规则：**生产与消费必须在不同任务里同时推进**。

## 20.5 任务异常：fetch 重抛（包着 TaskFailedException）

```julia
boom = @async error("任务内炸了")
fetch(boom)      # 抛 TaskFailedException——原始异常在 e.task.exception（1.13 实测）
istaskfailed(boom)
```

## 20.6 线程池与 @threads

```julia
julia -t 4            # 默认池 4；-t 4,1 加 1 个交互线程；默认 1 线程！
Threads.nthreads(:default) / :interactive

function threaded_sum(xs)
    acc = Threads.Atomic{Float64}(0.0)
    Threads.@threads for i in eachindex(xs)       # 迭代分给各线程（:dynamic 默认）
        Threads.atomic_add!(acc, Float64(xs[i]))  # 原子累加
    end
    acc[]
end
```

## 20.7 分块聚合：无锁最快的模式

```julia
function chunked_sum(xs; nchunks = Threads.nthreads())
    partial = zeros(Float64, nchunks)
    Threads.@threads for c in 1:nchunks
        # 每线程只写自己的槽位——无竞争、无原子开销
        ...
        partial[c] = s
    end
    sum(partial)
end
```

**首选分块**：无同步开销、缓存友好；锁保护"必须串行的复合操作"；原子只适合单值累加。

## 20.8 数据竞争：眼见为实

```julia
racy_sum(xs) = (s = Ref(0.0); Threads.@threads for x in xs; s[] += x; end; s[])
# 实测两次：2.57e9 / 3.93e9——正确 5.00005e9，每次都不一样
```

结果不确定就是竞争的签名。修复三板斧（按性能排序）：**分块聚合 > 锁 > 原子**（20.7/20.9/20.6）。

## 20.9 ReentrantLock 与 @spawn

```julia
lock(lock_obj) do                     # Base.lock 的 do 块形式，自动解锁
    s += x
end

function spawn_sum(xs; ntasks = 4)    # 任务级并行：切块 → @spawn → fetch 收集
    tasks = map(chunks) do chunk
        Threads.@spawn sum(chunk)
    end
    sum(fetch.(tasks))
end
```

`@spawn` 比 `@threads` 灵活：任务大小可不必均匀、支持递归分治。**数组推导里宏调用加括号**：`[Threads.@spawn(f(x)) for x in ...]`——不加括号 `@spawn` 吞掉 `for`（实测坑）。

## 20.10 Channel：跨线程的无脑安全选项

```julia
producers = [Threads.@spawn(put!(ch, k^2)) for k in 1:n]   # 多生产者
for i in 1:n; results[i] = take!(ch); end                  # 单消费者
```

Channel 内部自带锁——只共享"通道"不共享"状态"。

## 20.11 @async vs Threads.@spawn 选型表

| | `@async` | `Threads.@spawn` | `@threads` |
|---|---|---|---|
| 调度 | 单线程协作 | 多线程池 | 循环自动分片 |
| 并行 | 否（等待交叠） | 是 | 是 |
| 共享状态 | 防交错即可 | 必须锁/原子/通道 | 同左 |
| 适用 | IO 并发、流水线 | 任务级分治 | 数据并行循环 |

另：`Distributed` 标准库提供多进程并行（`-p 2`、`@spawnat`、`@everywhere`）——绕开单进程内存的第三条路，本教程点到为止。

## 20.12 坑位清单

1. **忘 `-t` = 串行**：默认 1 线程，多线程代码"能跑但没并行"——`Threads.nthreads()` 先查（20.6）。
2. **自己填满自己消费的 Channel = 死锁**：生产/消费分任务（20.4 实测卡死过一版）。
3. **fetch 失败任务抛 TaskFailedException**（1.13）：原始异常在 `.task.exception`——`@test_throws 原始类型 fetch(t)` 不成立（20.5 实测）。
4. **`@spawn` 吞 for**：推导式里写 `Threads.@spawn(f(x))`（20.9 实测）；`shuffle` 在 Random、`lock` 是 Base 函数。
5. **`Ref`/裸变量累加丢更新**：实测两次两个数——分块/锁/原子三选一（20.8）。
6. **@threads 体内异常聚合抛出**：调试先去掉 @threads 跑通再加并行（"先对后快"纪律，16 章 @inbounds 同款）。
