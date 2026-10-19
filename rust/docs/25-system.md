# 25 · 系统标准库：时间、环境、进程与网络

> 对应示例：`examples/25_system/`
>
> 前面 24 章把 Rust 的语言内核（所有权、trait、并发、async）讲透了。但一个真实的
> 系统程序还要和操作系统打交道：读时钟、查环境变量、启动子进程、收发网络包。
> 这四件事分别落在 std 的四个模块里——`time`、`env`、`process`、`net`。本章把它们
> 一次讲清，全部代码都在示例 `examples/25_system/src/main.rs` 里跑通并通过四层验证，
> 正文逐段引用讲解，你不需要自己翻源码。
>
> 这四个模块的共同点：**它们都是 Rust 对操作系统 syscall 的安全封装**。标准库把
> "会失败的操作"统一包成 `Result`，把"平台差异"（Windows 的 `\\` 与 Unix 的 `/`、
> 命令名、套接字 API）藏进统一接口背后。学完本章，你能写出真正跨平台的系统工具。

## 25.1 为什么把这四个模块放一起

`time`、`env`、`process`、`net` 看似不相关，其实是同一类东西：**程序与操作系统之间的边界**。

| 模块 | 对应的 OS 能力 | 典型场景 |
|---|---|---|
| `std::time` | 系统时钟、单调计数器 | 测耗时、打时间戳、超时控制 |
| `std::env` | 进程环境块、工作目录 | 读配置、解析命令行参数 |
| `std::process` | fork/exec（Unix）、CreateProcess（Windows） | 调用外部命令、跑子任务 |
| `std::net` | BSD socket API | TCP 服务器/客户端、UDP 收发 |

它们的 API 设计有一条统一哲学：**操作系统调用随时可能失败**（文件不存在、端口被占、子进程崩溃、时钟回拨），所以 std 一律返回 `Result` 或 `Option`，把"失败"变成值而不是异常（10 章的错误哲学在这里再次体现）。你在本章会反复看到 `?`、`.expect(...)`、`match ... Err`——这不是啰嗦，是 std 在强迫你正视"系统调用会失败"这个事实。

示例程序的结构很直白：`main()` 先检查自己是不是被当成子进程启动的（25.4 会解释这个技巧），否则依次跑四段演示：

```rust
fn main() {
    // 子进程入口：父进程用 --child 启动我们时，只打印标记就退出，不再跑演示。
    let args: Vec<String> = std::env::args().collect();
    if args.iter().any(|a| a == "--child") {
        child_mode();
        return;
    }

    println!("==== std::time ====");
    demo_time();
    println!("==== std::env ====");
    demo_env();
    println!("==== std::process ====");
    demo_process();
    println!("==== std::net ====");
    demo_net();
    println!("全部演示完成。");
}
```

下面四节分别拆开 `demo_time` / `demo_env` / `demo_process` / `demo_net`。

## 25.2 std::time：三种"时间"是三个不同的东西

新手最容易犯的错，是把"时间"当成一个概念。std 把它精确地拆成三个类型，各管一件事：

| 类型 | 是什么 | 会不会倒退 | 用途 |
|---|---|---|---|
| `Duration` | 一段**时长**（与时刻无关） | 不适用 | 表示"500 毫秒""3 天" |
| `Instant` | 一个**单调时刻**（某个未指定起点） | 永不倒退 | 测量耗时、超时判断 |
| `SystemTime` | 一个**墙上时刻**（相对 Unix 纪元） | 可能倒退（NTP 校时） | 打时间戳、记录"几点几分" |

### Instant：测耗时的唯一正确选择

`Instant` 是一个**单调递增**的时钟——它不告诉你"现在几点"，只保证"后取的时刻一定不早于先取的"。正因如此，它是测量"经过了多少时间"的唯一安全工具。示例里用它给一段计算计时：

```rust
let start = Instant::now();
let mut sum = 0u64;
for i in 0..100_000u64 {
    sum = std::hint::black_box(sum).wrapping_add(i);
}
let elapsed: Duration = start.elapsed();
let nanos = elapsed.as_nanos();
println!("计算 sum={sum} 耗时 {nanos} 纳秒");
assert!(elapsed < Duration::from_secs(10));
```

三个细节值得讲清：

1. **`Instant::now()` 取一个时间点，`.elapsed()` 返回从那一刻到现在的 `Duration`**。`elapsed()` 等价于 `Instant::now() - start`，但更直观。
2. **`std::hint::black_box` 不是装饰**。如果不加它，编译器会发现"这个循环的结果只用了 `sum`，而 `sum` 可以公式直接算"，于是把整个循环优化掉——你测到的就是 0 纳秒。`black_box` 告诉编译器"这个值我可能要，别动它"，强制循环真的执行。这是写基准测试（benchmark）的必备技巧。
3. **为什么不用 `SystemTime` 测耗时**？因为墙上时钟可能被 NTP（网络时间协议）回拨。假设你 `start = SystemTime::now()`，中途系统对时把时钟往回调了 2 秒，结束再取一次——你会算出**负的**耗时，或者一个离谱的值。`Instant` 单调，永远不会出现这种事故。**记住这条铁律：测耗时用 `Instant`，打时间戳才用 `SystemTime`。**

### Duration：与时刻无关的纯时长

`Duration` 表示"一段时间长度"，它不绑定任何时刻，所以可以随便做算术、拆分、比较：

```rust
let d = Duration::from_millis(1500);
let secs = d.as_secs();          // 1（整秒部分）
let subsec = d.subsec_nanos();   // 500_000_000（不足一秒的纳秒部分）
println!("1500ms = {secs} 秒 + {subsec} 纳秒");
assert_eq!((secs, subsec), (1, 500_000_000));
```

构造 `Duration` 有一组语义化的工厂方法，比裸写纳秒数可读得多：

```rust
Duration::from_secs(30)          // 30 秒
Duration::from_millis(1500)      // 1.5 秒
Duration::from_micros(500)       // 0.5 毫秒
Duration::from_nanos(42)         // 42 纳秒
Duration::from_secs_f64(2.5)     // 2.5 秒（浮点版，方便但注意精度）
```

读取时对称地有一组：`as_secs()`（整秒）、`as_millis()`（总毫秒，u128）、`subsec_nanos()`（秒以下部分）、`as_nanos()`（总纳秒，u128）。注意 `as_millis`/`as_nanos` 返回 `u128`——因为时长可以非常大（`Duration::MAX` 约 5.8 亿年），u64 纳秒只能表示约 584 年。示例的测试里验证了浮点构造与拆分：

```rust
#[test]
fn duration_splits_correctly() {
    let d = Duration::from_secs_f64(2.5);
    assert_eq!(d.as_secs(), 2);
    assert_eq!(d.subsec_millis(), 500);
}
```

`Duration` 还实现了 `Add`/`Sub`/`Mul`/`PartialOrd`，所以 `timeout * 2`、`a + b`、`if elapsed > limit` 都能直接写。22 章线程的 `sleep(Duration)`、23 章 async 的 `tokio::time::sleep`、以及网络超时，收的都是这个类型——它是 std 里"时间长度"的通用货币。

### SystemTime：墙上时钟与它的 Result

`SystemTime` 表示"现实世界的某个时刻"，内部存的是相对某个基准的偏移。最有用的基准是 `UNIX_EPOCH`（1970-01-01 00:00:00 UTC）：

```rust
let since_epoch = SystemTime::now()
    .duration_since(UNIX_EPOCH)
    .expect("系统时间早于 Unix 纪元");
let ts = since_epoch.as_secs();
println!("Unix 时间戳：{ts} 秒");
assert!(ts > 1_700_000_000); // 2023-11 之后，验证拿到的是真实时间
```

**为什么 `duration_since` 返回 `Result` 而不是直接给值**？因为 `SystemTime` 可能倒退。如果系统时钟被设到了 1970 年之前（或两次取值之间发生了回拨），`now` 可能**早于** `UNIX_EPOCH`，此时 `duration_since` 返回 `Err(SystemTimeError)`。std 不替你假设"时钟一定正确"，而是把这种边界情况如实暴露成 `Result`——这正是 25.1 说的"系统调用会失败"哲学的体现。实际中你几乎总是 `.expect(...)` 或 `?` 掉这个错误，因为系统时间早于 1970 年意味着机器本身已经坏掉了。

拿到 `Duration` 后，`as_secs()` 就是经典的 Unix 时间戳（秒数）。要毫秒就 `as_millis()`，要人类可读的"2026-10-19 15:30"则需要 `chrono` 或 `time` 这类第三方 crate——std 只管"距纪元多少秒"，不管日历格式化（这是刻意的最小化设计）。

## 25.3 std::env：进程与外界的第一条通道

`std::env` 模块封装了"进程环境"——命令行参数、环境变量、工作目录、临时目录。这些是程序启动时从操作系统继承的上下文。

### 命令行参数：args() 是个迭代器

```rust
let args: Vec<String> = std::env::args().collect();
let argc = args.len();
println!("命令行参数个数：{argc}");
```

`std::env::args()` 返回一个迭代器，产出 `String`。**第 0 个元素永远是程序自身的路径**（与 C 的 `argv[0]` 一致），所以 `argc` 至少是 1。示例直接运行时输出"命令行参数个数：1"。

两个要点：

1. **`args()` 遇到非法 Unicode 参数会 panic**。如果参数可能含非 UTF-8 字节（Unix 上文件名可以是任意字节），用 `args_os()`，它产出 `OsString`（不强制 UTF-8）。日常场景 `args()` 够用。
2. **手动解析参数很快会失控**。示例只有一个 `--child` 标志，用 `args.iter().any(...)` 就够；但真实 CLI 工具（子命令、短/长选项、值参数）应该用 `clap` crate 的 derive 宏——24 章 minigrep 手写了最简解析，正是为了让你体会"为什么需要 clap"。

### 环境变量：var() 为什么返回 Result

```rust
match std::env::var("PATH") {
    Ok(path) => {
        let len = path.len();
        println!("PATH 长度：{len} 字节");
    }
    Err(e) => println!("读 PATH 失败：{e}"),
}
```

`std::env::var("PATH")` 返回 `Result<String, VarError>`。它可能因两种原因失败，对应 `VarError` 的两个变体：

- `VarError::NotPresent`——变量不存在；
- `VarError::NotUnicode(OsString)`——变量存在，但内容不是合法 Unicode，无法转成 `String`。

第二种在 Windows 上尤其相关：环境变量是 UTF-16 的，可能含无法转成 UTF-8 的孤立代理项。std 不替你猜，而是返回 `Result`。如果你不在乎 Unicode 合法性，用 `var_os()` 拿 `OsString`。

查一个**不存在**的变量是再正常不过的逻辑分支，不是错误：

```rust
let missing = std::env::var("GUIDE_DEFINITELY_NOT_SET");
assert!(missing.is_err());
println!("不存在的变量：{:?}", missing.unwrap_err());  // 打印 NotPresent
```

这行输出 `NotPresent`——它演示了"查不到"是一个干净的 `Err` 值，你可以 `match`、可以用 `unwrap_or`、可以用 `?` 往上传，绝不会崩溃。测试里也固化了这个行为：

```rust
#[test]
fn env_missing_var_is_err() {
    assert!(std::env::var("GUIDE_DEFINITELY_NOT_SET").is_err());
}
```

写环境变量用 `env::set_var` / `remove_var`——但注意它们在多线程下是 **unsafe**（2024 edition 起，因为修改全局环境块与并发读取存在数据竞争）。单线程程序里随便用。

### 目录：temp_dir 与 current_dir

```rust
println!("临时目录：{}", std::env::temp_dir().display());
println!("当前目录：{}", std::env::current_dir().unwrap().display());
```

- `temp_dir()` 返回系统临时目录（Windows `%TEMP%`、macOS `/var/folders/...`、Linux `/tmp`）。**这是跨平台写临时文件的唯一正确方式**——本教程所有示例（20 章、24 章）都用它做沙箱，绝不硬编码 `/tmp`，否则 Windows 上直接失效。
- `current_dir()` 返回进程的当前工作目录，是 `Result`（进程可能没有可读的工作目录，比如某些守护进程）。

两者都返回 `PathBuf`（20 章讲过：`PathBuf` 是路径版的 `String`）。`.display()` 是打印路径的安全方式——它返回一个"即使路径含非法 Unicode 也能打印"的包装器，直接 `println!("{}", path)` 在畸形路径上会 panic。

## 25.4 std::process：启动并控制子进程

`std::process` 让你从 Rust 程序里启动别的程序。核心类型是 `Command`（构建一条命令行）和 `Output`（子进程结束后的全部结果）。

### 跨平台的陷阱：别用 echo

新手写"启动子进程"的示例，第一反应是 `Command::new("echo").arg("hi")`。**这在 Windows 上会失败**——`echo` 在 Windows 是 cmd.exe 的内建命令，不是独立的可执行文件，`Command::new` 找不到它。同理 `ls`、`cat`、`grep` 都是 Unix 专有。

示例用了一个完全跨平台的技巧：**启动程序自己**，靠一个标志位区分"父进程模式"和"子进程模式"：

```rust
fn demo_process() {
    // 跨平台启动子进程最稳妥的方式：启动"自己"，用标志位区分父子。
    // 不依赖 echo/ls 这类命令名——Windows 上 echo 是 shell 内建而非可执行文件，
    // Command::new("echo") 在 Windows 会直接失败。current_exe 则三平台一致。
    let exe = std::env::current_exe().expect("拿不到当前可执行文件路径");
    let output = std::process::Command::new(exe)
        .arg("--child")
        .output() // output() 等待子进程结束并一次性收回 stdout/stderr/status
        .expect("启动子进程失败");

    assert!(output.status.success(), "子进程应成功退出");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("child-stdout-marker"));
    let trimmed = stdout.trim();
    let code = output.status.code(); // Option<i32>：被信号杀死时是 None
    println!("子进程 stdout={trimmed:?}，退出码={code:?}");
}
```

而 `main()` 开头那段就是子进程模式的处理——当它发现自己带着 `--child` 被启动，就只打印一行标记然后退出：

```rust
fn child_mode() {
    println!("child-stdout-marker");
}
```

父进程捕获到这行 `child-stdout-marker`，就证明了"子进程确实启动并执行到了业务代码"。这个自举技巧在写跨平台测试时非常有用。

### Command 的三种执行方式

`Command` 是个 builder，配好后有三种"发射"方式，对应三种需求：

| 方法 | 行为 | 返回 | 何时用 |
|---|---|---|---|
| `.status()` | 等子进程结束，**不捕获**输出（直接继承父进程的 stdout/stderr） | `io::Result<ExitStatus>` | 只想让子命令的输出直接显示给用户 |
| `.output()` | 等子进程结束，**捕获** stdout/stderr 到内存 | `io::Result<Output>` | 需要程序化处理子进程的输出（示例用的就是这个） |
| `.spawn()` | **不等**，立即返回一个运行中的子进程句柄 | `io::Result<Child>` | 需要边跑边交互、或并行启动多个 |

`.output()` 返回的 `Output` 结构体有三个字段：`status`（退出状态）、`stdout`（`Vec<u8>`）、`stderr`（`Vec<u8>`）。注意 stdout/stderr 是**字节**不是字符串——子进程可能输出任意字节，要转成文本得自己 `String::from_utf8_lossy`（非法字节替换成 U+FFFD，不 panic）或 `from_utf8`（严格校验，返回 Result）。

### 退出码：ExitStatus 与 Option<i32>

```rust
let code = output.status.code(); // Option<i32>
```

`status.code()` 返回 `Option<i32>` 而不是 `i32`——**因为进程可能不是"正常退出"的**。在 Unix 上，进程可能被信号杀死（比如 SIGKILL、SIGSEGV），这种情况下没有"退出码"可言，`code()` 返回 `None`。`status.success()` 则是个方便的布尔判断（退出码为 0 即成功）。要拿到信号信息，得用 `std::os::unix::process::ExitStatusExt` 的 `signal()` 方法（平台特定 API，19 章 FFI 那套 `std::os` 分层）。

### spawn 与 Child：流式交互

`.spawn()` 返回 `Child`，它有三个公开字段 `stdin`/`stdout`/`stderr`（都是 `Option<ChildStdout>` 这类，取决于你是否在 Command 里配了 `Stdio::piped()`）。这让你能"边跑边喂数据、边读输出"，而不是等它全部结束。`Child` 还实现了 `Drop`——但**默认不杀进程也不等待**，子进程会变成"孤儿"继续跑。要确保回收，显式调 `child.wait()`（等待结束）或 `child.kill()`（强杀）。这个"不自动 join"的设计与 22 章线程的 `JoinHandle` 形成对比：线程 detach 是常见需求，子进程 detach 也常见（启动守护进程），所以 std 都不强制回收。

## 25.5 std::net：TCP 与 UDP

`std::net` 提供同步（阻塞）的网络原语。它是 23 章 async 网络的"地基"——tokio 的异步套接字本质上是把这里的阻塞 API 包进非阻塞 IO + 事件循环。理解 std::net 的阻塞模型，才理解 async 网络在解决什么问题。

### TCP：面向连接的字节流

TCP（传输控制协议）提供**可靠、有序、面向连接**的字节流。通信前要先"连接"，之后数据像水流一样双向传输，保证不丢、不乱序、不重复。示例实现了一个最小的回显服务器（echo server）——客户端发什么，服务器原样返回：

```rust
fn demo_net() {
    // ---- TCP：面向连接的字节流 ----
    // 绑端口 0 让操作系统分配一个空闲端口，避免与别的进程撞端口（测试可靠性的关键）。
    let listener = TcpListener::bind("127.0.0.1:0").expect("绑定 TCP 失败");
    let addr = listener.local_addr().unwrap();

    // 服务器放进独立线程：accept 是阻塞的，不能和客户端在同一线程顺序跑。
    let server = std::thread::spawn(move || {
        let (mut stream, _peer) = listener.accept().expect("accept 失败");
        let mut buf = [0u8; 5];
        stream.read_exact(&mut buf).expect("服务器读失败");
        stream.write_all(&buf).expect("服务器写失败"); // 原样回显
    });

    let mut client = TcpStream::connect(addr).expect("连接失败");
    client.write_all(b"hello").expect("客户端写失败");
    let mut echo = [0u8; 5];
    client.read_exact(&mut echo).expect("客户端读失败");
    server.join().expect("服务器线程 panic");

    assert_eq!(echo, *b"hello");
    println!("TCP 回显：{:?}", String::from_utf8_lossy(&echo));
    // ...（UDP 部分见下）
}
```

逐行讲清这段代码里的每个设计决策：

**1. 为什么绑 `127.0.0.1:0`（端口 0）？**
`127.0.0.1` 是回环地址（localhost），数据不出网卡，只在本机进程间流动——测试网络代码的标准做法。端口写 `0` 是一个特殊约定：**让操作系统自动分配一个当前空闲的端口**。如果硬编码 `127.0.0.1:8080`，而 8080 恰好被别的程序占了，`bind` 就会失败，测试变得不可靠。绑 0 之后，用 `listener.local_addr()` 反查操作系统实际分配的端口，再让客户端连过去。这是写可重复网络测试的关键技巧。

**2. 为什么服务器要放进独立线程？**
`listener.accept()` 是**阻塞**的——它会一直等到有客户端连进来才返回。如果服务器和客户端在同一线程顺序执行，`accept()` 会永远等下去（因为客户端代码还没跑到），程序死锁。把服务器丢进 `thread::spawn`（22 章），让它阻塞等待，主线程同时去当客户端连接，两者并行推进。`move` 闭包把 `listener` 的所有权移进线程（22 章的 move 规则）。

**3. `accept()` 返回什么？**
它返回 `(TcpStream, SocketAddr)`——一个是已建立的连接（用来收发数据），一个是对端的地址。示例用 `_peer` 忽略地址。注意 `TcpListener`（监听器，负责"接客"）和 `TcpStream`（连接，负责"通话"）是两个不同的类型，职责分离。

**4. `read_exact` 与 `write_all` 来自哪里？**
它们不是 `TcpStream` 的固有方法，而是 `std::io::Read` 和 `std::io::Write` 两个 trait 提供的（示例顶部 `use std::io::{Read, Write};`）。`TcpStream`、`File`、`UdpSocket`、甚至 `Vec<u8>` 都实现了这两个 trait——**这是 Rust IO 的统一抽象**：任何"能读字节的东西"都实现 `Read`，任何"能写字节的东西"都实现 `Write`。所以同一套 `read_exact`/`write_all` 能用在文件、网络、内存缓冲上（20 章文件 IO 用的也是这两个 trait）。

- `write_all(&buf)`：把整个缓冲写出去，内部循环处理"部分写入"（TCP 可能一次发不完）。
- `read_exact(&mut buf)`：读满整个 `buf` 才返回，内部循环处理"部分读取"。如果连接中途断开、读不满，返回 `Err`。

**5. 为什么 `assert_eq!(echo, *b"hello")`？**
`echo` 是 `[u8; 5]`，`b"hello"` 是 `&[u8; 5]`，`*b"hello"` 解引用成 `[u8; 5]` 值，两者按值比较。断言通过就证明"客户端收到的回显 == 发出去的内容"，TCP 往返成功。

### UDP：无连接的数据报

UDP（用户数据报协议）与 TCP 相反：**无连接、不保证送达、不保证顺序、保留消息边界**。每次 `send` 是一个独立的"数据报"（datagram），不会和别的粘在一起。代价是不可靠，收益是开销小、延迟低——适合 DNS 查询、视频流、游戏状态同步、心跳这类"丢一两个包无所谓，但要快"的场景。

```rust
    // ---- UDP：无连接数据报，两个 socket 互发 ----
    let a = UdpSocket::bind("127.0.0.1:0").expect("绑定 UDP a 失败");
    let b = UdpSocket::bind("127.0.0.1:0").expect("绑定 UDP b 失败");
    // connect 对 UDP 只是"记住默认对端地址"，不建立连接；之后 send/recv 都走这个对端。
    a.connect(b.local_addr().unwrap()).expect("connect a 失败");
    b.connect(a.local_addr().unwrap()).expect("connect b 失败");
    a.send(b"ping").expect("UDP 发送失败");
    let mut buf = [0u8; 4];
    let n = b.recv(&mut buf).expect("UDP 接收失败");
    assert_eq!(n, 4);
    assert_eq!(buf, *b"ping");
    println!("UDP 收发：{:?}", String::from_utf8_lossy(&buf[..n]));
```

几个与 TCP 的关键区别：

**1. 没有 listen/accept。** UDP 无连接，不需要"监听—接受"握手。两个 socket 各自 `bind` 到一个地址就能直接互发。

**2. `connect` 在 UDP 里是"假连接"。** 它不发送任何握手包，只是把对端地址记在 socket 里，这样后续 `send`/`recv` 不用再每次指定地址（也带来一个好处：内核会帮你过滤掉非对端来的包）。要发给任意地址，用 `send_to(&buf, addr)` / `recv_from(&mut buf)`（后者返回发送方地址）。

**3. `recv` 返回实际收到的字节数 `n`。** UDP 保留消息边界——你 `send` 4 个字节，对端 `recv` 就收到 4 个字节（`n == 4`），不会多也不会少（缓冲不够大会被截断，但本例缓冲正好 4 字节）。这与 TCP 的"字节流"本质不同：TCP 里你分两次 `write` 各 2 字节，对端可能一次 `read` 到 4 字节粘在一起，需要自己定协议拆包。

### std::net 与 async 的关系

std::net 是**阻塞**的：`accept`、`read`、`connect` 都会卡住当前线程直到 IO 完成。这意味着"一个连接一个线程"的模型——连接数上千时，线程开销（每个线程 MB 级栈）就撑不住了。23 章的 async 网络（tokio）正是为解决这个问题：把阻塞 IO 换成"非阻塞 IO + 事件循环"，单线程就能扛上万连接。但底层的数据流模型、`Read`/`Write` 的语义、TCP/UDP 的区别，与本章完全一致——**std::net 是 async 网络的概念地基**。先用本章的阻塞版理解清楚"连接、字节流、数据报"，再去看 23 章的 `.await` 版会顺畅得多。

## 25.6 坑位清单

1. **测耗时用 `Instant`，绝不用 `SystemTime`**：墙上时钟会被 NTP 回拨，导致负耗时或离谱值。`Instant` 单调递增，是测量"经过了多久"的唯一安全选择。
2. **基准测试忘了 `black_box`，测到 0 纳秒**：编译器会把"结果没被真正使用"的循环整个优化掉。用 `std::hint::black_box` 挡住优化，或确保结果被打印/断言。
3. **`SystemTime::duration_since` 返回 `Result` 不是 bug**：时钟可能早于纪元（回拨/错误配置），std 如实暴露。实际中 `.expect()` 掉即可，但要理解它为什么是 Result。
4. **`env::var` 的两种失败**：`NotPresent`（不存在）和 `NotUnicode`（存在但非法 Unicode）。不在乎 Unicode 用 `var_os`；查不到是正常分支，别当异常处理。
5. **`Command::new("echo")` 在 Windows 失败**：`echo`/`ls`/`cat`/`grep` 是 Unix 专有或 shell 内建。跨平台示例启动"自己"（`current_exe()` + 标志位），或明确区分平台。
6. **`status.code()` 是 `Option<i32>`**：进程被信号杀死时没有退出码，返回 `None`。判断成功用 `status.success()`，别直接 `unwrap()` code。
7. **`Child` 默认不回收**：`spawn` 的子进程在 `Child` drop 后变孤儿继续跑。要等待用 `child.wait()`，要终止用 `child.kill()`——与线程 `JoinHandle` 的 detach 语义类似，std 都不强制 join。
8. **网络测试硬编码端口会偶发失败**：端口被占就 `bind` 失败。一律绑 `127.0.0.1:0` 让 OS 分配空闲端口，再用 `local_addr()` 反查——这是可重复网络测试的铁律。
9. **阻塞 `accept`/`read` 不能和客户端同线程顺序跑**：会死锁。服务器逻辑放进 `thread::spawn`（本章）或 async 任务（23 章）。
10. **TCP 是字节流，没有消息边界**：两次 `write` 可能被对端一次 `read` 收到。要分消息得自己定协议（长度前缀、分隔符）。UDP 才有天然的数据报边界。
11. **`read_exact` 读不满会 `Err`，`read` 读到多少算多少**：要"读满 N 字节"用 `read_exact`；要"有多少读多少"用 `read`（返回实际字节数）。混淆两者是网络/文件 IO 的常见 bug。
12. **打印路径用 `.display()`**：`println!("{}", path)` 在含非法 Unicode 的路径上会 panic，`path.display()` 永远安全。

---

上一章：[24 实战：迷你 grep](24-minigrep.md)
