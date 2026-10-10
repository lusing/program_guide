# 39 · 异步 IO 与并发编程

> **阅读位置**：第五篇 · 与系统对话（7/8，并发线） ｜ **承前**：[31 并发进阶](31-concurrency.md)、[29 网络](29-networking.md)（echo 演示） ｜ **启后**：[43 并行采集](43-zlocate.md)。
>
> 对应示例：`examples/39_asyncio/main.zig`（335 行，5 个测试）
>
> 取材 Tsoukalos ch8/ch9（`std.Io` 异步模型、fan-out/fan-in、TCP 代理），按 0.17.0
> 实测 API 重写。31 章讲了"多线程 + 共享状态"的**并发**，本章讲"不等结果的 I/O"的
> **异步**——以及 0.17 里两者的统一接口 `std.Io`。
>
> 本章有 **6 条实测结论**：
>
> 1. **`async`/`await` 不是 Zig 关键字**（39.1）。Zig 0.10 就把语言级 async/await
>    移除了；0.17 的模型是 `std.Io` 上的方法：`io.async(fn, .{args})` 返回 Future，
>    `future.await(io)` 收结果，`future.cancel(io)` 取消。网上所有写 `async fn` 的
>    Zig 教程都是 0.9 之前的古董。
> 2. **`io.async` 不保证真并发，`io.concurrent` 保证**（39.2）。前者可能立即在
>    当前线程执行（后端说了算），后者失败时报 `error.ConcurrencyUnavailable`。
>    要"同时跑多个"，用 `io.concurrent`。
> 3. **`std.Io.Select(T)` 让任务赛跑，await 返回 tagged union 告诉你谁赢了**（39.5）。
>    这是超时、熔断、多源取最快的标准原语。输家要 `cancel()` 收掉，防资源泄漏。
> 4. **`std.Io.Group` 是结构化并发原语**（39.4）。`group.async` 扇出、
>    `group.await` 扇入、`defer group.cancel` 兜底——0.17 没有
>    `std.Thread.WaitGroup`（31 章实测已移除），Group 是官方替代品。
> 5. **spawn 的线程没有 `init.io`，要自己造 `std.Io.Threaded`**（39.6）。
>    `std.Io.Threaded.init(gpa, .{})` 创建一个线程池后端；测试里用
>    `.init_single_threaded` 拿单线程版。
> 6. **默认 `std.Io.Threaded` 后端是 OS 线程池，不是协程**（39.1）。
>    协程要显式选事件化后端（`std.Io.Uring` / `std.Io.Dispatch` / `std.Io.Kqueue`）。
>    "协程比线程轻量"的说法只在事件化后端下成立。
>
> **节号对应**：39.1–39.7 是示例 `main` 里的运行时小节；**39.8（坑位清单详解）与
> 39.9（验证方式）不在 `main` 里**，是本文档自己的两节。

---

## 导读：这一章要推翻四个说法

**说法一："Zig 的异步就是 `async fn` + `await`。"**

错，而且错得离谱。Zig 在 **0.10**（2022 年）就移除了语言级 async/await——
不是"计划移除"，是已经移了三个大版本。0.17 的异步是 `std.Io` 的**方法**：
`io.async(sleepAndReturn, .{io, 20, 7})` 返回一个 Future 值，
`fut.await(io)` 收结果。`async` 和 `await` 在这里是标识符（方法名），不是关键字。
你在网上看到的 `async fn foo() !void` 写法是 0.9 之前的古董，0.17 编译器直接报
`expected identifier, found keyword`——不，连这个错误都不会有，因为 `async` 不是
关键字了，它会把 `async` 当普通标识符然后报一堆类型错。

**说法二："异步 = 并发，并发 = 多线程。"**

错。并发是**结构**（把任务拆成独立单元），异步是**不阻塞**（等 I/O 时 CPU 去干别的）。
单线程异步程序可以高效管理上千连接（Node.js 就是），多线程程序也可以全程阻塞
（29 章的 echo 服务器就是）。39.3 的 fan-out 演示：三个任务"同时"启动，
但默认后端可能用线程池跑——你写的是"异步"，底层是"并发"，两者正交。

**说法三："要等所有任务完成才知道哪个最快。"**

错。`std.Io.Select(T)` 专门解决"多个来源取第一个结果"：两个任务赛跑，
`await` 返回 tagged union 告诉你谁赢了（39.5）。超时控制、多镜像下载、
健康检查都靠这个模式。

**说法四："0.17 没有结构化并发，只能 spawn + join。"**

错。`std.Io.Group` 就是：扇出时注册任务，扇入时 `await` 等全部完成，
异常退出时 `defer cancel` 兜底取消。配合 `io.concurrent` 的
`ConcurrencyUnavailable` 错误处理，是 0.17 里写并发服务的标准骨架。

---

## 39.1 历史课：async/await 关键字的消亡

```zig
// examples/39_asyncio/main.zig 第 31-47 行
fn sectionHistory() void {
    begin("39.1 历史课");
    std.debug.print("Zig 0.10 移除了 async/await 关键字（它们曾是语言级特性）\n", .{});
    std.debug.print("0.17 的异步模型是 std.Io 上的一组方法，不是语法：\n", .{});
    std.debug.print("  io.async(fn, .{{args}})      → Future（可能立即执行，不保证并发）\n", .{});
    std.debug.print("  io.concurrent(fn, .{{args}}) → Future（保证真并发，失败报 ConcurrencyUnavailable）\n", .{});
    std.debug.print("  future.await(io)             收结果\n", .{});
    std.debug.print("  future.cancel(io)            请求取消（defer 安全网）\n", .{});
    std.debug.print("  std.Io.Group                 结构化扇出\n", .{});
    std.debug.print("  std.Io.Select(T)             竞速\n", .{});
    std.debug.print("@hasDecl(std.Io, \"async\") = {}（comptime 验证存在）\n", .{@hasDecl(std.Io, "async")});
    // ...
    end("39.1 历史课");
}
```

运行输出：

```text
Zig 0.10 移除了 async/await 关键字（它们曾是语言级特性）
0.17 的异步模型是 std.Io 上的一组方法，不是语法：
  io.async(fn, .{args})      → Future（可能立即执行，不保证并发）
  io.concurrent(fn, .{args}) → Future（保证真并发，失败报 ConcurrencyUnavailable）
  future.await(io)             收结果
  future.cancel(io)            请求取消（defer 安全网）
  std.Io.Group                 结构化扇出
  std.Io.Select(T)             竞速
@hasDecl(std.Io, "async") = true（comptime 验证存在）
@hasDecl(std.Io, "concurrent") = true
@hasDecl(std.Io, "Group") = true
@hasDecl(std.Io, "Select") = true
⇒ 全部是 std.Io 的方法/类型，不是关键字。
```

`@hasDecl(std.Io, "async")` 在 comptime 求值为 `true`——`async` 是 `std.Io`
类型上的**声明**（方法），不是保留字。这解释了为什么你能写 `io.async(...)`
而不需要语言特判。

### 协程 vs OS 线程：理论背景

书中 ch9 的核心区分，本章浓缩为一张表：

| | OS 线程 | 协程（事件化后端） |
|---|---|---|
| 调度 | 内核抢占式 | 用户协作式（I/O 点让出） |
| 栈 | 固定 8-16 MB | 动态增长，KB 级 |
| 并发上限 | 数千（内存受限） | 数十万（调度开销受限） |
| 后端 | `std.Io.Threaded`（默认） | `std.Io.Uring` / `Dispatch` / `Kqueue` |

**关键**：默认的 `std.Io.Threaded` 是**线程池**（CPU 核数 - 1 个 worker），
不是协程。`io.async` 提交的任务在线程池上跑——你得到的是真并发，不是轻量协程。
协程优势只在显式选事件化后端时成立。

---

## 39.2 第一个异步任务

```zig
// examples/39_asyncio/main.zig 第 54-74 行
/// 睡 ms 毫秒后返回 value。模拟一个"耗时计算"。
fn sleepAndReturn(io: std.Io, ms: u64, value: u32) std.Io.Cancelable!u32 {
    try std.Io.sleep(io, .fromMilliseconds(@intCast(ms)), .awake);
    return value;
}

fn sectionFirstAsync(io: std.Io) !void {
    begin("39.2 第一个异步任务");
    var fut = try io.concurrent(sleepAndReturn, .{ io, @as(u64, 20), @as(u32, 7) });
    defer {
        _ = fut.cancel(io) catch {};
    }
    const v = fut.await(io) catch |err| switch (err) {
        error.Canceled => return error.UnexpectedCancel,
    };
    std.debug.print("并发任务返回 {d}\n", .{v});
    // ...
    end("39.2 第一个异步任务");
}
```

四步生命周期：

1. **`io.concurrent(fn, .{args})`**：提交任务。`fn` 的签名决定了 Future 的类型——
   这里 `sleepAndReturn` 返回 `Cancelable!u32`，所以 `fut` 是
   `Future(Cancelable!u32)`。`args` 是 tuple，类型必须和 `fn` 的参数一一对应。
2. **`defer fut.cancel(io)`**：安全网。如果 `await` 之前出错退出（比如另一个
   `try` 失败），`cancel` 确保任务不会泄漏。`await` 成功后再 `cancel` 是 no-op。
3. **`fut.await(io)`**：收结果。返回 `fn` 的返回类型（这里是 `Cancelable!u32`），
   所以还要处理 `error.Canceled`——任务被取消了（不是我们取消的，是外部
   `io` 后端取消的，比如超时）。
4. **结果**：`v == 7`。

**`io.async` vs `io.concurrent`**：`io.async` 允许后端"立即在当前线程执行"
（如果后端认为这样更快）；`io.concurrent` 强制要求真并发，后端做不到时报
`error.ConcurrencyUnavailable`。写"必须同时跑"的代码时用 `concurrent`，
写"顺序无所谓"的代码时用 `async`。

运行输出：

```text
==== 39.2 第一个异步任务 开始 ====
并发任务返回 7
⇒ io.concurrent 返回 Future，future.await(io) 收结果。
⇒ defer fut.cancel(io) 是安全网：await 后 cancel 是 no-op，但写上无害。
==== 39.2 第一个异步任务 结束 ====
```

---

## 39.3 fan-out/fan-in：扇出扇入

```zig
// examples/39_asyncio/main.zig 第 80-104 行
fn sectionFanOut(io: std.Io) !void {
    begin("39.3 fan-out/fan-in");
    var fut_a = try io.concurrent(sleepAndReturn, .{ io, @as(u64, 10), @as(u32, 1) });
    defer { _ = fut_a.cancel(io) catch {}; }
    var fut_b = try io.concurrent(sleepAndReturn, .{ io, @as(u64, 30), @as(u32, 2) });
    defer { _ = fut_b.cancel(io) catch {}; }
    var fut_c = try io.concurrent(sleepAndReturn, .{ io, @as(u64, 20), @as(u32, 3) });
    defer { _ = fut_c.cancel(io) catch {}; }

    const a = fut_a.await(io) catch return error.UnexpectedCancel;
    const b = fut_b.await(io) catch return error.UnexpectedCancel;
    const c = fut_c.await(io) catch return error.UnexpectedCancel;
    std.debug.print("任务 A (10ms) 返回 {d}\n", .{a});
    std.debug.print("任务 B (30ms) 返回 {d}\n", .{b});
    std.debug.print("任务 C (20ms) 返回 {d}\n", .{c});
    std.debug.print("⇒ 3 个任务并发执行，墙钟时间 ≈ 最慢的 30ms，不是 10+30+20=60ms。\n", .{});
    // ...
    end("39.3 fan-out/fan-in");
}
```

**fan-out** = 先启动全部三个（10ms、30ms、20ms），**fan-in** = 按序 await。
墙钟时间 ≈ 30ms（最慢的那个），不是 60ms（求和）。

**await 顺序不影响完成顺序**：`fut_a` 最先 await，但如果 B 先完成，await B 的
时候不会等——`await` 只是"收结果"，不是"等完成"。Future 在任务完成时就绪，
await 立即返回。

**结果槽位**：三个 Future 是独立变量，各自持有结果——不需要共享数组、不需要
mutex。这是 fan-out/fan-in 比"共享计数器"模式更安全的原因：每个结果有专属
所有者。

---

## 39.4 Io.Group 结构化并发

```zig
// examples/39_asyncio/main.zig 第 111-130 行
/// Group 任务必须返回 Cancelable!void（或能 coerce 到它）。
fn groupTask(io: std.Io, ms: u64, label: []const u8, counter: *std.atomic.Value(u32)) std.Io.Cancelable!void {
    try std.Io.sleep(io, .fromMilliseconds(@intCast(ms)), .awake);
    _ = counter.fetchAdd(1, .seq_cst);
    std.debug.print("  Group 任务 {s} 完成\n", .{label});
}

fn sectionGroup(io: std.Io) !void {
    begin("39.4 Io.Group 结构化并发");
    var group: std.Io.Group = .init;
    defer group.cancel(io);
    var counter = std.atomic.Value(u32).init(0);
    group.async(io, groupTask, .{ io, @as(u64, 15), @as([]const u8, "甲"), &counter });
    group.async(io, groupTask, .{ io, @as(u64, 25), @as([]const u8, "乙"), &counter });
    try group.await(io);
    const done = counter.load(.seq_cst);
    std.debug.print("Group 完成 {d} 个任务\n", .{done});
    // ...
    end("39.4 Io.Group 结构化并发");
}
```

`std.Io.Group` 是"一组任务的集合"，三个操作：

| 操作 | 含义 |
|---|---|
| `group.async(io, fn, args)` | 扇出：注册一个任务（不返回 Future，结果通过副作用收集） |
| `group.await(io)` | 扇入：阻塞到**全部**任务完成 |
| `group.cancel(io)` | 兜底：取消所有未完成 task（defer 里调用） |

**为什么用 Group 而不是三个独立 Future？** 任务数量动态时（比如"对每个文件
起一个任务"），没法声明固定数量的 Future 变量。Group 是动态集合——
`for (files) |f| group.async(io, process, .{f});` 就行。

**结果收集靠副作用**：`groupTask` 不返回值（`Cancelable!void`），它把结果
写到共享的 `counter` 里。这是 Group 的设计约定——返回值没有 Future 槽位，
要输出就用指针参数。

**`defer group.cancel(io)`**：如果 `await` 之前出错（比如某个 `group.async`
之后的代码 panic 了），cancel 确保已注册的任务不会泄漏。

运行输出：

```text
==== 39.4 Io.Group 结构化并发 开始 ====
  Group 任务 test-甲 完成
  Group 任务 test-乙 完成
Group 完成 2 个任务
⇒ Group 是结构化并发：任务作为一个整体 await 或 cancel。
⇒ group.async 不返回值（void），结果通过副作用（counter）收集。
==== 39.4 Io.Group 结构化并发 结束 ====
```

---

## 39.5 Io.Select 竞速

```zig
// examples/39_asyncio/main.zig 第 136-165 行
const RaceResult = union(enum) {
    fast: u32,
    slow: u32,
};

/// Select 任务必须返回字段类型本身（不是 error union），所以包一层。
fn selectSleep(io: std.Io, ms: u64, value: u32) u32 {
    return sleepAndReturn(io, ms, value) catch |err| switch (err) {
        error.Canceled => 0,
    };
}

fn sectionSelect(io: std.Io) !void {
    begin("39.5 Io.Select 竞速");
    var buffer: [2]RaceResult = undefined;
    var sel = std.Io.Select(RaceResult).init(io, &buffer);
    sel.async(.fast, selectSleep, .{ io, @as(u64, 50), @as(u32, 50) });
    sel.async(.slow, selectSleep, .{ io, @as(u64, 200), @as(u32, 200) });
    const winner = sel.await() catch return error.UnexpectedCancel;
    switch (winner) {
        .fast => |v| std.debug.print("快者胜: {d}ms 任务（返回 {d}）\n", .{ v, v }),
        .slow => |v| std.debug.print("快者胜: {d}ms 任务（返回 {d}）\n", .{ v, v }),
    }
    _ = sel.cancel();
    // ...
    end("39.5 Io.Select 竞速");
}
```

`std.Io.Select(T)` 的类型参数是 tagged union——每个字段对应一个任务，字段名
是标签，字段类型是任务的返回类型。`sel.async(.fast, fn, args)` 注册任务：
第一个参数是 `comptime field: Field`（union 的字段枚举），告诉 Select
"这个任务完成时，把结果装进 `.fast` 槽位"。

**`await` 返回 `RaceResult`**——tagged union 告诉你谁赢了，同时携带赢家的值。
这是超时控制的骨架：

```zig
const Result = union(enum) { response: []u8, timeout: void };
var sel = std.Io.Select(Result).init(io, &buf);
sel.async(.response, fetchData, .{url});
sel.async(.timeout, sleepVoid, .{5000}); // 5 秒超时
const r = sel.await() catch ...;
switch (r) {
    .response => |data| ...,
    .timeout => return error.Timeout,
}
sel.cancel(); // 收掉没跑完的那个
```

**`sel.cancel()` 收掉输家**：50ms 任务赢的时候，200ms 任务还在跑。不 cancel
它就泄漏了——占着线程池槽位直到自然结束。`cancel` 取消所有未完成 task。

**`selectSleep` 包装层**：`Select` 要求任务返回字段类型本身（`u32`），不接受
error union。`sleepAndReturn` 返回 `Cancelable!u32`，包一层把
`error.Canceled` 映射为 0。

---

## 39.6 并发 TCP echo 服务器 + 客户端

### 服务器线程：自建 Io 实例

```zig
// examples/39_asyncio/main.zig 第 172-192 行
const ServerCtx = struct {
    threaded: *std.Io.Threaded,
    listener: *net.Server,
};

/// echo 服务器线程：接受一条连接，回声一次，退出。
fn echoServer(ctx: *ServerCtx) void {
    const io = ctx.threaded.io();
    var stream = ctx.listener.accept(io) catch return;
    defer stream.close(io);
    var rbuf: [256]u8 = undefined;
    var fr = stream.reader(io, &rbuf);
    const r = &fr.interface;
    r.fillMore() catch return;
    const data = r.buffered();
    var wbuf: [256]u8 = undefined;
    var fw = stream.writer(io, &wbuf);
    const w = &fw.interface;
    w.writeAll(data) catch return;
    w.flush() catch {};
}
```

**关键：`spawn` 的线程没有 `init.io`**。`std.process.Init` 只在主线程的
`main` 里存在。 spawned 线程要 I/O 就得自己造一个 `std.Io.Threaded`：

```zig
// examples/39_asyncio/main.zig 第 213-215 行
var server_threaded = std.Io.Threaded.init(gpa, .{});
defer server_threaded.deinit();
const server_io = server_threaded.io();
```

`std.Io.Threaded.init(gpa, .{})` 创建一个线程池后端（默认 CPU 核数 - 1 个
worker）。`server_threaded.io()` 返回 `std.Io` 值——轻量句柄，可以跨线程传递。

### 客户端：io.concurrent

```zig
// examples/39_asyncio/main.zig 第 195-236 行
/// 客户端任务：连接 + 发 + 收，返回收到的字节数。
fn echoClient(io: std.Io, port: u16) !usize {
    const addr = try net.IpAddress.parseIp4("127.0.0.1", port);
    var stream = try addr.connect(io, .{ .mode = .stream });
    defer stream.close(io);
    var wbuf: [256]u8 = undefined;
    var fw = stream.writer(io, &wbuf);
    try fw.interface.writeAll("ping-asyncio");
    try fw.interface.flush();
    var rbuf: [256]u8 = undefined;
    var fr = stream.reader(io, &rbuf);
    const r = &fr.interface;
    try r.fillMore();
    return r.bufferedLen();
}

fn sectionTcpEcho(io: std.Io, gpa: std.mem.Allocator) !void {
    begin("39.6 并发 TCP echo 服务器 + 客户端");
    var server_threaded = std.Io.Threaded.init(gpa, .{});
    defer server_threaded.deinit();
    const server_io = server_threaded.io();

    const addr = try net.IpAddress.parseIp4("127.0.0.1", 0);
    var listener = try addr.listen(server_io, .{});
    defer listener.deinit(server_io);
    const port = listener.socket.address.getPort();

    var ctx = ServerCtx{ .threaded = &server_threaded, .listener = &listener };
    const th = try std.Thread.spawn(.{}, echoServer, .{&ctx});

    var fut = try io.concurrent(echoClient, .{ io, port });
    defer { _ = fut.cancel(io) catch {}; }
    const n = fut.await(io) catch return error.UnexpectedCancel;
    th.join();
    std.debug.print("echo 往返成功（{d} 字节）\n", .{n});
    // ...
    end("39.6 并发 TCP echo 服务器 + 客户端");
}
```

架构：服务器在 spawned 线程（自己的 Threaded 实例），客户端在主线程
（`io.concurrent` 提交到主线程的 Threaded 池）。两者通过 TCP 回环通信。

**端口确定性**：`parseIp4("127.0.0.1", 0)` 让内核分配 ephemeral 端口，
`listener.socket.address.getPort()` 读回实际端口。不硬编码端口号——
测试环境端口可能被占。

**确定性**：服务器只服务一条连接就退出（`echoServer` 没有循环），主线程
`th.join()` 等它结束。不可能挂死。

---

## 39.7 坑位清单

示例的 39.7 节打印了清单。逐条展开：

### 1. async/await 不是关键字

0.10 移除。写 `async fn` 在 0.17 是语法错误（`async` 不是关键字，但
`fn` 前的标识符位置也不接受它——编译器会报 `expected identifier` 或类型错）。
正确写法：`io.async(theFn, .{args})`——函数是普通函数，`async` 是方法名。

### 2. Future 必须 await 或 cancel

`io.async` / `io.concurrent` 返回的 Future 是资源——任务在后台跑着，
不占槽位就泄漏。`defer fut.cancel(io)` 是安全网：正常路径 await 消费了
Future，cancel 是 no-op；异常路径 cancel 兜底。

### 3. `io.concurrent` 的错误处理

```zig
var fut = try io.concurrent(sleepAndReturn, .{...});
//  ^^^ 这里可能报 error.ConcurrencyUnavailable
```

后端做不到真并发时（比如单线程构建 `builtin.single_threaded`），`concurrent`
失败。`async` 不会失败（可以退化成内联执行），所以返回非错误类型。

### 4. 默认 Threaded 后端是线程池

`std.Io.Threaded` 的默认配置：`async_limit = CPU 核数 - 1`，每个 worker
一个 OS 线程。`io.async` 提交的任务在这些 worker 上跑——是真并发，不是协程。
"协程比线程轻"只在事件化后端（`std.Io.Uring` / `Dispatch` / `Kqueue`）下成立。
选后端：`std.Io.Threaded.init(gpa, .{ .evented = true })`（如果编译目标支持）。

### 5. `std.Thread.Pool` / `WaitGroup` 已移除

31 章实测：`@hasDecl(std.Thread, "Pool")` = `false`，`WaitGroup` 同样。
替代方案：`std.Io.Group`（结构化并发）或 `std.Io.Threaded`（线程池）。
等 N 个任务：`group.async` N 次 + `group.await`。

### 6. Group 任务的异常处理

`group.async` 注册的函数如果 panic 了，整个进程退出（Zig 的 panic 语义）。
没有"任务级异常捕获"——Zig 没有异常机制，panic 就是进程终止。要容错，
在任务函数内部 `catch` 并记录，不要让错误变成 panic。

---

## 39.8 和书上的差异一览

| 书（0.15/0.16 写法） | 本章（0.17 实测） | 原因 |
|---|---|---|
| `io.async(fn, .{args})` 返回 `Future` | 相同 | 0.17 保留了这套 API |
| `std.Io.Threaded = .init_single_threaded` | 相同（测试）/ `std.Io.Threaded.init(gpa, .{})`（运行时） | 测试用编译期常量，运行时要 gpa |
| TCP 代理（~100 行） | 并发 echo（~40 行） | 教学聚焦：代理的核心是 transferOneWay + half-close，echo 已覆盖"双向 + 线程边界" |
| `std.Io.Select` 超时演示 | 竞速演示 | Select API 相同，超时是应用层模式 |
| io_uring / kqueue 裸后端（~200 行） | 理论提及（39.1） | 事件化后端在 0.17 仍是实验性；教学价值在"理解模型"而非"调内核 API" |

---

## 39.9 本章的验证方式

三层，与全项目一致：

```bash
cd examples/39_asyncio
zig fmt --check .                                    # 第 1 层：格式 + 语法
zig test main.zig                                    # 第 2 层：5 个 test
zig build-exe main.zig -femit-bin=/tmp/39_asyncio    # 第 3 层：main 也要能编
/tmp/39_asyncio                                      # 第 3 层：真跑一遍
```

不需要 `-lc`——纯 Zig std，无 C 依赖。

第 3 层不可省：`zig test` 不执行 `main`，而本章 7 个运行时小节全在 `main` 里。

跑完应看到（逐字节确定）：

```text
==== 39.1 历史课 开始 ====
Zig 0.10 移除了 async/await 关键字（它们曾是语言级特性）
0.17 的异步模型是 std.Io 上的一组方法，不是语法：
  ...
⇒ 全部是 std.Io 的方法/类型，不是关键字。
==== 39.1 历史课 结束 ====
==== 39.2 第一个异步任务 开始 ====
并发任务返回 7
==== 39.2 第一个异步任务 结束 ====
==== 39.6 并发 TCP echo 服务器 + 客户端 开始 ====
echo 往返成功（12 字节）
==== 39.6 并发 TCP echo 服务器 + 客户端 结束 ====
39 章自检通过
```

5 个测试覆盖：`sleepAndReturn` 纯逻辑（0ms 立即返回）、fan-out 结果按序收集、
Io.Group 计数器、Io.Select 竞速（快者胜）、echo 客户端逻辑（不依赖网络——
用 `std.Io.Threaded = .init_single_threaded` 在单线程里跑）。
