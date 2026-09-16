# 02 · 第一个程序

> 对应示例：`examples/02_hello/`

## 2.1 std.debug.print：最省事的输出

```zig
const std = @import("std");

pub fn main() !void {
    std.debug.print("你好，Zig 0.16！\n", .{});
    std.debug.print("编号 {d:0>3}，十六进制 {x}，二进制 {b}\n", .{ 7, 255, 10 });
}
```

`@import("std")` 引入标准库（`@` 开头的都是编译器内建，第 13 章细讲）。`std.debug.print` 写 **stderr**、无缓冲立即落地、线程安全——开发期打印用它最省心，不用管什么 flush。

格式串是**编译期检查**的：占位符数量和类型跟实参对不上，编译就过不了（C 的 printf 只能靠运气）。常用占位符：

| 占位符 | 含义 | 例 |
|---|---|---|
| `{d}` | 十进制数字（整数/浮点） | `7` |
| `{s}` | 字符串/字节切片（**必须**，见坑位） | `zig` |
| `{}` | 默认格式（bool 打 true/false） | `true` |
| `{x}` `{o}` `{b}` | 十六/八/二进制 | `ff` |
| `{d:.2}` | 浮点保留 2 位 | `3.14` |
| `{d:0>3}` | 宽度 3 右对齐补零 | `007` |
| `{any}` | 任意类型（数组/切片/指针只能用它） | `{ 1, 2 }` |

## 2.2 stdout 的正确姿势：缓冲 Writer + flush

```zig
var buf: [256]u8 = undefined;
var w = std.Io.File.stdout().writer(init.io, &buf);
const out = &w.interface;
try out.print("姓名：{s}，年龄：{d}\n", .{ "阿 Z", 25 });
try out.flush();
```

0.15/0.16 重构后的标准姿势，四个动作：`stdout()` 拿文件 → `writer(io, &buf)` 挂上**你提供的**缓冲 → `.interface` 拿到通用 Writer → 用完 `flush()`。缓冲区所有权归调用者是这次重构的核心：**缓冲从哪来、何时落盘，全在你眼前**——代价是忘了 flush 会丢尾部输出（新手第一大坑）。

对比 cpp20 的 `std::print`：那边缓冲藏在库里；Zig 认为"隐式缓冲"也是一种隐藏行为。`std.debug.print` 不经过这套（stderr 直写），所以调试期尽量用它。

## 2.3 `std.process.Init`：main 的标准参数包

0.16 起支持（并推荐）给 main 一个 `init` 参数，一揽子拿齐运行环境：

```zig
pub fn main(init: std.process.Init) !void {
    // init.io            Io 接口：所有 std.Io 操作的入场券
    // init.gpa           通用分配器（Debug 模式带泄漏检测）
    // init.arena         进程级 arena（进程退出自动回收）
    // init.minimal.args  命令行参数（Windows 原生是 UTF-16，22 章讲怎么用）
    // init.environ_map   环境变量 map
}
```

**main 仍然可以零参数**——`pub fn main() void` 一路合法，本章示例两种都见。需要 IO/参数/分配器时才接 `init`；教程从 19 章起基本都接。旧式 `std.io.getStdOut()` 已随重构消失，别再找了。

## 2.4 编译与运行：三条命令

```bash
zig run main.zig            # 编译 + 立即运行：改代码→看结果最快路径
zig build-exe main.zig      # 产 main.exe（Windows 旁生 main.pdb 调试信息）
zig test main.zig           # 跑 test 块（2.6 节）
```

构建模式（默认 Debug）：

| 模式 | 优化 | 安全检查（溢出/越界/未定义读） | 用途 |
|---|---|---|---|
| `Debug`（默认） | 无 | **全开** + 错误返回跟踪 | 开发 |
| `ReleaseSafe` | 有 | 全开 | 发布但求稳 |
| `ReleaseFast` | 有 | 全关（UB 是 UB） | 发布求性能 |
| `ReleaseSmall` | 有（压体积） | 全关 | 嵌入式/体积敏感 |

切换：`zig build-exe main.zig -O ReleaseFast`（`zig run` 同样接受）。**开发期永远 Debug**——安全检查是 Zig 送的免费测试。

## 2.5 test 块初见

```zig
test "打印不是测试重点，先验证格式化语义" {
    const name = "阿 Z";
    try std.testing.expectEqualStrings("阿 Z", name);
}
```

`test "描述" { ... }` 是语言内建的测试语法——没有测试框架要装、没有构建脚本要配，`zig test main.zig` 直接跑。断言失败会打出自带错误跟踪的对比输出。第 15 章系统讲（包括泄漏检测这种杀手锏），这里先混个脸熟：**本教程每个示例都带 test 块**，build.ps1 的验证就靠它。

## 2.6 zig fmt：格式即规范

```bash
zig fmt main.zig          # 原地格式化
zig fmt --check main.zig  # 只检查不改（CI 用，退出码非 0 = 有文件不合格）
```

Zig 没有 gofmt 式的"圣战"——官方格式化器就是唯一格式。本仓库 build.ps1 用 `--check` 把关每个示例。写完顺手 `zig fmt .`，永远不在这件事上花脑细胞。

## 2.7 坑位清单

1. **忘 flush 丢输出**：stdout 走缓冲 Writer，进程退出前不 flush，缓冲里的尾部内容可能丢失。调试打印改用 `std.debug.print`（stderr 无缓冲）绕开整个问题。
2. **切片/数组不能用 `{d}`**：0.16 格式化收紧，`print("{d}", .{some_slice})` 直接编译错——用 `{any}`（`{s}` 只给字符串）。
3. **源文件 UTF-8 无 BOM**：Windows 记事本"带 BOM 的 UTF-8"会让 zig 拒绝编译。
4. **`zig run` 传参用 `--` 分隔**：`zig run main.zig -- these are args`。
5. **exe 旁的 .pdb 别提交**：`zig build-exe` 产物含调试数据库，`.gitignore` 应忽略（本仓库已配 `**/build/`）。
6. **`std.debug.print` 打的中文进的是 stderr**：重定向 stdout 时看不到它，`2>&1` 合并才能见。

---
