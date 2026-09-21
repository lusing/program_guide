# 09 · 可选类型与错误处理 I

> 对应示例：`examples/09_errors1/`

## 9.1 `?T`：可能缺席的值

```zig
fn findFirst(hay: []const u8, needle: u8) ?usize {
    for (hay, 0..) |b, i| {
        if (b == needle) return i;
    }
    return null;                 // 缺席也是合法返回
}
```

`?T` 是**可选类型**：值域 = T 的所有值 + null。"可能没有"被写进返回类型，编译器强制调用方面对 null——对比 C 的"返回 -1 表示没有"口口相传约定。`?*T`（可选指针）有个漂亮性质：与 `*T` 同大小（null 复用 0 地址），可选**不花内存**。

## 9.2 解包三件套

```zig
// ① if 捕获：有值走 A，没值走 B
if (idx) |i| { 用 i } else { 没找到 }
// ② orelse：给默认值
const fallback = findFirst("zig", '-') orelse 999;
// ③ .?：确信非 null，是就解，不是就 panic
const sure = findFirst("zig", 'z').?;
```

`.?` 是"我拿名誉担保它不是 null"——担保错了当场 panic（带栈跟踪）。它只该出现在**逻辑上不可能为 null** 的地方（刚检查过、常量表），拿它当"懒得写 else"的捷径必炸。

## 9.3 错误集合：error set

```zig
const ParseError = error{
    Empty,
    NotDigit,
    TooLong,
};
```

error set 是**编译期的错误名字集合**——每个错误就是一个全局唯一的名字（本质是 16 位整数 + 全局符号表），`error.Empty` 是它的值。集合还能做并集：`const Mixed = ParseError || error{Boom};`。错误**没有负载**（不能 `error.Invalid{line: 3}`）——要带数据的错误自己定义 struct 往外带（惯用法见 10 章）。

## 9.4 错误联合 `!T`：值或错误

```zig
fn parseScore(s: []const u8) ParseError!u8 {
    if (s.len == 0) return error.Empty;
    // ...
    return @intCast(v);          // 正常值直接 return，自动包进联合
}
```

`!T`（错误联合）= T 的值域 + 错误集合。返回它意味着"可能失败"——**调用方不处理就编译不过**（`if/while` 条件里直接用错误联合也编译错）。这是"强制检查的返回码"：Go 的 error 常忘查，Zig 忘查编译器拦。

签名两种写法：`ParseError!u8`（显式集合，给人看的契约，库边界推荐）和 `!u8`（推断集合，编译器从实现算出最小集合）。日常随手写 `!T`，发布 API 写显式。

## 9.5 try：向上传播

```zig
fn showScore(s: []const u8) ParseError!void {
    const score = try parseScore(s);   // 失败 → 立即 return 那个错误
    std.debug.print("得分 {d}\n", .{score});
}
```

`try expr` 就是 `expr catch |e| return e` 的语法糖——**错误处理的最常见动词**。一层层 `try` 下去就是错误传播链（10 章的错误返回跟踪会给这条链录像）。对照：Go 手写 `if err != nil { return err }` 十遍，Zig 一个 `try` 字。

## 9.6 catch：就地处理

```zig
const a = parseScore("88") catch 0;      // 后备值
const b = parseScore("8x8") catch 0;
const r = parseScore("") catch blk: {    // 后备块（可多行）
    break :blk 0;
};
```

`catch` 是 try 的反面：错误**在这里**被消化掉，不再向上。`catch 0`（吞掉给默认）要小心——吞错误不打日志是坏味道，至少 `catch |e| std.debug.print(...)` 记一笔。**`catch unreachable` 是"这不可能失败"的断言**（配 ReleaseFast 时是 UB 承诺，慎用）。

## 9.7 if/else 捕获：错误和值二选一

```zig
if (parseScore("")) |v| {
    std.debug.print("值 {d}\n", .{v});
} else |err| {
    std.debug.print("错误名：{s}\n", .{@errorName(err)});
}
```

和可选类型的 if 捕获同构：成功分支拿值，失败分支 `|err|` 拿错误。`@errorName(err)` 把错误转字符串（运行期查表）。`while` 同样支持：`while (it.next()) |item| { ... } else |err| { ... }`（迭代器遇错时退出到 else）。

## 9.8 对照表：?T、!T 和别家

| 场景 | Zig | C++ | Rust |
|---|---|---|---|
| 可能没有 | `?T` | `std::optional<T>` | `Option<T>` |
| 可能失败 | `E!T` | 返回码 / `expected<T,E>` | `Result<T, E>` |
| 两者都要 | `?E!T` | optional<expected<>> | `Option<Result<>>` |
| 强制检查 | 编译器 | 无（C++）/ 部分库 | 编译器 |

`?T` 与 `!T` 语义有分工：**"没有"是正常业务（字典里没这个键）用 `?T`；"失败了"是异常路径（文件打不开）用 `!T`**。两者可组合成 `?E!T`（10 章实操）。

## 9.9 坑位清单

1. **`.?` 当万能解包**：逻辑上可能 null 的地方用 `.?` = 埋 panic——业务路径一律 if/orelse，`.?` 只留给"刚验证过"的场合。
2. **推断错误集传染**：`!T` 函数调了一堆别的 `!T` 函数，你的集合悄悄膨胀——库公开 API 用显式集合钉死契约，不然改实现 = 破坏 API。
3. **错误不能带数据**：`error.Invalid` 就是个名字——要带上下文（哪一行、什么值）返回自定义 struct，或用 `std.log` 先记日志再返回错误。
4. **`catch unreachable` 在 ReleaseFast 是 UB 承诺**：Debug 下它 panic（能抓到打脸），ReleaseFast 下编译器信了你——只用在真·不可能的分支。
5. **`?*T` 与 `*?T` 是两个东西**：前者"可能没有指针"（零开销），后者"指向可能为 null 的值的指针"——类型要写对，语义完全不同。

---

上一章：[08 枚举与联合](08-enums.md) · 下一章：[10 错误 II](10-errors-advanced.md)
