# 20 · 任务与通道

> 对应示例：`examples/20_tasks/`
>
> Task 是协作式调度的"轻量线程"：IO 并发的主力工具。真并行见 21 章。

## 20.1 Task：构造、调度、取结果

```julia
slow_id(x) = (sleep(0.01); x * 10)     # sleep 是 yield 点：任务让出调度

t1 = @task slow_id(1)                  # 只构造，不运行
istaskstarted(t1)                      # false
schedule(t1)                           # 手动入队
fetch(t1)                              # 10——阻塞等结果

t2 = @async slow_id(2)                 # 构造 + 立即调度（最常用）
fetch(t2) == 20 && istaskdone(t2)
```

`@async` 是"发射后等 fetch"的主力；`@task + schedule` 用于想精确控制时机的场合。

## 20.2 并发等待：sleep 们交叠着过

```julia
function run_all()
    ts = [@async slow_id(i) for i in 1:5]
    fetch.(ts)
end
run_all()                              # 预热（排除编译时间）
elapsed = @elapsed run_all()
# 实测：14.5 ms（串行会是 ≈50ms）
```

单线程协作调度下任务不并行，但**等待交叠**——5 个 sleep(0.01) 同哄同醒。注意计时前预热（20/16 章纪律）。

## 20.3 Channel：类型化阻塞队列

```julia
function producer(ch::Channel)
    for i in 1:4
        put!(ch, i)            # 缓冲满 → 阻塞（背压）
    end
    close(ch)                  # 关闭 → 消费者迭代正常结束
end

got = Int[]
for x in Channel(producer)     # Channel(f)：绑定生产者，可直接迭代
    push!(got, x)
end
# got == [1, 2, 3, 4]

ch = Channel{Int}(2)           # 显式类型 + 容量
put!(ch, 100); put!(ch, 200)
take!(ch)                      # 100——空了阻塞
isready(ch)                    # false（无待取元素）
close(ch)                      # 关闭后 put! 抛 InvalidStateException
```

`Channel(f)` 的 f 在绑定任务里跑——通道结束自动关闭。

## 20.4 两级流水线：消费者也要在任务里（实测死锁教训）

```julia
function pipeline()
    src = Channel(32) do ch            # 生产者：1..6 的平方
        for i in 1:6; put!(ch, i^2); end
    end
    sink = Channel(4)                  # 中间缓冲：限制在制品
    worker = @async begin              # ★ 加工者在任务里消费 src
        for x in src
            put!(sink, x + 1)
        end
        close(sink)
    end
    out = collect(sink)                # 主任务同时收集 sink
    fetch(worker)
    out                                # [2, 5, 10, 17, 26, 37]
end
```

**反例（实测死锁）**：如果主任务自己"先填满 sink 再 collect"——sink 容量 4、共 6 件、无消费者——第 5 个 `put!` 永远阻塞。规则：**生产与消费必须在不同任务里同时推进**。

## 20.5 异常：fetch 时重抛（包着 TaskFailedException）

```julia
boom = @async error("任务内炸了")
try
    fetch(boom)
catch e
    inner = e isa TaskFailedException ? e.task.exception : e   # 原始异常在 .task.exception
    occursin("任务内炸了", sprint(showerror, inner))
end
istaskfailed(boom)      # true
```

1.13 实测：fetch 失败任务抛的是 **TaskFailedException 包装**——原始异常要掏 `.task.exception`（老版本直接重抛原始异常）。

## 20.6 yield 与当前任务

```julia
t = @async begin
    yield()          # 主动让出一步
    "resumed"
end
fetch(t) == "resumed"
current_task() isa Task
```

协作式的本质：**切换只发生在 yield 点**（sleep、IO、fetch、put!/take! 阻塞）——两个纯计算任务单线程下互不交错（要交错用 yield 或 21 章 @spawn）。

## 20.7 @async vs Threads.@spawn

| | `@async` | `Threads.@spawn` |
|---|---|---|
| 调度 | 单线程协作 | 多线程池（默认 default 池） |
| 并行 | 否（等待交叠） | 是（真并行） |
| 共享状态 | 无竞争（仍防 yield 间交错） | 必须加锁/原子/通道 |
| 适用 | IO 并发、流水线 | 计算并行（21 章） |

经验法则：**IO 用 @async + Channel，计算用 @spawn/@threads**。另：`Distributed` 标准库提供多进程（`-p 2`、`@spawnat`、`@everywhere`）——绕开 GIL 式限制的第三条路，本教程点到为止。

## 20.8 坑位清单

1. **自己填满自己消费的 Channel = 死锁**：容量有限且无并发消费者时 put! 永塞——生产/消费分任务（20.4 实测卡死过一版）。
2. **fetch 失败任务抛 TaskFailedException**（1.13）：原始异常在 `.task.exception`——`@test_throws DomainError fetch(t)` 不成立，要断言包装类型（20.5 实测）。
3. **关 channel 后 put! 抛 InvalidStateException**：生产者循环里 close 后继续 put 是常见竞态——close 是"终结宣告"，放最后（20.3）。
4. **计时忘预热**：`@elapsed` 首测含编译——交叠效果被编译时间淹没（20.2 与 16 章同纪律）。
5. **@async 不是并行**：以为开 @async 就"多核加速"是常见误会——它只交错等待；提速要走 21 章。
