# 07 · 结构体

> 对应示例：`examples/07_structs/`

## 7.1 定义与实例化：全字段初始化

```zig
const Point = struct {
    x: f64,
    y: f64 = 0,            // 默认值

    // ...
};
var p = Point{ .x = 3, .y = 4 };   // 字段名初始化，缺省字段可省
const origin = Point{ .x = 0 };    // y 用默认值 0
```

实例化用匿名字面量 `.{ .字段 = 值 }`——**漏掉没有默认值的字段是编译错**（不存在"未初始化的 struct"偷偷跑路）。这配合 7.4 节的匿名 struct，就是 05 章参数结构体惯用法的地基。

## 7.2 方法：第一个参数是 self

```zig
fn dist(self: Point) f64 {                 // 值 self：只读
    return @sqrt(self.x * self.x + self.y * self.y);
}
fn translate(self: *Point, dx: f64, dy: f64) void {  // 指针 self：可改字段
    self.x += dx;
    self.y += dy;
}
p.translate(1, 1);   // 语法糖：编译器自动取址 p
```

**Zig 没有方法语法**——`fn dist(self: Point)` 只是碰巧第一个参数叫 self 的普通函数，`p.dist()` 是 `Point.dist(p)` 的糖。`self` 是惯用名不是关键字（有人写 `myself` 也合法）。值/指针两种 self 的区别要记牢：值 self 改字段是改拷贝（白改），要修改必须 `*Point`。调用时自动取址/解引用（`p.translate(...)` 会自动 `&p`）。

## 7.3 类型即命名空间

```zig
const Config = struct {
    const version = "1.0";              // 关联常量
    fn describe() []const u8 {          // 无 self：静态函数
        return "Config v" ++ version;
    }
};
Config.describe();   // 点号访问
```

struct 不只是"数据布局"，也是**命名空间**：里面可以放常量、函数、嵌套类型，与字段平级。没有 `static` 关键字——写在 struct 里的就是"类型的"，不在实例里。`std.ArrayList` 这类泛型容器全是靠这个机制组织 API 的。

## 7.4 匿名 struct：`.{}` 的真身

```zig
const anon = .{ .name = "Zig", .born = 2016 };  // 匿名结构体：字段有名字
std.debug.print("{s} {d}", .{ anon.name, anon.born });
```

你天天写的 `.{ ... }` 字面量就是匿名 struct——它在函数参数位置被目标类型**强制转换**（coerced），字段对得上就成。也可以像上例一样当轻量记录用（类型是编译期生成的匿名结构体，无法在签名里写出——跨函数传参要正经类型）。

## 7.5 元组：匿名字段的结构体

```zig
const tup = .{ "Zig", 2016, true };
tup[0]        // "Zig"——下标访问，只能在编译期
tup.len       // 3：长度编译期已知
```

元组 = 字段没有名字的 struct。`anytype` 参数接收"参数包"（`std.debug.print` 的 args）本质就是元组。**下标必须是编译期常量**（运行期索引编译错）——要运行期索引的东西用数组/切片。

## 7.6 文件即 struct

每个 `.zig` 文件本身是一个 struct：文件顶层的 `const std = ...`、`pub fn main` 都是它的"字段"。这就是模块系统的全部——`@import("util.zig")` 拿到的是那个文件的 struct，`util.sluggify(...)` 是访问它的 pub 成员。没有 include、没有头文件、没有符号冲突。

## 7.7 惯用法：init / deinit

```zig
const Session = struct {
    id: u32,
    fn init(id: u32) Session {          // 命名构造
        return .{ .id = id };
    }
    fn deinit(self: *Session) void {    // 命名析构（配合 defer 调用）
        self.* = undefined;
    }
};
var sess = Session.init(7);
defer sess.deinit();
```

**Zig 没有构造函数和析构函数**——初始化就是返回 struct 的普通函数（惯用名 `init`），清理就是惯用名 `deinit` 的方法，由调用方用 `defer` 显式调。对比 C++：构造/析构的自动调用很方便，但"什么时候跑了什么代码"不再显而易见——Zig 把这点显式性当成了原则（无隐藏控制流）。需要分配器的 init 长这样：`fn init(allocator) !Self`，配 `defer x.deinit()`（11 章实战）。

## 7.8 坑位清单

1. **值 self 改字段是白改**：`fn f(self: Point) void { self.x = 1; }` 编译都过不了（self 是 const）——加 `var` 也只改了拷贝。要修改必须 `self: *Point`。
2. **漏字段编译错**：`Point{ .x = 1 }` 若 y 无默认值直接报 `missing struct field`——这是特性不是麻烦。
3. **默认值不能引用其他字段**：`.{ .y = x * 2 }` 不合法，字段默认值必须是编译期常量——需要计算就用 init 函数。
4. **元组不能运行期索引**：`tup[i]` 的 i 必须编译期已知；动态索引请用数组。
5. **匿名 struct 跨函数传参会失败**：两个 `.{ .a = 1 }` 在不同上下文是不同类型——正经用途定义命名 struct。

---
