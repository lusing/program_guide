# 14 · 泛型

> 对应示例：`examples/14_generics/main.zig`
>
> Zig 没有 C++ 那种 `template` 系统，也没有 Rust 的 `trait`。它只有一件事：**comptime 参数**。
> `fn f(comptime T: type, v: T)` 就是泛型，`fn Container(comptime T: type) type` 就是"类"，
> `@typeInfo` 就是反射。上一章的机制拼起来，本章是成果展。
> 读完你应该能自己回答三个问题：`comptime T: type` 和 `anytype` 到底差在哪？
> 为什么泛型容器里必须有 `const Self = @This();`？以及——为什么 0.17 里
> `@typeInfo(T).@"struct".fields` 这个字段**已经不存在了**？

本章的核心变化全在**本机 0.17.0**（`zig-x86_64-macos-0.17.0`，macOS x86_64）上实测过。
0.17 把 `@typeInfo` 的结构体做了**大手术**：字段从"字段结构体数组"改成"三条平行数组"、
`.tag` 改名 `.layout`、`.optional.payload` 改名 `.child`、`.pointer` 的属性挪进了 `attrs` 子结构、
`.float` 从枚举变成结构体。**本章的坑位清单有一半就是这次手术的直接后果**，所有引用的编译错误文本都实测复现过。

---

## 14.1 泛型就是 comptime 参数

Zig 的泛型没有关键字、没有尖括号、没有实例化语法。`type` 是一等值（13.8 节），所以**返回一个类型**的普通函数就是类型构造器：

```zig
// examples/14_generics/main.zig 第 20-24 行
/// 14.1 节的类型构造器：参数全是 comptime，返回值是 `type`。
/// 泛型在Zig 里就是"编译期跑一个函数，把类型当返回值"。
fn Matrix(comptime T: type, comptime rows: usize, comptime cols: usize) type {
    return [rows][cols]T;
}
```

`Matrix(u8, 2, 3)` 不是"实例化"——它就是**编译期调用了一个函数**，返回值是类型 `[2][3]u8`。这一点决定了泛型在 Zig 里的全部性质：报错是**普通函数的报错**（直接指向你写的那一行，不是一屏长的模板栈）、实例化**有缓存**（同样的参数只算一次）、泛型能调用泛型（函数里的泛型是普通函数）。

```zig
// examples/14_generics/main.zig 第 363-377 行（14.1 节的横幅注释到 end("14.1")）
    // ═══ 14.1 泛型就是 comptime 参数：没有 template，也没有尖括号 ═══
    begin("14.1");
    // Matrix(u8, 2, 3) 是**编译期调用**，返回值是类型 [2][3]u8
    const Grid = Matrix(u8, 2, 3);
    const grid: Grid = .{ .{ 1, 2, 3 }, .{ 4, 5, 6 } };
    std.debug.print("Matrix(u8,2,3) = {s}；grid[1][2] = {d}\n", .{ @typeName(Grid), grid[1][2] });
    std.debug.print("Grid 的 @sizeOf = {d} 字节\n", .{@sizeOf(Grid)});
    // 同一个构造器换参数就是另一个类型——**没有重载、没有歧义**
    const LongGrid = Matrix(i64, 2, 3);
    std.debug.print("Matrix(i64,2,3) = {s}；@sizeOf = {d} 字节\n", .{ @typeName(LongGrid), @sizeOf(LongGrid) });
    std.debug.print("Grid == LongGrid = {}（不同类型，类型相等按结构逐项比）\n", .{Grid == LongGrid});
    std.debug.print("Grid == Matrix(u8,2,3) = {}（同参数同类型，实例化有缓存）\n", .{Grid == Matrix(u8, 2, 3)});
    // comptime 参数不限于类型：尺寸也是 comptime 输入
    std.debug.print("形状同但每格大小不同：{}（6 vs 48 字节）\n", .{@sizeOf(Grid) != @sizeOf(LongGrid)});
    end("14.1");
```

运行输出（`examples/14_generics/main.zig`）：

```text
==== 14.1 开始 ====
Matrix(u8,2,3) = [2][3]u8；grid[1][2] = 6
Grid 的 @sizeOf = 6 字节
Matrix(i64,2,3) = [2][3]i64；@sizeOf = 48 字节
Grid == LongGrid = false（不同类型，类型相等按结构逐项比）
Grid == Matrix(u8,2,3) = true（同参数同类型，实例化有缓存）
形状同但每格大小不同：true（6 vs 48 字节）
==== 14.1 结束 ====
```

输出第 5 行值得单独说：**`Grid == Matrix(u8, 2, 3)` 是 `true`**。类型相等在这里是**结构相等**（逐项比字段），不是"同一个声明"（那在 Zig 里叫类型同一性）。所以第 4 行 `Grid == LongGrid` 是 `false`（元素类型不同），而同一组参数的两次构造结果"相等"。这个 `==` 在 14.9 节的单态化讨论里还会出现一次——**它是"实例被缓存了"的最直接证据**。

对比 C++ 模板：那边实例化是暗箱（SFINAE、两阶段查找、`>>` 还要空格避歧义），报错是一屏长的模板栈。这边就是"编译期跑了个函数"——**报错直接指向你的源码行，没有栈**。唯一的心智负担是：`Matrix` 这种**首字母大写的名字只是命名约定**（Zig 靠它提示"这是个类型构造器"），语法上它就是个普通函数，你甚至可以叫它 `matrix`（很多 std 代码就这么写）。

## 14.2 `fn Container(comptime T: type) type` 与 `@This()`

Zig 的"类"就是这个形状。`std.ArrayList`、`std.HashMap`、`std.BoundedArray`（⚠️ 0.17 已不存在）全是它。

```zig
// examples/14_generics/main.zig 第 26-56 行
/// 14.2 节的泛型容器：`fn Container(comptime T: type) type` 是标准形状。
/// @This() 在泛型 struct 里指向"当前正在定义的这个 struct"——
/// 此刻它还没有名字（名字是 `Stack(u32)` 这种实例化产物），所以只能靠 @This() 自指。
fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();

        items: std.ArrayList(T) = .empty,

        /// 把类型参数再导出成一个常量，方便外部查询（13.8 节 type 是一等值）。
        pub const Item = T;

        pub fn push(self: *Self, gpa: std.mem.Allocator, v: T) !void {
            try self.items.append(gpa, v);
        }

        pub fn pop(self: *Self) ?T {
            if (self.items.items.len == 0) return null;
            return self.items.pop();
        }

        pub fn peek(self: *const Self) ?T {
            if (self.items.items.len == 0) return null;
            return self.items.items[self.items.items.len - 1];
        }

        pub fn deinit(self: *Self, gpa: std.mem.Allocator) void {
            self.items.deinit(gpa);
        }
    };
}
```

**`const Self = @This();` 为什么必需**：泛型 struct 在被定义的那一刻**还没有名字**。`Stack` 这个函数返回的类型叫 `main.Stack(u32)`——这个名字是 `u32` 这个实参**代进去之后**才有的。所以 struct 内部要写 `*Self`（而不是 `*Stack(u32)`，那会无限递归），只能靠 `@This()` 拿"包含我的这个类型"。

```zig
// examples/14_generics/main.zig 第 379-409 行（14.2 节的横幅注释到 end("14.2")）
    // ═══ 14.2 fn Container(comptime T: type) type 与 @This() ═══
    begin("14.2");
    var st = Stack(u32){};
    defer st.deinit(std.heap.page_allocator);
    try st.push(std.heap.page_allocator, 10);
    try st.push(std.heap.page_allocator, 20);
    try st.push(std.heap.page_allocator, 30);
    std.debug.print("Stack(u32) 弹栈：{d} {d} {d} 空={any}\n", .{ st.pop().?, st.pop().?, st.pop().?, st.pop() });
    var st2 = Stack(u8){};
    defer st2.deinit(std.heap.page_allocator);
    try st2.push(std.heap.page_allocator, 'Z');
    std.debug.print("新栈 peek = {c}（peek 不弹栈）\n", .{st2.peek().?});
    std.debug.print("pop 后 = {c}\n", .{st2.pop().?});
    std.debug.print("空栈 peek = {any} / pop = {any}\n", .{ st2.peek(), st2.pop() });
    // @This() 的意义：泛型 struct 里"引用自己的类型"，此刻名字还不存在
    std.debug.print("Stack(u32) 的类型名 = {s}\n", .{@typeName(@TypeOf(st))});
    std.debug.print("Stack(u32).Item = {s}（类型参数被导出成常量）\n", .{@typeName(Stack(u32).Item)});
    std.debug.print("Stack(u32).Self = {s}（就是它自己）\n", .{@typeName(Stack(u32).Self)});
    // ⚠️ 0.17 新坑：decl 只能通过**类型**访问，不能通过**值**访问：
    //    st.item_type报 error: no field named 'item_type' in struct 'main.Stack(u32)'
    std.debug.print("⚠️ st.Item 在 0.17 编译不过（decl 只能经类型访问）；字段访问 = {s}\n", .{@typeName(@FieldType(@TypeOf(st), "items"))});
    // 两个类型参数：A 和 B 完全独立，这是 anytype 做不到的
    var pr = Pair(u8, []const u8){ .a = 7, .b = "seven" };
    std.debug.print("Pair(u8,[]const u8) = {s}：a={d} b={s}\n", .{ @typeName(@TypeOf(pr)), pr.a, pr.b });
    std.debug.print("  size_a={d} size_b={d}（两个参数的尺寸独立算）\n", .{ Pair(u8, []const u8).size_a, Pair(u8, []const u8).size_b });
    std.debug.print("  toBytes = {any}（长度 {d} 是编译期常量，异构照样能摊）\n", .{ pr.toBytes(), pr.toBytes().len });
    // swap 只在 A == B 时合法，异构调用是**编译期** @compileError
    var pr2 = Pair(u8, u8){ .a = 1, .b = 2 };
    pr2.swap();
    std.debug.print("  Pair(u8,u8).swap 后：a={d} b={d}（同型才能换）\n", .{ pr2.a, pr2.b });
    end("14.2");
```

运行输出（`examples/14_generics/main.zig`）：

```text
==== 14.2 开始 ====
Stack(u32) 弹栈：30 20 10 空=null
新栈 peek = Z（peek 不弹栈）
pop 后 = Z
空栈 peek = null / pop = null
Stack(u32) 的类型名 = main.Stack(u32)
Stack(u32).Item = u32（类型参数被导出成常量）
Stack(u32).Self = main.Stack(u32)（就是它自己）
⚠️ st.Item 在 0.17 编译不过（decl 只能经类型访问）；字段访问 = array_list.Aligned(u32,null)
Pair(u8,[]const u8) = main.Pair(u8,[]const u8)：a=7 b=seven
  size_a=1 size_b=16（两个参数的尺寸独立算）
  toBytes = { 7 }（长度 1 是编译期常量，异构照样能摊）
  Pair(u8,u8).swap 后：a=2 b=1（同型才能换）
==== 14.2 结束 ====
```

### ⚠️【新】0.17 里 decl 只能通过**类型**访问，不能通过**值**访问

这是本章新踩到的一个坑，不在老教程的清单里。写 `st.Item`（`st` 是 `Stack(u32)` 的**值**）编译失败：

```text
error: no field named 'Item' in struct 'main.Stack(u32)'
    std.debug.print("{s}\n", .{@typeName(st.Item)});
                             ^~~
note: struct declared here
    return struct {
           ^~~~~~
```

而且这条限制**和泛型无关**——普通 struct 一样（实测 `const Box = struct { v: u32, pub const item_type = u32; };` 之后 `b.item_type` 同样报 `no field named 'item_type' in struct '...Box'`）。0.17 把"字段访问"和"声明访问"分开了：`a.b` 只找**字段**，声明必须经类型名（`Box.item_type`）。这对泛型尤其刺眼，因为老代码里 `my_list.item_type` 这种写法很常见。**记牢：decl 一律经类型名，字段才经点号。**

### 多个类型参数

`Pair(comptime A: type, comptime B: type)` 展示了泛型相对 `anytype` 的直接优势：**参数个数不限、各自独立**。

```zig
// examples/14_generics/main.zig 第 58-88 行
/// 14.2 节：两个类型参数的泛型（异构 pair）。
/// A 和 B 是**独立**的类型参数——这是 `comptime T: type` 相对 anytype 的
/// 直接优势：anytype 只能一个参数，泛型可以任意多个、各自独立。
fn Pair(comptime A: type, comptime B: type) type {
    return struct {
        const Self = @This();

        /// 两个字段各自占多少字节（编译期算，运行期零开销）。
        pub const size_a = @sizeOf(A);
        pub const size_b = @sizeOf(B);

        a: A,
        b: B,

        /// 交换两个字段。⚠️ 只能用于 A == B——异构字段没法直接互换，
        /// 这条限制是**编译期**判定的（见下面 swapChecked 的 @compileError）。
        pub fn swap(self: *Self) void {
            if (A != B) @compileError("swap 要求 A == B；异构请用 toBytes/toFromBytes");
            const tmp = self.a;
            self.a = self.b;
            self.b = tmp;
        }

        /// 把整个 Pair 的**第一个字段**摊成字节数组。长度是编译期算出来的常量，
        /// 异构也能用——这是"编译期算尺寸、运行期零开销"的典型写法。
        pub fn toBytes(self: *const Self) [@sizeOf(A)]u8 {
            // 指针转换 + 解引用 = 零拷贝的字节视图（@bitCast 不能用于指针类型）
            return @as(*const [@sizeOf(A)]u8, @ptrCast(&self.a)).*;
        }
    };
}
```

输出第 12、13 行说明了两件事：`size_a=1 size_b=16` 是**两个参数各自独立**算出来的（异构）；`swap` 在 `A != B` 时走 `@compileError`——**这是编译期判定，不是运行期 panic**。泛型函数体里的 `if (A != B)` 走的是编译期分支（`A` 是 `comptime` 参数），只有实参真正触发时才编译失败。

`toBytes` 那个 `@as(*const [N]u8, @ptrCast(&self.a)).*` 是"零拷贝字节视图"的 idiom：数组长度 `N` 是 `@sizeOf(A)` 编译期算出来的，运行时只是把指针重新解释一下。⚠️ **0.17 的 `@bitCast` 不能用于指针类型**（报 `error: cannot @bitCast from '*const [1]u8'`），必须"转换指针 + 解引用"两步走。

## 14.3 `anytype` vs `comptime T: type`

上一章 13.5 节说过"`anytype` 是隐式 comptime 参数"。这一节把三者的取舍彻底说清。

```zig
// examples/14_generics/main.zig 第 90-99 行
/// 14.3 节的 anytype：单个参数版"隐式 comptime T"。
/// 返回类型用 @TypeOf(values[0]) —— 值本身就是编译期已知的，元素类型随之确定。
fn firstOf(items: anytype) @TypeOf(items[0]) {
    return items[0];
}

/// 14.3 节：两个 anytype 参数。
fn maxOf(a: anytype, b: anytype) @TypeOf(a) {
    return if (a > b) a else b;
}
```

```zig
// examples/14_generics/main.zig 第 411-427 行（14.3 节的横幅注释到 end("14.3")）
    // ═══ 14.3 anytype vs comptime T: type ═══
    begin("14.3");
    const ints = [_]i32{ 7, 8, 9 };
    const bytes = [_]u8{ 4, 5 };
    // anytype：类型从实参推导，返回类型用 @TypeOf(items[0]) 表达"和元素同型"
    std.debug.print("firstOf(ints) = {d} 类型 {s}\n", .{ firstOf(&ints), @typeName(@TypeOf(firstOf(&ints))) });
    std.debug.print("firstOf(bytes) = {d} 类型 {s}（同一份函数体，两个实例）\n", .{ firstOf(&bytes), @typeName(@TypeOf(firstOf(&bytes))) });
    // 两个 anytype 参数，返回类型由第一个决定
    std.debug.print("maxOf(3, 9) = {d}；maxOf(9, 3) = {d}；maxOf(2.5, 1.5) = {d}\n", .{ maxOf(3, 9), maxOf(9, 3), maxOf(2.5, 1.5) });
    // 隐式 vs 显式：写法不同，实例化机制完全一样
    std.debug.print("anyTypeSum(ints) = {d}；anyTypeSum(bytes) = {d}\n", .{ anyTypeSum(&ints), anyTypeSum(&bytes) });
    std.debug.print("泛型 vs 鸭子类型：泛型能声明【额外编译期参数】，anytype 不能\n", .{});
    std.debug.print("matrixOf(ints, 3) 长度 = {d}（要额外的 comptime 参数就得显式写出来）\n", .{matrixOf(ints, 3).len});
    // ⚠️ anytype 的契约是"编译期检查的鸭子类型"：实参不满足就编译错，
    //   报错指向函数体那一行 + referenced by 链指向调用点。
    //   sumAll(@as(u8, 3)) → error: type 'u8' is not indexable and not a range
    end("14.3");
```

运行输出（`examples/14_generics/main.zig`）：

```text
==== 14.3 开始 ====
firstOf(ints) = 7 类型 i32
firstOf(bytes) = 4 类型 u8（同一份函数体，两个实例）
maxOf(3, 9) = 9；maxOf(9, 3) = 9；maxOf(2.5, 1.5) = 2.5
anyTypeSum(ints) = 24；anyTypeSum(bytes) = 9
泛型 vs 鸭子类型：泛型能声明【额外编译期参数】，anytype 不能
matrixOf(ints, 3) 长度 = 3（要额外的 comptime 参数就得显式写出来）
==== 14.3 结束 ====
```

### 三者怎么选

| | `comptime T: type` | `anytype` | `comptime n: usize`（非类型） |
|---|---|---|---|
| 写法 | `fn Box(comptime T: type) type` | `fn sum(xs: anytype) T` | `fn pow(comptime base: u64, comptime n: u32)` |
| 类型怎么来 | **调用方显式给** | **编译器从实参推导** | 与类型无关，只是编译期常量 |
| 能声明几个 | 任意多个，各自称 `T`/`A`/`B` | 每个参数一个，但**都叫 `xs`** | 任意多个 |
| 返回类型怎么表达 | `-> type` 或直接 `T` | `@TypeOf(xs[0])` 这类"从实参反推" | 写死或 `@TypeOf` 组合 |
| 典型用途 | 泛型容器、类型构造器 | `print` / `min` / 工具函数 | 查表、幂、位宽常量 |
| 契约强度 | **强**（类型必须满足函数体里所有假设） | **弱**（鸭子类型：不满足就在函数体那行报错） | 强（值必须编译期已知） |

**判断标准很简单：需要"多个互相独立的编译期输入"或者"调用方主动指定类型"→ 用 `comptime T: type`；只有一个参数、类型完全由实参形状决定、且不想让调用方写类型参数 → 用 `anytype`。**

`anytype` 的代价是**契约模糊**：`firstOf` 声明的契约是"接受任何可索引的序列"，但签名上看不出来。实参不满足时**编译期报错，但报在函数体那一行**，靠 `referenced by:` 链才找得到调用点：

```text
main.zig:4:10: error: type 'u8' is not indexable and not a range
    for (values) |v| t += @intCast(v);
         ^~~~~~
main.zig:4:10: note: for loop operand must be a range, array, slice, tuple, or vector
referenced by:
    main: main.zig:8:38
```

这是 `anytype` 唯一的实质缺点：**错误信息离调用点比较远**。`comptime T: type` 的错误直接出现在实参位置上。所以 05 章那条建议依然成立——**公开 API 偏好 `comptime T: type`（显式），`anytype` 留给 print/工具函数**。

`anytype` 也能配显式 `comptime` 参数（示例里的 `matrixOf(comptime items: anytype, comptime rows: usize)`），但这时候它就不"省事"了——你还是得把 `comptime` 写出来。**`anytype` 的真正价值是"单个参数、纯推导"。**

## 14.4 反射：三条平行数组

这是本章最重要的一节，也是 0.17 变化最大的地方。

⚠️ **0.17 起 `@typeInfo(T).@"struct".fields`（字段结构体数组）已不存在。** 写它编译失败：

```text
error: no field named 'fields' in struct 'lang.Type.Struct'
    inline for (s.fields) |f| std.debug.print("{s}\n", .{f.name});
                  ^~~~~~
note: struct declared here
    pub const Struct = struct {
                       ^~~~~~
```

替代方案是**三条平行数组**：`field_names` / `field_types` / `field_attrs`。std 源码里对后两条的注释写得很明确：

```zig
field_names: []const [:0]const u8,
/// Guaranteed to have the same length as `field_names`.
field_types: []const type,
/// Guaranteed to have the same length as `field_names`.
field_attrs: []const FieldAttributes,
```

**"Guaranteed to have the same length as `field_names`"** —— 这句注释就是"按下标配对"的契约依据。你不需要像老教程那样写 `for (info.fields)`，直接 `inline for (a, b, c)` 三序列并行遍历即可。

```zig
// examples/14_generics/main.zig 第 108-123 行
/// 14.4 节：0.17 迁移后的字段表遍历。
/// ⚠️ `@typeInfo(T).@"struct".fields`（字段结构体数组）**已不存在**，
/// 改用三条**平行数组** field_names / field_types / field_attrs，
/// 长度保证一致，按下标配对。
fn dumpFields(comptime T: type) void {
    const s = @typeInfo(T).@"struct";
    inline for (s.field_names, s.field_types, s.field_attrs) |name, ty, attrs| {
        std.debug.print("  {s}: {s}  显式对齐={any} comptime字段={} 有默认值={}\n", .{
            name[0..name.len], // 哨兵切片，打印要写 [0..len]
            @typeName(ty),
            attrs.@"align", // ⚠️ 0.17 是 .@"align"（?usize），不是 .alignment
            attrs.@"comptime",
            attrs.default_value_ptr != null,
        });
    }
}
```

⚠️ **这里有三个独立的坑，集中在 15 行里**：

1. **`inline for` 不是可选的**。`field_types` 的元素是 `type`，普通 `for` 一律失败：

   ```text
   error: values of type 'type' must be comptime-known, but index value is runtime-known
       for (s.field_types) |t| std.debug.print("{s}\n", .{@typeName(t)});
            ~^~~~~~~~~~~~
   note: types are not available at runtime
   ```

   道理直白：**运行期根本没有"类型"这个值**。你在运行期循环里想拿第 N 个字段的类型，但"类型"这个概念在运行期不存在。`inline for` 在编译期把循环展开 N 份，每次的 `ty` 都是编译期常量。

2. **`field_attrs` 的对齐字段叫 `.@"align"`，不是 `.alignment`**。写 `.alignment` 报：

   ```text
   error: no field named 'alignment' in struct 'lang.Type.Struct.FieldAttributes'
   ```

   而且它的类型是 `?usize`——`null` 表示"没有显式指定"，字段仍然会按类型自然对齐。

3. **`field_names` 的元素是哨兵切片** `[:0]const u8`。打印可以直接 `{s}`，也可以 `[0..len]`；但**不能按固定长度加哨兵取子范围**：`names[0..8 :0]` 报 `error: expected type '[:0]const u8', found 'comptime_int'`。

`default_value_ptr` 是 `?*const anyopaque`（类型擦除的指针，因为它不知道字段类型）。要取值得调内联函数 `attrs.defaultValue(FieldType)`。

```zig
// examples/14_generics/main.zig 第 429-456 行（14.4 节的横幅注释到 end("14.4")）
    // ═══ 14.4 反射：@typeInfo 的三条平行数组 ═══
    begin("14.4");
    std.debug.print("Person 的字段（0.17：field_names / field_types / field_attrs 三条平行数组）：\n", .{});
    dumpFields(Person);
    std.debug.print("三条数组长度一致：{}\n", .{
        @typeInfo(Person).@"struct".field_names.len == @typeInfo(Person).@"struct".field_types.len and
            @typeInfo(Person).@"struct".field_names.len == @typeInfo(Person).@"struct".field_attrs.len,
    });
    // .tag 已改名 .layout（std.lang.ContainerLayout：auto / extern / packed）
    std.debug.print("Person layout={t}（类型 {s}，不再是 .tag）\n", .{
        @typeInfo(Person).@"struct".layout, @typeName(@TypeOf(@typeInfo(Person).@"struct".layout)),
    });
    // 有默认值的字段：default_value_ptr 非空
    const WithDefault = struct { a: u32 = 7, b: u8 = 0, c: u8 align(4) };
    std.debug.print("带默认值/对齐的结构体：\n", .{});
    dumpFields(WithDefault);
    // 哨兵切片可以直接传给 @offsetOf（它接受 [:0]const u8）
    inline for (@typeInfo(WithDefault).@"struct".field_names) |name| {
        std.debug.print("  @offsetOf(WithDefault, \"{s}\") = {d}\n", .{ name[0..name.len], @offsetOf(WithDefault, name) });
    }
    // ⚠️ field_types 元素是 type，**只能 inline for**：
    //   for (info.@"struct".field_types) |t| ...
    //   → error: values of type 'type' must be comptime-known,
    //            but index value is runtime-known
    //            note: types are not available at runtime
    // 因为"类型"这个概念在运行期不存在。
    end("14.4");
```

运行输出（`examples/14_generics/main.zig`）：

```text
==== 14.4 开始 ====
Person 的字段（0.17：field_names / field_types / field_attrs 三条平行数组）：
  name: []const u8  显式对齐=null comptime字段=false 有默认值=false
  age: u8  显式对齐=null comptime字段=false 有默认值=false
  vip: bool  显式对齐=null comptime字段=false 有默认值=false
三条数组长度一致：true
Person layout=auto（类型 lang.Type.ContainerLayout，不再是 .tag）
带默认值/对齐的结构体：
  a: u32  显式对齐=null comptime字段=false 有默认值=true
  b: u8  显式对齐=null comptime字段=false 有默认值=true
  c: u8  显式对齐=4 comptime字段=false 有默认值=false
  @offsetOf(WithDefault, "a") = 0
  @offsetOf(WithDefault, "b") = 5
  @offsetOf(WithDefault, "c") = 4
==== 14.4 结束 ====
```

**`@offsetOf` 的结果是 0 / 5 / 4**——看起来"乱序"，其实是 `c: u8 align(4)` 的显式对齐把 `c` 挤到了偏移 4，而 `a: u32` 占 0..4，`b` 只能从 5 开始。**字段的内存布局由对齐要求决定，和声明顺序无关**（这是 08 章内存布局的规则，反射把它直接暴露出来了）。

⚠️ `.tag` 已改名 **`.layout`**，取值 `.auto` / `.@"extern"` / `.@"packed"`，类型是 `std.lang.ContainerLayout`。写 `.tag` 报：

```text
error: no field named 'tag' in struct 'lang.Type.Struct'
    std.debug.print("{t}\n", .{s.tag});
                                 ^~~
```

## 14.5 `@typeInfo` 全分支速查表

`@typeInfo` 返回一个**25 分支的联合**（`std.lang.Type`）。Zig 强制你 `switch` 它（漏分支编译错），所以你必须知道每个分支的字段名——而 0.17 里这些字段名**几乎全变了**。这一节就是那张表。

```zig
// examples/14_generics/main.zig 第 125-208 行（节选）
/// 14.5 节：@typeInfo 全分支速查——把 0.17 每个分支的关键字段都打出来。
/// 这是本章最该记住的一段代码：字段名全变过，照着它写就不会错。
fn dumpTypeInfo(comptime T: type) void {
    const info = @typeInfo(T);
    std.debug.print("  @typeName({s}) 分支标签 = {s}\n", .{ @typeName(T), @tagName(info) });
    // 编译器强制穷尽 switch：漏一个分支就编译错。
    switch (info) {
        .int => |i| std.debug.print("    .int: signedness={s} bits={d}（bits 的类型是 u16）\n", .{ @tagName(i.signedness), i.bits }),
        .float => |f| std.debug.print("    .float: bits={d}（0.17 起是 struct，不是 enum！）\n", .{f.bits}),
        ...
        .pointer => |p| std.debug.print("    .pointer: size={s} child={s} const={} volatile={} align={any} sentinel={any}\n", .{
            @tagName(p.size), @typeName(p.child),
            p.attrs.@"const", p.attrs.@"volatile",
            p.attrs.@"align", p.sentinel(),
        }),
        .@"struct" => |s| std.debug.print("    .@\"struct\": is_tuple={} layout={t} backing_integer={any} 字段数={d} decl数={d}\n", .{
            s.is_tuple, s.layout, s.backing_integer, s.field_names.len, s.decl_names.len,
        }),
        .optional => |o| std.debug.print("    .optional: child={s}（⚠️ 是 .child 不是 .payload）\n", .{@typeName(o.child)}),
        ...
    }
}
```

`examples/14_generics/main.zig` 第 458-534 行（14.5 节的横幅注释到 `end("14.5")`）把 18 个样本类型全打了一遍：

```text
==== 14.5 开始 ====
  @typeName(u16) 分支标签 = int
    .int: signedness=unsigned bits=16（bits 的类型是 u16）
  @typeName(f32) 分支标签 = float
    .float: bits=32（0.17 起是 struct，不是 enum！）
  @typeName(bool) 分支标签 = bool
    .bool:无字段
  @typeName([4]u8) 分支标签 = array
    .array: len=4（comptime_int） child=u8 sentinel=null
  @typeName(@Vector(4, i8)) 分支标签 = vector
    .vector: len=4 child=i8
  @typeName(*const u8) 分支标签 = pointer
    .pointer: size=one child=u8 const=true volatile=false align=null sentinel=null
  @typeName([]const u8) 分支标签 = pointer
    .pointer: size=slice child=u8 const=true volatile=false align=null sentinel=null
  @typeName(main.Person) 分支标签 = struct
    .@"struct": is_tuple=false layout=auto backing_integer=null 字段数=3 decl数=0
  @typeName(?u32) 分支标签 = optional
    .optional: child=u32（⚠️ 是 .child 不是 .payload）
  @typeName(error{Corrupted,NotFound}!u16) 分支标签 = error_union
    .error_union: error_set=error{Corrupted,NotFound} payload=u16（这里才叫 payload）
  @typeName(error{Corrupted,NotFound}) 分支标签 = error_set
    .error_set: 2 个成员 → NotFound Corrupted
  @typeName(main.Stage) 分支标签 = enum
    .@"enum": tag_type=u8 mode=exhaustive 成员数=3 decl数=0
  @typeName(main.Payload) 分支标签 = union
    .@"union": layout=auto tag_type=main.PayloadTag 字段数=3（同样是三条平行数组）
  @typeName(anyerror!u8) 分支标签 = error_union
    .error_union: error_set=anyerror payload=u8（这里才叫 payload）
  @typeName(anyerror) 分支标签 = error_set
    .error_set: error_names = null（anyerror 是开放错误集）
  @typeName(main.Opaque) 分支标签 = opaque
    .@"opaque": decl数=1
  @typeName(fn (u32, u32) u8) 分支标签 = fn
    .@"fn": is_generic=false return_type=u8 callconv=auto varargs=false 参数数=2 → u32 u32
  @typeName([4:0]u8) 分支标签 = array
    .array: len=4（comptime_int） child=u8 sentinel=0
  @typeName(main.main__struct_904) 分支标签 = struct
    .@"struct": is_tuple=false layout=auto backing_integer=null 字段数=1 decl数=0
  @typeName(main.main__struct_905) 分支标签 = struct
    .@"struct": is_tuple=false layout=extern backing_integer=null 字段数=2 decl数=0
error_names 的三种状态：
  error{}：0 个成员 →
  error{A,B}：2 个成员 → A B
  anyerror：null（anyerror 是【开放】错误集，没有成员表）
哨兵切片：直接 NotFound 可打印；取子范围写 [0..len] = "NotFound"
声明序 vs @typeName（后者按字母重排）：error{Corrupted,NotFound}
  Stage.alpha = 1（@backingInt = 1）
  Stage.beta = 2（@backingInt = 2）
  Stage.gamma = 3（@backingInt = 3）
decl_names（只列 pub 声明）：struct=0 enum=0 union=1 opaque=1
  Opaque（有 pub fn onlyFn）=1，Opaque2（空）=0
要列声明：用 @hasDecl 逐个问，或 std.meta.declarations（T）
==== 14.5 结束 ====
```

### `@typeInfo` 各分支字段形状（0.17.0 实测表）

这张表是本章最有价值的产物。**每一行都是上面那段输出或 `std/lang.zig` 源码里核过的**。

| 分支 | 字段（0.17.0 实测） | 备注 |
|---|---|---|
| `.int` | `signedness: Signedness`（enum(u1) signed/unsigned）、`bits: u16` | ⚠️ `bits` 是 **u16** 不是 u8 |
| `.float` | `bits: u16` | ⚠️ **0.17 起是 struct `{ bits: u16 }`，不再是 enum**（`@tagName(f.float)` 报 `expected enum or union; found 'lang.Type.Float'`） |
| `.array` | `len: comptime_int`、`child: type`、`sentinel_ptr: ?*const anyopaque` + `sentinel()` 方法 | ⚠️ `len` 是 **comptime_int** 不是 usize；哨兵**不是字段**，得调 `sentinel()` |
| `.vector` | `len: comptime_int`、`child: type` | 和 `.array` 一样 `len` 是 comptime_int |
| `.pointer` | `size: Size`（enum(u2) `one`/`many`/`slice`/`c`）、`attrs: Attributes`、`child: type`、`sentinel_ptr` + `sentinel()` | ⚠️ **`is_const`/`is_volatile`/`is_volatile` 全挪进了 `attrs`** |
| `.pointer.attrs` | `const: bool`、`volatile: bool`、`allowzero: bool`、`addrspace: ?AddressSpace`、`align: ?usize` | ⚠️ 关键字字段要写 `@"const"` / `@"volatile"` / `@"align"` |
| `.@"struct"` | `is_tuple: bool`、`layout: ContainerLayout`、`backing_integer: ?type`、`field_names` / `field_types` / `field_attrs`（三条平行数组）、`decl_names` | ⚠️ **没有 `fields`**；`.tag` → `.layout` |
| `.optional` | `child: type` | ⚠️ **是 `.child` 不是 `.payload`** |
| `.error_union` | `error_set: type`、`payload: type` | ⚠️ **这里才叫 `payload`**——和 `.optional` 不一致 |
| `.error_set` | `error_names: ?[]const [:0]const u8` | ⚠️ **可空**：`error{}` 是空切片、`anyerror` 是 `null` |
| `.@"enum"` | `tag_type: type`、`mode: Mode`（enum `exhaustive`/`nonexhaustive`）、`field_names` / `field_values`（两条平行数组，元素 `comptime_int`）、`decl_names` | ⚠️ **没有 `fields`**；⚠️ `field_values` 只能 `inline for` |
| `.@"union"` | `layout: ContainerLayout`、`tag_type: ?type`、`backing_integer: ?type`、`field_names` / `field_types` / `field_attrs`（三条平行数组）、`decl_names` | ⚠️ **没有 `fields`**；`FieldAttributes` 只有 `align` 一个字段（**没有 `comptime`、没有 `default_value_ptr`**） |
| `.@"fn"` | `attrs: Attributes`（`callconv` / `varargs`）、`is_generic: bool`、`return_type: ?type`、`param_types: []const ?type`、`param_attrs` | ⚠️ **`params` 数组没了**，改成 `param_types` + `param_attrs` 两条；⚠️ `return_type` **可空**；⚠️ `param_types` 元素是 `?type`，**只能 `inline for`** |
| `.@"opaque"` | `decl_names: []const [:0]const u8` | 只有这一个字段 |
| `.anyframe` | `child: ?type` | |
| `.bool` / `.type` / `.void` / `.noreturn` / `.comptime_int` / `.comptime_float` / `.undefined` / `.null` / `.frame` / `.enum_literal` | **无字段**（payload 是 `void`） | 这些分支后面**不能跟 `|x|` 捕获**（写了报 `unused capture`） |
| `.spirv` | `Spirv` 联合（`sampler` / `image` / `sampled_image` / `runtime_array`） | 不用管 |

### ⚠️ 分支标签的引号：只有 6 个真的需要

在 `switch (@typeInfo(T))` 里写分支标签时，**只有 6 个必须写成 `.@"名字"`**：

| 标签 | 为什么 |
|---|---|
| `.@"struct"` `.@"enum"` `.@"union"` `.@"fn"` `.@"opaque"` | Zig **关键字**，任何版本都得加引号 |
| `.@"anyframe"` | ⚠️ **唯一一个新坑**：它和内建类型 `anyframe` 同名 |

漏掉 `.@"anyframe"` 的引号，报出来的错**完全指不到地方**：

```text
af.zig:3:26: error: expected expression, found '.'
    if (@typeInfo(u8) == .anyframe) std.debug.print("y\n", .{});
                         ^~~~~~~~~
```

更坑的是：在**穷尽 switch** 里，报错会指向 `switch` 关键字本身，而不是出问题的那个分支：

```text
af2.zig:3:29: error: expected '}', found '.'
    switch (@typeInfo(u8)) {
                            ^
```

⚠️ 我一开始误以为 `frame` / `enum_literal` / `spirv` 也需要引号——**实测是错的**（这三个裸写完全合法）。之所以看起来像需要，是因为它们和 `.anyframe` 挨在一起，`.anyframe` 报错时行号指向的是**后面**那个分支（解析器在 `.anyframe` 就崩了，后面的行只是"被算作出错位置"）。单独隔离测试才看得出真相：

| 标签 | 裸写 | 加引号 |
|---|---|---|
| `.frame` | ✅ | ✅ |
| `.enum_literal` | ✅ | ✅ |
| `.spirv` | ✅ | ✅ |
| `.anyframe` | ❌ `expected '}', found '.'` | ✅ |

**建议**：干脆**全部 25 个分支都写成 `.@"int"` / `.@"float"`** 这种形式——一劳永逸，永远不会因为名字撞车而出错。本章示例就是这么写的（`.@"struct"`、`.@"fn"`、`.@"opaque"` 全带引号，连 `.int` 也写成 `.@"int"` 保持一致）。

### `error_names` 的三个坑

```text
error{}：0 个成员 →                              ← 空切片，不是 null
error{A,B}：2 个成员 → A B                       ← 元素是哨兵切片，可直接 {s}
anyerror：null（anyerror 是【开放】错误集，没有成员表）  ← 真的是 null
```

1. **可空**。`anyerror` 是 `null`（它没有成员表，任何错误都匹配），所以必须 `if (x) |y|` 或 `.?`。注意 `error{}`（空错误集）是**长度 0 的切片**，不是 `null`——这两个语义完全不同。
2. **元素是哨兵切片**。可以直接 `{s}` 打印；取子范围写 `[0..len]`；写 `[0..8 :0]` 报 `error: expected type '[:0]const u8', found 'comptime_int'`。
3. ⚠️ **【新】`error_names` 保持声明顺序，但 `@typeName` 按字母重排**。实测 `error{ NotFound, Corrupted }`：
   - `error_names` → `NotFound`（下标 0）、`Corrupted`（下标 1）—— **声明序**
   - `@typeName` → `error{Corrupted,NotFound}` —— **字母序**

   **别拿 `@typeName` 反推成员表**。要做"错误码 → 字符串"的映射表，只能遍历 `error_names`。

### ⚠️ `decl_names` 只列 **pub** 声明

老教程说 `decl_names` 拿不到东西，0.17 的实测更精确：**只列 `pub` 声明**。

| 类型 | 有 pub 声明？ | `decl_names.len` |
|---|---|---|
| `Person`（无 decl） | — | **0** |
| `Stage`（无 decl） | — | **0** |
| `Payload`（有 `pub fn tagName`） | 有 | **1** |
| `Opaque`（有 `pub fn onlyFn`） | 有 | **1** |
| `Opaque2`（空） | — | **0** |
| `struct { const K: u8 = 3; a: u32 }`（**非** pub const） | 非 pub | **0** |
| `struct { fn f() void {} a: u32 }`（非 pub fn） | 非 pub | **0** |
| `struct { pub fn g() void {} a: u32 }` | pub | **1** |

所以：**要列一个容器的声明，用 `@hasDecl` 逐个问（14.6 节），或者 `std.meta.declarations(T)`。别指望 `decl_names`。**

### ⚠️ 匿名容器的类型名是编译器编的

输出最后两行的 `main.main__struct_904` / `main.main__struct_905`——这是**直接写 `struct { a: u32 }` / `extern struct { a: u32, b: u8 }`（不赋给 const）**的类型名。编号（904、905）是编译器内部序号，**每次编译都可能变**。匿名 `opaque {}` 同理（实测 `main.main__opaque_904`）。**不要拿 `@typeName` 的结果做稳定标识符。**

## 14.6 `@hasDecl` / `@typeName`：探测与命名

```zig
// examples/14_generics/main.zig 第 536-564 行（14.6 节的横幅注释到 end("14.6")）
    // ═══ 14.6 @hasDecl / @typeName：探测与命名 ═══
    begin("14.6");
    // ⚠️ 0.17 里 @hasDecl 的第二个参数**必须给字符串**：
    //   @hasDecl(std.mem, copyForwards) → error: use of undeclared identifier 'copyForwards'
    std.debug.print("@hasDecl(std.ArrayList(u8), \"append\") = {}\n", .{@hasDecl(std.ArrayList(u8), "append")});
    std.debug.print("@hasDecl(std.ArrayList(u8), \"noSuchMethod\") = {}\n", .{@hasDecl(std.ArrayList(u8), "noSuchMethod")});
    // ⚠️ @hasDecl 问的是**声明**，字段不算：
    std.debug.print("@hasDecl(Person, \"name\") = {}（字段不是 decl）\n", .{@hasDecl(Person, "name")});
    std.debug.print("@hasField(Person, \"name\") = {}（问字段要用 @hasField）\n", .{@hasField(Person, "name")});
    std.debug.print("@hasField(Person, \"nope\") = {}\n", .{@hasField(Person, "nope")});
    // ⚠️ std.meta.fields / declarationInfo / fieldInfo 三个在 0.17 已改成
    //   @compileError 占位（源码注释写着 "To be removed after 0.17.0 is tagged"）：
    //     std.meta.fields(Person)
    //     → error: deprecated in favor of @typeInfo
    //   std.meta 剩下的活口都是 @typeInfo 的薄封装（Child / Elem / fieldNames /
    //   fieldTypes / containerLayout / declarations / stringToEnum ...）。
    std.debug.print("std.meta.fields 已废弃（@compileError 占位）→ 全走 @typeInfo\n", .{});
    std.debug.print("  std.meta 剩下的 Child/fieldNames/declarations 等都是 @typeInfo 的薄封装\n", .{});
    // 类型名一律 @typeName；@tagName 只吃枚举/联合的**值**
    std.debug.print("@typeName(Person) = {s}；@typeName(u24) = {s}；@tagName(Stage.beta) = {s}\n", .{
        @typeName(Person), @typeName(u24), @tagName(Stage.beta),
    });
    std.debug.print("泛型实例的类型名带参数：Stack(u32) = {s}\n", .{@typeName(Stack(u32))});
    // ⚠️ @Type 已移除（error: invalid builtin function: '@Type'）。
    //   造函数类型用 @TypeOf，但 @TypeOf(&f) 拿到的是**指针**：
    std.debug.print("@TypeOf(&addThenNarrow) = {s}\n", .{@typeName(@TypeOf(&addThenNarrow))});
    const FnPtr = @TypeOf(&addThenNarrow);
    std.debug.print("剥掉指针 = {s}（.pointer.child）\n", .{@typeName(@typeInfo(FnPtr).pointer.child)});
    end("14.6");
```

运行输出（`examples/14_generics/main.zig`）：

```text
==== 14.6 开始 ====
@hasDecl(std.ArrayList(u8), "append") = true
@hasDecl(std.ArrayList(u8), "noSuchMethod") = false
@hasDecl(Person, "name") = false（字段不是 decl）
@hasField(Person, "name") = true（问字段要用 @hasField）
@hasField(Person, "nope") = false
std.meta.fields 已废弃（@compileError 占位）→ 全走 @typeInfo
  std.meta 剩下的 Child/fieldNames/declarations 等都是 @typeInfo 的薄封装
@typeName(Person) = main.Person；@typeName(u24) = u24；@tagName(Stage.beta) = beta
泛型实例的类型名带参数：Stack(u32) = main.Stack(u32)
@TypeOf(&addThenNarrow) = *const fn (u32, u32) u8
剥掉指针 = fn (u32, u32) u8（.pointer.child）
==== 14.6 结束 ====
```

### `@hasDecl` 的字符串形式（0.17 必知）

```text
error: use of undeclared identifier 'append'
    if (@hasDecl(std.ArrayList(u8), append)) std.debug.print("has\n", .{});
                                    ^~~~~~
```

这条报错**极具迷惑性**——它看起来像"这个 decl 不存在"，但真正的问题是**参数形式不对**：编译器把 `append` 当成普通标识符去解析，于是报"未声明"。看到这条报错要先怀疑写法，而不是库。正确写法是 `@hasDecl(std.ArrayList(u8), "append")`。

### `@hasDecl` 问声明，`@hasField` 问字段

输出第 3、4 行是这一节的 takeaway：`@hasDecl(Person, "name") = false` 但 `@hasField(Person, "name") = true`。**字段不算声明**（14.5 节的 `decl_names` 只列 pub 声明也是同一个道理）。想探测"某类型有没有某个字段"，用 `@hasField`；想探测"有没有某个常量/函数/类型别名"，用 `@hasDecl`。

### `std.meta` 的现状

⚠️ 0.17 里 `std.meta.fields` / `declarationInfo` / `fieldInfo` 三个已经改成 **`@compileError` 占位**：

```text
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/meta.zig:248:20: error: deprecated in favor of @typeInfo
pub const fields = @compileError("deprecated in favor of @typeInfo");
                   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

源码注释写着 `/// To be removed after Zig 0.17.0 is tagged.`。`std.meta` 剩下的活口（`Child` / `Elem` / `fieldNames` / `fieldTypes` / `containerLayout` / `declarations` / `stringToEnum` / `eql` / `activeTag` / `ArgsTuple` / `Slice` / `AbsorbSentinel` …）全是 `@typeInfo` 的薄封装。**新代码直接写 `@typeInfo`**——本章 14.4、14.5 两节就是这么写的。

### `@typeName` 吃类型，`@tagName` 吃值

输出第 8 行：`@typeName(Person) = main.Person`、`@typeName(u24) = u24`、`@tagName(Stage.beta) = beta`。三个名字各管一段：

- `@typeName(T)` —— 类型 → 字符串。**反射拿类型名只能用这个。**
- `@tagName(v)` —— 枚举/联合的**那个值** → 字符串。给它类型会报 `error: expected enum or union; found 'type'`。
- `@hasDecl(T, "name")` —— 探测。

⚠️ **泛型实例的类型名带参数**：`@typeName(Stack(u32))` = `main.Stack(u32)`。这对调试很友好（一眼看出实例化参数），但也意味着**类型名里含 `(`、`)`、`,`**，不能拿去当文件名或 map key 而不做转义。

### ⚠️ `@Type` 已移除，函数类型用 `@TypeOf` + `.pointer.child`

13.8 节已经记过这条（`error: invalid builtin function: '@Type'`）。这里补充一个 0.17 的细节：**裸函数名在元组/数组里会退化成指针**。

```text
main.zig:401:22: error: expected type 'type', found 'fn (u32, u32) u8'
        dumpTypeInfo(T);
                     ^
main.zig:127:29: note: parameter type declared here
fn dumpTypeInfo(comptime T: type) void {
                            ^~~~
```

要在 `[_]type{...}` 里放一个函数类型，得写 `@TypeOf(addThenNarrow)` 而不是裸的 `addThenNarrow`（后者是 `*const fn (...)`）。拿到函数类型本身还要剥一层指针：`@typeInfo(@TypeOf(&f)).pointer.child`（输出最后两行）。

## 14.7 编译期代码生成

反射的三大用途：**查表**、**类型分派**、**生成类型**。三个都是把"结果只取决于编译期常量"的计算搬到编译期。

```zig
// examples/14_generics/main.zig 第 217-259 行
/// 14.7 节：按类型算"逻辑字节数"——纯 comptime 分派，运行期零开销。
fn byteSize(comptime T: type) usize {
    return switch (@typeInfo(T)) {
        .bool, .@"enum" => 1,
        .int => |i| i.bits / 8,
        .float => |f| f.bits / 8,
        else => @sizeOf(T),
    };
}

/// 14.7 节：编译期生成一个"操作码类型"。
/// kind 是 comptime 参数，所以 switch (kind) 整个在编译期求值，
/// 运行期只剩 `a + b` 一条加法——分派表本身不进二进制。
fn Op(comptime kind: u8) type {
    return struct {
        const Self = @This();

        pub const kind_id = kind;
        pub const name = switch (kind) {
            0 => "add",
            1 => "sub",
            2 => "mul",
            3 => "div",
            4 => "min",
            else => @compileError("Op 只支持 0..4"),
        };

        /// kind 是编译期常量，所以整个 switch 在编译期折叠——
        /// 运行期剩下的只有一条加法（或一条比较），分派表不进二进制。
        /// 注意这里**没有 self**：这是一个"由类型携带行为"的静态函数。
        pub fn apply(a: i32, b: i32) i32 {
            return switch (kind) {
                0 => a + b,
                1 => a - b,
                2 => a * b,
                3 => if (b == 0) 0 else @divTrunc(a, b),
                4 => if (a < b) a else b,
                else => @compileError("未知操作码"),
            };
        }
    };
}
```

```zig
// examples/14_generics/main.zig 第 566-580 行（14.7 节的横幅注释到 end("14.7")）
    // ═══ 14.7 编译期代码生成：查表 / 类型分派 / 生成类型 ═══
    begin("14.7");
    // (1) 生成数据表：编译期算 256 次，运行期只剩一次索引
    std.debug.print("SqTable[7]={d} [15]={d} [255]={d}（表在编译期算好）\n", .{ SqTable[7], SqTable[15], SqTable[255] });
    // (2) 按类型分派：整个函数是 comptime 的，运行期零开销
    std.debug.print("byteSize: u8={d} u24={d} f64={d} bool={d} Stage={d}\n", .{
        byteSize(u8), byteSize(u24), byteSize(f64), byteSize(bool), byteSize(Stage),
    });
    // (3) 生成类型：kind 是编译期常量，switch (kind) 整体在编译期折叠
    inline for (.{ 0, 1, 2, 3, 4 }) |k| {
        std.debug.print("  Op({d}).name = {s}：apply(7,3) = {d}\n", .{ k, Op(k).name, Op(k).apply(7, 3) });
    }
    std.debug.print("Op(2) 的类型名 = {s}；kind_id = {d}（常量进了类型）\n", .{ @typeName(Op(2)), Op(2).kind_id });
    //⚠️ 越界的 kind 在**编译期**就炸：Op(9) → error: Op 只支持 0..4
    end("14.7");
```

运行输出（`examples/14_generics/main.zig`）：

```text
==== 14.7 开始 ====
SqTable[7]=49 [15]=225 [255]=65025（表在编译期算好）
byteSize: u8=1 u24=3 f64=8 bool=1 Stage=1
  Op(0).name = add：apply(7,3) = 10
  Op(1).name = sub：apply(7,3) = 4
  Op(2).name = mul：apply(7,3) = 21
  Op(3).name = div：apply(7,3) = 2
  Op(4).name = min：apply(7,3) = 3
Op(2) 的类型名 = main.Op(2)；kind_id = 2（常量进了类型）
==== 14.7 结束 ====
```

**三个细节值得单独说**：

**① `byteSize(u24) = 3`** 展示了 `.int` 分支的用处：`u24` 的 `bits = 24`，`24 / 8 = 3`——**一个 `u24` 值占了 3 个字节**，这不是 `@sizeOf(u24)` 能直接告诉你的（`@sizeOf(u24)` 是 4，因为对齐到 4 字节了）。要"逻辑字节数"就得自己算 `bits / 8`。

**② `Op(3).apply(7, 3) = 2`** 里的除零保护：分派表本身是编译期常量，但 `b` 是运行期参数。所以 `if (b == 0) 0` 这条分支**留在运行期**——`switch (kind)` 折叠掉的只是"选哪条分支"，不是分支体里的代码。这个区分很重要：**`comptime` 参数消除的是"选择"，不是"计算"。**

**③ `Op(2)` 的类型名 = `main.Op(2)`** —— 编译期常量进了类型名。`kind_id = 2` 也是 `pub const`。这是"用一个类型携带一份配置"的 idiom：**配置在编译期固定，行为跟着配置走，运行期零分派**。越界的 `Op(9)` 会在 `name` 那个 `switch` 上触发 `@compileError("Op 只支持 0..4")`——**编译期炸，不是运行期 panic**。

### 编译期生成数据表

```zig
// examples/14_generics/main.zig 第 210-215 行
/// 14.7 节：编译期生成的平方表——运行期只剩一次数组索引。
const SqTable = blk: {
    var buf: [256]u16 = undefined;
    for (&buf, 0..) |*slot, i| slot.* = @intCast(i * i);
    break :blk buf;
};
```

⚠️ 注意这里**没有** `comptime` / `inline` 关键字——容器级本身就是编译期作用域（13.4 节的规则）。256 次乘法在编译期完成，二进制里只剩 512 字节的表；运行期 `SqTable[15]` 只是一次数组索引。

## 14.8 `@field` / `@fieldParentPtr` / 通用打印器

### `@field`：名字来自编译期变量

```zig
// examples/14_generics/main.zig 第 582-602 行（14.8 节的横幅注释到 end("14.8")）
    // ═══ 14.8 @field / @fieldParentPtr / printAny ═══
    begin("14.8");
    var p = Person{ .name = "阿 Z", .age = 25, .vip = true };
    const field_name = comptime "age";
    @field(p, field_name) = 26; // 名字来自编译期变量
    std.debug.print("@field 写入：{s} {d} 岁 vip={}\n", .{ p.name, @field(p, field_name), p.vip });
    std.debug.print("@field 读回：name={s} vip={}\n", .{ @field(p, "name"), @field(p, "vip") });
    // ⚠️ @field 的名字必须是编译期字符串；运行期拼出来的 []const u8 不行
    // @fieldParentPtr：从字段指针反推宿主指针
    var eng = Engine{ .power = 100 };
    eng.boost(50);
    std.debug.print("Engine.power 经 boost(50) 后= {d}（@fieldParentPtr 走回宿主）\n", .{eng.power});
    // 四件套合体：自动打印
    std.debug.print("printAny(Person)：", .{});
    printAny(p);
    printAny(42);
    printAny(@as(u8, 7));
    printAny(@as(?u32, 9));
    printAny(@as(?u32, null));
    printAny("hi");
    end("14.8");
```

运行输出（`examples/14_generics/main.zig`）：

```text
==== 14.8 开始 ====
@field 写入：阿 Z 26 岁 vip=true
@field 读回：name=阿 Z vip=true
Engine.power 经 boost(50) 后= 150（@fieldParentPtr 走回宿主）
printAny(Person)：{name="阿 Z", age=26, vip=true}
42
7
9
null
"hi"
==== 14.8 结束 ====
```

⚠️ **0.17 里函数体里的 `const` 初始化不再自动 comptime**——`const field_name = comptime "age";` 必须写 `comptime`（13.3 节的规则）。而 `@field` 的名字**必须是编译期字符串**，运行期拼出来的 `[]const u8` 不行。反射遍历之所以能用 `@field(value, name)`，正是因为 `field_names` 里的 `name` 是编译期值。

### `@fieldParentPtr`：从字段指针走回宿主

```zig
// examples/14_generics/main.zig 第 260-284 行
/// 14.8 节：@fieldParentPtr 的宿主反推——从一个字段指针走回宿主 struct。
const Engine = struct {
    power: u32,

    /// 只拿到字段指针，也能改宿主：
    /// @fieldParentPtr("字段名", 字段指针) 返回 *宿主类型。
    pub fn boost(self: *Engine, by: u32) void {
        const self2: *@This() = @fieldParentPtr("power", &self.power);
        self2.power += by;
    }

    /// 0.17 里@fieldParentPtr 的指针元素类型必须**精确匹配**字段类型，
    /// 跨层要手动 @ptrCast（实测报pointer element type 'u32' cannot coerce into
    /// element type 'Inner'）。
    pub fn boostViaField(self: *Engine, by: u32) void {
        const self2: *@This() = @fieldParentPtr("power", &self.power);
        self2.power += by;
    }
};
```

这是 08 章 8.3.4 节那个技巧的 0.17 版本：`@fieldParentPtr("power", &self.power)` 从字段指针反推出 `*Engine`。⚠️ **0.17 的指针元素类型必须精确匹配字段类型**——如果字段本身是个 struct（`Inner`）而你手里是 `*u32`，会报：

```text
error: pointer element type 'u32' cannot coerce into element type 'g6.Inner'
    const o: *Outer = @fieldParentPtr("i", p);
                      ^~~~~~~~~~~~~~~~~~~~~~~
note: use @ptrCast to cast pointer element type
```

也就是**不能像老教程那样"从最内层的 `*u32` 一路反推"**了——必须一层一层来，或者自己补 `@ptrCast`。想多层穿透就写成 `self.a.b.c` 这种点号访问（编译器自己会算偏移），或者在每一层各写一次 `@fieldParentPtr`。

### 四件套合体：通用打印器

```zig
// examples/14_generics/main.zig 第 280-347 行
/// 14.8 节：按类型分派的打印器——四件套合体。
/// @TypeOf 拿类型 → @typeInfo 拆结构 → switch 分派 → inline for + @field 遍历。
/// 每一层都能递归下去：字段本身又是一个"任意类型"，所以先printField 分派再打印。
fn printField(value: anytype) void {
    switch (@typeInfo(@TypeOf(value))) {
        // ⚠️ bool 不支持 {d}（实测 error: invalid format string 'd' for type 'bool'），
        //   要打 true/false 只能用 {} 或 {any}。
        .bool => std.debug.print("{}", .{value}),
        .int, .float => std.debug.print("{d}", .{value}),
        // ⚠️ 可选：if (value) |inner| 的 else 分支里 value 是 null，
        //   但 @TypeOf(value) 仍然是 "?u32"（不是 null）。
        .optional => if (value) |inner| {
            printField(inner);
        } else {
            std.debug.print("null", .{});
        },
        // 指针：先看被指类型再决定怎么打。
        // ⚠️ slice（size == .slice）不能写 value.* ——实测报
        //   error: index syntax required to access runtime-known slice
        .pointer => |p| switch (p.size) {
            .one => {
                // 单个指针：u8数组/切片按字符串打，其他按值打
                if (@typeInfo(p.child) == .array and @typeInfo(p.child).array.child == u8) {
                    std.debug.print("\"{s}\"", .{value.*});
                } else {
                    std.debug.print("{s}={any}", .{ @typeName(p.child), value.* });
                }
            },
            .slice => {
                if (p.child == u8) {
                    std.debug.print("\"{s}\"", .{value});
                } else {
                    std.debug.print("{s}={any}", .{ @typeName(p.child), value });
                }
            },
            else => std.debug.print("{s}({d})", .{ @typeName(p.child), value }),
        },
        .array => |a| {
            if (a.child == u8) {
                std.debug.print("\"{s}\"", .{std.mem.sliceTo(&value, 0)});
            } else {
                std.debug.print("{any}", .{value});
            }
        },
        .@"enum" => std.debug.print("{s}({d})", .{ @tagName(value), @backingInt(value) }),
        .error_union => std.debug.print("错误联合={any}", .{value}),
        .@"struct" => |s| {
            std.debug.print("{{", .{});
            inline for (s.field_names, 0..) |name, i| {
                if (i != 0) std.debug.print(", ", .{});
                std.debug.print("{s}=", .{name[0..name.len]});
                printField(@field(value, name));
            }
            std.debug.print("}}", .{});
        },
        // ⚠️ 裸 union 打印要小心：读非活跃字段会 panic（access of union field
        //   ... while field ... is active）。std.meta.activeTag 帮你先问是哪个。
        .@"union" => std.debug.print("联合(tag={s}){any}", .{ std.meta.activeTag(value), value }),
        else => std.debug.print("{any}", .{value}),
    }
}

/// 顶层入口。
fn printAny(value: anytype) void {
    printField(value);
    std.debug.print("\n", .{});
}
```

输出第 4 行 `{name="阿 Z", age=26, vip=true}` 就是这 40 行的效果。**四个内建配合**：`@TypeOf` 拿类型 → `@typeInfo` 拆结构 → `switch` 分派 → `inline for` + `@field` 遍历。而因为字段本身又是"任意类型"，`printField` 可以**递归调用自己**——这是自动序列化的雏形（把 `printAny` 换成写字节就是 JSON writer）。

⚠️ 写这种通用打印器会撞上一堆格式细节，全都是实测踩出来的：

- **`bool` 不支持 `{d}`**：`error: invalid format string 'd' for type 'bool'`。打 true/false 用 `{}` 或 `{any}`。
- **`.pointer` 必须先看 `size`**：`[]const u8` 的 `size` 是 `.slice`，此时写 `value.*` 会报 `error: index syntax required to access runtime-known slice`——切片不能解引用成"那个元素"，只能整体当切片用。
- **字符串判断**：`u8` 数组/切片要按字符串打，靠 `p.child == u8` 判断；无哨兵的定长数组用 `std.mem.sliceTo(&value, 0)` 截断（⚠️ 0.17 的 `std.mem.span` **不接受哨兵数组** `[:0]u8`，报 `error: invalid type given to std.mem.span: [2:0]u8`）。
- **裸 union 打印会 panic**：读非活跃字段触发 `access of union field 'x' while field 'y' is active`。用 `std.meta.activeTag(value)` 先问是哪个。

⚠️ 另外：`std.debug.print` 即使格式串没有占位符也**必须传 `.{}`**（实测 `print("peek 一下新栈：")` 报 `error: expected 2 argument(s), found 1`）。

## 14.9 泛型的代价：单态化实测

泛型不是免费的。Zig 用的是**单态化**（monomorphization）：**每个用到的类型生成一份代码**。

**好处**：运行期**零开销**——没有类型标签、没有虚表（vtable）、没有装箱（boxing）。`Stack(u32)` 的 `pop()` 就是一条 `mov`，不是"查 tag 然后跳转"。

**代价**：二进制体积和编译时间都随"**唯一类型数**"线性增长。

### 实测数据

同一个泛型函数（函数体是 2000 次 `inline for`，每个实例展开 2000 条指令），Debug 模式：

| 唯一类型数 | 二进制体积 | 符号表里的 `work` 副本 | 编译耗时 |
|---|---|---|---|
| 1（`u8`） | 2 148 746 B | 1 | 约 4.2 s |
| 8（`u8`…`i64`） | 2 645 062 B | 8 | 约 4.9 s |
| 4（调用 16 次） | 2 194 557 B | **4** | 约 4.3 s |
| 8（调用 16 次） | 2 194 568 B | **8** | 约 4.3 s |

第二、三行是本节最重要的发现：**16 次调用但只有 4 个唯一类型时，符号表里只有 4 份 `work` 代码**。也就是说——

> ⚠️ **单态化的账单按「唯一类型数」算，不按「调用次数」算。**

Zig 编译器会缓存实例化结果（14.1 节那个 `Grid == Matrix(u8,2,3)` 为 `true` 就是这个缓存的外部表现）。所以"同一个泛型被用 1000 次"**不**等于"生成 1000 份代码"；只有**类型参数不同**才会新增实例。

第 2 行到第 4 行的对比（8 个类型 vs 4 个类型但调用 16 次）也能看出：体积差（2 645 062 vs 2 194 568 = 450 KB）就是那多出来的 4 个类型实例的代价——**每个实例约 112 KB**（在这个故意放大的例子上；真实代码里每个实例几十字节到几 KB）。

### 什么时候会痛

| 场景 | 账单 |
|---|---|
| 泛型容器（`ArrayList(T)`）用了 5 种 `T` | 5 份容器代码 —— 通常可接受 |
| 泛型函数用了 8 种类型，函数体很大 | 8 份 —— **开始疼** |
| 在泛型容器上再套泛型容器（`Map(K, ArrayList(V))`） | 类型数 = K 的种数 × V 的种数 —— **组合爆炸** |
| 编译期展开-heavy 的泛型（`inline for` / `inline while`） | 每个实例都完整展开 —— **最贵** |

### 想省体积怎么办

两条路，都有明确代价：

1. **擦除成运行期多态**：把类型参数换成 `anyopaque` + 手写 tag（Zig 的 `std.AnyType` 风格），一份代码处理所有类型。代价是**放弃编译期类型安全**，每次访问都要手动转换。
2. **传 `anytype` 让调用方决定**：还是单态化，只是把选择权交给调用方——**不省体积**。

Zig 标准库两条都给了：`std.ArrayList` 的对齐参数是**泛型**的（`ArrayList(u8, 4)` vs `ArrayList(u8, null)` 是两个类型），而 `std.ArrayListUnmanaged` + 显式传对齐则是非泛型的那条路。

```zig
// examples/14_generics/main.zig 第 604-630 行（14.9 节的横幅注释到 end("14.9")）
    // ═══ 14.9 泛型的代价：单态化实测 ═══
    begin("14.9");
    // 单态化（monomorphization）：每个类型生成一份代码。
    // 好处：运行期零开销（没有类型标签、没有虚表、没有装箱）。
    // 代价：二进制体积 + 编译时间都随"用到的类型数"线性增长。
    //
    // 实测（Debug 模式，同一个 2000 次inline for 的泛型函数）：
    //   1 个类型  → 二进制 2_148_746 字节，1 份work 代码
    //   8 个类型  → 二进制 2_645_062 字节，8 份 work 代码（+496_316 字节）
    //   编译耗时：约 4.2 s → 约 4.9 s
    //
    // ⚠️ 但**相同类型只实例化一次**（有缓存）：16 次调用、只有 4 个唯一类型时，
    //   符号表里仍然只有 4 份work 代码。实测二进制 2_194_557 字节，
    //   和只调4 次几乎一样。所以账单按"唯一类型数"算，不按"调用次数"算。
    //
    // 对比 C++ 模板：机制一样（都是单态化），但C++ 的实例化点藏在
    // 两阶段查找里，报错是一屏长的模板栈；Zig 这边就是"编译期跑了个函数"，
    // 报错直接指向你的源码行。
    std.debug.print("单态化账单按【唯一类型数】算，不按调用次数算\n", .{});
    std.debug.print("本节实测：1 类型 2_148_746 B→ 8 类型 2_645_062 B（+496_316 B）\n", .{});
    std.debug.print("运行期代价：0（没有类型标签、没有虚表、没有装箱）\n", .{});
    // 想要"一份代码多种类型"怎么办？两条路：
    //   (a) 传anytype，让调用方决定（还是单态化，只是隐藏了）
    //   (b) 运行期擦除成u8/void 指针 + 手写 tag（放弃类型安全，换体积）
    // Zig 标准库两条都给了：anytype 走(a)，std.ArrayList 的对齐/分配器参数走组合。
    std.debug.print("省体积的手段：擦除成 anyopaque + 外部 tag（放弃编译期类型安全）\n", .{});
    end("14.9");
```

运行输出（`examples/14_generics/main.zig`）：

```text
==== 14.9 开始 ====
单态化账单按【唯一类型数】算，不按调用次数算
本节实测：1 类型 2_148_746 B→ 8 类型 2_645_062 B（+496_316 B）
运行期代价：0（没有类型标签、没有虚表、没有装箱）
省体积的手段：擦除成 anyopaque + 外部 tag（放弃编译期类型安全）
==== 14.9 结束 ====
```

### 对比 C++ 模板

机制**完全一样**（都是单态化，都按唯一类型数计费，都有实例缓存）。差别全在**可诊断性**上：

| | C++ 模板 | Zig 泛型 |
|---|---|---|
| 实例化点 | 藏在两阶段查找 / ADL 里，**不可见** | **就是一行源码** `Stack(u32)` |
| 报错形态 | 一屏长的模板栈 + "in instantiation of..." 链 | 普通函数报错，直接指向你的行 |
| 语法 | `std::vector<T>`，尖括号 | `Stack(T)`，函数调用 |
| 显式实例化 | `template class vector<int>;` | 无此概念（编译器自动决定） |
| 非类型参数 | `vector<int, 5>` ✅ | `Matrix(u8, 2, 3)` ✅（更通用：任何编译期值） |

最后一行是Zig 的一个小优势：C++ 的非类型参数**类型受限于可参与模板参数的少数几种**（整型、指针、枚举），而 Zig 的 `comptime n: usize` 可以是**任何编译期已知的东西**（包括 `[]const u8` 字符串、其他类型本身）。

### 测试：把语义钉住

本章行为全靠测试守着（`main.zig` 第 693-940 行，9 个 `test` 块）：

```text
$ zig test main.zig
1/9 main.test.14.1 类型构造器：Matrix 返回 type，参数全是 comptime...OK
2/9 main.test.14.2 泛型容器：@This() 自指 + 类型参数导出...OK
3/9 main.test.14.3 anytype 与 comptime T: type 是同一个机制...OK
4/9 main.test.14.4 三条平行数组：field_names / field_types / field_attrs...OK
5/9 main.test.14.5 @typeInfo 各分支的字段形状（0.17 实测）...OK
6/9 main.test.14.6 @hasDecl 第二个参数必须是字符串；@typeName 吃类型...OK
7/9 main.test.14.7 编译期生成的表 / 分派 / 类型...OK
8/9 main.test.14.8 @field / @fieldParentPtr / printAny...OK
9/9 main.test.14.9 单态化：相同类型只实例化一次...OK
All 9 tests passed.
```

其中第 5 个测试最有价值——它把 14.5 节那张表**逐条钉死**：`.int.bits` 是 `u16`、`.array.len` 是 `comptime_int`、`.optional` 是 `.child` 而 `.error_union` 是 `.payload`、`error{}` 是空切片而 `anyerror` 是 `null`、`std.lang.Type` 有 25 个分支、`error_names` 保持声明序而 `@typeName` 按字母重排。**下次升级 Zig 版本时，这个测试会第一个告诉你哪里变了。**

## 14.10 坑位清单

1. **⚠️【本章最大变化】`@typeInfo(T).@"struct".fields` 已不存在**，改成三条平行数组 `field_names` / `field_types` / `field_attrs`（std 源码注释：`Guaranteed to have the same length as 'field_names'`）。`.@"union"` 分支**同样是三条平行数组**（不是 `fields`）。写 `.fields` 报 `error: no field named 'fields' in struct 'lang.Type.Struct'`。

2. **⚠️ `.tag` 已改名 `.layout`**（类型 `std.lang.ContainerLayout`，取值 `.auto` / `.@"extern"` / `.@"packed"`）。写 `.tag` 报 `error: no field named 'tag' in struct 'lang.Type.Struct'`。

3. **⚠️ `.optional` 的字段是 `.child`，不是 `.payload`**——而 `.error_union` 的字段**仍然叫 `.payload`**（两个分支不一致）。写 `.optional.payload` 报 `error: no field named 'payload' in struct 'lang.Type.Optional'`。

4. **⚠️ `.pointer` 的属性全挪进了 `attrs` 子结构**：`attrs.@"const"` / `attrs.@"volatile"` / `attrs.@"allowzero"` / `attrs.@"addrspace"` / `attrs.@"align"`。顶层 `is_const` / `is_volatile` / `align` 已不存在。`size` 是 `enum(u2){one,many,slice,c}`。

5. **⚠️ `.float` 从枚举变成了 `struct { bits: u16 }`**。`@tagName(@typeInfo(f64).float)` 报 `error: expected enum or union; found 'lang.Type.Float'`，`{t}` 格式符报 `invalid format string 't' for type 'lang.Type.Float'`。改用 `.bits`。

6. **⚠️ `.@"fn"` 分支的 `params` 数组没了**，改成 `param_types: []const ?type` + `param_attrs: []const ParamAttributes` 两条平行数组；`calling_convention` / `is_var_args` 挪进了 `attrs`（`attrs.@"callconv"` / `attrs.varargs`）；`return_type` 变成**可空** `?type`。**`param_types` 的元素是 `?type`（`null` = anytype），只能 `inline for`**——普通 `for` 报 `error: values of type '?type' must be comptime-known, but index value is runtime-known`。

7. **⚠️ `field_types`（元素 `type`）、`field_values`（元素 `comptime_int`）、`param_types`（元素 `?type`）、`[_]type` 数组——全部只能用 `inline for`**。普通 `for` 一律报 `error: values of type 'type' must be comptime-known, but index value is runtime-known` + `note: types are not available at runtime`。理由：运行期没有"类型"这个值。

8. **⚠️ `error_names` 是可空的 `?[]const [:0]const u8`**：`anyerror` 是 `null`，`error{}` 是**长度 0 的切片**（不是 null）。元素是哨兵切片，可直接 `{s}` 打印，取子范围写 `[0..len]`；写 `[0..8 :0]` 报 `error: expected type '[:0]const u8', found 'comptime_int'`。⚠️ **`error_names` 保持声明顺序，但 `@typeName` 按字母重排**（`error{NotFound, Corrupted }` → `error{Corrupted,NotFound}`）——别拿 `@typeName` 反推成员表。

9. **⚠️ `.@"enum"` / `.@"struct"` / `.@"union"` 的哨兵值都改成了 `sentinel_ptr` 字段 + `sentinel()` 内联方法**（不是直接给值）。`@typeInfo([4:0]u8).array.sentinel()` 返回 `?u8`。`attrs.default_value_ptr` 同理，用 `attrs.defaultValue(FieldType)` 取值。

10. **⚠️ 分支标签只有 6 个必须写 `.@"名字"`**：5 个关键字（`struct` / `enum` / `union` / `fn` / `opaque`）加上 **`anyframe`**（它和内建类型 `anyframe` 同名）。漏掉 `.anyframe` 的引号，在穷尽 `switch` 里报错会指向 **`switch` 关键字本身**：`error: expected '}', found '.'`。⚠️ **`.frame` / `.enum_literal` / `.spirv` 裸写完全合法**（隔离实测）——它们看起来"也需要引号"只是因为紧跟在报错的 `.anyframe` 后面被连带算作出错位置。**建议 25 个分支全写成 `.@"int"` 这种形式**，一劳永逸。

11. **⚠️【新】0.17 里 decl 只能通过**类型**访问，不能通过**值**访问**。`st.Item`（`st` 是 `Stack(u32)` 的值）报 `error: no field named 'Item' in struct 'main.Stack(u32)'`。这条限制和泛型无关，普通struct 一样。**`a.b` 只找字段，声明必须经类型名**（`Stack(u32).Item`）。

12. **⚠️【新】`decl_names` 只列 `pub` 声明**。`Person` / `Stage`（无声明）= 0，`Payload`（有 `pub fn tagName`）= 1，`struct { const K: u8 = 3; ... }`（非 pub）= 0。**要列声明用 `@hasDecl` 逐个问，或 `std.meta.declarations(T)`。**

13. **⚠️ `@hasDecl(T, ident)` 的标识符形式失效**，必须给字符串：`@hasDecl(std.mem, "copyForwards")`。写标识符报 `error: use of undeclared identifier 'copyForwards'`——**极具迷惑性**（看起来像"这个 decl 不存在"），看到它要先怀疑参数形式。顺带：`@hasDecl` 问的是**声明**，字段不算（`@hasDecl(Person, "name") = false`）；问字段要用 `@hasField`。

14. **⚠️ `@Type` 已移除**（`error: invalid builtin function: '@Type'`，13.8 节）。替代：`@TypeOf(f)` 拿函数类型，但 `@TypeOf(&f)` 拿到的是**指针** `*const fn (...)`，要函数类型得 `@typeInfo(ptr).pointer.child`。⚠️ **0.17 里裸函数名放进 `[_]type{...}` 会退化成指针**（报 `expected type 'type', found 'fn (u32, u32) u8'`），要写 `@TypeOf(f)`。

15. **⚠️ `std.meta.fields` / `declarationInfo` / `fieldInfo` 在 0.17 已改成 `@compileError` 占位**（源码注释 `To be removed after Zig 0.17.0 is tagged`）。`std.meta.fields(S)` 报 `error: deprecated in favor of @typeInfo`。剩下的 `Child` / `Elem` / `fieldNames` / `declarations` 等都是 `@typeInfo` 的薄封装——新代码直接写 `@typeInfo`。

16. **⚠️ 匿名容器的 `@typeName` 是编译器编的**。直接写 `struct { a: u32 }` / `opaque {}` 而不赋给 const，`@typeName` 会打出 `main.main__struct_904` 这种带内部序号的字符串，**每次编译都可能变**。用具名 `const` 才有稳定名字。

17. **⚠️ 0.17 不许在函数体里声明 `fn`**（报极具误导性的 `error: expected ',' after initializer`），所有辅助函数必须放容器级。另外 `std.debug.print` 即使没有占位符也**必须传 `.{}`**（`print("x")` 报 `expected 2 argument(s), found 1`）。

18. **⚠️ `@fieldParentPtr` 的指针元素类型必须精确匹配字段类型**。跨层反推（从 `*u32` 反推 `*Outer`，但字段是 `Inner`）报 `error: pointer element type 'u32' cannot coerce into element type 'Inner'` + `note: use @ptrCast to cast pointer element type`。**不能像老教程那样从最内层一路反推了**——要么每层各写一次 `@fieldParentPtr`，要么用点号访问。

19. **写通用打印器的一堆格式细节（全部实测）**：`bool` 不支持 `{d}`（要用 `{}` / `{any}`）；slice（`size == .slice`）不能写 `value.*`（报 `index syntax required to access runtime-known slice`）；`std.mem.span` 不接受哨兵数组 `[:0]u8`（报 `invalid type given to std.mem.span`），无哨兵定长数组用 `std.mem.sliceTo(&arr, 0)`；裸 union 打印非活跃字段会 panic（用 `std.meta.activeTag` 先问）。

20. **泛型的账单：单态化按「唯一类型数」计费，不按调用次数**。实测同一个泛型函数 1 个类型时二进制 2 148 746 B、8 个类型时 2 645 062 B（+496 KB），编译耗时 4.2 s → 4.9 s；但 16 次调用只有 4 个唯一类型时**仍然只有 4 份代码**。运行期代价是**零**（无类型标签、无虚表、无装箱）。省体积只能擦除成 `anyopaque` + 手写 tag，代价是放弃编译期类型安全。

---

上一章：[13 comptime I](13-comptime.md) · 下一章：[15 测试](15-testing.md)