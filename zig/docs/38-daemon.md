# 38 · 实战：守护进程与信号

> **阅读位置**：第五篇 · 与系统对话（4/8，进程线） ｜ **承前**：[22 进程](22-process.md)、[17 C 互操作](17-c-interop.md)（std.c 系统调用） ｜ **启后**：[34](34-zcache.md)/[42](42-memsrv.md)/[43](43-zlocate.md) 这类常驻服务的部署形态。
>
> 对应示例：`examples/38_daemon/main.zig`（302 行，5 个测试，须 `-lc`）
>
> 取材 Tsoukalos ch7（信号处理 / fork / 守护进程化 / zcron），按 0.17.0 实测重写。
> 22 章讲了"怎么起子进程并等它结束"，本章讲"怎么让进程**活着**并响应系统事件"——
> 信号、僵尸收割、daemon 化、迷你调度器。全部走 `std.c` / `std.posix` 的 0.17 真实 API。
>
> 本章有 **6 条实测结论**：
>
> 1. **`std.posix.waitpid` 在 0.17 不存在**。`grep -c waitpid lib/std/posix.zig` = **0**。
>    收割子进程只有 `std.c.waitpid`（38.2）。书里说的"`std.posix.waitpid` 把 ECHILD
>    当 unreachable"在 0.17 已经进化成"整个函数没了"。
> 2. **`std.posix.sigaction` 返回 `void`**（38.1）。失败即 unreachable——传参错了
>    是程序员 bug，不是运行时错误。0.17 的错误哲学： preventable 的错误在编译期，
>    程序员错误直接 panic。
> 3. **信号 handler 里唯一能写的是 lock-free 原子变量**（38.1 / 38.6）。
>    POSIX 禁止在 handler 里 malloc / printf / 拿锁——不是"不建议"，是"可能死锁或堆损坏"。
>    主循环轮询原子标志是唯一正确模式。
> 4. **double-fork 不是仪式，是防"重新获得控制终端"的正式手段**（38.5）。
>    `setsid` 后进程仍是会话首进程，再 fork 一次让孙进程**永远不是**会话首进程，
>    从而任何 `open()` 终端设备都不会把它绑回终端。
> 5. **`std.c.fork` 返回 `pid_t`（c_int），用 `== 0` 判子进程**（38.2）。
>    不是 `Option` 不是 `!pid_t`——C 的返回值约定原样保留，`< 0` 是错误。
> 6. **`std.Io.sleep` 取代 `std.time.sleep`**（38.7）。签名三参数：
>    `sleep(io, Duration, .awake)`——`.awake` 是单调时钟，不受系统时间跳变影响。
>
> **节号对应**：38.1–38.8 是示例 `main` 里的运行时小节；**38.9（坑位清单详解）与
> 38.10（验证方式）不在 `main` 里**，是本文档自己的两节。

---

## 导读：这一章要推翻四个说法

**说法一："信号 handler 里可以随便写代码，反正能跑。"**

错。POSIX 对 async-signal-safe 有**白名单**（`write(2)`、`_exit(2)` 等少量函数），
`malloc` / `printf` / `mutex.lock` 全部不在名单上。原因不是"官方洁癖"：信号可以在
**任何时刻**打断任何线程，包括正持有堆锁或互斥锁的那个线程。handler 里再调
`malloc` 就会对同一把锁二次加锁——非递归锁直接死锁。38.6 有完整的允许/禁止清单。

**说法二："子进程退出就完了，不用管它。"**

错。子进程退出后在内核进程表里留一条**僵尸记录**（`Z` 状态），直到父进程 `waitpid`
收割。父进程不收割，记录就一直在——长跑服务反复 fork 会把进程表打满。38.3 演示
了"故意不收割 → 200ms 后 WNOHANG 收割"的全过程。

**说法三："daemon 化就是末尾加个 `&`。"**

错。`&` 只做了"后台运行"一件事。真正的守护进程要：脱离 shell 的 job control
（fork）、脱离控制终端（setsid）、**再** fork 一次防重新获得终端、chdir("/") 防
占用文件系统、dup2 /dev/null 切断 stdio。38.5 给出完整 recipe。

**说法四："调度器一定要多线程 + 优先队列。"**

错。Redis 和 Nginx 的单线程事件循环证明：一个 `while` + 固定数组 + `isDue()`
判断就够。38.7 的 zcron 迷你版用**栈上** `[3]Job` 数组（不分配内存）、
30ms tick、纯函数 `isDue`——零依赖、零分配、可单测。

---

## 38.1 信号处理基础：sigaction + 原子标志位

### 全局原子标志：handler 唯一能写的东西

```zig
// examples/38_daemon/main.zig 第 20-31 行
/// 全局原子标志：信号处理器唯一允许写的状态。
/// 必须是全局变量——信号处理器不接收用户指针（SA_SIGINFO 除外），
/// 只能写模块级变量。这是本章唯一允许的全局状态。
var g_sigint_received: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);

/// SIGINT 处理器：async-signal-safe 的唯一正确写法。
/// 规则：只写 lock-free 原子变量，不 malloc、不 print、不拿锁。
fn handleSigint(sig: std.c.SIG) callconv(.c) void {
    _ = sig;
    // .monotonic 足够：处理器里不需要同步顺序，只需要原子性
    g_sigint_received.store(true, .monotonic);
}
```

三个细节，每个都是 0.17 的实测结论：

1. **`var` 不是 `const`**。`std.atomic.Value(bool)` 的 `store` 需要 `*Self`（可变指针），
   所以全局变量必须 `var`。但它是**原子**的——多线程并发 store/load 不会撕裂。
2. **`callconv(.c)` 是硬性要求**。内核用 C 调用约定投递信号；漏写编译器不报错，
   但运行时调用约定不匹配直接 UB。
3. **`.monotonic` 序在 handler 里足够**。`std.atomic.Value` 的 store/load 默认
   `.seq_cst`（最强），但信号场景只需要"原子地写一次布尔"——`.monotonic` 是最便宜的
   正确序。主循环用 `.acquire` 读（见下文），配对 `.release` 写，构成 happens-before。

### 安装 handler：sigaction 返回 void

```zig
// examples/38_daemon/main.zig 第 92-113 行
begin("38.1 信号处理基础");
try w.print("安装 SIGINT handler...\n", .{});
const act: std.posix.Sigaction = .{
    .handler = .{ .handler = handleSigint },
    .mask = std.posix.sigemptyset(),
    .flags = 0,
};
// 0.17：sigaction 返回 void，失败直接 unreachable（EINVAL = 程序员错误）
std.posix.sigaction(std.c.SIG.INT, &act, null);
try w.print("SIGINT handler 安装成功\n", .{});
try w.print("handler 类型: {s}\n", .{@typeName(@TypeOf(handleSigint))});
try w.print("规则: handler 里只写原子变量，不 malloc / 不 print / 不拿锁\n", .{});
// 不真的发 SIGINT（不确定时序）；演示优雅退出路径靠手动置位
g_sigint_received.store(true, .release);
var spins: usize = 0;
while (!g_sigint_received.load(.acquire)) {
    try std.Io.sleep(io, std.Io.Duration.fromMilliseconds(50), .awake);
    spins += 1;
    if (spins > 100) break;
}
try w.print("SIGINT 已捕获，优雅退出\n", .{});
end("38.1");
```

`std.posix.Sigaction` 是 `extern struct`，三个字段：

| 字段 | 值 | 含义 |
|---|---|---|
| `.handler` | `.{ .handler = handleSigint }` | 收到信号时调用的函数（另一种是 `.sigaction` 带 siginfo） |
| `.mask` | `std.posix.sigemptyset()` | 处理期间屏蔽的信号集——空集 = 不额外屏蔽 |
| `.flags` | `0` | 不用 SA_RESTART 等修饰 |

**0.17 的 `sigaction` 返回 `void`**——不是 `!void`。传了非法信号号或 handler 指针？
那是程序员 bug，编译期或 panic 拦住，不是运行时错误。这个设计哲学贯穿 0.17：
可预防的错误在编译期，程序员错误直接 unreachable。

**为什么不真的发 SIGINT？** 信号是异步的——`kill(getpid(), SIGINT)` 后 handler
何时执行由内核决定，测试输出不确定。演示改用"手动置位 + 走同一条轮询路径"：
`g_sigint_received.store(true, .release)` 之后，`while (!load(.acquire))` 循环
的行为和真收到信号**完全一致**——因为 handler 做的唯一一件事就是这次 store。

运行输出：

```text
安装 SIGINT handler...
SIGINT handler 安装成功
handler 类型: fn (c.SIG__enum_10) callconv(.c) void
规则: handler 里只写原子变量，不 malloc / 不 print / 不拿锁
SIGINT 已捕获，优雅退出
```

`c.SIG__enum_10` 是 macOS 上 `std.c.SIG` 枚举的编译器内部名（Linux 上不同），
`@typeName` 如实反映——跨平台代码不要依赖这个名字。

---

## 38.2 fork 与 waitpid

### fork：一次调用，两次返回

```zig
// examples/38_daemon/main.zig 第 116-134 行
begin("38.2 fork 与 waitpid");
const pid = std.c.fork();
if (pid == 0) {
    // 子进程分支：打印自己的 PID，以 42 退出
    try w.print("  子进程: 我的 PID = {d}，即将 _exit(42)\n", .{std.c.getpid()});
    w.flush() catch {};
    std.c._exit(42);
}
// 父进程分支
try w.print("父进程: 我的 PID = {d}，子进程 PID = {d}\n", .{ std.c.getpid(), pid });
var status: c_int = 0;
_ = std.c.waitpid(pid, &status, 0);
const ustatus: u32 = @bitCast(status);
try w.print("waitpid 返回: W.IFEXITED = {}，exit status = {d}\n", .{
    std.posix.W.IFEXITED(ustatus),
    std.posix.W.EXITSTATUS(ustatus),
});
end("38.2");
```

`std.c.fork()` 的返回值约定原样来自 C：

| 返回值 | 含义 | 分支 |
|---|---|---|
| `< 0` | 出错（如 RLIMIT_NPROC 打满） | `return error.ForkFailed` |
| `== 0` | **子进程** | 子进程逻辑 |
| `> 0` | **父进程**，返回值 = 子进程 PID | 父进程逻辑 |

**子进程用 `std.c._exit(42)` 而不是 `std.process.exit(42)`**——区别微妙但重要：
`_exit` 直接进内核，**不刷 stdio 缓冲**。fork 复制了父进程的整个地址空间，包括
stdout 缓冲区；子进程如果正常 `exit`，会把**父进程缓冲里还没写出去的字节**再刷一遍
——输出翻倍。`_exit` 绕过 atexit handler 和 stdio 刷新，是子进程退出的唯一正确方式。

**`waitpid` 的 status 不是 exit code**。`status` 是编码过的 `c_int`：
exit code 在**高 8 位**（`status >> 8`），低 8 位是信号信息。`std.posix.W.IFEXITED`
和 `std.posix.W.EXITSTATUS` 是解码宏：

```zig
const ustatus: u32 = @bitCast(status);  // c_int → u32（W 宏要无符号）
std.posix.W.IFEXITED(ustatus)           // 是否正常退出（不是被信号杀死）
std.posix.W.EXITSTATUS(ustatus)         // 提取 exit code（0-255）
```

### 测试：合成 status 验证解码

```zig
// examples/38_daemon/main.zig 第 249-264 行
test "W exit status 解码宏" {
    // 构造合成 status：exit code 42 → status = 42 << 8
    const status: u32 = 42 << 8;
    try std.testing.expect(std.posix.W.IFEXITED(status));
    try std.testing.expectEqual(@as(u8, 42), std.posix.W.EXITSTATUS(status));
    // ...
}
```

不 fork 也能测解码逻辑——`42 << 8` 就是"exit code 42"的 waitpid 编码。
这就是把逻辑抽成纯函数的好处。

---

## 38.3 僵尸进程与 SIGCHLD

### 僵尸：子进程死了，尸体还在进程表里

```zig
// examples/38_daemon/main.zig 第 137-158 行
begin("38.3 僵尸进程与 SIGCHLD");
const zpid = std.c.fork();
if (zpid == 0) {
    std.c._exit(0); // 子进程立即退出
}
try w.print("子进程 PID = {d} 已退出但尚未 wait\n", .{zpid});
try w.print("→ /proc 里会是 Z 状态（Linux）；macOS 用 `ps -o stat` 也能看到\n", .{});
// 给子进程一点时间变成僵尸
try std.Io.sleep(io, std.Io.Duration.fromMilliseconds(200), .awake);
// WNOHANG 轮询收割
var reap_status: c_int = 0;
var reap_count: usize = 0;
while (true) {
    const r = std.c.waitpid(zpid, &reap_status, std.posix.W.NOHANG);
    if (r == zpid) {
        reap_count += 1;
        break;
    }
    try std.Io.sleep(io, std.Io.Duration.fromMilliseconds(10), .awake);
}
try w.print("已收割（WNOHANG 轮询 {d} 次）\n", .{reap_count});
end("38.3");
```

时间线：

```
t=0     fork → 子进程 _exit(0) → 子进程消失，但进程表条目保留
t=0     父进程打印"已退出但尚未 wait" ← 此刻子进程已是僵尸（Z 状态）
t=200ms 父进程 waitpid(WNOHANG) → 收割成功，进程表条目清除
```

**`W.NOHANG` 的含义**：不阻塞。`waitpid(pid, &status, 0)` 会挂起父进程直到子进程
退出；`W.NOHANG` 让 `waitpid` 立即返回——子进程还没退就返回 0，退了返回子进程 PID。
事件循环里必须用 `WNOHANG`：阻塞的 `waitpid` 会卡住整个循环。

**生产模式**：`SIGCHLD` 信号的 handler 里 `while (waitpid(-1, &s, WNOHANG) > 0) {}`
循环收割——信号告诉你"有子进程变了状态"，WNOHANG 循环把到期的全收掉。POSIX 不
排队信号（同信号同时来只算一次），所以必须循环收割而不是只收一次。

---

## 38.4 fork + execve 执行命令

fork 复制地址空间只是手段，execve **替换**地址空间才是目的：

```zig
// examples/38_daemon/main.zig 第 161-175 行
begin("38.4 fork + execve 执行命令");
const epath: [*:0]const u8 = "/bin/echo";
const argv = [_:null]?[*:0]const u8{ epath, "hello", "from", "execve", null };
const envp = [_:null]?[*:0]const u8{ "PATH=/bin:/usr/bin", null };
const epid = std.c.fork();
if (epid == 0) {
    // 子进程：execve 替换镜像。成功则不返回，失败返回 -1
    _ = std.c.execve(epath, &argv, &envp);
    std.c._exit(127); // execve 失败才走到这里
}
var exec_status: c_int = 0;
_ = std.c.waitpid(epid, &exec_status, 0);
const uexec: u32 = @bitCast(exec_status);
try w.print("execve 完成, status={d}\n", .{std.posix.W.EXITSTATUS(uexec)});
end("38.4");
```

`execve` 的三个参数都是 C 风格：

- `path: [*:0]const u8`——哨兵终止的绝对路径
- `argv: [*:null]const ?[*:0]const u8`——指针数组，**最后一项必须 null**
- `envp: [*:null]const ?[*:0]const u8`——环境变量，同上

`[_:null]` 数组类型让编译器**自动在末尾补 null**——`argv.len == 4`（三个元素 + null
终止符），这是 0.17 里最安全的构造方式。测试验证了这一点：

```zig
// examples/38_daemon/main.zig 第 288-296 行
test "null 结尾 argv 构造" {
    const argv = [_:null]?[*:0]const u8{ "/bin/echo", "hello", null };
    try std.testing.expectEqual(@as(usize, 3), argv.len);
    try std.testing.expect(argv[2] == null);
    try std.testing.expectEqualStrings("/bin/echo", std.mem.span(argv[0].?));
}
```

**`execve` 成功不返回**——整个地址空间被 `/bin/echo` 替换，原来的代码不存在了。
失败（文件不存在 / 权限不足）返回 -1，此时**必须** `_exit(127)`：子进程不能
`return` 回 main——那是父进程的 main，逻辑全乱。127 是 POSIX 约定的"exec 失败"
退出码。

运行输出：

```text
hello from execve
execve 完成, status=0
```

`hello from execve` 是子进程（已是 `/bin/echo`）写的，直接继承父进程的 stdout fd。
`execve 完成` 是父进程在 `waitpid` 后写的。两行顺序确定：父进程等子进程结束后才打印。

---

## 38.5 守护进程化（daemonize）

### 完整 recipe

```zig
// examples/38_daemon/main.zig 第 39-63 行
/// 完整守护进程化五步法。编译期存在、运行期不调用——
/// 真调用了进程就从终端消失，演示就没法继续了。
fn daemonizeSteps() !void {
    // 第 1 步：第一次 fork，脱离 shell 的 job control
    const pid1 = std.c.fork();
    if (pid1 < 0) return error.ForkFailed;
    if (pid1 > 0) std.c._exit(0); // 父进程立即退出，子进程被 init 收养

    // 第 2 步：setsid()，成为新会话首进程，脱离控制终端
    if (std.c.setsid() < 0) return error.SetsidFailed;

    // 第 3 步：第二次 fork，确保不是会话首进程，无法再获得控制终端
    const pid2 = std.c.fork();
    if (pid2 < 0) return error.ForkFailed;
    if (pid2 > 0) std.c._exit(0);

    // 第 4 步：chdir("/")，避免占用可卸载的文件系统
    if (std.c.chdir("/") != 0) return error.ChdirFailed;

    // 第 5 步：把 /dev/null dup2 到 0/1/2，切断终端 I/O
    const devnull = std.c.open("/dev/null", .{ .ACCMODE = .RDWR });
    if (devnull < 0) return error.OpenDevNullFailed;
    _ = std.c.dup2(devnull, 0);
    _ = std.c.dup2(devnull, 1);
    _ = std.c.dup2(devnull, 2);
    if (devnull > 2) _ = std.c.close(devnull);
}
```

每一步解决一个具体问题：

| 步 | 调用 | 解决什么 |
|---|---|---|
| 1 | `fork` + 父 `_exit` | shell 的 job control 管不到孤儿进程；终端关闭时 SIGHUP 不会传到新会话 |
| 2 | `setsid` | 创建新会话，进程成为会话首进程，**脱离控制终端** |
| 3 | 再 `fork` + 父 `_exit` | **关键步**：setsid 后仍是会话首进程，System V 系统上 open 终端设备可能重新获得控制终端。再 fork 一次，孙进程**永远不是**会话首进程，免疫此问题 |
| 4 | `chdir("/")` | 守护进程 cwd 如果在 /mnt/usb 上，管理员 umount 会失败。chdir 到根目录解除占用 |
| 5 | `dup2 /dev/null` | 守护进程没有终端，stdout/stderr 写入会 EBADF 或更糟。重定向到 /dev/null 让 `print` 安全成为 no-op |

**生产环境还应补两步**（本章省略，书中有提及）：
- `umask(0)`：清文件创建掩码，守护进程创建的文件权限可预测
- pidfile：把 PID 写到 `/var/run/mydaemon.pid`，init 系统和管理员按名定位进程

---

## 38.6 信号安全规则总结

这一节是 38.1 的理论展开。运行输出就是教学内容：

```text
handler 里允许做的事（async-signal-safe）：
  ✓ lock-free 原子变量读写（std.atomic.Value）
  ✓ 写一段预分配的静态缓冲（不分配内存）
  ✓ 调用 async-signal-safe 的 C 函数（write、_exit 等）
handler 里禁止做的事：
  ✗ malloc / free（堆锁可能已被持有）
  ✗ print / format（内部可能 malloc）
  ✗ 拿 mutex / rwlock（非递归，可能死锁）
  ✗ 调非 async-signal-safe 的库函数
唯一正确模式（本章 handler 的写法）：
  fn handler(sig: c.SIG) callconv(.c) void {
      flag.store(true, .monotonic);  // 只写原子变量
  }
```

为什么 `mutex.lock` 会死锁？信号是**异步**的——它可以在任何线程的任何指令处触发。
如果信号打断了正持有 mutex 的线程，handler 里再 lock 同一把锁：非递归锁同一
线程二次加锁 = 死锁（该线程永远等自己释放）。`malloc` 同理：堆内部有全局锁。

**self-pipe trick**（书中提到，本章未实现）：在 handler 里 `write` 一个字节到
预先创建的 pipe，主循环用 `poll`/`select` 同时等 pipe 和其他 fd。这是"信号 + I/O
多路复用"场景的标准解法——比原子轮询更及时，但多两个 fd 的管理成本。原子标志
方案在"主循环本来就有 tick"的场景（如 zcron）更简单够用。

---

## 38.7 zcron 迷你调度器

### 纯函数 isDue

```zig
// examples/38_daemon/main.zig 第 69-78 行
const Job = struct {
    name: []const u8,
    interval_ms: i64,
    last_run_ms: i64,
};

/// 纯函数：判断某 job 是否到期。抽出来是为了可测试。
fn isDue(now_ms: i64, last_run_ms: i64, interval_ms: i64) bool {
    return now_ms - last_run_ms >= interval_ms;
}
```

`isDue` 不碰全局状态、不分配内存、不依赖时钟——输入输出完全由参数决定。
这意味着它可以被单测直接驱动（第 275-286 行有 5 个断言覆盖边界），也是
调度器唯一需要测的逻辑。

### 调度循环

```zig
// examples/38_daemon/main.zig 第 208-229 行
begin("38.7 zcron 迷你调度器");
var jobs: [3]Job = .{
    .{ .name = "backup", .interval_ms = 60, .last_run_ms = 0 },
    .{ .name = "cleanup", .interval_ms = 90, .last_run_ms = 0 },
    .{ .name = "heartbeat", .interval_ms = 30, .last_run_ms = 0 },
};
const tick_ms: i64 = 30;
var now_ms: i64 = 0;
var tick: usize = 0;
while (tick < 5) : (tick += 1) {
    now_ms += tick_ms;
    try w.print("tick {d} (t={d}ms):\n", .{ tick + 1, now_ms });
    for (&jobs) |*job| {
        if (isDue(now_ms, job.last_run_ms, job.interval_ms)) {
            try w.print("  运行 job {s}\n", .{job.name});
            job.last_run_ms = now_ms;
        }
    }
    try std.Io.sleep(io, std.Io.Duration.fromMilliseconds(30), .awake);
}
try w.print("5 tick 完成，调度器退出\n", .{});
end("38.7");
```

三个设计决定，每个都来自书里的生产经验：

1. **栈数组 `[3]Job` 不是 `ArrayList`**。调度器的执行路径上零分配——分配可能
   失败，失败时调度器正处于"该触发 backup 但没触发"的状态。固定容量 + 编译期
   已知 = 无失败路径。生产版上限 128 个 job，对个人服务绰绰有余。

2. **`now_ms` 手动累加而不是每次读时钟**。`std.Io.Timestamp.now` 每次调用是
   一次系统调用；tick 循环里手动 `+= tick_ms` 既省 syscall 又确定可测。
   代价是漂移（sleep 不保证精确 30ms）——对分钟级 cron 无所谓。

3. **`std.Io.sleep(io, duration, .awake)` 的 `.awake`**。单调时钟（monotonic），
   不受 NTP 校时或用户改系统时间影响。如果用 `.real`（wall clock），管理员
   把时钟拨回一小时，调度器就停摆一小时。

运行输出（确定性——间隔整除，无竞态）：

```text
tick 1 (t=30ms):
  运行 job heartbeat
tick 2 (t=60ms):
  运行 job backup
  运行 job heartbeat
tick 3 (t=90ms):
  运行 job cleanup
  运行 job heartbeat
tick 4 (t=120ms):
  运行 job backup
  运行 job heartbeat
tick 5 (t=150ms):
  运行 job heartbeat
5 tick 完成，调度器退出
```

heartbeat 每 tick 都跑（30ms 间隔 = tick 间隔），backup 每 2 tick（60ms），
cleanup 每 3 tick（90ms）。数学上确定，和 sleep 精度无关。

---

## 38.8 坑位清单

示例的 38.8 节打印了清单。这里逐条展开为什么。

### 1. `std.posix.waitpid` 在 0.17 不存在

```bash
$ grep -c waitpid /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/posix.zig
0
```

0.16 的 `std.posix.waitpid` 把 `ECHILD`（没有子进程可等）当 `unreachable`——
因为库作者认为"你调 waitpid 就一定有子进程"。但 SIGCHLD handler 里收割时
ECHILD 是**正常结束条件**（信号不排队，多个子进程同时退出只触发一次信号，
循环收割时最后一次必然 ECHILD）。0.17 的解法：整个函数移除，用 `std.c.waitpid`
拿原始返回值自己判。

### 2. handler 必须是 `callconv(.c) fn`，不能有 error union

内核用 C 调用约定调 handler。`fn handle(sig: SIG) !void` 编译器会拒绝
（error union 不是 C ABI），但 `fn handle(sig: SIG) void` 漏写 `callconv(.c)`
在 x86_64 上可能"碰巧能跑"（System V ABI 和 Zig 默认接近），在 ARM 或
Windows 上就是 UB。永远写 `callconv(.c)`。

### 3. `std.c.fork` 返回 `pid_t`（c_int），用 `== 0` 判子进程

不是 `?pid_t` 不是 `!pid_t`。C 的三态返回（负/零/正）原样保留。
`if (pid == 0)` 是子进程——这个反直觉的约定来自 1970s UNIX：
fork 的返回值设计让父子进程用同一段代码分流。

### 4. 原子序：handler 里 `.monotonic` 足够；主循环用 `.acquire`

`.monotonic` 只保证原子性（不撕裂），不保证顺序。handler 里除了 store 没别的事，
不需要顺序。主循环 `load(.acquire)` 需要看到 store **之前**的所有写入——
`.acquire` / `.release` 配对构成 happens-before。用 `.seq_cst` 也能对，但
是最强也是最贵的序——信号场景不需要。

### 5. `std.Io.sleep` 签名

```zig
std.Io.sleep(io, std.Io.Duration.fromMilliseconds(50), .awake)
//     时钟 ───────────────────────────────────────────────┘
```

第三个参数是时钟选择：`.awake`（单调）或 `.real`（wall clock）。
调度器永远用 `.awake`——wall clock 会被 NTP / 用户拨动。

### 6. `sigaction` 返回 `void`

0.17 的错误哲学：可预防的错误编译期拦，程序员错误 panic。传非法信号号给
`sigaction` 是程序员错误（EINVAL），不是运行时故障。所以返回 `void`——
你不会收到 `error.InvalidSignal`，你会在 Debug 下直接 panic 并带栈跟踪。

---

## 38.9 本章的验证方式

三层，与全项目一致：

```bash
cd examples/38_daemon
zig fmt --check .                                        # 第 1 层：格式 + 语法
zig test main.zig -lc                                    # 第 2 层：5 个 test
zig build-exe main.zig -lc -femit-bin=/tmp/38_daemon     # 第 3 层：main 也要能编
/tmp/38_daemon                                           # 第 3 层：真跑一遍
```

`-lc` 的原因：本章全部走 `std.c`（fork/execve/waitpid/setsid/dup2），需要链接 libc。

第 3 层不可省：`zig test` 不执行 `main`，而本章 8 个运行时小节全在 `main` 里。

跑完应看到（PID 每次不同，其余逐字节确定）：

```text
==== 38.1 信号处理基础 开始 ====
安装 SIGINT handler...
SIGINT handler 安装成功
handler 类型: fn (c.SIG__enum_10) callconv(.c) void
规则: handler 里只写原子变量，不 malloc / 不 print / 不拿锁
SIGINT 已捕获，优雅退出
==== 38.1 结束 ====

==== 38.2 fork 与 waitpid 开始 ====
  子进程: 我的 PID = 40104，即将 _exit(42)
父进程: 我的 PID = 40103，子进程 PID = 40104
waitpid 返回: W.IFEXITED = true，exit status = 42
==== 38.2 结束 ====
```

5 个测试覆盖：W 宏解码（合成 status）、原子 store/load、isDue 边界（恰好到期 /
interval=0 / 首次必到期）、null 结尾 argv 构造、daemonizeSteps 函数引用。

---

## 38.10 和书上的差异一览

| 书（0.15/0.16 写法） | 本章（0.17 实测） | 原因 |
|---|---|---|
| `c.signal(c.SIGINT, handler)` | `std.posix.sigaction(std.c.SIG.INT, &act, null)` | `signal(2)` 是过时接口；`sigaction` 可设 mask/flags，且 `std.c.SIG.INT` 是 0.17 的枚举名 |
| `std.posix.waitpid(...)` | `std.c.waitpid(...)` | 0.17 移除了 `std.posix.waitpid`（见坑位 1） |
| `std.time.sleep(...)` | `std.Io.sleep(io, Duration, .awake)` | `std.time.sleep` 已移除 |
| `std.process.exit(0)`（子进程） | `std.c._exit(0)` | fork 后子进程必须 `_exit` 防 stdio 双刷（38.2 详解） |
| 完整 zcron 项目（6 文件） | 迷你调度器（38.7，30 行） | 教学聚焦：调度逻辑（isDue + tick）是核心，REPL/配置解析是外围 |
