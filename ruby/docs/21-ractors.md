# 21 · Ractor 并行

> 对应示例：`examples/21_ractors/`

Ractor 是 Ruby 的真并行原语：每个 Ractor 有独立的 GVL，CPU 密集任务真能吃满多核——代价是**隔离**。隔离意味着你在 20 章养成的「共享变量」直觉全部作废，数据只能走参数、消息、Port 三条路。本章示例第一行代码就是 `Warning[:experimental] = false`（Ractor 仍是实验特性，默认往 stderr 打告警，而本教程 stderr 必须为空）——这行是全示例的生死线，必须出现在任何 `Ractor.new` 之前。

输出确定性纪律与 20 章同源：**多 Ractor 结果一律按固定顺序 `.value` 收口再打印**，绝不打印完成顺序。

## 21.1 最小 Ractor

`Ractor.new(参数) { |v| ... }`——参数按值传入（不可共享对象会被深拷贝），返回值用 `.value` 收口：

```ruby
r = Ractor.new(21) { |v| v * 2 }
r.value                          # => 42
Ractor.new("你好") { |s| s * 2 }.value   # => "你好你好"
```

实测输出：

```text
---- 21.1 最小 Ractor ----
Ractor.new(21) { |v| v * 2 }.value = 42 —— 参数传入即隔离，返回值用 .value 收口
```

**4.0 头号变更：`.take` 已删除**。旧教程里满屏的 `r.take`，现在一律用 `r.value`——语义等价于「join + 取返回值」。查资料看到 `.take` 就知道那是 3.x 时代的东西。

- `value` 可传多个参数：`Ractor.new(a, b) { |x, y| }`，每个参数独立按值传入（21.4 的深拷贝规则逐个适用）。
- 也可以先 `join` 再 `.value`：join 返回 Ractor 自身，拿值仍要 `.value`——21.7 的收尾写法。

## 21.2 消息传递：receive 与 <<

不带走返回值、要中途通信时，走消息：块里 `Ractor.receive` 阻塞收信，外面 `r << msg` 发信（发送的也是拷贝/移动语义，不是共享引用）：

```ruby
r2 = Ractor.new do
  msg = Ractor.receive       # 阻塞等消息
  "收到：#{msg}"
end
r2 << "乒乓球"               # 发进 r2 的入口 Port
r2.value                     # => "收到：乒乓球"
```

实测输出：

```text
---- 21.2 消息传递：receive 与 << ----
先 r << 消息再 .value 收口：收到：乒乓球
```

配套的坑：**`Ractor.new` 带参数时块不收消息**——带参形式的消息入口不走 `receive`。块里没调 `receive` 就别再 `<<`，否则发不进去（Port 已关闭时报 `ClosedError`）。

## 21.3 Ractor::Port

结果不想挤在 `.value` 一条道上，就给子 Ractor 发一个 `Ractor::Port`，让它把中间结果发回来。Port 只有四件套：`<<`（发）、`receive`（收，阻塞）、`close`、`closed?`：

```ruby
port = Ractor::Port.new
worker = Ractor.new(port) do |p|
  p << (1..100).sum          # 子 Ractor 把结果发进端口
end
port.receive                 # => 5050（主线程阻塞取结果）
worker.join                  # join 确保子 Ractor 干净退场
port.close
port.closed?                 # => true
```

实测输出：

```text
---- 21.3 Ractor::Port ----
port.receive = 5050；close 后 closed? = true
```

Port 与 `.value` 的分工：一次性结果用 `.value`；多次通信、流水线、多个结果用 Port。这也是 3.x 的 `Ractor.yield`/`r.take` 配对的现代替代——4.0 把「往哪儿发」显式化成端口对象了。

注意示例里 Port 是**作为参数传进**子 Ractor 的：Port 本身可共享，所以传的是引用而非拷贝——主线程 `port.receive` 收到的正是子 Ractor `p <<` 发来的那个值。收发双方谁先谁后无所谓：`receive` 阻塞等消息、`<<` 随时可发，这条不需要约定时序。而 `worker.join` 放在 `port.receive` 之后，是收口纪律的体现：先拿到结果，再等子 Ractor 退场。

## 21.4 可共享性：shareable? 与深拷贝

什么能直接跨 Ractor 共享？`Ractor.shareable?` 说了算：不可变对象天然可共享，可变对象不可共享：

```ruby
Ractor.shareable?(42)                  # => true（数字不可变）
Ractor.shareable?("frozen".freeze)     # => true（frozen 字符串）
Ractor.shareable?(+"mutable")          # => false（普通可变 String）
Ractor.shareable?({ a: 1 }.freeze)     # => true（冻结的哈希）
Ractor.shareable?({ a: 1 })            # => false
```

不可共享对象作为 Ractor 参数/消息传递时被**深拷贝**——两边从此是两个对象。示例用 `object_id` 断言验证（id 不同即拷贝），id 本身绝不打印：

```text
---- 21.4 可共享性：shareable? 与深拷贝 ----
frozen/数字可共享；可变对象传参被深拷贝（object_id 断言通过，不打印 id）
```

工程含义：大对象跨 Ractor 传参有拷贝成本；频繁传的常量数据，写完就 `.freeze`（或 `Ractor.make_shareable`），让它走共享而不是拷贝。

判 shared 与否的心智模型一句话：**可共享 = 冻结后的不可变结构（或数字/Symbol 这类天生不可变的东西）**。字符串要 `+"..."` 制造可变副本（frozen_string_literal 纪律的另一半），哈希/数组要显式 freeze——反过来，凡是「还没冻结的可变容器」，一律按「传了就会被深拷贝」来预期行为，别指望两边看到同一个对象。

## 21.5 Ractor.make_shareable

`Ractor.make_shareable(obj)` 递归冻结整棵对象树并返回——嵌套哈希里的内层结构也一并冻结：

```ruby
shared = Ractor.make_shareable([1, [2], { a: 3 }])
shared.frozen?                   # => true
shared[2].frozen?                # => true（内层也被冻）
```

冻结不了的对象它会明确拒绝：**对 Proc 调用抛 `Ractor::IsolationError`**（Proc 持有环境变量，线程、IO 同理）：

```text
---- 21.5 Ractor.make_shareable ----
make_shareable 递归冻结并返回；对 Proc 调用抛 Ractor::IsolationError（rescue 后打印中文句 + 类名）
```

对照 20 章的坑族：把 Thread 对象传进 Ractor，或对持有 Mutex 的结构 `make_shareable`，抛的是 `Ractor::Error`——Proc/不可冻结结构走 `IsolationError`，线程/Mutex 这类「天生不可隔离」的走 `Ractor::Error`。两类异常名像，报错场景不同，rescue 时别写串。

## 21.6 并行分治求和

Ractor 的正戏：1..100_000 切 4 份，4 个 Ractor 各自求和（每个有独立 GVL，真并行），主线程汇总：

```ruby
chunks = [[1, 25_000], [25_001, 50_000], [50_001, 75_000], [75_001, 100_000]]
partials = chunks.map do |lo, hi|
  Ractor.new(lo, hi) { |a, b| (a..b).sum }
end.map(&:value)                 # 依次 .value 收口（顺序固定，输出确定）
partials.sum                     # => 5_000_050_000
```

实测输出：

```text
---- 21.6 并行分治求和 ----
4 个 Ractor 分片求和，汇总 = 5000050000（= 100000*100001/2，逐片 [312512500, 937512500, 1562512500, 2187512500]）
```

注意 `map(&:value)` 的写法妙在**顺序天然确定**：哪怕 4 个 Ractor 谁先算完随机，`.value` 按创建顺序收口，partials 永远是 4 片的原顺序——这正是「join 后按固定顺序汇总」纪律在 Ractor 世界的写法。

分治粒度也有讲究：4 片是「片数 ≈ 核心数」的起点——片太多则每片的任务量抵不过 Ractor 的创建/拷贝开销，片太少则吃不满核心。切片本身只传两个 Integer（可共享，零拷贝），每片内部再各自求和，主线程只收 4 个整数——**传小消息、算大数据**是 Ractor 并行的成本模型要点。

## 21.7 Ractor.count 与收尾

`Ractor.count` 返回当前存活的 Ractor 数（至少 1，含主 Ractor）。`Ractor#join` 等结束、返回自身；拿值仍要 `.value`：

```ruby
bg = Ractor.new { 40 + 2 }
bg.join        # => bg（返回自身）
bg.value       # => 42
Ractor.count   # >= 1
```

实测输出：

```text
---- 21.7 Ractor.count 与收尾 ----
收尾纪律：value 或 join 二选一收口 —— 未收口的 Ractor 由 GC 兜底回收（计数回落有延迟）
```

**实测坑：别断言 `Ractor.count` 的精确值**。已结束的 Ractor 不会立即从计数消失，回落时机取决于 GC——所以示例只断言 `>= 1` 这种必然成立的下界。想拿「计数必须回落到 1」写断言的，先过了 GC 这一关再说。

## 21.8 外层局部变量不可见

Ractor 块长得像普通块，但它是独立执行单元——**引用外层局部变量是编译期错误**，根本轮不到运行时：

```ruby
outer = "外层的值"
Ractor.new { outer.upcase }   # 编译期 ArgumentError！
# 正确姿势：数据从参数进来
Ractor.new(outer) { |s| s.length }.value   # => 4
```

实测输出：

```text
---- 21.8 外层局部变量不可见 ----
Ractor 块引用外层局部变量 → 编译期拒绝（实测抛 ArgumentError）；要传数据请走参数或 Port
```

本机实测抛的是 `ArgumentError`（不是运行时的 `IsolationError`）——错误发生在代码编译/构造 Ractor 时，`begin/rescue` 能接到。数据进 Ractor 只有三条路：**参数、消息（`<<`/`receive`）、可共享常量**。这条约束初看烦人，实际上是 21.6 能放心并行的全部前提：没有共享就没有数据竞争。

## 21.9 坑位清单

1. **`Warning[:experimental] = false` 必须是第一行代码**：Ractor 实验告警默认打 stderr，且要在任何 `Ractor.new` 之前关（章首、全书 stderr 纪律）。
2. **`.take` 已删除**：4.0 取值一律 `r.value`，看到 `.take` 就是过时资料（21.1）。
3. **外层局部变量进 Ractor 块是编译期 `ArgumentError`**：不是运行时错误，数据只能走参数/消息/可共享常量（21.8）。
4. **带参数的 `Ractor.new` 块不收消息**：没调 `receive` 别 `<<`，否则 `ClosedError`（21.2）。
5. **`make_shareable(Proc)` 抛 `Ractor::IsolationError`，而 Thread/Mutex 相关抛 `Ractor::Error`**：两类异常场景不同，别 rescue 锯（21.5）。
6. **`Ractor.count` 回落取决于 GC**：结束 ≠ 计数立即下降，断言只写 `>= 1` 级别的下界（21.7）。
7. **可变对象传参被深拷贝**：大对象高频传参有拷贝成本，常量数据先 freeze 走共享（21.4）。
8. **`shareable?` 的分界是可变性不是类型**：`{ a: 1 }` 不可共享，`{ a: 1 }.freeze` 可以——忘 freeze 就吃拷贝（21.4）。
9. **多 Ractor 结果必须按创建顺序 `.value` 收口**：完成顺序随机，收口顺序写死，输出才确定（21.6）。
10. **`value` 或 `join` 二选一收口**：不收口的 Ractor 由 GC 兜底，但清理时机不可控（21.7）。
11. **Port 只有 `<<`/`receive`/`close`/`closed?` 四件套**：3.x 的 `yield`/`take` 配对已不存在，别按旧 API 找方法（21.3）。
12. **Ractor 仍是实验特性**：行为可能随版本变动，教程结论绑定 Ruby 4.0.7 实测（章首）。

---

[上一章](20-threads.md) | [下一章](22-fibers.md)
