# 14 · comptime II：泛型与反射 ⭐

> 对应示例：`examples/14_generics/`
>
> Zig 没有专门的泛型系统——**返回 type 的函数**就是泛型，**@typeInfo** 就是反射。上一章的机制拼起来，本章是成果展。

## 14.1 类型构造器：函数返回 type

```zig
fn Matrix(comptime T: type, comptime rows: usize, comptime cols: usize) type {
    return [rows][cols]T;             // type 是合法的返回值
}
const grid = Matrix(u8, 2, 3){ .{ 1, 2, 3 }, .{ 4, 5, 6 } };
// Matrix(u8,2,3) 在编译期"调用"，结果是 [2][3]u8 这个类型
```

`type` 本身是编译期类型，能当参数、能当返回值——**泛型 = 返回 type 的普通函数**。没有 `template`、没有尖括号：实例化就是函数调用（带缓存，同参数只算一次）。对比 C++ 模板：那边实例化是暗箱（SFINAE/两阶段查找），这边就是"编译期跑了一个函数"——**报错是普通函数的报错**，栈跟踪直接指到你的代码行。

## 14.2 泛型容器：Stack(T)

```zig
fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();                  // 指代"当前正在定义的 struct"

        items: std.ArrayList(T) = .empty,      // 内部用 ArrayList（12 章）

        pub fn push(self: *Self, allocator: std.mem.Allocator, v: T) !void {
            try self.items.append(allocator, v);
        }
        pub fn pop(self: *Self) ?T {
            if (self.items.items.len == 0) return null;
            return self.items.pop();
        }
        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            self.items.deinit(allocator);
        }
    };
}
var stack = Stack(u32){};
```

标准模板：`fn Container(comptime T: type) type` → 返回 `struct { const Self = @This(); ... }`。`@This()` 是"包含我的那个类型"——泛型 struct 里引用自己必须用它（名字还没定）。std 里的 `ArrayList`、`HashMap` 全是这个形状——**读 std 源码就是在读泛型范例**。分配器在方法上（12 章 unmanaged 风格），泛型与内存策略正交组合。

## 14.3 anytype：鸭子类型的接口

```zig
fn sumAll(values: anytype) i64 {
    var total: i64 = 0;
    for (values) |v| total += @intCast(v);   // 要求：能迭代、元素能转 i64
    return total;
}
sumAll(&[_]i32{ 1, 2, 3 });   // 6
sumAll(&[_]u8{ 4, 5 });       // 9——每个类型实例化一份
```

`anytype` 参数 = "编译期检查的鸭子类型"：函数体对值做什么操作，实参类型就得支持什么——不满足时**在调用处报错**（带完整实例化跟踪）。和 05 章说的一样：anytype 灵活但契约模糊，**公开 API 偏好 `comptime T: type`（显式）**，anytype 留给 print/工具函数。Zig 没有 interface/trait——"约束"用 14.4 的反射自己写（14.6 有例子）。

## 14.4 @typeInfo：全量反射

```zig
fn dumpFields(comptime T: type) void {
    inline for (@typeInfo(T).@"struct".fields) |f| {
        std.debug.print("  {s}: {s}\n", .{ f.name, @typeName(f.type) });
    }
}
// Person 的字段：
//   name: []const u8
//   age: u8
```

`@typeInfo(T)` 返回**编译期**的类型描述联合——`.@"struct"`（字段表）、`.enum`（值表）、`.union"`、`.@"fn"`（签名）、`.int`（位宽/符号）、`.pointer`、`.array`……serde、ORM、命令行参数解析、代码生成的地基全是它。注意：**运行期没有反射**（类型信息不进二进制），`@typeInfo` 只能出现在 comptime 上下文——分支要 `inline for` 展开（13.5）。

## 14.5 @field：按名字存取

```zig
var p = Person{ .name = "阿 Z", .age = 25, .vip = true };
const field_name = comptime "age";       // 名字可以是编译期变量
@field(p, field_name) = 26;              // 等价 p.age = 26
@field(p, "vip")                          // 读也一样
```

`@field(value, "name")` 是反射的写侧——名字来自 `@typeInfo` 遍历的 `f.name` 时，就能"循环访问所有字段"（下一个例子）。

## 14.6 编译期代码生成：printAny

```zig
fn printAny(value: anytype) void {
    const info = @typeInfo(@TypeOf(value));
    switch (info) {
        .@"struct" => |s| inline for (s.fields) |f| {
            std.debug.print("  {s} = {any}\n", .{ f.name, @field(value, f.name) });
        },
        else => std.debug.print("  {any}\n", .{value}),
    }
}
```

四件套合体：**@TypeOf 拿类型 → @typeInfo 拆结构 → switch 分派 → inline for + @field 遍历**。给任何 struct 加"自动打印"就是 15 行；把 print 换成 `w.print` 就是序列化雏形。这就是 Zig 的"宏"——但它是类型安全、可调试、带栈跟踪的普通代码。

## 14.7 惯用法与边界

- 泛型容器签名统一 `fn X(comptime T: type) type`；struct 内第一行 `const Self = @This();`
- 反射只管**形状**（字段名/类型/标签），拿不到默认值以外的语义（doc 注释、属性）——复杂序列化还是写显式 `toJson`。
- 每个不同 `T` 实例化一份代码——**二进制膨胀是真的**（C++ 模板同款账单）。泛型热点可考虑 comptime 函数替代泛型容器。
- 实例化错误读法：定位**第一条 `error:`**（在调用处），后面的 `referenced by:` 链是来路不是责任。

## 14.8 坑位清单

1. **anytype 报错在调用处**：错误信息一屏长——只看第一条 error 和它指向的你的代码行，中间的实例化链是路标不是判决。
2. **@typeInfo 返回联合必须 switch**：不能直接 `.fields`——先 `switch (info) { .@"struct" => |s| ... }` 把形态剥出来（编译器强制）。
3. **运行期别找反射**：`@typeInfo` 出现在非 comptime 上下文直接编译错——类型信息只存在于编译期。
4. **`@This()` 写错时机**：嵌套 struct 里 `@This()` 指的是**最近的**容器——跨层引用外层类型要把外层存成命名 const。
5. **@field 的名字必须是编译期字符串**：运行期拼出来的 `[]const u8` 不行——反射遍历之所以能用，正是因为 `f.name` 是编译期值。

---
