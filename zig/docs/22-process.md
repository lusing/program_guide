# 22 · 进程与系统编程

> 对应示例：`examples/22_process/`
>
> argv、环境变量、子进程、时间——和操作系统打交道的日常。

## 22.1 argv：跨平台迭代器

```zig
pub fn main(init: std.process.Init) !void {
    var it = try std.process.Args.Iterator.initAllocator(init.minimal.args, mem);
    defer it.deinit();                    // 迭代器有内部缓冲（Windows 要转码）
    var argc: usize = 0;
    while (it.next()) |arg| {             // ?[:0]const u8，null 即尽
        std.debug.print("  argv[{d}] = {s}\n", .{ argc, arg });
        argc += 1;
    }
}
```

0.16 的真相：**Windows 的命令行原生是 UTF-16**，`init.minimal.args` 在 Windows 上是 `[]const u16`——直接用会拿到 UTF-16。`Args.Iterator` 抹平平台（Windows 侧转成 UTF-8 再给你），`initAllocator` 要分配器（转码缓冲）、用完 `deinit`。跳参数不取值用 `it.skip()`。旧 API `std.process.argsAlloc(alloc)` 已让位给这套。

## 22.2 环境变量

```zig
if (init.environ_map.get("USERNAME") orelse init.environ_map.get("USER")) |user| { ... }
```

`Init.environ_map` 是**启动时解析好的 map**（`*Environ.Map`）——`get` 即查，不用自己分配。没接 Init 时 `std.process.getEnvMap(alloc)` 现场解析。Windows 环境变量名不区分大小写（查询时注意）。

## 22.3 子进程：process.run

```zig
const res = try std.process.run(mem, io, .{
    .argv = &.{ "cmd", "/c", "echo", "hello from child" },
});
std.debug.print("子进程 stdout：{s}", .{res.stdout});
// res.term    结束方式（退出码/信号）
// res.stderr  错误输出（也收进来了）
```

0.16 的 `run(gpa, io, options)` 是"跑完收输出"的一步式——**argv 是字符串切片数组，不是 shell 命令行**（要管道/通配符自己拼 `cmd /c`）。选项还有 `cwd`、`environ_map`、`timeout`。要流式交互（往子进程 stdin 写、边跑边读 stdout）用 `std.process.spawn(io, options)` 拿 `*Child` 手动管（kill/wait 也带 io）。

## 22.4 当前目录与路径

```zig
var pbuf: [std.fs.max_path_bytes]u8 = undefined;
const cwd_len = try std.process.currentPath(io, &pbuf);   // 写进你的缓冲，返回长度
std.debug.print("{s}\n", .{pbuf[0..cwd_len]});
```

`currentPath(io, buf)` 零分配版（缓冲你出）；`currentPathAlloc(io, alloc)` 便利版。路径处理回 20.6 的 `std.fs.path`。

## 22.5 时间：Io.Clock 与 Timestamp

0.16 把 `std.time` 的计时函数全部收编进 Io（`std.time` 只剩常量如 `ns_per_ms` 和日历换算）：

```zig
const t0 = std.Io.Timestamp.now(io, .awake);          // 单调钟（系统休眠不计时）
try (std.Io.Clock.Duration{
    .raw = std.Io.Duration.fromMilliseconds(2),       // 时长
    .clock = .awake,
}).sleep(io);                                          // 0.16 的 sleep
const t1 = std.Io.Timestamp.now(io, .awake);
t0.durationTo(t1).nanoseconds                         // 差值（i96 纳秒）

std.Io.Timestamp.now(io, .real).nanoseconds           // 墙钟（Unix 纪元纳秒）
```

| Clock | 语义 | 用途 |
|---|---|---|
| `.real` | 墙钟（会跳） | 显示时间、日志时间戳 |
| `.awake` | 单调（休眠不走） | **测耗时**（默认选择） |
| `.boot` | 开机起（休眠也走） | 埋点 |

**测耗时永远用单调钟**——墙钟被 NTP 调整会测出负数。Duration 的两套构造（`Io.Duration.fromMilliseconds` 纯时长 / `Clock.Duration{.raw, .clock}` 挂钟的时长）容易看花——睡 2ms 按 22.5 的样板抄。

## 22.6 main 的退出码

```zig
pub fn main() !void { ... }
// 正常返回 → 退出码 0；错误冒泡到顶 → 退出码 1（stderr 带错误返回跟踪）
```

要自定义退出码：`pub fn main() u8 { ...; return 3; }`。CI/脚本按退出码判生死——build.ps1 的"运行 exit 0"检查靠的就是它。

## 22.7 坑位清单

1. **Windows 的 args 是 UTF-16**：直接遍历 `init.minimal.args` 拿到 `[]const u16`——**必须走 `Args.Iterator`**；`it.next()` 返回的才是 UTF-8。
2. **迭代器忘 deinit**：Windows 侧有转码分配——泄漏虽小，testing.allocator 会抓。
3. **`Child.run` 已不是 0.16 写法**：现在是 `std.process.run(gpa, io, .{...})`；旧代码的 `Child.run(.{...})` 编译不过。
4. **sleep 的正确路径是 `Clock.Duration.sleep`**：`Io.Duration` 上没有 sleep（它只是裸时长）——差一层 `.clock` 字段，编译错信息不会告诉你答案（实测踩满）。
5. **测耗时用 `.awake`/`.monotonic` 系**：`.real` 受校时影响——负耗时、跳变耗时的来源。
6. **`cmd /c` 才有 shell 语义**：`run` 的 argv 不经 shell——`echo`、`dir` 这类内建命令要套 `cmd /c`（Windows）或 `sh -c`（POSIX）。

---
