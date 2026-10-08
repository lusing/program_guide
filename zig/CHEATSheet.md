# Zig 0.17 速查表

语法速查 + 坑位索引。详细讲解见对应章（表中 N.M = 第 N 章 M 节）。
>⚠️ **按 0.17.0 整理**。0.17 移除/改名了一批语法与 API（`**`、`void{}`、`@cImport`、
>`@intFromEnum`、`b.args`、`std.meta` 等），从 0.16 迁移先看
>[00 · 0.16 → 0.17 迁移手册](docs/00-migration-0.17.md)。

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
@intCast / @truncate(无符号!) / @bitCast(同宽，不接受裸结构体)
@floatFromInt / @intFromFloat
@backingInt(枚举→整数) / @fromBackingInt(@intCast(n))  // 0.17 改名，fmt 会自动改
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
@typeInfo(T).@"struct".field_names/.field_types  // 0.17：三条平行数组，不再有 fields
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

## 9. 0.13 → 0.17 迁移坑位索引（按遇错频率排）

| 旧写法 | 0.17 写法 | 章 |
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
| `callconv(.win64)` | `callconv(.winapi)`（自动选架构变体） | 28/29 |
| `std.Thread.Mutex/Condition/RwLock` | 全并入 `std.Io.*`，方法带 io | 31 |
| `windows.BOOL == 0` | BOOL 是枚举：比较 `.FALSE` | 28 |
| `DoublyLinkedList.pushFront` | `prepend` / `pop`（队尾）/ `popFirst` | 34 |
| `extern "sqlite3" fn ...` | 去库名 + DLL 路径当对象传给 zig | 32 |
| **`a ** b`（运算符）** | **已移除**：用 `@splat` 或 comptime 函数；`++` 拼接仍在 | 06 |
| `const b = void{}` | `const b: void = {};` | 05 |
| `@cImport` / `@cInclude` | **已移除**：`build.zig` 的 `b.addTranslateC` + `tc.createModule()` | 17 |
| `callconv(.C)` | `callconv(.c)`（小写） | 17 |
| `b.args` | `run_cmd.addPassthruArgs()` | 16/17 |
| `@intFromEnum` / `@enumFromInt` / `@intToEnum` | `@backingInt` / `@fromBackingInt(@intCast(n))` / `@enumFromInt` | 03/08 |
| `builtin.mode == .Debug` | `.debug`（`.ReleaseSafe` → `.safe`） | 02 |
| `std.meta.fields(T)` | `@typeInfo(T).@"struct".field_names` | 14/25/32 |
| `@typeInfo(E).error_set.?.names` | `.error_set.error_names`（元素是字符串，非结构体） | 09 |
| `std.heap.stackFallback(a, &buf)` | `BufferFirstAllocator.init(&buf, a).allocator()` | 11 |
| `@bitCast(结构体)` | `std.mem.asBytes` + `readInt(…, .little)` | 21/25 |

## 10. 格式化占位符（02）

| 占位 | 用途 |
|---|---|
| `{d}` `{d:.2}` `{d:0>3}` | 数字/精度/补零 |
| `{s}` | 字符串（必须） |
| `{x}` `{b}` | 十六/二进制 |
| `{any}` | 数组/切片/指针/任意 |
| `{}` | 默认（bool → true/false） |

## 11. 平台差异速记（Windows ↔ Linux/macOS）

示例代码全部双平台可跑（`builtin.os.tag` 分支）；差异在工具链与系统行为：

| 差异点 | Windows | Linux/macOS | 章 |
|---|---|---|---|
| 产物 | `main.exe` + 旁生 `main.pdb` | `main`（无后缀，调试信息内嵌） | 02/23 |
| 中文控制台 | 先 `chcp 65001` | 原生 UTF-8 无此问题 | 01 |
| 原生 argv | UTF-16，必须走 `Args.Iterator` | UTF-8，迭代器同样能用 | 22 |
| 子进程要 shell | `cmd /c` | `sh -c` | 22 |
| 环境变量用户名 | `USERNAME` | `USER`（示例两者都试） | 22 |
| `std.posix.getenv` | 不可用（用 `init.environ_map`） | 可用（但 Init 写法双平台一致） | 23 |
| 路径分隔符 | `\`（`std.fs.path` 抹平） | `/` | 20 |
| 内联汇编 | x86_64 分支（`rdtsc`） | aarch64 分支（`mrs %[v], cntvct_el0`），Apple Silicon 直接可跑 | 21 |
| panic 栈帧尾 | `... in main (xx.obj)` / DLL 名 | `0x... in main (main)`，末帧 `/usr/lib/dyld` | 23 |
| 全量验证 | `build.ps1`（pwsh） | `./run-all.sh`（bash，`ZIG=` 可指定）；macOS 跑 ps1 版要 `pwsh -NoProfile -Command '& ./build.ps1 -All'` | — |
| 合并重定向 `> f 2>&1` | 正常 | Zig 侧会覆盖 stderr 前部（0.16 实测），分开重定向 | 02 |

## 12. 25–37 章新增速查（书本扩充篇）

```zig
// 二进制（25）
std.mem.readInt(u32, bytes, .little)        // 任意偏移解包（不要求对齐）
std.mem.bytesToValue(Record, &raw)          // 整体 view（extern struct + align 关）
const board: u16 = @bitCast(packed_val);    // packed struct(u16) ↔ 背板整数
@typeInfo(T).@"struct".field_types          // comptime 遍历字段（wire 尺寸断言/行映射）

// 编码与流（26）
std.fmt.bytesToHex(data, .upper) / hexToBytes(&out, &hex)
std.base64.standard.Encoder.calcSize(n) + .encode(dst, src)
r.interface.fillMore() + buffered() + toss()  // 0.17：readSliceShort 是「填满或EOF」语义，不能当 recv
const v: @Vector(32, u8) = slice[0..32].*;  // SIMD：比较→位掩码→@popCount

// 文件系统（27/28）
statFile(io, p, .{ .follow_symlinks = false })  // lstat 语义
std.Io.sleep(io, Duration.fromMilliseconds(200), .awake)
extern "kernel32" ReadDirectoryChangesW      // Windows 目录监视（手写声明）

// 网络（29/30）——Windows 上 std.Io.net TCP 数据面 0.16.0 实测坏（AFD）：
std.Io.net.IpAddress.parseIp4("127.0.0.1", port)
.listen(io, .{}) / .connect(io, .{ .mode = .stream }) / .bind(io, .{ .mode = .dgram })
sock.receive(io, &buf) → IncomingMessage{ .from, .data }   // UDP 可用（实测）
extern "ws2_32" socket/bind/accept/connect/send/recv       // TCP 逃生门（需 WSAStartup）

// 并发（31）
std.atomic.Value(u64).init / fetchAdd / cmpxchgWeak(cur, want, .seq_cst, .seq_cst)
Io.RwLock.lockSharedUncancelable(io) / unlockShared(io)
Io.Condition.waitUncancelable(io, &mutex)   // 持锁判断 + while 重判
哨兵 job 关停线程池；放哨兵后先解锁再 join（持锁 join = 自锁）

// SQLite（32）——zig build-exe main.zig C:\Windows\System32\winsqlite3.dll
sqlite3_open_v2(":memory:", ...) / prepare_v2 / bind_text(TRANSIENT) / step(ROW=100,DONE=101)
column_text 的借用窗口：下一次 step 前有效，出循环前 dupe

// 解释器（33）与 LRU（34）
Pratt：bindingPower 每算符一对 (left,right)——右结合 caret 是 left>right
@fieldParentPtr("link", node)               // 侵入式链表节点反查宿主

// ZLS（35）：Zig 0.17.0 无官方配对版——master 源码 zig build -Doptimize=ReleaseSafe
// zls.json: enable_build_on_save + build_on_save_args=["check"]（build_on_save_step 已删）
// build.zig check 步骤：addExecutable 不 installArtifact → 0.17 自动 -fno-emit-bin

// 指针深水区（36）
p[i]                                            // [*]T 只能下标；(p+i).* 0.17 编译错误
@ptrFromInt(addr)                               // 安全模式当场查对齐（panic 在转换行）
@ptrCast(@alignCast(p))                         // 重解释内存；@bitCast(x) 重解释值（同宽/可 comptime）
std.StringHashMap(void)                         // = Set；零尺寸类型地址全是 0x1
*align(1:0:1) u3                                // packed 字段位对齐指针（字节对齐:位偏移:宿主宽）

// FileGuard（37）：双索引 StringHashMap(Metadata) + AutoHashMap(i64, []const u8)
//   inode==0 哨兵不进索引；求差两遍扫描，inode 反查认 moved
std.crypto.hash.sha2.Sha256.init/update/final   // 一次性 hash(data, &out, .{}) 是三参
init.minimal.args.iterateAllocator(a)           // Windows 上 iterate() 编译错误；切片随 deinit 悬空→dupe
```

### 25–37 实测坑位（按疼度排）

| 坑 | 解 | 章 |
|---|---|---|
| 迭代器 `entry.name` 跨 `next()` 失效 | 内部缓冲复用，必须 `dupe` | 27/34 |
| 返回栈上缓冲切片 | 函数返回栈帧死，`dupe` 进调用方 | 30 |
| `std.Thread.Mutex/Condition/WaitGroup/Pool` 全部已移除 | 同步原语搬到 `std.Io.*`；`std.Thread` 只剩 `spawn/join/detach/yield` | 19/31/34 |
| `Io.Condition.wait` 在 `std.testing.io` 上死锁 | 编排测试放 `main(init.io)`，test 只测原子/纯函数 | 31/15 |
| `Future.await` 返回 `Result` 本身（不是 `!Result`） | 写 `try f.await(io)` 编译失败 | 31 |
| `Io.Clock` 没有 `.monotonic` | 成员是 `real/awake/boot/cpu_process/cpu_thread` | 22/31/32 |
| `Io.Duration` 有 `format` 无 `formatNumber` | `{d}` 失败，用 `{f}` | 22/31 |
| 环绕加 `+%` 不满足结合律 | 并行归约必须用 XOR；Debug 不报错但结果差 6 个数量级 | 31 |
| `std.io` 时代 doctest | 0.17 无此功能：`zig test` 不编译文档示例，写显式 test 块 | 15/33 |
| packed struct 字段取地址 | 字段不按字节对齐：整个背板 `@bitCast` 出来再取 | 25 |
| asm clobber 从字符串列表变成类型化结构体 | 写 `.{ .cc = true, .memory = true }`；**按架构分**（aarch64 只有 `.nzcv`） | 21 |
| x86 单字母寄存器类全废 | `"=a" "=b" "=c" "=d"` 报 `couldn't allocate output register`；用 `"=r"` | 21 |
| aarch64 内联汇编是 Intel 语序 | 不是 AT&T：`add %[a], %[o]` 报 `too few operands` | 21 |
| Zig 的 `"m"` 不是 C 的内存操作数 | 指向"装着值的临时栈槽"，读到值副本；编译测试都过、只有数值错 | 21 |
| x86_64 macOS 裸 `syscall` 吃 SIGSYS | 退出码 140；必须借 libc（`zig cc` 编的 C 同样 140） | 21 |
| Windows 用户态没有 `syscall` 通道 | 裸 `syscall` 直接非法指令异常；win32 API 就是 ntdll 网关，走 `std.os.windows.GetCurrentProcessId()` | 21 |
| Windows 下 `std.c.getpid()` 编译错 | 0.17 把它的返回类型映射成 `pid_t = windows.HANDLE`（`*anyopaque`），`@intCast` 报 `expected integer or vector` | 21 |
| `-lc` 下 `extern "system"` 找不到 `system.lib` | 报 `DllImportLibraryNotFound`；win32 API 用 `std.os.windows` 现成声明 | 21 |
| 两操作数指令 + 独立 `"=x"` 输出 = 垃圾值 | `addsd` 就地覆盖 dst（AT&T 末位）；Zig 无 `"0"` 匹配约束，输出/输入共用**显式寄存器**（`={xmm0}`/`{xmm0}`）；错法在 macOS 撞对、Windows 算出 0 | 21 |
| `undeclared identifier` 是 AstGen 层错 | 未选中的 comptime 分支也逃不过全模块标识符解析；平台分叉引用的辅助函数必须真实定义 | 24 |
| `std.posix.AT.FDCWD` 只在 POSIX 存在 | Windows 编译错 `no member named 'FDCWD'`；且 `Dir.handle` 是 `*anyopaque`，`{d}` 打不了 | 20/24 |
| `@cImport` 已移除，单文件场景手写 `extern "c"` | `b.addTranslateC` 走不了（无 build.zig）；`callconv(.C)` → `.c` | 17/32 |
| `extern fn` 参数里不许出现切片 | `[:0]const u8` 报 `slices have no guaranteed in-memory representation` | 32 |
| `sqlite3_source_id` 在 macOS 共享缓存里没导出 | 照抄头文件会 `undefined symbol`；删掉这行声明 | 32 |
| 变量名不能叫 `void`/`error` | `name shadows primitive`；C 侧类型加 `Raw` 前缀 | 32/33 |
| `.()` unwrap 语法已移除 | `stmt.()` 报错；一律 `.?` | 32 |
| `bufPrintZ` → `bufPrintSentinel(buf,fmt,args,0)` | 哨兵是 comptime 形参；`dupeZ` → `dupeSentinel(u8,src,0)` | 32 |
| `@typeInfo(T).@"union".tag` 不存在 | 新名 `tag_type`（`?type`，须 `.?`） | 33 |
| 结合性判据与「左严右松」相反 | `left < right` 才是左结合 | 33 |
| `++` 不能拼接运行期切片 | `slice being concatenated must be comptime-known` | 33 |
| `std.DoublyLinkedList` 变成非泛型侵入式 | `std.DoublyLinkedList(T)` 报 `type 'type' not a function`；塞 `Node` + `@fieldParentPtr` | 34 |
| 它还没有 `init()/iterator()/fetchNode()/insert()` | `@hasDecl` 全 `false`；`first` 是**字段**不是方法 | 34 |
| `StringHashMap` 没有 `putOwned`/`getOrPutOwned` | `@hasDecl` = `false`；唯一写法是**先 `dupe` 再 `put`** | 34 |
| `insertBefore/insertAfter` 不检查「已相邻」 | 重复插相邻节点写出 `a.prev = a` 自环，遍历永不终止 | 34 |
| `DebugAllocator.deinit()` 返回 `heap.Check` 枚举 | 不是 `void` 也不是字节数；对比 `testing.allocator` 的 `usize` | 34 |
| `std.time.Timer` 整个类型不存在 | `std.time` 只剩 `ns_per_ms` 除数常量；计时归 `std.Io.Clock` | 34 |
| `GeneralPurposeAllocator` → `DebugAllocator` | `@hasDecl` 实测 `false`；`.{}` 与 `.init` 都行 | 34 |
| 切片赋值 `s = v` 已移除 | 但**数组** `var s: [8]u8` 仍可整体赋值；只有切片不行 | 34 |
| `"x" ** 1900` 报「空格不对称」 | 报错完全看不出真相（`**` 被词法拆成两个 `*`）；改 `@memset` | 21/34 |
| `Reader.fixed` 是单参数 | 旧双参写法报 `expected 1 argument(s), found 2` | 34 |
| `takeDelimiterExclusive` 不消费分隔符（std bug） | 它只 `toss(result.len)` 而 result 不含分隔符 → 第二次起永远返回空片；改 `takeDelimiter`（返回 `?[]u8`）或手工 `fillMore`+`indexOfScalarPos`+`toss` | 29/30/33/34 |
| `stream.reader(io,&self.rbuf)` 在 init 里绑定 | 值拷贝后悬垂；改懒绑定（收发前 ensureBound） | 29/30/34 |
| `Stream.close` 不幂等 | 显式 close 后再 `defer close` → BADF panic；要全 defer 或全显式 | 34 |
| `Server.accept` 要`*Server` | 传给 `Thread.spawn` 的参数写 `&srv`，形参也改指针 | 29 |
| `Stream.read(io, [][]u8)` | **0.17.0 标准库自身 bug**（Io/net.zig:1286）；改走 reader/writer | 29/30 |

