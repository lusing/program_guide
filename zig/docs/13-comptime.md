# 13 · comptime I

> 对应示例：`examples/13_comptime/main.zig`
>
> Zig 的编译期执行和运行期是**同一种语言**——这是它替代 C 预处理器和 C++ 模板元编程的根本方案。
> 读完你应该能自己回答三个问题：为什么改一个 `comptime var` 的循环必须写 `inline while`？
> 为什么 `@setEvalBranchQuota` 的默认值是 1000 而不是"无限"？以及——`comptime` 到底能不能 `print`？

本章的核心变化全部在**本机 0.17.0**（`zig-x86_64-macos-0.17.0`，macOS x86_64）上实测过。
0.17 在 comptime 这一块有一批**不报错但语义变了**的改动（`@Type` 直接没了、`inline for` 反而多了索引捕获），
也有**报错文案彻底换了**的改动（`@hasDecl` 的参数形式、`@tagName` 的适用范围）。本章的坑位清单里
相当一部分就是这些改动的直接后果，所有引用的编译错误文本都实测复现过。

---

## 13.1 一份代码，两个世界

Zig 里**没有** `constexpr` 这样的标注。满足两个条件就在编译期算：值绑定给 `const`（`const` 的初始化必须编译期完成）+ 输入编译期已知。同一份 `fibonacci`，编译期是查表、运行期是函数。

```zig
// examples/13_comptime/main.zig 第 17-21 行
/// 13.1 节：普通函数（没有 comptime 关键字），编译期与运行期都能调。
fn fibonacci(n: usize) usize {
    if (n < 2) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}
```

```zig
// examples/13_comptime/main.zig 第 167-181 行（begin("13.1") 到 end("13.1")）
    // ═══ 13.1 一份代码，两个世界：const 实参 = 编译期算完 ═══
    begin("13.1");
    // 顶层 const 的初始化必须编译期可得 → fibonacci(10) 在编译期算成 55 塞进二进制
    const fib10 = fibonacci(10);
    std.debug.print("fibonacci(10) 编译期常量= {d}\n", .{fib10});
    // 同一个函数，运行期照常调（n 来自运行期，没有任何编译期信息）
    var n: usize = 20; // 假装来自用户输入
    n += 1;
    std.debug.print("fibonacci({d}) 运行期调用 = {d}\n", .{ n, fibonacci(n) });
    // 关键：函数体里没有一行 comptime 关键字，两栖资格是"默认的"
    std.debug.print("对照：{d} < 2 == {}（判断本身没变）\n", .{ fib10, fib10 < 2 });
    // const vs comptime var：const 是"编译期可算"，不是"只在编译期存在"
    const runtime_also: usize = fibonacci(n); // 运行期算的值也能被 const 装
    std.debug.print("运行期值也能被 const 装 = {d}（const ≠ comptime）\n", .{runtime_also});
    end("13.1");
```

运行输出（`examples/13_comptime/main.zig`）：

```text
==== 13.1 开始 ====
fibonacci(10) 编译期常量= 55
fibonacci(21) 运行期调用 = 10946
对照：55 < 2 == false（判断本身没变）
运行期值也能被 const 装 = 10946（const ≠ comptime）
==== 13.1 结束 ====
```

对比 C++20：那边函数要标 `constexpr` 才有两栖资格，而且 `constexpr` 函数有一堆限制（不能有 `static`局部变量、不能有虚函数、……）。Zig 全部函数默认两栖，**没有任何标注成本**。

### `const` 和 `comptime var` 不是一回事

这是本章最容易混掉的一组概念，用输出第 4 行说明：

| | `const x = ...` | `comptime var x = ...` |
|---|---|---|
| 含义 | "这个绑定**不可变**" | "这个绑定**只在编译期存在**" |
| 装什么 | 编译期算的值**或**运行期算的值 | 只能是编译期算的值 |
| 有运行期表示吗 | 有（值最终要进二进制） | **没有**（只是编译期求值的一个临时格子） |
| 出现在哪 | 任何地方 | **只能**出现在函数体、comptime 块、 comptime 参数的函数体里 |
| 顶层（容器级）能用吗 | ✅ | ❌ 编译错 |

第 4 行 `运行期值也能被 const 装 = 10946` 就是证据：`fibonacci(n)` 里 `n` 是运行期的，所以这个 `const` 装的是**运行期算出来的值**。而 `comptime var` 从头到尾就没进过二进制——它只是编译器在求值过程中用的一个格子，算完就扔。

⚠️ **容器级（文件顶层）不能声明 `comptime var`**，实测报错：

```text
error: expected type expression, found 'var'
    comptime var cv: u32 = 0;
             ^~~
```

因为容器级**本身就是编译期作用域**，压根不需要这个关键词（详见 13.4 节）。

## 13.2 comptime 参数：把编译期常量写进签名

参数表里标 `comptime` = **该参数必须在编译期已知**。传运行期值直接编译错——这不是限制是契约：它保证函数体可以把这个值当数组长度、当类型、当查表键。泛型与反射全靠它（14 章）。

```zig
// examples/13_comptime/main.zig 第 23-37 行
/// 13.2 节：comptime 参数 —— 参数本身必须在编译期已知。
fn pow(comptime base: u64, comptime exp: u32) u64 {
    comptime var acc: u64 = 1;
    comptime var i: u32 = 0;
    inline while (i < exp) : (i += 1) acc *%= base;
    return acc;
}

/// 13.2 节：普通参数版——同一个算法，运行期输入也能调（两栖）。
fn powRuntime(base: u64, exp: u8) u64 {
    var acc: u64 = 1;
    var i: u8 = 0;
    while (i < exp) : (i += 1) acc *%= base;
    return acc;
}
```

`pow` 内部**没有一行运行期代码**：`acc` 和 `i` 都是 `comptime var`，循环是 `inline while`，返回值 `u64` 是实参类型定的。所以 `pow(2, 10)` 这个表达式本身就是常量 1024，类型是 `u64` 而**不是** `comptime_int`。

⚠️ 传运行期值编译错，**完整实测报错**：

```text
main.zig:7:22: error: unable to resolve comptime value
    const v = pow(2, n);
                     ^
main.zig:7:22: note: argument to comptime parameter must be comptime-known
main.zig:11:28: note: parameter declared comptime here
fn pow(comptime base: u64, comptime exp: u8) u64 {
                           ^~~~~~~~
```

两个 note 把"哪一行传错了"和"哪个参数是 comptime 的"一起指出来——错误信息相当可读。

```zig
// examples/13_comptime/main.zig 第 183-197 行（begin("13.2") 到 end("13.2")）
    // ═══ 13.2 comptime 参数：参数本身必须编译期已知 ═══
    begin("13.2");
    std.debug.print("pow(2,10) 编译期 = {d}\n", .{pow(2, 10)});
    std.debug.print("pow(3,5) 编译期 = {d}\n", .{pow(3, 5)});
    std.debug.print("pow(2,10) 类型 = {s}\n", .{@typeName(@TypeOf(pow(2, 10)))});
    // ⚠️ 传运行期值编译错：unable to resolve comptime value
    //      note: argument to comptime parameter must be comptime-known
    //   var e: u8 = 3; e += 1;
    //   const v = pow(2, e);          ← 编译错，报错见正文
    //
    // 要两栖就把参数改成普通参数——同一个算法，两种写法：
    var e: u8 = 3;
    e += 1;
    std.debug.print("运行期 pow(2,{d}) = {d}（普通参数版，两栖）\n", .{ e, powRuntime(2, e) });
    end("13.2");
```

运行输出（`examples/13_comptime/main.zig`）：

```text
==== 13.2 开始 ====
pow(2,10) 编译期 = 1024
pow(3,5) 编译期 = 243
pow(2,10) 类型 = u64
运行期 pow(2,4) = 16（普通参数版，两栖）
==== 13.2 结束 ====
```

**怎么选**：如果指数是编译期固定的（比如 `kib = 1024`），用 `comptime` 参数——零运行期开销。如果指数来自命令行/配置，去掉 `comptime` 关键字。同一算法的两份代码放在一起对照，是本章最实用的 takeaway。

## 13.3 `comptime` 块与容器级 `const`：两种"块"

带标签的块表达式 `blk: { ... break :blk 值; }` 是 Zig 里"把一段语句当表达式用"的通用手段（Rust 的 `loop {}` / Go 的裸 `return` 同类）。配合 `comptime` 就得到"编译期算出一段结果"。

```zig
// examples/13_comptime/main.zig 第 199-224 行（begin("13.3") 到 end("13.3")）
    // ═══ 13.3 comptime 块与容器级 const：两种"块"的写法 ═══
    begin("13.3");
    // 带标签的块表达式：blk: { ... break :blk 值; }
    const square_table = blk: {
        var buf: [8]u16 = undefined;
        for (0..8) |i| buf[i] = @intCast(i * i);
        break :blk buf;
    };
    std.debug.print("square_table = {any}\n", .{square_table});
    // 容器级 const 本身就在编译期求值，所以那里写 comptime 是多余的：
    //   const x = comptime blk: {...};  → error: redundant comptime keyword in
    //                                        already comptime scope
    // 而函数体内必须显式写 comptime 才行：
    const func_local = comptime blk: {
        var acc: usize = 0;
        for (0..8) |k| acc += k;
        break :blk acc;
    };
    std.debug.print("func_local = {d}（函数体里加了 comptime 才被强制求值）\n", .{func_local});
    // comptime 块在函数体里也可以不写 labeled block，直接给const：
    const another = comptime r: {
        const a = 1 + 1;
        break :r a * 20;
    };
    std.debug.print("another = {d}\n", .{another});
    end("13.3");
```

运行输出（`examples/13_comptime/main.zig`）：

```text
==== 13.3 开始 ====
square_table = { 0, 1, 4, 9, 16, 25, 36, 49 }
func_local = 28（函数体里加了 comptime 才被强制求值）
another = 40
==== 13.3 结束 ====
```

注意三处 `const` 都写在**函数体内**，但只有后两处加了 `comptime`。第一处 `square_table` 没加——它能编译是因为它的初始化恰好全是编译期可算的（`for (0..8)` 的上界是字面量）。加上 `comptime` 就会报错：

```text
error: redundant comptime keyword in already comptime scope
const x = comptime blk: { ... };
          ^~~~~~~~
```

⚠️ 这条报错只在**容器级**（文件顶层、struct 字段默认值）出现。函数体里 `comptime` 是**必需**的——`const func_local = blk: {...}` 里的 `var acc` 是运行期变量，`break :blk acc` 会试图把运行期的 `acc` 初始化给 `const`，直接编译失败。**判断标准：容器级天然 comptime，函数体要显式声明。**

### `comptime { }` 独立块：编译期断言的容器

```zig
// examples/13_comptime/main.zig 第 147-160 行
comptime {
    // 13.3 节：编译期断言 —— @compileError / @setEvalBranchQuota 的用法
    if (fibonacci(10) != 55) @compileError("fibonacci 算错了");
    if (pow(2, 10) != 1024) @compileError("pow 算错了");
    // 13.7 节：inline fn 在编译期也能调
    if (twice(21) != 42) @compileError("twice 算错了");
    // 13.10 节：编译期断言一条结构体布局假设
    if (@sizeOf(Header) != 8) @compileError("Header 的sizeOf 变了，需要复核内存布局");
    if (@offsetOf(Header, "len") != 4) @compileError("Header.len 的偏移变了");
    // 13.8 节：反射结果本身在编译期就能断言
    if (@typeInfo(Header).@"struct".field_names.len != 3) @compileError("Header 字段数变了");
    if (!std.mem.eql(u8, kindName(u8), "整数")) @compileError("kindName 分派坏了");
    if (!std.mem.eql(u8, @tagName(Stage.beta), "beta")) @compileError("@tagName 用法错了");
}
```

`@compileError` 让错误**发生在构建期**。数学常数、协议字段偏移、结构体布局假设，都值得一条断言护航（对照 C++20 的 `static_assert`，Zig 版能带任意条件逻辑）。断言失败时的报错实测是：

```text
main.zig:11:22: error: fibonacci 算错了
    if (fib10 != 56) @compileError("fibonacci 算错了");
                     ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

⚠️ **注意断言本身也可能撞配额**。这七条断言里 `fibonacci(10)` 要递归两千多次调用，全在 1000 分支配额内（因为函数调用不算backwards branch）；但如果你在 `comptime` 块里写 `fibonacci(30)`，就会得到（实测）：

```text
main.zig:6:30: error: evaluation exceeded 1000 backwards branches
    return cfib(n - 1) + cfib(n - 2);
                         ~~~~^~~~~~~
main.zig:6:30: note: use @setEvalBranchQuota() to raise the branch limit from 1000
main.zig:6:16: note: called at comptime here (20 times)
```

**`@compileLog` 是编译期的 `printf`**，但它的行为和 `print` 完全不同：它**把编译搞失败**，同时把值打到编译输出里。实测：

```text
main.zig:4:5: error: found compile log statement
    @compileLog("编译日志：这条只在编译输出里出现");
    ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
...
Compile Log Output:
@as(*const [48:0]u8, "编译日志：这条只在编译输出里出现")
```

诊断完记得删掉。

## 13.4 `comptime var`：编译期的"可变"绑定

**这是本章的核心坑**。改 `comptime var` 的循环**必须是 `inline while`**，普通 `while` 不行：

```zig
// examples/13_comptime/main.zig 第 226-255 行（begin("13.4") 到 end("13.4")）
    // ═══ 13.4 comptime 变量：编译期的"可变"绑定 ═══
    begin("13.4");
    // ⚠️ 核心坑：改 comptime 变量的循环**必须是 inline while**。
    // 普通 while 会报：error: cannot store to comptime variable in non-inline loop
    comptime var acc: u32 = 0;
    comptime var i: u32 = 0;
    inline while (i < 1000) : (i += 1) acc +%= i;
    std.debug.print("inline while 0..999 求和 = {d}（i 最终 = {d}）\n", .{ acc, i });
    // 为什么必须 inline：inline 循环在编译期**完全展开**，每轮的i 都有确定值，
    // 所以编译器知道写进 acc 的是编译期常量；普通 while 的迭代次数运行期才知道，
    // 编译器无法确认这次赋值安全。
    //
    // 同理，普通 for 里改 comptime 变量报的是另一个错（即使赋的是常量 0）：
    //   error: store to comptime variable depends on runtime condition
    //     note: runtime condition here
    //
    // ⚠️ 而在**容器级**（顶层 const 初始化）这些关键字全是多余的：
    //   const x = comptime blk: {...}   → error: redundant comptime keyword in
    //                                       already comptime scope
    //   comptime var acc: u32 = 0;      → error: 'comptime var' is redundant in
    //                                       comptime scope
    //   inline while (...) ...          → error: redundant inline keyword in
    //                                       comptime scope
    // 容器级已经是编译期作用域，直接写 var + while 即可（见 Primes 的写法）。
    //
    // comptime var 可以取地址（读），那个地址只在编译期有意义：
    comptime var boxed: u32 = 7;
    const addr = &boxed;
    std.debug.print("comptime var 取地址读回来= {d}\n", .{addr.*});
    end("13.4");
```

运行输出（`examples/13_comptime/main.zig`）：

```text
==== 13.4 开始 ====
inline while 0..999 求和 = 499500（i 最终 = 1000）
comptime var 取地址读回来= 7
==== 13.4 结束 ====
```

### 为什么必须 `inline`——两个不同的报错

把上面的 `inline while` 改成 `while`，实测得到：

```text
main.zig:6:34: error: cannot store to comptime variable in non-inline loop
    while (i < 5) : (i += 1) acc += i;
                             ~~~~^~~~
main.zig:6:5: note: non-inline loop here
    while (i < 5) : (i += 1) acc += i;
    ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

改成 `for`（即使循环体里赋的是常量 `0`），报的是**另一个**错：

```text
main.zig:22:23: error: store to comptime variable depends on runtime condition
    for (0..3) |_| ro += 0; // 只读不改
                   ~~~^~~~
main.zig:22:10: note: runtime condition here
    for (0..3) |_| ro += 0;
         ^~~~
```

**两条报错说的是同一件事**：编译器要在编译期把某个值写进 `comptime var`，必须先能证明"这次写入会发生，而且写入的值是编译期已知的"。`inline` 循环在编译期**完全展开**——3 次迭代就是 3 段独立的代码，每段的条件和赋值都直接摊在源码里，编译器不需要推理。而普通循环的迭代次数只有运行期才知道（哪怕实参是 `for (0..3)` 这种看着编译期已知的序列，编译器也不做这个假设），所以它无法确认这次写入合法。

这个设计的收益是**它不可能出错**。凡是能写成 `inline while` 的代码，赋值都必然发生在编译期；写不成就在编译期报错。没有"运行时悄悄写坏一个编译期常量"这种可能。

### `comptime var` 能在哪写

`inline while` 这套要求只出现在**函数体**里。在容器级（顶层 `const` 的初始化块），`comptime` / `inline` / `comptime var` **三个关键字全是多余的**，实测各报一条：

```text
error: redundant comptime keyword in already comptime scope
error: 'comptime var' is redundant in comptime scope
error: redundant inline keyword in comptime scope
```

所以容器的`blk` 块写成这样（对比 13.3 节）：

```zig
// examples/13_comptime/main.zig 第 96-114 行
/// 13.10 节：编译期筛出的素数表（埃氏筛，0..255 全覆盖）。
/// 这是"编译期算、运行期只查表"最典型的例子：约 3 万次编译期迭代，
/// 换来运行期每次判定只需一次数组索引。
/// ⚠️ 容器级已经是编译期作用域，所以这里**不需要** comptime / inline 关键字
///（写了会报 redundant comptime / redundant inline）。
const PrimeFlags = blk: {
    @setEvalBranchQuota(10_000_000); // 见 13.6 节：默认 1000 远远不够
    var flags: [256]bool = @splat(true); // ⚠️ 0.17 没有 [_]T{x} ** n 重复填充（见 13.11 节）
    flags[0] = false;
    flags[1] = false;
    var n: u16 = 2;
    while (n * n < 256) : (n += 1) {
        if (flags[n]) {
            var m: u16 = n * n;
            while (m < 256) : (m += n) flags[m] = false;
        }
    }
    break :blk flags;
};
```

普通 `var` + 普通 `while`，没有 `inline`——因为容器级本来就是编译期作用域，编译器逐条执行它。**两条规则的适用边界划得很清：容器级写普通代码，函数体里写 `comptime var` + `inline while/for`。**

`comptime var` 还能取地址读（输出第 2 行 `7`），但那个地址只在编译期有意义——它指向编译器求值用的临时格子，不是最终二进制里的某个位置。

## 13.5 `comptime` 参数 vs 泛型：两个都是"编译期输入"

这两个概念在很多书里被讲成两件事，但在 Zig 里是**同一个机制的两种写法**。

```zig
// examples/13_comptime/main.zig 第 45-61 行
/// 13.5 节：13.5 节的struct 样本——编译期造一份、运行期造一份，类型完全相同。
const Conf = struct {
    name: []const u8,
    count: u32,
};

/// 13.5 节：comptime 参数把两个编译期字面量塞进一个 struct。
fn makeConf(comptime name: []const u8, comptime count: u32) Conf {
    return .{ .name = name, .count = count };
}

/// 13.5 节：泛型 —— 没有显式 comptime 参数表，类型从实参推导。
fn genericSum(values: anytype) @TypeOf(values[0]) {
    comptime var acc: @TypeOf(values[0]) = 0;
    for (values) |v| acc +|= v;
    return acc;
}
```

```zig
// examples/13_comptime/main.zig 第 257-272 行（begin("13.5") 到 end("13.5")）
    // ═══ 13.5 comptime 参数 vs 泛型：两个都是"编译期输入" ═══
    begin("13.5");
    //显式版：comptime T: type + comptime values
    std.debug.print("genericSum(u8切片) = {d}\n", .{genericSum(&.{ 1, 2, 3, 4 })});
    std.debug.print("genericSum(u64 切片) = {d}\n", .{genericSum(&.{ 10, 20, 30 })});
    // 显式 comptime 参数版：makeConf("alpha", 3) 的两个实参都在编译期
    const c1 = makeConf("alpha", 3);
    std.debug.print("makeConf(\"alpha\",3) = {s} {d}\n", .{ c1.name, c1.count });
    // 同一个 Conf 类型，运行期手写一份（证明类型完全一样）
    var rt: u32 = 1;
    rt += 2;
    const c2: Conf = .{ .name = "beta", .count = rt };
    std.debug.print("运行期手写Conf= {s} {d}\n", .{ c2.name, c2.count });
    // comptime 参数不只接收类型，也能接收普通编译期值（这里两个都是字面量）
    std.debug.print("两处 count 都是编译期常量：{d} 与 {d}，加起来 = {d}\n", .{ c1.count, c2.count, c1.count + c2.count });
    end("13.5");
```

运行输出（`examples/13_comptime/main.zig`）：

```text
==== 13.5 开始 ====
genericSum(u8切片) = 10
genericSum(u64 切片) = 60
makeConf("alpha",3) = alpha 3
运行期手写Conf= beta 3
两处 count 都是编译期常量：3 与 3，加起来 = 6
==== 13.5 结束 ====
```

| | 显式 `comptime` 参数 | 泛型（`anytype`） |
|---|---|---|
| 写法 | `fn f(comptime T: type, comptime n: u32)` | `fn f(a: anytype)` |
| 输入怎么来 | 你在签名里点名 | 从实参**推导**（`@TypeOf(values[0])`） |
| 能拿到几个值 | 任意多个，每个都能单独声明 | 只能拿到"实参类型"这一个整体 |
| 适合 | 多个编译期标量（尺寸、模式、阈值） | 一个值的类型决定一切（容器、转换） |

**`anytype` 是"隐式 comptime 参数"**：它等价于 `comptime T: anytype`，编译器从调用点推导。`genericSum(&.{1,2,3,4})` 的实参类型是 `*const [4]u8`，`@TypeOf(values[0])` 就是 `u8`；换成 `&.{10,20,30}` 就变成 `u64`。输出第 1、2 行就是这个机制在起作用——**同一份函数体，两个不同类型，零运行期开销**。

⚠️ 别把 `anytype` 当 `[]const u8` 用。`anytype` 是**编译期**的类型占位符，函数体会为每个实参类型单独实例化一次；如果实参是运行期才确定的类型（比如 `var x: u32 = ...` 的 `x`），推导出的就是运行期类型，函数体不再有 comptime 保证。

## 13.6 `@setEvalBranchQuota`：编译期循环配额

**默认值就是 1000。** 超过就编译失败。这条机制的目的是防止一个手滑的无限循环把编译器卡死——你必须**显式申请**才能算更多。

```zig
// examples/13_comptime/main.zig 第 162-165 行（pub fn main 开头）
pub fn main() !void {
    // 本函数里所有编译期求值共享同一份分支配额，13.4/13.6 节的循环会消耗它。
    // 默认 1000 本来够用，但 13.6 节要显式演示抬高配额的效果，所以先抬高。
    @setEvalBranchQuota(2_000_000);
```

```zig
// examples/13_comptime/main.zig 第 274-297 行（begin("13.6") 到 end("13.6")）
    // ═══ 13.6 @setEvalBranchQuota：编译期循环配额 ═══
    begin("13.6");
    // 默认配额是 **1000 个"向后跳转"**（backwards branches），且**按作用域累计**：
    // 不是每个循环各给1000，而是同一个作用域里所有编译期循环共用这1000。
    //
    // 实测边界：容器级一个普通 while 跑 1000 次不爆；函数体内两个 600 次的
    // inline while 连着写就爆（600+600=1200 > 1000），报错是：
    //   error: evaluation exceeded 1000 backwards branches
    //   note: use @setEvalBranchQuota() to raise the branch limit from 1000
    //
    // 本函数开头已经抬高到 2_000_000，所以这里可以放心跑 10 万次：
    comptime var big_sum: u64 = 0;
    comptime var k: u32 = 0;
    inline while (k < 100_000) : (k += 1) big_sum +%= k;
    std.debug.print("抬高配额后 inline while 0..99999 求和 = {d}\n", .{big_sum});
    // 想验证"默认配额就是 1000"：在**没有**@setEvalBranchQuota 的作用域里跑
    // 2000 次 inline while，会编译失败（正文贴了完整报错）。
    //
    // ⚠️ 实测：@setEvalBranchQuota **可以往小调**，不报错——在同一作用域里先写
    //   100_000 再写 100，编译照样通过。所以它不是"护栏"，只是"预算申请"。
    //
    // 代价：编译期算 10 万次 inline 迭代把编译时间从约 0.3 s 拉到约 4 s。
    // 这就是 comptime 的账单（见 13.12 节）。
    end("13.6");
```

运行输出（`examples/13_comptime/main.zig`）：

```text
==== 13.6 开始 ====
抬高配额后 inline while 0..99999 求和 = 4999950000
==== 13.6 结束 ====
```

### 爆掉时的真实报错（实测逐字）

在**没有** `@setEvalBranchQuota` 的作用域里跑 2000 次 `inline while`：

```text
main.zig:5:12: error: evaluation exceeded 1000 backwards branches
    inline while (i < 2000) : (i += 1) acc +%= i;
    ~~~~~~~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
main.zig:5:12: note: use @setEvalBranchQuota() to raise the branch limit from 1000
referenced by:
    callMain [inlined]: /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/start.zig:788:64
    callMainWithArgs [inlined]: /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/start.zig:729:20
    main: /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/start.zig:754:28
```

**"backwards branches"（向后跳转）**是循环的回边计数。一次迭代 = 一次向后跳转。所以配额不是"迭代次数"而是"回边数"——递归也算（每层函数的返回是一次回边），`if`/`switch` 的分支不算。

### 配额是按作用域累计的

这是实测里最容易被误判的一点。**不是"每个循环各给 1000"，而是同一个作用域里所有编译期循环共用这1000。** 实测（独立探针，不在示例文件里）：

```zig
// 探针：main 里连着两个 600 次的 inline while
pub fn main() !void {
    comptime var acc: u32 = 0;
    comptime var i: u32 = 0;
    inline while (i < 600) : (i += 1) acc +%= i;   // 600，OK
    comptime var acc2: u32 = 0;
    comptime var j: u32 = 0;
    inline while (j < 600) : (j += 1) acc2 +%= j;  // 600 + 600 = 1200 > 1000，爆
}
```

→ `error: evaluation exceeded 1000 backwards branches`。所以调配额要**一次调够**，不能指望"这个循环超了下一个还有余量"。

⚠️ **实测：`@setEvalBranchQuota` 可以往小调，不报错。** 在同一作用域里先写 `100_000` 再写 `100`，编译照样通过（`attempt to reduce branch quota` 这条老报错在 0.17 已经没有了）。所以它**不是护栏，只是预算申请**——它挡不住你写出慢编译的代码，只能让你在撞墙时知道往哪调。

## 13.7 `inline fn`：强制内联，描述"函数体怎么处理"

⚠️ **实测结论和多数教程写的不同：`inline fn` 在运行期也能调。**

```zig
// examples/13_comptime/main.zig 第 63-66 行
/// 13.7 节：inline fn（强制内联），运行期也能调。
inline fn twice(x: u32) u32 {
    return x * 2;
}
```

```zig
// examples/13_comptime/main.zig 第 299-316 行（begin("13.7") 到 end("13.7")）
    // ═══ 13.7 inline fn：强制内联，描述"函数体怎么处理" ═══
    begin("13.7");
    // ⚠️ inline fn 在**运行期也能调**（实测见正文）—— inline 说的是
    //    "函数体如何处理"（强制在调用点展开），不是"只在编译期调用"。
    std.debug.print("twice(21) 编译期 = {d}\n", .{twice(21)});
    const rt_in: u32 = 21;
    std.debug.print("twice(运行期 21) = {d}\n", .{twice(rt_in)});
    // @inComptime() 在普通函数里是 false。注意函数体里有 comptime 参数**也不改变**这一点——
    // comptime 参数只保证"实参在编译期已知"，不等于"函数体在编译期执行"。
    // ⚠️ 0.17 里它必须写成**无参** @inComptime()：写 @inComptime(x) 报
    //   error: expected 0 arguments, found 1
    // 而在 comptime 块里写 @inComptime() 反而报
    //   error: redundant '@inComptime' in comptime scope
    std.debug.print("inComptime：普通函数 = {}；带 comptime 参数的函数 = {}\n", .{
        probeInComptime(1),
        probeGenericInComptime(u8),
    });
    end("13.7");
```

运行输出（`examples/13_comptime/main.zig`）：

```text
==== 13.7 开始 ====
twice(21) 编译期 = 42
twice(运行期 21) = 42
inComptime：普通函数 = false；带 comptime 参数的函数 = false
==== 13.7 结束 ====
```

第 2 行 `twice(运行期 21) = 42` 里，`rt_in` 是 `const`（值编译期已知），但函数被调用的位置是运行期语句——**`inline` 描述的是"函数体如何处理"（强制在调用点展开，不走 call 指令），不是"调用时机"。** 要强制"只在编译期调用"，得用 `comptime fn` 之外的手段：把它放进 `comptime` 块或 `const` 初始化里。

### `@inComptime()` 在 0.17 必须无参

这是本章又一处版本敏感点。0.17 里它是**零参数**内建：

```text
error: expected 0 arguments, found 1
    return @inComptime(x);
           ^~~~~~~~~~~~~~
```

正确写法 `return @inComptime();`。而**在 `comptime` 块里写它反而报错**：

```text
error: redundant '@inComptime' in comptime scope
```

输出后两行还说明另一件事：**函数里有 `comptime` 参数 ≠ 函数体在编译期执行**。`probeGenericInComptime` 声明为 `inline fn`且带 `comptime T: type`，`@inComptime()` 依然返回 `false`——因为这个函数是在运行期被调用的。`comptime` 参数只约束**实参**，不承诺**函数体的求值时机**。

## 13.8 `type` 是一等值

`type` 是 Zig 里的一个**编译期值的类型**。说"类型是编译期值"的意思是：你可以把类型本身当数据传递、存储、比较。

```zig
// examples/13_comptime/main.zig 第 68-94 行
/// 13.8 节要反射的结构体。
const Header = struct {
    magic: u32,
    len: u16 = 0,
    ok: bool,
};

/// 13.8 节：造函数类型用 @TypeOf —— ⚠️ 0.17 不许在函数体里声明 fn，必须放容器级。
fn addThenNarrow(a: u32, b: u32) u8 {
    return @intCast(a + b);
}

/// 13.8 节：13.8 的枚举样本，@tagName 只能作用于它的**值**。
const Stage = enum { alpha, beta, gamma };

/// 13.8 节：按类型分派 —— 证明 comptime 反射能写普通代码。
fn kindName(comptime T: type) []const u8 {
    return switch (@typeInfo(T)) {
        .int => "整数",
        .float => "浮点",
        .@"struct" => "结构体",
        .@"enum" => "枚举",
        .array => "数组",
        .pointer => "指针",
        else => "其它",
    };
}
```

```zig
// examples/13_comptime/main.zig 第 318-340 行（begin("13.8") 到 end("13.8")）
    // ═══ 13.8 类型作为编译期数据：type 是一等值 ═══
    begin("13.8");
    // type 是编译期值：能当参数传给 comptime T: type
    std.debug.print("kindName(u8)={s} kindName(Header)={s}\n", .{ kindName(u8), kindName(Header) });
    // 能装进容器 —— 但遍历必须 inline for（元素是 type，运行期不存在）：
    const types = [_]type{ u8, u16, u32, u64 };
    comptime var total: usize = 0;
    inline for (types) |T| total += @sizeOf(T);
    std.debug.print("[_]type{{u8,u16,u32,u64}} 的 @sizeOf 之和 = {d}\n", .{total});
    // ⚠️ @Type 在 0.17 已被移除（error: invalid builtin function: '@Type'），
    // 所以"从 @typeInfo 的结果反向造类型"这条老路走不通了。
    // 造函数类型用 @TypeOf（见容器级的 addThenNarrow）：
    // 注意 @TypeOf(&f) 拿到的是**指针**类型，要函数类型本身得去掉 &。
    const FnPtr = @TypeOf(&addThenNarrow);
    const Fn = @typeInfo(FnPtr).pointer.child;
    std.debug.print("@TypeOf(&addThenNarrow) = {s}；剥掉指针 = {s}\n", .{ @typeName(FnPtr), @typeName(Fn) });
    // ⚠️ 0.17 不许在函数体里声明 fn（实测报expected ',' after initializer），
    // 所以上面的 addThenNarrow 必须放在容器级。
    // ⚠️ 反射类型名一律 @typeName。@tagName 只能作用于枚举/联合的**值**：
    //   @tagName(Header) → error: expected enum or union; found 'type'
    std.debug.print("typeName(Header) = {s}；typeName(u24) = {s}\n", .{ @typeName(Header), @typeName(u24) });
    std.debug.print("tagName(Stage.beta) = {s}（@tagName 只能吃枚举/联合的值）\n", .{@tagName(Stage.beta)});
    end("13.8");
```

运行输出（`examples/13_comptime/main.zig`）：

```text
==== 13.8 开始 ====
kindName(u8)=整数 kindName(Header)=结构体
[_]type{u8,u16,u32,u64} 的 @sizeOf 之和 = 15
@TypeOf(&addThenNarrow) = *const fn (u32, u32) u8；剥掉指针 = fn (u32, u32) u8
typeName(Header) = main.Header；typeName(u24) = u24
tagName(Stage.beta) = beta（@tagName 只能吃枚举/联合的值）
==== 13.8 结束 ====
```

三件事：

**① `type` 能装进数组**（输出第 2 行 `15` = 1+2+4+8）。但**遍历必须 `inline for`**——普通 `for` 遍历 `[_]type` 编译失败：

```text
main.zig:302:10: error: values of type 'type' must be comptime-known, but index value is runtime-known
    for (types) |T| total += @sizeOf(T);
         ~~~~~^~~~~~~~~
main.zig:302:10: note: types are not available at runtime
```

**② ⚠️ `@Type` 在 0.17 已被移除。** 这是一个**新踩到的坑**，不在老教程的坑位清单里：

```text
error: invalid builtin function: '@Type'
const T = @Type(.{ .int = .{ .signedness = .unsigned, .bits = 24 } });
              ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

老教程里"用 `@Type` 从 `@typeInfo` 的结果反向构造类型"这条路的入口没了。替代方案：

- 造函数类型 → `@TypeOf(f)`（输出第 3 行）。注意 `@TypeOf(&f)` 拿到的是**指针**类型 `*const fn (u32, u32) u8`，要函数类型本身得 `@typeInfo(ptr).pointer.child`剥掉。
- 造结构体/数组等 → 直接写声明。0.17 的 `type { ... }` 也走不通（实测 `error: type 'type' does not support struct initialization syntax`）。

**③ ⚠️ 反射类型名一律 `@typeName`，`@tagName` 不行**：

```text
error: expected enum or union; found 'type'
    const x = @tagName(E);
                       ^
```

`@tagName` 的语义是"取枚举/联合**那个值**的标签名"，不是"取类型的名字"。想打印类型名用 `@typeName`（输出第 4 行 `main.Header`）。这是个高频混淆点：**`@typeName(T)` 吃类型，`@tagName(v)` 吃值。**

⚠️ 顺带一条和 14 章有关的：**0.17 不许在函数体里声明 `fn`**。实测 `fn inner(a: u32) u32 { ... }` 写在 `main` 里报 `error: expected ',' after initializer`（报错很莫名其妙，实际是解析器把 `fn` 当成了别的东西）。所以 `addThenNarrow` 必须放容器级。

## 13.9 `inline for` / `inline while`：编译期展开循环

`inline for` 在编译期把循环体**展开 N 份**（N = 序列长度），每一份里的捕获值都是编译期常量。

```zig
// examples/13_comptime/main.zig 第 342-386 行（begin("13.9") 到 end("13.9")）
    // ═══ 13.9 inline for / inline while：编译期展开循环 ═══
    begin("13.9");
    // inline for 在编译期把循环体展开 N 份（N = 序列长度）
    const names = [_][]const u8{ "alpha", "beta", "gamma" };
    inline for (names) |name| {
        std.debug.print("  inline for 展开：{s}\n", .{name});
    }
    // ⚠️ 0.17 **支持索引捕获**（旧教程说"不支持"已过时）：多写一个 `0..`
    comptime var idx_sum: usize = 0;
    comptime var joined: []const u8 = "";
    inline for (names, 0..) |name, idx| {
        idx_sum += idx;
        joined = joined ++ name ++ ";"; // ++ 拼接仍可用
    }
    std.debug.print("索引之和 = {d}；拼起来 = {s}\n", .{ idx_sum, joined });
    // 但 field_types（元素是 type）**必须** inline for，普通 for 编译失败：
    //   error: values of type 'type' must be comptime-known,
    //          but index value is runtime-known
    //   note: types are not available at runtime
    // 理由：类型是编译期实体，运行期根本没有"类型"这个值。
    const hi = @typeInfo(Header);
    std.debug.print("Header layout={t} 字段数={d}\n", .{ hi.@"struct".layout, hi.@"struct".field_names.len });
    // ⚠️ 三条平行数组（0.17 没有 .fields了）：field_names / field_types / field_attrs
    inline for (hi.@"struct".field_names, hi.@"struct".field_types, hi.@"struct".field_attrs) |fname, ftype, attrs| {
        // field_names 的元素是 [:0]const u8（哨兵切片），打印要写 fname[0..fname.len]
        std.debug.print("  字段 {s}: {s} 显式对齐={any} 有默认值={}\n", .{
            fname[0..fname.len],
            @typeName(ftype),
            attrs.@"align", // ⚠️ 0.17 里是 .@"align"（?usize），不是 .alignment
            attrs.default_value_ptr != null,
        });
    }
    std.debug.print("@offsetOf(Header, \"len\") = {d}\n", .{@offsetOf(Header, "len")});
    // error_names 是**可空**的 ?[]const [:0]const u8，得先 if (x) |y|
    const StoreError = error{ NotFound, Corrupted };
    if (@typeInfo(StoreError).error_set.error_names) |enames| {
        for (enames) |ename| std.debug.print("  错误名{s}\n", .{ename[0..ename.len]});
    }
    // ⚠️ @hasDecl 的第二个参数在 0.17 **必须给字符串**：
    //   @hasDecl(std.mem, copyForwards) → error: use of undeclared identifier
    std.debug.print("@hasDecl(std.mem, \"copyForwards\")={}；不存在的名字={}\n", .{
        @hasDecl(std.mem, "copyForwards"),
        @hasDecl(std.mem, "noSuchThingAtAll"),
    });
    end("13.9");
```

运行输出（`examples/13_comptime/main.zig`）：

```text
==== 13.9 开始 ====
  inline for 展开：alpha
  inline for 展开：beta
  inline for 展开：gamma
索引之和 = 3；拼起来 = alpha;beta;gamma;
Header layout=auto 字段数=3
  字段 magic: u32 显式对齐=null 有默认值=false
  字段 len: u16 显式对齐=null 有默认值=true
  字段 ok: bool 显式对齐=null 有默认值=false
@offsetOf(Header, "len") = 4
  错误名NotFound
  错误名Corrupted
@hasDecl(std.mem, "copyForwards")=true；不存在的名字=false
==== 13.9 结束 ====
```

### ⚠️ 0.17 支持索引捕获（旧教程说"不支持"已过时）

老教程普遍写"`inline for` 没有索引捕获，`inline for (xs) |x, i|` 编译错"。**0.17 里支持了**：多写一个 `0..` 序列作为第二段。

```zig
// examples/13_comptime/main.zig 第 352-355 行（inline for 的索引捕获写法）
    inline for (names, 0..) |name, idx| {
        idx_sum += idx;
        joined = joined ++ name ++ ";"; // ++ 拼接仍可用
    }
```

输出第 5 行 `索引之和 = 3`（0+1+2）就是证据。要自己维护 `comptime var` 计数的旧写法不再必要。

### `@typeInfo` 的 0.17 三条平行数组

⚠️ **`@typeInfo(T).@"struct".fields` 在 0.17 不存在了**。取而代之是三条**长度相同、按下标对应**的平行数组：

| 数组 | 元素类型 | 用途 |
|---|---|---|
| `.field_names` | `[]const [:0]const u8` | 字段名（**哨兵切片**） |
| `.field_types` | `[]const type` | 字段类型 |
| `.field_attrs` | `[]const FieldAttributes` | `@"comptime"` / `@"align"` / `default_value_ptr` |

⚠️ **`.tag` 已改名 `.layout`**（取值 `.auto` / `.@"extern"` / `.@"packed"`，类型是 `std.lang.ContainerLayout`）。

⚠️ **`field_attrs` 的对齐字段叫 `.@"align"`（`?usize`），不是 `.alignment`**。写 `.alignment` 报：

```text
error: no field named 'alignment' in struct 'lang.Type.Struct.FieldAttributes'
```

这解释了输出里三行 `显式对齐=null`：`Header` 的字段都没写 `align`，所以是"未显式指定"（字段仍然会按类型自然对齐）。

### 三条平行数组只能用 `inline for`

**这是 0.17 最容易踩的反射坑**。`field_types` 的元素是 `type`，`field_values`（枚举）的元素是 `comptime_int`——**两者都是编译期实体**，普通 `for` 一律失败：

```text
error: values of type 'type' must be comptime-known, but index value is runtime-known
    for (info.@"struct".field_types) |ft| {
         ~~~~~~~~~~~~~~^~~~~~~~~~~~
note: types are not available at runtime
```

道理很直白：**运行期根本没有"类型"这个值**。你在运行期循环里想拿到第 N 个字段的类型，但"类型"这个概念在运行期不存在。`inline for` 在编译期把循环展开，每次迭代的 `ftype` 都是编译期已知的。

⚠️ 同一个数组在**测试里可以直接下标**（编译期求值），但在 `main` 里用普通 `for` 遍历就编译失败。同一种数据，访问方式不同。

⚠️ `error_names` 是**可空的** `?[]const [:0]const u8`，得先 `if (x) |y|` 或 `.?`；元素是哨兵切片，打印要写 `ename[0..ename.len]`（写 `ename[0..8 :0]` 会报 `value in memory does not match slice sentinel`）。

### ⚠️ `@hasDecl` 的第二个参数必须给字符串

0.17 里 `@hasDecl(T, ident)` 的**标识符形式失效了**：

```text
error: use of undeclared identifier 'copyForwards'
    if (@hasDecl(std.mem, copyForwards)) std.debug.print("has\n", .{});
                          ^~~~~~~~~~~~
```

正确写法是给字符串：`@hasDecl(std.mem, "copyForwards")`（输出第 11 行 `true`）。这个报错特别有迷惑性——它看起来像"这个 decl 不存在"，但真正的问题是**参数形式不对**：编译器把 `copyForwards` 当成一个普通标识符去解析，于是报"未声明"。看到这条报错要先怀疑写法，而不是库。

## 13.10 编译期数据结构：构造查表

编译期最实用的用途是**造数据表**：把一段"结果只取决于常量"的计算搬到编译期，运行期只剩一次数组索引。

```zig
// examples/13_comptime/main.zig 第 96-128 行
/// 13.10 节：编译期筛出的素数表（埃氏筛，0..255 全覆盖）。
/// 这是"编译期算、运行期只查表"最典型的例子：约 3 万次编译期迭代，
/// 换来运行期每次判定只需一次数组索引。
/// ⚠️ 容器级已经是编译期作用域，所以这里**不需要** comptime / inline 关键字
///（写了会报 redundant comptime / redundant inline）。
const PrimeFlags = blk: {
    @setEvalBranchQuota(10_000_000); // 见 13.6 节：默认 1000 远远不够
    var flags: [256]bool = @splat(true); // ⚠️ 0.17 没有 [_]T{x} ** n 重复填充（见 13.11 节）
    flags[0] = false;
    flags[1] = false;
    var n: u16 = 2;
    while (n * n < 256) : (n += 1) {
        if (flags[n]) {
            var m: u16 = n * n;
            while (m < 256) : (m += n) flags[m] = false;
        }
    }
    break :blk flags;
};

/// 13.10 节：从筛表里再编译期抽出前 8 个素数（演示表可以由表生成）。
const Primes = blk: {
    var buf: [8]u32 = undefined;
    var count: usize = 0;
    for (PrimeFlags, 0..) |is_p, idx| {
        if (count == 8) break;
        if (is_p) {
            buf[count] = @intCast(idx);
            count += 1;
        }
    }
    break :blk buf;
};
```

```zig
// examples/13_comptime/main.zig 第 130-145 行
/// 13.11 节：编译期生成的 CRC-32 查找表（标准 256 项多项式表）。
/// 这是"编译期算大数组、运行期只查表"最经典的例子：一段 2048 次迭代的编译期计算，
/// 换来运行期每字节一次查表 + 一次异或。
const CrcTable = blk: {
    @setEvalBranchQuota(10_000_000);
    var buf: [256]u32 = undefined;
    for (&buf, 0..) |*slot, idx| {
        var c: u32 = @intCast(idx);
        for (0..8) |_| {
            // ⚠️ 0.17 没有 ** 幂运算符，也没有 @clamp（见 13.12 节）
            if (c & 1 != 0) c = (c >> 1) ^ 0xEDB88320 else c >>= 1;
        }
        slot.* = c;
    }
    break :blk buf;
};
```

```zig
// examples/13_comptime/main.zig 第 388-413 行（begin("13.10") 到 end("13.10")）
    // ═══ 13.10 编译期数据结构：构造查表 ═══
    begin("13.10");
    // PrimeFlags 是埃氏筛：编译期约 3 万次迭代，编译时间只多零点几秒，
    // 二进制里只剩 256 个 bool。运行期判定变成 O(1) 数组索引。
    std.debug.print("筛表覆盖 0..{d}；241 是素数吗？{}；247 是素数吗？{}\n", .{
        PrimeFlags.len - 1, isPrime(241), isPrime(247),
    });
    std.debug.print("0/1 的标记 = {} / {}（筛法要特判头两个）\n", .{ isPrime(0), isPrime(1) });
    // 表可以由表生成：Primes 就是从 PrimeFlags 里编译期抽出来的前 8 个素数
    std.debug.print("从筛表抽出的前 8 个素数 = {any}\n", .{Primes});
    inline for (Primes, 0..) |p, idx| {
        std.debug.print("  Primes[{d}] = {d}\n", .{ idx, p });
    }
    // CRC-32 表：8 轮移位异或 × 256 项 = 2048 次编译期迭代，纯编译期产物
    std.debug.print("CRC-32 幂表前 4 项 = 0x{x:0>8}, 0x{x:0>8}, 0x{x:0>8}, 0x{x:0>8}...\n", .{
        CrcTable[0], CrcTable[1], CrcTable[2], CrcTable[3],
    });
    // 用它算标准校验值：说明这张表真的对
    std.debug.print("crc32(\"123456789\") = 0x{x:0>8}（标准 CRC-32 校验值）\n", .{crc32("123456789")});
    // 编译期递归也要配额：cfib(25) 不抬配额会撞 1000 分支上限（见 13.6 节）
    const f25 = comptime blk: {
        @setEvalBranchQuota(1_000_000);
        break :blk cfib(25);
    };
    std.debug.print("cfib(25) 编译期 = {d}（类型 {s}，没定型）\n", .{ f25, @typeName(@TypeOf(f25)) });
    end("13.10");
```

运行输出（`examples/13_comptime/main.zig`）：

```text
==== 13.10 开始 ====
筛表覆盖 0..255；241 是素数吗？true；247 是素数吗？false
0/1 的标记 = false / false（筛法要特判头两个）
从筛表抽出的前 8 个素数 = { 2, 3, 5, 7, 11, 13, 17, 19 }
  Primes[0] = 2
  Primes[1] = 3
  Primes[2] = 5
  Primes[3] = 7
  Primes[4] = 11
  Primes[5] = 13
  Primes[6] = 17
  Primes[7] = 19
CRC-32 幂表前 4 项 = 0x00000000, 0x77073096, 0xee0e612c, 0x990951ba...
crc32("123456789") = 0xcbf43926（标准 CRC-32 校验值）
cfib(25) 编译期 = 75025（类型 comptime_int，没定型）
==== 13.10 结束 ====
```

**三个细节值得单独说**：

**① 表可以由表生成。** `Primes`（前 8 个素数）是从 `PrimeFlags`（筛表）里**编译期抽**出来的。第一个 `blk` 是"干活"，第二个 `blk` 是"从产物里再加工"。这种分层在真实的查表代码里很常见。

**② 用标准校验值验证表本身是对的。** `crc32("123456789") = 0xcbf43926` 是 CRC-32 的标准测试向量。这个断言的价值在于：如果编译期算错了（比如某个常量写错），运行期会立刻暴露，而不用等到真实数据出问题。

**③ 编译期递归也需要配额。** `cfib(25)` = 75025（注意 `fibonacci(25)` 也是 75025——两栖函数，两个名字算出同一个数，这是 13.1 节机制的直接体现）。返回类型是 `comptime_int` **而不是 `u32`**，因为 `comptime` 参数 `n: u32` 没参与结果定型——递归返回的是加法结果，两个 `comptime_int` 相加还是 `comptime_int`。它只在**用到它的地方**才定型（比如塞进 `u32` 数组）。

## 13.11 编译期算术：`comptime_int` 的任意精度

```zig
// examples/13_comptime/main.zig 第 415-439 行（begin("13.11") 到 end("13.11")）
    // ═══ 13.11 编译期算术：comptime_int 的任意精度 ═══
    begin("13.11");
    const huge = 1 << 200; // 远超 u64 的上限（约 1.8e19），这里约 1.6e60
    std.debug.print("1 << 200 = {d}\n", .{huge});
    std.debug.print("  类型 = {s}（字面量没类型，用到时才定）\n", .{@typeName(@TypeOf(huge))});
    // ⚠️ 落地时必须装得下：给 u8 就编译错
    //   const small: u8 = 300;  → error: type 'u8' cannot represent integer value '300'
    const fits: u8 = 200;
    std.debug.print("200 装进 u8 = {d}；@bitSizeOf(u8) = {d}\n", .{ fits, @bitSizeOf(u8) });
    // 编译期算阶乘：20! 装得进 u64（20! ≈ 2.4e18，u64 上限 ≈ 1.8e19）
    comptime var fact: u64 = 1;
    comptime var fi: u32 = 1;
    inline while (fi <= 20) : (fi += 1) fact *= fi;
    std.debug.print("20! = {d}（编译期算，运行期零开销）\n", .{fact});
    // ⚠️ 0.17 没有 ** 幂运算符，也没有 [_]T{x} ** n 重复填充：
    //   `2 ** 3` → error: binary operator '*' has whitespace on one side,
    //                   but not the other（报错文案有点误导）
    //   [_]u8{7} ** 4 → @splat(7) 或 @memset
    const sp: [4]u8 = @splat(7);
    std.debug.print("@splat(7) = {any}（替代 ** 重复填充）\n", .{sp});
    // @clamp 已移除（error: invalid builtin function: '@clamp'），用 @min / @max
    const a: i32 = -5;
    const b: i32 = 12;
    std.debug.print("@max(a,b)={d} @min(a,b)={d}（替代 @clamp）\n", .{ @max(a, b), @min(a, b) });
    end("13.11");
```

运行输出（`examples/13_comptime/main.zig`）：

```text
==== 13.11 开始 ====
1 << 200 = 1606938044258990275541962092341162602522202993782792835301376
  类型 = comptime_int（字面量没类型，用到时才定）
200 装进 u8 = 200；@bitSizeOf(u8) = 8
20! = 2432902008176640000（编译期算，运行期零开销）
@splat(7) = { 7, 7, 7, 7 }（替代 ** 重复填充）
@max(a,b)=12 @min(a,b)=-5（替代 @clamp）
==== 13.11 结束 ====
```

输出第 1 行那个61 位整数（约 1.6e60）**远超 u64 的上限（约 1.8e19）**，这就是 `comptime_int` 的任意精度：编译期整数不是固定宽度，而是"编译器先精确记下这个数，用到时才定宽度"。C 里写不出这种东西（连 `unsigned __int128` 也只到 1.7e38）。

**但落地时必须装得下**——这是 03 章 3.3 节的规则，在 comptime 里同样适用：

```text
error: type 'u8' cannot represent integer value '300'
```

`20!` 恰好装得进 `u64`（2.4e18 < 1.8e19），所以 `comptime var fact: u64` 声明得对。写成 `comptime var fact: u32` 就会在编译期报 `overflow of integer type 'u32'`。

### ⚠️ 0.17 没有 `**` 幂运算符

实测报错（**文案有点误导**，编译器把 `**` 解析成了 `*` 然后抱怨空格不对称）：

```text
error: binary operator '*' has whitespace on one side, but not the other
    var flags = [_]bool{true} ** 256;
                              ^**
```

⚠️ **这意味着 `[_]T{x} ** n` 重复填充语法也一并没了**（它内部用的是同一条路径）。替代品：

| 老写法 | 0.17 写法 |
|---|---|
| `2 ** 3` | `1 << 3`（2 的幂）或 `std.math.pow(u64, 2, 3)` |
| `[_]u8{7} ** 4` | `@splat(7)`（输出第 5 行 `{ 7, 7, 7, 7 }`） |
| `[_]bool{true} ** 256` | `var flags: [256]bool = @splat(true);`（见 `PrimeFlags`） |

⚠️ 注意 `@splat` 的目标是**已声明类型**：`var flags: [256]bool = @splat(true);`✅，而 `[_]bool{@splat(true)}` ❌ 报 `expected array or vector type, found 'bool'`。

### ⚠️ `@clamp` 已移除

```text
error: invalid builtin function: '@clamp'
    const x = @clamp(5, 0, 3);
              ^~~~~~~~~~~~~~~
```

用 `@min` / `@max` 组合（输出第 6 行）。这是 0.17 清理掉的又一个便利内建——顺便说，**0.17 也把 `@intFromEnum` 改名成 `@backingInt`**（03 章 3.9 节），这个改名和 `@clamp` 的移除是同一批"内建函数瘦身"的一部分。

## 13.12 comptime 的代价：编译变慢 vs 运行变快

```zig
// examples/13_comptime/main.zig 第 441-464 行（begin("13.12") 到 end("13.12")）
    // ═══ 13.12 comptime 的代价：编译变慢 vs 运行变快 ═══
    begin("13.12");
    // 同一个判定，两种写法：查表版 O(1)（表在编译期算）vs 试除版 O(√n)（循环在二进制里）
    std.debug.print("查表版 isPrime(241)={} isPrime(247)={}；试除版 = {} / {}\n", .{
        isPrime(241),        isPrime(247),
        isPrimeRuntime(241), isPrimeRuntime(247),
    });
    // 编译期算 vs 运行期算：两者结果相同，代价分布不同
    const rt_n: usize = 30;
    std.debug.print("fibonacci({d})：编译期常量 = {d}（运行期 0 条指令）\n", .{ rt_n, fibonacci(25) });
    std.debug.print("fibonacci({d})：运行期递归 = {d}（几十条 call 指令）\n", .{ rt_n, fibonacci(rt_n) });
    // @sizeOf / @typeName / @typeInfo / @offsetOf 全都是 comptime 内建——
    // 写它们**不需要**"进编译期"，也不需要 comptime 关键字：
    std.debug.print("@sizeOf(Conf)={d} @typeName(u24)={s} @bitSizeOf(u24)={d}\n", .{
        @sizeOf(Conf),
        @typeName(u24),
        @bitSizeOf(u24),
    });
    // 编译期的红线：IO 与堆内存不行。
    //   comptime { std.debug.print(...); }
    //   → error: unable to resolve comptime value
    //     note: called at comptime from here（std/Io/Threaded.zig 里Thread.current 求值失败）
    std.debug.print("comptime 里不能 print（unable to resolve comptime value），也不能分配堆内存\n", .{});
    end("13.12");
```

运行输出（`examples/13_comptime/main.zig`）：

```text
==== 13.12 开始 ====
查表版 isPrime(241)=true isPrime(247)=false；试除版 = true / false
fibonacci(30)：编译期常量 = 75025（运行期 0 条指令）
fibonacci(30)：运行期递归 = 832040（几十条 call 指令）
@sizeOf(Conf)=24 @typeName(u24)=u24 @bitSizeOf(u24)=24
comptime 里不能 print（unable to resolve comptime value），也不能分配堆内存
==== 13.12 结束 ====
```

### 权衡的形状

| | 编译期算 | 运行期算 |
|---|---|---|
| 二进制里有什么 | **只有结果** | 完整算法（循环 + 判断） |
| 编译时间 | 随计算量**线性增长** | 不受影响 |
| 运行期性能 | 最优（0 条指令 / 1 次查表） | 每次调用都重算 |
| 适合 | 结果只取决于编译期常量；输入规模大且重复 | 输入运行期才知道；算法本身很便宜 |

`fibonacci(30)` 这一行最能说明问题：`832040` 是**运行期递归**算的（`rt_n` 是运行期变量），要跑几十条 `call`；而 `75025` 是 `fibonacci(25)` 在编译期算好的常量，运行期**一条指令都没有**。同一个函数，同一个二进制。

**实测的编译时间账单**：把 13.6 节那个10 万次 `inline while` 加进 `main`，编译时间从约 0.3 s 涨到约 4 s——**13倍**。这就是为什么 `@setEvalBranchQuota` 默认只有 1000：Zig 不让你不小心写出慢编译的代码。

### 编译期能做什么、不能做什么

| ✅ 可以 | ❌ 不可以 |
|---|---|
| 循环、分支、递归、局部 `var` | 任何 IO（`print` / 文件 / 网络） |
| 整数/浮点运算、比较 | 分配堆内存 |
| 调用其他函数（两栖的） | 读取运行期才有的值 |
| 反射：`@typeInfo` 全家、`@typeName`、`@sizeOf` | 把一个编译期常量改成不同类型 |
| 构造编译期数据结构（数组、结构体） | |

红线很直白：**编译期能算的都可以，依赖运行期世界的不行。** 函数"能不能在编译期跑"不需要声明——塞进 comptime 上下文里试一下就知道（不行就编译错，错误信息相当可读）。

**为什么 `print` 不行**——实测报错把调用链完整摊开了：

```text
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:2402:35: error: unable to resolve comptime value
    const thread = Thread.current orelse return .unblocked;
                   ~~~~~~~~~~~~~~~^~~~~~~~~~~~~~~~~~~~~~~~
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io.zig:1472:42: note: called at comptime from here
    return io.vtable.swapCancelProtection(io.userdata, new);
           ~~~~~~~~~~~~~~~~~~~~~~~~~~^~~~~~~~~~~
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/debug.zig:325:41: note: called at comptime from here
    const prev = io.swapCancelProtection(.blocked);
                 ~~~~~~~~~~~~~~~~~~~~~~~^~~~~~~~~~
main.zig:5:20: note: called at comptime from here
    std.debug.print("这行在编译期执行吗？\n", .{});
    ~~~~~~~~~~~~~~~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
main.zig:3:1: note: 'comptime' keyword forces comptime evaluation
comptime {
^~~~~~~~
```

这条报错值得逐层读：`std.debug.print` 需要拿当前的 `Io` 实例（`io.swapCancelProtection`），而 `Io` 实例的状态（比如 `Thread.current`）是**运行期才有的**——编译期没有"当前线程"。**不是 `print` 被禁了，是它依赖的东西在编译期不存在。** 最后一行 `note: 'comptime' keyword forces comptime evaluation` 直接告诉你：是你那个 `comptime` 块把 `print` 拖进编译期的。

⚠️ 顺带说`@sizeOf` / `@typeName` / `@typeInfo` / `@offsetOf` 这些（输出第 4 行）：它们**本身就是 comptime 内建**，写它们不需要"进编译期"，也不需要 `comptime` 关键字。你在普通运行期语句里写 `@sizeOf(u32)` 完全合法——它就是个常量表达式。

### 测试：把语义钉住

本章行为全靠测试守着（`main.zig` 第 511-685 行，11 个 `test` 块）：

```text
$ zig test main.zig
1/11 main.test.13.1 一份代码两个世界：fibonacci 两栖...OK
2/11 main.test.13.2 comptime 参数在编译期求值，传运行期值编译不过...OK
3/11 main.test.13.3 labeled block 是块表达式；容器级写 comptime 是冗余的...OK
4/11 main.test.13.4 改 comptime 变量的循环必须是 inline while...OK
5/11 main.test.13.5 泛型与显式 comptime 参数是同一个机制...OK
6/11 main.test.13.7 inline fn 运行期也能调；@inComptime() 无参且在普通函数为 false...OK
7/11 main.test.13.8 type是一等值；@Type 已移除，@tagName 不能作用于类型...OK
8/11 main.test.13.9 反射三条平行数组 + inline for；@hasDecl 必须给字符串...OK
9/11 main.test.13.10 编译期算出的数据表能直接用于运行期查询...OK
10/11 main.test.13.11 comptime_int 任意精度但落地要装得下...OK
11/11 main.test.13.12 查表版与试除版结果一致，但成本不同...OK
All 11 tests passed.
```

有两个测试特别值得注意：

- **第 9 个**断言 `isPrime(247) == false` 且 `isPrime(256) == false`（表覆盖范围外不猜）。这是查表代码的关键性质——**表的边界必须有明确语义**，不能靠运气。
- **第 11 个**用一个 12 元素的数组逐一断言 `isPrimeRuntime(n) == isPrime(n)`，保证两种实现结果一致（编译期算的表是对的）；同时断言 `@addWithOverflow` 的标志位是 `u1`（`ov[1] == 1`）和 `undefined` 填 `0x00`。

## 13.13 坑位清单

1. **改`comptime var` 的循环必须是 `inline while` / `inline for`**。普通 `while` 报 `error: cannot store to comptime variable in non-inline loop` + `note: non-inline loop here`；普通 `for`（哪怕赋的是常量）报 `error: store to comptime variable depends on runtime condition` + `note: runtime condition here`。两条报错说的是同一件事：编译器要证明这次写入发生在编译期。

2. **`@setEvalBranchQuota` 默认值是 1000，按作用域累计**。不是"每个循环各给 1000"，而是同一作用域里所有编译期循环共用。爆掉时报 `error: evaluation exceeded 1000 backwards branches` + `note: use @setEvalBranchQuota() to raise the branch limit from 1000`。"backwards branch"是循环回边计数，所以递归也算（`cfib(30)` 会撞上限）。⚠️ **实测可以往小调，不报错**（老教程说的 `attempt to reduce branch quota` 在 0.17 已消失）——它是预算申请，不是护栏。

3. **容器级（顶层 const 初始化）里`comptime` / `inline` / `comptime var` 三个关键字全是多余的**，各报一条 `redundant comptime keyword in already comptime scope` / `'comptime var' is redundant in comptime scope` / `redundant inline keyword in comptime scope`。容器级直接写 `var` + `while`。顶层甚至不能声明 `comptime var`（`error: expected type expression, found 'var'`）。

4. **`inline for` 在 0.17 支持索引捕获了**（旧教程说"不支持"已过时）：写 `inline for (names, 0..) |name, idx|`，不用再自己维护 `comptime var` 计数器。

5. **`@typeInfo(T).@"struct".fields` 不存在了**，改成三条平行数组：`field_names`（元素 `[:0]const u8`，哨兵切片）/ `field_types`（元素 `type`）/ `field_attrs`。`.tag` 改名`.layout`（`.auto` / `.@"extern"` / `.@"packed"`）。`field_attrs` 的对齐字段叫 **`.@"align"`（`?usize`）**，写 `.alignment` 报 `no field named 'alignment' in struct 'lang.Type.Struct.FieldAttributes'`。

6. **`field_types`（元素 `type`）、`field_values`（元素 `comptime_int`）、`[_]type` 数组只能用 `inline for`**。普通 `for` 一律报 `error: values of type 'type' must be comptime-known, but index value is runtime-known` + `note: types are not available at runtime`。理由：运行期没有"类型"这个值。同一个数组在 `test` 里可以直接下标断言。

7. **`@hasDecl(T, ident)` 的标识符形式在 0.17 失效**，必须给字符串：`@hasDecl(std.mem, "copyForwards")`。写标识符报 `error: use of undeclared identifier 'copyForwards'`——**这条报错极具迷惑性**（看起来像"这个 decl 不存在"），看到它要先怀疑参数形式。

8. **`@tagName` 不能作用于类型**：`@tagName(Header)` 报 `error: expected enum or union; found 'type'`。反射类型名一律 `@typeName`。记牢：`@typeName(T)` 吃类型，`@tagName(v)` 吃枚举/联合的值。

9. **⚠️【新】`@Type` 在 0.17 已被移除**：`error: invalid builtin function: '@Type'`。老教程"用 `@Type` 从 `@typeInfo` 结果反向造类型"这条路走不通了。替代：函数类型用 `@TypeOf(f)`（注意 `@TypeOf(&f)` 拿到的是**指针** `*const fn (...)`，要函数类型得 `@typeInfo(ptr).pointer.child`）；`type { ... }` 也报错（`does not support struct initialization syntax`）；其余类型直接写声明。

10. **`inline fn` 在运行期也能调**（实测）。`inline` 描述的是"函数体如何处理"（强制在调用点展开，不走 `call` 指令），**不是"调用时机"**。老教程说"`inline fn` 只在编译期可用"是错的。要强制编译期求值，得把它放进 `comptime` 块或 `const` 初始化里。

11. **`@inComptime()` 在 0.17 必须无参**：`@inComptime(x)` 报 `error: expected 0 arguments, found 1`；而在 `comptime` 块里写 `@inComptime()` 报 `error: redundant '@inComptime' in comptime scope`。另外：**函数里有 `comptime` 参数 ≠ 函数体在编译期执行**，实测 `inline fn f(comptime T: type) bool { return @inComptime(); }` 返回 `false`。

12. **`comptime` 参数传运行期值编译错**：`error: unable to resolve comptime value` + `note: argument to comptime parameter must be comptime-known` + `note: parameter declared comptime here`。这是契约不是 bug——要两栖就去掉 `comptime` 关键字（示例里`pow` 和 `powRuntime` 是同一算法的两份）。

13. **`comptime` 里不能IO**。`comptime { std.debug.print(...); }` 报 `unable to resolve comptime value`，报错链显示根因是 `std/Io/Threaded.zig` 里的 `Thread.current` 在编译期无解——**不是 print被禁，是它依赖的运行期状态不存在**。堆内存同理（编译期没有 allocator）。

14. **0.17 没有 `**` 幂运算符**（报的是莫名其妙的 `binary operator '*' has whitespace on one side, but not the other`），**`[_]T{x} ** n` 重复填充也一并没了** → `@splat(x)`。⚠️ `@splat` 要给已声明类型：`var flags: [256]bool = @splat(true);` ✅，而 `[_]bool{@splat(true)}` ❌ 报 `expected array or vector type, found 'bool'`。`++` 拼接仍可用。

15. **`@clamp` 已移除**：`error: invalid builtin function: '@clamp'` → 用 `@min` / `@max`。同批改名还有 `@intFromEnum` → `@backingInt`（03 章 3.9 节）。

16. **`@addWithOverflow` 的溢出标志是 `u1` 不是 `bool`**：`ov[1]` 是 0 或 1，要写 `ov[1] == 1` 才能喂给 `expect(bool)`，写 `expect(ov[1])` 报 `error: expected type 'bool', found 'u1'`。另外 **`error_names` 是可空的** `?[]const [:0]const u8`，得 `if (x) |y|` 或 `.?`；元素是哨兵切片，打印写 `n[0..n.len]`，写 `n[0..8 :0]` 报 `value in memory does not match slice sentinel`。**`undefined` 在 0.17 填 `0x00`**（0.16 是 `0xaa`）。

17. **⚠️【新】0.17 不许在函数体里声明 `fn`**：`fn inner(a: u32) u32 { ... }` 写在 `main` 里报 `error: expected ',' after initializer`（报错很莫名其妙，解析器把 `fn` 当成了别的东西）。需要局部函数就得放容器级。

---

上一章：[12 集合](12-collections.md) · 下一章：[14 泛型](14-generics.md)
