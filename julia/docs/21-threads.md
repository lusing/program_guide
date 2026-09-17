# 21 · 多线程

> 对应示例：`examples/21_threads/`（build.ps1 自动以 `-t 4` 运行）
>
> 先记住：**默认 1 线程**。`julia -t 4` 才有并行（01 章坑位）。

## 21.1 启动与线程池

```julia
julia --startup-file=no -t 4 main.jl        # 4 个默认线程
julia -t 4,1                                # 4 默认 + 1 交互线程（交互池保 REPL 响应）
julia -t auto                               # 按 CPU 推断

Threads.nthreads()                 # 4（总数）
Threads.nthreads(:default)         # 4——计算池
Threads.nthreads(:interactive)     # 1——交互池（`-t N,M` 的 M）
```

`@spawn`/`@threads` 落 default 池；`Threads.@spawn :interactive f()` 给低延迟任务（GC、日志）留的专属池。

## 21.2 @threads：循环分片

```julia
function threaded_sum(xs)
    acc = Threads.Atomic{Float64}(0.0)
    Threads.@threads for i in eachindex(xs)      # 迭代分给各线程
        Threads.atomic_add!(acc, Float64(xs[i])) # 原子累加
    end
    acc[]
end
```

调度参数 `Threads.@threads :dynamic`（默认，可迁移迭代）/`:static`（固定切分，嵌套场景）/`:greedy`（动态偷取，1.11+）。

## 21.3 数据竞争：眼见为实

```julia
function racy_sum(xs)
    s = Ref(0.0)
    Threads.@threads for x in xs
        s[] += x                # 读-改-写三步，并发互相覆盖
    end
    s[]
end
racy = racy_sum(shuffle(collect(1:100_000)))
# 实测两次：3.19e9 / 2.93e9——正确 5.00005e9，每次都不一样
```

**结果不确定**就是竞争的签名。修复三板斧（按性能排序）：

```julia
# ① 分块聚合（最快）：每线程私有槽位，零锁零原子
function chunked_sum(xs; nchunks = Threads.nthreads())
    partial = zeros(Float64, nchunks)
    Threads.@threads for c in 1:nchunks
        lo = floor(Int, (c - 1) * length(xs) / nchunks) + 1
        hi = floor(Int, c * length(xs) / nchunks)
        s = 0.0
        @inbounds for i in lo:hi
            s += xs[i]
        end
        partial[c] = s          # 只写自己的槽
    end
    sum(partial)
end

# ② 锁：临界区串行化（通用但慢）
s = 0.0
lock_obj = ReentrantLock()
Threads.@threads for x in xs
    lock(lock_obj) do           # Base.lock 的 do 块形式，自动解锁
        s += x
    end
end

# ③ 原子：单变量累加/计数（@threads 版 21.2）
```

**首选分块**：无同步开销、缓存友好；锁保护"必须串行的复合操作"；原子只适合单值。

## 21.4 @spawn + fetch：任务级并行

```julia
function spawn_sum(xs; ntasks = 4)
    chunks = [xs[a:b] for ...]                 # 切块
    tasks = map(chunks) do chunk
        Threads.@spawn sum(chunk)              # 每块一个任务，调度到各线程
    end
    sum(fetch.(tasks))                         # 收集
end
```

比 @threads 灵活：任务大小不必均匀、能嵌套 fetch（分治递归）。注意 `[Threads.@spawn(put!(ch, k)) for k in 1:n]`——**宏调用加括号**，否则 `@spawn` 把后面的 `for` 整个吞进任务体（实测坑）。

## 21.5 Channel：现成的多生产者-多消费者

```julia
function parallel_fill(n)
    results = Vector{Int}(undef, n)
    ch = Channel{Int}(n)
    producers = [Threads.@spawn(put!(ch, k^2)) for k in 1:n]   # 多生产者
    for i in 1:n
        results[i] = take!(ch)                                  # 单消费者收集
    end
    foreach(fetch, producers)
    sort!(results)
end
```

Channel 内部自带锁——**跨线程传数据的无脑安全选项**；只共享"通道"不共享"状态"。

## 21.6 与 20 章的边界 + 顶层坑

顶层直接写 `Threads.@threads` 循环并给全局累加，除了 soft scope 的 UndefVarError（04 章）还叠加并发问题——**多线程逻辑一律进函数**（本教程全部示例如此）。@threads 循环体内的异常会以 CompositeException 聚合抛出——别在并行循环里裸 throw。

## 21.7 坑位清单

1. **忘 `-t` = 串行**：默认 1 线程，多线程代码"能跑但没并行"——`Threads.nthreads()` 先查（21.1）。
2. **`Ref`/裸变量累加丢更新**：实测三次三个数——分块/锁/原子三选一（21.3）。
3. **`@spawn` 吞 for**：数组推导里 `Threads.@spawn f(x) for x in ...` 会把 for 当任务体——写 `Threads.@spawn(f(x))`（21.4 实测）。
4. **`lock` 是 Base 函数**：`Threads.lock` 不存在——`lock(l) do ... end` 直接用（21.3 实测）。
5. **`shuffle` 在 Random**：Base 不导出——`using Random`（21 章示例实测）。
6. **@threads 体内异常聚合抛出**：调试时先去掉 @threads 跑通，再加并行（同 @inbounds 的"先对后快"纪律，16 章）。
