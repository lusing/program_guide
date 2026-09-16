# 05 · 函数

> 对应示例：`examples/05_functions/`

## 5.1 基本形态

```zig
fn add(a: i64, b: i64) i64 {
    return a + b;
}
```

参数名在前、类型在后（冒号），返回类型在参数表后。公开导出用 `pub`（文件即命名空间，不 pub 就是文件私有）。**没有默认参数、没有重载**——这两个"缺失"各有一个惯用法补位（5.6/5.7 节）。

## 5.2 defer：作用域退出时执行

```zig
fn deferDemo() void {
    defer std.debug.print("defer A（先注册，最后跑）\n", .{});
    defer std.debug.print("defer B（后注册，先跑）\n", .{});
    {
        defer std.debug.print("块级 defer（出了块就跑）\n", .{});
    }  // ← 这里就执行了
}
```

`defer` 注册一段"离开当前作用域时执行"的清理——**多条 defer 按 LIFO（逆序）执行**，块级作用域单独生效。它是 Zig 资源管理的地基：关文件、释放内存、解锁（19 章）全靠它，错误路径和正常路径**统一走同一份清理代码**——对比 C++ RAII（析构函数藏在类型里）和 Go defer（只能挂函数尾），Zig 的作用域粒度最细。

`errdefer` 是它的错误专用变体（10 章），两者配合覆盖"成功清理 / 失败回滚"。

## 5.3 comptime 参数：编译期常量当参数

```zig
fn maxOf(comptime T: type, a: T, b: T) T {   // T 是编译期参数
    return if (a > b) a else b;
}
maxOf(i32, 3, 9)   // 每种 T 实例化一份
maxOf(f64, 2.5, 1.5)
```

标了 `comptime` 的参数**必须在编译期已知**——这让函数能接收类型当参数，是 Zig 泛型的全部机制（第 13/14 章）。普通参数传了编译期常量，函数也不会因此特化。

## 5.4 anytype：编译期鸭子类型

```zig
fn describe(value: anytype) void {
    const T = @TypeOf(value);
    std.debug.print("类型 {s}，值 {any}\n", .{ @typeName(T), value });
}
describe(42);        // 类型 comptime_int
describe("字符串也行"); // 类型 *const [15:0]u8
```

`anytype` 参数对每个实际类型实例化一份，函数体里用 `@TypeOf` + 反射（14 章）适配。`std.debug.print` 的 `args: anytype` 就是这么实现的——这就是为什么格式串能编译期检查。**代价**：错误在调用处报（5.8 坑位），文档性弱——库的公开 API 用 `comptime T: type` 更清晰，`anytype` 更适合打印/工具类函数。

## 5.5 没有嵌套函数：匿名 struct 当命名空间

```zig
fn outer(x: i64) i64 {
    const square = struct {          // struct 是容器，容器里才能放 fn
        fn call(v: i64) i64 {
            return v * v;
        }
    }.call;
    return square(x) + square(@divTrunc(x, 2));
}
```

**Zig 不允许在函数体内直接声明 `fn`**（函数只能属于文件/struct 等容器）。需要"局部函数"时，惯用法是匿名 struct 命名空间（如上）。注意它**不能捕获**外层变量——`square` 看不到 `x`，参数必须传。这和闭包是两个世界：Zig 目前没有闭包，"函数 + 数据"用 struct 方法表达（07 章）。

## 5.6 没有重载 → comptime T / anytype 分派

同名不同参的函数在 Zig 里直接冲突（编译错）。替代方案就两条：`comptime T: type`（5.3 节，调用处显式选类型）或 `anytype`（5.4 节，编译器按实参特化）。C++ 重载解析的惊喜（哪个重载被选中？），Zig 用"显式类型参数"换掉了。

## 5.7 没有默认参数 → 参数结构体

```zig
const DrawOpts = struct {
    color: []const u8 = "黑",
    bold: bool = false,
};
fn rect(opts: DrawOpts) void { ... }

rect(.{});                             // 全默认
rect(.{ .color = "红", .bold = true }); // 覆盖个别
```

默认值长在 struct 字段上，调用处用匿名字面量 `.{ ... }`——只写要覆盖的字段。std 库的 options 参数（如 `openDir(io, path, .{ .iterate = true })`）全是这个模式，参数多了以后可读性远超位置参数。

## 5.8 坑位清单

1. **函数体内写 `fn` 直接编译错**：`expected ',' after initializer` 之类奇怪报错的常见真因——改用匿名 struct 命名空间（5.5）。
2. **有符号除法必须点名**：`x / 2` 对 i32 是编译错，写 `@divTrunc(x, 2)`（向零取整）/ `@divFloor`（向下）/ `@divExact`（整除断言）——三种语义显式选择。
3. **defer 在 return 值求值之后、真正返回之前执行**：defer 里改的是局部状态，别指望影响已求出的返回值。
4. **递归函数必须显式返回类型**：类型推导需要函数体，递归时推不动——写全签名。
5. **anytype 的错误在调用处爆**：函数体里对 T 的假设不满足时，报错指向你的调用（带着一长串模板式跟踪）——读第一条 error，别被 reference trace 吓到。

---
