# 20 · 线程

> 对应示例：`examples/20_threads/`

这章讲 MRI 的线程世界观：线程真实存在，但 GVL 让同一时刻只有一个线程执行 Ruby 代码，所以线程的价值在 **IO 并发**（阻塞时让出 GVL）而不是 CPU 并行（那是 21 章 Ractor 的活）。先立三条**输出确定性纪律**，本章示例全程遵守：

1. **join 后按固定顺序汇总打印**——绝不打印线程调度顺序，谁先跑完是操作系统的事。
2. **不测耗时、不打印时间**——耗时不稳定，文档没法逐字节引用；只断言「必然正确」的结果。
3. **可能的 stderr 输出一律圈死**——线程异常默认往 stderr 打报告（见 20.5），演示异常前先关 `report_on_exception`。

## 20.1 Thread.new / join 与值传递

最小用法：`Thread.new(参数) { |x| ... }`，参数显式传给块——**局部变量隔离，不靠闭包抓外层**：

```ruby
t = Thread.new(40) do |x|
  x + 2
end
t.join          # 等待结束，返回线程对象自身
t.value         # => 42（块的返回值）
t.status        # => false（正常结束）
```

实测输出：

```text
---- 20.1 Thread.new / join 与值传递 ----
join 后按需取值：t.value = 42（块返回值，不靠共享变量）
线程收尾纪律：每个 Thread.new 必有对应 join
```

两条状态语义先记牢：`status == false` 是**正常结束**；`status == nil` 是**异常死亡**；`"sleep"` 是阻塞中（20.6 会用到）。收尾纪律只有一条：**每个 `Thread.new` 必有对应 join**——不 join 的线程在主线程退出时被直接掐死，跑到一半的活无声消失。

`Thread.new(40) { |x| }` 的参数形式还有一层用意：示例注释特意写了「局部变量隔离，不靠闭包抓外层」。闭包抓外层局部变量在单线程下没问题，但多线程共享同一个闭包变量就是 20.4 的数据竞争现场；把数据当参数传进去，每个线程拿到自己的拷贝，从源头掐掉竞争。主线程与工作线程之间要传**结果**，用 `t.value`（块的返回值）；要传**消息**，用 20.3 的 Queue。

## 20.2 GVL 直觉：CPU 密集任务不因线程变快

MRI 的 GVL（全局虚拟机锁）保证同一时刻只有一个线程在执行 Ruby 代码。线程切出去的时机是**阻塞**：IO、sleep、锁等待会释放 GVL；纯 CPU 循环不释放，两线程只能轮流咬同一口。示例的验证方式因此很克制——只验证**并发分片求和的正确性**（这是唯一确定的东西），耗时一个字都不打印：

```ruby
expected = sum_to(6_000_000)                             # 单线程基准
a = Thread.new { sum_to(3_000_000) }                     # 前半段
b = Thread.new { sum_to(6_000_000) - sum_to(3_000_000) } # 后半段
a.join.value + b.join.value == expected                  # => true
```

实测输出：

```text
---- 20.2 GVL 直觉：CPU 密集任务不因线程变快 ----
并发分片求和 = 单线程结果（正确性必然成立）；CPU 任务快慢受 GVL 与调度影响，耗时不在 stdout 引用
```

一个反直觉的实测观察：本机（x86_64-darwin23, Ruby 4.0.7）跑「单线程 vs 双线程各算一半」的基准，双线程**偶尔反而快约 8%**——预热、缓存、调度器亲和性都能造成这种噪声。教训是别教条：GVL 挡的是规模化并行，不保证「两线程一定更慢」；但「快不了多少、且数字完全不可复现」是稳的，所以教程不引用任何耗时。

## 20.3 Queue：生产者消费者

`Queue` 自带锁，是线程间传数据的首选：`pop` 在空时阻塞，`push` 永不竞争，**不用自己加锁**：

```ruby
q = Queue.new
producer = Thread.new do
  (1..5).each { |n| q << n }
  q.close                      # close 后 pop 取完剩余即返回 nil
end
w1 = Thread.new { items = []; while (x = q.pop); items << x; end; items }
w2 = Thread.new { items = []; while (x = q.pop); items << x; end; items }
collected = (w1.value + w2.value).sort   # 谁拿到哪个不确定 → join 后排序再比
```

实测输出：

```text
---- 20.3 Queue：生产者消费者 ----
生产 1..5，两个 worker 分工取完 —— 排序后汇总：[1, 2, 3, 4, 5]
```

`while (x = q.pop)` 是惯用法：`pop` 返回 `nil`（队列 close 且取空）时循环自然停。两个 worker 各拿到哪几个元素完全由调度决定——所以汇总前先 `sort`，比的是集合不是顺序。收尾三连：`q.closed?`、`q.empty?` 都是确定性的，可以直接断言。

生产者侧的 `q.close` 是这套协议的另一半：不 close，消费者在取空后 `pop` 永远阻塞，两个 worker 线程就永远 join 不回来。close 的语义是「不会再有新元素」——消费者先排干存量、再收到 nil 停机。这也是 20.5 里 `ClosedQueueError` 的由来：close 是单向阀，关了就只能消费，回头再 push 就是异常。

## 20.4 Mutex：互斥锁

`counter += 1` 是「读-改-写」三步，线程切换可丢更新。丢不丢看调度，结果不确定——所以示例**不演示无锁版**（打印出来就不是确定输出了），只锁有锁版：

```ruby
mutex = Mutex.new
counter = 0
threads = 4.times.map do
  Thread.new do
    100.times { mutex.synchronize { counter += 1 } }
  end
end
threads.each(&:join)
counter                                # => 400，必然精确
```

实测输出：

```text
---- 20.4 Mutex：互斥锁 ----
4 线程各 +100 次，Mutex.synchronize 下计数 = 400（无锁版可能丢失更新，不打印）
```

`synchronize { }` 保证块内独占；`mutex.owned?` 问「当前线程是否持锁」，主线程在块外自然是 false。经验法则：能用 `Queue` 传消息就别共享变量；真要共享，锁的粒度宁小勿大，且永远避免嵌套两把锁（死锁的经典配方）。

## 20.5 线程异常：join 时重新抛出

本章最重要的坑：**线程里抛异常不会打断主线程**。线程自己死掉，异常被吞进线程对象，直到有人 `join`/`value` 才在调用点 re-raise。更阴的是 `report_on_exception` 默认开启——线程死掉的瞬间就往 stderr 打一份报告。演示异常必须先把报告关掉（stderr 干净是本教程的硬指标）：

```ruby
problem = Thread.new do
  Thread.current.report_on_exception = false   # 关掉死后自动报告
  raise "线程内部炸了"
end
begin
  problem.join                                  # 异常在 join 调用点重新抛出
rescue RuntimeError => e
  e.class                                       # => RuntimeError
end
problem.status                                  # => nil（异常死亡；正常结束是 false）
```

实测输出：

```text
---- 20.5 线程异常：join 时重新抛出 ----
未处理前主线程毫发无伤；join 时 re-raise，捕获到 RuntimeError（中文句 + 类名）
关闭的 Queue 再 push → join 处抛 ClosedQueueError；运行时错误抛 RuntimeError —— 分类处理不误吞
```

同一出口还演示了错误分类：**对已 close 的 Queue 再 push 抛 `ClosedQueueError`**（20.3 的 close 用对了没事，用错了有专门的异常类），运行时错误抛 `RuntimeError`——在 join 处按类 rescue，各归各的处理路径，不误吞。

## 20.6 SizedQueue：背压

`SizedQueue.new(n)` 给队列加容量上限：满了再 push，**生产者阻塞**——这就是背压（backpressure），让快的一方被慢的一方自然限流：

```ruby
sq = SizedQueue.new(2)
sq << 1; sq << 2                     # 队列满
producer = Thread.new { sq << 99; :pushed }
sleep 0.05                           # 给生产者时间进入阻塞
producer.status                      # => "sleep"（阻塞中）
sq.size                              # => 2（停在容量上限）
sq.pop                               # 消费一个 → 生产者被放行
producer.join.value                  # => :pushed
```

实测输出：

```text
---- 20.6 SizedQueue：背压 ----
容量 2：满时生产者阻塞（size=2 处停下），pop 一个后完成推送 —— join 后取确定结果
```

这里 `status` 的第三种取值 `"sleep"` 上场了：`false` 正常结束、`nil` 异常死亡、`"sleep"` 阻塞中。背压断言的写法依赖这条语义，而不是猜队列内容。

## 20.7 ConditionVariable：条件等待

`Queue`/`SizedQueue` 覆盖不了的「等某个条件成立」，用 `ConditionVariable` + `Mutex` 握手：

```ruby
cv = ConditionVariable.new
lock = Mutex.new
ready = false
signaler = Thread.new do
  lock.synchronize do
    ready = true
    cv.signal                  # 唤醒一个 wait 者（broadcast 唤醒全部）
  end
end
lock.synchronize do
  cv.wait(lock) until ready    # wait 必须持锁调用，且用 until 重查条件
end
```

实测输出：

```text
---- 20.7 ConditionVariable：条件等待 ----
握手完成：等待方持锁 wait、通知方持锁 signal —— join 后按固定顺序打印：ready = true
```

两条铁律：**`wait` 必须持锁调用**（它内部先释放锁让通知方能进来，醒来时重新拿锁）；**醒来后必须用 `until` 重查条件**——等待者可能被虚假唤醒，条件未必真的成立。`signal` 唤醒一个、`broadcast` 唤醒全部，拿不准就 `broadcast`。

## 20.8 坑位清单

1. **不 join 的线程被主线程退出直接掐死**：每个 `Thread.new` 必有对应 `join`/`value` 收口（20.1）。
2. **线程异常默认被吞**：不打断主线程，只在 `join`/`value` 调用点 re-raise——不收口的线程死了都没人知道（20.5）。
3. **`report_on_exception` 默认 true，线程一死就往 stderr 打报告**：演示异常先 `Thread.current.report_on_exception = false`（20.5）。
4. **关闭的 Queue 再 push 抛 `ClosedQueueError`**：close 之后只能消费，生产侧要救就 rescue 这个类（20.5）。
5. **`status` 三态别混**：`false` 正常结束、`nil` 异常死亡、`"sleep"` 阻塞中——`status == false` 与 `status.nil?` 是完全不同的两种死法（20.1、20.6）。
6. **GVL 让 CPU 密集任务并行不提速**：线程的价值在 IO 阻塞时让出；CPU 并行去 21 章找 Ractor（20.2）。
7. **耗时对比根本不稳**：实测双线程 CPU 任务偶尔反快约 8%，数字受预热/调度噪声支配——别写进任何断言或文档（20.2）。
8. **无锁 `counter += 1` 丢不丢更新看调度**：结果不确定，演示和断言都必须走 `Mutex.synchronize`（20.4）。
9. **`cv.wait` 必须持锁调用且用 `until` 重查条件**：裸 `if` + wait 挡不住虚假唤醒（20.7）。
10. **多线程输出先 join 再排序汇总**：worker 间分工顺序由调度决定，直接打印必然不可复现（20.3、全书纪律）。
11. **`pop` 返回 `nil` 是 close 的信号**：`while (x = q.pop)` 惯用法靠它停机，忘了 close 就永远阻塞（20.3）。
12. **嵌套两把锁是死锁配方**：要么单锁，要么全程序规定统一的加锁顺序（20.4）。

---

[上一章](19-files.md) | [下一章](21-ractors.md)
