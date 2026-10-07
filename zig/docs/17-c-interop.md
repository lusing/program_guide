# 17 · C 互操作 ⭐

> 对应示例：`examples/17_cinterop/`（**build.zig 工程**，0.17 起不再是 `zig build-exe … -lc`）
>
> "Zig 是一门更好的 C"的另一面：**和 C 无缝互认**。没有 FFI 层、没有绑定生成器门槛。
>
> ⚠️ **本章按 0.17 重写**。0.17 把 `@cImport` 从语言里**移除**了，
> 头文件翻译改由构建系统发起。如果你手上有一份 0.16 时代的
> `const c = @cImport({ @cInclude("stdio.h"); })`，在 0.17 下会得到
> `error: invalid builtin function: '@cImport'`。
> 完整的迁移对照见 [00 · 0.16 → 0.17 迁移手册](00-migration-0.17.md)。

---

## 17.1 extern fn：手写 C 声明

想调一个 libc 函数，最直接的办法是手写一行声明，不碰任何头文件：

```zig
// src/main.zig
extern fn printf(format: [*:0]const u8, ...) c_int;   // 变参 C 函数

export fn zig_add(a: i32, b: i32) callconv(.c) i32 {
    return a + b;
}

pub fn main() !void {
    _ = printf("printf 直连：zig_add(3,4)=%d\n", zig_add(3, 4));
}
```

```text
printf 直连：zig_add(3,4)=7
```

`extern fn` 声明"这函数在 C 那边"——签名对上 C ABI 就直接链接调用。

几个类型映射要点：

- **`c_int` / `c_char` / `c_uint`** 等（`std.c` 里全家福）对应 C 的定宽类型。
  不要直接用 `i32`/`u8`——在大多数平台上它们一样，但**语义上**你在说
  "这是一个 C 的 int"，写 `c_int` 才对得起这份声明。
- **C 字符串是 `[*:0]const u8`**：哨兵指针（很多个可能的结尾），
  不是切片——因为 C 那边没有长度，这是 06 章讲过的"胖指针 vs 哨兵指针"。
- **变参函数用 `...` 收尾**，且从此**放弃类型检查**：`printf` 的格式串
  和参数对不对得上，Zig 不再验证（`std.debug.print` 才享受编译期检查）。
- **普通字符串字面量就是 0 结尾的**（`*const [N:0]u8` 自动退化），
  可以直接传给 `[*:0]const u8` 形参，不需要任何转换。
  旧的 `c"..."` 前缀字面量在 0.16 就已经移除了。

`extern` 和 `export` 一进一出：Zig 代码可以嵌进任何 C 工程，
甚至只把 Zig 当"更好的 C 编译器"用。

## 17.2 整头文件拿进来：b.addTranslateC

上面手写声明只适合一两个函数。要把**整个头文件**（几十个函数、
一堆宏、层层嵌套的 `#include`）变成 Zig 能用的声明，0.17 的做法是
**让构建系统去翻译**，然后把产物当成一个普通模块 import 进来。

先看 C 侧长什么样（`examples/17_cinterop/include/ci.h`）：

```c
#include <stddef.h>

int ci_add(int a, int b);
int ci_triple(int a);
size_t ci_strlen(const char *s);
int ci_strcmp(const char *a, const char *b);

// 从 Zig 侧导出的函数（Zig 用 export + callconv(.c) 实现）
int zig_add(int a, int b);
const char *zig_version(void);
```

实现放在 `csrc/ci.c`：

```c
#include "ci.h"
#include <string.h>

int ci_add(int a, int b) { return a + b; }
int ci_triple(int a) { return a * 3; }

size_t ci_strlen(const char *s) { return strlen(s); }
int ci_strcmp(const char *a, const char *b) { return strcmp(a, b); }

// 调用 Zig 导出的函数：C 侧完全看不出对面是 Zig
int ci_call_zig_add(int a, int b) { return zig_add(a, b); }
```

然后是全部的胶水——`build.zig`（节选，完整版见 `examples/17_cinterop/build.zig`）：

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ① 翻译头文件 → 一个名为 ci 的 Zig 模块
    const tc = b.addTranslateC(.{
        .root_source_file = b.path("include/ci.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,          // strlen/strcmp 在 libc 里
    });
    const ci_module = tc.createModule();   // 私有模块：只给本工程用

    // ② Zig 主模块：imports 里挂上翻译结果，并把 C 源文件一起链接
    const main_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .imports = &.{
            .{ .name = "ci", .module = ci_module },
        },
    });
    main_mod.addCSourceFiles(.{
        .root = b.path("csrc"),
        .files = &.{"ci.c"},          // 节选：完整的见下面第二段
        .flags = &.{ "-I", "include" },
    });
    // …（exe / run / test 三个 step，见 16 章）
}
```

本例还有第二个头文件 `include/ci_ext.h`（结构体 / 数组 / 函数指针，见 17.4），
所以 `addTranslateC` 也调了第二次，`imports` 里挂两个模块：

```zig
    const tc_ext = b.addTranslateC(.{
        .root_source_file = b.path("include/ci_ext.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const ci_ext_module = tc_ext.createModule();
    // …
    .imports = &.{
        .{ .name = "ci", .module = ci_module },
        .{ .name = "ci_ext", .module = ci_ext_module },
    },
    // …
    .files = &.{ "ci.c", "ci_ext.c" },
```

`addTranslateC` 可以调任意多次，每次产出一个独立命名的模块，互不干扰——
想按功能把头文件分组时就这么用。

Zig 侧只剩一行 import（`src/main.zig`）：

```zig
const ci = @import("ci");

std.debug.print("ci_add(3,4)        = {d}\n", .{ci.ci_add(3, 4)});
std.debug.print("ci_triple(7)       = {d}\n", .{ci.ci_triple(7)});
std.debug.print("ci_strlen(\"hello\") = {d}\n", .{ci.ci_strlen("hello")});
std.debug.print("ci_strcmp(\"ab\",\"ab\") = {d}（相等为 0）\n", .{ci.ci_strcmp("ab", "ab")});
```

```text
ci_add(3,4)        = 7
ci_triple(7)       = 21
ci_strlen("hello") = 5
ci_strcmp("ab","ab") = 0（相等为 0）
size_t 在 Zig 侧的类型 = usize
```

最后那行是个很好的观察点：头文件里的 `size_t` 翻译过来是
`@TypeOf(ci.ci_strlen("x"))`，打印出来就是 `usize`——
**头文件里的宏会被翻译成 comptime 常量**，
`#include` 会被展开，你不需要自己再声明一遍。

### 为什么 0.17 要这么改？

这不是倒退，而是把"C 头文件处理"从**编译期搬到了构建期**：

- 0.16 的 `@cImport` 藏在源码里，编译器在解析每个文件时才想起要跑 clang，
  缓存粒度天然按文件走；
- 0.17 里翻译是一个**独立的构建步骤**（`addTranslateC`），
  它的产物是一个有名字的模块，能被单独依赖、单独缓存、单独审查；
- 更重要的是**可复现**：翻译产物落在 `.zig-cache/` 里，
  CI 上"这次用了哪份头文件翻译结果"是有迹可循的，
  而不是"编译器那天心情好解析出来的"。

同时它也把 `@cInclude` 一起废掉了——没有"在源码里随手 include 一个头"
这种写法了，所有 C 依赖都必须显式声明在 `build.zig` 里。

`link_libc = true` 还是要写：翻译出来的声明只是**声明**，
真正拿 `strlen`/`strcmp` 的实现还在 libc 里，不链就报
`undefined symbol`，不是"headers not available"了（那是更老的 0.11 时代）。

## 17.3 export fn：反向导出

```zig
// src/main.zig
const version: [:0]const u8 = "0.17.0";

export fn zig_version() callconv(.c) [*:0]const u8 {
    return version.ptr;
}
```

```c
// C 侧（csrc/ci.c）反过来调它
int ci_call_zig_add(int a, int b) { return zig_add(a, b); }
```

```text
zig_version() 返回 0.17.0
C 侧回调 zig_add(20,22) = 42
```
`export fn` 让 Zig 函数以 C 调用约定导出——C/Python/wasm（18 章）都能调它。
配套的 `@export(variable, .{ .name = "..." })` 能导出全局变量。

⚠️ **0.17 改名：`callconv(.C)` → `callconv(.c)`（小写）**。
照抄旧代码会得到
`error: union 'lang.CallingConvention' has no member named 'C'`。

导出字符串时的要点：C 没有所有权概念，`return version.ptr` 返回的是
**全局常量的裸指针**，谁分配谁释放这句话在这里的答案是"**谁都不释放**"。
如果你导出的是动态分配的内存，就必须在文档里写清楚由谁 `free`。

```text
zig_version() 返回 0.17.0
C 侧回调 zig_add(20,22) = 42
C 侧用 Zig 函数指针 zig_op_max(3,9) = 9
```

`export fn` 让 Zig 函数以 C 调用约定导出——C/Python/wasm（18 章）都能调它。
配套的 `@export(variable, .{ .name = "..." })` 能导出全局变量。

⚠️ **0.17 改名：`callconv(.C)` → `callconv(.c)`（小写）**。
照抄旧代码会得到
`error: union 'lang.CallingConvention' has no member named 'C'`。

导出字符串时的要点：C 没有所有权概念，`return version.ptr` 返回的是
**全局常量的裸指针**，谁分配谁释放这句话在这里的答案是"**谁都不释放**"。
如果你导出的是动态分配的内存，就必须在文档里写清楚由谁 `free`。

### 反向的极致：把 Zig 函数当"函数指针"交给 C

`export fn` 的地址就是一份合法的 C 函数指针。C 侧定义 typedef、
Zig 侧提供实现、把指针传过去，两边都不需要写胶水。

C 侧（`include/ci_ext.h`）：

```c
typedef int (*ci_op_t)(int, int);
int ci_apply_op(ci_op_t op, int a, int b);
```

Zig 侧——注意**实现本身仍然是 `export fn`**，只是多了一个
`&` 取地址（`include/ci_ext.h` 里的 `ci_op_t` 被翻译成
`?*const fn (c_int, c_int) callconv(.c) c_int`）：

```zig
export fn zig_op_max(a: i32, b: i32) callconv(.c) i32 {
    return if (a > b) a else b;
}

const Op = *const fn (a: c_int, b: c_int) callconv(.c) c_int;

const op: Op = &zig_op_max;
std.debug.print("C 侧用 Zig 函数指针 zig_op_max(3,9) = {d}\n", .{ci_ext.ci_apply_op(op, 3, 9)});
```

⚠️ 传 `&zig_op_max` 时**签名必须和 typedef 逐个类型对上**。
写错类型编译能过、运行才炸——和坑位 18 是同一个陷阱。

## 17.4 extern struct：布局保证

```zig
const CFoo = extern struct {
    a: u32,
    b: u32,
};
```

普通 `struct` 的字段布局由 Zig 自由安排（重排/填充优化）；
**`extern struct` 保证 C 布局规则**（声明序 + 自然对齐 + 平台填充）
——跨语言共享的结构必须用它。`packed struct`（08 章）则是精确到位的极端版。
`align(N)` 还能指定字段/变量对齐。

### 双向共享同一块内存

`extern struct` 的真正用途是**和 C 的结构体共享内存**——不是拷贝，是同一块。
C 侧（`include/ci_ext.h`）：

```c
typedef struct ci_box {
    int x;
    int y;
} ci_box_t;

// C 侧往这块内存写
void ci_box_shift(ci_box_t *b, int dx, int dy);
// C 侧读同一块内存并打印
void ci_box_print(const char *tag, const ci_box_t *b);
// C 侧的 offsetof：Zig 侧用 @offsetOf，两边输出必须一致
size_t ci_box_off_x(void);
size_t ci_box_off_y(void);
size_t ci_box_size(void);
```

Zig 侧手写一份镜像，字段序和类型逐个对齐：

```zig
const Box = extern struct {
    x: c_int,
    y: c_int,
};
```

**怎么证明"布局真的对齐"？两边各打印一遍偏移量，逐字节比较。**
Zig 用 `@offsetOf`，C 用 `offsetof`：

```zig
std.debug.print("Zig 侧 @offsetOf: x={d} y={d} size={d} align={d}\n", .{
    @offsetOf(Box, "x"), @offsetOf(Box, "y"), @sizeOf(Box), @alignOf(Box),
});
std.debug.print("C   侧 offsetof : x={d} y={d} size={d}\n", .{
    ci_ext.ci_box_off_x(), ci_ext.ci_box_off_y(), ci_ext.ci_box_size(),
});
```

```text
Zig 侧 @offsetOf: x=0 y=4 size=8 align=4
C   侧 offsetof : x=0 y=4 size=8
翻译出的 ci_box_t 与手写 Box 布局相同 = true
```

完全一致——这才是"能共享"的证明。光看代码"写着一样"不算证据。

然后是真正的双向读写，Zig 分配、C 改、Zig 读回：

```zig
var b: Box = .{ .x = 10, .y = 20 };
const p: [*c]ci_ext.ci_box_t = @ptrCast(&b);
ci_ext.ci_box_print("C 读到 Zig 写的", p);
ci_ext.ci_box_shift(p, 5, -3);
std.debug.print("Zig 读到 C 改完 : x={d} y={d}\n", .{ b.x, b.y });
```

```text
  [C] C 读到 Zig 写的: x=10 y=20
Zig 读到 C 改完 : x=15 y=17
```

三处细节值得单独记：

- **`@ptrCast` 而不是直接传。** 手写的 `Box` 和翻译出来的 `ci_box_t`
  是两个**不同的 Zig 类型**（一个是 `main.Box`，一个是
  `ci_ext.struct_ci_box`），指针不能直接互传，会报
  `error: pointer type child 'main.Box' cannot cast into pointer type child 'ci_ext.struct_ci_box'`。
  布局逐字节相同才能 `@ptrCast`——而"布局相同"正是上面那三行验证的东西。
- **打印走 `stderr` 而不是 `printf`。** C 的 `printf` 写 stdout（有缓冲），
  Zig 的 `std.debug.print` 写 stderr（无缓冲），混用时 C 的输出会全部堆到程序末尾，
  顺序全乱。本例的 `ci_box_print` 因此用 `fprintf(stderr, ...)`。
- **C 侧要 `#include` 自己的头文件**，不能靠翻译产物——翻译只给 Zig 侧生成声明。

### `@bitCast` 在 0.17 拒绝裸结构体

⚠️ 0.17 的一个硬变化：**`@bitCast` 不再接受裸结构体，`extern struct` 也不行**：

```text
error: cannot @bitCast from 'main.Box'
note: struct declared here
const Box = extern struct {
            ~~~~~~~^~~~~~~~~~~~~~~~~~~~~~~~~
```

注意报错里的类型名是**你声明的那个模块内名字**：手写的是 `main.Box`，
翻译出来的是 `ci_ext.struct_ci_box`。（`packed struct` 是例外，仍然允许。）

正确写法是**显式走字节 + 显式写端序**：

```zig
const raw = std.mem.asBytes(&b);
const lo = std.mem.readInt(u32, raw[0..4], .little);
const hi = std.mem.readInt(u32, raw[4..8], .little);
std.debug.print("asBytes+readInt  : x={d} y={d}（raw.len={d}）\n", .{ lo, hi, raw.len });
```

```text
asBytes+readInt  : x=15 y=17（raw.len=8）
```

`asBytes` 的返回类型实测是 `*align(4) const [8]u8`——
**指针，不是切片**：长度就是 `sizeof(T)`，所以**切不出 `[8..16]`**，
一个 8 字节的结构体读第一个 `u64` 就读完了。见
[21 章](21-asm.md) 和 [25 章](25-binary.md)。

### 结构体数组与指针数组

C 侧的静态数组传进 Zig 就是 `[*c]const T`（"多指针"，元素数未知），
所以惯例是**再传一个长度**，Zig 侧切出区间再遍历：

```c
typedef struct ci_pair {
    const char *key;
    int val;
} ci_pair_t;

const ci_pair_t *ci_pairs(void);  // C 侧静态数组，生命周期 = 整个进程
int ci_pairs_len(void);
```

```zig
const pairs = ci_ext.ci_pairs();          // [*c]const ci_pair_t
const n: usize = @intCast(ci_ext.ci_pairs_len());
var total: c_int = 0;
for (pairs[0..n]) |it| {
    std.debug.print("  pair {s} = {d}\n", .{ std.mem.span(it.key), it.val });
    total += it.val;
}
std.debug.print("C 侧静态数组 {d} 项求和 = {d}（元素 {d} 字节，key 在偏移 {d}）\n", .{
    n, total, @sizeOf(ci_ext.ci_pair_t), @offsetOf(ci_ext.ci_pair_t, "key"),
});
```

```text
  pair red = 3
  pair green = 5
  pair blue = 7
C 侧静态数组 3 项求和 = 15（元素 16 字节，key 在偏移 0）
```

三处细节：

- **`[ *c]` 不能用 `c_int` 下标。** `pairs[i]` 的 `i` 必须是 `usize`，
  写 `var i: c_int = 0` 会报
  `error: expected type 'usize', found 'c_int'`。
  干脆先 `@intCast` 成 `usize` 再循环。
- **元素的 `key` 字段是 `[*c]const u8`**，没有长度，
  要 `std.mem.span(...)` 才拿到切片。
- **单个元素是 `[*c]T` 时不能直接点字段**：`owner.name` 会报
  `error: type '[*c]ci_ext.struct_ci_owner' does not support field access`，
  要写 `owner.*.name`（`*` 取出指针指向的那一个元素）。

### 所有权：结构体里带指针时，谁分配谁释放

C 的结构体带 `char *` 字段时，**这块内存和指针指向的那块是两次分配**。
规矩只有一条：**谁分配谁释放，且释放必须回到原分配器**。

```c
typedef struct ci_owner {
    char *name;   // 指向另一块 malloc 出来的内存
    int id;
} ci_owner_t;

ci_owner_t *ci_owner_new(const char *name, int id);  // C 侧 malloc + strdup
void ci_owner_free(ci_owner_t *p);                   // C 侧 free(p->name); free(p);
```

Zig 侧只读，释放交回 C：

```zig
const owner = ci_ext.ci_owner_new("owned-by-c", 42);
std.debug.print("C 分配的 name = {s}（id={d}）\n", .{ std.mem.span(owner.*.name), owner.*.id });
ci_ext.ci_owner_free(owner);
```

```text
C 分配的 name = owned-by-c（id=42）
```

⚠️ **绝对不能**把 `owner.*.name` 丢给 Zig 的 allocator 去 `free`：
那是 libc 的 `malloc` 出来的内存，Zig 的 `allocator.free` 走的是
`GeneralPurposeAllocator`（Debug 下带哨兵和 poisons），
跨分配器释放是**未定义行为**——轻则数据损坏，重则直接崩。
反过来 Zig 分配的东西也不能给 C 的 `free`。
需要 Zig 侧管理生命周期时，正确做法是**别让 C 拥有**：
用 Zig 的 slice/map 传给 C 只读视图，或者在两侧都遵守同一套分配器
（比如两边都用 libc 的 `malloc`/`free`）。


## 17.5 字符串双向桥

```zig
const zig_str = "哨兵切片互转";
const c_ptr: [*:0]const u8 = zig_str.ptr;        // 哨兵保证 0 结尾 → 直接给 C
const back: [:0]const u8 = std.mem.span(c_ptr);  // C 指针 → 哨兵切片（带长度）

std.debug.print("span 回来长度 {d}（两侧字节一致）\n", .{back.len});
std.debug.print("C 侧 strlen 同一块内存 = {d}\n", .{ci.ci_strlen(c_ptr)});
```

```text
span 回来长度 18（两侧字节一致）
C 侧 strlen 同一块内存 = 18
const char* 在翻译模块里的类型 = [*c]const u8，span 长度 18
```

`std.mem.span` 是回程票：从 0 结尾指针**重建出带长度的切片**（扫到 0 为止）。
Zig 侧永远用切片思维，C 边界上一进一出转换，两头都是最地道的类型。

（"18"是 UTF-8 字节数不是字符数——"哨兵切片互转" 6 个汉字，
每个 3 字节。这个例子顺手说明了一件常被忘的事：**Zig 的 `[]u8` 长度是字节数**。）

⚠️ **0.17 的哨兵类型：手写写 `[:0]`，translate-c 产出 `[*c]`。**
两者都还可用（`[:0]const u8` 在 0.17 依然能编译），但是同一件事的两种写法：

| 写法 | 类型 | 谁产出 |
|---|---|---|
| `[:0]const u8` | 哨兵**切片**（有 `len`） | 手写 `extern fn` 时常用 |
| `[*c]const u8` | 哨兵**指针**（无 `len`） | `translate-c` / `addTranslateC` 的产物 |

所以从翻译模块拿到的字符串指针，直接喂给手写声明成 `[*:0]const u8` 的
`printf` 形参是**不行的**（类型不匹配），反之亦然。
两个都能用 `std.mem.span` 拿回 `[:0]const u8` 切片。双向互转实测：

```zig
const a: [:0]const u8 = "x";
const b: [*c]const u8 = a;                   // [:0] → [*c]：可以
const back: [:0]const u8 = std.mem.span(b);  // [*c] → [:0]：也可以
```

需要统一风格时，在赋值处显式转一下即可（`src/main.zig` 的 17.5 就是这么做的）：

```zig
const from_c: [*c]const u8 = c_ptr;    // [:0] 的指针，标注成 [*c] 给 C 用
std.debug.print("const char* 在翻译模块里的类型 = {s}，span 长度 {d}\n", .{
    @typeName(@TypeOf(from_c)), std.mem.span(from_c).len,
});
```

## 17.6 混编：把 .c 当输入

小项目不需要构建系统两套账，zig 内置了 clang 前端：

```bash
zig build-exe main.zig util.c -lc
```

正式工程则在 `build.zig` 里 `main_mod.addCSourceFiles(...)`（17.2 用过），
链系统库用 `linkSystemLibrary("ssl", .{})` / `linkLibrary(...)`。

本例用的就是 `addCSourceFiles`：`csrc/ci.c`、`csrc/ci_ext.c` 和 `src/main.zig`
被链接进同一个可执行文件，两边的符号互相可见。

⚠️ 混编时两个输出去向不同，混用会让顺序错乱：
**`printf` 写 stdout（有缓冲），`std.debug.print` 写 stderr（无缓冲）**。
C 侧要输出诊断信息时用 `fprintf(stderr, ...)`（本例 `ci_box_print` 就是），
否则 C 的输出会全部堆到程序最末尾。

## 17.7 zig translate-c：预生成绑定

```bash
zig translate-c include/ci.h > src/bindings_ci.zig
```

把 C 头文件**翻译成 Zig 源码**输出。和 17.2 的 `addTranslateC` 是同一个翻译器，
区别只在**产物去哪**：一条进 `.zig-cache/`（构建时用），一条进你的源码树（提交进仓库）。

### 你真的能看到它生成什么

对 `include/ci.h`（12 行）跑这条命令，产出 **420 行**。完整输出很长，
这里只贴**头 16 行**和**尾 3 行**：

```zig
const __root = @This();
pub const __builtin = @import("std").zig.c_translation.builtins;
pub const __helpers = @import("std").zig.c_translation.helpers;
pub const ptrdiff_t = c_long;
pub const wchar_t = c_int;
pub const max_align_t = extern struct {
    __aro_max_align_ll: c_longlong = 0,
    __aro_max_align_ld: c_longdouble = 0,
};
pub extern fn ci_add(a: c_int, b: c_int) c_int;
pub extern fn ci_triple(a: c_int) c_int;
pub extern fn ci_strlen(s: [*c]const u8) usize;
pub extern fn ci_strcmp(a: [*c]const u8, b: [*c]const u8) c_int;
pub extern fn zig_add(a: c_int, b: c_int) c_int;
pub extern fn zig_version() [*c]const u8;
```

```zig
pub const NULL = __helpers.cast(?*anyopaque, @as(c_int, 0));
pub const offsetof = @compileError("unable to translate macro: undefined identifier `__builtin_offsetof`");
// .../lib/compiler/aro/include/stddef.h:18:9
```

三点观察，每一点都对应一个 17.2 没讲到的细节：

1. **12 行头文件 → 420 行产物。** 中间 384 行全是 `<stddef.h>` 展开带来的
   编译器内置宏（`__STDC_VERSION__`、`__LDBL_MAX__`、`__GNUC__`……）。
   这就是"要裁剪"的真实理由——**你 99% 的头文件都是这个形状**。
2. **`const char *` 翻译成 `[*c]const u8`**，不是 `[:0]const u8`（见 17.5 的对照表）。
   0.17 的 `translate-c` 一律用 `[*c]`。
3. **`offsetof` 宏翻译成了 `@compileError`**。这个宏在 Zig 侧**用不了**——
   这正是本例 17.4 要在 C 侧包一层 `ci_box_off_x()` 返回 `offsetof` 的原因：
   C 侧自己算偏移，Zig 侧用 `@offsetOf`，两边对照。

### 什么时候要手动跑这个命令？

- 想**审查**绑定结果（比 `addTranslateC` 的黑盒更透明）；
- 想**裁剪**：SDL、lua 这种大库的翻译结果有几十万行，
  真正用到的可能只有几十个函数，删掉其余的再提交；
- 想让不装 clang 的机器也能构建（不用构建期跑翻译）。

惯用流程：translate-c 生成 → 手工整理出精简绑定层 → 当普通 `.zig` 文件 commit。
本例的 `src/bindings_ci.zig` 就是裁剪到极致的版本——420 行删到 6 个声明：

```zig
pub extern fn ci_add(a: c_int, b: c_int) c_int;
pub extern fn ci_triple(a: c_int) c_int;
pub extern fn ci_strlen(s: [*c]const u8) usize;
pub extern fn ci_strcmp(a: [*c]const u8, b: [*c]const u8) c_int;
pub extern fn zig_add(a: c_int, b: c_int) c_int;
pub extern fn zig_version() [*c]const u8;
```

它和 `addTranslateC` 的产物可以**同时存在于同一个程序**——实测两者对同一份头文件
给出完全一致的签名，也就能互相替换：

```zig
const ci = @import("ci");                    // addTranslateC 的产物（.zig-cache/）
const bindings = @import("bindings_ci.zig");  // CLI 的产物（源码树里）

std.debug.print("addTranslateC   : ci_add(3,4)={d} ci_strlen(\"hello\")={d}\n", .{
    ci.ci_add(3, 4), ci.ci_strlen("hello"),
});
std.debug.print("translate-c CLI : ci_add(3,4)={d} ci_strlen(\"hello\")={d}\n", .{
    bindings.ci_add(3, 4), bindings.ci_strlen("hello"),
});
```

```text
addTranslateC   : ci_add(3,4)=7 ci_strlen("hello")=5
translate-c CLI : ci_add(3,4)=7 ci_strlen("hello")=5
```

裁剪版还能**加注释**——这是进源码树相对黑盒最实用的好处：
生成物没法写注释，提交进仓库的版本可以标明每个声明的来源和坑。
代价是**头文件改了要记得重新生成**，忘了就是链接期 `undefined symbol`。


## 17.8 三种方式怎么选

| 方式 | 适用 | 代价 |
|---|---|---|
| 手写 `extern`（17.1） | 一两个函数、libc 常用函数 | 手写签名，可能写错 |
| `b.addTranslateC`（17.2） | 整个库头文件 | 必须有构建系统，翻译开销 |
| `translate-c` CLI（17.7） | 大库、要裁剪、要审查 | 产物进仓库，要手动维护 |

判断顺序：**先试手写 extern**——如果三行以内能搞定就别折腾构建系统。
需要整套声明时再上 `addTranslateC`；发现绑定太大、只用到冰山一角时，
再退到 CLI 版手工裁剪。

## 17.9 坑位清单

先看一个**能跑的坑**：变参 `printf` 完全放弃类型检查，
`usize` 直塞 `%d` 是实打实的 UB，而不是"编译期能拦你"。

```zig
const big: usize = 0x1_0000_0001;   // 4294967297，32 位槽装不下
_ = printf("%%d  直塞 usize = %d   ← 被截断，只剩低 32 位\n", big);
_ = printf("%%zu 直塞 usize = %zu  ← size_t 的正确格式串\n", big);
_ = printf("%%d  显式收窄     = %d   ← @as(c_int, @intCast(x)) 之后是对的\n", @as(c_int, @intCast(big & 0xff)));
```

```text
%d  直塞 usize = 1   ← 被截断，只剩低 32 位
%zu 直塞 usize = 4294967297  ← size_t 的正确格式串
%d  显式收窄     = 1   ← @as(c_int, @intCast(x)) 之后是对的
```

同一个值 `0x1_0000_0001`：`%d` 打出 **1**（低 32 位，高的那位丢了），
`%zu` 打出完整的 **4294967297**。注意这还只是本机（x86_64 macOS）
varargs 按寄存器传递的表现——**别把它当"最多截断"的保证**，
这在文档里就是 UB，换个平台/编译器可能是别的结果。

0.17 对**字面量**倒是会拦你一手，但只拦字面量：

```zig
_ = printf("%d\n", 42);
// error: integer and float literals passed to variadic function
//        must be casted to a fixed-size number type
```

写成 `const n: u32 = 42;` 就能过——**这恰恰说明检查是表面的**：
过了编译期那关，宽度对不对全靠你自己。

清单：

1. **`@cImport` 在 0.17 已被移除**（`error: invalid builtin function: '@cImport'`），
   `@cInclude` 随之失效。头文件翻译改走 `build.zig` 的 `b.addTranslateC`，
   产物用 `tc.createModule()` 取出，再挂进主模块的 `imports`。
2. **`callconv(.C)` 改名 `callconv(.c)`（小写）**，旧写法报
   `has no member named 'C'`。
3. **`b.args` 已移除**：run artifact 不再自动透传命令行参数，
   必须 `run_cmd.addPassthruArgs()`。
4. **`build.zig.zon` 要写 `.minimum_zig_version = "0.17.0"`**。
5. **`link_libc = true` 仍然必需**，但错误信息变了：不再是老版本的
   "libc headers not available"，而是链接期的 `undefined symbol`。
6. **C 宏不是函数**：翻译后宏是 comptime 常量或内联包装，
   想拿函数指针的宏（如 `RGB(...)`）拿不到，要看翻译结果里它的真身。
7. **`printf` 的 `%d` 与 Zig 宽度**：`usize`/`size_t` 直塞 `%d` 是 UB
   （本例实测被截断成低 32 位）——`@as(c_int, @intCast(x))` 显式收窄。
   注意本例 `%zu` 是对的，因为它就是 `size_t`。
8. **extern struct vs 普通 struct**：跨 ABI 共享布局必须用 `extern struct`；
   普通 struct 被编译器重排后和 C 对不上——数据损坏悄无声息。
   验证办法是两边各打一遍 `@offsetOf` / `offsetof`（17.4）。
9. **`@bitCast` 拒绝裸结构体（0.17）**，`extern struct` 也不例外，
   报 `error: cannot @bitCast from 'main.Box'`；
   改 `std.mem.asBytes` + `std.mem.readInt(…, .little)`，
   顺带把端序显式写出来。`asBytes` 实测返回 `*align(4) const [N]u8`
   （**指针**不是切片），切不出超出 `sizeof(T)` 的区间。
10. **变参没有类型检查**：`printf` 传错类型 C 那边一样崩；
    Zig 的编译期格式检查只保护 `std.debug.print`，不覆盖 extern 变参。
    连整数**字面量**都只有"必须 cast 成定宽类型"这一层检查。
11. **`size_t` 翻译成 `usize`**，`#include` 被展开、宏成 comptime 常量——
    所以你**不需要**在 Zig 侧重复声明头文件里已有的东西。
12. **哨兵类型有两套**：手写 `extern fn` 常写 `[:0]const u8`（哨兵切片），
    `translate-c` 产出的是 `[*c]const u8`（哨兵指针）。
    两者都还能编译，但不能互相直接传参——`std.mem.span` 是双向通票。
13. **`offsetof` 宏翻译不出来**：`translate-c` 给的是
    `@compileError("unable to translate macro: undefined identifier
    '__builtin_offsetof'")`。要在 Zig 侧对偏移就在 C 侧包一层函数返回它。
14. **手写的 extern struct 和翻译出来的结构体是两个类型**：
    `main.Box` 和 `ci_ext.struct_ci_box` 指针不能直接互传，报
    `pointer type child 'main.Box' cannot cast into pointer type child 'ci_ext.struct_ci_box'`。
    布局逐字节相同才能 `@ptrCast`。
15. **`[*c]T` 的两个限制**：下标必须是 `usize`（写 `c_int` 报
    `expected type 'usize', found 'c_int'`）；单元素的 `[*c]T` **不能直接点字段**
    （`owner.name` 报 `does not support field access`），要 `owner.*.name`。
16. **导出的字符串谁负责释放**：`return version.ptr` 指向全局常量，
    谁都不释放。导出动态内存必须在文档里写明由谁 `free`，否则两边都以为对方会 free。
17. **结构体里的指针字段，释放必须回原分配器**：C `malloc` 的内存不能给
    Zig 的 `allocator.free`，反之亦然——跨分配器释放是 UB。
18. **双向调用会掩盖类型错误**：C 回调 Zig 时两边都按 `int` 传，
    你把 `i32` 写成 `i64` 编译能过、运行才炸。跨语言边界上
    优先用定宽 C 类型而不是 Zig 原生宽度。传函数指针给 C 时同理。
19. **`printf` 写 stdout、`std.debug.print` 写 stderr**：混用时 C 的输出
    因为缓冲会全部堆到程序末尾，顺序错乱。C 侧诊断信息用
    `fprintf(stderr, ...)`。
20. **17 章现在是 build.zig 工程**，不再是 `zig build-exe … -lc`；
    `run-all.sh` 和 `build.ps1` 都走 `zig build test` / `zig build run` 两条通道。
21. **`zig translate-c` 与 `addTranslateC` 是同一个翻译器**，
    区别只在产物进 `.zig-cache/` 还是进源码树——裁剪和审查需求决定选哪个。
    两者可以同时存在于一个程序里，签名完全一致。

---

上一章：[16 构建与包管理](16-build.md) · 下一章：[18 交叉编译](18-cross.md)