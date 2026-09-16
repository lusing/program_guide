# Zig 0.16 速查表

语法速查 + 0.16 坑位索引。详细讲解见对应章（表中 N.M = 第 N 章 M 节）。

## 1. 命令速查

```bash
zig run main.zig -- args     # 编译+运行（-- 后是程序参数）
zig build-exe main.zig       # 产 exe（Debug 默认；-O ReleaseFast 换模式）
zig build-lib lib.zig        # 产库（wasm/动态库；无入口场景）
zig test main.zig [-lc]      # 跑 test 块（-lc：链接 libc）
zig build [run|test] [-- a]  # build.zig 工程
zig fmt . [--check]          # 格式化 / 只检查
zig cc / zig c++             # 当 C/C++ 编译器（交叉白送）
zig translate-c header.h     # C 头 → Zig 绑定
zig fetch --save <url>       # 拉依赖进 zon
zig targets                  # 合法 -target 列表
zig init                     # 工程骨架
```

## 2. 类型与转型（03）

```zig
const x: u32 = 42;           // const 优先；var 不改会编译错
const b: u3 = 5;             // 任意位宽（0..7）
a + b                        // 安全加（Debug 溢出 panic）
a +%= b                      // 环绕加
@as(T, x)                    // 类型协调
@intCast / @truncate(无符号!) / @bitCast(同宽)
@floatFromInt / @intFromFloat / @enumFromInt / @intFromEnum
```

| 坑 | 解法 |
|---|---|
| comptime 已知越界的 @intCast | **编译错**——换宽类型或 @truncate（03.6） |
| @truncate 报 "expected unsigned" | 先 @intCast 到无符号（03.6） |
| `{d}` 打数组/切片 | 用 `{any}`（02.2） |

## 3. 控制流（04）

```zig
const v = if (c) a else b;              // if 是表达式
while (i < n) : (i += 1) { }            // continue 表达式
for (arr, 0..) |x, i| { }               // zip + 下标
for (0..5) |k| { }                      // 范围
break :label / continue :label          // 标签
switch (x) { 1, 2 => .., 3...9 => .., else => .. }   // 穷尽；范围三个点
sw: switch (st) { continue :sw .next, ... }          // 状态机
```

## 4. 解包与错误（09/10）

```zig
if (opt) |v| {} else {}          // 可选捕获
opt orelse 默认值                 // 可选默认
opt.?                            // 断言非 null（null 即 panic）
const v = try f();               // 错误上抛
const v = f() catch 0;           // 就地消化
if (f()) |v| {} else |err| {}    // 值/错误二选一
defer  cleanup();                // 无条件清理
errdefer rollback();             // 失败才回滚
```

| 坑 | 解法 |
|---|---|
| `?!T` 编译不过 | 写 `?E!T`（显式错误集）（10.3） |
| catch 直接作用 `?E!T` | 先 orelse 剥 null 再 catch（10.3） |

## 5. 分配器（11）

```zig
var da = std.heap.DebugAllocator(.{}){};   // 开发默认（泄漏检测）
var ar = std.heap.ArenaAllocator.init(backing);  // 批量一把收
var fba = std.heap.FixedBufferAllocator.init(&buf);  // 定容缓冲
std.heap.page_allocator / std.heap.smp_allocator
const s = try a.alloc(u32, n);  defer a.free(s);
const p = try a.create(T);      defer a.destroy(p);
const c = try a.dupe(u8, src);  defer a.free(c);
// 惯用法：分配 → errdefer free → 初始化 → 返回
```

## 6. 集合（12）

```zig
var l: std.ArrayList(T) = .empty;  defer l.deinit(a);   // unmanaged
try l.append(a, v);  l.items;  l.pop()  // pop 返回 ?T！
try l.toOwnedSlice(a);                  // 所有权转出
var m = std.AutoHashMap(K,V).init(a);   defer m.deinit();  // managed！
try m.put(k, v);  m.get(k)  // ?V；getOrPut / remove / fetchRemove
std.mem.sort(T, slice, ctx, lessThanFn);
```

## 7. comptime 与泛型（13/14）

```zig
const fib10 = fibonacci(10);             // const 即编译期
fn f(comptime T: type, v: T) {}          // comptime 参数
const t = blk: { @setEvalBranchQuota(n); ...; break :blk val; };  // 编译期块
inline for (tuple) |x| {}                // 无索引捕获！
fn Container(comptime T: type) type { return struct { const Self = @This(); ... }; }
@typeInfo(T).@"struct".fields            // 反射（须 switch）
@field(v, "name")                        // 按名存取（编译期名字）
```

| 坑 | 解法 |
|---|---|
| 顶层 const 写 comptime | redundant 编译错——去掉（13.3） |
| 编译期循环配额爆 | @setEvalBranchQuota 加大（13.4） |

## 8. 构建与包（16）

```bash
zig build run -- args       # run/test 步骤；-- 透传
zig build -Doptimize=ReleaseFast -Dtarget=aarch64-linux
# zon：.name 不能数字开头；.fingerprint 新包先写 0x0 再抄编译器提示值
# 路径依赖：.dependencies = .{ .x = .{ .path = "../x" } }
# 接线：b.dependency("x", .{}) → x.module("x") → imports 挂载（三层缺一不可）
```

## 9. 0.13 → 0.16 迁移坑位索引（按遇错频率排）

| 旧写法 | 0.16 写法 | 章 |
|---|---|---|
| `ArrayList(T).init(alloc)` | `var l: ArrayList(T) = .empty;` 方法传 alloc | 12 |
| `std.io.getStdOut()` / `std.fs.File` | `std.Io.File.stdout().writer(io, &buf)` + flush | 02 |
| `std.fs.cwd()` / fs.Dir | `std.Io.Dir.cwd()`，方法带 io | 20 |
| `makePath` | `createDirPath(io, path)` | 20 |
| `BoundedArray` | 已移除：数组 + len | 12 |
| `Thread.WaitGroup` / `Thread.sleep` | 已移除：join / `Clock.Duration.sleep(io)` | 19/22 |
| `std.Thread.Mutex = .{}` | `std.Io.Mutex = .init`，lock 带 io | 19 |
| `std.time.nanoTimestamp()` | `std.Io.Timestamp.now(io, .awake)` | 22 |
| `Child.run(.{})` | `std.process.run(gpa, io, .{})` | 22 |
| `argsAlloc(alloc)` | `Args.Iterator.initAllocator(init.minimal.args, a)` | 22 |
| `c"..."` 字面量 | 已移除：普通字面量即 0 结尾 | 17 |
| `--no-entry`（wasm） | 已移除：`zig build-lib` | 18 |
| `zig build-wasm` | 从来没有过：`build-exe -target wasm32-...` | 18 |
| `std.fmt.print` | 不存在：`std.debug.print` 或 Writer | 02 |
| `expectNull` | 已移除：`expect(opt == null)` | 15 |
| asm `%[r]` 之外的 `{[r]}` | 模板占位就是 `%[r]` | 21 |

## 10. 格式化占位符（02）

| 占位 | 用途 |
|---|---|
| `{d}` `{d:.2}` `{d:0>3}` | 数字/精度/补零 |
| `{s}` | 字符串（必须） |
| `{x}` `{b}` | 十六/二进制 |
| `{any}` | 数组/切片/指针/任意 |
| `{}` | 默认（bool → true/false） |
