# 22 · Fiber 与协程

> 对应示例：`examples/22_fibers/`

Fiber 是 Ruby 的协程：一段可以**暂停再续跑**的计算。它不像线程那样被调度器抢来抢去——切换只发生在你亲手写的 `Fiber.yield` / `resume` 上，单线程内、纯协作、无需加锁。这章的主线有三条：`resume/yield` 的交接协议、`Enumerator` 的 Fiber 本质、以及手写生成器。读完你会发现 11 章里天天用的 `next`，底下就是一个 Fiber。

## 22.1 最小 Fiber：resume 与 yield

`Fiber.new { }` 只创建不执行；`resume` 从头跑到第一个 `Fiber.yield` 暂停，把 yield 的值交回调用方；再 `resume` 从暂停点续跑；块跑完 Fiber 终结：

```ruby
f = Fiber.new do
  Fiber.yield(:第一步)     # yield = 暂停并把值交回 resume 调用方
  :最后一步                # 块跑完 = Fiber 终结
end
f.resume                    # => :第一步
f.resume                    # => :最后一步
f.resume                    # 终结后再 resume → FiberError
```

实测输出：

```text
---- 22.1 最小 Fiber：resume 与 yield ----
终结后再 resume → 抛 FiberError（rescue 后打印中文句 + 类名）
resume 序列：:第一步 → :最后一步 → FiberError（确定的交接顺序）
```

交接序列是死的：`:第一步` → `:最后一步` → `FiberError`。死 Fiber 不能复活，想要「可重来」就得重新 `Fiber.new`。

## 22.2 双向传值：乒乓

Fiber 是双向通道：**`resume(x)` 的参数成为 `yield` 的返回值**。每次往返都能带一条消息进去、交一个值出来：

```ruby
counter = Fiber.new do |first|
  acc = first
  loop do
    acc = Fiber.yield(acc * 2)   # 暂停交出翻倍值；恢复时收进的值存回 acc
  end
end
counter.resume(10)    # => 20（启动：first = 10）
counter.resume(100)   # => 200（送进 100，拿到 200）
counter.resume(1)     # => 2
```

实测输出：

```text
---- 22.2 双向传值：乒乓 ----
乒乓序列：resume(10)=20 → resume(100)=200 → resume(1)=2（固定脚本，结果确定）
```

初次 `resume` 的参数走块的块参数（`|first|`），之后每次 resume 的参数走 `Fiber.yield` 的返回值——两条进数据的路别搞混。

## 22.3 生命周期：alive? 状态流转

`alive?` 问「还能不能继续 resume」：

```ruby
life = Fiber.new do
  Fiber.yield(:暂停)
  :结束
end
life.alive?    # => true（尚未跑也算 alive）
life.resume    # => :暂停
life.alive?    # => true（yield 暂停 → 仍活着）
life.resume    # => :结束
life.alive?    # => false（块跑完 → terminated）
```

实测输出：

```text
---- 22.3 生命周期：alive? 状态流转 ----
alive? 序列：true →（yield 后）true →（跑完后）false —— 纯布尔确定结论
```

对照 22.1：`alive? == false` 之后 resume 就是 `FiberError`。写消费循环时 `while f.alive?` 是比 rescue `StopIteration` 更直白的停机条件（见 22.5 的另一条路）。

## 22.4 Fiber 内异常

Fiber 里抛的异常不会自己跑到外面——它在 **`resume` 调用点重新抛出**，语义与 20.5 线程异常在 join 处 re-raise 一致：

```ruby
bomb = Fiber.new do
  raise "fiber 里引爆"
end
begin
  bomb.resume           # resume 调用点就是异常重抛点
rescue RuntimeError => e
  e.class               # => RuntimeError
end
bomb.alive?             # => false（异常后 fiber 终结）
```

实测输出：

```text
---- 22.4 Fiber 内异常 ----
resume 处 re-raise，捕获到 RuntimeError（中文句 + 类名）；异常后 alive? = false
```

与线程的两点差异值得对照记：Fiber 异常**必须**在 resume 处接（没有 join 可以延后），且没有「默认往 stderr 打报告」的机制——但死掉同样是静默的，`alive?` 变 false 而已。

## 22.5 Enumerator 就是 Fiber

同一个「产生什么」的逻辑，两种写法。方法内嵌 `yield` 的 each 版，与把产出交给 `Enumerator::Yielder` 的版本，输出必然相等：

```ruby
def each_doubled(enum)
  enum.each { |x| yield x * 2 if x.even? }
end

doubler = Enumerator.new do |y|      # y 是 Enumerator::Yielder
  [1, 2, 3, 4].each { |x| y << x * 2 if x.even? }   # y << 等价于 yield
end
```

实测输出：

```text
---- 22.5 Enumerator 就是 Fiber ----
each 版与 Enumerator::Yielder 版输出相等：[4, 8] —— Enumerator 就是包装好的 Fiber
```

Enumerator 的外部迭代器接口 `next`，底层就是 Fiber 的暂停/恢复：

```ruby
doubler.next    # => 4
doubler.next    # => 8
doubler.next    # 取尽后再 next → StopIteration
```

**实测坑：取尽后再 `next` 抛 `StopIteration`**，不是返回 nil。同时它还有个隐藏协议——`loop { }` 就是靠捕获 `StopIteration` 来停机的，所以 `loop` 包 Enumerator 天然取尽即停；自己写循环消费时，要么 rescue 这个异常，要么先问 `alive?`。

## 22.6 手写生成器：斐波那契

生成器是 Fiber 的招牌应用。同一套斐波那契逻辑，Fiber 版显式控制推进，Enumerator 版把产出交给 Yielder：

```ruby
fib_fiber = Fiber.new do
  a, b = 0, 1
  loop do
    Fiber.yield(a)
    a, b = b, a + b
  end
end
8.times.map { fib_fiber.resume }   # => [0, 1, 1, 2, 3, 5, 8, 13]

fib_enum = Enumerator.new do |y|
  a, b = 0, 1
  loop do
    y << a
    a, b = b, a + b
  end
end
fib_enum.take(8)                   # => [0, 1, 1, 2, 3, 5, 8, 13]
```

实测输出：

```text
---- 22.6 手写生成器：斐波那契 ----
前 8 项：[0, 1, 1, 2, 3, 5, 8, 13]；两版相等 = true
```

`take(8)` 内部就是 resume 8 次。注意 Fiber 版自己 `8.times.map` 控制取多少，Enumerator 版则多了 `first(4)`、惰性链这些免费午餐（11 章的老朋友在无限序列上的正确打开方式）——**日常写生成器优先 Enumerator**，Fiber 版的意义在于理解机制和需要双向传值时（22.2）。

## 22.7 Fiber 与线程的区别

把结论钉死：

- **协作式 vs 抢占式**：Fiber 的切换只发生在 `Fiber.yield`/`resume` 显式调用点，没有抢占、无需加锁；线程在任何字节码间隙都可能被切走，共享状态要 Mutex。
- **单线程内 vs 多核心**：Fiber 永远在同一个线程里切换（不并行）；线程由调度器映射到多个核心（20 章的 GVL 之下是并发，Ractor 才是真并行）。
- **异步库的基石**：async gem 靠 Fiber Scheduler 钩子把「看似阻塞」的 IO 变成协作切换——你在 IO 等待时让出，表现像并发，实际单线程。

示例用一份写死的执行顺序当「协作式」的铁证：

```ruby
order = []
ping = Fiber.new { order << :ping_start; Fiber.yield; order << :ping_end }
pong = Fiber.new { order << :pong_start; Fiber.yield; order << :pong_end }
ping.resume; pong.resume; ping.resume; pong.resume
```

实测输出：

```text
---- 22.7 Fiber 与线程的区别 ----
两个 Fiber 交替 resume，执行顺序完全由代码写死：[:ping_start, :pong_start, :ping_end, :pong_end] —— 无抢占、单线程内切换
```

`order` 的值不依赖任何调度——运行一亿次也是这个序列。20 章里我们为了输出确定要 join 后排序汇总；Fiber 这里顺序天生确定，这正是协作式的定义。

## 22.8 坑位清单

1. **Fiber 取尽后再 `next` 抛 `StopIteration`**：不返回 nil；`loop` 能自动停就是靠捕获它（22.5）。
2. **死 Fiber 再 resume 抛 `FiberError`**：块跑完即终结，不可复活；重跑要重新 `Fiber.new`（22.1）。
3. **初次 `resume` 的参数走块参数，之后走 `Fiber.yield` 的返回值**：两条进数据的路别混（22.2）。
4. **`alive?` 的 false 判定的是「块跑完或异常死」**：暂停中（yield 后）依然 true——把它当「还能 resume 吗」来读（22.3）。
5. **Fiber 内异常在 resume 调用点 re-raise 且 Fiber 终结**：没有 join 可延后，异常处理必须在 resume 一侧（22.4）。
6. **`Enumerator.new` 块里的 `y << x` 才是产出**：写成 `yield x` 在这个块里 yield 的是 Enumerator 构造块自己，什么都产不出（22.5）。
7. **Fiber 不并行也不并发**：同一线程内的协作切换，CPU 密集任务该找 Ractor（22.7）。
8. **Fiber 里也别调阻塞 IO**：协作式切换靠显式 yield，真阻塞会把整个线程（含所有 Fiber）卡死——异步库靠 Fiber Scheduler 才能让 IO 变成协作点（22.7）。
9. **生成器里忘写 `Fiber.yield` 就是死循环**：`loop` 里只算不交出，resume 那头永远等不到值（22.6）。
10. **双向传值的 acc 状态存在 Fiber 闭包里**：每次 resume 复用同一份局部状态，别在外面另设「影子变量」造成两份真相（22.2）。
11. **消费无限 Enumerator 用 `take(n)`/`first(n)`，别 `to_a`**：`to_a` 对无限序列永不返回（22.6）。
12. **需要抢占和真并行的场景，Fiber 不是答案**：锁竞争、CPU 并行分别回 20 章线程和 21 章 Ractor（22.7）。

---

[上一章](21-ractors.md) | [下一章](23-ffi.md)
