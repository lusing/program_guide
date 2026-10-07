# 11 · 分配器 ⭐

> 对应示例：`examples/11_allocators/main.zig`
>
> 本章是全书的核心章之一。Zig 最与众不同的设计不是语法，而是**内存策略是显式参数**：
> 你调用的每一个"申请内存"的函数，都要求你先回答"从哪儿申请"。读完你应该能自己回答：
> 为什么 `std.heap.stackFallback` 在 0.17 里编译不过、它的继任者是谁；为什么
> `std.mem.Allocator` 只有 16 字节却能代表六种完全不同的内存策略；以及为什么
> `dupeZ` 这个从 0.13 就存在的函数在 0.17 里消失了。

本章所有代码在 **Zig 0.17.0 / x86_64-macos** 上实测通过（`./run-all.sh 11_allocators`
三层验证）。凡带 ⚠️ 的地方都是 0.17 相对老教程的**实测差异**。

---

## 11.1 为什么 Zig 要"显式分配器"

C 的 `malloc` 是个全局函数，内存从"那个堆"来。这意味着：测试时没法换一块假堆（于是
OOM 路径永远测不到）、嵌入式根本没有堆（于是你得自己造）、多线程要靠全局锁串行化
（于是你只能祈祷）。C++ 的 `new` 藏在表达式里，分配行为完全看不见。Rust 允许换全局
分配器，但 API 层面你还是"隐式拿内存"——`Vec::new()` 不会问你从哪儿拿。

Zig 的答案：**分配器是个普通的接口值，谁需要内存，谁就得把它传进去。**

```zig
// examples/11_allocators/main.zig 第 69-75 行
fn enchantedSword(allocator: std.mem.Allocator, src: []const u8) ![]u8 {
    const copy = try allocator.alloc(u8, src.len);
    errdefer allocator.free(copy);
    @memcpy(copy, src);
    return copy;
}
```

这一行代码在任何环境下都能编译：调用方传 `std.heap.page_allocator` 就是真的堆，传
arena 就是批量回收，传 FixedBuffer 就是无堆环境。**函数本身一行都不用改。** 收益直接
落在工程上：测试时注入会失败的分配器来走错误路径（11.10 节）、解析器挂 arena 一把回收
（11.8 节）、嵌入式给一块静态缓冲当堆（11.7 节）、性能热路径换无锁分配器（11.5 节）——
同一段代码，五种内存策略。

### `std.mem.Allocator` 到底是什么

```zig
// examples/11_allocators/main.zig 第 147-171 行（begin("11.1") 到 end("11.1")）
begin("11.1");
{
    // std.mem.Allocator 就是一个胖指针：ctx 指针 + vtable 指针，各 8 字节 = 16 字节。
    // vtable 是 4 个函数指针 = 32 字节（静态数据，不随实例走）。
    std.debug.print("Allocator 接口值 = {d} 字节（ptr {d} + vtable {d}）\n", .{
        @sizeOf(std.mem.Allocator),
        @sizeOf(*anyopaque),
        @sizeOf(std.mem.Allocator.VTable),
    });
    std.debug.print("vtable 槽位 = alloc / resize / remap / free，一共 {d} 个\n", .{
        @typeInfo(std.mem.Allocator.VTable).@"struct".field_names.len,
    });
    std.debug.print("类型名 = {s}；这是**普通结构体**，不是接口类型、不需要继承\n", .{@typeName(std.mem.Allocator)});
    std.debug.print("指针字段 = {s}，vtable 字段 = {s}\n", .{
        @typeName(@typeInfo(std.mem.Allocator).@"struct".field_types[0]),
        @typeName(@typeInfo(std.mem.Allocator).@"struct".field_types[1]),
    });
    std.debug.print("本页编译模式 builtin.mode = {s}（0.17 是小写 .debug，0.16 及更早是 .Debug）\n", .{@tagName(builtin.mode)});
    std.debug.print("run-all.sh 走的是 zig run/build-exe 默认模式 = {s}\n", .{@tagName(builtin.mode)});
    std.debug.print("而 `zig build -Doptimize=ReleaseFast` 才是 {s}，那时 init.gpa 会换成 smp_allocator\n", .{"ReleaseFast"});
    std.debug.print("顺带：undefined 在 0.17 被填 0x00（不是老教程写的 0xaa）——见 3.1 节\n", .{});
    const probe_undef: u8 = undefined;
    std.debug.print("  实测 const u8 = undefined 读出来是 0x{x:0>2}\n", .{probe_undef});
}
end("11.1");
```

运行输出（`examples/11_allocators/main.zig`）：

```text
==== 11.1 开始 ====
Allocator 接口值 = 16 字节（ptr 8 + vtable 32）
vtable 槽位 = alloc / resize / remap / free，一共 4 个
类型名 = mem.Allocator；这是**普通结构体**，不是接口类型、不需要继承
指针字段 = *anyopaque，vtable 字段 = *const mem.Allocator.VTable
本页编译模式 builtin.mode = debug（0.17 是小写 .debug，0.16 及更早是 .Debug）
run-all.sh 走的是 zig run/build-exe 默认模式 = debug
而 `zig build -Doptimize=ReleaseFast` 才是 ReleaseFast，那时 init.gpa 会换成 smp_allocator
顺带：undefined 在 0.17 被填 0x00（不是老教程写的 0xaa）——见 3.1 节
  实测 const u8 = undefined 读出来是 0x00
==== 11.1 结束 ====
```

**① 16 字节，而且真的是"胖指针"**。`ptr` 是 `*anyopaque`（指向分配器自己的状态），`vtable`
是 `*const VTable`（指向一张函数指针表）。两个 8 字节指针加起来 16 字节——**接口值可以直接
按值传递、拷贝、存进结构体**，一点都不重。这解释了本章贯穿始终的签名纪律：`fn f(alloc:
std.mem.Allocator)` **按值传**就对了，不要套 `*`。

**② 它不是"接口类型"，是一个普通 struct**。Zig 没有 Java 那种 `interface`——不需要继承、
不需要虚方法表。`Allocator` 就是一个有两个指针字段的结构体，谁想当分配器，谁就填一个
`.ptr`（自己）+ `.vtable`（一张四个函数指针的表）。11.2 节就手写一个。

**③ ⚠️ `builtin.mode` 在 0.17 是小写 `.debug`**，不是老教程写的 `.Debug`。这是 0.17 的
全局改名（`std.builtin.Mode` 的枚举成员全部小写了）。写 `builtin.mode == .Debug` 会报
`error: expected enum value, found 'Debug'`。

## 11.2 vtable 的四个槽位，以及手写一个分配器

vtable 上只有**四个**函数指针，没有第五个。实测它们的完整签名：

```zig
// examples/11_allocators/main.zig 第 174-209 行（begin("11.2") 到 end("11.2")）节选
begin("11.2");
{
    std.debug.print("VTable 字段：", .{});
    inline for (@typeInfo(std.mem.Allocator.VTable).@"struct".field_names) |fname| {
        std.debug.print("{s} ", .{fname[0..fname.len]});
    }
    std.debug.print("\n", .{});
    inline for (@typeInfo(std.mem.Allocator.VTable).@"struct".field_types) |ftype| {
        std.debug.print("  槽位类型 = {s}\n", .{@typeName(ftype)});
    }
    std.debug.print("官方 no-op 实现：noAlloc / noResize / noRemap / noFree（不想支持就填它们）\n", .{});
    // ...（后面是 CountingAllocator 的记账演示）
}
end("11.2");
```

```text
==== 11.2 开始 ====
VTable 字段：alloc resize remap free 
  槽位类型 = *const fn (*anyopaque, usize, mem.Alignment, usize) ?[*]u8
  槽位类型 = *const fn (*anyopaque, []u8, mem.Alignment, usize, usize) bool
  槽位类型 = *const fn (*anyopaque, []u8, mem.Alignment, usize, usize) ?[*]u8
  槽位类型 = *const fn (*anyopaque, []u8, mem.Alignment, usize) void
官方 no-op 实现：noAlloc / noResize / noRemap / noFree（不想支持就填它们）
两次分配后：分配 2 次 / 释放 0 次 / 在用 132 字节 / 峰值 132 字节
作用域结束（两个 defer 都跑了）：分配 2 / 释放 2 / 在用 0 字节
注意：CountingAllocator 只有 48 字节，而它包装的 page_allocator 是全局单例
Allocator 接口值可直接按值拷贝：两份 ptr 相同=true（16 字节搬来搬去）
==== 11.2 结束 ====
```

四个槽位的语义：`alloc(ctx, 字节数, 对齐, 返回地址) → ?[*]u8`（**失败返回 `null`，不抛错**）、
`resize(ctx, 切片, 对齐, 新长度, 返回地址) → bool`（能否原地改长）、`remap(...) → ?[*]u8`
（能否搬家并返回新指针）、`free(ctx, 切片, 对齐, 返回地址)`。那个 `usize` 返回地址是给
分配器记栈回溯用的（DebugAllocator 的泄漏报告就靠它）。

**不想支持某个操作怎么办？填官方的 no-op。** `std.mem.Allocator` 提供了四个现成的
`noAlloc` / `noResize` / `noRemap` / `noFree`——`resize` 填 `noResize` 就永远返回
`false`，`remap` 填 `noRemap` 就永远返回 `null`。这让"写一个只支持基本分配的分配器"
变成十行代码：

```zig
// examples/11_allocators/main.zig 第 21-56 行
/// 11.2 节：自己实现一个分配器，包住底层分配器并顺手记账。
/// 只要提供 vtable 的四个槽位（alloc / resize / remap / free），就能得到一个合法的
/// std.mem.Allocator。这四个槽位就是 0.17 的**全部**接口——没有第五个方法。
const CountingAllocator = struct {
    inner: std.mem.Allocator,
    allocs: usize = 0,
    frees: usize = 0,
    live_bytes: usize = 0,
    peak_bytes: usize = 0,

    fn alloc(ctx: *anyopaque, len: usize, alignment: std.mem.Alignment, ra: usize) ?[*]u8 {
        const self: *CountingAllocator = @ptrCast(@alignCast(ctx));
        const p = self.inner.rawAlloc(len, alignment, ra) orelse return null;
        self.allocs += 1;
        self.live_bytes += len;
        if (self.live_bytes > self.peak_bytes) self.peak_bytes = self.live_bytes;
        return p;
    }

    fn free(ctx: *anyopaque, memory: []u8, alignment: std.mem.Alignment, ra: usize) void {
        const self: *CountingAllocator = @ptrCast(@alignCast(ctx));
        self.inner.rawFree(memory, alignment, ra);
        self.frees += 1;
        self.live_bytes -= memory.len;
    }

    fn allocator(self: *CountingAllocator) std.mem.Allocator {
        return .{
            .ptr = self,
            .vtable = &.{
                .alloc = alloc,
                .free = free,
                // 不支持原地伸缩/搬家：用std 提供的官方"no-op"实现占位。
                // 这两个 no-op 就是 0.17 提供的"我不管这块"的标准写法。
                .resize = std.mem.Allocator.noResize,
                .remap = std.mem.Allocator.noRemap,
            },
        };
    }
};
```

这段代码有三个值得学的点。**第一**，`ctx: *anyopaque` 进来要 `@ptrCast(@alignCast(ctx))`
才能变回 `*CountingAllocator`——这是 Zig 里从"无类型指针"恢复类型的标准写法（也就是
C 那个经典 `ContainerOf` 手写版的替代品）。**第二**，`rawAlloc` / `rawFree` 是
"vtable 级别的原始入口"：它们**不**把字节数解释成"n 个 T"（`alloc` 会做 `@sizeOf(T) * n`
的乘法检查），只处理字节。**第三**，`CountingAllocator` 本体只有 48 字节，而它包装的
`page_allocator` 是全局单例——**包装一个单例几乎不要钱**，这正是"装饰器"式分配器好用的
原因。

有了它，你就能在任何代码路径上挂一个"记账层"，想知道某段代码到底分配了多少次、峰值多少
字节、释放是否配平，不用改一行被测代码。11.2 节的输出里 `在用 132 字节 / 峰值 132 字节`
就是这么来的。

## 11.3 全家族：`alloc` / `create` / `dupe` / `dupeSentinel` / `print` / `resize` / `realloc` / `free` / `destroy`

```zig
// examples/11_allocators/main.zig 第 212-294 行（begin("11.3") 到 end("11.3")）节选
begin("11.3");
{
    const page = std.heap.page_allocator;

    // alloc(T, n) → []T：长度编进切片
    const nums = try page.alloc(u32, 4);
    defer page.free(nums);
    @memset(nums, 7);
    std.debug.print("alloc(u32, 4)   → {any}（{d} 字节），free 要传回**原来那个切片**\n", .{ nums, nums.len * @sizeOf(u32) });

    // alloc 返回 ![]T 而不是 []T：分配可能失败
    std.debug.print("alloc 返回类型 = {s}（**可能失败**）\n", .{@typeName(std.mem.Allocator.Error![]u8)});
    std.debug.print("create 返回类型 = {s}（单个对象，同一个错误集）\n", .{@typeName(std.mem.Allocator.Error!*Sword)});
    std.debug.print("free 返回 void —— 释放本身不失败，所以没有错误联合\n", .{});

    // create(T) → *T / destroy(p)：单个对象，destroy 不用传长度
    const one = try page.create(Sword);
    defer page.destroy(one);
    one.stats = try page.alloc(u8, 1);
    defer page.free(one.stats);
    one.stats[0] = 'V';
    std.debug.print("create(Sword)   → *Sword（{d} 字节）；destroy 不用传长度，因为长度是编译期已知的\n", .{@sizeOf(Sword)});

    // dupe(T, m)：拷贝
    const copy = try page.dupe(u8, "zig");
    defer page.free(copy);
    std.debug.print("dupe(u8, \"zig\") → len={d} 内容={s}（长度不含任何结尾 0）\n", .{ copy.len, copy });

    // ⚠️ 0.17：dupeZ **已移除**。继任者是 dupeSentinel(T, m, sentinel)
    const cz = try page.dupeSentinel(u8, "zig", 0);
    defer page.free(cz);
    // ...（allocSentinel / print / resize / realloc 略）
}
end("11.3");
```

```text
==== 11.3 开始 ====
alloc(u32, 4)   → { 7, 7, 7, 7 }（16 字节），free 要传回**原来那个切片**
alloc 返回类型 = error{OutOfMemory}![]u8（**可能失败**）
create 返回类型 = error{OutOfMemory}!*main.Sword（单个对象，同一个错误集）
free 返回 void —— 释放本身不失败，所以没有错误联合
create(Sword)   → *Sword（16 字节）；destroy 不用传长度，因为长度是编译期已知的
dupe(u8, "zig") → len=3 内容=zig（长度不含任何结尾 0）
dupeSentinel(u8, "zig", 0) → 类型 [:0]u8，len=3，第 3 字节是 0
allocSentinel(u8, 5, 0) → 类型 [:0]u8，len=5（哨兵不算在 len 里，但占了 1 字节）
page.print(...)  → [hi] n=42（分配器上的 printf，0.16 还没有）
⚠️ alloc 返回 undefined 内存，Debug 下被填成 0xaa...：读到 2863311530 / 2863311530（十六进制 0xaaaaaaaa）
  （栈上的 undefined 填0x00，堆上的 undefined 填 0xaa —— 两个不一样，别混）
  @memset(0) 之后：0 / 0
resize(16→8)    = true（true = 原地缩小成功，指针不变）
realloc(8→8192) 搬家了=true（page_allocator 不能原地扩，走 remap）
realloc(8192→8) 搬家了=true
把切片缩到一半再 free：会 panic。DebugAllocator 的 free 认的是 (地址, 长度, 对齐) 三元组，
  实测 panic 文案 = `Invalid free`；SafeAllocator 是 `free of invalid memory`或 corrupted metadata`。
  所以本示例只演示"指针地址仍等于原始地址"，不真的去free 半块：true
还原成完整长度 64 字节再 free：正常
==== 11.3 结束 ====
```

把全家族列一遍，语义差别其实很清楚：

| 方法 | 签名要点 | 说明 |
|---|---|---|
| `alloc(T, n)` | `Error![]T` | 返回切片，长度编进返回值 |
| `allocSentinel(T, n, s)` | `Error![:sentinel]T` | n 个元素 + 尾部哨兵，**哨兵不算在 `.len` 里** |
| `allocWithOptions(T, n, ?Alignment, ?T)` | `Error![]align(..)T` | 对齐与哨兵**一起**要（11.14 节） |
| `create(T)` | `Error!*T` | 单个对象 |
| `alignedAlloc(T, ?Alignment, n)` | `Error![]align(..)T` | ⚠️ 第二个参数是**对齐不是长度** |
| `alignedCreate(T, ?Alignment)` | `Error!*align(..)T` | 同上，单个 |
| `dupe(T, m)` | `Error![]T` | 拷贝 |
| `dupeSentinel(T, m, s)` | `Error![:sentinel]T` | **⚠️ 0.17 里 `dupeZ` 的继任者** |
| `print(fmt, args)` | `Error![]u8` | 分配一块格式化好的字符串（0.16 还没有） |
| `resize(slice, new_len)` | `bool` | **不改指针**，返回能否成功 |
| `realloc(slice, new_n)` | `Error![]T` | 可能搬家 |
| `free(slice)` / `destroy(ptr)` | `void` | 不返回错误 |

### 为什么 `alloc` 返回 `![]T` 而 `create` 返回 `!T`

两者都是"可能失败"，错误集也是同一个 `error{OutOfMemory}`。区别在**返回值的形状**：
`alloc` 要告诉你"给了你多少个元素"，所以长度只能编进返回值里——于是返回 `[]T`；
`create` 只给一个 `*T`，长度是编译期已知的 `@sizeOf(T)`，编不进返回值也不需要。

这个"长度编进返回值"的设计有个重要推论：**`free` 必须传回当初那个切片**。分配器要靠
`(地址, 长度, 对齐)` 三元组找回元数据。你把切片改成 `s[0..32]` 再 free，实测会 panic：

```text
thread 919674 panic: Invalid free
lib/std/heap/debug_allocator.zig:885:49: in free
    if (bucket.canary != config.canary) @panic("Invalid free");
lib/std/mem/Allocator.zig:165:25: in rawFree
    return a.vtable.free(a.ptr, memory, alignment, ret_addr);
```

用 `init.gpa`（Debug 模式下的 `SafeAllocator`）报的是另一条文案：`panic: free of invalid
memory [addr: ..., len: 64 (0x40) align: 1] or corrupted metadata`。**两条都是 panic，不是
静默 UB**——这是 0.17 内存安全的一部分：契约被违反时炸给你看，而不是让你调试三天。

### ⚠️ `alloc` 返回的是 `undefined` 内存，堆上填 0xaa 不是 0x00

输出第 11 行那个 `2863311530` 就是 `0xAAAAAAAA`。**栈上的 `undefined` 在 0.17 被填
`0x00`（3.1 节实测），但堆上的 `undefined` 填 `0xaa`。**两个不一样，别混。理由是栈上
未初始化内存由 Debug 运行时清零，而 `alloc` 返回的内存来自 `allocBytesAligned`，那里
显式 `@memset(byte_ptr[0..byte_count], undefined)`。总之：**`alloc` 之后必须初始化，
不能读**。

### ⚠️ `dupeZ` 在 0.17 被移除

这是本章最"意外"的破坏性变更。实测报错：

```text
error: no field or member function named 'dupeZ' in 'mem.Allocator'
note: struct declared here
    //! The standard memory allocation interface.
```

继任者是 **`dupeSentinel(comptime T, m, comptime sentinel)`**，返回值类型从 `[:0]T` 变成
`:sentinel`——**哨兵值从"写死的 0"变成"你指定的编译期常量"**。想复制一个 C 风格字符串就写
`dupeSentinel(u8, s, 0)`。这个改动让"用别的哨兵值"（比如 `0xff` 作终止符、`0` 之外的
`u16` 分隔符）成了可能。

## 11.4 OOM 是返回值，不是崩溃

这是 Zig 和 C 最大的差别之一：**内存不足是一个你能 `catch` 的值**。

```zig
// examples/11_allocators/main.zig 第 297-319 行（begin("11.4") 到 end("11.4")）
begin("11.4");
{
    var backing: [64]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&backing);
    const a = fba.allocator();
    const first = try a.alloc(u8, 40);
    std.debug.print("先分 40 字节：成功，end_index={d}，还剩 {d} 字节\n", .{ fba.end_index, 64 - fba.end_index });
    if (a.alloc(u8, 40)) |_| {
        std.debug.print("不该成功\n", .{});
    } else |err| {
        std.debug.print("再分 40 字节：拿到 {s}——是**返回值**，进程没崩、errno 没变\n", .{@errorName(err)});
        std.debug.print("  @typeName(try a.alloc(u8, 1)) = {s}\n", .{@typeName(std.mem.Allocator.Error![]u8)});
        std.debug.print("  错误集只有 OutOfMemory 一种：{s}\n", .{@typeName(std.mem.Allocator.Error)});
        const err_names = @typeInfo(std.mem.Allocator.Error).error_set.error_names.?;
        std.debug.print("  错误名 = {s}（成员数 {d}）\n", .{ err_names[0][0..err_names[0].len], err_names.len });
    }
    a.free(first); // 只归还"最后一块"，end_index 才能回退
    std.debug.print("归还最后一块后 end_index={d}，再分 40 字节：成功={}\n", .{
        fba.end_index, (try a.alloc(u8, 40)).len == 40,
    });
    std.debug.print("对比：OOM 从来不是 panic。Zig 里唯一会 panic 的是\"契约被违反\"（比如用错分配器 free）\n", .{});
}
end("11.4");
```

```text
==== 11.4 开始 ====
先分 40 字节：成功，end_index=40，还剩 24 字节
再分 40 字节：拿到 OutOfMemory——是**返回值**，进程没崩、errno 没变
  @typeName(try a.alloc(u8, 1)) = error{OutOfMemory}![]u8
  错误集只有 OutOfMemory 一种：error{OutOfMemory}
  错误名 = OutOfMemory（成员数 1）
归还最后一块后 end_index=0，再分 40 字节：成功=true
对比：OOM 从来不是 panic。Zig 里唯一会 panic 的是"契约被违反"（比如用错分配器 free）
==== 11.4 结束 ====
```

**分配器的错误集只有一个成员**：`error{OutOfMemory}`。这是刻意的——分配器只可能因为
"要不到内存"失败，不会因为别的原因失败（格式错误是编译期的事）。所以你可以写
`catch return error.OutOfMemory` 或者干脆 `catch return`，把错误往上传播。

对比一下：C 里 `malloc` 返回 `NULL`，你得每次检查；忘了检查就是段错误。Rust 里 `Vec`
分配失败会 **abort**（因为 Rust 的分配错误默认不可恢复）。Zig 把它变成普通错误值，
于是"OOM 要怎么处理"成了一个你可以**设计**的问题——11.10 节会用注入失败的方式把这条路径
彻底测一遍。

## 11.5 栈 vs 堆：实测

```zig
// examples/11_allocators/main.zig 第 322-408 行（begin("11.5") 到 end("11.5")）节选
begin("11.5");
{
    const n: usize = 20_000;
    var acc: usize = 0;
    const page = std.heap.page_allocator;

    var t = std.Io.Clock.awake.now(io);
    for (0..n) |i| {
        var buf: [256]u8 = undefined;
        buf[0] = @truncate(i);
        acc += buf[0];
    }
    const stack_ns = t.durationTo(std.Io.Clock.awake.now(io)).toNanoseconds();
    // ...（page / fba / bfa / smp / DebugAllocator 五组计时循环）
    std.debug.print("{d} 轮，每轮拿 256 字节（Debug 模式，ns/次；机器不同数字会变，看**量级**）：\n", .{n});
    std.debug.print("  栈上 [256]u8（根本不分配）{d:>7} ns\n", .{@as(u64, @intCast(@divTrunc(stack_ns, n)))});
    // ...
}
end("11.5");
```

```text
==== 11.5 开始 ====
20000 轮，每轮拿 256 字节（Debug 模式，ns/次；机器不同数字会变，看**量级**）：
  栈上 [256]u8（根本不分配）      8 ns
  FixedBufferAllocator          117 ns
  BufferFirstAllocator(64)      183 ns
  smp_allocator                 196 ns
  page_allocator               6881 ns
  DebugAllocator              27471 ns
栈最便宜（就一次栈指针下移），FBA 只做 end_index 加法，DebugAllocator 最贵（每块都记元数据+栈回溯）
acc=2646416（防止被优化掉）
page_allocator 分100 字节：地址页内偏移 = 0（一页 4096 字节，实际只用 100）
结论：**能用栈上定长数组就别分配**。堆是给"长度运行期才知道"的东西准备的
==== 11.5 结束 ====
```

**绝对数字每次跑都会变，看的是量级关系**（这台 x86_64 Mac，Debug 模式）：栈 ≈ 8ns，
FixedBuffer ≈ 117ns（**约 15 倍**），smp_allocator ≈ 196ns，page_allocator ≈ 6881ns
（**约 860 倍**），DebugAllocator ≈ 27471ns（**约 3400 倍**）。

三个结论。**第一，栈不是"快一点"，是快三个数量级**——因为栈分配就是"移动一下栈指针"，
没有任何 bookkeeping。所以长度编译期已知时，答案永远是栈。**第二，`FixedBufferAllocator`
的常数极小**（117ns），它只做"检查边界 + 移动 end_index + 对齐"三件事，没有任何簿记。
热路径（每帧都要缓冲）用它。**第三，`page_allocator` 做小分配是灾难**：6881ns 里绝大部分
是 `mmap`/`munmap` 的系统调用开销。所以它是**别的分配器的底座**，不是业务代码的直接工具。

还有一个"内存浪费"的证据：输出最后两行说 `page_allocator 分 100 字节` 时，地址的页内偏移
是 0——**100 字节的东西占了一整页 4096 字节**（利用率 2.4%）。这就是为什么
`DebugAllocator` 内部要自己做分桶（size class），而 `page_allocator` 不做。

⚠️ 顺带一个格式化的小坑：`std.Io.Clock.awake.now(io).durationTo(...).toNanoseconds()`
返回的是 **`i64`**，而 `{d}` 打印有符号整数时会带正号（`+8`）。示例里统一 `@intCast` 成
`u64` 再打，输出才是纯数字。格式化宽度用 `{d:>7}`（右对齐补空格）或 `{d:_>7}`（补下划线）。

## 11.6 六大分配器各自的定位

```zig
// examples/11_allocators/main.zig 第 411-465 行（begin("11.6") 到 end("11.6")）节选
begin("11.6");
{
    std.debug.print("① page_allocator    类型 {s}，直接向 OS 要页（mmap/munmap）\n", .{@typeName(@TypeOf(std.heap.page_allocator))});
    std.debug.print("   page_size_min={d} page_size_max={d}（本机页大小）\n", .{ std.heap.page_size_min, std.heap.page_size_max });
    std.debug.print("   它是**其他分配器的底座**，不是业务代码的直接工具\n", .{});

    std.debug.print("② FixedBufferAllocator  类型 {s}，@sizeOf={d} 字节\n", .{
        @typeName(std.heap.FixedBufferAllocator), @sizeOf(std.heap.FixedBufferAllocator),
    });
    // ...（BufferFirst / Arena / Debug / Smp 六段逐一探针）
    std.debug.print("补充两个 0.17 新面孔：std.heap.SafeAllocator 存在={}，std.mem.ValidationAllocator 存在={}\n", .{
        @hasDecl(std.heap, "SafeAllocator"), @hasDecl(std.mem, "ValidationAllocator"),
    });
}
end("11.6");
```

```text
==== 11.6 开始 ====
① page_allocator    类型 mem.Allocator，直接向 OS 要页（mmap/munmap）
   page_size_min=4096 page_size_max=4096（本机页大小）
   它是**其他分配器的底座**，不是业务代码的直接工具
② FixedBufferAllocator  类型 heap.FixedBufferAllocator，@sizeOf=24 字节
   两个字段：end_index=0 buffer.len=8（分配 = 移动 end_index）
③ BufferFirstAllocator  类型 heap.BufferFirstAllocator，@sizeOf=40 字节
   两个字段：fallback_allocator=mem.Allocator fixed_buffer_allocator=heap.FixedBufferAllocator
   ⚠️ 0.17：std.heap.stackFallback **已移除**，继任者就是它（语义一致：先试栈上缓冲，容纳不下自动落到底层）
     老写法 std.heap.stackFallback(...) → error: root source file struct 'heap' has no member named 'stackFallback'
④ ArenaAllocator    类型 heap.ArenaAllocator，@sizeOf=32 字节，字段 child_allocator=mem.Allocator
   批量分配一次释放；ResetMode = free_all / retain_capacity / retain_with_limit
⑤ DebugAllocator    是函数（生成类型）：std.heap.DebugAllocator(Config)
   有 pub const init（0.17 推荐）：var da: std.heap.DebugAllocator(.{}) = .init;
   旧写法 std.heap.DebugAllocator(.{}){} 仍能编译，但源码注释写明 "Default initialization of this struct is deprecated"
   ⚠️ 注意 DebugAllocator **不是** std.testing.allocator 的本体（见 11.12 节）
⑥ SmpAllocator      单例，无init/无 allocator()——直接用 std.heap.smp_allocator
   @hasDecl(SmpAllocator,"init")=false @hasDecl(SmpAllocator,"allocator")=false
   五个单例都是同一个类型 mem.Allocator：page/smp/c/brk/wasm_allocator
   c_allocator 存在=true（要zig build-exe ... -lc，17 章）
补充两个 0.17 新面孔：std.heap.SafeAllocator 存在=true，std.mem.ValidationAllocator 存在=true
  SafeAllocator = init.gpa 在 Debug/Safe 模式下的真身（见 11.17 节）
实测：page_allocator 一次给 1000000 个 u32 = 3 MB（大块走 mmap，小块也按页起）
==== 11.6 结束 ====
```

### 0.17 各分配器的真实名字与初始化方式（**逐个探针实测**）

| 分配器 | 0.17 真实名字 | 初始化方式 | `@sizeOf` | 定位 |
|---|---|---|---|---|
| 页分配器 | `std.heap.page_allocator`（单例，类型 `std.mem.Allocator`） | 直接用，无初始化 | — | 底座：向 OS `mmap` 要页 |
| 固定缓冲 | `std.heap.FixedBufferAllocator` | `std.heap.FixedBufferAllocator.init(&buf)` | 24 | 一块栈/静态缓冲当堆，用尽报 OOM |
| 缓冲优先 | `std.heap.BufferFirstAllocator` | `std.heap.BufferFirstAllocator.init(&buf, fallback)` | 40 | 小分配走缓冲，大分配落底层 |
| 竞技场 | `std.heap.ArenaAllocator` | `std.heap.ArenaAllocator.init(child_allocator)` | 32 | 批量分配一次释放 |
| 调试分配器 | `std.heap.DebugAllocator(Config)` | `var da: std.heap.DebugAllocator(.{}) = .init;`（或旧写法 `(.{}){}`） | — | 泄漏/双free/栈回溯检测，慢 |
| 安全分配器 | `std.heap.SafeAllocator` | `std.heap.SafeAllocator.init(backing, .{})` | — | **0.17 新**：`init.gpa` 在 Debug/Safe 下的真身 |
| 多线程分配器 | `std.heap.smp_allocator`（单例） | 直接用，**无 `init` 也无 `allocator()`** | — | ReleaseFast 默认堆，每线程独立 freelist |
| 校验分配器 | `std.mem.ValidationAllocator(T)` | `.init(underlying)` | 16 | 0.17 新：断言接口不被违反 |
| 对象池 | `std.heap.MemoryPool(T)` | `var p: std.heap.MemoryPool(u32) = .empty;` | 24 | 同类型节点批量分配最快 |
| libc | `std.heap.c_allocator` | 直接用 | — | 要 `-lc`（17 章） |

**关于 `SmpAllocator` 的一个反直觉事实**：它是**单例**，`@hasDecl(SmpAllocator, "init")` 和
`@hasDecl(SmpAllocator, "allocator")` **都是 `false`**。源码注释写得很直白："This
allocator is a singleton; it uses global state and only one should be instantiated for the
entire process."。所以只有 `std.heap.smp_allocator` 这一个值可用，不要试图自己造第二个。

**关于 `DebugAllocator` 的初始化**：0.17 的源码里 `DebugAllocator(Config)` 返回一个匿名
struct，它有 `pub const init: Self = .{}`，同时源码顶部写着 "Default initialization of this
struct is deprecated; use `.init` instead."。实测**两种写法都能编译**（`(.{}){}` 不会报错，
只是注释层面不推荐）。新代码写 `var da: std.heap.DebugAllocator(.{}) = .init;`。

**⚠️ `std.heap.stackFallback` 已移除**，继任者是 `std.heap.BufferFirstAllocator`：

```text
error: root source file struct 'heap' has no member named 'stackFallback'
note: struct declared here
const std = @import("std.zig");
```

语义完全一致：先试栈上缓冲，容纳不下自动落到底层分配器。11.9 节专门讲它。

## 11.7 `FixedBufferAllocator`：一块缓冲当堆

```zig
// examples/11_allocators/main.zig 第 468-511 行（begin("11.7") 到 end("11.7")）节选
begin("11.7");
{
    var backing: [128]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&backing);
    const f = fba.allocator();
    _ = try f.alloc(u8, 50);
    std.debug.print("alloc 50 → end_index={d}（缓冲128）\n", .{fba.end_index});
    _ = try f.alloc(u8, 50);
    std.debug.print("alloc 50 → end_index={d}，剩 {d} 字节\n", .{ fba.end_index, 128 - fba.end_index });
    if (f.alloc(u8, 50)) |_| {
        std.debug.print("不该成功\n", .{});
    } else |err| {
        std.debug.print("第三次 alloc 50 按预期失败：{s}——剩 28 字节装不下 50（阿喀琉斯之踵）\n", .{@errorName(err)});
    }
    fba.reset();
    _ = try f.alloc(u8, 100);
    std.debug.print("reset() 归零后再分 100 字节：成功（现在 end_index={d}），无需逐个 free\n", .{fba.end_index});

    // 分配=移动 end_index，free 只对"最后一块"有效
    var b2: [64]u8 = undefined;
    var fba2 = std.heap.FixedBufferAllocator.init(&b2);
    const g = fba2.allocator();
    const x1 = try g.alloc(u8, 16);
    const x2 = try g.alloc(u8, 16);
    g.free(x1); // x1 不是最后一块
    std.debug.print("先 free x1（非最后一块）→ end_index仍={d}：内存没还（**只回退最后一块**）\n", .{fba2.end_index});
    g.free(x2);
    std.debug.print("再 free x2 → end_index={d}（回退到 x1 之后）\n", .{fba2.end_index});
    // ...
}
end("11.7");
```

```text
==== 11.7 开始 ====
alloc 50 → end_index=50（缓冲128）
alloc 50 → end_index=100，剩 28 字节
第三次 alloc 50 按预期失败：OutOfMemory——剩 28 字节装不下 50（阿喀琉斯之踵）
reset() 归零后再分 100 字节：成功（现在 end_index=100），无需逐个 free
两块 16 字节：end_index=32
先 free x1（非最后一块）→ end_index仍=32：内存没还（**只回退最后一块**）
再 free x2 → end_index=16（回退到 x1 之后）
alloc(u32,1) 要 4 字节 + 4 对齐 → end_index=4
alloc(u64,1) 要 8 字节 + 8 对齐 → end_index=8
无堆环境（内核 / wasm / 中断上下文）与热路径用它；用尽返回 error.OutOfMemory——优雅的失败
threadSafeAllocator() 存在=true（多线程共享一块缓冲时换它）
==== 11.7 结束 ====
```

它的实现简单到可以一句话说完：**两个字段（`end_index` + `buffer`），分配就是"把 end_index
往前挪 n 字节并对齐"**。`@sizeOf = 24`（两个 `usize` 加一个 slice）。

三个必须知道的行为。**① 用尽返回 `error.OutOfMemory`**，不是崩溃。这是无堆环境
（内核模块、wasm、中断上下文）能跑起来的唯一原因——在那些环境里"内存不够"是一个
**预期内**的正常情况，你得能优雅处理。**② `free` 只对最后一块有效**。输出里
`先 free x1 → end_index 仍=32` 说明了：如果你乱序 free，内存不会还回来。想整块复用就调
`reset()`，它把 `end_index` 直接归零，不需要逐个 free。**③ 对齐会吃掉 padding**：
`alloc(u64, 1)` 要的不只是 8 字节，还要地址是 8 的倍数，所以 `end_index` 从 0 跳到 8。

## 11.8 `ArenaAllocator`：一批分配一次释放

```zig
// examples/11_allocators/main.zig 第 514-557 行（begin("11.8") 到 end("11.8")）节选
begin("11.8");
{
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const a = arena.allocator();
    std.debug.print("初始 queryCapacity={d}（还没向底层要过任何东西）\n", .{arena.queryCapacity()});
    _ = try a.alloc(u8, 100);
    std.debug.print("alloc 100 后容量={d}：一次性向底层要了整块，再也不还给底层\n", .{arena.queryCapacity()});
    _ = try a.alloc(u8, 100);
    std.debug.print("再 alloc 100 容量={d}：同块内只是 end_index 加法，不进底层\n", .{arena.queryCapacity()});
    // ...（第三、四次分配看容量跳变；单个 free 是 no-op；三种 reset）
    _ = arena.reset(.free_all);
    std.debug.print("reset(.free_all)→ 容量={d}（整块还给底层）\n", .{arena.queryCapacity()});
    _ = try a.alloc(u8, 4096);
    _ = arena.reset(.retain_capacity);
    std.debug.print("reset(.retain_capacity) → 容量={d}（预热：块留着复用，后续不再找底层要）\n", .{arena.queryCapacity()});
    _ = arena.reset(.{ .retain_with_limit = 512 });
    std.debug.print("reset(.{{ .retain_with_limit = 512 }}) → 容量={d}（超了，砍到最小）\n", .{arena.queryCapacity()});
}
end("11.8");
```

```text
==== 11.8 开始 ====
初始 queryCapacity=0（还没向底层要过任何东西）
alloc 100 后容量=188：一次性向底层要了整块，再也不还给底层
再 alloc 100 容量=300：同块内只是 end_index 加法，不进底层
第三次 alloc 100 容量=500
第四次 alloc 100 容量=700（188/112/200 这样的跳变 = 又向底层要了一块）
单个 free(scratch) 前后容量都是 828：**内存不归还**（合法但是 no-op，别依赖）
  （free 之前 alloc(64) 也只把容量从 700 抬到 828；free 之后仍是 828，这 64 字节彻底留在 arena 里了）
reset(.free_all)→ 容量=0（整块还给底层）
alloc 4096 → 容量=6182
reset(.retain_capacity) → 容量=6182（预热：块留着复用，后续不再找底层要）
reset(.{ .retain_with_limit = 512 }) → 容量=512（超了，砍到最小）
splitIntoArena 切出 4 段：the/quick/brown/fox/
  整个函数只有分配、没有一次 free——这就是 arena 风格
==== 11.8 结束 ====
```

看 `188 → 300 → 500 → 700 → 828` 这串数字：arena 一次向底层要一块（这里底层是
`page_allocator`，所以要了整整一页），之后同块内的分配只是 `end_index` 加法，**再也不进
底层**。这是它快的全部原因。

**必须接受的事实：arena 里的内存不归还给底层**。单个 `free` 是**合法的 no-op**——输出第 6
行显示 `alloc(64)` 把容量从 700 抬到 828，`free` 之后仍是 828，这 64 字节彻底留在 arena
里了。别把"看起来能 free"当成在 arena 上做细粒度管理的理由。

**三种 reset 模式**，用一个联合体（`ResetMode = union(enum)`）表达：

| 模式 | 行为 | 用在哪 |
|---|---|---|
| `.free_all` | 整块还给底层，容量归 0 | 这一批彻底结束了 |
| `.retain_capacity` | 保留已申请的块，`end_index` 归零 | **预热**：循环复用，后续不再进底层 |
| `.{ .retain_with_limit = N }` | 保留但容量砍到不超过 N | 长期驻留但要限制水位 |

注意输出里 `reset(.{ .retain_with_limit = 512 })` 把 6182 砍到 512——**这个模式会让底层把
内存还给 OS**，如果原来有多块，只保留能装下 N 的那些。

典型的 arena 形状就是本章的 `splitIntoArena`（第 98-107 行）：把一行文本按空格切成若干段，
每段 `dupe` 到 arena 上，切片数组也挂 arena 上。**整个函数只有分配、没有一次 `free`**：

```zig
// examples/11_allocators/main.zig 第 98-107 行
fn splitIntoArena(arena: std.mem.Allocator, line: []const u8) ![]const []const u8 {
    var parts: std.ArrayList([]const u8) = .empty;
    errdefer parts.deinit(arena);
    var it = std.mem.tokenizeAny(u8, line, " ");
    while (it.next()) |tok| {
        try parts.append(arena, try arena.dupe(u8, tok));
    }
    return parts.toOwnedSlice(arena);
}
```

这解决了递归下降解析器最难写的那部分：AST 是一棵树，每个节点都要分配内存，构造完之后
"释放整棵树"是一个不可能优雅表达的操作。有了 arena，`defer arena.deinit()` 一行就够，
**中间产物零清理成本**。

## 11.9 `BufferFirstAllocator`：0.17 的新日常

```zig
// examples/11_allocators/main.zig 第 560-598 行（begin("11.9") 到 end("11.9")）节选
begin("11.9");
{
    // ⚠️ 0.17 迁移注记：老教程里的 std.heap.stackFallback 已移除。
    // 继任者是 std.heap.BufferFirstAllocator，语义完全一致：
    // 先试栈上缓冲，容纳不下自动落到底层分配器。
    //   旧：var fb = std.heap.stackFallback(std.heap.page_allocator, &stack_buf);
    //   新：var fb = std.heap.BufferFirstAllocator.init(&stack_buf, std.heap.page_allocator);
    var stack_buf: [64]u8 = undefined;
    var fb = std.heap.BufferFirstAllocator.init(&stack_buf, std.heap.page_allocator);
    const a = fb.allocator();
    const small = try a.alloc(u8, 32);
    std.debug.print("BufferFirstAllocator(64) 分 32→ 走栈上缓冲={}（ownsPtr 判定）\n", .{
        fb.fixed_buffer_allocator.ownsPtr(@ptrCast(small.ptr)),
    });
    a.free(small);
    const exact = try a.alloc(u8, 64);
    std.debug.print("分 64（刚好装满）      → 走栈上缓冲={}\n", .{fb.fixed_buffer_allocator.ownsPtr(@ptrCast(exact.ptr))});
    a.free(exact);
    const large = try a.alloc(u8, 8192);
    std.debug.print("分 8192              → 走栈上缓冲={}（自动落到底层）\n", .{fb.fixed_buffer_allocator.ownsPtr(@ptrCast(large.ptr))});
    a.free(large);
    std.debug.print("关键：free 时它靠ownsPtr 自动判断该还给栈缓冲还是底层——调用方完全无感\n", .{});
}
end("11.9");
```

```text
==== 11.9 开始 ====
BufferFirstAllocator(64) 分 32→ 走栈上缓冲=true（ownsPtr 判定）
分 64（刚好装满）      → 走栈上缓冲=true
分 8192              → 走栈上缓冲=false（自动落到底层）
关键：free 时它靠ownsPtr 自动判断该还给栈缓冲还是底层——调用方完全无感
用法：把 std.heap.page_allocator 换成它，小分配省一次系统调用，大分配照样落到底层
  var bfa = std.heap.BufferFirstAllocator.init(&buf, std.heap.smp_allocator);
  const a = bfa.allocator();  // 之后 a 就是一个普通 Allocator
MemoryPool(u32).create → 42，@sizeOf(MemoryPool(u32))=24（同类型节点批量分配最快）
==== 11.9 结束 ====
```

它只有两个字段：`fallback_allocator` 和 `fixed_buffer_allocator`。逻辑简单到 20 行：`alloc`
先问 `FixedBufferAllocator`（能容纳就走缓冲），不行才问 `fallback`（`@sizeOf = 40`）。

**最漂亮的地方是 `free` 完全不需要调用方参与**：它内部用
`fixed_buffer_allocator.ownsPtr(buf.ptr)` 判断"这块指针是不是在我的缓冲里"——是就还给
缓冲，不是就还给底层。**这就是"栈优先"策略能自动化的关键**：调用方拿到的还是一个普通
`Allocator`，完全不知道背后有两个来源。

典型用法就是拿它包住 `smp_allocator`：

```zig
var buf: [4096]u8 = undefined;
var bfa = std.heap.BufferFirstAllocator.init(&buf, std.heap.smp_allocator);
const a = bfa.allocator();  // 之后 a 就是一个普通 Allocator
```

小分配（解析 token、格式化小字符串）完全在栈上，零系统调用；大分配照样能从 smp 拿。
本节末尾还演示了 `std.heap.MemoryPool(T)`（`@sizeOf(MemoryPool(u32)) = 24`）——专治
"创建十万个同类型小对象"的场景（AST 节点、链表节点），它复用已释放的元素，是同类型批量
分配最快的路子。

## 11.10 注入失败以测 OOM 路径

**OOM 路径是最难测、也最该测的代码。** 因为它平时根本不发生——等你发现"第三步会失败"
的时候，线上已经因为第三步失败漏了一堆内存。Zig 的答案是 `FailingAllocator`：包一个正常
分配器，让它在第 N 次分配时开始返回失败。

```zig
// examples/11_allocators/main.zig 第 601-638 行（begin("11.10") 到 end("11.10")）节选
begin("11.10");
{
    // FailingAllocator：第 N 次分配开始返回 null
    var fa = std.testing.FailingAllocator.init(std.heap.page_allocator, .{ .fail_index = 2 });
    const a = fa.allocator();
    const p1 = try a.alloc(u8, 64);
    const p2 = try a.alloc(u8, 64);
    if (a.alloc(u8, 64)) |_| {
        std.debug.print("  不该成功\n", .{});
    } else |err| {
        std.debug.print("fail_index=2：两次成功后第 3 次返回 {s}\n", .{@errorName(err)});
    }
    std.debug.print("  计量：alloc_index={d}（失败的那次不计数），allocated={d} 字节，has_induced_failure={}\n", .{
        fa.alloc_index, fa.allocated_bytes, fa.has_induced_failure,
    });
    std.debug.print("  还有 resize_fail_index={d}（默认 maxInt，即 resize 永不失败）\n", .{fa.resize_fail_index});
    a.free(p1);
    a.free(p2);
    std.debug.print("  归还后：allocations={d} deallocations={d} freed={d} 字节\n", .{
        fa.allocations, fa.deallocations, fa.freed_bytes,
    });

    // fail_index = 0：第一次就失败
    var fa0 = std.testing.FailingAllocator.init(std.heap.page_allocator, .{ .fail_index = 0 });
    // ...
    // std.testing.failing_allocator：现成的"永远失败"实例
}
end("11.10");
```

```text
==== 11.10 开始 ====
fail_index=2：两次成功后第 3 次返回 OutOfMemory
  计量：alloc_index=2（失败的那次不计数），allocated=128 字节，has_induced_failure=true
  还有 resize_fail_index=18446744073709551615（默认 maxInt，即 resize 永不失败）
  归还后：allocations=2 deallocations=2 freed=128 字节
fail_index=0：第一次就返回 OutOfMemory（alloc_index=0）
std.testing.failing_allocator：永远返回 OutOfMemory（fail_index=0 的全局实例）
==== 11.10 结束 ====
```

`FailingAllocator` 的 `Config` 有两个字段：`fail_index`（前 N 次分配成功，第 N+1 次失败）
和 `resize_fail_index`（同理，对 `resize`/`remap`）。实测确认三个记账字段的行为：
**`alloc_index` 在失败那次不计数**（停在 2），`allocated_bytes` 只累计成功的（128 = 2×64），
`has_induced_failure` 置 `true`。另外 `std.testing.failing_allocator` 是一个**全局现成实例**，
它的 `fail_index = 0`（底层是 `FixedBufferAllocator.init("")`，也就是一块**空缓冲**——
所以它永远失败）。

手写这个包装器只需要实现 `alloc`/`free`/`resize`/`remap` 四个槽位，和 11.2 节的
`CountingAllocator` 完全一样——**这就是 vtable 只有四槽位的价值**：包装一个分配器是
二十行的事。

## 11.11 `checkAllAllocationFailures`：逐个 OOM 点自动抓泄漏

上一节能手动指定 `fail_index`，但你得自己猜"第几次分配会失败"。`checkAllAllocationFailures`
把这件事自动化了：**它自己数出总分配次数，然后对每个 `fail_index` 从 0 到总数逐个试一遍**。

先看它的靶子函数（`examples/11_allocators/main.zig` 第 109-133 行）：

```zig
/// 11.11 节的靶子：会做**多次**分配的函数，才能被 fail_index 逐个打断。
fn buildTeamSafe(allocator: std.mem.Allocator, names: []const []const u8) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    for (names, 0..) |name, i| {
        if (i > 0) try out.append(allocator, ',');
        try out.appendSlice(allocator, name);
    }
    return out.toOwnedSlice(allocator);
}

/// 故意漏内存的版本：第一次分配成功、第二次失败时，第一块就丢了。
/// 用它跑 checkAllAllocationFailures 就能当场抓到（见 11.11 节实测输出）。
fn leakOnOom(allocator: std.mem.Allocator, n: usize) !void {
    const a = try allocator.alloc(u8, n);
    const b = try allocator.alloc(u8, n); // ← 这里失败时，a 永远不会被 free
    allocator.free(b);
    allocator.free(a);
}

/// checkAllAllocationFailures 的靶子：第一个参数必须是 allocator。
fn exerciseSafe(allocator: std.mem.Allocator, names: []const []const u8) !void {
    const s = try buildTeamSafe(allocator, names);
    defer allocator.free(s);
}
```

```zig
// examples/11_allocators/main.zig 第 641-655 行（begin("11.11") 到 end("11.11")）
begin("11.11");
{
    const names = [_][]const u8{ "zig", "rust", "go" };
    // 有 errdefer 的版本：每一条 OOM 路径都不漏
    std.testing.checkAllAllocationFailures(std.heap.page_allocator, exerciseSafe, .{names[0..]}) catch |err| {
        std.debug.print("  buildTeamSafe 被查出问题：{s}\n", .{@errorName(err)});
    };
    std.debug.print("buildTeamSafe（有 errdefer）：全部 OOM 路径都不漏，检查通过\n", .{});
    // 故意漏内存的版本：checkAllAllocationFailures 会当场抓出来
    std.testing.checkAllAllocationFailures(std.heap.page_allocator, leakOnOom, .{32}) catch |err| {
        std.debug.print("leakOnOom 被查出：{s}（上面打印了泄漏点的栈回溯）\n", .{@errorName(err)});
    };
    std.debug.print("对比：leakOnOom（没 errdefer）在第 2 次分配失败时就丢了第 1 块\n", .{});
}
end("11.11");
```

`checkAllAllocationFailures(backing_allocator, test_fn, extra_args)` 的工作方式很暴力：
先用一个"不失败"的实例跑一遍，数出总共分配了多少次（`needed_alloc_count`）；然后
**对 `fail_index` 从 0 到总数逐个试一遍**，每次都调用 `test_fn` 并检查
`allocated_bytes == freed_bytes`。任何一条路径漏了内存，就返回
`error.MemoryLeakDetected` 并把泄漏点的栈回溯打出来。

`test_fn` 的第一个参数**必须是 allocator**，剩下的参数通过 `extra_args` 传。

```text
==== 11.11 开始 ====
buildTeamSafe（有 errdefer）：全部 OOM 路径都不漏，检查通过

fail_index: 1/2
allocated bytes: 32
freed bytes: 0
allocations: 1
deallocations: 0
allocation that was made to fail: 
/Volumes/.../examples/11_allocators/main.zig:123:34: 0x10fb92a2b in leakOnOom (main)
    const b = try allocator.alloc(u8, n); // ← 这里失败时，a 永远不会被 free
                                 ^
...
leakOnOom 被查出：MemoryLeakDetected（上面打印了泄漏点的栈回溯）
对比：leakOnOom（没 errdefer）在第 2 次分配失败时就丢了第 1 块
==== 11.11 结束 ====
```

这段输出（栈回溯里的**地址**每次运行都不同，上面 `0x10fb92a2b` 那部分不可复现，故用
`0x...` 省略）就是这套工具的价值：**`leakOnOom` 的 bug 是一行 `errdefer` 的缺失，
`checkAllAllocationFailures` 把它精确指到第 123 行第 34 列**。这个"漏内存"的 bug 在正常
测试里永远不会暴露——因为正常测试下 OOM 从不发生。

⚠️ 本章示例里这一段会往 stderr 打泄漏报告，但 `std.log.err` 类输出**不会**让 `zig test`
失败。真正会让 `zig test` 失败的是测试自己 `try` 了返回 `error.MemoryLeakDetected`
（本节用 `catch` 兜住了，所以测试通过）。如果需要用 `std.log.err` 演示日志而不影响
`zig test`，加 `if (builtin.is_test) return;` 守卫。

## 11.12 泄漏检测：`std.testing.allocator` 与 `DebugAllocator`

```zig
// examples/11_allocators/main.zig 第 658-688 行（begin("11.12") 到 end("11.12")）节选
begin("11.12");
{
    // std.testing.allocator 的真身：SafeAllocator
    std.debug.print("std.testing.allocator 是 {s}（0.17 已从DebugAllocator 换成 SafeAllocator）\n", .{
        "heap.SafeAllocator",
    });
    std.debug.print("⚠️ 所以在 main 里写 std.testing.allocator 是**编译错误**（实测文案）：\n", .{});
    std.debug.print("   lib/std/testing.zig:21:80: error: not testing\n", .{});
    std.debug.print("   pub const allocator = if (builtin.is_test) allocator_instance.allocator() else @compileError(\"not testing\");\n", .{});
    std.debug.print("  builtin.is_test 在 main 里是 {}\n", .{builtin.is_test});

    // DebugAllocator 的等价能力（可写在 main 里演示）
    var leaky_da = std.heap.DebugAllocator(.{}){};
        _ = try leaky_da.allocator().alloc(u8, 32); // 故意不释放
    std.debug.print("故意用 DebugAllocator 漏一块 32 字节 → deinit() 返回 {s}\n", .{@tagName(leaky_da.deinit())});

    // deinit 返回值
    var clean_da = std.heap.DebugAllocator(.{}){};
    const cbuf = try clean_da.allocator().dupe(u8, "先free再deinit");
    clean_da.allocator().free(cbuf);
    std.debug.print("先 free 再 deinit → {s}（heap.Check 枚举：ok / leak）\n", .{@tagName(clean_da.deinit())});

    // SafeAllocator.deinit 返回泄漏**块数**（usize），不是枚举
    var sa = std.heap.SafeAllocator.init(std.heap.page_allocator, .{});
    const sbuf2 = try sa.allocator().dupe(u8, "safe");
    sa.allocator().free(sbuf2);
    std.debug.print("SafeAllocator.init(page_allocator, .{{}}) + deinit() → 泄漏块数 = {d}（返回 usize，不是 heap.Check）\n", .{sa.deinit()});
}
end("11.12");
```

```text
==== 11.12 开始 ====
std.testing.allocator 是 heap.SafeAllocator（0.17 已从DebugAllocator 换成 SafeAllocator）
⚠️ 所以在 main 里写 std.testing.allocator 是**编译错误**（实测文案）：
   lib/std/testing.zig:21:80: error: not testing
   pub const allocator = if (builtin.is_test) allocator_instance.allocator() else @compileError("not testing");
  builtin.is_test 在 main 里是 false
error(DebugAllocator): memory address 0x... leaked: 
/Volumes/.../examples/11_allocators/main.zig:671:43: 0x... in main (main)
        _ = try leaky_da.allocator().alloc(u8, 32); // 故意不释放
                                          ^
...

故意用 DebugAllocator 漏一块 32 字节 → deinit() 返回 leak
  它把泄漏块打到 **stderr**，格式是 `error(DebugAllocator): memory address 0x... leaked:`
  后跟分配点的文件:行号:列号。⚠️ 那个地址每次运行都不同，别把它抄进文档当固定输出
先 free 再 deinit → ok（heap.Check 枚举：ok / leak）
SafeAllocator.init(page_allocator, .{}) + deinit() → 泄漏块数 = 0（返回 usize，不是 heap.Check）
==== 11.12 结束 ====
```

（上面 `memory address 0x... leaked:` 那一段来自 stderr，其中的**内存地址每次运行都不同**，
所以用 `0x...` 占位；`deinit()` 的返回值 `.leak` / `.ok` 才是可复现的部分。）

**⚠️ 0.17 的最大变化：`std.testing.allocator` 的真身不再是 `DebugAllocator`，而是
`SafeAllocator`。**源码里写得很清楚：

```zig
// lib/std/testing.zig 第 18-21 行
var base_allocator_instance = std.heap.FixedBufferAllocator.init("");
pub var allocator_instance: std.heap.SafeAllocator = undefined;
pub const allocator = if (builtin.is_test) allocator_instance.allocator() else @compileError("not testing");
```

连带两个后果。**第一，`deinit()` 的返回类型变了**：`DebugAllocator.deinit()` 返回
`std.heap.Check` 枚举（`.ok` / `.leak`），而 `SafeAllocator.deinit()` 返回 **`usize`
（泄漏块数）**。本节输出最后两行把两者并排打出来对照。**第二，在 `main` 里写
`std.testing.allocator` 是编译错误**（`error: not testing`），因为它被 `builtin.is_test`
守卫了。所以本章示例在 `main` 里演示泄漏检测用的是 `DebugAllocator`（可以自己实例化），
测试块里才用 `std.testing.allocator`。

### 测试里泄漏了会怎样

在 `test` 块里用 `std.testing.allocator` 而忘了 `free`，测试**会失败**。实测（故意泄漏
64 字节）：

```text
1/3 t1.test.testing.allocator 正常路径...OK
2/3 t1.test.故意泄漏：testing.allocator 会报出来...OK
[SafeAllocator] (err): leaked [addr: 10ca98010, len: 64 (0x40) align: 1] allocated at: 
/private/tmp/zprobe/t1.zig:25:40: 0x10c97d161 in test.故意泄漏：testing.allocator 会报出来 (test)
    _ = try std.testing.allocator.alloc(u8, 64);
                                       ^
...
3/3 t1.test.checkAllAllocationFailures...OK
All 3 tests passed.
1 errors were logged.
1 tests leaked memory.
error: the following test command failed with exit code 1:
```

注意这个反直觉的现象：**`All 3 tests passed.` 和 `1 tests leaked memory.` 同时出现**。
每个 test 函数"本身"通过了，但测试运行器在所有测试跑完后统一检查泄漏，发现了就让**整个命令
退出码非零**。所以 CI 上会红。

⚠️ **这段输出里的地址（`addr: 10ca98010`、栈帧里的 `0x10c97d161`）每次运行都不同**，
不要把它们当固定值抄进文档或写进断言。

⚠️ 另一条纪律：`std.log.err` / `std.log.warn` 级别的输出会让 `zig test` 以非零码退出，
报 `N errors were logged.`。如果示例只是想演示日志而不希望测试失败，要么用
`std.debug.print`（走 stderr 但不计错误数），要么加 `if (builtin.is_test) return;` 守卫。

## 11.13 生命周期：alloc + errdefer free + 初始化 + 返回

内存 bug 的三大来源：**悬垂切片**（返回了栈上的东西）、**泄漏**（分配了但没释放）、
**用错分配器**（跨分配器 free）。前两个靠写法，第三个靠 panic。

### 惯用法：四步走

```zig
// examples/11_allocators/main.zig 第 78-95 行
const Sword = struct {
    stats: []u8,

    pub fn init(allocator: std.mem.Allocator, stats: []const u8) !*Sword {
        const self = try allocator.create(Sword);
        errdefer allocator.destroy(self); // 下面失败时，结构体本身不会漏
        self.stats = try allocator.alloc(u8, stats.len);
        errdefer allocator.free(self.stats);
        @memcpy(self.stats, stats);
        return self;
    }

    pub fn deinit(self: *Sword, allocator: std.mem.Allocator) void {
        allocator.free(self.stats);
        allocator.destroy(self);
    }
};
```

**`try` → `errdefer` → 初始化 → `return`**。每个 `try` 后面紧跟一句 `errdefer` 兜底，
于是"从第 k 步失败返回"时，前 k-1 步的分配全都会被释放。**每加一个 `try` 就加一行
`errdefer`**，这个纪律让"任意失败点都不漏"变成机械保证，而不是需要推理的事。

`init` / `deinit` 只是**社区惯例**，不是语言特性——但它和"分配器也作为参数传进去"这个
设计天然契合，所以成了事实标准。

### 陷阱：返回局部数组的切片

```zig
// examples/11_allocators/main.zig 第 59-66 行
/// 11.13 节：反面教材——返回栈上局部数组的切片。
/// Zig **不会**在这里报错（返回 `&局部变量` 才会），于是你拿到一个悬垂切片。
fn cursedScroll() []u8 {
    var spell: [5]u8 = .{ 'F', 'i', 'r', 'e', '!' };
    return spell[0..];
}
```

```text
==== 11.13 开始 ====
陷阱：cursedScroll() 返回局部数组的切片。期望 "Fire!"
  刚返回时内容还是原文吗？false（Debug 下栈上 undefined 填 0x00，常常已经是 false）
  再 memset(&pad, 'Z') 之后还是原文吗？false → **悬垂切片**（同一块栈被反复改写）
  Zig 只在返回 &局部变量 时报错；返回 局部数组的切片 是**合法但危险**的
  堆分配版本不受影响：Slash（内容稳定，因为不在栈上）
init/deinit 惯例：stats=Victory!（errdefer 已保证中途失败不漏）
  init/deinit **不是**语言特性，只是社区约定的成对写法；free 才是语言关键字
惯用法：try alloc → errdefer free → 初始化 → try后面每步都有兜底→ return
  少了 errdefer 那一行，多个分配点里任何一个失败都会漏前面已分配的那些
用错分配器 free：DebugAllocator 报 `Invalid free`；SafeAllocator 报 `free of invalid memory`或 corrupted metadata`
  两者都是 **panic**（进程终止），不是静默 UB——这是0.17 内存安全的一部分
==== 11.13 结束 ====
```

`cursedScroll()` 返回的切片指向**函数退出后就被复用的栈空间**。上面输出里两次判断都是
`false`——因为 `spell` 是 `var`（不是 `const`），编译器把它放在一个"退出后不保证保留"的
栈槽里，函数一返回那块位置就可以被任何后续调用覆盖。

⚠️ **这类悬垂切片的内容每次运行都不一样**（取决于栈上恰好残留了什么，可能是 `0x00`、
可能是上次的随机数、可能是别的函数留下的指针低位）。所以本节的示例刻意只打印
"还是原文吗？`true`/`false`"这种**断言性判断**，而不把具体字节抄进文档——那样抄出来的
数字下次跑就变了，读者会以为是 bug。真正要记住的是那个 `false`。

⚠️ **Zig 只在返回 `&局部变量` 时报错**（因为那逃逸了栈指针本身），返回
`局部数组[0..]` 是**完全合法**的——切片是"指针 + 长度"，编译器看不出你指向哪儿。
正确做法是拷到分配器上（`enchantedSword`）。

### 用错分配器会 panic，不是静默 UB

```text
thread 919281 panic: free of invalid memory [addr: 10d8cc018, len: 12 (0xc) align: 1] or corrupted metadata
lib/std/heap/SafeAllocator.zig:546:27: in startModify
    _ => panic(
lib/std/mem/Allocator.zig:165:25: in rawFree
    return a.vtable.free(a.ptr, memory, alignment, ret_addr);
```

（`thread 919281` 是线程 id、`addr: 10d8cc018` 是那块内存的地址——**两者每次运行都不同**，
这里保留是为了让你看清消息的形状：`panic: free of invalid memory [...] or corrupted
metadata`，关键是 `free of invalid memory` 这个短语和 `or corrupted metadata` 的并列表述。）

这是 0.17 内存安全的一部分：**分配器会核对每块内存的元数据**（地址范围、对齐、canary）。
用 arena 分配的内存交给 `init.gpa` 去 free，会当场 panic。开发期直接抓到，比上线后随机
崩溃好得多。

## 11.14 对齐分配：⚠️ 0.17 的 `Alignment` 是 log2 枚举

**这是本章最"反直觉"的 0.17 变化。** `std.mem.Alignment` 不再是"装一个字节数的结构体"，
而是**以 log2 为基整型的非穷尽枚举**：

```zig
// examples/11_allocators/main.zig 第 729-784 行（begin("11.14") 到 end("11.14")）节选
begin("11.14");
{
    // ⚠️ 0.17 的大变化：std.mem.Alignment 不再是"字节数结构体"，
    // 而是**以 log2 为基整型的非穷尽枚举**：enum(math.Log2Int(usize))。
    const A = std.mem.Alignment;
    std.debug.print("std.mem.Alignment 是 {s}，@sizeOf={d} 字节\n", .{ @typeName(A), @sizeOf(A) });
    std.debug.print("  成员只有 @\"1\"..@\"64\" 加一个非穷尽 `_`；128/256要靠 fromByteUnits 造\n", .{});
    std.debug.print("  .of(u64).toByteUnits() = {d}；.fromByteUnits(256).toByteUnits() = {d}，@backingInt = {d}\n", .{
        A.of(u64).toByteUnits(), A.fromByteUnits(256).toByteUnits(), @backingInt(A.fromByteUnits(256)),
    });
    std.debug.print("  ⚠️ @tagName(A.fromByteUnits(256)) 会 **panic: invalid enum value**（非穷尽枚举没有名字）\n", .{});

    // 对齐分配的四个入口
    const page = std.heap.page_allocator;
    const b = try page.alignedAlloc(u8, .@"64", 10);
    defer page.free(b);
    std.debug.print("alignedAlloc(u8, .@\"64\", 10)     → 类型 {s}，addr%64={d}\n", .{
        @typeName(@TypeOf(b)), @intFromPtr(b.ptr) % 64,
    });
    const c = try page.allocWithOptions(u8, 10, .fromByteUnits(128), null);
    defer page.free(c);
    const ac = try page.alignedCreate(u64, .fromByteUnits(256));
    defer page.destroy(ac);
    const combo = try page.allocWithOptions(u8, 4, .fromByteUnits(64), @as(u8, 0));
    defer page.free(combo);
    // ...
}
end("11.14");
```

```text
==== 11.14 开始 ====
std.mem.Alignment 是 mem.Alignment，@sizeOf=1 字节
  成员只有 @"1"..@"64" 加一个非穷尽 `_`；128/256要靠 fromByteUnits 造
  .of(u64).toByteUnits() = 8；.fromByteUnits(256).toByteUnits() = 256，@backingInt = 8
  ⚠️ @tagName(A.fromByteUnits(256)) 会 **panic: invalid enum value**（非穷尽枚举没有名字）
     @tagName(A.of(u64)) = 8，@tagName(A.@"8") = 8（≤64 才有名字）
alignedAlloc(u8, .@"64", 10)     → 类型 []align(64) u8，addr%64=0
allocWithOptions(u8,10,fromByteUnits(128),null) → 类型 []align(128) u8，addr%128=0
alignedCreate(u64, fromByteUnits(256))        → 类型 *align(256) u64，addr%256=0
allocWithOptions(u8,4,fromByteUnits(64),0)     → 类型 [:0]align(64) u8（对齐+哨兵一起要）
⚠️ 传字节数给 alignedAlloc 在 0.17 编译不过：
   const b = try a.alignedAlloc(u8, 64, 10);
   error: expected type '?mem.Alignment', found 'comptime_int'
   note: enum declared here / pub const Alignment = enum(math.Log2Int(usize))
   写 .@"64"（枚举成员）或 .fromByteUnits(64)（运行期算）才对
绝大多数时候不用管对齐——alloc 会自动按 @alignOf(T) 对齐：
alloc(u64,4) 的地址 % 8 = 0（自动 8 字节对齐，无需alignedAlloc）
零大小类型：@sizeOf(void)=0 @sizeOf(u0)=0 @sizeOf([0]u8)=0
alloc(T, 0) 合法且free 合法（长度为 0 的切片不需要真内存）
==== 11.14 结束 ====
```

### 0.17 对齐分配 API 的真实名字

| 方法 | 对齐参数类型 | 写法 | 返回类型 |
|---|---|---|---|
| `alignedAlloc(T, ?Alignment, n)` | `?Alignment`（**comptime**） | `a.alignedAlloc(u8, .@"64", 10)` | `Error![]align(64) u8` |
| `alignedCreate(T, ?Alignment)` | `?Alignment`（**comptime**） | `a.alignedCreate(u64, .fromByteUnits(256))` | `Error!*align(256) u64` |
| `allocWithOptions(T, n, ?Alignment, ?T)` | `?Alignment`（comptime） | `a.allocWithOptions(u8, 10, .fromByteUnits(128), null)` | `Error![]align(128) u8` |
| `allocSentinel(T, n, sentinel)` | — | `a.allocSentinel(u8, 5, 0)` | `Error![:0]u8` |

**三档写法，按场景选**：

- **编译期常量**（最常见）：直接写枚举成员 `."8"` / `."16"` / `."64"`。成员名就是字节数，
  因为枚举成员名可以是任意字符串（`@"64"` 这种写法在旧版本就支持了）。
- **超过 64 的对齐**：枚举只列了 1..64，其余靠 `_` 非穷尽。用
  `.fromByteUnits(256)`（`assert(isPowerOfTwo(n))` 然后 `@fromBackingInt(@ctz(n))`），
  或 `.fromByteUnitsOptional(null)` 拿可空版。
- **类型已知**：`Alignment.of(T)` 直接给出 T 的自然对齐（内部就是
  `fromByteUnits(@alignOf(T))`）。

### ⚠️ 三个实测到的报错

**① 传字节数给 `alignedAlloc` 编译不过**（老教程的写法）：

```text
error: expected type '?mem.Alignment', found 'comptime_int'
note: enum declared here
pub const Alignment = enum(math.Log2Int(usize)) {
```

**② 超过 64 的对齐不能用 `.@"128"`**（哪怕 `."128"` 看起来很对称）：

```text
error: enum 'mem.Alignment' has no member named '128'
note: enum declared here
pub const Alignment = enum(math.Log2Int(usize)) {
```

必须用 `.fromByteUnits(128)`。

**③ `@tagName` 在非穷尽枚举上会 panic**：

```text
thread 942506 panic: invalid enum value
/private/tmp/zprobe/e7.zig:4:32: in main
    std.debug.print("{s}\n", .{@tagName(al)});
                               ^
```

因为 128/256 对应的枚举值不在具名成员里，`@tagName` 找不到名字。打印 `Alignment` 要用
`.toByteUnits()` 或 `.{d}`（内部 `formatInt`），不要用 `{s}` + `@tagName`。

### 大多数时候你不需要管对齐

输出倒数第 3 行：`alloc(u64, 4) 的地址 % 8 = 0`。**`alloc` 会自动按 `@alignOf(T)`
对齐**——`u64` 要 8 字节对齐，它就给 8。只有当你要的类型需要**比自然对齐更强的对齐**
（比如 SIMD 的 `u8x32` 要 32、缓存行填充结构体要 64）时才需要 `alignedAlloc`。

## 11.15 什么时候不该分配

回到 11.5 节的量级：栈比堆快三个数量级。**默认答案是"不分配"。**

```zig
// examples/11_allocators/main.zig 第 787-820 行（begin("11.15") 到 end("11.15")）节选
begin("11.15");
{
    const runtime_len: usize = 8;
    var stack_buf: [64]u8 = undefined;
    std.debug.print("长度编译期已知 → 用 [N]T，长度运行期才知道 → 才考虑分配\n", .{});
    std.debug.print("  栈：var buf: [{d}]u8 = undefined;（{d} 字节栈空间，零分配）\n", .{ runtime_len, 64 });
    @memset(stack_buf[0..runtime_len], 'x');
    std.debug.print("  堆：const p = try a.alloc(u8, {d}); defer a.free(p);\n", .{runtime_len});
    std.debug.print("BufferFirstAllocator 就是这两者的自动桥：小的走栈缓冲，大的自动落底层\n", .{});

    // ArrayList 内部就是"增长式重新分配"，但外部看不见
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(a);
    for (0..8) |i| try list.append(a, @intCast('0' + i));
    std.debug.print("  内容={s}，arena 容量={d}（8 次append 只涨到这么多）\n", .{ list.items, arena.queryCapacity() });
    std.debug.print("判断清单：① 大小编译期已知？→ 栈。② 一批东西同生共死？→ arena。③ 都不成立 → gpa\n", .{});
}
end("11.15");
```

```text
==== 11.15 开始 ====
长度编译期已知 → 用 [N]T，长度运行期才知道 → 才考虑分配
  栈：var buf: [8]u8 = undefined;（64 字节栈空间，零分配）
  堆：const p = try a.alloc(u8, 8); defer a.free(p);
BufferFirstAllocator 就是这两者的自动桥：小的走栈缓冲，大的自动落底层
arena 里32 字节的东西也可以放栈上——arena 只解决"批量回收"，不解决"该不该分配"
  栈上版本首字节 = A，arena 版本首字节 = ?（都没初始化过，内容无意义）
  在 arena 上 "忘记 free" 不是 bug（批量回收兜着），这正是它比 gpa 省心的地方
ArrayList 内部反复 realloc，但调用方只写 append —— 12 章展开
  内容=01234567，arena 容量=290（8 次append 只涨到这么多）
判断清单：① 大小编译期已知？→ 栈。② 一批东西同生共死？→ arena。③ 都不成立 → gpa
==== 11.15 结束 ====
```

### 判断清单

- **① 大小编译期已知？→ 用栈上 `[N]T`。** 本机栈约 8MB，但一个函数里超过几十 KB 就该警惕
  （尤其在递归里）。
- **② 一批东西同生共死？→ arena。** 解析一批 token、构造一棵 AST、处理一个请求。
- **③ 都不成立 → gpa**（`init.gpa`，Debug 模式下带泄漏检测）。
- **④ 只是"想省一次系统调用" → `BufferFirstAllocator`。** 让上面三种的选择自动化。

另外：`alloc(T, 0)` 是合法的（长度 0 的切片不需要真内存），`free` 它也合法——这让
"分配长度可能为 0"的代码不需要特殊分支。
## 11.16 零大小类型与 peer type resolution

零大小类型（ZST）是"分配器哲学"的直接推论：**如果类型大小是 0，分配它根本不碰内存**。`@sizeOf` 对这类类型返回 0，于是它们可以塞进任何容器当"无成本"的值。

```zig
// examples/11_allocators/main.zig 第 823-860 行（begin("11.16") 到 end("11.16")）
begin("11.16");
{
    std.debug.print("@sizeOf(void)={d}  @sizeOf(u0)={d}  @sizeOf([0]u8)={d}\n", .{
        @sizeOf(void), @sizeOf(u0), @sizeOf([0]u8),
    });
    std.debug.print("*anyopaque 是 {d} 字节的指针；@sizeOf(anyopaque) 是编译错误（无法实例化）\n", .{
        @sizeOf(*anyopaque),
    });

    // void 把HashMap 变成 Set
    var set = std.AutoHashMap(u32, void).init(init.gpa);
    defer set.deinit();
    try set.put(42, {}); // ⚠️ 0.17：void{} 已移除，写const b: void = {};
    try set.put(7, {});
    std.debug.print("HashMap(u32, void) 当集合用：count={d}，含 42？{}，含 9？{}\n", .{
        set.count(), set.contains(42), set.contains(9),
    });
    _ = set.remove(42);
    std.debug.print("删掉 42 后 count={d}（值类型不占空间，但键仍在表里）\n", .{set.count()});

    // peer type resolution：cond 必须是运行期值，否则编译器直接取走那一条分支
    var seed: u8 = 1;
    const cond = @intFromPtr(&seed) % 2 == 0;
    const peer = if (cond) @as(u8, 1) else @as(u16, 300);
    std.debug.print("peer type resolution：u8 与 u16 分支统一成 {s}（取能装下两者的最小类型）\n", .{@typeName(@TypeOf(peer))});
    const peer2 = if (cond) "abc" else @as([]const u8, "xy");
    std.debug.print("数组字面量与切片分支统一成 {s}\n", .{@typeName(@TypeOf(peer2))});
    const peer3 = if (cond) @as(?u32, 7) else @as(?u32, null);
    std.debug.print("optional 与非 optional 分支统一成 {s}（可选性取并集）\n", .{@typeName(@TypeOf(peer3))});
    const SentinelOrNot = if (cond) @as([]u8, undefined) else @as([:0]const u8, "x");
    std.debug.print("哨兵切片 [:0]u8 与普通切片 []u8 统一成 {s}（哨兵信息丢失）\n", .{
        @typeName(@TypeOf(SentinelOrNot)),
    });
}
end("11.16");
```

运行输出（`examples/11_allocators/main.zig`）：

```text
==== 11.16 开始 ====
@sizeOf(void)=0  @sizeOf(u0)=0  @sizeOf([0]u8)=0
*anyopaque 是 8 字节的指针；@sizeOf(anyopaque) 是编译错误（无法实例化）
HashMap(u32, void) 当集合用：count=2，含 42？true，含 9？false
删掉 42 后 count=1（值类型不占空间，但键仍在表里）
peer type resolution：u8 与 u16 分支统一成 u16（取能装下两者的最小类型）
数组字面量与切片分支统一成 []const u8
optional 与非 optional 分支统一成 ?u32（peer resolution 的第二条规则：可选性取并集）
哨兵切片 [:0]u8 与普通切片 []u8 在 if/else 里统一成 []const u8（丢掉了哨兵信息）
  → 如果两条分支一个带哨兵一个不带，编译器无法解析，只能自己点名类型
==== 11.16 结束 ====
```

**`HashMap(K, void)` 就是集合（Set）**。`void` 占 0 字节，所以每个条目只有键的开销——这是"用哈希表实现集合"的标准做法，也是"标记存在性"（比如 visited 集合、已访问节点集合）的标准写法。删掉 42 后 `count` 从 2 变 1，说明键确实被移除了（值类型不占空间，但键仍在表里这句话说的是**没删之前**的状态）。

⚠️ **0.17 里 `void{}` 已被移除**。想往 `HashMap(K, void)` 里 `put` 一个"空值"，写
`const marker: void = {};` 然后 `put(key, marker)`——本示例的测试块里就是这么写的
（`examples/11_allocators/main.zig` 的 `test "零大小类型：void 把HashMap 变成 Set"`）。

**peer type resolution** 是 0.17 新增的 `if`/`else` 类型解析规则：当两个分支类型不同，
编译器自动找一个"peer type"（能同时容纳两者的类型）作为结果。实测三条规则：

- **数值**：取能装下两者的最小类型。`u8` 与 `u16` → **`u16`**。
- **数组/切片**：`"abc"`（`*const [3:0]u8`）与 `[]const u8` → **`[]const u8`**。
- **可选性取并集**：`?u32` 与 `?u32` → `?u32`；非 optional 分支会自动提升成 optional。

⚠️ **哨兵切片 `[:0]u8` 与普通切片 `[]u8` 会解析成 `[]const u8`，哨兵信息丢失**——这是分配器
章节唯一真正常见的类型陷阱（因为 `dupeSentinel` / `allocSentinel` 的返回值都带哨兵）。
要保留哨兵就自己点名类型：`const x: [:0]u8 = if (cond) a else b;`。

## 11.17 线程安全与 `init.gpa`

```zig
// examples/11_allocators/main.zig 第 135-140 行
/// 11.17 节：4 个线程各自向 smp_allocator 申请/归还。
fn worker(done: *std.atomic.Value(u32)) void {
    const a = std.heap.smp_allocator;
    const block = a.alloc(u64, 32) catch return;
    defer a.free(block);
    @memset(block, 1);
    _ = done.fetchAdd(1, .monotonic);
}
```

```zig
// examples/11_allocators/main.zig 第 863-905 行（begin("11.17") 到 end("11.17")）节选
begin("11.17");
{
    var done = std.atomic.Value(u32).init(0);
    var threads: [4]std.Thread = undefined;
    for (&threads) |*t| t.* = try std.Thread.spawn(.{}, worker, .{&done});
    for (threads) |t| t.join();
    std.debug.print("4 个线程各自向 smp_allocator 申请/归还：完成 {d} 个\n", .{done.load(.monotonic)});

    // 各分配器的线程安全声明
    std.debug.print("ArenaAllocator 有 threadSafeAllocator()={}（0.17 没有，安全性随child_allocator 走）\n", .{
        @hasDecl(std.heap.ArenaAllocator, "threadSafeAllocator"),
    });
    std.debug.print("FixedBufferAllocator 有 threadSafeAllocator()={}（多线程共享一块缓冲时用它）\n", .{
        @hasDecl(std.heap.FixedBufferAllocator, "threadSafeAllocator"),
    });

    // init.gpa / init.arena / init.io
    std.debug.print("init.gpa   = {s}：进程级堆\n", .{@typeName(@TypeOf(init.gpa))});
    std.debug.print("init.arena = {s}：进程级 arena，退出才整体回收（免掉满地的 free）\n", .{@typeName(@TypeOf(init.arena))});
    const perm = try init.arena.allocator().alloc(u8, 32);
    @memset(perm, 'A');
    std.debug.print("init.arena 分 32 字节：{s}（不用 free，进程退出自动回收）\n", .{perm[0..4]});

    // 签名纪律
    std.debug.print("签名纪律：fn f(alloc: std.mem.Allocator) **按值传**（接口就是胖指针）\n", .{});
}
end("11.17");
```

运行输出（`examples/11_allocators/main.zig`）：

```text
==== 11.17 开始 ====
4 个线程各自向 smp_allocator 申请/归还：完成 4 个
ArenaAllocator 有 threadSafeAllocator()=false（0.17 没有，只有 child_allocator 的线程安全性随底层走）
FixedBufferAllocator 有 threadSafeAllocator()=true（多线程共享一块缓冲时用它）
BufferFirstAllocator 有 threadSafeAllocator()=false
DebugAllocator 配置项thread_safe 默认 = !builtin.single_threaded（本机 = false）
init.gpa   = mem.Allocator：进程级堆
init.arena = *heap.ArenaAllocator：进程级 arena，退出才整体回收（免掉满地的 free）
init.io    = Io：带缓冲的 I/O
init.arena 分 32 字节：AAAA（不用 free，进程退出自动回收）
⚠️ 0.17 的 init.gpa 在 Debug/Safe 模式下是 **SafeAllocator**（不是 DebugAllocator）：
  start.zig: const use_safe_allocator = switch (builtin.mode) { .debug, .safe => true, ... }
  var safe_allocator: std.heap.SafeAllocator = .init(std.heap.page_allocator, .{});
  它的 deinit() 返回**泄漏块数 usize**（不是 heap.Check 枚举），且"泄漏不影响返回码"
  本节实测：main 结束时 init.gpa 若有泄漏，stderr 会出现 [SafeAllocator] (err): leaked [addr: ...]
  但 `zig build-exe &&./prog` 的**退出码仍然是 0** —— 想要失败必须自己查（见 11.12 节）
签名纪律：fn f(alloc: std.mem.Allocator) **按值传**（接口就是胖指针）
  写 *std.mem.Allocator 会得到：error: expected type '*mem.Allocator', found '*const mem.Allocator'
  因为 allocator() 返回的值是 const 的，取地址得到 *const；接口本身不需要可变
==== 11.17 结束 ====
```

### 各分配器的线程安全

| 分配器 | 线程安全 | 说明 |
|---|---|---|
| `smp_allocator` | ✅ | 设计目标就是多线程：每线程独立 freelist + 无锁快路径 |
| `page_allocator` | ✅ | 系统调用本身安全 |
| `SafeAllocator` | ✅ | 源码注释直接写 "Thread-safe" |
| `DebugAllocator` | 配置项 | `.{ .thread_safe = true }`，默认 `!builtin.single_threaded` |
| `FixedBufferAllocator` | ❌（默认）/ ✅ | 多线程共享要用 `threadSafeAllocator()` |
| `ArenaAllocator` | 随 child | 0.17 **没有** `threadSafeAllocator()`，安全性继承底层 |
| `BufferFirstAllocator` | 随底层 | 同上 |

**"随底层"是什么意思**：arena 自己只在 `end_index` 上做非原子加减。如果两个线程同时用
同一个 arena 实例，就会有数据竞争。但如果你**每个线程一个 arena 实例**（各自的局部变量），
它们底层都是 `page_allocator`（线程安全），那就没问题。**分配器的线程安全性永远要问
"谁在调用它"，不是"它自己安不安全"。**

### `init.gpa` 到底是什么

`std.process.Init` 的 `gpa` 字段（类型 `std.mem.Allocator`）在 0.17 里按模式选实现
（`lib/std/start.zig` 第 794-803 行）：

```zig
const use_safe_allocator = !is_wasm and switch (builtin.mode) {
    .debug, .safe => true,
    .fast, .small => !builtin.link_libc and builtin.single_threaded,
};
const gpa = if (use_safe_allocator)
    safe_allocator.allocator()          // SafeAllocator
else if (builtin.link_libc)
    std.heap.c_allocator
else if (is_wasm)
    std.heap.wasm_allocator
else if (!builtin.single_threaded)
    std.heap.smp_allocator
else
    comptime unreachable;
```

⚠️ 所以：**Debug/Safe 模式下 `init.gpa` 是 `SafeAllocator`，不是 `DebugAllocator`**
（老教程这么写的）。而且 `start.zig` 里那行 `defer` 的注释很关键：

```zig
defer if (use_safe_allocator) {
    _ = safe_allocator.deinit(); // Leaks do not affect return code.
};
```

——**`init.gpa` 泄漏不会让进程退出码非零**。想在 `main` 里因泄漏失败，得自己查（11.12 节）。

`init.arena`（类型 `*heap.ArenaAllocator`）是**进程级 arena**，随进程退出整体回收——
用来放那些"整个进程都要活着"的东西（环境变量表、`argv` 副本），省掉满地的 `free`。
本节实测从它分 32 字节，打印 `AAAA`，不需要 `free`。

### 签名纪律：`Allocator` 按值传

```zig
fn parseLine(arena: std.mem.Allocator, line: []const u8) ![]const []const u8 { ... }  // ✅
fn parseLine(arena: *std.mem.Allocator, line: []const u8) !void { ... }               // ❌
```

写 `*std.mem.Allocator` 实测报错：

```text
error: expected type '*mem.Allocator', found '*const mem.Allocator'
note: cast discards const qualifier
note: parameter type declared here
fn f(alloc: *std.mem.Allocator) !void {
```

原因很直白：`allocator()` 返回的值是 `const` 的，取地址得到 `*const Allocator`；而且
**接口本身就是胖指针**（ptr + vtable），再套一层指针只是多一次间接寻址，还诱导读者
以为"分配器状态需要可变"——实际上 `alloc` 的所有修改都发生在 `ptr` 指向的那个分配器
对象上（实现里通过 `@ptrCast(@alignCast(ctx))` 拿到可变指针），接口值本身从不变。## 11.18 测试：把本章语义钉住

本章 15 个 `test` 块全部用 `std.testing.allocator`（带泄漏检测）：

```text
$ zig test main.zig
1/15 main.test.接口值是 16 字节胖指针，vtable 四个槽位...OK
2/15 main.test.自研分配器：记账准确，noResize/noRemap 占位可用...OK
3/15 main.test.全家族：alloc / create / dupe / dupeSentinel / allocSentinel / print...OK
4/15 main.test.resize 与 realloc：page_allocator 能缩不能扩...OK
5/15 main.test.OOM 是返回值：FixedBufferAllocator 满了返回 error.OutOfMemory...OK
6/15 main.test.FixedBufferAllocator 只对最后一块 free 生效，reset 归零...OK
7/15 main.test.BufferFirstAllocator：小的走栈缓冲，大的自动落到底层...OK
8/15 main.test.ArenaAllocator：一次 deinit 回收全部，单个 free 是 no-op...OK
9/15 main.test.DebugAllocator 与 SafeAllocator 的 deinit 返回值不同...OK
10/15 main.test.对齐分配：Alignment 是 log2 枚举，≤64 才有名字...OK
11/15 main.test.FailingAllocator：fail_index逐条走OOM 路径...OK
12/15 main.test.checkAllAllocationFailures：每一条 OOM 路径都不许漏...OK
13/15 main.test.errdefer 惯用法：alloc → errdefer free → 初始化 → 返回...OK
14/15 main.test.零大小类型：void 把HashMap 变成 Set...OK
15/15 main.test.零大小类型与peer type resolution...OK
All 15 tests passed.
```

几个测试值得单独说。**第 2 个**把 `CountingAllocator` 的记账钉死（分配 2 次、在用 132 字节、
`resize` 返回 `false`、`remap` 返回 `null`）——证明 11.2 节那个手写分配器真的符合接口
契约。**第 9 个**同时断言两种 `deinit` 的返回类型差异：
`expectEqual(std.heap.Check.ok, da.deinit())`（枚举）对 `expectEqual(@as(usize, 0),
sa.deinit())`（块数）。**第 11 个**把 `FailingAllocator` 的三个记账字段钉死
（`alloc_index` 停在 2 不计失败那次、`allocated_bytes` 只算成功的、`has_induced_failure`
为 `true`）。**第 12 个**用 `checkAllAllocationFailures` 跑 `exerciseSafe`，这条测试
本身就是"每条 OOM 路径都不漏"的机器证明。

⚠️ 写这类测试有个反复踩的坑：**`alloc` 返回 `undefined` 内存，别直接拿去断言**。本教程
实测堆上的 `undefined` 在 Debug 下被填 `0xaa`——所以第 3 个测试一开始写成

```zig
const nums = try a.alloc(u32, 4);
try std.testing.expectEqualSlices(u32, &.{ 1, 2, 3, 4 }, nums);   // ❌ 读到 0xAAAAAAAA
```

直接失败。必须先逐个赋值（`nums[0] = 1; ...`）再断言。

## 11.18 坑位清单

1. **`std.heap.stackFallback` 已移除**，继任者是 `std.heap.BufferFirstAllocator`
   （语义一致：先试栈上缓冲，容纳不下自动落到底层）。老写法报
   `error: root source file struct 'heap' has no member named 'stackFallback'`。
   初始化从 `stackFallback(allocator, &buf)` 变成
   `BufferFirstAllocator.init(&buf, allocator)`——**注意参数顺序反了**。

2. **`std.mem.Alignment` 在 0.17 是以 log2 为基整型的非穷尽枚举**
   （`enum(math.Log2Int(usize))`，`@sizeOf = 1`），不再是"装字节数的结构体"。所以
   `alignedAlloc(T, 64, n)` 报 `expected type '?mem.Alignment', found 'comptime_int'`；
   `."128"` 报 `enum 'mem.Alignment' has no member named '128'`（要写
   `.fromByteUnits(128)`）；`@tagName(A.fromByteUnits(256))` 报
   `panic: invalid enum value`（非穷尽枚举没名字，打印要用 `.toByteUnits()`）。

3. **`dupeZ` 已移除**，继任者是 `dupeSentinel(comptime T, m, comptime sentinel)`。
   老写法报 `no field or member function named 'dupeZ' in 'mem.Allocator'`。返回值类型
   从固定的 `[:0]T` 变成 `:sentinel`。

4. **`std.testing.allocator` 的真身从 `DebugAllocator` 换成了 `SafeAllocator`**。
   连带两个后果：`deinit()` 返回类型从 `std.heap.Check` 枚举变成 **`usize` 泄漏块数**；
   在 `main` 里用它是编译错误 `lib/std/testing.zig:21:80: error: not testing`
   （被 `builtin.is_test` 守卫）。`init.gpa` 在 Debug/Safe 模式下也是 `SafeAllocator`
   （`start.zig` 的 `use_safe_allocator`），且**它的泄漏不影响进程退出码**。

5. **`std.heap.stackFallback` / `dupeZ` 这类移除会让大量旧代码直接编译失败**；
   而 `std.heap.DebugAllocator(.{}){}` 这种"默认初始化"虽然 0.17 源码注释写着
   *deprecated*，**实测仍能编译**（新写法是 `var da: std.heap.DebugAllocator(.{}) = .init;`）。
   遇到分不清的时候，写探针编译一遍比翻记忆可靠。

6. **`SmpAllocator` 是单例，没有 `init` 也没有 `allocator()`**
   （`@hasDecl` 两个都是 `false`）。只有 `std.heap.smp_allocator` 这一个值可用。
   同理 `page_allocator` / `c_allocator` / `brk_allocator` / `wasm_allocator` 都是
   `std.mem.Allocator` 类型的单例，`@typeName` 全都打印 `mem.Allocator`。

7. **`free` 必须传回当初那个切片**（起点 + 长度 + 对齐都要对上）。改过长度的切片还回去
   会 panic：`DebugAllocator` 报 `Invalid free`，`SafeAllocator` 报
   `free of invalid memory [addr: ..., len: ...] or corrupted metadata`。
   跨分配器 free 同样 panic——0.17 把这类 UB 变成了崩溃，是内存安全的一部分。

8. **堆上的 `undefined` 填 `0xaa`，栈上的填 `0x00`**。`alloc` 返回的内存没初始化，
   Debug 下读到 `2863311530`（`0xAAAAAAAA`）。别把它当"随机垃圾"——它是确定的，
   但**读它仍然是未定义行为**，写测试时尤其要注意（直接 `expectEqualSlices` 会失败）。

9. **跨分配器/漏释放的检测报告里含内存地址，每次运行都不同**
   （`memory address 0x... leaked`、`[SafeAllocator] (err): leaked [addr: ...]`）。
   这些**不要写进断言或文档的"固定输出"**。文档里应该写成断言性表述 + 说明"地址每次不同"。

10. **arena 里的单个 `free` 是合法的 no-op，内存不归还给底层**。别把"看起来能 free"当成
    在 arena 上做细粒度管理的理由。`FixedBufferAllocator` 的 `free` 也只对**最后一块**
    有效（乱序 free 内存不会还），想整块复用要 `reset()`。

11. **`page_allocator` 不适合做小分配**：每次分配都是 `mmap`/`munmap`（本机实测 6881
    ns/次，是 FixedBufferAllocator 的约 60 倍），而且 100 字节的请求也占满一整页
    4096 字节（利用率 2.4%）。它是**别的分配器的底座**。

12. **测试里泄漏了会出现"`All N tests passed.` 和 `1 tests leaked memory.` 同时出现"的
    反直觉现象**——每个测试函数本身通过，但运行器在最后统一检查泄漏并让整个命令退出码
    非零。另外 `std.log.err` 级别的输出也会让 `zig test` 以非零码退出（报
    `N errors were logged.`）；只想演示日志就用 `std.debug.print`，或加
    `if (builtin.is_test) return;` 守卫。

13. **`toNanoseconds()` 返回 `i64`，用 `{d}` 打印会带正号**（`+8` 而不是 `8`）。格式化
    宽度语法是 `{d:>7}`（补空格）或 `{d:_>7}`（补下划线）；想打印"非法"的格式串会报
    `invalid format string 'xx' for type 'comptime_int'`，想用动态 specifier（如 `{d:x}`）
    在 0.17 的 `std.debug.print` 里也不行（报 `expected . or }, found 'x'`）——先把值转成
    你想要的类型。

14. **`builtin.mode` 在 0.17 是小写 `.debug` / `.safe` / `.fast` / `.small`**
    （0.16 及更早是 `.Debug` 等大写）。写 `builtin.mode == .Debug` 编译失败。

15. **签名纪律：`fn f(alloc: std.mem.Allocator)` 按值传**。接口本身是胖指针（16 字节），
    套 `*std.mem.Allocator` 会得到 `expected type '*mem.Allocator', found '*const
    mem.Allocator'`——因为 `allocator()` 返回的是 `const` 值，且接口状态本来就在 `ptr`
    指向的对象上，不需要通过接口值本身可变。

16. **`std.ArrayList` 在 0.17 用 `.empty` 初始化**（不是 `init(allocator)`），
    `append` / `appendSlice` 要显式传分配器（`try list.append(a, x)`），
    `toOwnedSlice(allocator)` 会把元素所有权转交并清空原容器。`std.BoundedArray` 已不存在。

---

上一章：[10 错误 II](10-errors-advanced.md) · 下一章：[12 集合](12-collections.md)