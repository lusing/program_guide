# 17 · C 互操作 ⭐

> 对应示例：`examples/17_cinterop/`（构建需 `-lc`）
>
> "Zig 是一门更好的 C"的另一面：**和 C 无缝互认**。没有 FFI 层、没有绑定生成器门槛。

## 17.1 extern fn：手写 C 声明

```zig
extern fn printf(format: [*:0]const u8, ...) c_int;   // 变参 C 函数

pub fn main() !void {
    _ = printf("printf 直连：zig_add(3,4)=%d\n", zig_add(3, 4));
}
```

`extern fn` 声明"这函数在 C 那边"——签名对上 C ABI 就直接链接调用。类型映射：`c_int`/`c_char`/`c_uint` 等（`std.c` 里全家福）、C 字符串是 `[*:0]const u8`（哨兵指针，06 章）。变参函数用 `...` 收尾。**普通字符串字面量就是 0 结尾的**（`*const [N:0]u8` 自动退化），旧的 `c"..."` 前缀字面量 0.16 已移除，直接传就行。

## 17.2 @cImport：整头文件拿进来

```zig
const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("string.h");
});

_ = c.printf("cImport 版：strlen(hello)=%d\n", @as(c_int, @intCast(c.strlen("hello"))));
```

`@cImport` 在编译期调用 clang 解析头文件，把所有符号装进 `c` 命名空间——**函数、类型、宏**一锅端。**必须链 libc（`-lc`）**，否则报 "libc headers not available"（构建/测试命令都要带）。宏会变成常量或 inline 函数。小坑：C 的 `size_t` 之类进 printf 的 `%d` 要显式 `@intCast` 到 `c_int`。

选择建议：一两个函数手写 `extern`（17.1，零成本最直白）；整库头文件用 `@cImport`（17.2）；要**看代码/裁剪/预生成绑定**用 translate-c（17.7）。

## 17.3 export fn：反向导出

```zig
export fn zig_add(a: i32, b: i32) i32 {   // 按 C ABI 导出符号 zig_add
    return a + b;
}
```

`export fn` 让 Zig 函数以 C 调用约定导出——C/Python/wasm（18 章）都能调它。配套的 `@export(variable, .{ .name = "..." })` 能导出全局变量。`extern` 和 `export` 一进一出，Zig 代码可以嵌进任何 C 工程（甚至只把 Zig 当"更好的 C 编译器"用）。

## 17.4 extern struct：布局保证

```zig
const CFoo = extern struct {
    a: u32,
    b: u32,
};
```

普通 struct 的字段布局由 Zig 自由安排（重排/填充优化）；**`extern struct` 保证 C 布局规则**（声明序 + 自然对齐 + 平台填充）——跨语言共享的结构必须用它。`packed struct`（08 章）则是精确到位的极端版。`align(N)` 还能指定字段/变量对齐。

## 17.5 字符串双向桥

```zig
const zig_str = "哨兵切片互转";
const c_ptr: [*:0]const u8 = zig_str.ptr;        // 哨兵保证 0 结尾 → 直接给 C
const back: [:0]const u8 = std.mem.span(c_ptr);  // C 指针 → 哨兵切片（带长度）
```

`std.mem.span` 是回程票：从 0 结尾指针**重建出带长度的切片**（扫到 0 为止）。Zig 侧永远用切片思维，C 边界上一进一出转换，两头都是最地道的类型。

## 17.6 链接 C 源码与库

```bash
# 混编：main.zig 引用 util.c 里的函数
zig build-exe main.zig util.c -lc
```

zig 能直接把 `.c` 文件当输入编译（内置 clang）——小项目无需构建系统两套账。正式工程在 build.zig 里 `root_module.addCSourceFile(.{ .file = b.path("util.c"), .flags = &.{"-O2"} })`，链接库 `linkSystemLibrary("ssl", .{})`。

## 17.7 zig translate-c：预生成绑定

```bash
zig translate-c header.h > bindings.zig
```

把 C 头文件**翻译成 Zig 源码**输出——相比 @cImport：结果可见可读可裁剪（不想要的符号删掉）、不依赖头文件现场解析、能进代码审查。大型 C 库（SDL、lua）的惯用流程：translate-c 生成 → 手工整理出精简绑定层。构建期自动版：build.zig 的 `b.addTranslateC(...)`。

## 17.8 坑位清单

1. **`-lc` 忘带**：`@cImport` 直接报 "libc headers not available"——`zig test main.zig -lc`、`zig build-exe main.zig -lc` 都要带（build.ps1 对 17 章示例自动加）。
2. **`c"..."` 字面量已移除**（0.16）：普通字符串字面量就是 0 结尾的，直接传。
3. **C 宏不是函数**：@cImport 后宏是常量或内联包装——想拿函数指针的宏（如 `RGB(...)`）不行，手写 extern 或 translate-c 的结果里看真身。
4. **printf 的 `%d` 与 Zig 宽度**：`usize`/`size_t` 直塞 `%d` 是 UB（Windows 上 64 位塞 32 位槽）——`@as(c_int, @intCast(x))` 显式收窄。
5. **extern struct vs 普通 struct**：跨 ABI 共享布局用 extern struct；普通 struct 被编译器重排后和 C 对不上——数据损坏悄无声息。
6. **变参没类型检查**：`printf` 传错类型 C 那边一样崩——Zig 的编译期格式检查只保护 `std.debug.print`，不覆盖 extern 变参。

---
