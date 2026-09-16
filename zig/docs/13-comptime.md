# 13 · comptime I：编译期求值 ⭐

> 对应示例：`examples/13_comptime/`
>
> Zig 的编译期执行和运行期是**同一种语言**——这是它替代 C 预处理器和 C++ 模板元编程的根本方案。

## 13.1 一份代码，两个世界

```zig
fn fibonacci(n: usize) usize {
    if (n < 2) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}
const fib10 = fibonacci(10);   // 55：const 初始化必须编译期可得 → 编译期算

var n: usize = 20;             // 运行期输入（假装来自用户）
n += 1;
fibonacci(n)                   // 同一个函数，运行期照常调
```

**没有 `constexpr` 这样的标注**——满足两个条件就自动在编译期算：值是 `const`（初始化必须编译期完成）+ 输入编译期已知。同一份 `fibonacci`，编译期是查表、运行期是函数——对比 cpp20：那边函数要标 `constexpr` 才有两栖资格，Zig 全部函数默认两栖。

## 13.2 comptime 参数：编译期常量进签名

```zig
fn pow(comptime base: u64, comptime exp: u32) u64 {
    return std.math.pow(u64, base, exp);
}
const kib = pow(2, 10);        // 编译期算出 1024
pow(runtime_base, 10)          // 编译错！comptime 参数必须编译期已知
```

参数表里标 `comptime` = **该参数必须在编译期已知**。传运行期值直接编译错——这不是限制是契约：保证函数体可以对它做编译期的事（当数组长度、当类型开关）。泛型全靠它（14 章）。

## 13.3 comptime 块与容器级 const

```zig
const table = blk: {
    @setEvalBranchQuota(10000);        // 编译期循环配额
    var t: [16]u16 = undefined;
    for (0..16) |i| t[i] = i * i;
    break :blk t;
};
```

两个要点：**容器级（文件/struct 顶层）的 const 本身就在编译期求值**——那里写 `comptime` 关键字反而"redundant"编译错（本教程实测踩过）；函数体内才需要 `comptime blk: { ... }` 显式声明。`blk: { ... break :blk val }` 是块表达式语法（带标签的块产出值）。

## 13.4 @setEvalBranchQuota：编译期配额

```zig
const checksum = blk: {
    @setEvalBranchQuota(100000);       // 不加这行：默认 1000 分支配额必爆
    var acc: u32 = 0;
    var i: usize = 0;
    while (i < 1000) : (i += 1) acc +%= @intCast(i);
    break :blk acc;
};
```

编译期执行默认只有 **1000 个分支配额**——防止一个手滑的无限循环把编译器卡死。循环超过配额就编译错，错误信息会提示你加 `@setEvalBranchQuota`（只能往大调）。这是"编译期计算也要看账单"的机制化：0.13 节说的"编译时间失控"在 Zig 里有闸门。

## 13.5 inline for / inline while

```zig
inline for (.{ "alpha", "beta", "gamma" }) |name| {   // 序列须编译期已知
    std.debug.print("inline 展开 {s}\n", .{name});
}
```

`inline for/while` 在编译期**展开**循环体——三轮迭代生成三段代码。什么时候用：循环体内要做"每轮不同类型"的事（14 章反射遍历字段）——普通 for 做不到（循环变量运行期化）。**普通计算别加 inline**：不会更快（编译器自己会展开小循环），只会让二进制变大。注意 inline for **没有索引捕获**（`|name, i|` 编译错）。

## 13.6 编译期断言与诊断

```zig
comptime {
    if (fib10 != 55) @compileError("fibonacci 算错了");   // 构建期报错
}
comptime std.debug.assert(@sizeOf(u64) == 8);             // 编译期断言
```

`@compileError(msg)` 让错误**发生在构建期**——数学常数、协议字段偏移、布局假设，都值得一条 `comptime assert` 护航（对照 cpp20 的 `static_assert`，Zig 版还能带条件逻辑）。`@compileLog(x)` 是编译期的 `printf`：诊断 comptime 值时在**编译输出**里打值，完事记得删。

## 13.7 comptime 能做什么

| ✅ 可以 | ❌ 不可以 |
|---|---|
| 循环、分支、递归、局部 var | 任何 IO（print/文件/网络） |
| 整数/浮点运算、比较 | 分配堆内存 |
| 调用其他函数（两栖的） | 读取运行期才有的值（全局可变量） |
| 反射：@typeInfo 全家（14 章） | 修改变成不同类型 |

红线很直白：**编译期能算的都可以，依赖运行期世界的不行**。函数"能不能在编译期跑"不需要声明——塞进 comptime 上下文里试一下就知道（不行就编译错，错误信息相当可读）。

## 13.8 坑位清单

1. **容器级 const 里写 `comptime` 报 redundant**：顶层 const 天然编译期——`const x = comptime f();` 编译错，去掉 comptime。
2. **分支配额不足**：`while` 循环上千次的 comptime 块默认必爆——按错误提示 `@setEvalBranchQuota(大数)`。
3. **comptime 参数传运行期值编译错**：这是契约不是 bug——真要两栖就把参数改成普通参数，靠调用侧 const 化进编译期。
4. **inline for 无索引捕获**：`inline for (xs) |x, i|` 编译错；要下标自己维护 comptime var 计数。
5. **编译期递归无界**：comptime 递归 fibonacci(30+) 会先撞配额再撞编译时间——大表用迭代生成，别硬算。

---
