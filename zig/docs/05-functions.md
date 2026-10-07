# 05 · 函数

> 对应示例：`examples/05_functions/main.zig`
>
> 前四章讲"值怎么变"，这一章讲**结构**。函数是 Zig 里**唯一**的抽象手段
> ——没有类、没有继承、没有闭包、没有异常、没有默认参数、没有重载——
> 这些"缺失"都不是 bug，而是各有替代方案。读完你应该能回答：
> Zig 为什么敢不要重载，以及 `!T` 里的 `T` 消失了是什么意思。

---

## 5.1 声明与返回值

语法是 `fn 参数表 返回类型 { }`。参数名在前类型在后（冒号），返回类型在参数表**之后**，
不返回东西写 `void`。函数不需要前置声明——`add2` 定义在 `main` 之后（第 583 行），
`main` 里照样调用。

```zig
// examples/05_functions/main.zig 第 14-29 行
fn add(a: i64, b: i64) i64 {
    return a + b;
}

fn greet(name: []const u8) void {
    std.debug.print("  你好，{s}\n", .{name});
}

fn increment(n: i32) i32 {
    // n += 1; // error: cannot assign to constant —— 参数天生是 const
    var copy = n; // 想改就自己复制一份
    copy += 1;
    return copy;
}
```

运行输出（`examples/05_functions/main.zig`）：

```text
==== 5.1 声明与返回值 开始 ====
add(3, 4)=7  返回类型=i64
  你好，Zig
  你好，函数
increment(10)=11（参数是 const，函数内改的是副本）
==== 5.1 声明与返回值 结束 ====
```

**参数是 `const`**：`increment(10)` 返回 11 而不是报错，因为函数体写的是 `var copy = n`。
这条纪律让"这个函数会不会偷偷改我的数据"永远不需要猜。**返回类型不能省略**——
老教程里 `fn f(x: i32) { ... }`（靠推断）在 0.17 报 `error: expected return type
expression, found '{'`，和 5.8 节同根同源。**Zig 不做返回类型推断。**

## 5.2 可选返回值 `?T`

"可能找到也可能找不到"用 `?T`，最自然的写法是 `for` 循环里提前 `return`：

```zig
// examples/05_functions/main.zig 第 33-46 行
fn firstEven(xs: []const i32) ?i32 {
    for (xs) |x| {
        if (@mod(x, 2) == 0) return x; // 注意：i32 的 % 要写 @mod
    }
    return null; // 一个都没找到
}

// findByte 同构（第 41-46 行），只是返回下标：
//   for (haystack, 0..) |b, i| { if (b == needle) return i; }
//   return null;
```

运行输出（`examples/05_functions/main.zig`）：

```text
==== 5.2 可选返回值 ?T 开始 ====
firstEven([1,3,4,5]) = 4（找到4）
firstEven([1,3,5])   = null（全是奇数 → null）
findByte("zig", 'g')  = 2
findByte("zig", 'x')  = null
解包失败用 -1兜底 = -1
?i32 类型名 = ?i32
==== 5.2 可选返回值 ?T 结束 ====
```

**`?T` 的语义边界很窄**：它只表示"有可能没有值"，**不表示"失败了"**。找不到元素、
数组可能为空、可选下标越界——这些是正常、可预期的结果。但"文件打不开""网络断了"
不是"没有值"，那是错误，交给下一节的 `!T`。**解包三姿势**：
`if (opt) |v| { ... } else { ... }`、`opt orelse 默认值`、`opt.?`。

⚠️ **`i32` 的 `%` 必须写 `@mod`**。示例第 35 行是 `@mod(x, 2)`，照抄 C 的 `x % 2` 会撞上
`error: remainder division with 'i32' and 'comptime_int': signed integers and floats must use @rem or @mod`。

## 5.3 错误返回值 `!T` 与错误集合推导

Zig **没有异常**。失败必须写进签名：`!T` 表示"要么给一个 T，要么给一个错误"。
`!` 是 `anyerror` 的简写（所以 `!u32` 全写是 `anyerror!u32`），但更推荐**让编译器推导**
——只写一个 `!`，不给错误集：

```zig
// examples/05_functions/main.zig 第 51-83 行
/// 无参 `!`：编译器从函数体推导出一个只含实际出现过的错误的集合
fn inferredFail(ok: bool) !void {
    if (!ok) return error.Boom;
    if (ok) {} // 成功路径什么都不做
}

/// 具名错误集：写死"可能报哪几种错"，可被 @typeInfo 列出成员
const ParseError = error{ Empty, BadDigit };

fn parseDigits(s: []const u8) ParseError!u32 {
    if (s.len == 0) return error.Empty;
    var acc: u32 = 0;
    for (s) |c| {
        if (c < '0' or c > '9') return error.BadDigit;
        acc = acc * 10 + @as(u32, c - '0');
    }
    return acc;
}

/// anyerror!T：最宽松，"任何错误都可能出现"。库内部常用，公开 API 不该用
fn anythingGoesWrong() anyerror!u8 {
    return error.Mystery;
}

/// 双重失败：!?T 读作"可能报错；不报错的话还可能没有值"
fn findPositive(xs: []const i32) !?i32 {
    for (xs) |x| {
        if (x > 0) return x;
    }
    if (xs.len == 0) return error.EmptyInput; // 第一层失败：错误
    return null; // 第二层失败：没找到值，但不算错误
}
```

运行输出（`examples/05_functions/main.zig`）：

```text
==== 5.3 错误返回值 !T 开始 ====
inferredFail(true)  = void
inferredFail(false) = error.Boom
inferredFail 的错误集 == anyerror ? false  成员数=1
parseDigits 的错误集成员数=2： Empty BadDigit
parseDigits("1234") = 1234
parseDigits("")= error.Empty
parseDigits("12a")    = error.BadDigit
anythingGoesWrong()      = error.Mystery（anyerror!u8）
anythingGoesWrong 类型   = anyerror!u8
findPositive([负数]) = null（不报错，只是 null）
findPositive([])    = error.EmptyInput（这是错误）
findPositive([-1,7]) = 7
!?i32 打印出来的类型名 = @typeInfo(@typeInfo(@TypeOf(main.findPositive)).@"fn".return_type.?).error_union.error_set!?i32
（这一长串就是 0.17 的坑：推导错误集无名字，只能这么打）
parseDigits("") catch 0 = 0（错误就地兜底）
==== 5.3 错误返回值 !T 结束 ====
```

**无参 `!` 是"让编译器数一数你用了几种错误"**——这是本章最容易被误解的符号。
`!void` 里的 `!` **不是**"返回任意错误"，它等价于 `anyerror!void`，但**编译器会把它收窄**：
扫一遍函数体，只保留实际 `return error.X` 出现过的那些错误。证据是输出第 3 行：
函数体只 `return error.Boom`，成员数就是 1，而且 `== anyerror` 为 `false`
（test 块第 606-619 行把这条钉成了断言）。**为什么推导比 `anyerror` 好**：错误集是签名的
一部分，写 `anyerror!u32` 等于对调用方说"随便什么错都可能出现"——那调用方除了 `anyerror`
什么都接不住，等于没有承诺；写 `!u32` 才是真正的承诺。反过来，推导的集合**不能被外部检查**，
所以公开 API 应该用具名错误集：它可文档化、可被 `@typeInfo` 反射、能被 `switch` 穷举
（输出第 4 行）。⚠️ 而推导出的集合是**匿名的**，`@typeName` 只会给你
`@typeInfo(...)...error_union.error_set!?i32` 这一串（输出倒数第 3 行）。

**`?T` 和 `!T` 的分工**：`findPositive` 展示了叠起来的样子——`[-1, 7]` → `7`（找到）；
`[-1, -2]` → `null`（没找到，但正常结果）；`[]` → `error.EmptyInput`（空数组是调用方的错）。
**处理错误的五个动作**：`try` 向上抛、`catch` 就地兜底、`catch |err|` 拿到错误值、
`catch 默认值`（示例第 425 行的 `parseDigits("") catch 0`）、`catch unreachable` 赌一把。

## 5.4 没有重载：`comptime T` 与 `anytype`

**Zig 没有重载**。同名不同参的两个函数是**直接编译错**，不是"编译器帮你选一个"：

```text
error: duplicate struct member name 'f'
fn f(a: i32) i32 { return a; }
   ^
note: duplicate name here
```

替代方案有两个，都靠**编译期特化**实现：

```zig
// examples/05_functions/main.zig 第 94-108 行
/// 泛型：comptime T: type 把"类型"本身当编译期参数传进来
fn maxOf(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}

/// anytype：对每个实际传入的类型自动特化一份（std.debug.print 的 args 就是它）
fn describe(value: anytype) void {
    const T = @TypeOf(value);
    std.debug.print("  类型 {s} → 值 {any}\n", .{ @typeName(T), value });
}

/// anytype 的多参数版：同一次调用里多个参数可以是不同类型
fn firstOf2(a: anytype, b: anytype) @TypeOf(a) { _ = b; return a; }
```

运行输出（`examples/05_functions/main.zig`）：

```text
==== 5.4 没有重载：comptime T 与 anytype 开始 ====
maxOf(i32, 3, 9)   = 9（类型 i32）
maxOf(f64, 2.5, 1.5) = 2.5（类型 f64）
两种 T 各特化一份，函数地址不同？ true
  类型 comptime_int → 值 42
  类型 comptime_float → 值 3.5
  类型 bool → 值 true
  类型 *const [3:0]u8 → 值 { 97, 98, 99 }
  类型 u8 → 值 7
firstOf2(9, "str") = 9（anytype 允许不同类型）
==== 5.4 没有重载：comptime T 与 anytype 结束 ====
```

- **`comptime T: type`**：传的是**类型**本身，调用处要显式写 `maxOf(i32, 3, 9)`。
  适合公开 API、参数之间有类型关系（`fn f(comptime T: type, a: T, b: T)`）；
  代价是调用处啰嗦。
- **`anytype`**：传的是实参，类型自动推导，调用处写 `describe(42)`。
  适合打印/工具函数（`std.debug.print` 的 `args` 就是它），多个参数还可以是**不同**类型；
  代价是错误报在**调用处**，附一长串模板式跟踪。

**为什么敢不要重载**：C++ 的重载解析是"按实参类型猜哪个重载对"，猜错了就是一段难懂的
`ambiguous` 报错。Zig 把选择权交给程序员——要么显式写 `maxOf(i32, ...)`，要么用 `anytype`
让编译器照实参生成一份。代价是调用处啰嗦一点，收益是**没有任何"选错"的可能**。
输出第 3 行是关键：`两种 T 各特化一份，函数地址不同？ true`——
`@TypeOf(maxOf(i32,0,0))` 和 `@TypeOf(maxOf(f64,0.0,0.0))` 是**两个不同的类型**，
因为 `comptime T` 是签名的一部分。这就是"泛型零开销"的技术含义：
不是运行期做类型检查，是**编译期生成多份**。

## 5.5 没有默认参数：匿名结构体

默认值放在**结构体字段**上，调用处用 `.{ }` 只写要覆盖的：

```zig
// examples/05_functions/main.zig 第 113-121 行
const DrawOpts = struct {
    color: []const u8 = "black",
    bold: bool = false,
    size: u8 = 1,
};

fn rect(o: DrawOpts) void {
    std.debug.print("  rect color={s} bold={} size={d}\n", .{ o.color, o.bold, o.size });
}
```

运行输出（`examples/05_functions/main.zig`，第 447-452 行的四次调用）：

```text
==== 5.5 匿名结构体参数 开始 ====
  rect color=black bold=false size=1
  rect color=red bold=false size=1
  rect color=green bold=true size=1
  rect color=black bold=false size=3
==== 5.5 匿名结构体参数 结束 ====
```

四行就是全部语义：`rect(.{})` 全默认、`rect(.{ .color = "red" })` 只改 color
（其余仍取默认）、`rect(.{ .size = 3 })` 只改 size。`std` 库全是这个模式
（`openFile(path, .{ .mode = .read_only })`）。**位置参数超过三个以后可读性会断崖下跌。**
⚠️ 但用 `anytype` 收匿名结构体时**字段必须全给**：`fn anon(o: anytype)` 里访问 `o.bold`，
那 `anon(.{ .color = "x" })` 会报 `error: no field named 'bold' in struct ...`——
`anytype` 造出来的是**匿名字面量类型**，没有字段声明就没有默认值。要默认值必须用具名类型。

## 5.6 `defer` 与 `errdefer`

`defer` 把代码安排到**当前作用域退出时**执行（无论怎么退出），多条按 **LIFO 逆序**执行。
`errdefer` 是错误专用变体：**只在函数返回错误时**执行。

```zig
// examples/05_functions/main.zig 第 155-162 行（核心；轨迹记录辅助见 128-152 行）
/// 模拟"获取资源→可能失败→释放"。
/// defer 无条件跑；errdefer 只在**返回错误**时跑。
fn acquireResource(should_fail: bool) !u8 {
    note("acquire");
    defer note("defer(一定跑)");
    errdefer note("errdefer(出错才跑)");
    if (should_fail) return error.NoResource;
    return 42;
}
```

配套三个演示函数（第 164-196 行）：`deferLifo` 连续注册三条 `defer` 观察逆序；
`deferInLoop` 在 `for` 循环体里注册 `defer`；`nestedScope` 演示内层块的 `defer`
只在内层块结束时跑。

运行输出（`examples/05_functions/main.zig`）：

```text
==== 5.6 defer 与 errdefer 开始 ====
acquireResource(false)=42 轨迹 [acquire] [defer(一定跑)]
acquireResource(true) = error.NoResource 轨迹 [acquire] [errdefer(出错才跑)] [defer(一定跑)]
 [函数体] [第3个注册的defer] [第2个注册的defer] [第1个注册的defer]
 [第0次迭代的本体] [第0次迭代的defer] [第1次迭代的本体] [第1次迭代的defer] [第2次迭代的本体] [第2次迭代的defer]
 [外层-进入] [内层-本体] [内层-退出] [外层-尾巴] [外层-退出]
returnThenDefer()=0，之后 defer_trace=1（返回值先求值）
==== 5.6 defer 与 errdefer 结束 ====
```

逐行读输出：第 1 行**成功路径只有 `defer` 跑**；第 2 行**失败路径两个都跑**；
第 3 行是**LIFO 逆序**（后注册的第 3 个先跑）；第 4 行 6 个格子说明 `defer` 挂在
**每一次迭代**上、不是循环结束后跑一次；第 5 行说明内层 `defer` 只在内层块结束时跑；
第 6 行说明 `defer` 在返回值**求值之后**执行、改不动返回值。

⚠️ **第 2 行的顺序反直觉**：`errdefer` 注册在前、`defer` 注册在后，按 LIFO 应该
`defer` 先跑——但实测输出是 `errdefer` 在前。这是 0.17 的实际行为，记住，别推演。

**两者的分工**是资源管理的核心模式：`defer` 做**通用清理**（关文件、free 内存——
成功失败都要做），`errdefer` 做**失败回滚**（撤销已做的改动）。"获取资源 → `defer` 清理
→ 中间可能失败 → `errdefer` 回滚"这个三段式在 11 章（分配器）、20 章（文件 IO）
会反复出现。它比 C++ RAII 和 Go defer 都强的地方在于**作用域粒度最细**：
Go 只能挂在函数尾，C++ 把清理藏进析构函数里（看不见），
Zig 的 `defer` 就写在你想要它跑的那一层块上，一眼可见。

## 5.7 函数指针：一等函数

函数在 Zig 里是**值**：可以存进变量、数组、结构体，可以当参数传。
类型写法是 `*const fn (参数表) 返回类型`：

```zig
// examples/05_functions/main.zig 第 199-228 行
const BinOp = *const fn (i32, i32) i32;

fn apply(op: BinOp, a: i32, b: i32) i32 {
    return op(a, b); // 直接调用指针
}
// CmpFn = *const fn (i32, i32) bool，less / greater 同理（第 211-219 行）

/// Zig **没有嵌套函数**。需要"局部函数"时用匿名 struct 当命名空间，
/// 注意它捕获不了外层变量，参数必须显式传。
fn outer(x: i64) i64 {
    const helper = struct {
        fn square(v: i64) i64 {
            return v * v;
        }
    }.square;
    return helper(x) + helper(@divTrunc(x, 2));
}
```

运行输出（`examples/05_functions/main.zig`）：

```text
==== 5.7 函数指针 开始 ====
  ops[0](10, 3) = 13
  ops[1](10, 3) = 7
  ops[2](10, 3) = 30
BinOp 类型名 = *const fn (i32, i32) i32
  cmps[0](3, 9) = true
  cmps[1](3, 9) = false
@call(.auto, sub, .{10, 3}) = 7
outer(8) = 80（匿名 struct 模拟局部函数）
==== 5.7 函数指针 结束 ====
```

第 1-3 行是把函数指针存进**数组**再交给 `apply` 间接调用——这就是"把行为当数据传"的
全部机制。C 要写 `int (*ops[3])(int,int) = {add, sub, mul};`，Zig 的
`[_]BinOp{ add2, sub, mul }` 更直白，且元素自动从 `fn(...)` 转成 `*const fn(...)`。

⚠️ **`@call` 在 0.17 是三参数**：`@call(调用约定, 函数, 参数元组)`。老的两参数写法报
`error: expected 3 arguments, found 2`。

⚠️ **函数体内不能直接声明 `fn`**，这是语法错（报错非常迷惑）：
`error: expected ';' after statement`。Zig 的函数只能属于**容器**（文件、struct、
union、enum）。需要"局部函数"时用**匿名 struct 当命名空间**（上面 `outer` 里的 `helper`）。
注意它**捕获不了外层变量**——`square` 看不到 `outer` 的 `x`，必须显式传参。这是 Zig
**没有闭包**的直接后果："函数 + 它需要的数据"要表达成一个 struct，方法里通过 `self` 拿（07 章）。

## 5.8 递归

递归函数**必须写全返回类型**，这是 5.1 那条规则的直接后果：

```zig
fn countdown(n: u32) {
    if (n == 0) return;
    countdown(n - 1);   // ❌
}
```

```text
error: expected return type expression, found '{'
fn countdown(n: u32) {
                     ^
```

**为什么**：返回类型推断需要分析函数体，而函数体里有对自身的调用——要分析它就得先知道
返回类型。循环依赖，编译器只能报错。写全返回类型就打破了循环：调用方已经知道要一个
`u32`，函数体可以安心分析。

```zig
// examples/05_functions/main.zig 第 235-244 行
fn countdown(n: u32) u32 {
    if (n == 0) return 0;
    return 1 + countdown(n - 1);
}

/// 斐波那契：朴素递归（指数级慢，只作教学演示）
fn fib(n: u32) u64 {
    if (n < 2) return n;
    return fib(n - 1) + fib(n - 2);
}
```

运行输出（`examples/05_functions/main.zig`）：

```text
==== 5.8 递归 开始 ====
countdown(5) = 5
fib(20)     = 6765（朴素递归，指数级）
fib(25)     = 75025（还能跑，但已经很慢了）
==== 5.8 递归 结束 ====
```

Zig 的递归没有任何特殊之处——**没有尾调用优化保证、没有栈大小提示**。`fib(25)`
"还能跑"只是因为 Debug 模式的栈还撑得住，`fib(35)` 就会爆栈。朴素递归只适合教学，
真要算就用带记忆化的版本（或干脆迭代）。

## 5.9 `comptime` 参数的函数

参数标了 `comptime` 就必须在**编译期**已知，整个函数在编译期求值一次，
返回值固化成常量：

```zig
// examples/05_functions/main.zig 第 248-265 行
/// comptime 值参数：调用处必须给编译期已知的值，整个函数在编译期求值一次
fn squareArea(comptime w: u32, comptime h: u32) u32 {
    return w * h;
}

/// 纯编译期阶乘：comptime 变量 + inline while（⚠️ 必须是 inline while）
fn factorial(comptime n: u32) u64 {
    comptime var acc: u64 = 1;
    comptime var k: u32 = 2;
    inline while (k <= n) : (k += 1) acc *= k;
    return acc;
}

/// comptime 参数 + 运行期参数混合
fn scaleBy(comptime k: u32, v: u32) u32 {
    return v * k;
}
```

运行输出（`examples/05_functions/main.zig`）：

```text
==== 5.9 comptime 参数的函数 开始 ====
squareArea(6, 7)   = 42（编译期算好的常量）
factorial(10)      = 3628800（inline while 在编译期展开）
scaleBy(3, 100)    = 300（k 是comptime，v 是运行期）
==== 5.9 comptime 参数的函数 结束 ====
```

- **`squareArea(6, 7)` 的 42 是编译期常量**：直接躺在二进制里，运行期没有任何计算。
  传运行期变量会报 `error: argument to comptime parameter must be comptime-known`。
- **`scaleBy(3, 100)` 是混合的**：`k` 编译期、`v` 运行期。这种"部分编译期"的函数
  是 Zig 泛型的主力形态——编译器把 `k` 优化成常量，只对 `v` 生成机器码。
- ⚠️ **`inline while` 不是"性能选项"**：写普通 `while` 会报
  `error: cannot store to comptime variable in non-inline loop`
  ——普通循环是运行期的循环体，往编译期变量里赋值在语义上说不通。

## 5.10 泛型函数

`comptime T: type` 让**类型本身**成为编译期参数，返回类型也可以用 T：

```zig
// examples/05_functions/main.zig 第 269-284 行
/// 泛型 + 泛型返回值：返回结构体的字段类型就是 T
fn makePair(comptime T: type, a: T, b: T) struct { a: T, b: T } {
    return .{ .a = a, .b = b };
}

/// 泛型求和：同一份代码对 u8 / i64 各特化一份
fn sumOf(comptime T: type, xs: []const T) T {
    var acc: T = 0;
    for (xs) |x| acc += x;
    return acc;
}

/// 类型约束靠"body 里用了什么类型操作"隐式表达：a < b 要求 T 支持 <
fn needsComparable(comptime T: type, a: T, b: T) bool {
    return a < b;
}
```

运行输出（`examples/05_functions/main.zig`）：

```text
==== 5.10 泛型函数 开始 ====
makePair(u8, 1, 2)   = .{ .a = 1, .b = 2 }（类型 main.makePair__struct_927）
makePair(i64, -1, -2)= .{ .a = -1, .b = -2 }（类型 main.makePair__struct_929）
sumOf(u8, [1,2,3])   = 6（类型 u8）
sumOf(i64, [10,20])  = 30（类型 i64）
needsComparable(u8, 1, 2) = true
needsComparable(f64, 1, 2) = true
==== 5.10 泛型函数 结束 ====
```

**泛型没有 `where` 子句**。类型约束是**隐式**的：`needsComparable` 里写了 `a < b`，
就要求 T 支持 `<`；`sumOf` 里写了 `acc += x`，就要求 T 支持 `+` 和 `0`。传不支持的
类型（比如切片）在编译期就炸：`error: operator comptime_int '<' not allowed for type
'[]const u8'`。这比 `where` 简洁得多，而且约束和函数体**永远一致**——不会出现"约束写了
但函数体没用"的虚假约束，也不会出现"函数体用了但约束漏了"的漏洞。

`makePair` 两次调用的类型名不同（`__struct_927` / `__struct_929`）：**每个 T 都生成了独立
的返回类型**，这不是 bug，是泛型的本质。⚠️ 匿名结构体类型的名字是编译器生成的内部名
（带序号，跨版本会变），**永远不要在代码或断言里依赖它**。

## 5.11 多返回值：元组

Zig 没有"输出参数"，要返回多个值就返回**元组**。Zig 的元组是**结构体**，
`struct { i32, i32 }` 是匿名的（有字段名就是普通结构体）：

```zig
// examples/05_functions/main.zig 第 288-295 行
/// 具名字段元组：有自解释性
fn divmod(a: i32, b: i32) struct { q: i32, r: i32 } {
    return .{ .q = @divTrunc(a, b), .r = a - @divTrunc(a, b) * b };
}

/// 匿名元组 struct { i32, i32 }：只能按 [0]/[1] 访问
fn minmax(a: i32, b: i32) struct { i32, i32 } {
    return .{ if (a < b) a else b, if (a < b) b else a };
}
```

运行输出（`examples/05_functions/main.zig`）：

```text
==== 5.11 多返回值：元组 开始 ====
divmod(17,5): q=3 r=2（具名字段，类型 main.divmod__struct_943）
minmax(3,9): mm[0]=3 mm[1]=9 len=2（匿名元组，类型 struct { i32, i32 }）
解构const lo, const hi = 3, 9
具名元组也能按 [0] 访问？见 test 块
==== 5.11 多返回值：元组 结束 ====
```

**具名**（`struct { q: i32, r: i32 }`）用 `dm.q` 访问，自解释，但类型名是内部名
（`main.divmod__struct_943`，别依赖），也**没有 `.len`**；**匿名**（`struct { i32, i32 }`）
只能 `mm[0]` 访问，类型名稳定可读、有 `.len`。两者都能解构（输出第 4 行），
所以返回值超过两个时**优先用具名字段**——`res.q` 比 `res[0]` 强得多。⚠️ 但**具名字段的结构体不能按 `[0]` 访问**：想当然地写 `dm[0]` 会报
`error: type 'main.divmod__struct_943' does not support indexing`
+ `note: operand must be an array, slice, tuple, or vector`。`struct { q: i32, r: i32 }`
是**具名结构体**（只是恰好返回两个值），不是元组。这个区分不是吹毛求疵——
它决定了能不能下标、有没有 `.len`，编译期就分得清。

## 5.12 `noreturn` 与 `unreachable`

`noreturn` 标记"这个函数不会正常返回"。因为它与**所有类型兼容**，
所以能放在任何需要值的位置：

```zig
// examples/05_functions/main.zig 第 299-311 行
/// 返回类型是 noreturn：告诉编译器"这个函数不会正常返回"
fn mustNotReach() noreturn {
    unreachable; // Debug/safe 下 panic: reached unreachable code
}

/// noreturn可以用在任何需要值的位置——它与所有类型兼容
fn classify(code: u8) u8 {
    return switch (code) {
        1 => 42,
        2 => 84,
        else => mustNotReach(),
    };
}
```

运行输出（`examples/05_functions/main.zig`）：

```text
==== 5.12 noreturn 与 unreachable 开始 ====
classify(1) = 42
classify(2) = 84
noreturn 类型名 = noreturn（与所有类型兼容）
unreachable 在 Debug/safe 下 panic：reached unreachable code
==== 5.12 noreturn 与 unreachable 结束 ====
```

`classify` 的返回类型是 `u8` 而不是 `noreturn`——返回类型由**参数**决定，`code` 是运行期
值，编译器只能取 `u8`。但 `else` 分支写 `mustNotReach()` 合法，因为 `noreturn` 与 `u8` 兼容。

**`unreachable` 按构建模式分两种行为**：`debug` / `safe` 下 **panic**
（`thread NNNNN panic: reached unreachable code`）；`fast` / `small` 下编译器**假定该路径
不可能发生**并据此优化，真跑到了是**未定义行为**。这就是"零成本抽象"和"开发期安全网"
的分工。`classify(3)` 会真的 panic，所以示例没调用它。

## 5.13 `inline fn`

`inline fn` 的函数体在被调用处**展开**（像宏），而不是走一次函数调用：

```zig
// examples/05_functions/main.zig 第 316-318 行
/// inline fn：函数体在被调用处**展开**（像宏），而不是走一次函数调用
inline fn triple(x: i32) i32 {
    return x * 3;
}
```

运行输出（`examples/05_functions/main.zig`）：

```text
==== 5.13 inline fn 开始 ====
triple(4) = 12（运行期调用也合法）
comptime triple(5) = 15（编译期展开成常量）
==== 5.13 inline fn 结束 ====
```

**`inline fn` 在运行期调用是合法的**（输出第 2 行）——它不是"只能在编译期调"。`inline`
描述的是**函数体如何被处理**（展开而非调用），不是"调用时机"。需要强制在编译期求值时
关键词是 `comptime`：`comptime triple(5)`（输出第 3 行）。什么时候需要它：递归函数
（否则调用栈会深）、泛型内部的小辅助函数。普通函数编译器**也会**按需内联，不必滥用。

## 5.14 参数传递语义

三种传法，三种语义：

```zig
// examples/05_functions/main.zig 第 322-354 行
const Point = struct {
    x: i32,
    y: i32,
    // format 方法让 {f} 能打印 Point，见下方输出的 "(3, 4)"
};

/// 值传递：Point 是 8 字节，传进来的是**拷贝**。返回新值，原值不动
fn translateByValue(p: Point, dx: i32, dy: i32) Point {
    return .{ .x = p.x + dx, .y = p.y + dy };
}

/// 指针传递：改的是调用方的那份
fn translateByPointer(p: *Point, dx: i32, dy: i32) void {
    p.x += dx;
    p.y += dy;
}

/// 数组按值传 = 拷贝，参数是 const，**改不了元素**
fn firstOfArray(arr: [3]i32) i32 {
    // arr[0] = 99; // error: cannot assign to constant
    return arr[0];
}

/// 想改数组元素，要么传 *[N]，要么传切片
fn bumpPtr(arr: *[3]i32) void {
    arr[0] += 100;
}
fn bumpSlice(xs: []i32) void {
    for (xs) |*x| x.* += 100; // 注意是 |*x| 取元素指针
}
```

运行输出（`examples/05_functions/main.zig`）：

```text
==== 5.14 参数传递语义 开始 ====
按值：原 (3, 4) → 返回 (8, 2)（原值一个字节没变）
按指针：(8, 2)（就地改了调用方那份）
Point 占8 字节 → 按值传就是拷这 8 字节
数组按值传：firstOf([1,2,3])=1，原数组仍是 { 1, 2, 3 }
传 *[3]：{ 101, 2, 3 }
传切片：{ 101, 102, 103 }（切片本身只占 16 字节 = 指针+长度）
数组类型 [3]i32 长度 3；切片类型 []i32 长度 3
==== 5.14 参数传递语义 结束 =====
```

四种写法的语义：`p: Point` 传**拷贝**（8 字节，调用方看不到修改，参数 `const`）；
`p: *Point` 传指针（能改到调用方那份）；`a: [3]i32` 也是**拷贝**（12 字节，参数 `const`，
`arr[0] = x` **编译错**）；`xs: []i32` 传**视图**（指针 + 长度共 16 字节，元素可改）。

**数组按值传是拷贝，而且参数是 `const`**。示例第 345 行的 `arr[0] = 99;` 会报
`error: cannot assign to constant`——比"改了不生效"更早一步，编译期就拦住。这比 C 的
"数组传指针但类型写 `int[3]`"更诚实：**签名里的类型就是真实的传递语义**。`Point` 只有
8 字节，值传递的拷贝成本可以忽略；大结构体（几 KB）就该传 `*const T`。

**切片是"指针 + 长度"的视图**，本身只占 16 字节（输出第 7 行），与元素个数无关——
传百万长度的切片，参数也只有 16 字节。代价是**切片自带边界检查**（越界 panic），
而数组不检查（长度在类型里，编译器知道）。

## 5.15 调用约定与 `pub`

```zig
// examples/05_functions/main.zig 第 358-360 行
/// callconv(.c)：0.17 是 .c（小写），老代码写 .C 会被拒
fn cAdd(a: i32, b: i32) callconv(.c) i32 {
    return a + b;
}
```

运行输出（`examples/05_functions/main.zig`）：

```text
==== 5.15 调用约定与 pub 开始 ====
cAdd(2, 3) = 5（callconv(.c)，0.17 是小写 .c）
⚠️ main 必须是 `pub fn main`，漏掉 pub 会报std 内部一个看不懂的错：
   struct 'elf.AT__struct_XXX' has no member named 'HWCAP'
==== 5.15 调用约定与 pub 结束 ====
```

### ⚠️ 本章新踩到的 0.17 坑：`main` 漏掉 `pub`，报错在标准库内部

把 `pub fn main()` 的 `pub` 去掉，编译报的**不是** "main 必须 pub"，而是：

```text
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/start.zig:624:23: error: struct 'elf.AT__struct_855' has no member named 'HWCAP'
                elf.AT.HWCAP => at_hwcap = auxv[i].a_un.a_val,
                ~~~~~~^~~~~~
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/elf.zig:222:13: note: struct declared here
note: referenced by:
    _start: /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/start.zig:560:40
```

报错位置在 `lib/std/start.zig` 的 `posixCallMainAndExit`——离源码十万八千里，而且提到
`elf.AT.HWCAP`（一个和你的程序毫无关系的 Linux/Android auxv 常量）。**机制**：漏掉 `pub`
后编译器找不到入口函数，走了"没有 main"的兜底路径去实例化 `posixCallMainAndExit`，
而这条路径在 macOS 目标上本身有 bug（`elf.AT` 在非 Linux 目标下落到 `else => struct {...}`
分支，里面没有 `HWCAP` 字段）——**兜底路径自己先炸了**，把你真正的问题完全掩盖。
最小复现（本机实测）：`pub fn main() void {}` ✅ 通过，`fn main() void {}` ❌ 报上面那个错。
这个错误**只在 macOS 上出现**，Linux 端没有 `posixCallMainAndExit` 这条路径。

**诊断口诀**：看到报错指向 `lib/std/start.zig` 或 `lib/std/elf.zig`，**先回头检查
`pub fn main` 的 `pub` 有没有写**。写 5.15 节时被这个报错卡了十几分钟，逐个删除顶层声明
做二分才定位到。

`callconv` 指定调用约定——参数怎么传、谁负责清栈。`.c` 是 C ABI，导出给其他语言调用时
必须标。⚠️ **0.17 是小写 `.c`**，老代码写 `callconv(.C)` 会被拒（17 章详述互操作）。

## 5.16 坑位清单

1. **返回类型不能省略**：`fn f(x: i32) { ... }` → `error: expected return type expression, found '{'`。Zig 不做返回类型推断（5.1）。
2. **递归函数必须写全返回类型**：返回类型推断要分析函数体，函数体又要调用自己 → 循环依赖（5.8）。
3. **`main` 必须是 `pub fn main`**：漏掉 `pub` 在 macOS 上报 `struct 'elf.AT__struct_855' has no member named 'HWCAP'`，**报错在 `lib/std/start.zig` 里，完全掩盖真正原因**（5.15）。看到 `lib/std/elf.zig` 报错先查 `pub`。
4. **Zig 没有重载**：同名不同参 → `error: duplicate struct member name 'f'`。替代方案是 `comptime T: type` 或 `anytype`（5.4）。
5. **`i32` 的 `%` 必须写 `@mod`**：`x % 2` → `error: remainder division with 'i32' and 'comptime_int': signed integers and floats must use @rem or @mod`（5.2）。
6. **无参 `!` 推导出的错误集不是 `anyerror`**，而且是**匿名的**：`@typeName` 只会给你一串 `@typeInfo(...)...error_union.error_set!?i32`。要可文档化就用具名错误集（5.3）。
7. **函数值不能从推导错误集 coerce 成 `anyerror` 函数指针**：`const as_any: anyerror!void = inferredFail;` → `error: expected type 'anyerror!void', found 'fn (bool) ...error_set!void'`。但函数**返回值**可以向上 coerce（5.3）。
8. **`@call` 是三参数**：`@call(调用约定, 函数, 参数元组)`。老的两参数写法 → `error: expected 3 arguments, found 2`（5.7）。
9. **函数体内不能直接声明 `fn`**：`error: expected ';' after statement`（报错很迷惑）。用匿名 `struct { fn ... }.name` 模拟局部函数，且**不能捕获外层变量**——Zig 没有闭包（5.7）。
10. **改 `comptime` 变量的循环必须是 `inline while`**：普通 `while` → `error: cannot store to comptime variable in non-inline loop`（5.9）。
11. **具名字段的结构体不能按 `[0]` 访问**：`struct { q: i32, r: i32 }` 报 `type 'main.divmod__struct_943' does not support indexing` + `note: operand must be an array, slice, tuple, or vector`。只有匿名元组才行（5.11）。
12. **数组按值传是拷贝且 `const`**：`fn f(a: [3]i32)` 里写 `a[0] = 1` → `error: cannot assign to constant`。想改就传 `*[N]` 或切片（5.14）。
13. **`anytype` 收匿名结构体时字段必须全给**：`.{ .color = "x" }` 少 `bold` → `error: no field named 'bold' in struct ...`（5.5）。
14. **`unreachable` 在 `fast`/`small` 模式下是未定义行为**：Debug/safe 下 panic，优化模式假定它不会执行。别把"跑不到"当成安全保证（5.12）。
15. **`errdefer` 的执行顺序反直觉**：示例第 155-162 行 `errdefer` 先注册、`defer` 后注册，实测输出却是 `errdefer` 先跑。别按 LIFO 推演这条（5.6）。
16. **匿名结构体类型的名字是编译器内部生成的**（`main.makePair__struct_927`），带序号、跨版本会变，永远不要依赖它；`callconv(.c)` 是小写 `.c`（5.10、5.11、5.15）。

---

上一章：[04 控制流](04-control.md) · 下一章：[06 数组切片字符串](06-slices.md)