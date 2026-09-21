# 10 · 错误处理 II：errdefer、组合、安全模式

> 对应示例：`examples/10_errors2/`

## 10.1 errdefer：失败才执行的回滚

```zig
var made: usize = 0;
fn makeThing(gpa: std.mem.Allocator, id: u32) !*Thing {
    made += 1;                          // 副作用
    errdefer made -= 1;                 // 失败 → 回滚副作用
    const t = try gpa.create(Thing);    // try 失败会先跑上面的 errdefer
    errdefer gpa.destroy(t);            // 分配成功但后续失败 → 销毁
    t.* = .{ .id = id };
    return t;                           // 成功：两个 errdefer 都不跑
}
```

`defer` 无条件清理；**`errdefer` 只在"本作用域以错误退出"时执行**。两者分工：`defer` 管正常路径的资源释放（调用方负责），`errdefer` 管**半成品的回滚**（构造失败时把自己造的烂摊子收拾干净）。这是 Zig 版的"强异常保证"，也是本教程最重要的惯用法之一。

| 路径 | defer | errdefer |
|---|---|---|
| 正常 return | ✅ 执行 | ❌ 不执行 |
| 出错 return（含 try 失败） | ✅ 执行 | ✅ 执行 |
| panic | ❌（不保证） | ❌ |

## 10.2 分配-初始化模式（背下来）

```zig
fn buildList(gpa: std.mem.Allocator, n: usize) ![]u32 {
    const slice = try gpa.alloc(u32, n);   // ① 分配
    errdefer gpa.free(slice);              // ② 立刻挂回滚
    for (slice, 0..) |*p, i| p.* = @intCast(i * 2);  // ③ 初始化（可失败）
    if (n > 8) return error.TooBig;        // 这里失败 → errdefer 兜住
    return slice;                          // ④ 成功：所有权交给调用方
}
```

**①分配 → ②errdefer 回滚 → ③初始化 → ④交权**——顺序不能乱：errdefer 必须紧跟分配、在任何可能失败的初始化之前。多条 errdefer 也是 LIFO。C++ 用构造函数+RAII 自动做这事，Zig 用三个关键字把它摊开在你眼前——多写两行，换"退出路径全部显式"。

## 10.3 `?E!T`：缺席与出错双层

```zig
fn parseOpt(s: ?[]const u8) ?OptError!u8 {
    const str = s orelse return null;    // 先剥 null
    if (str[0] < '0' or str[0] > '9') return error.NotDigit;
    return str[0] - '0';
}
// 消费侧：orelse 先、catch 后
const parsed = parseOpt(cs) orelse { 缺席处理; continue; };
const digit = parsed catch |e| { 错误处理; continue; };
```

可选包着错误联合，类型写作 `?E!T`（**推断式 `?!T` 不可解析**——错误集必须显式）。解包顺序固定：**先 orelse 剥 null，再 catch/try 剥 error**——`catch` 不能直接作用于可选。反过来 `E!?T`（错误联合包可选）也是合法的另一个类型，别写混。

## 10.4 错误返回跟踪：Debug 白送的排查利器

错误一路 `try` 冒泡到 main 时，Debug 模式会打印**完整传播链**。实测输出（`ZIG_ERT=1` 跑 23 章示例）：

```text
error: DemoErrorReturnTrace
G:\code\guide\zig\examples\23_debug\main.zig:32:9: ... in main
```

多层传播时它会列出每一层的文件:行号——"这个错从哪来的"一眼可见。代价：Debug 模式在每个 `try` 上记录返回地址（约一条指令），**ReleaseFast/Small 下完全消失，零成本**。这就是 Zig 对"异常栈展开太贵"的回答：跟踪是记录出来的，不是展开出来的。

## 10.5 panic / unreachable：程序员的错

```zig
fn mustPositive(x: i32) i32 {
    if (x <= 0) @panic("x 必须为正");   // 主动崩溃，带栈跟踪
    return x;
}
fn classify(x: u2) []const u8 {
    return switch (x) {                 // u2 只有 0..3，穷尽
        0 => "零", 1 => "一", 2 => "二",
        3 => unreachable,               // 逻辑上到不了
    };
}
```

panic 家族和错误是**两个世界**：错误（`!T`）是"预料中的失败"，panic 是"程序写错了"。`unreachable` 是"到这说明逻辑已经崩了"的断言——Debug/ReleaseSafe 下到达即 panic，**ReleaseFast 下是 UB**（编译器会基于"到不了"优化）。`.?` 解到 null、`@intCast` 越界、越界索引，底层全是 panic。

## 10.6 安全模式：检查项矩阵

| 检查 | Debug | ReleaseSafe | ReleaseFast | ReleaseSmall |
|---|---|---|---|---|
| 整数溢出（`+ - *`） | ✅ panic | ✅ panic | ❌ UB | ❌ UB |
| 数组/切片越界 | ✅ | ✅ | ❌ | ❌ |
| 读错 union 形态 | ✅ | ✅ | ❌ | ❌ |
| `.?` 解 null、@intCast 越界 | ✅ | ✅ | ❌ | ❌ |
| 错误返回跟踪 | ✅ | ✅ | ❌ | ❌ |

```zig
fn addWrap(a: u8, b: u8) u8 {
    @setRuntimeSafety(false);    // 函数内关闭运行期检查（信任不变量换性能）
    return a +% b;
}
```

`@setRuntimeSafety(false)` 局部关检查——先有测试证明安全，再谈关闸。**开发永远 Debug，发布默认 ReleaseSafe，测透了才 ReleaseFast**。

## 10.7 坑位清单

1. **errdefer 写在 try 之后**：分配之后的失败就没有回滚了——errdefer 必须紧跟在它保护的动作后面注册（10.2 的顺序就是答案）。
2. **`?!T` 编译不过**：可选-错误联合必须显式错误集 `?E!T`（`?error{E}!u8` 或命名集合）；解析器不知道 `!` 属于谁。
3. **`catch` 直接作用在 `?E!T` 上是编译错**：先 `orelse` 剥可选（得到 `E!T`）再 catch——顺序反了工具全罢工。
4. **unreachable 在 ReleaseFast 是 UB**：它不是 assert——写下去就是在向编译器承诺"到不了"，承诺错了没有回头路。
5. **errdefer 不覆盖 panic**：panic 是"放弃治疗"，defer/errdefer 都不保证执行——所以 panic 消息只该用于 bug 报告，不做资源清理依赖。

---

上一章：[09 可选与错误 I](09-optionals-errors.md) · 下一章：[11 分配器](11-allocators.md)
