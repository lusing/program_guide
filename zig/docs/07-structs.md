# 07 · 结构体

> 对应示例：`examples/07_structs/main.zig`（680 行，14 个 `test`），另有 `examples/07_structs/helper2.zig` 演示「文件即struct」
>
> Zig 没有类。结构体是Zig 里唯一的"用户自定义聚合类型"，它同时扮演三个角色：**数据布局**（字段 + 内存布局）、**命名空间**（常量 / 函数 / 嵌套类型挂在类型上）、**值语义载体**（赋值即拷贝）。这一章要把这三层都讲透，因为后面每一章都会用到它们的组合。读完你应该能自己回答：为什么 `const p = Point{.x=1}; p.x = 2;` 编译不过，而 `var q = Point{.x=1}; q.translate(1,1);` 里的 `translate` 能改到 `q`。
>
> 本章所有输出均在本机 **Zig 0.17.0**（Debug 模式）实测抄录。

---

## 7.1 定义与实例化：字段名初始化，漏字段是编译错

结构体的声明就是 `struct { ... }`。字段是 `名字: 类型` 或 `名字: 类型 = 默认值`。实例化必须用**具名字段字面量** `Type{ .字段 = 值 }`：

```zig
// examples/07_structs/main.zig 第 13-31 行
/// 点。注意 y 有默认值 0，所以实例化时可以省掉。
pub const Point = struct {
    x: f64,
    y: f64 = 0,

    // 7.3：方法就是"第一个参数叫 self 的普通函数"，self 只是惯用名
    pub fn dist(self: Point) f64 {
        return @sqrt(self.x * self.x + self.y * self.y);
    }
    /// 想改字段就必须收指针。调用写 p.translate(...) 即可，编译器自动取址
    pub fn translate(self: *Point, dx: f64, dy: f64) void {
        self.x += dx;
        self.y += dy;
    }
    /// 返回新值，不动原实例
    pub fn moved(self: Point, dx: f64, dy: f64) Point {
        return .{ .x = self.x + dx, .y = self.y + dy };
    }
};
```

```zig
// examples/07_structs/main.zig 第 189-202 行（begin("7.1") 到 end("7.1")）
    begin("7.1");
    var p = Point{ .x = 3, .y = 4 }; // 具名字段初始化
    const origin = Point{ .x = 0 }; // y 用默认值 0
    std.debug.print("p=({d:.1},{d:.1}) origin=({d:.1},{d:.1})\n", .{ p.x, p.y, origin.x, origin.y });
    std.debug.print("Point sizeOf={d} @alignOf={d} @offsetOf(y)={d}\n", .{ @sizeOf(Point), @alignOf(Point), @offsetOf(Point, "y") });
    // ⚠️ 漏掉没有默认值的字段直接编译错，不是运行期问题：
    //   const bad = Point{ .y = 1 };
    //   → error: missing struct field: x
    // ⚠️ 写不存在的字段也编译错：
    //   const bad2 = Point{ .x = 1, .z = 2 };   → error: no field named 'z'
    // ⚠️ 具名字段结构体不能用位置初始化：
    //   const bad3 = Point{ 3, 4 };              → error: ... does not support array initialization syntax
    std.debug.print("p.dist()={d:.1}（方法已定义在上面）\n", .{p.dist()});
    end("7.1");
```

运行输出（`examples/07_structs/main.zig`）：

```text
==== 7.1 开始 ====
p=(3.0,4.0) origin=(0.0,0.0)
Point sizeOf=16 @alignOf=8 @offsetOf(y)=8
p.dist()=5.0（方法已定义在上面）
==== 7.1 结束 ====
```

**"漏字段"与"漏字段名"是两回事。** `x: f64` 没有默认值，所以 `Point{ .y = 1 }` 编译期就报 `error: missing struct field: x`（连 `note: struct declared here` 都给你）。**Zig 不存在"部分初始化的结构体"**——这和 C 里`struct S s = {0};` 悄悄把没写的字段清零的行为完全相反。C 的写法让你以为赋值了，实际上是零；Zig 强迫你把每一个决定写出来。`y: f64 = 0` 给了默认值，才能省。

⚠️ **具名字段结构体不能用位置初始化**：`Point{ 3, 4 }` 报 `error: type 'main.Point' does not support array initialization syntax`。位置初始化只对元组（7.9 节）有效。这条堵死了"字段顺序变了但代码还能编译"的一整类隐患——因为**编译器本来就不保证字段的内存顺序**（7.12 节实测：`Auto{ a: u8, b: u32, c: u8 }` 的 `a` 偏移是 4 不是 0）。

`Point sizeOf=16 @alignOf=8` 是因为两个字段都是 `f64`（8 字节、8 字节对齐）。`@offsetOf(y) = 8` 就是因为 `x` 占满了前 8 字节。这里"碰巧"和声明顺序一致——**只是碰巧**，7.12 节会看到反例。

## 7.2 字段没有 `const`/`var` 之分，可变性由绑定决定

```zig
// examples/07_structs/main.zig 第 204-216 行
    // ═══ 7.2 字段没有 const/var 之分，可变性由绑定决定 ═══
    begin("7.2");
    const cp = Point{ .x = 1, .y = 2 };
    std.debug.print("const 绑定的 Point: x={d:.1}（读得到，改不了）\n", .{cp.x});
    // cp.x = 9;  → error: cannot assign to constant
    var mp = Point{ .x = 1, .y = 2 };
    mp.x = 9; // var 绑定 → 字段可写
    std.debug.print("var 绑定的 Point: x={d:.1}\n", .{mp.x});
    // ⚠️ 结构体字段**不能**写 var / const：
    //   const Bad = struct { var x: i32 = 0, y: i32 };
    //   → error: expected ';' after declaration
    //   字段永远是"可写的位"，能不能写取决于你手里这个值是 const 还是 var。
    end("7.2");
```

运行输出（`examples/07_structs/main.zig`）：

```text
==== 7.2 开始 ====
const 绑定的 Point: x=1.0（读得到，改不了）
var 绑定的 Point: x=9.0
==== 7.2 结束 ====
```

⚠️ **结构体的字段声明里不能写 `var` 或 `const`**。实测 `struct { var x: i32 = 0, y: i32 }` 报 `error: expected ';' after declaration`——因为逗号后面编译器在等一个字段名，而不是可变性关键字。这条规则让"字段"和"可变的容器元素"分开：**字段永远是"可写的位"（mutable slot），能不能写取决于你手里这个值是 `const` 还是 `var`**。所以 C++ 里"成员变量声明成 const 表示只读成员"那套设计在 Zig 里不需要——字段的只读性由**访问路径**决定，不由声明决定。

这个设计的直接好处：把一个 `const Point` 传给一个 `fn f(p: *Point)` 会立刻报错（见 7.3 节的 const 限定符错误），而不是让你在运行期发现"我以为改了，其实改的是拷贝"。

## 7.3 方法：第一个参数是 `self`，但它不是关键字

```zig
// examples/07_structs/main.zig 第 19-30 行（Point里的三个方法）
    pub fn dist(self: Point) f64 {
        return @sqrt(self.x * self.x + self.y * self.y);
    }
    /// 想改字段就必须收指针。调用写 p.translate(...) 即可，编译器自动取址
    pub fn translate(self: *Point, dx: f64, dy: f64) void {
        self.x += dx;
        self.y += dy;
    }
    /// 返回新值，不动原实例
    pub fn moved(self: Point, dx: f64, dy: f64) Point {
        return .{ .x = self.x + dx, .y = self.y + dy };
    }
```

```zig
// examples/07_structs/main.zig 第 218-235 行
    // ═══ 7.3 方法：self 是普通参数，不是关键字 ═══
    begin("7.3");
    var q = Point{ .x = 3, .y = 4 };
    std.debug.print("q.dist()={d:.1}\n", .{q.dist()});
    q.translate(1, 1);
    std.debug.print("translate(1,1) 后 q=({d:.1},{d:.1})\n", .{ q.x, q.y });
    const q2 = q.moved(10, 10); // 值 self 方法：返回新实例，原实例不动
    std.debug.print("moved(10,10): q2=({d:.1},{d:.1}) q 不变=({d:.1},{d:.1})\n", .{ q2.x, q2.y, q.x, q.y });
    // 方法名可以随便起，self 也可以写成别的名字：
    //   fn norm(myself: Point) f64 { ... }   然后 p.norm() 照样能用
    //   —— 点号调用不检查第一个参数叫什么，只检查它是不是该类型。
    // ⚠️ 值 self 想改字段编译不过：self 是 const 绑定
    //   fn set(self: Point) void { self.x = 1; }
    //   → error: cannot assign to constant
    // ⚠️ const 实例不能调 *self 方法：
    //   const c = Point{ .x = 1, .y = 2 }; c.translate(1, 1);
    //   → error: expected type '*Point', found '*const Point' + note: cast discards const qualifier
    end("7.3");
```

运行输出（`examples/07_structs/main.zig`）：

```text
==== 7.3 开始 ====
q.dist()=5.0
translate(1,1) 后 q=(4.0,5.0)
moved(10,10): q2=(14.0,15.0) q 不变=(4.0,5.0)
==== 7.3 结束 ====
```

**Zig 没有方法语法。** `q.translate(1, 1)` 是 `Point.translate(&q, 1, 1)` 的语法糖——编译器看到第一个参数是指针就自动取址。`self` 这个名字纯属惯例：把它改成 `myself`、`this` 甚至 `s`（原书《Learning Zig》就建议别用 `self`，理由是它让人误以为 Zig 有 class），`p.dist()` 照样能编译。

**两种 `self` 的语义差别是本章最容易踩的坑。**

| 写法 | 语义 | 改字段 |
|---|---|---|
| `fn f(self: Point)` | 值传递，收一份拷贝，且`self` 是 `const` | **编译错** |
| `fn f(self: *Point)` | 指针传递 | 能改到原实例 |

`dist` 收值 `self` 是对的——它只读字段。`translate` 收指针。`moved` 收值并返回新实例：输出第 4 行 `q2=(14.0,15.0) q 不变=(4.0,5.0)` 是这一节的证据——`moved` 没有副作用，这是函数式风格（`.translate(1,1)` 在 C++ 里会返回 `*this`）。

⚠️ **值 `self` 里改字段是编译错，不是白改**：报 `error: cannot assign to constant`。这比 C++ 的"改拷贝然后静默丢弃"好得多——问题在编译期就暴露。

⚠️ **`const` 实例不能调指针 `self` 方法**：`const c = Point{...}; c.translate(1, 1);` 报 `error: expected type '*Point', found '*const Point'` + `note: cast discards const qualifier`。这正是 7.2 节那条设计的价值：你不可能"意外改到别人的数据"。

## 7.4 按值传递 vs 按指针传递：结构体是值语义

```zig
// examples/07_structs/main.zig 第 237-247 行
    // ═══ 7.4 按值传递 vs 按指针传递 ═══
    begin("7.4");
    var src = Point{ .x = 1, .y = 1 };
    var copy = src; // var 赋值 = 完整拷贝
    copy.x = 100;
    std.debug.print("copy.x={d:.1} 但 src.x 仍是 {d:.1}（结构体是值语义）\n", .{ copy.x, src.x });
    std.debug.print("byValue 返回 {d:.1}，原实例 {d:.1}\n", .{ movedOf(src).x, src.x });
    translatePtr(&src, 5, 5);
    std.debug.print("translatePtr(&src,5,5) 后 src=({d:.1},{d:.1})（指针改的是原实例）\n", .{ src.x, src.y });
    std.debug.print("Point 占 {d} 字节；传 *Point 只传 {d} 字节地址\n", .{ @sizeOf(Point), @sizeOf(*Point) });
    end("7.4");
```

配合的两个自由函数：

```zig
// examples/07_structs/main.zig 第 467-476 行
fn movedOf(p: Point) Point {
    var local = p;
    local.x = 999;
    return local;
}

fn translatePtr(p: *Point, dx: f64, dy: f64) void {
    p.x += dx;
    p.y += dy;
}
```

运行输出（`examples/07_structs/main.zig`）：

```text
==== 7.4 开始 ====
copy.x=100.0 但 src.x 仍是 1.0（结构体是值语义）
byValue 返回 999.0，原实例 1.0
translatePtr(&src,5,5) 后 src=(6.0,6.0)（指针改的是原实例）
Point 占 16 字节；传 *Point 只传 8 字节地址
==== 7.4 结束 ====
```

**`movedOf` 里第一行必须是 `var local = p;`**，不能写 `var` 收参——因为值参数本身是 `const` 绑定，写 `p.x = 999` 直接 `error: cannot assign to constant`（7.3 节那条规则）。要改就得先拷一份。

**这不是性能细节，是所有权模型。** C 里传结构体等于传指针（可以偷偷改），Go/Java 里传结构体等于传引用（调用方不知道会不会被改），Zig 明确选了C 的方向（值传递 = 拷贝），但**把选择权交给签名**：收 `Point` 就是拷贝，收 `*Point` 就是共享。输出最后一行给了量化：`Point` 是 16 字节（两个 `f64`），传指针只传 8 字节地址。

**大结构体的实践规则**：超过几个机器字（比如包含切片 / 数组 / 字符串的）就该收指针；纯 POD 的小结构体（两三个标量）收值更清晰，因为你想表达的就是"这是独立的一份"。

## 7.5 结构体当命名空间：`Point.create` 那套写法

结构体里可以放 `const`、函数、甚至嵌套类型。它们属于**类型**，不在实例里。

```zig
// examples/07_structs/main.zig 第 33-71 行
// ═══ 7.5：结构体当命名空间 ═══
/// 这个 struct 一个字段都没有，纯命名空间。
pub const Config = struct {
    pub const version = "1.0";
    pub const max_entities = 1024;

    pub fn describe() []const u8 {
        return "Config v" ++ version;
    }
    /// 关联常量参与运算：当成类型的一部分来算
    pub fn entityLimit() u32 {
        return max_entities;
    }
};

// ═══ 7.5：Point.create 风格的具名构造器 ═══
pub const Vec2 = struct {
    x: f32,
    y: f32,

    /// 具名构造器。惯例上放在结构体命名空间里，而不是全局 free 函数
    pub fn create(sx: f32, sy: f32) Vec2 {
        return .{ .x = sx, .y = sy };
    }
    pub fn origin() Vec2 {
        return create(0, 0);
    }
    /// 嵌套类型：struct 里还能再放 struct，形成命名空间层级
    pub const Info = struct {
        count: usize = 0,
        pub fn of(n: usize) Info {
            return .{ .count = n };
        }
    };
    /// 注意这个 stats 没有 self：它属于**类型** Vec2，不属于某个实例。
    pub fn stats() Info {
        return Info.of(2);
    }
};
```

```zig
// examples/07_structs/main.zig 第 249-262 行
    // ═══ 7.5 结构体当命名空间 ═══
    begin("7.5");
    std.debug.print("Config.describe() = {s}\n", .{Config.describe()});
    std.debug.print("Config.version = {s}，max_entities = {d}\n", .{ Config.version, Config.max_entities });
    std.debug.print("Config.entityLimit() = {d}\n", .{Config.entityLimit()});
    std.debug.print("Config sizeOf={d}（没有字段的 struct 是 0 字节，纯命名空间）\n", .{@sizeOf(Config)});
    const v = Vec2.create(1.5, 2.5);
    const z = Vec2.origin();
    std.debug.print("Vec2.create(1.5,2.5)=({d},{d})  Vec2.origin()=({d},{d})\n", .{ v.x, v.y, z.x, z.y });
    std.debug.print("Vec2.Info.of(3).count = {d}；Vec2.stats().count = {d}\n", .{ Vec2.Info.of(3).count, Vec2.stats().count });
    std.debug.print("类型全名：{s} / {s}\n", .{ @typeName(Vec2), @typeName(Vec2.Info) });
    // 没有 static 关键字：写在 struct 里的 decl 属于**类型**，不在实例里。
    // 实例里只有字段。所以 Point{ .x = 1 }.dist 是方法，但不存在"实例上的 dist 字段"。
    end("7.5");
```

运行输出（`examples/07_structs/main.zig`）：

```text
==== 7.5 开始 ====
Config.describe() = Config v1.0
Config.version = 1.0，max_entities = 1024
Config.entityLimit() = 1024
Config sizeOf=0（没有字段的 struct 是 0 字节，纯命名空间）
Vec2.create(1.5,2.5)=(1.5,2.5)  Vec2.origin()=(0,0)
Vec2.Info.of(3).count = 3；Vec2.stats().count = 2
类型全名：main.Vec2 / main.Vec2.Info
==== 7.5 结束 ====
```

**`Config sizeOf=0`** 是这一节最有信息量的一个数字。一个没有任何字段的 struct 的 `@sizeOf` 是 **0**——它不是"最小的结构体"（1 字节），而是**真的零字节**：编译后不占任何内存，可以有无穷多个实例。`std.ArrayList`、`std.StringHashMap` 这些泛型容器里全是这样的"纯命名空间 struct"，它们只承载API，不承载数据。

**`Vec2.create` 这个惯例值得单独说。** "为某个类型造一个实例"这件事，在没有构造函数的语言里需要有个函数。放哪里？全局 `makeVec2(...)` 会污染顶层命名空间；放类型里写成 `Vec2.create(...)` 就是**以字段为命名空间的函数**——`Point.create`、`Vec2.origin`、`Config.describe` 读起来都像"从某个类型里取出什么"，而且顶层一个名字都不占。你在标准库里见过的 `std.mem.Allocator.Error`（错误嵌套在类型里）、`std.time.ns_per_us` 都是同一套机制。

⚠️ **没有 `static` 关键字。** C++ 需要 `static` 来区分"属于类的"和"属于实例的"，Zig 里位置本身就说明了：**写在 struct 里的 decl 属于类型，不在实例里**。实例里只有字段。所以不存在"实例上的 dist 字段"这种东西——`p.dist` 里的 `dist` 是类型成员，`p.x` 里的 `x` 是实例字段，两条路径不重叠（7.15 节会验证这个）。

⚠️ **嵌套类型里写同名的外层名字会报"歧义引用"。** 实测：`Vec2.Info.of` 的返回类型写成 `Stats`，而文件里另有一个顶层 `Stats` → `error: ambiguous reference` + 两条`note` 分别指出两个声明处。Zig 的名字解析在嵌套作用域里向外查找，**同名就是错**，不像有些语言"内层优先"地遮蔽。解法就是改名（示例里把嵌套的叫 `Info`，顶层的叫 `Stats`）。

## 7.6 嵌套结构体：字段可以是另一个结构体

```zig
// examples/07_structs/main.zig 第 73-82 行
// ═══ 7.6：嵌套结构体 ═══
pub const Inner = struct {
    v: i32,
    label: []const u8 = "inner",
};

pub const Outer = struct {
    inner: Inner,
    tag: u8,
};
```

```zig
// examples/07_structs/main.zig 第 264-272 行
    // ═══ 7.6 嵌套结构体 ═══
    begin("7.6");
    var o = Outer{ .inner = .{ .v = 1, .label = "deep" }, .tag = 9 };
    std.debug.print("o.inner.v={d} o.inner.label={s} o.tag={d}\n", .{ o.inner.v, o.inner.label, o.tag });
    o.inner.v = 42; // 逐层走
    std.debug.print("改完 o.inner.v={d}；Outer sizeOf={d}（内层 {d} + tag 1 字节 + 补齐对齐）\n", .{ o.inner.v, @sizeOf(Outer), @sizeOf(Inner) });
    const inner_only = Outer{ .inner = .{ .v = 5 }, .tag = 1 }; // 内层的 label 用默认值
    std.debug.print("inner.label 默认值 = {s}\n", .{inner_only.inner.label});
    end("7.6");
```

运行输出（`examples/07_structs/main.zig`）：

```text
==== 7.6 开始 ====
o.inner.v=1 o.inner.label=deep o.tag=9
改完 o.inner.v=42；Outer sizeOf=32（内层 24 + tag 1 字节 + 补齐对齐）
inner.label 默认值 = inner
==== 7.6 结束 ====
```

**`Outer sizeOf=32` 而 `Inner sizeOf=24`** ——差值8字节，值得逐字节算一遍：`Inner` 里 `v: i32`（4 字节，放在偏移 0..4）+ `label: []const u8`（16 字节的"指针+长度"，要求 8 字节对齐，所以偏移要补到 8）→ `Inner` 占 8..24，`sizeOf = 24`。`Outer` 里 `inner` 占 24 字节，`tag: u8` 放在偏移 24，共25 字节，但 `Outer` 的对齐要求是 8（跟着 `inner` 里的切片），**补到 32**。这就是"嵌套结构体的对齐会传染"。

`o.inner.v = 42` 逐层走：先取 `o.inner`（得到一个可写的 `Inner`），再取它的 `v`。这是**按值嵌套**，不是引用嵌套——每次访问不涉及指针解引用（编译器会优化掉）。

**默认值的继承**：`Outer{ .inner = .{ .v = 5 }, .tag = 1 }` 里内层没写 `label`，于是用了 `Inner` 自己的默认值 `"inner"`（输出最后一行）。**每一层struct 各自管自己的默认值**，外层管不到内层。

## 7.7 `init` / `deinit` 惯例，以及 `init` 不会被自动调用

```zig
// examples/07_structs/main.zig 第 84-105 行
// ═══ 7.7：init / deinit 惯例 ═══
pub const Session = struct {
    id: u32,
    slots: u32 = 4,

    /// init 不会被自动调用（Zig 没有构造函数），就是一个返回 Self 的普通函数
    pub fn init(id: u32) Session {
        return .{ .id = id };
    }
    /// 需要分配器时惯用 `fn init(allocator: std.mem.Allocator) !Self`
    pub fn initWithSlots(id: u32, slots: u32) Session {
        return .{ .id = id, .slots = slots };
    }
    /// deinit 同样不会被自动调用，靠调用方 defer
    pub fn deinit(self: *Session) void {
        self.* = undefined;
    }
    pub fn describe(self: Session) []const u8 {
        _ = self;
        return "session";
    }
};
```

```zig
// examples/07_structs/main.zig 第 274-286 行
    // ═══ 7.7 init / deinit 惯例，以及 init 不自动调用 ═══
    begin("7.7");
    const direct = Session{ .id = 1 }; // 直接字面量：init 根本不在调用链上
    std.debug.print("直接字面量 Session{{.id = 1}}: id={d} slots={d}\n", .{ direct.id, direct.slots });
    var s = Session.init(7); // 显式调 init
    defer s.deinit();
    std.debug.print("Session.init(7): id={d} slots={d}\n", .{ s.id, s.slots });
    const s2 = Session.initWithSlots(8, 64);
    std.debug.print("Session.initWithSlots(8,64): id={d} slots={d}\n", .{ s2.id, s2.slots });
    std.debug.print("describe()={s}\n", .{s.describe()});
    // Zig 没有构造函数 / 析构函数，也不会自动调 init。上面 direct 那一行就是证据：
    // 如果 init 是构造函数，direct 的 slots 会被 init 里的值覆盖。
    end("7.7");
```

运行输出（`examples/07_structs/main.zig`）：

```text
==== 7.7 开始 ====
直接字面量 Session{.id = 1}: id=1 slots=4
Session.init(7): id=7 slots=4
Session.initWithSlots(8,64): id=8 slots=64
describe()=session
==== 7.7 结束 ====
```

**`direct` 那一行就是本章最重要的证据。** 它的 `slots = 4`（字段默认值），而不是 `init` 里会设的值——因为 **`Session{ .id = 1 }` 这个字面量是编译期直接构造，`init` 完全不在调用链上**。Zig 里"构造函数"这个概念不存在：`init` 只是**一个恰好命名为 `init` 的普通函数**，靠约定（而不是靠语言强制）成为惯用构造器。

对比 C++：`Point p(3, 4)` 保证调了构造函数。Zig 里 `Point{ .x = 3, .y = 4 }` 保证**什么函数都没调**。区别在哪儿体现？当你的类型需要"不可违反的不变量"时（比如缓冲区必须 `len <= capacity`）——C++ 让你无法绕过构造函数，Zig 让你用别的手段守住：

1. **只暴露 `pub` 的创建路径**：字段不给 `pub`，或者整个 struct 声明在一个私有文件里，只导出 `init`（20 章的文件布局会用这个手法）。
2. **不变量破坏时报错**：`init` 里 `std.debug.assert(len <= cap)`，或者返回一个错误（`!Self`）。需要分配器时惯用 `fn init(allocator: std.mem.Allocator) !Self`（11 章实战）。

**`deinit` 同理**：靠调用方 `defer s.deinit()`（示例第 279 行）。`self.* = undefined` 是惯例上的"抹掉内容"——不是必须的，但对含敏感数据的类型（口令、密钥）是推荐做法。**"谁分配谁释放"这条规则由人守，不是由编译器守**，这也是为什么 `defer` 很重要。

## 7.8 匿名结构体：`.{}` 的真身

你写的每一个 `.{ ... }` 字面量都是**匿名 struct**——一个当场生成、没有名字的类型。

```zig
// examples/07_structs/main.zig 第 107-124 行
// ═══ 7.8：接收匿名结构体的函数 ═══
/// 参数写成 anytype，调用处传 `.{ ... }` 字面量，编译器现场造类型
pub fn checkSettings(settings: anytype) u32 {
    // settings 的类型是调用方那个字面量的类型，所以字段可能是 comptime_int，
    // 得在这里点名成 u32 再算（算术结果永不宽化，03 章 3.5 节）。
    const retries: u32 = settings.retries;
    return @as(u32, @intFromBool(settings.enabled)) + retries;
}

/// 参数写成显式匿名结构体类型：类型名可写出来，但每个字面量都是各自的新类型
fn sumXY(a: struct { x: i32, y: i32 }) i32 {
    return a.x + a.y;
}

/// 返回元组而不是结构体
fn divmod(a: i32, b: i32) struct { i32, i32 } {
    return .{ @divTrunc(a, b), @rem(a, b) };
}
```

```zig
// examples/07_structs/main.zig 第 288-305 行
    // ═══ 7.8 匿名结构体：.{} 的真身 ═══
    begin("7.8");
    // 字面量被目标类型强制转换（coerce）。anytype = "什么类型都行"
    std.debug.print("checkSettings({{ .enabled = true, .retries = 3 }}) = {d}\n", .{checkSettings(.{ .enabled = true, .retries = 3 })});
    const anon = .{ .name = "Zig", .born = 2016 };
    std.debug.print("匿名 struct 当轻量记录用: name={s} born={d}\n", .{ anon.name, anon.born });
    std.debug.print("匿名 struct 的类型名 = {s}（编译器生成的内部名）\n", .{@typeName(@TypeOf(anon))});
    // 函数返回结构体 vs 返回元组
    std.debug.print("sumXY({{ .x = 10, .y = 20 }}) = {d}\n", .{sumXY(.{ .x = 10, .y = 20 })});
    const dm = divmod(17, 5);
    std.debug.print("divmod(17,5) = {{ {d}, {d} }}（元组：商与余数没有名字）\n", .{ dm[0], dm[1] });
    const opt_anon = makeAnonOrNull();
    if (opt_anon) |a| {
        std.debug.print("返回 ?匿名 struct: x={d} y={d}\n", .{ a.x, a.y });
    } else {
        std.debug.print("返回 null\n", .{});
    }
    end("7.8");
```

运行输出（`examples/07_structs/main.zig`）：

```text
==== 7.8 开始 ====
checkSettings({ .enabled = true, .retries = 3 }) = 4
匿名 struct 当轻量记录用: name=Zig born=2016
匿名 struct 的类型名 = main.main__struct_899（编译器生成的内部名）
sumXY({ .x = 10, .y = 20 }) = 30
divmod(17,5) = { 3, 2 }（元组：商与余数没有名字）
返回 ?匿名 struct: x=7 y=8
==== 7.8 结束 ====
```

**匿名 struct 的类型名是 `main.main__struct_899`** ——编译器生成的内部名，行号都编进去了。这说明一件事：**匿名 struct 不能写进任何签名里**（你没法在另一个文件里引用这个类型），所以它只适合"当场用一次"。

三种写法，三种取舍：

| 写法 | 类型名 | 适合 |
|---|---|---|
| `fn f(x: anytype)` | 调用方各自的匿名类型 | 泛型/变长参数（`std.debug.print` 就这样） |
| `fn f(x: struct { x: i32, y: i32 })` | 匿名但可写 | 签名要自描述，且调用方字面量会被强制转换 |
| `fn f(x: Point)` | 具名 | 跨文件、多次传递、需要存进别的结构体 |

`checkSettings` 用 `anytype`，所以 `settings.retries` 的类型是**调用方字面量的类型**——实测传 `.retries = 3` 时它是 `comptime_int`。于是 `checkSettings` 里必须写 `const retries: u32 = settings.retries;` 点名定型，否则 `u1 + comptime_int` 的结果定成 `u1`装不下 3（03 章 3.5 节那条"算术结果永不宽化"在这里真实咬人了一次）。

**返回结构体 vs 返回元组 vs 返回匿名结构体**：`makeAnonOrNull()` 返回 `?struct { x: i32, y: i32 }`（第 478 行）——**返回类型可以写成匿名形式**，调用方拿到后直接用`.?` 解包访问字段，不需要知道类型名。这个写法在"我不想为此起个名字"的场景很好用；如果这个类型要被传三手，就该给它起名字（`Pair`、`Point`）。

## 7.9 元组：字段名就是 `"0"`、`"1"`

元组 = 字段没有名字的 struct。Zig 里它们是同一个东西。

```zig
// examples/07_structs/main.zig 第 121-124 行（divmod 返回元组）
/// 返回元组而不是结构体
fn divmod(a: i32, b: i32) struct { i32, i32 } {
    return .{ @divTrunc(a, b), @rem(a, b) };
}
```

```zig
// examples/07_structs/main.zig 第 307-321 行
    // ═══ 7.9 元组：字段名就是 "0" "1" ═══
    begin("7.9");
    const tup = .{ "Zig", 2016, true };
    std.debug.print("tup.len = {d}\n", .{tup.len});
    std.debug.print("tup[0]={s} tup[1]={d} tup[2]={}\n", .{ tup[0], tup[1], tup[2] });
    std.debug.print("tup.@\"0\"={s}（字段名写法：数字 0 变成字段名 \"0\"）\n", .{tup.@"0"});
    std.debug.print("元组的类型名 = {s}\n", .{@typeName(@TypeOf(tup))});
    // ⚠️ 运行期索引编译错：tup[i] 里 i 必须编译期已知
    //   var i: usize = 0; _ = tup[i];
    //   → error: unable to resolve comptime value
    //   note: tuple field index must be comptime-known
    var rt = makeTriple(1);
    rt[0] = 99; // 运行期元组可以按常量下标改（写死了0，所以合法）
    std.debug.print("运行期元组 makeTriple(1) 改[0]后 = ({d},{d},{d})\n", .{ rt[0], rt[1], rt[2] });
    end("7.9");
```

运行输出（`examples/07_structs/main.zig`）：

```text
==== 7.9 开始 ====
tup.len = 3
tup[0]=Zig tup[1]=2016 tup[2]=true
tup.@"0"=Zig（字段名写法：数字 0 变成字段名 "0"）
元组的类型名 = struct { comptime *const [3:0]u8 = "Zig", comptime comptime_int = 2016, comptime bool = true }
运行期元组 makeTriple(1) 改[0]后 = (99,2,3)
==== 7.9 结束 ====
```

**元组的类型名把整张表摊开给你看了**：`struct { comptime *const [3:0]u8 = "Zig", comptime comptime_int = 2016, comptime bool = true }`——字段名是 `"0"`/`"1"`/`"2"`，每个字段的值都编译期已知（所以标了 `comptime`）。这就是为什么元组只能用在**编译期就知道形状**的地方。

**两种访问方式完全等价**：`tup[0]` 和 `tup.@"0"`。后者揭示了本质——元组就是"字段名叫 `"0"` 的 struct"，`@""` 是Zig 给非法标识符（纯数字）用的转义语法。知道这一点，你就明白**元组和结构体在运行时是同一种东西**。

**`anytype` 参数收的就是元组**：`std.debug.print(fmt, args)` 的第二个参数类型是 `anytype`，实际收到一个元组。这解释了为什么打印参数里可以塞 14 个不同类型的值（03 章那种`@{d} {s} {any}`）。

⚠️ **元组不能运行期索引**：`tup[i]` 里`i` 必须编译期已知，否则 `error: unable to resolve comptime value` + `note: tuple field index must be comptime-known`。**要运行期索引就用数组或切片**（06 章）。这条限制的根源是"元组字段名就是数字下标"——如果下标运行期才知道，`@field(tup, i)` 就没法在编译期生成。

**怎么在结构体和元组之间取舍**：需要自解释（`divmod` 返回的商和余数，谁在第0 位）就用结构体；纯位置化的短序列（RGB 三元组、坐标对）用元组省字数。超过三个元素建议老实起名字——你已经在 `tup[1]` 上花了两个字符去回忆"这是啥"。

## 7.10 可选字段 `?T`

```zig
// examples/07_structs/main.zig 第 452-457 行
// ═══ 7.10 的可选字段类型 ═══
pub const User = struct {
    name: []const u8,
    email: ?[]const u8 = null,
    login_count: ?u32 = null,
};
```

```zig
// examples/07_structs/main.zig 第 323-337 行
    // ═══ 7.10 可选字段 ?T ═══
    begin("7.10");
    var usr = User{ .name = "ada" };
    std.debug.print("新建 User: email={any}（默认值 null）\n", .{usr.email});
    usr.email = "ada@example.com";
    usr.login_count = 7;
    std.debug.print("填完后: email={s} login_count={d}\n", .{ usr.email.?, usr.login_count.? });
    // ⚠️ 可选字段的默认值必须是 null，否则它就是个"必填字段"：
    //   const Bad = struct { v: ?u32 };  const b = Bad{};
    //   → error: missing struct field: v
    const anon_user = User{ .name = "bob" };
    std.debug.print("orelse 兜底: {s}\n", .{anon_user.email orelse "<未设置>"});
    if (usr.email) |e| std.debug.print("if (可选) |值| 取出: {s}\n", .{e});
    std.debug.print("User sizeOf={d}（name16 + email16 + count8）\n", .{@sizeOf(User)});
    end("7.10");
```

运行输出（`examples/07_structs/main.zig`）：

```text
==== 7.10 开始 ====
新建 User: email=null（默认值 null）
填完后: email=ada@example.com login_count=7
orelse 兜底: <未设置>
if (可选) |值| 取出: ada@example.com
User sizeOf=40（name16 + email16 + count8）
==== 7.10 结束 ====
```

**`?T` 在结构体里的意思是"这个字段可以不填"**，用法和独立变量一样：`== null` 判空、`.?` 强制解包（null 就panic）、`orelse 默认值` 兜底、`if (opt) |值| {...}` 解包分支。

⚠️ **可选字段必须显式写 `= null` 才"可以不填"。** 这条实测确认过：`struct { v: ?u32 }` 里 `Bad{}` 报 `error: missing struct field: v`——**`?T` 只是"能装 null"，不等于"默认是 null"**。这其实很合理：Zig 要求你明确表达"这字段可以不填"的意图，而不是让你猜。

**`User sizeOf=40` 值得算一下**：`name: []const u8` 是 16 字节（指针+长度），`email: ?[]const u8` 是**16 字节**——**可选没有多占一个字节**。Zig 用"空指针"表示null（`*const [3:0]u8` 全 0 就是 null slice），所以`?[]const u8` 和 `[]const u8` 一样宽。这是 Zig 和 Rust 最大的运行时差异之一（Rust 的 `Option<&T>` 会多一个字节的判别式/tag）。

## 7.11 `@field` 与 `@fieldParentPtr`

按名字读写字段，名字**必须编译期已知**。

```zig
// examples/07_structs/main.zig 第 126-141 行
// ═══ 7.11：@fieldParentPtr 需要知道宿主类型 ═══
pub const Creature = struct {
    name: []const u8,
    health: f32,
    mana: u32,
};

/// 只拿到字段指针时，用 @fieldParentPtr 反推回宿主指针
fn healMana(mana_ptr: *u32, amount: u32) void {
    // ⚠️ 0.17 的坑：mana 落在偏移 20 上，只需 4 字节对齐；而 Creature 因为
    //   name 是切片（16 字节指针对）要 8 字节对齐。父指针的对齐要求比子指针更高，
    //   不写 @alignCast 就报：error: @fieldParentPtr increases pointer alignment
    const self: *Creature = @alignCast(@fieldParentPtr("mana", mana_ptr));
    self.mana += amount;
    self.health += @floatFromInt(amount / 10);
}
```

```zig
// examples/07_structs/main.zig 第 339-353 行
    // ═══ 7.11 @field 与 @fieldParentPtr ═══
    begin("7.11");
    var cr = Creature{ .name = "elf", .health = 150, .mana = 10 };
    healMana(&cr.mana, 40);
    std.debug.print("healMana(&cr.mana,40) 后 mana={d} health={d:.0}（@fieldParentPtr 反推宿主）\n", .{ cr.mana, cr.health });
    // @field：按名字读写字段，名字必须编译期已知
    @field(cr, "health") = 175;
    std.debug.print("@field(cr,\"health\")=175 后 health={d:.0}\n", .{cr.health});
    inline for (.{ "name", "mana" }) |fname| {
        std.debug.print("  inline for 展开 @field(cr, \"{s}\") = {any}\n", .{ fname, @field(cr, fname) });
    }
    // ⚠️ 名字运行期才知道就编译错：
    //   @field(cr, someRuntimeString)
    //   → error: unable to resolve comptime value / note: field name must be comptime-known
    end("7.11");
```

运行输出（`examples/07_structs/main.zig`）：

```text
==== 7.11 开始 ====
healMana(&cr.mana,40) 后 mana=50 health=154（@fieldParentPtr 反推宿主）
@field(cr,"health")=175 后 health=175
  inline for 展开 @field(cr, "name") = { 101, 108, 102 }
  inline for 展开 @field(cr, "mana") = 50
==== 7.11 结束 ====
```

**`@field(cr, "health") = 175` 是一次真正的写入**——它不是语法糖，而是编译期按名字定位到偏移再写。**`@fieldParentPtr` 是它的反向操作**：给一个字段指针，顺着"面包屑"走回宿主 struct 的指针。这在"只拿到 `*u32` 但想改同结构体的别的字段"时是唯一办法（示例里 `healMana` 顺手把 `health` 也加了 10%）。

⚠️ **0.17 新坑：`@fieldParentPtr` 会要求提高对齐，必须配`@alignCast`。** 实测报错原文：

```text
error: @fieldParentPtr increases pointer alignment
note: parent pointer type '*main.Creature' has alignment '3'
note: struct field 'mana' limits alignment to '2'
note: use @alignCast to assert pointer alignment
```

**这是安全的**：字段 `mana` 在偏移 20，而 `Creature` 的起始地址必然是 8 对齐的，所以 20+4 的区域一定满足 8 对齐。编译器要你用 `@alignCast` 亲口确认这个推理。写法是 `@alignCast(@fieldParentPtr("mana", mana_ptr))`——实测通过。

⚠️ **字段名必须编译期已知**。`@field(cr, someRuntimeString)` 报 `error: unable to resolve comptime value` + `note: field name must be comptime-known`。和元组下标一样的道理：字段访问要生成机器码，得编译期定死偏移。想"运行期按字符串读写字段"，用 `std.meta.Field` 或自己写 `offsetOf` 分派（13 章comptime）。

## 7.12 布局三兄弟：`auto` / `extern` / `packed`

这是本章最"硬"的一节，也是 25 章（二进制格式）的基础。

```zig
// examples/07_structs/main.zig 第 143-149 行
// ═══ 7.12：布局三兄弟 ═══
/// auto：字段顺序由编译器重排以填满对齐空隙
pub const Auto = struct { a: u8, b: u32, c: u8 };
/// extern：严格按声明顺序排列，字段类型必须是 0 或 2 的幂次位宽
pub const Wire = extern struct { a: u32, b: u16 };
/// packed：位级打包，没有 padding
pub const Reg = packed struct { flag: u1, rest: u15 };
```

```zig
// examples/07_structs/main.zig 第 356-394 行
    begin("7.12");
    std.debug.print("Auto{{a:u8,b:u32,c:u8}} sizeOf={d} align={d}：a@{d} b@{d} c@{d}\n", .{
        @sizeOf(Auto),        @alignOf(Auto),
        @offsetOf(Auto, "a"), @offsetOf(Auto, "b"),
        @offsetOf(Auto, "c"),
    });
    // ↑ 注意 a 的偏移是 4 不是 0：编译器把 u32 挪到最前面去了，
    //   这样 a 和 c 才能挤进同一组 padding 空隙。别依赖字段的内存顺序。
    std.debug.print("Wire extern sizeOf={d} align={d}：a@{d} b@{d}\n", .{
        @sizeOf(Wire), @alignOf(Wire), @offsetOf(Wire, "a"), @offsetOf(Wire, "b"),
    });
    const w = Wire{ .a = 0x11223344, .b = 0x5566 };
    const wbytes = std.mem.asBytes(&w);
    std.debug.print("Wire 数据 6 字节但 sizeOf={d}：{any}（末尾 2 字节是 padding）\n", .{ @sizeOf(Wire), wbytes });
    const magic_le = std.mem.readInt(u32, wbytes[0..4], .little);
    std.debug.print("按字节读回 a（小端）= 0x{x:0>8}\n", .{magic_le});
    std.debug.print("Reg packed{{flag:u1,rest:u15}} sizeOf={d} bitSize={d} align={d}\n", .{ @sizeOf(Reg), @bitSizeOf(Reg), @alignOf(Reg) });
    const reg = Reg{ .flag = 1, .rest = 0x7FFF };
    const reg_word: u16 = @bitCast(reg); // packed struct 允许 @bitCast
    std.debug.print("flag=1 rest=0x7FFF → u16 = 0x{x:0>4}\n", .{reg_word});
    std.debug.print("layout 标签：Auto={t} Wire={t} Reg={t}\n", .{
        @typeInfo(Auto).@"struct".layout,
        @typeInfo(Wire).@"struct".layout,
        @typeInfo(Reg).@"struct".layout,
    });
    // ⚠️ 0.17 的坑：@bitCast **不接受裸结构体**（extern struct 也不行）
    //   const x: u64 = @bitCast(wire);
    //   → error: cannot @bitCast from 'main.Wire'
    //   packed struct 是例外（上一行成功了）。走字节请用 asBytes + readInt。
    // ⚠️ extern struct 不许含 u24 这类非 2 的幂次位宽字段：
    //   const E = extern struct { a: u24 };
    //   → error: extern structs cannot contain fields of type 'u24'
    // ⚠️ packed struct 里不能取字段地址（对齐只有 2 字节，rest 还在第1 位的偏移上）：
    //   const p: *u15 = &reg.rest;
    //   → error: expected type '*u15', found '*align(2:1:2) u15'
    //   note: pointer host size '2' cannot cast into pointer host size '0'
    //   note: pointer bit offset '1' cannot cast into pointer bit offset '0'
    // 要改单个字段请用 @field 按值读写（7.11 节）。
    end("7.12");
```

运行输出（`examples/07_structs/main.zig`）：

```text
==== 7.12 开始 ====
Auto{a:u8,b:u32,c:u8} sizeOf=8 align=4：a@4 b@0 c@5
Wire extern sizeOf=8 align=4：a@0 b@4
Wire 数据 6 字节但 sizeOf=8：{ 68, 51, 34, 17, 102, 85, 0, 0 }（末尾 2 字节是 padding）
按字节读回 a（小端）= 0x11223344
Reg packed{flag:u1,rest:u15} sizeOf=2 bitSize=16 align=2
flag=1 rest=0x7FFF → u16 = 0xffff
layout 标签：Auto=auto Wire=extern Reg=packed
==== 7.12 结束 ====
```

### `auto`（默认）：编译器会重排字段

**`a@4 b@0 c@5` 是本章最反直觉的一行输出。** 声明顺序是 `a, b, c`，但实际偏移是 `a=4, b=0, c=5`。编译器把对齐要求最高的 `u32`（4 字节）挪到最前面，然后让两个 `u8` 挤在它后面的padding 空隙里——这样总大小是 8 而不是 12。**这是性能优化，代价是"字段的内存顺序不等于声明顺序"。**

⚠️ **所以永远不要假设 `auto` struct 的字段在内存里按声明顺序排列。** C 程序员从 `int32 b; int8 a;` 的经验会在这里翻车。要按字节走就必须用 `extern` 或 `packed`。

### `extern`：给外部二进制格式用

**`a@0 b@4`** ——严格按声明顺序，因为外部格式（网络报文、文件头）已经把偏移钉死了。代价有两条：

1. **末尾 padding**：`Wire` 的数据只占 6 字节（4+2），但 `sizeOf = 8`——`{ 68, 51, 34, 17, 102, 85, 0, 0 }` 最后那个 `{ 0, 0 }` 是对齐填出来的空隙，**内容不确定**。这就是"不能把 `asBytes` 的结果直接写进文件"的原因（03 章 3.7 节讲过同一个坑）。正解是显式按字段读：`std.mem.readInt(u32, wbytes[0..4], .little)` 拿回 `0x11223344`（输出第 4 行）。
2. **字段类型受严格限制**：只允许位宽是 0 或 2 的幂次的类型（u8/u16/u32/u64 及指针/浮点）。

### `packed`：位级布局

**`Reg` 正好 2 字节**，因为 `u1 + u15 = 16` 位，一个字节都不浪费。原书《Learning Zig》ch8 的经典例子是 `packed struct { high: u4, low: u4 }` → `@sizeOf == 1`。`packed` 是做**硬件寄存器、位域协议**的唯一工具：你可以有一个"占 1 位的 flag 字段"，这在 `auto` 里做不到（`bool` 至少占 1 字节）。

**`packed struct` 是 `@bitCast` 的唯一例外。** 上面 `const reg_word: u16 = @bitCast(reg);` 成功了，输出 `0xffff`（`flag` 在低位、占 bit 0）。而普通 struct 和 extern struct 都被拒（下面详述）。

### ⚠️ 三个 0.17 的硬限制

**① `@bitCast` 拒绝裸结构体（extern 也不行）：**

```text
error: cannot @bitCast from 'main.Wire'
note: struct declared here
const Wire = extern struct { a: u32, b: u16 };
          ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

注意这**不是**因为宽度不等（`Wire` 和 `u64` 都是 8 字节）——0.17 直接把结构体排除在 `@bitCast` 之外。**唯一例外是 `packed struct`**（它的位布局是完全确定的，没有 padding）。走字节的正道是 `std.mem.asBytes` + `std.mem.readInt`（示例第 5 行就是这么做的）。

**② `extern struct` 不许含非2 的幂次位宽字段：**

```text
error: extern structs cannot contain fields of type 'u24'
note: only integers with 0 or power of two bits are extern compatible
```

所以 `u3`、`u24`、`u7` 这些"省空间的任意位宽"只能用在 `packed struct` 或普通 struct 里。

**③ `packed struct` 里不能取字段地址：**

```text
error: expected type '*u15', found '*align(2:1:2) u15'
note: pointer host size '2' cannot cast into pointer host size '0'
note: pointer bit offset '1' cannot cast into pointer bit offset '0'
```

`Reg{ flag: u1, rest: u15 }` 的 `rest` 起始于**第 1 个位偏移**（`flag` 占了 bit 0），对齐只有 2 字节——**这个地址不是硬件能寻址的地址**。想改单个字段请用 `@field`（7.11 节）按值读写，别取指针。（这个报错比 `@alignCast` 那条更精细：连 bit offset 都报出来了。）

## 7.13 comptime 反射：三条平行数组

在编译期把结构体的元数据全部读出来，然后**按这些元数据生成运行期代码**——这是 13 章comptime 的地基。

```zig
// examples/07_structs/main.zig 第 151-185 行
// ═══ 7.13：反射 ═══
/// 通用打印：把 T 的所有字段名与字段类型列出来，再把值逐个打出来
pub fn dumpFields(comptime T: type, value: T) void {
    const info = @typeInfo(T).@"struct";
    inline for (info.field_names, info.field_types, 0..) |fname, ftype, i| {
        // field_names 的元素是 [:0]const u8（带哨兵），打印要写全长度
        // field_types 的元素是 type，必须 inline for 展开才能 @typeName
        std.debug.print("    [{d}] {s}: {s} = {any}\n", .{ i, fname[0..fname.len], @typeName(ftype), @field(value, fname) });
    }
}

/// 反射驱动的通用求和：只累加整型字段，跳过其它类型
pub fn sumIntFields(comptime T: type, value: T) u64 {
    const info = @typeInfo(T).@"struct";
    var acc: u64 = 0;
    inline for (info.field_names, info.field_types) |fname, ftype| {
        switch (@typeInfo(ftype)) {
            .int => acc += @as(u64, @intCast(@field(value, fname))),
            else => {},
        }
    }
    return acc;
}

/// 字段类型是类型、值是编译期常量，所以 @intCast 能在这里用
pub fn sumFieldSizes(comptime T: type) usize {
    const info = @typeInfo(T).@"struct";
    var total: usize = 0;
    // field_attrs 与前两条平行数组等长，按下标配对
    inline for (info.field_types, info.field_attrs) |ftype, attr| {
        _ = attr;
        total += @sizeOf(ftype);
    }
    return total;
}
```

```zig
// examples/07_structs/main.zig 第 396-413 行
    // ═══ 7.13 comptime 反射：三条平行数组 ═══
    begin("7.13");
    const c = Creature{ .name = "goblin", .health = 30, .mana = 7 };
    const info = @typeInfo(Creature).@"struct";
    std.debug.print("Creature layout={t} is_tuple={} 字段数={d} decl数={d}\n", .{ info.layout, info.is_tuple, info.field_names.len, info.decl_names.len });
    dumpFields(Creature, c);
    std.debug.print("sumFieldSizes(Creature) = {d}（{d}+{d}+{d}）\n", .{ sumFieldSizes(Creature), @sizeOf([]const u8), @sizeOf(f32), @sizeOf(u32) });
    const stats = Stats{ .hp = 10, .mp = 20, .atk = 12, .name = "hero" };
    std.debug.print("sumIntFields(Stats) = {d}（只累加整型字段，跳过 name）\n", .{sumIntFields(Stats, stats)});
    // field_attrs：与 field_names / field_types 平行，按下标配对
    const withDefaults = @typeInfo(Point).@"struct";
    inline for (withDefaults.field_names, withDefaults.field_attrs, 0..) |fname, attr, i| {
        std.debug.print("  Point 字段[{d}] {s} 有默认值={}\n", .{ i, fname[0..fname.len], attr.default_value_ptr != null });
    }
    // 元组也是 struct，is_tuple = true，字段名是 "0"/"1"/"2"
    const tinfo = @typeInfo(@TypeOf(tup)).@"struct";
    std.debug.print("元组 is_tuple={} 字段名[1]={s} 类型[1]={s}\n", .{ tinfo.is_tuple, tinfo.field_names[1][0..1], @typeName(tinfo.field_types[1]) });
    end("7.13");
```

运行输出（`examples/07_structs/main.zig`）：

```text
==== 7.13 开始 ====
Creature layout=auto is_tuple=false 字段数=3 decl数=0
    [0] name: []const u8 = { 103, 111, 98, 108, 105, 110 }
    [1] health: f32 = 30
    [2] mana: u32 = 7
sumFieldSizes(Creature) = 24（16+4+4）
sumIntFields(Stats) = 42（只累加整型字段，跳过 name）
  Point 字段[0] x 有默认值=false
  Point 字段[1] y 有默认值=true
元组 is_tuple=true 字段名[1]=1 类型[1]=comptime_int
==== 7.13 结束 ====
```

### ⚠️ 0.17 的核心变化：`fields` 数组没了

**`@typeInfo(T).@"struct".fields` 在 0.17 不存在**（老教程大量使用它）。取而代之的是**三条长度一致的平行数组**，按下标配对：

| 数组 | 元素类型 | 拿什么 |
|---|---|---|
| `field_names` | `[:0]const u8` | 字段名 |
| `field_types` | `type` | 字段的**类型** |
| `field_attrs` | `std.builtin.Type.FieldAttrs` | 属性：`default_value_ptr`、`alignment` 等 |

```zig
const info = @typeInfo(T).@"struct");
// info.field_names[i] ↔ info.field_types[i] ↔ info.field_attrs[i]
```

配套的还有 `layout`（**注意 0.17 里 `.tag` 已改名为 `.layout`**，取值 `.auto` / `.@"extern"` / `.@"packed"`）、`is_tuple`、`decl_names`（结构体里声明的常量/函数/嵌套类型名）、`backing_integer`（给带整数基类型的 packed struct 用，普通结构体是 `null`）。

**`decl数=0`**：`Creature` 里只有字段，没有 `const` 也没有 `fn`——注意 `healMana` 是**文件级**函数，不在 `Creature` 里。而 7.5 节的 `Vec2` 就有 `create`、`origin`、`Info`、`stats` 四个 decl。

### `field_attrs` 能问出"这个字段有默认值吗"

`attr.default_value_ptr != null` 是判断"该字段是否声明了默认值"的官方方式。输出里 `Point 字段[0] x 有默认值=false` / `字段[1] y 有默认值=true` —— 这和 7.1 节"漏字段是编译错"是同一件事的两面：**没默认值 → 初始化时必须给**。

### ⚠️ 三条限制（全部实测）

**① `field_types` 只能用 `inline for`。** 普通 `for` 报 `error: values of type 'type' must be comptime-known, but index value is runtime-known` + `note: types are not available at runtime`。道理很直白：**类型是编译期实体，运行期根本没有"类型"这个值**。`inline for` 在编译期把循环展开，每次迭代的 `ftype` 都已知。

同理 `@field(value, fname)` 里 `fname` 来自 `field_names`——**这也是为什么必须 `inline for`**：`@field` 的名字参数要求编译期已知（7.11 节）。

**② `field_names` 的元素是哨兵切片，打印要写全长度。** `fname[0..fname.len]` 得到 `*const [N:0]u8`，`{s}` 能直接吃；写 `fname[0..3 :0]` 声称"第3 字节是哨兵"会报 `error: value in memory does not match slice sentinel`（哨兵在第 N 字节，不在第 3 字节）。

**③ `@typeInfo` 的结果要绑到变量再用。** 像 `@typeInfo(T).@"struct".field_names.len` 这样链式访问，`.@"struct"` 标签只在 `@typeInfo` 的结果上存在，重复调用 `@typeInfo` 会被重新求值（能编译但风格差）。

**④ `inline for` 的第三个元素是下标。** `inline for (arr, 0..) |item, i|` 拿计数用；`inline for (a, b, c) |x, y, z|` 同时遍历多条平行数组——这是 7.13 节所有代码的基础写法。

## 7.14 文件即 struct，以及 `usingnamespace` 的下场

每个 `.zig` 文件本身就是一个 struct。文件顶层的 `const`、`fn` 都是它的"字段"。

```zig
// examples/07_structs/helper2.zig 全文
//! 07 结构的第二个文件：演示"每个 .zig 文件本身就是一个 struct"
pub const Answer = 42;

pub fn twice(x: u32) u32 {
    return x * 2;
}

/// 文件 struct 里也能再放 struct
pub const Table = struct {
    keys: usize = 0,
};
```

```zig
// examples/07_structs/main.zig 第 486-486 行
const helper2 = @import("helper2.zig");
```

```zig
// examples/07_structs/main.zig 第 415-430 行
    // ═══ 7.14 文件即 struct；usingnamespace 在 0.17 已被移除 ═══
    begin("7.14");
    std.debug.print("本文件的 main 与 helper2 都是「文件 struct」的字段：helper2.twice(21)={d}\n", .{helper2.twice(21)});
    const empty_table = helper2.Table{};
    std.debug.print("helper2.Answer={d} helper2.Table 的 keys={d}\n", .{ helper2.Answer, empty_table.keys });
    // 注意 @TypeOf(helper2) 的结果是 "type" —— @import 拿回的是**一个类型**，
    // 不是一个模块对象。要看它的成员就写 helper2.xxx，编译器在编译期解析。
    std.debug.print("@TypeOf(helper2)={s}；helper2.twice 的类型 = {s}\n", .{ @typeName(@TypeOf(helper2)), @typeName(@TypeOf(helper2.twice)) });
    // ⚠️ 0.17 已移除 usingnamespace。老教程里的
    //     const A = struct { pub const v = 7; };
    //     usingnamespace A;      // 把 A 的 decl 摊到当前作用域
    //   在 0.17 编译失败：error: expected ',' after field
    //   （它被当成结构体字段解析了）。替代品是显式导入：
    //     const a = @import("a.zig");  然后写 a.v
    // 这样"名字从哪来"永远写在源码里，不会被一个远处的 usingnamespace 改掉。
    end("7.14");
```

运行输出（`examples/07_structs/main.zig`）：

```text
==== 7.14 开始 ====
本文件的 main 与 helper2 都是「文件 struct」的字段：helper2.twice(21)=42
helper2.Answer=42 helper2.Table 的 keys=0
@TypeOf(helper2)=type；helper2.twice 的类型 = fn (u32) u32
==== 7.14 结束 ====
```

**这就是模块系统的全部。** 没有 include、没有头文件、没有符号冲突、没有链接顺序问题：`@import("helper2.zig")` 拿到的是那个文件的 struct，`helper2.twice(...)` 是访问它的 `pub` 成员（`pub` 相当于"导出"）。不写 `pub` 的话成员是私有的，别的文件访问不到——和 C 里"头文件里声明了什么"是一个意思，只不过**声明和定义天生在同一个文件里**。

`@TypeOf(helper2) = type` 这个输出有点反直觉但很重要：`@import` 返回的是**一个类型**（编译期实体），不是一个运行期的"模块对象"。所以 `@TypeOf` 结果是 `type`，而没有"运行期的模块实例"这种东西。要用成员就在源码里写 `helper2.twice`——编译器在编译期解析成直接的符号引用，没有查表。

### ⚠️ `usingnamespace` 在 0.17 已被移除

实测确认：

```zig
const A = struct { const v: u32 = 7; };
usingnamespace A;      // ← 0.17 编译失败
```

```text
p2.zig:3:16: error: expected ',' after field
usingnamespace A;
               ^
```

`usingnamespace` 是老教程里"把某个 struct 的 decl 摊到当前作用域"的写法，现在被完全删除（现在连语法都不被识别，编译器把它当成结构体字段解析）。**替代品就是显式导入**：

```zig
const a = @import("a.zig");
// 然后写 a.v
```

这实际上是**更好的设计**：`usingnamespace` 让名字从哪来变得不透明——你在第 100 行看到 `v`，得一路翻回才知道它是 `A` 的成员、谁 `usingnamespace` 了 `A`。显式导入把"这个名字的来源"写在每一处使用点上。代价是多打几个字符，收益是**可grep、可重构、无隐式控制流**——和 Zig 在别处的一贯取舍一致。

## 7.15 禁止遮蔽：同名 shadow 是编译错

Zig **不允许**内层作用域用和外层同名的变量（03 章 3.10 节实测过，这里补上结构体视角）。

```zig
// examples/07_structs/main.zig 第 432-447 行
    // ═══ 7.15 禁止遮蔽：同名 shadow 是编译错 ═══
    begin("7.15");
    const tmp = Point{ .x = 1, .y = 2 };
    const total = tmp.dist();
    if (total > 0) {
        // 内层想再用 total 这个名字 → 编译错：
        //   error: local constant 'total' shadows local constant from outer scope
        //   note: previous declaration here
        // 变通做法：换个名字
        const total_sq = total * total;
        std.debug.print("内层用 total_sq={d:.1}（不能叫 total）\n", .{total_sq});
    }
    // 字段名与方法名属于不同命名空间，互不干扰
    const same = Point{ .x = 2, .y = 0 };
    std.debug.print("字段 x 与方法互不干扰：x={d:.1} dist={d:.1}\n", .{ same.x, same.dist() });
    end("7.15");
```

运行输出（`examples/07_structs/main.zig`）：

```text
==== 7.15 开始 ====
内层用 total_sq=5.0（不能叫 total）
字段 x 与方法互不干扰：x=2.0 dist=2.0
==== 7.15 结束 ====
```

**报错原文（实测）**：

```text
error: local constant 'total' shadows local constant from outer scope
note: previous declaration here
```

（`const` 与 `var` 的措辞不同：写`var` 时是 `local variable 'x' shadows local variable from outer scope`，但都是编译错。）

原书《Learning Zig》ch5 说得很直接："in Zig, scope shadowing is simply not allowed… This isn't JavaScript." 理由很实在：**同名变量让"这一行到底在动哪个"变成需要动脑排查的事**。代价是变通写法——给内层换个名字（示例里的 `total_sq`）。

⚠️ **变量名不能遮蔽原始类型名。** 实测 `var u1: User = .{...};` 报 `error: name shadows primitive 'u1'` + `note: consider using @"u1" to disambiguate`。写 `var u1 = ...` 看着人畜无害，但它和 `u1` 这个 1 位无符号整型撞了。本章示例里所有 `u1` / `u2` 变量都叫 `ua` / `ub` 就是这个原因。

**但字段名和方法名不受这条限制**——因为它们在不同的命名空间：字段在**实例**上，方法在**类型**上。`p.x` 和 `Point.dist` 可以共存，`p.dist` 是类型成员查找，`p.x` 是字段查找，两者不冲突。7.5 节讲过"没有 `static` 关键字"的另一面就是这个。

## 7.16 坑位清单

1. **漏字段是编译错**：没有默认值的字段不写 → `error: missing struct field: x` + `note: struct declared here`。Zig 不存在"部分初始化的结构体"——这和 C 里 `struct S s = {0}` 悄悄清零完全相反。
2. **具名字段结构体不能用位置初始化**：`Point{ 3, 4 }` → `error: type 'main.Point' does not support array initialization syntax`。**而且编译器本来就不保证字段的内存顺序**（见第 6 条），位置初始化即使能过也是自欺欺人。
3. **结构体字段不能写 `var` / `const`**：`struct { var x: i32 = 0, y: i32 }` → `error: expected ';' after declaration`。字段永远是可写的位，能不能写取决于你手里的绑定是 `const` 还是 `var`。好处是 `const` 实例传给 `fn f(p: *Point)` 会立刻报 `cast discards const qualifier`。
4. **值 `self` 里改字段是编译错**：`fn set(self: Point) void { self.x = 1; }` → `error: cannot assign to constant`。要改必须 `self: *Point`。同理值参数 `fn byValue(p: Point)` 里想改得先 `var local = p;` 拷一份。
5. **`const` 实例不能调指针 `self` 方法**：`const c = Point{...}; c.translate(1, 1);` → `error: expected type '*Point', found '*const Point'`。
6. **`auto` struct 的字段内存顺序 ≠ 声明顺序**：实测 `Auto{ a: u8, b: u32, c: u8 }` 的偏移是 `a@4 b@0 c@5`（编译器把 u32 挪到最前）。**要按字节走就用 `extern` 或 `packed`。**
7. **`extern struct` 的数据长度可能小于 `sizeOf`**：`Wire{ a: u32, b: u16 }` 数据 6 字节但 `sizeOf = 8`，末尾 2 字节是内容不确定的 padding。别把 `asBytes` 的结果直接写文件，走 `std.mem.readInt` 按字段读。
8. **`@bitCast` 拒绝裸结构体（extern 也不行）**：`error: cannot @bitCast from 'main.Wire'`——即使 `@sizeOf` 相等也不行。**唯一例外是 `packed struct`**。正解是 `std.mem.asBytes` + `std.mem.readInt`/`writeInt`。
9. **`extern struct` 不许含非 2 的幂次位宽字段**：`extern struct { a: u24 }` → `error: extern structs cannot contain fields of type 'u24'`。省空间的任意位宽只能在 `packed struct` / 普通 struct 里用。
10. **`packed struct` 里不能取字段地址**：`&reg.rest` → `error: expected type '*u15', found '*align(1:0:1) u15'`（对齐只有 1 字节，地址不是硬件可寻址的）。改单个字段用 `@field` 按值读写。
11. **`@fieldParentPtr` 在 0.17 要配 `@alignCast`**：`error: @fieldParentPtr increases pointer alignment` + `note: struct field 'mana' limits alignment to '2'`。写 `@alignCast(@fieldParentPtr("mana", p))`。这是安全的（父指针必然比字段对齐更强），编译器要你亲口确认。
12. **`@typeInfo(T).@"struct".fields` 在 0.17 不存在**：改用三条等长平行数组 `field_names` / `field_types` / `field_attrs`，按下标配对。`.tag` 已改名 `.layout`（`.auto` / `.@"extern"` / `.@"packed"`）。配套还有 `is_tuple` / `decl_names` / `backing_integer`。
13. **`field_types`（元素 `type`）只能用 `inline for`**：普通 `for` 报 `values of type 'type' must be comptime-known` + `note: types are not available at runtime`。`@field(value, fname)` 的名字参数同样要求编译期已知。`field_names` 的元素是哨兵切片，打印写 `fname[0..fname.len]`，写 `fname[0..3 :0]` 报 `value in memory does not match slice sentinel`。
14. **元组不能运行期索引**：`tup[i]` 的 `i` 必须编译期已知，否则 `error: unable to resolve comptime value` + `note: tuple field index must be comptime-known`。`@field(p, runtimeString)` 同样报 `field name must be comptime-known`。要运行期索引就用数组/切片。
15. **可选字段必须显式写 `= null`**：`struct { v: ?u32 }` 的 `Bad{}` 报 `missing struct field: v`——**`?T` 只是"能装 null"，不等于"默认是 null"**。另外 `?T` 不额外占字节（Zig 用空指针表示 null），所以 `?[]const u8` 和 `[]const u8` 一样宽。
16. **`usingnamespace` 在 0.17 已被移除**：`error: expected ',' after field`（被当成结构体字段解析）。替代品是 `const a = @import("a.zig");` 然后写 `a.v`。**另外：变量名不能遮蔽原始类型名**——`var u1 = ...` 报 `error: name shadows primitive 'u1'`；**内层块用同名变量**报 `local constant 'a' shadows local constant from outer scope`。但字段名与方法名在不同命名空间，互不干扰。

### 测试：把语义钉住

本章行为全靠 14 个 `test` 块守着（`main.zig` 第 488-681 行）：

```text
$ zig test main.zig
1/14 main.test.7.1 字段初始化、默认值与漏字段...OK
2/14 main.test.7.3 方法：值 self 只读，指针 self 才改...OK
3/14 main.test.7.4 值语义：赋值与传参都是拷贝...OK
4/14 main.test.7.5 结构体是命名空间...OK
5/14 main.test.7.6 嵌套结构体与逐层访问...OK
6/14 main.test.7.7 init 不自动调用...OK
7/14 main.test.7.8 匿名结构体与 anytype...OK
8/14 main.test.7.9 元组：.len、下标、@"0" 字段名...OK
9/14 main.test.7.10 可选字段...OK
10/14 main.test.7.11 @field 与 @fieldParentPtr...OK
11/14 main.test.7.12 auto/extern/packed 布局...OK
12/14 main.test.7.13 comptime 反射...OK
13/14 main.test.7.14 文件即 struct...OK
14/14 main.test.7.15 方法名与字段名属于不同命名空间...OK
All 14 tests passed.
```

三个测试值得单独看：

- **7.7**断言 `Session{ .id = 1 }` 的 `slots == 4`（字段默认值，不是 `init` 设的值）——这就是"`init` 不自动调用"的机器可验证形式。
- **7.12** 断言 `@offsetOf(Auto, "b") == 0`（u32 被挪到最前）和 `@offsetOf(Auto, "a") == 4`——把"编译器会重排字段"这条事实钉成断言，以后编译器行为变了测试会立刻响。
- **7.13** 断言三条平行数组 `field_names.len == field_types.len == field_attrs.len`，并用 `default_value_ptr != null` 区分 `x`（无默认值）和 `y`（有默认值）。

---

上一章：[06 数组切片字符串](06-slices.md) · 下一章：[08 枚举与联合](08-enums.md)