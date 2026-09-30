# 33 · 实战：表达式解释器 zcalc

> 对应示例：`examples/33_zcalc/`
>
> 一个小语言的完整生命线：**lexer → Pratt 解析器 → AST → 树遍求值**。取材 Tsoukalos ch12——这一章是前面所有语言设施的合体考试：tagged union（AST）、comptime、HashMap（环境）、错误处理（带位置的诊断）。

## 33.1 词法：字符流 → 记号流

`lex` 一个字符一个字符走：空白跳过、数字与标识符**贪吃最长匹配**（`while isDigit` 连吃）、单字符运算符查表。产出 `Token{ kind, text, pos }`——**pos 是错误报告的本钱**，语法错能指到列。

## 33.2 AST：表达式即树

```zig
const Expr = union(enum) {
    num: f64,
    variable: []const u8,
    unary: struct { op: TokenKind, child: *Expr },
    binary: struct { op: TokenKind, lhs: *Expr, rhs: *Expr },
    call: struct { name: []const u8, arg: *Expr },
};
```

tagged union + 指针子节点——Zig 建树的标准姿势。求值器对它 `switch`，穷尽性由编译器兜底（加新节点类型，忘改求值器=编译错）。

## 33.3 Pratt 解析：优先级爬升

```zig
fn bindingPower(op: TokenKind) ?struct { left: u8, right: u8 } {
    return switch (op) {
        .plus, .minus => .{ .left = 1, .right = 2 },   // 左结合：左严右松
        .caret => .{ .left = 6, .right = 5 },          // 右结合：左松右严
        ...
    };
}
fn parseBinary(p: *Parser, min_bp: u8) ParseError!*Expr {
    var lhs = try p.parseUnary();
    while (true) {
        const bp = bindingPower(p.peek().kind) orelse break;
        if (bp.left < min_bp) break;
        _ = p.advance();
        const rhs = try p.parseBinary(bp.right);       // 递归带着右界爬
        lhs = try p.alloc(.{ .binary = .{ .op, .lhs = lhs, .rhs = rhs } });
    }
    return lhs;
}
```

一对 `(left, right)` 优先级编码结合性：`2 ^ 3 ^ 2 = 2^(3^2) = 512`（右结合），`10 - 3 - 2 = 5`（左结合）。十几行代码吃掉整个表达式文法——比"为每个优先级写一个函数"的教科书路线短一个数量级。

## 33.4 求值：树上走一圈 + 变量环境

`Env = StringHashMap(f64)`；赋值是**语句**（`x = 5`），表达式只读变量。除零显式报错（f64 除零本可得 inf，解释器选择给用户看 `DivideByZero`）。内建函数 `sqrt/abs/floor` 走 `.call` 节点。

## 33.5 解释器的内存姿势：arena

解析产生的 AST 节点、环境里的键，全喂一个 arena——**一次求值一个 arena**，`deinit` 全清。手写树结构天然不规则，逐节点 free 是给自己埋雷；这也解释了为何示例测试全用 arena（testing.allocator 对 AST 逐节点泄漏零容忍）。

## 33.6 坑位清单

1. **`var` 是关键字**：AST 字段名写 `var` 直接编译错——改 `variable`（本章实测现场；关键字家族还有 align/enum/error 等）。
2. **switch 臂里的 `blk:` 标签不用即报错**：数字/标识符分支用不上标签就别写（unused block label 是编译错不是警告）。
3. **尾部必须 `.eol`**：`parseExpr` 返回后 peek 不是 eol 即语法错——`"1 2"` 这种输入没有它会被静默接受。
4. **f64 求和断言用 `expectApproxEqAbs`**：`sqrt(2)*sqrt(2) = 2.0000000000000004`——浮点相等断言必带容差。
5. **REPL 的交互读行**：0.16 的终端行读取依赖 `std.Io.Terminal`（raw 模式行编辑），示例把它留作练习——核心（lex/parse/eval/runLine）与交互层解耦后，REPL 只是薄壳。

## 33.7 扩展练习

1. 一元负号推广到 `+`；比较运算 `< <= > >= ==`（返回 0/1，优先级低于加减）。
2. `min(a, b)` 多参数——`call.arg` 改成参数列表（AST 里挂切片）。
3. REPL：`Io.Terminal` 行读取 + 历史上一页（进阶）。
4. 编译到栈虚拟机字节码再执行（从树遍走进化到 bytecode loop——性能差异立现）。

---

上一章：[32 SQLite 实战](32-sqlite.md) · 下一章：[34 实战：LRU 缓存服务器](34-zcache.md)
