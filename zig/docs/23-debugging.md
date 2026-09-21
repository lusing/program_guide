# 23 · 调试与工具链收尾

> 对应示例：`examples/23_debug/`
>
> 三层排错观：**编译错（comptime）→ panic（运行期断言）→ 错误跟踪（error 传播）**——Zig 把大部分 bug 往前推。

## 23.1 assert 与构建模式

```zig
fn risky(x: u32) u32 {
    std.debug.assert(x != 0);    // Debug/ReleaseSafe：不满足即 panic
    return 100 / x;              // ReleaseFast：assert 整个消失（编译掉）
}
```

`std.debug.assert` 在 Debug/ReleaseSafe 是活的地雷，ReleaseFast/Small 被编译器删除——**它断的是"逻辑不可能"，不是错误处理**（错误用 `!T`，10 章）。`builtin.mode` 编译期可查（示例打印当前模式）。

## 23.2 panic 栈跟踪：实测长这样

示例用环境变量当开关（`ZIG_PANIC=1` 才触发，正常验证路径不崩）。实测输出：

```text
thread 7632 panic: 演示 panic：看栈跟踪（正文贴真实输出）
G:\code\guide\zig\examples\23_debug\main.zig:26:9: ... in main (23_debug_zcu.obj)
        @panic("演示 panic：看栈跟踪（正文贴真实输出）");
        ^
G:\scoop\apps\zig\0.16.0\lib\std\start.zig:737: ... in callMain
...
???:?:?: 0x... in ??? (KERNEL32.DLL)
```

> 上图是 Windows 实测；Linux/macOS 下栈跟踪格式相同，但路径是本机路径、帧尾没有 `.obj`/DLL 名（如 `... in main`），调试信息内嵌在 ELF/Mach-O 里而非单独的 pdb。

panic = 不可恢复的程序错误（`.?` 解 null、@intCast 越界、越界索引、除零……全是它）——**消息 + 完整栈跟踪**直接打到 stderr，连 ReleaseFast 都带（panic 路径不追求零成本）。调试信息默认就位：`zig build-exe` 产的 pdb 与 exe 同目录，栈里的行号是现成的。

## 23.3 错误返回跟踪 vs panic 栈

错误冒泡到 main（`ZIG_ERT=1` 触发）：

```text
error: DemoErrorReturnTrace
G:\code\guide\zig\examples\23_debug\main.zig:32:9: ... in main
```

区别：**panic 栈**是"崩在哪"（调用栈）；**错误返回跟踪**是"这个错从哪来"（try 传播链，10 章）。两个都只在 Debug/ReleaseSafe 记录，Release 下零成本消失。排错顺序：错误跟踪找源头 → 必要时在源头下断点/加 panic。

## 23.4 断点与诊断工具箱

```zig
if (init.environ_map.get("ZIG_BREAK") != null) {
    @breakpoint();    // 生成调试断点指令（x86 的 int3）
}
```

`@breakpoint()` 在调试器里停下、没调试器就崩——配环境变量开关，"构建不变、行为变"（比改代码重编译优雅）。`@compileLog(x)`（13 章）打 comptime 值；`std.debug.dumpCurrentStackTrace()` 运行期手动打栈。

## 23.5 LLDB 速查

```bash
zig build-exe main.zig        # Debug 默认带调试信息
lldb ./main.exe               # Linux/macOS 产物无 .exe 后缀：lldb ./main

(lldb) break set -n main      # 断点
(lldb) run                    # 运行
(lldb) next / step            # 单步（不进/进函数）
(lldb) print x                # 打变量
(lldb) bt                     # 栈回溯
(lldb) frame variable         # 当前帧全部变量
(lldb) continue / quit
```

Zig 的调试信息是标准 DWARF/pdb，LLDB（或 Windows 上配 VS 调试器）开箱即用。`std.debug.print` 打点 + 错误跟踪解决 90% 问题，调试器留给剩下的 10%。

## 23.6 微基准

```zig
var sink: u64 = 0;                                   // 防优化：结果要被"用掉"
const t0 = std.Io.Timestamp.now(io, .awake);
for (0..1_000_000) |i| sink +%= @intCast(i % 7);
const t1 = std.Io.Timestamp.now(io, .awake);
std.debug.print("百万次循环 {d} ns\n", .{t0.durationTo(t1).nanoseconds});
```

单调钟掐表（22.5 的 `.awake`）。两个纪律：**结果进 sink**（否则 ReleaseFast 直接把循环删了），**对比同模式构建**（Debug 的数字没有参考价值）。本机实测百万次循环约 2ms（Debug）——ReleaseFast 下通常快一个数量级，读者可自测。

## 23.7 工具链速查（收尾）

```bash
zig fmt .                  # 格式化（--check 检查）
zig ast-check main.zig     # 只查语法不编译（编辑器集成用）
zig test main.zig          # 测试（15 章）
zig targets                # 目标列表（18 章）
zig translate-c h.h        # C 头转 Zig（17 章）
zig doc src/main.zig       # 生成 HTML 文档（/// 注释）
```

`///` 是文档注释（进 doc），`//!` 是文件头注释，`//` 普通注释——三件套写规范，`zig doc` 就有料。

## 23.8 坑位清单

1. **ReleaseFast 下 assert 消失**：Debug 测得好好的、发布版裸奔——assert 只断"逻辑不可能"，真可能发生的用错误处理。
2. **`@breakpoint()` 无调试器 = 崩溃**：它是真断点指令，不是可捕获错误——配环境变量开关（23.4 模式）。
3. **栈跟踪没行号**：确认不是 `-O ReleaseFast` + strip 产物；Debug 默认全有。
4. **Debug 的性能数字没意义**：安全检查全开，测性能必须 ReleaseFast（还要 sink 防删循环）。
5. **环境变量开关法**在 0.16 Windows 上走 `init.environ_map`——`std.posix.getenv` 在 Windows 不可用（示例实测，不是猜测）。

---
