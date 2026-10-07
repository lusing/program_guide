# 33 · 实战：表达式解释器 zcalc

> 对应示例：`examples/33_zcalc/main.zig`（1550 行，14 个分节 + 26 个 test）
>
> 一个小语言的完整生命线：**词法 → 优先级爬升解析 → `union(enum)` AST → 树遍求值 → REPL**。
> 这是前面所有语言设施的合体考试：`union(enum)` 建树、comptime 查表、`StringHashMapUnmanaged`
> 做环境、错误集 + 旁路诊断、深度闸门防栈溢出。
>
> ⚠️ **本章会推翻五个常见说法**：
> 1. ❌「解释器就是递归调 `eval`」→ `eval` 只是第三段；前两段（词法/语法）各有各的活，
>    而且**第三段反而是最浅的一段**。见 33.1。
> 2. ❌「Zig 有隐式整数提升」→ **算术结果永不宽化**，`u8 + u8` 的类型就是 `u8`。
>    要提升必须显式 `@as` / `@intCast`。见 33.13。
> 3. ❌「`left > right` 表示左结合」→ **正好相反**。`left < right` 才是左结合。
>    教科书式的"左严右松"直觉在这里是错的。见 33.4。
> 4. ❌「Zig 会检查栈溢出」→ **不检查**。没有 canary，递归写深了直接段错误。见 33.10。
> 5. ❌「`std.Io.Reader.takeDelimiterExclusive` 能直接用来读行」→ 0.17 里它
>    **不消费缓冲**，第二次调用拿到空串。行协议必须自己写。见 33.14。
>
> 验证：`zig fmt --check` → `zig test`（26 个 test）→ `zig build-exe` → 运行，
> 三层全绿。输出连跑 5 次逐字节一致（MD5 相同）。

---

## 33.1 为什么要写解释器：三阶段流水线

"编译"这个词骗人。 interpreters 里根本没有编译，只有**三段各自独立的变换**：

```plain
  字符流            记号流               AST                值
  "1 + 2 * 3"  ──▶  num plus num  ──▶  binary(plus)   ──▶  7
                   num star num       └ binary(star)
                   eof                  ├ num 1
                                        ├ num 2
                                        └ num 3 / num 3
     │                  │                    │
   lex（词法）      parseBinary（语法）    eval（求值）
   分类 + 记位置     优先级爬升建树        后序遍历查环境
```

三段之间**只靠两个数据类型通信**：`lex` 吐 `[]Token`，`parse` 吐 `*Expr`，
`eval` 吃 `*Expr`。这个窄接口就是可测试性的全部来源——33.15 里每一层的测试
都不需要启动前一层。

所以"解释器就是递归调 eval"这句话只对了一半：`eval` 是第三段，也是最简单的一段。
真正难的是前两段：`lex` 要在**一次前進**里同时定下"这是什么记号"和"它在哪"，
`parse` 要把一维记号流拧成二维树并且拧对结合性。

```zig
// examples/33_zcalc/main.zig 第 757-771 行（33.1 分节）
    begin("33.1");
    std.debug.print("源码 \"1 + 2 * 3\"\n", .{});
    std.debug.print("  字符流  |1| |+| |sp| |2| |sp| |*| |sp| |3|\n", .{});
    std.debug.print("    │词法 lex：分类 + 记位置（一次前進拿全三样）\n", .{});
    std.debug.print("    ▼\n", .{});
    std.debug.print("  记号流  num(1@1:1) plus(@1:3) num(2@1:5) star(@1:7) num(3@1:9) eof\n", .{});
    std.debug.print("    │语法 parseBinary：优先级爬升，结合性编码进 (left,right)\n", .{});
    std.debug.print("    ▼\n", .{});
    std.debug.print("  AST      binary(plus) → binary(star) → num(2) num(3)，左边裸 num(1)\n", .{});
    std.debug.print("    │求值 eval：树上后序遍历，遇变量查环境\n", .{});
    std.debug.print("    ▼\n", .{});
    std.debug.print("  值       7\n", .{});
    std.debug.print("⚠️ 三段只靠 []Token 和 *Expr 通信 ⇒ 每段能单独测试（33.15）\n", .{});
    std.debug.print("⚠️ '解释器就是递归调 eval' 只对一半：eval 只是第三段\n", .{});
    end("33.1");
```

运行输出（`examples/33_zcalc/main.zig`）：

```text
==== 33.1 开始 ====
源码 "1 + 2 * 3"
  字符流  |1| |+| |sp| |2| |sp| |*| |sp| |3|
    │词法 lex：分类 + 记位置（一次前進拿全三样）
    ▼
  记号流  num(1@1:1) plus(@1:3) num(2@1:5) star(@1:7) num(3@1:9) eof
    │语法 parseBinary：优先级爬升，结合性编码进 (left,right)
    ▼
  AST      binary(plus) → binary(star) → num(2) num(3)，左边裸 num(1)
    │求值 eval：树上后序遍历，遇变量查环境
    ▼
  值       7
⚠️ 三段只靠 []Token 和 *Expr 通信 ⇒ 每段能单独测试（33.15）
⚠️ '解释器就是递归调 eval' 只对一半：eval 只是第三段
==== 33.1 结束 ====
```

---

## 33.2 词法分析（Lexer）：手写扫描器，不写正则

`lex` 一个字符一个字符往前挪，每一步做三件事之一：跳空白、贪吃多字符记号、
查表定单字符记号。**不用正则**不是复古瘾，理由在下面。

正则的接口是"给我一个字符串，告诉我匹配到了什么"，**位置是事后用
`match.start` 补的**。于是"识别"和"定位"变成两趟，而你要么写两趟（慢且容易
在两趟之间丢掉状态），要么在回调里手工维护行列计数器（那就已经在手写扫描器了）。

手写扫描器一次前進同时拿到三样：`kind`（这是什么）、`text`（原文切片）、
`pos`（行列）。第三样是本章所有错误报告能成立的前提（33.3）。

分类规则只有三类，对应三种循环结构：

| 记号类 | 判据 | 结构 |
|---|---|---|
| 单字符运算符 | `switch (ch)` 查表 | 一个 `switch`，13 个 case |
| 数字 | `isDigit` 循环 + 小数点前瞻 | `while`，前瞻一格 |
| 标识符/关键字 | `isAlphanumeric` 循环 | `while`，然后查关键字表 |

```zig
// examples/33_zcalc/main.zig 第 20-48 行（记号类型与位置类型）
const TokenKind = enum {
    num,
    ident,
    plus,
    minus,
    star,
    slash,
    percent,
    caret,
    lparen,
    rparen,
    lbrace,
    rbrace,
    comma,
    semi,
    eq,
    let_kw,
    var_kw,
    eof,
};

/// 没有位置的错误信息等于没用——用户只知道自己写错了一个字符，却不知道是哪个。
const Pos = struct { offset: u32, line: u32, col: u32 };

const Token = struct {
    kind: TokenKind,
    text: []const u8,
    pos: Pos,
};
```

⚠️ **关键字字段不能叫 `let` / `var`**：`let` 和 `var` 在 Zig 里是关键字，
`var` 更糟——它是所有 `var` 声明的关键词。所以关键字记号只能叫 `let_kw` / `var_kw`。
（原始类型名同理：`error` / `void` / `u1` 拿来当变量名会报
`name shadows primitive`，见 33.9 坑位清单。）

扫描器主体：

```zig
// examples/33_zcalc/main.zig 第 85-130 行（lex 开头到数字分支）
fn lex(a: std.mem.Allocator, src: []const u8, diag: ?*Diag) CalcError![]Token {
    var toks: std.ArrayList(Token) = .empty;
    errdefer toks.deinit(a);
    var i: usize = 0;
    var line: u32 = 1;
    var col: u32 = 1;
    while (i < src.len) {
        const ch = src[i];
        if (ch == '\n') {
            i += 1;
            line += 1;
            col = 1;
            continue;
        }
        if (ch == ' ' or ch == '\t' or ch == '\r') {
            i += 1;
            col += 1;
            continue;
        }
        const pos: Pos = .{ .offset = @intCast(i), .line = line, .col = col };
        const kind: TokenKind = switch (ch) {
            '+' => .plus,
            '-' => .minus,
            '*' => .star,
            '/' => .slash,
            '%' => .percent,
            '^' => .caret,
            '(' => .lparen,
            ')' => .rparen,
            '{' => .lbrace,
            '}' => .rbrace,
            ',' => .comma,
            ';' => .semi,
            '=' => .eq,
            '0'...'9' => {
                // 小数点只在**后面还有数字**时才算小数点，否则 `1..2` 会被并成一个记号。
                // 这是"最长匹配但要前瞻一格"的最小例子。
                const start = i;
                while (i < src.len and std.ascii.isDigit(src[i])) i += 1;
                if (i + 1 < src.len and src[i] == '.' and std.ascii.isDigit(src[i + 1])) {
                    i += 1;
                    while (i < src.len and std.ascii.isDigit(src[i])) i += 1;
                }
                col += @intCast(i - start);
                try toks.append(a, .{ .kind = .num, .text = src[start..i], .pos = pos });
                continue;
```

三个设计点值得单独说：

1. **`pos` 在进 `switch` 之前就算好了**。这样无论哪个分支（包括 `else` 的
   `BadChar`）都能报出位置。33.2 的输出里 `1 $ 2` 报 `1:3`，就靠这个。
2. **关键字在词法层就定型**。`let` 到 token 流里已经是 `let_kw`，解析器
   永远不需要 `std.mem.eql(u8, t.text, "let")`。这是把"什么算关键字"这个
   决定放在唯一该放的地方。
3. **小数点前瞻一格**。`1.5` 是一个记号；`1..2` 里第二个 `.` 后面没有数字，
   于是它不是小数点，孤立的 `.` 落到 `switch` 的 `else` → `BadChar`。
   如果不做前瞻，`1..2` 会被并成 `1..2` 一个数字记号，静默吞掉一个错误。

```zig
// examples/33_zcalc/main.zig 第 774-796 行（33.2 分节）
    begin("33.2");
    {
        const src = "let x = 3.5 + sqrt(2); %";
        const toks = try lex(a, src, null);
        std.debug.print("源码：{s}\n", .{src});
        std.debug.print("切出 {d} 个记号 + 1 个 eof：\n", .{toks.len - 1});
        for (toks) |t| std.debug.print("  {s: <9} text={s:<6} @{d}:{d}\n", .{ @tagName(t.kind), t.text, t.pos.line, t.pos.col });
        std.debug.print("分类靠三件事：switch(单字符) / isDigit 循环 / isAlphanumeric 循环\n", .{});
        std.debug.print("⚠️ '1..2' 不会并成一个数字：小数点要前瞻一格确认后面还有数字\n", .{});
        std.debug.print("⚠️ 关键字在**词法**就定型，解析器不再比对字符串\n", .{});
    }
    {
        // ⚠️ 坑：`catch |e| { print(..); return; }` 的 return 会**结束整个 main**，
        // 后面 33.3~33.14 全不执行（实测产物只有两节）。要退出当前块得用 break。
        var d: Diag = .{};
        if (lex(a, "1 $ 2", &d)) |_| {
            std.debug.print("?? 不该成功\n", .{});
        } else |e| {
            std.debug.print("非法字符 $ → error.{s}（词法层唯一的失败）\n", .{@errorName(e)});
            report("1 $ 2", d);
        }
    }
    end("33.2");
```

运行输出（`examples/33_zcalc/main.zig`）：

```text
==== 33.2 开始 ====
源码：let x = 3.5 + sqrt(2); %
切出 11 个记号 + 1 个 eof：
  let_kw    text=let    @1:1
  ident     text=x      @1:5
  eq        text==      @1:7
  num       text=3.5    @1:9
  plus      text=+      @1:13
  ident     text=sqrt   @1:15
  lparen    text=(      @1:19
  num       text=2      @1:20
  rparen    text=)      @1:21
  semi      text=;      @1:22
  percent   text=%      @1:24
  eof       text=       @1:25
分类靠三件事：switch(单字符) / isDigit 循环 / isAlphanumeric 循环
⚠️ '1..2' 不会并成一个数字：小数点要前瞻一格确认后面还有数字
⚠️ 关键字在**词法**就定型，解析器不再比对字符串
非法字符 $ → error.BadChar（词法层唯一的失败）
    位置 1:3  非法字符 $
    | 1 $ 2
    |   ^
==== 33.2 结束 ====
```

⚠️ 注意最后那个 `diag` 参数是**可选**的（`?*Diag`）。测试里只关心 token 序列时
传 `null` 省事；但走 `runProgramDiag` 的路径必须把真的 `diag` 传进去，
否则 `BadChar` 在报告里就是 `0:0`——这个坑本章实测踩过（33.9 的输出里
`1 $ 2` 一开始报的就是 `0:0`）。

---

## 33.3 Token 与位置信息：为什么错误必须带位置

位置三元组 `Pos { offset, line, col }` 里，`offset` 是给切片用的（`src[start..i]`），
`line` / `col` 是给人看的。三者都在 `lex` 里一次算完，一路带到 AST 节点上。

为什么值得为它多写一个字段？拿除零举例。`10 / (4 - 4)` 求值时，
`eval` 拿到的是一棵**已经不含任何源码文本**的树——它不知道用户写了什么。
如果不把 `pos` 焊在 `binary` 节点上，报错就只能是 `error.DivisionByZero`，
用户得自己在脑子里重跑一遍词法分析才知道是哪个 `/` 出问题。

有了 `pos`，同一个错误能变成"第 1 行第 4 列，下面那个指针"：

```zig
// examples/33_zcalc/main.zig 第 799-813 行（33.3 分节）
    begin("33.3");
    {
        const src = "10 / (4 - 4)";
        std.debug.print("源码：{s}\n", .{src});
        for (try lex(a, src, null)) |t| std.debug.print("  {s: <7} @{d}:{d}  字符 '{s}'\n", .{ @tagName(t.kind), t.pos.line, t.pos.col, t.text });
        var diag: Diag = .{};
        if (runProgramDiag(a, &env, src, &diag, default_max_depth)) |_| {
            std.debug.print("?? 不该成功\n", .{});
        } else |e| {
            std.debug.print("求值 10 / 0 → error.{s}\n", .{@errorName(e)});
            report(src, diag);
            std.debug.print("⇒ 位置来自 binary 节点的 pos，也就是 '/' 这个 token 的位置\n", .{});
        }
    }
    end("33.3");
```

`report` 是本章唯一的诊断渲染函数，三样缺一不可：

```zig
// examples/33_zcalc/main.zig 第 706-717 行（report）
/// 带位置的错误报告：行列 + 出错行 + 插入符。少任何一样，用户都得自己数格子。
fn report(src: []const u8, d: Diag) void {
    if (d.msg.len == 0) {
        std.debug.print("    （无诊断信息）\n", .{});
        return;
    }
    std.debug.print("    位置 {d}:{d}  {s}\n", .{ d.pos.line, d.pos.col, d.msg });
    if (d.pos.line == 0) return;
    std.debug.print("    | {s}\n", .{lineText(src, d.pos.line)});
    const pad = "                                                                ";
    std.debug.print("    | {s}^\n", .{pad[0..@min(@as(usize, d.pos.col) -| 1, pad.len)]});
}
```

运行输出（`examples/33_zcalc/main.zig`）：

```text
==== 33.3 开始 ====
源码：10 / (4 - 4)
  num     @1:1  字符 '10'
  slash   @1:4  字符 '/'
  lparen  @1:6  字符 '('
  num     @1:7  字符 '4'
  minus   @1:9  字符 '-'
  num     @1:11  字符 '4'
  rparen  @1:12  字符 ')'
  eof     @1:13  字符 ''
求值 10 / 0 → error.DivisionByZero
    位置 1:4  除数为 0
    | 10 / (4 - 4)
    |    ^
⇒ 位置来自 binary 节点的 pos，也就是 '/' 这个 token 的位置
==== 33.3 结束 ====
```

注意位置是 **1:4**——`/` 所在的那一格，不是 `4 - 4` 里的 `4`。
这是 `parseBinary` 建 `binary` 节点时用 `t.pos`（运算符 token）的结果。
这个选择是对的：用户写下 `10 / (...)` 时，**除零的责任在 `/`**，不在右操作数。

⚠️ 本章最贵的一个 bug 就出在这一块：`Diag` 里 `msg` 是指向自己 `buf` 的切片。
如果把 `Diag` **按值**传递（`ctx.diag: Diag` 而不是 `*Diag`），`msg` 会指向
**旧对象**的缓冲区，旧对象（栈上的临时）一返回，读到的就是垃圾字节。
实测症状是报告里打出 `位置 1:4  ⟨乱码⟩`——位置对，文案乱。修法是让
`Ctx.diag` 变成指针（见 33.9 的 `Ctx`）。

---

## 33.4 递归下降语法分析（Parser）：优先级爬升法

教科书路线是"每个优先级层写一个函数"：`parseExpr` 调 `parseAdd`，`parseAdd`
调 `parseMul`，`parseMul` 调 `parseUnary`……七层优先级就是七个函数，
加一个运算符要动一串函数。

优先级爬升（Pratt / precedence climbing）把这件事压成**一个函数 + 一张表**。
核心循环只有六行：

```zig
// examples/33_zcalc/main.zig 第 319-330 行（parseBinary）
    fn parseBinary(p: *Parser, min_bp: u8) CalcError!*Expr {
        var lhs = try p.parseUnary();
        while (true) {
            const t = p.peek();
            const bp = bindingPower(t.kind) orelse break;
            if (bp.left < min_bp) break;
            _ = p.advance();
            const rhs = try p.parseBinary(bp.right);
            lhs = try p.alloc(.{ .binary = .{ .op = t.kind, .lhs = lhs, .rhs = rhs, .pos = t.pos } });
        }
        return lhs;
    }
```

读法：先拿到左边，然后**循环**看下一个记号是不是二元运算符。
是的话看它的 `left` 够不够 `min_bp`——不够就收工（这个运算符归上层管）。
够就吃掉它，用 `bp.right` 作新的门槛递归解析右边，然后把结果包成新节点。

### ⚠️ 结合性判据：和直觉正好相反

这是本章最容易讲错的一点。`bindingPower` 返回 `(left, right)` 两个数，
直觉说法是"左严右松 = 左结合"。**在爬升法里这正好是反的**：

```zig
// examples/33_zcalc/main.zig 第 189-206 行（bindingPower 及其机制说明）
/// 一对 (left, right) 优先级同时编码了优先级与结合性。
///
/// 机制：`parseBinary(min_bp)` 里 `if (bp.left < min_bp) break;`，右操作数用
/// `parseBinary(bp.right)` 递归。所以：
/// - **left < right**（`+ -` 的 1/2）：右侧门槛更高 ⇒ 右侧**吃不下**同级运算符
///   ⇒ 剩下的 `+` 留给外层循环 ⇒ **左结合**（`10-3-2 = (10-3)-2`）。
/// - **left > right**（`^` 的 7/6）：右侧门槛更低 ⇒ 右侧**能**继续吃 ⇒ **右结合**。
///
/// ⚠️ 这条判据和"左严右松"的直觉说法**正好相反**，实测反证见 33.4。
/// 放**顶层**而非 Parser 的方法——33.12 的表格验证要在 main 里直接查它。
fn bindingPower(op: TokenKind) ?struct { left: u8, right: u8 } {
    return switch (op) {
        .plus, .minus => .{ .left = 1, .right = 2 },
        .star, .slash, .percent => .{ .left = 3, .right = 4 },
        .caret => .{ .left = 7, .right = 6 },
        else => null,
    };
}
```

**为什么反了**？关键在那句 `if (bp.left < min_bp) break;`。
右操作数是用 `parseBinary(bp.right)` 解析的，所以 `bp.right` 是**右侧的门槛**。

- `+ -` 给 1/2：右侧门槛 2 比较高，`1 + 1 + 1` 里内层的 `1 + 1` 用门槛 2 解析，
  它看到下一个 `+`（`left = 1`），`1 < 2` 成立 → **break**，不吃。
  于是第二个 `+` 留给外层循环 → `(1+1)+1` → **左结合**。
- `^` 给 7/6：右侧门槛 6比较低，`2^3^2` 里内层 `3^2` 用门槛 6 解析，
  它看到 `^`（`left = 7`），`7 < 6` 不成立 → **继续吃** → `2^(3^2)` → **右结合**。

所以判据是：**`left < right` ⇒ 左结合，`left > right` ⇒ 右结合**。

数字只取 1/2/3/4/7 这种稀疏值，间隔故意留 2（而不是 1），
以后要插入比较运算符（优先级在 `+ -` 和 `* /` 之间）不用重排所有数字。

### 逐级展开

`+ -` → `* / %` → `^` → 一元 `-` → 括号，对应的树形（实测输出）：

```zig
// examples/33_zcalc/main.zig 第 816-837 行（33.4 分节）
    begin("33.4");
    {
        std.debug.print("每个二元运算符一对 (left,right) 优先级：\n", .{});
        inline for (.{ TokenKind.plus, .minus, .star, .slash, .percent, .caret }) |op| {
            const bp = bindingPower(op).?;
            std.debug.print("  {s: <7} left={d} right={d} ⇒ {s}\n", .{ @tagName(op), bp.left, bp.right, if (bp.left < bp.right) "左结合" else "右结合" });
        }
        std.debug.print("判据：left < right = 左结合（右侧收窄）；left > right = 右结合\n", .{});
        std.debug.print("⚠️ 数字是**相对**大小，间隔故意留 2（1/3/7），插新运算符不用重排\n", .{});
    }
    {
        for ([_][]const u8{
            "1 + 2 - 3", "1 - 2 - 3", "2 * 3 / 4",   "2 ^ 3 ^ 2",
            "2 ^ 3 * 4", "- - 5",     "(1 + 2) * 3", "2 ^ - 1",
        }) |src| {
            std.debug.print("\n{s}\n", .{src});
            dumpStmts(try parseOnly(a, src), 1);
        }
        std.debug.print("\n看形状：1 - 2 - 3 是 (left)，2 ^ 3 ^ 2 是 (right)\n", .{});
        std.debug.print("⚠️ 括号在 parsePrimary 里被丢掉：它只改树形，不进 AST\n", .{});
    }
    end("33.4");
```

运行输出（`examples/33_zcalc/main.zig`）：

```text
==== 33.4 开始 ====
每个二元运算符一对 (left,right) 优先级：
  plus    left=1 right=2 ⇒ 左结合
  minus   left=1 right=2 ⇒ 左结合
  star    left=3 right=4 ⇒ 左结合
  slash   left=3 right=4 ⇒ 左结合
  percent left=3 right=4 ⇒ 左结合
  caret   left=7 right=6 ⇒ 右结合
判据：left < right = 左结合（右侧收窄）；left > right = 右结合
⚠️ 数字是**相对**大小，间隔故意留 2（1/3/7），插新运算符不用重排

1 + 2 - 3
  expr
    binary minus
      binary plus
        num 1
        num 2
      num 3

1 - 2 - 3
  expr
    binary minus
      binary minus
        num 1
        num 2
      num 3

2 * 3 / 4
  expr
    binary slash
      binary star
        num 2
        num 3
      num 4

2 ^ 3 ^ 2
  expr
    binary caret
      num 2
      binary caret
        num 3
        num 2

2 ^ 3 * 4
  expr
    binary star
      binary caret
        num 2
        num 3
      num 4

- - 5
  expr
    unary minus
      unary minus
        num 5

(1 + 2) * 3
  expr
    binary star
      binary plus
        num 1
        num 2
      num 3

2 ^ - 1
  expr
    binary caret
      num 2
      unary minus
        num 1
==== 33.4 结束 ====
```

**逐个对照着读**：

| 源码 | 树形 | 说明 |
|---|---|---|
| `1 + 2 - 3` | `-(+(1,2),3)` | 顶层是**第二个** `-` |
| `1 - 2 - 3` | `-(-(1,2),3)` | 顶层也是第二个 `-` |
| `2 * 3 / 4` | `/(*(2,3),4)` | 顶层是第二个 `/` |
| `2 ^ 3 ^ 2` | `^(2, ^(3,2))` | 顶层是**第一个** `^`（右子树是子树） |
| `2 ^ 3 * 4` | `*(^(2,3),4)` | `^` 优先级高于 `*` |
| `- - 5` | `unary(unary(5))` | 一元负号右结合，不进 `binary` |
| `(1 + 2) * 3` | `*(+(1,2),3)` | 和不加括号时**同一棵树** |
| `2 ^ - 1` | `^(2, unary(1))` | `^` 的右操作数可以是一元表达式 |

最后两行是重点：`(1 + 2) * 3` 和 `1 + 2 * 3` 生成**完全相同**的 AST。
括号**不进树**——`parsePrimary` 遇到 `(` 就递归解析里面然后原样返回内层节点。
括号是纯语法糖，只影响树的形状，不留下任何痕迹。

---

## 33.5 AST 的 `union(enum)` 表示

AST 节点用 tagged union。三个理由，按重要性排：

**1）穷尽性是编译期保证的（最重要的理由）。**
`eval` 对 `Expr` 做 `switch`，漏掉一个 tag 就是**编译错误**。
用 struct 的话，给结构体加一个字段只是多一个字段，`switch` 不会报缺失，
新的节点类型会静默走到 `else` 分支去。

**2）必须具名。**
0.17 里匿名结构体字面量**跨函数是不同类型**。所以 AST 节点只能是顶层
`const Expr = union(enum) {...}`，不能是"每个 tag 里现写的匿名 struct"——
那样 `parsePrimary` 造出来的 `*Expr` 和 `eval` 里的就类型不匹配了。

**3）内存布局（次要理由，别夸大）。**
布局是"tag + 最大负载"。但实测差距只有 72 → 56 字节（1.28 倍），
**不值得当卖点**——AST 节点数量再多，这个常数因子也无所谓。
真正值钱的是第 1 条。

```zig
// examples/33_zcalc/main.zig 第 167-185 行（Expr 与 Stmt 定义）
/// 本章最关键的设计决定：`union(enum)` 而**不是** `struct`。
/// 1) 布局 = tag + 最大负载，不是所有字段之和（33.5 实测 @sizeOf 对比）；
/// 2) `switch` 穷尽性由编译器兜底——加了新 tag 忘改求值器是**编译错**，不是运行期静默；
/// 3) 必须**具名**（顶层 const）：0.17 里匿名结构体字面量跨函数是不同的类型。
/// 每个节点都带 pos：求值阶段（`1/0`）已离 token 流很远，没位置就指不回源码。
const Expr = union(enum) {
    num: struct { v: f64, pos: Pos },
    variable: struct { name: []const u8, pos: Pos },
    unary: struct { op: TokenKind, child: *Expr, pos: Pos },
    binary: struct { op: TokenKind, lhs: *Expr, rhs: *Expr, pos: Pos },
    call: struct { name: []const u8, args: []const *Expr, pos: Pos },
};

const Stmt = union(enum) {
    decl: struct { name: []const u8, mutable: bool, value: *Expr, pos: Pos },
    assign: struct { name: []const u8, value: *Expr, pos: Pos },
    block: struct { body: []const Stmt, pos: Pos },
    expr: *Expr,
};
```

注意 `Stmt.block` 的 `body: []const Stmt`——**自引用结构体用切片而不是指针**，
`@sizeOf(Stmt)` 因此是常数（48 字节），不会随嵌套深度膨胀。

```zig
// examples/33_zcalc/main.zig 第 840-870 行（33.5 分节）
    begin("33.5");
    {
        const ti = @typeInfo(Expr).@"union";
        std.debug.print("Expr 是 {s}，tag 类型 = {s}，{d} 个 tag：", .{ @typeName(Expr), @typeName(ti.tag_type.?), ti.field_names.len });
        inline for (ti.field_names) |f| std.debug.print(" .{s}", .{f[0..f.len]});
        std.debug.print("\n", .{});
        std.debug.print("@sizeOf(Expr) = {d}，@alignOf = {d}，tag 只占 {d} 字节\n", .{ @sizeOf(Expr), @alignOf(Expr), @sizeOf(ti.tag_type.?) });
        std.debug.print("⚠️ 0.17 里 union 的字段是三条平行数组 field_names/field_types/field_attrs，\n", .{});
        std.debug.print("   tag 字段叫 **tag_type**（不是 0.15 的 .tag）\n", .{});
    }
    {
        // 对照组：同样字段全塞进一个 struct 会多大。
        const ExprFlat = struct {
            tag: u8,
            num: f64,
            name: []const u8,
            op: TokenKind,
            lhs: ?*Expr,
            rhs: ?*Expr,
            args: ?[]const *Expr,
            pos: Pos,
        };
        // ⚠️ 72 vs 56 只差 1.28 倍——**别拿它当"省内存"的卖点**。
        // 真正的理由是下一行的穷尽性：布局差异在这个规模下无关痛痒。
        std.debug.print("对照：全字段 struct 版 @sizeOf = {d} 字节，union {d} 字节（省 {d} 字节）\n", .{ @sizeOf(ExprFlat), @sizeOf(Expr), @sizeOf(ExprFlat) - @sizeOf(Expr) });
        std.debug.print("⇒ 省内存是次要理由（1.28 倍，不值得吹）；主要理由是**穷尽性**\n", .{});
        std.debug.print("⇒ 更要紧的是穷尽性：Struct 加 tag 只是多一个字段，switch 不会报缺失\n", .{});
        std.debug.print("@sizeOf(Stmt) = {d}（块体用切片，不递归展开）\n", .{@sizeOf(Stmt)});
        std.debug.print("⚠️ 必须**具名**：0.17 里匿名结构体字面量跨函数是不同的类型\n", .{});
    }
    end("33.5");
```

运行输出（`examples/33_zcalc/main.zig`）：

```text
==== 33.5 开始 ====
Expr 是 main.Expr，tag 类型 = @typeInfo(main.Expr).@"union".tag_type.?，5 个 tag： .num .variable .unary .binary .call
@sizeOf(Expr) = 56，@alignOf = 8，tag 只占 1 字节
⚠️ 0.17 里 union 的字段是三条平行数组 field_names/field_types/field_attrs，
   tag 字段叫 **tag_type**（不是 0.15 的 .tag）
对照：全字段 struct 版 @sizeOf = 72 字节，union 56 字节（省 16 字节）
⇒ 省内存是次要理由（1.28 倍，不值得吹）；主要理由是**穷尽性**
⇒ 更要紧的是穷尽性：Struct 加 tag 只是多一个字段，switch 不会报缺失
@sizeOf(Stmt) = 48（块体用切片，不递归展开）
⚠️ 必须**具名**：0.17 里匿名结构体字面量跨函数是不同的类型
==== 33.5 结束 ====
```

⚠️ **0.17 的 `@typeInfo` 变了**：`@typeInfo(T).@"union".tag` 这个写法在 0.17
**报 `no field named 'tag'`**。新名字是 `tag_type`（`?type`），而且它和
`@"enum".tag_type` 一样是**可空**的（`union` 也可能没有 tag），
所以要写 `.tag_type.?`。字段列表走三条平行数组 `field_names` /
`field_types` / `field_attrs`（见 13 章坑位清单第 5 条）。

另外注意 `tag 只占 1 字节`：5 个 tag 在 0.17 里编码成 `u1`（不是 byte），
因为 5 ≤ 2³。33.15 有一条 test 专门钉住这个事实。

---

## 33.6 求值器（Interpreter）：树上后序遍历

`eval` 是全章最短的一段。`switch` 每个 tag，一层递归：

```zig
// examples/33_zcalc/main.zig 第 528-581 行（eval 全体）
fn eval(e: *const Expr, env: *Env, ctx: *Ctx) CalcError!f64 {
    // 求值侧深度闸门。解析侧那道管**语法**嵌套，这道管**求值递归**。
    // 两者独立：加法长链解析很浅但求值沿左脊递归 1000 层（实测，33.10）。
    if (ctx.depth >= ctx.max_depth) {
        ctx.diag.set(.{ .offset = 0, .line = 0, .col = 0 }, "求值递归超过上限", .{});
        return error.TooDeep;
    }
    ctx.depth += 1;
    defer ctx.depth -= 1;

    switch (e.*) {
        .num => |n| return n.v,
        .variable => |v| {
            const b = env.lookup(v.name) orelse {
                ctx.diag.set(v.pos, "未定义的标识符 {s}", .{v.name});
                return error.UnknownIdentifier;
            };
            return b.value;
        },
        .unary => |u| return -try eval(u.child, env, ctx),
        .binary => |b| {
            const l = try eval(b.lhs, env, ctx);
            const r = try eval(b.rhs, env, ctx);
            return switch (b.op) {
                .plus => l + r,
                .minus => l - r,
                .star => l * r,
                // f64 除零本会给 ±inf 或 NaN。解释器**选择报错**：inf 进了后续乘法
                // 会静默污染一整串结果，比当场报错难查得多。
                .slash => if (r == 0) {
                    ctx.diag.set(b.pos, "除数为 0", .{});
                    return error.DivisionByZero;
                } else l / r,
                .percent => @rem(l, r),
                .caret => std.math.pow(f64, l, r),
                else => unreachable, // bindingPower 只放行这 6 个运算符
            };
        },
        .call => |c| {
            const bi = builtinIndex(c.name) orelse {
                ctx.diag.set(c.pos, "没有这个内建函数 {s}", .{c.name});
                return error.UnknownFunction;
            };
            const b = builtin_table[bi];
            if (c.args.len != b.arity) {
                ctx.diag.set(c.pos, "内建 {s} 要 {d} 个参数，收到 {d} 个", .{ c.name, b.arity, c.args.len });
                return error.ArityMismatch;
            }
            var vals: [builtin_max_arity]f64 = undefined;
            for (c.args, 0..) |arg, i| vals[i] = try eval(arg, env, ctx);
            return b.apply(vals[0..c.args.len]);
        },
    }
}
```

四个设计取舍：

**1）`.percent` 用 `@rem` 而不是 `%`。**
f64 没有 `%` 运算符（Zig 的 `%` 只对整数）。`@rem` 是浮点余数，
`@rem(-7, 2) = -1`（符号跟被除数），`@mod` 才是非负版本。
本章不区分正负（用户写负数除法时通常想要数学余数，但那是语言设计问题）。

**2）`.caret` 走 `std.math.pow` 而不是 `std.math.pow(f64, ...)` 的简化形式。**
0.17 里 `@exp`/`^` 对 f64 不可用，必须调 `std.math.pow`。
注意 0.17 **没有 `**` 幂运算符**（13 章坑位 14）。

**3）`else => unreachable` 而不是给个默认值。**
`bindingPower` 只放行 6 个运算符，`.binary` 的 `op` 只可能是这 6 个之一。
写 `unreachable` 是让编译器帮你验证这个不变量：如果哪天往 `bindingPower`
里加了个新运算符但忘了在 `eval` 里处理，会在**这个** `unreachable` 上炸，
而不是静默算错。

**4）除零显式报错。**
f64 除零本来会给 `±inf`（`1/0`）或 `NaN`（`0/0`），IEEE-754 语义完全合法。
但解释器选择拦下来：一旦 `inf` 进了后续乘法，整串结果都变成 `inf`/`NaN`，
用户拿到最终结果时根本定位不到是**哪一步**出的事。宁可当场报错。

```zig
// examples/33_zcalc/main.zig 第 873-888 行（33.6 分节）
    begin("33.6");
    for ([_]struct { src: []const u8, note: []const u8 }{
        .{ .src = "1 + 2 * 3", .note = "优先级" },
        .{ .src = "(1 + 2) * 3", .note = "括号" },
        .{ .src = "7 / 2", .note = "f64 除法不截断" },
        .{ .src = "17 % 5", .note = "取余 @rem" },
        .{ .src = "2 ^ 10", .note = "幂走 pow" },
        .{ .src = "-4 + 10", .note = "一元负号" },
        .{ .src = "- - 5", .note = "一元右结合" },
        .{ .src = "10 / 4 + 0.5", .note = "混合" },
    }) |c| {
        std.debug.print("  {s: <12} = {d: <6}（{s}）\n", .{ c.src, try runValue(a, &env, c.src), c.note });
    }
    std.debug.print("⚠️ '/' 不截断（7/2=3.5），要整除得自己套 floor(7/2)\n", .{});
    std.debug.print("⚠️ f64 除零本可给 inf，解释器选报错：inf 会静默污染后续乘法\n", .{});
    end("33.6");
```

运行输出（`examples/33_zcalc/main.zig`）：

```text
==== 33.6 开始 ====
  1 + 2 * 3    = 7     （优先级）
  (1 + 2) * 3  = 9     （括号）
  7 / 2        = 3.5   （f64 除法不截断）
  17 % 5       = 2     （取余 @rem）
  2 ^ 10       = 1024  （幂走 pow）
  -4 + 10      = 6     （一元负号）
  - - 5        = 5     （一元右结合）
  10 / 4 + 0.5 = 3     （混合）
⚠️ '/' 不截断（7/2=3.5），要整除得自己套 floor(7/2)
⚠️ f64 除零本可给 inf，解释器选报错：inf 会静默污染后续乘法
==== 33.6 结束 ====
```

⚠️ 注意 `7 / 2 = 3.5` 而不是 `3`。值统一 f64，所以 `/` **永不截断**。
想要整数除法得自己写 `floor(7 / 2)`（见 33.8）。这是"值统一 f64"这个
取舍的直接代价——换来的是除法没有截断语义要解释（33.13 会讲这个取舍的另一半）。

---

## 33.7 变量与赋值：`let` / `var` 双模式

可变性存在**绑定**上，不在 AST 上。这是本章第二个值得单独讲的设计。

```
Binding { value: f64, mutable: bool }        ← 唯一存可变性���地方
AST: assign { name, value }                  ← 完全不知道 let 还是 var
```

于是同一棵表达式树 `x = 9`，在不同环境里语义不同：

- `let x = 5` 之后 → `Binding.mutable == false` → `assign` 报 `ImmutableBinding`
- `var y = 5` 之后 → `Binding.mutable == true` → `assign` 成功

**AST 一行代码都不用改。** 如果把可变性写进 AST（`assign { mutable: bool }`），
你就得让解析器知道每个名字是怎么声明的——那需要一个符号表，
而符号表是运行期的概念，解析器是纯语法阶段。设计上说不通。

```zig
// examples/33_zcalc/main.zig 第 891-906 行（33.7 分节）
    begin("33.7");
    {
        std.debug.print("同一行源码 \"x = 9\"，两种声明下行为不同：\n", .{});
        _ = try runProgram(a, &env, "let x = 5");
        if (runValue(a, &env, "x = 9")) |v| {
            std.debug.print("  ?? let 竟然可赋值：{d}\n", .{v});
        } else |e| std.debug.print("  let  声明后赋值 → error.{s}（树一样，语义不同）\n", .{@errorName(e)});
        _ = try runProgram(a, &env, "var y = 5");
        std.debug.print("  var   声明后赋值 → {d}（可改）\n", .{try runValue(a, &env, "y = 9")});
        _ = try runProgram(a, &env, "var z = 1");
        _ = try runProgram(a, &env, "z = z + 41");
        std.debug.print("  var   自增式累加 z = {d}（读到的是新值）\n", .{try runValue(a, &env, "z")});
        std.debug.print("⇒ 可变性存在**绑定**上（Binding.mutable），不在 AST 上\n", .{});
        std.debug.print("⇒ 同一棵树在两种环境里语义不同——AST 不需要变\n", .{});
    }
    end("33.7");
```

`assign` 的实现——注意它和 `lookup` 一样**从内向外找**，但拿到的是 `getPtr`：

```zig
// examples/33_zcalc/main.zig 第 430-440 行（Env.assign）
    fn assign(e: *Env, name: []const u8, v: f64) CalcError!void {
        var i = e.scopes.items.len;
        while (i > 0) {
            i -= 1;
            if (e.scopes.items[i].getPtr(name)) |b| {
                if (!b.mutable) return error.ImmutableBinding;
                b.value = v;
                return;
            }
        }
        return error.UnknownIdentifier;
```

运行输出（`examples/33_zcalc/main.zig`）：

```text
==== 33.7 开始 ====
同一行源码 "x = 9"，两种声明下行为不同：
  let  声明后赋值 → error.ImmutableBinding（树一样，语义不同）
  var   声明后赋值 → 9（可改）
  var   自增式累加 z = 42（读到的是新值）
⇒ 可变性存在**绑定**上（Binding.mutable），不在 AST 上
⇒ 同一棵树在两种环境里语义不同——AST 不需要变
==== 33.7 结束 ====
```

`z = z + 41` 那行值得看：右边先求值（此时 `z` 还是 1），得到 42，
再写回。**求值在前、写入在后**——`execBlock` 里就是这个顺序。
反过来（先写占位再求值）会让 `z = z + 41` 读到占位值。

---

## 33.8 内置函数与常量：comptime 表驱动

八个内建：`pi` / `e`（0 元常量）、`sqrt` / `abs` / `floor` / `ceil`（1 元）、
`min` / `max`（2 元）。三种形态，一份表：

```zig
// examples/33_zcalc/main.zig 第 479-510 行（内建表 + comptime 校验 + 派生常量）
const builtin_table = [_]Builtin{
    .{ .name = "pi", .arity = 0, .apply = biPi },
    .{ .name = "e", .arity = 0, .apply = biE },
    .{ .name = "sqrt", .arity = 1, .apply = biSqrt },
    .{ .name = "abs", .arity = 1, .apply = biAbs },
    .{ .name = "min", .arity = 2, .apply = biMin },
    .{ .name = "max", .arity = 2, .apply = biMax },
    .{ .name = "floor", .arity = 1, .apply = biFloor },
    .{ .name = "ceil", .arity = 1, .apply = biCeil },
};

// 编译期把表扫一遍：查重名、核对签名。两条断言都在**编译时**跑，一次都不进运行期。
comptime {
    for (builtin_table, 0..) |b, i| {
        for (builtin_table, 0..) |c, j| {
            if (i != j and std.mem.eql(u8, b.name, c.name)) @compileError("内建名重复: " ++ b.name);
        }
    }
    for (builtin_table) |b| {
        if (@TypeOf(b.apply) != *const fn (args: []const f64) f64) @compileError("签名不对: " ++ b.name);
    }
}

/// 表里最大元数，用**容器级求值**算出来当数组长度——求值侧的临时数组尺寸由表决定。
const builtin_max_arity: usize = blk: {
    var m: usize = 0;
    for (builtin_table) |b| {
        if (b.arity > m) m = b.arity;
    }
    break :blk m;
};
const builtin_count: usize = builtin_table.len;
```

三点值得注意：

**1）`comptime` 块里的两两查重是 O(n²) 但 n=8，且只在编译期跑。**
这条不变量（"表里不能有重名"）如果放到运行期，就是一次白费的扫描；
放编译期，它变成"改错了编不过"。`@compileError` 是这里的终止条件。

**2）`builtin_max_arity` 用容器级 `blk:` 表达式算出来，然后当数组长度用。**

```zig
// examples/33_zcalc/main.zig 第 576-576 行（eval 里按表算出的上限开数组）
            var vals: [builtin_max_arity]f64 = undefined;
```

求值侧的临时数组尺寸**由表决定**，不是硬编码的 `2`。
将来加一个 3 元内建，这行和 `biMax` 都不用动——`builtin_max_arity` 自动变成 3。

**3）0 元常量 `pi` 的语法糖在解析器里。**
`pi`（无括号）和 `pi()` 都合法，两者都归一成"`.call` 标签 + 空 args"：

```zig
// examples/33_zcalc/main.zig 第 370-377 行（parsePrimary 里的 0 元常量处理）
                // 0 元内建（pi / e）写成"无括号调用"：语法上多一种形态，
                // 求值器却完全不用改——同一个 `.call` 标签，args 为空。
                if (builtinIndex(t.text)) |bi| {
                    if (builtin_table[bi].arity == 0) {
                        const none: []const *Expr = &.{};
                        return p.alloc(.{ .call = .{ .name = t.text, .args = none, .pos = t.pos } });
                    }
                }
```

于是求值器**完全不需要**"常量"这个概念——它只看到 `.call`，
查表、校验 arity（0 == 0）、调用 `biPi`。语法糖在解析期化掉，
运行期零成本。

```zig
// examples/33_zcalc/main.zig 第 909-927 行（33.8 分节）
    begin("33.8");
    std.debug.print("内建表 {d} 项，最大元数 {d}（容器级 comptime 算出来当数组长度）：\n", .{ builtin_count, builtin_max_arity });
    inline for (builtin_table, 0..) |b, i| {
        std.debug.print("  [{d}] {s: <6} arity={d}\n", .{ i, b.name, b.arity });
    }
    std.debug.print("comptime 块已验证：名字不重复、apply 签名一致（编译期就跑完了）\n", .{});
    for ([_][]const u8{
        "pi",        "e",            "sqrt(2)",     "abs(0 - 7)", "min(3, 7)",
        "max(3, 7)", "floor(7 / 2)", "ceil(7 / 2)", "pi()",       "sqrt(2) * sqrt(2)",
    }) |src| {
        std.debug.print("  {s: <20} = {d}\n", .{ src, try runValue(a, &env, src) });
    }
    std.debug.print("⚠️ pi/e 是 0 元：写 pi 和 pi() 都行，解析器都归一成 .call + 空 args\n", .{});
    for ([_][]const u8{ "sqrt(1, 2)", "sqrt()", "nosuch(1)" }) |src| {
        if (runValue(a, &env, src)) |v| {
            std.debug.print("  {s: <14} → ?? 竟然成功 {d}\n", .{ src, v });
        } else |e| std.debug.print("  {s: <14} → error.{s}\n", .{ src, @errorName(e) });
    }
    end("33.8");
```

运行输出（`examples/33_zcalc/main.zig`）：

```text
==== 33.8 开始 ====
内建表 8 项，最大元数 2（容器级 comptime 算出来当数组长度）：
  [0] pi     arity=0
  [1] e      arity=0
  [2] sqrt   arity=1
  [3] abs    arity=1
  [4] min    arity=2
  [5] max    arity=2
  [6] floor  arity=1
  [7] ceil   arity=1
comptime 块已验证：名字不重复、apply 签名一致（编译期就跑完了）
  pi                   = 3.141592653589793
  e                    = 2.718281828459045
  sqrt(2)              = 1.4142135623730951
  abs(0 - 7)           = 7
  min(3, 7)            = 3
  max(3, 7)            = 7
  floor(7 / 2)         = 3
  ceil(7 / 2)          = 4
  pi()                 = 3.141592653589793
  sqrt(2) * sqrt(2)    = 2.0000000000000004
⚠️ pi/e 是 0 元：写 pi 和 pi() 都行，解析器都归一成 .call + 空 args
  sqrt(1, 2)     → error.ArityMismatch
  sqrt()         → error.ArityMismatch
  nosuch(1)      → error.UnknownFunction
==== 33.8 结束 ====
```

⚠️ 最后一行 `sqrt(2) * sqrt(2) = 2.0000000000000004`——**不是 2**。
这是 33.15 里那条"浮点断言必须带容差"的由来。`expectApproxEqAbs(2, v, 1e-9)`
过，但 `expectEqual(2, v)` 不过。33.15 有一条 test 专门断言 `v != 2.0`
把这个事实钉住，免得有人后来"顺手改成 expectEqual"。

---

## 33.9 错误处理：错误集设计 + 带位置的旁路

九个错误，按产生的阶段分组：

| 错误 | 阶段 | 触发条件 |
|---|---|---|
| `BadChar` | 词法 | 遇到不认识的字符 |
| `SyntaxError` | 语法 | 记号序列不符合文法 |
| `TooDeep` | 语法/求值 | 嵌套或递归超上限 |
| `UnknownIdentifier` | 求值 | 变量没声明 |
| `UnknownFunction` | 求值 | 内建表里没这个名 |
| `ArityMismatch` | 求值 | 实参与内建表的 arity 不符 |
| `ImmutableBinding` | 求值 | 给 `let` 绑定的赋值 |
| `DivisionByZero` | 求值 | 除数为 0 |
| `OutOfMemory` | 贯穿 | arena 分配失败 |

```zig
// examples/33_zcalc/main.zig 第 50-60 行（错误集）
const CalcError = error{
    BadChar,
    SyntaxError,
    DivisionByZero,
    UnknownIdentifier,
    UnknownFunction,
    ArityMismatch,
    ImmutableBinding,
    TooDeep,
    OutOfMemory,
};
```

### 为什么位置必须走旁路

**Zig 的错误集不能携带数据。** `error{...}` 的成员是无值枚举，
`error.DivisionByZero` 就是 `error.DivisionByZero`，没法往里塞 `(line, col)`。
想把位置带上去只有两条路：

1. 把错误类型做成结构体（`const CalcError = error{...}` 变成
   `const CalcError = union(enum) { DivisionByZero: struct { pos: Pos }, ... }`）——
   但那样它就不是错误联合了，`try` / `catch` / `expectError` 全部失效。
2. **旁路**：错误集只管控制流，位置和文案走一个可写的 `*Diag`。

本章选 2。这是 Zig 里做诊断的**标准姿势**（编译器自己也是这么干的）：
`try` 负责"往上抛"，`Diag` 负责"我已经知道错在哪了"。

```zig
// examples/33_zcalc/main.zig 第 62-79 行（Diag）
/// 诊断与错误**分离**：错误集负责控制流（可 `try` 传播、可 `expectError` 断言），
/// 位置与文案走 `Diag` 旁路。混在一起就没法既传播又报位置。
///
/// ⚠️ 0.17 坑一：文案不能写 `"a" ++ @tagName(x)`——`++` 要求两侧都是**编译期已知**切片，
/// 右边是运行期值就报 `slice being concatenated must be comptime-known`。正解是 bufPrint。
/// ⚠️ 0.17 坑二：doc 注释（///）不能挂在 `comptime {}` 块上，必须用 //。
const Diag = struct {
    pos: Pos = .{ .offset = 0, .line = 0, .col = 0 },
    msg: []const u8 = "",
    buf: [192]u8 = undefined,

    fn set(d: *Diag, pos: Pos, comptime fmt: []const u8, args: anytype) void {
        d.pos = pos;
        // bufPrint 失败只可能是格式串写坏了（args 与占位符不匹配），那属于编程错误，
        // 宁可截断也不能让诊断路径变成新的崩溃源。
        d.msg = std.fmt.bufPrint(&d.buf, fmt, args) catch "诊断信息过长";
    }
};
```

⚠️ **`++` 不能用于运行期切片**（本章踩过两次）。最初写的是

```zig
p.diag.set(t.pos, "此处应为 " ++ @tagName(kind) ++ "，实际是 " ++ @tagName(t.kind));
```

`@tagName` 返回运行期切片，`++` 直接报
`slice being concatenated must be comptime-known`。正解是 `bufPrint`——
`set` 的签名把 `fmt` 声明成 `comptime`（格式串必须编译期已知，这是格式化器的要求），
参数走 `anytype`（可以是运行期值）。

⚠️ **`Ctx.diag` 必须是指针**（本章最贵的 bug）。最初写的是 `diag: Diag`（值），
于是 `set` 写的是 `ctx.diag.buf`，而 `ctx.diag.msg` 指向 `ctx.diag.buf` 内部——
这没问题。问题出在**回写**：

```zig
// ❌ 本章最初的样子（已修）：errdefer 回写会留下悬空切片
    var ctx: Ctx = .{ .diag = diag.*, .max_depth = max_depth };  // 值拷贝
    errdefer diag.* = ctx.diag;    // 把 msg（指向 ctx.diag.buf）拷进 diag
    const out = try execBlock(stmts, env, &ctx);
    diag.* = ctx.diag;
    return out;
```

`diag.* = ctx.diag` 复制了 `buf` 的**内容**，但 `msg` 字段仍然指向
`ctx.diag.buf`——那是 `runProgramDiag` 栈帧上的临时。函数一返回，
`report` 读到的就是垃圾。实测症状：`位置 1:4  ⟨乱码⟩`（位置对，文案乱）。

改成指针就干净了，回写代码整个不需要：

```zig
// examples/33_zcalc/main.zig 第 610-623 行（runProgramDiag，正确版本）
/// 解析与求值**共用同一个** Diag（都是指针），所以任何一层失败位置都已落在
/// 调用方持有的 diag 里，不需要 errdefer 回写（回写反而是 `msg` 悬空的来源）。
fn runProgramDiag(
    a: std.mem.Allocator,
    env: *Env,
    src: []const u8,
    diag: *Diag,
    max_depth: u32,
) CalcError!?f64 {
    var p: Parser = .{ .toks = try lex(a, src, diag), .a = a, .diag = diag, .max_depth = max_depth };
    const stmts = try p.parseProgram();
    var ctx: Ctx = .{ .diag = diag, .max_depth = max_depth };
    return execBlock(stmts, env, &ctx);
}
```

```zig
// examples/33_zcalc/main.zig 第 519-526 行（Ctx）
/// 求值上下文。`diag` 必须是**指针**而非 `Diag` 值：Diag 里 `msg` 指向自己 `buf`
/// 的内部，按值拷贝会让 `msg` 指向**旧对象**的缓冲区，旧对象一返回读到的就是
/// 垃圾字节（实测 33.3 曾打出 `位置 1:4 ⟨乱码⟩`）。指针让所有递归层共享同一块缓冲。
const Ctx = struct {
    diag: *Diag,
    depth: u32 = 0,
    max_depth: u32 = default_max_depth,
};
```

⚠️ 还有一个相关的坑：`runProgram` 返回 **`!?f64`**（错误联合套可选）。
于是 `if (runProgram(..)) |v|` 捕获到的 `v` 是 `?f64` 而不是 `f64`，
拿去 `{d}` 打印就报 `invalid format string 'd' for type '?f64'`。
本章加了一个压平辅助函数：

```zig
// examples/33_zcalc/main.zig 第 630-635 行（runValue）
/// 把 `!?f64` 压平成 `!f64`。⚠️ 不做这层转换的话，`if (runProgram(..)) |v|`
/// 捕获到的 v 是 **?f64 而不是 f64**，拿去 `{d}` 打印就报
/// "invalid format string 'd' for type '?f64'"（实测踩过）。
fn runValue(a: std.mem.Allocator, env: *Env, src: []const u8) (CalcError || error{NoValue})!f64 {
    return (try runProgram(a, env, src)) orelse error.NoValue;
}
```

传播链和实测：

```zig
// examples/33_zcalc/main.zig 第 930-954 行（33.9 分节）
    begin("33.9");
    {
        std.debug.print("错误集共 {d} 个成员：", .{@typeInfo(CalcError).error_set.error_names.?.len});
        inline for (@typeInfo(CalcError).error_set.error_names.?) |en| {
            std.debug.print(" {s}", .{en[0..en.len]});
        }
        std.debug.print("\n词法 BadChar │语法 SyntaxError/TooDeep │求值其余 6 个\n", .{});
    }
    for ([_][]const u8{
        "1 $ 2", "1 +", "1 2", "(1", "nosuch(1)", "q + 1", "1 / 0", "sqrt(1, 2)",
    }) |src| {
        var diag: Diag = .{};
        if (runProgramDiag(a, &env, src, &diag, default_max_depth)) |_| {
            std.debug.print("  {s: <12} → ?? 成功\n", .{src});
        } else |e| std.debug.print("  {s: <12} → error.{s} @ {d}:{d}\n", .{ src, @errorName(e), diag.pos.line, diag.pos.col });
    }
    std.debug.print("\n传播链：lex → parseProgram → parseExpr → eval → execBlock → runProgram\n", .{});
    std.debug.print("每层都是 try，位置靠 &Diag 旁路携带（错误值本身不带数据）\n", .{});
    std.debug.print("⚠️ 错误值放不进错误集 ⇒ 想带位置只能旁路，这是 Zig 的硬约束\n", .{});
    report("sqrt(1, 2)", blk: {
        var d: Diag = .{};
        _ = runProgramDiag(a, &env, "sqrt(1, 2)", &d, default_max_depth) catch {};
        break :blk d;
    });
    end("33.9");
```

运行输出（`examples/33_zcalc/main.zig`）：

```text
==== 33.9 开始 ====
错误集共 9 个成员： OutOfMemory DivisionByZero BadChar SyntaxError UnknownIdentifier UnknownFunction ArityMismatch ImmutableBinding TooDeep
词法 BadChar │语法 SyntaxError/TooDeep │求值其余 6 个
  1 $ 2        → error.BadChar @ 1:3
  1 +          → error.SyntaxError @ 1:4
  1 2          → error.SyntaxError @ 1:3
  (1           → error.SyntaxError @ 1:3
  nosuch(1)    → error.UnknownFunction @ 1:1
  q + 1        → error.UnknownIdentifier @ 1:1
  1 / 0        → error.DivisionByZero @ 1:3
  sqrt(1, 2)   → error.ArityMismatch @ 1:1

传播链：lex → parseProgram → parseExpr → eval → execBlock → runProgram
每层都是 try，位置靠 &Diag 旁路携带（错误值本身不带数据）
⚠️ 错误值放不进错误集 ⇒ 想带位置只能旁路，这是 Zig 的硬约束
    位置 1:1  内建 sqrt 要 1 个参数，收到 2 个
    | sqrt(1, 2)
    | ^
==== 33.9 结束 ====
```

⚠️ 错误集成员**打印顺序不是声明顺序**——`OutOfMemory` 排在最前，
`TooDeep` 排在最后。Zig 对错误集内部的存储顺序不做保证，所以本章的
`inline for` 是照实际输出断言的，不要想当然按声明顺序写测试。

八个错误位置全部非零，而且都指向正确的格子。逐个核对：

| 源码 | 位置 | 指向 |
|---|---|---|
| `1 $ 2` | 1:3 | `$` 本身（第 3 格） |
| `1 +` | 1:4 | `+` 之后（eof 位置） |
| `1 2` | 1:3 | 多出来的 `2` |
| `(1` | 1:3 | 缺 `)`，peek 到了 eof |
| `nosuch(1)` | 1:1 | 函数名 `nosuch` |
| `q + 1` | 1:1 | 变量 `q` |
| `1 / 0` | 1:3 | `/` 运算符 |
| `sqrt(1, 2)` | 1:1 | 函数名 `sqrt` |

---

## 33.10 防止栈溢出：两道闸门

**Zig 不检查栈。** 没有栈保护 canary，没有 guard page 手动映射，
递归写深了就是段错误。这不是缺陷——可预测的崩溃比隐式检查便宜——
但它意味着**解释器必须自己数深度**。

本章用实测证明了一件反直觉的事：**解析深度和求值深度是两个独立的量**。
一道闸门不够。

```plain
  括号嵌套 200 层
    词法   线性，1 层
    解析   parseExpr 递归 200 层  ← 解析期就撞闸门
    求值   （根本没走到）

  加法长链 1+1+...+1（1000 项）
    词法   线性，1 层
    解析   parseBinary 是 while 循环，递归恒 1 层  ← 解析期不撞
    求值   沿左脊递归 1000 层  ← 求值期撞闸门

  幂长链 2^2^2^...（100 项）
    词法   线性，1 层
    解析   parseBinary 递归 100 层  ← 解析期撞
    求值   （没走到）
```

解析侧的闸门装在 `parseExpr`（每进入一层嵌套表达式 +1）：

```zig
// examples/33_zcalc/main.zig 第 307-317 行（parseExpr 与 parseBinary 的深度闸门）
    /// 嵌套深度闸门：进入一层嵌套表达式 +1，退出 -1。
    /// 这是解释器唯一能挡住栈溢出的手段——Zig 本身不检查栈（见 33.10）。
    fn parseExpr(p: *Parser) CalcError!*Expr {
        if (p.depth >= p.max_depth) {
            p.diag.set(p.peek().pos, "括号/调用嵌套超过上限", .{});
            return error.TooDeep;
        }
        p.depth += 1;
        defer p.depth -= 1;
        return p.parseBinary(0);
    }
```

求值侧的闸门装在 `eval` 入口（见 33.6 的源码）。两道闸门各自独立计数，
因为它们量的不是同一个东西。

```zig
// examples/33_zcalc/main.zig 第 957-1017 行（33.10 分节）
    begin("33.10");
    {
        // 括号嵌套：**解析阶段**就撞闸门。
        for ([_]u32{ 8, 40, 200 }) |n| {
            const wrapped = try a.alloc(u8, n * 2 + 1);
            for (0..n) |k| {
                wrapped[k] = '(';
                wrapped[wrapped.len - 1 - k] = ')';
            }
            wrapped[n] = '1';
            var diag: Diag = .{};
            if (runProgramDiag(a, &env, wrapped, &diag, default_max_depth)) |v| {
                std.debug.print("  括号嵌套 {d: <3} 层 → 成功 {d}\n", .{ n, v orelse 0 });
            } else |e| std.debug.print("  括号嵌套 {d: <3} 层 → error.{s}（上限 {d}，{s}）\n", .{ n, @errorName(e), default_max_depth, diag.msg });
        }
        // 加法长链：解析**很浅**（同级由 while 消化，递归恒 1 层），
        // 但求值**沿左脊递归** ⇒ 换一道闸门才拦得住。解析浅 ≠ 求值浅。
        var chain: std.ArrayList(u8) = .empty;
        try chain.appendSlice(a, "1");
        for (0..999) |_| try chain.appendSlice(a, " + 1");
        {
            var diag: Diag = .{};
            var p: Parser = .{ .toks = try lex(a, chain.items, null), .a = a, .diag = &diag };
            if (p.parseProgram()) |stmts| {
                std.debug.print("  加法长链 1000 项 →解析 OK（{d} 条语句，深度计数回落 {d}）\n", .{ stmts.len, p.depth });
            } else |e| std.debug.print("  加法长链 →解析 error.{s}\n", .{@errorName(e)});
        }
        {
            var diag: Diag = .{};
            if (runProgramDiag(a, &env, chain.items, &diag, default_max_depth)) |_| {
                std.debug.print("  同一条链求值 → ?? 竟然成功\n", .{});
            } else |e| std.debug.print("  同一条链求值 → error.{s}（{s}）\n", .{ @errorName(e), diag.msg });
        }
        var short: std.ArrayList(u8) = .empty;
        try short.appendSlice(a, "1");
        for (0..30) |_| try short.appendSlice(a, " + 1");
        std.debug.print("  加法短链 31 项 → {d}（两道闸门都不触发）\n", .{try runValue(a, &env, short.items)});
        // 幂长链：右结合 ⇒ parseBinary 自己就递归，解析期就拦住
        var pow: std.ArrayList(u8) = .empty;
        try pow.appendSlice(a, "2");
        for (0..99) |_| try pow.appendSlice(a, " ^ 2");
        var diag3: Diag = .{};
        if (runProgramDiag(a, &env, pow.items, &diag3, default_max_depth)) |_| {
            std.debug.print("  幂长链 100 项 → ?? 竟然成功\n", .{});
        } else |e| std.debug.print("  幂长链 100 项 → error.{s}（右结合 = 解析期真递归）\n", .{@errorName(e)});
        std.debug.print("⚠️ Zig **不检查栈**：没有 canary，递归写深了直接段错误\n", .{});
    }
    {
        // 自举子进程：真的把栈写穿，看宿主给什么
        const gpa = init.gpa;
        const self = try std.process.executablePathAlloc(init.io, gpa);
        defer gpa.free(self);
        const r = try std.process.run(gpa, init.io, .{ .argv = &.{ self, "probe-stack" } });
        defer {
            gpa.free(r.stdout);
            gpa.free(r.stderr);
        }
        std.debug.print("  子进程无界递归 → term={f}，success={}，stderr 报段错误={}\n", .{ r.term, r.term.success(), std.mem.indexOf(u8, r.stderr, "Segmentation fault") != null });
        std.debug.print("  ⇒ 深度必须**自己数**（两道闸门），不能靠宿主报错\n", .{});
    }
    end("33.10");
```

运行输出（`examples/33_zcalc/main.zig`）：

```text
==== 33.10 开始 ====
  括号嵌套 8   层 → 成功 1
  括号嵌套 40  层 → 成功 1
  括号嵌套 200 层 → error.TooDeep（上限 64，括号/调用嵌套超过上限）
  加法长链 1000 项 →解析 OK（1 条语句，深度计数回落 0）
  同一条链求值 → error.TooDeep（求值递归超过上限）
  加法短链 31 项 → 31（两道闸门都不触发）
  幂长链 100 项 → error.TooDeep（右结合 = 解析期真递归）
⚠️ Zig **不检查栈**：没有 canary，递归写深了直接段错误
  子进程无界递归 → term=terminated with signal ABRT，success=false，stderr 报段错误=true
  ⇒ 深度必须**自己数**（两道闸门），不能靠宿主报错
==== 33.10 结束 ====
```

### 最后两行：自举子进程实测段错误

光说"Zig 不检查栈"是空话。本章让程序**把自己再跑一遍**，
只不过带一个 `probe-stack` 参数，那条路径直接无界递归：

```zig
// examples/33_zcalc/main.zig 第 721-731 行（三个探针函数）
fn probeMul(a: i64, b: i64) i64 {
    return a * b; // Debug/ReleaseSafe：溢出 panic；ReleaseFast：静默回绕
}
fn probeRecurse(n: u32) u32 {
    if (n == 0) return 0;
    return 1 + probeRecurse(n - 1); // Zig **不检查栈**：一路下探到碰栈顶
}
fn unsafedMul(a: u8, b: u8) u8 {
    @setRuntimeSafety(false); // 局部关掉溢出检查 = ReleaseFast 对这条指令的待遇
    return a * b;
}
```

`probeRecurse` 的栈溢出**不是干净的段错误**——Zig 的运行时在 `start.zig`
里查到了信号，打印一长串栈回溯后 `abort()`。所以 `term` 是
`terminated with signal ABRT` 而不是 `SEGV`，但 `stderr` 里有
`Segmentation fault at address 0x7ff...` 字样。两种都算"宿主杀了你"。

⚠️ 这个自举模式有个**顺序陷阱**：`main` 开头必须先扫 `args` 里的
`probe-*`，命中就直接 `return`。否则父进程跑完 33.14 之后还会 fork 一个子进程，
子进程又 fork……本章第一版把 `probe-*` 判断写在 `main` 末尾，
结果子进程自己又去跑 33.1~33.14，输出多出一大坨。

---

## 33.11 变量遮蔽与作用域

遮蔽（shadowing）是词法作用域的**全部**内容，Zig 语言层面零特殊支持。
本例子的实现只有两个动作：

- `declare`：写进**栈顶**作用域
- `lookup` / `assign`：**从栈顶往回找**，先命中先用

```zig
// examples/33_zcalc/main.zig 第 415-429 行（declare 与 lookup）
    fn declare(e: *Env, name: []const u8, v: f64, mutable: bool) std.mem.Allocator.Error!void {
        // 名字必须 dupe：REPL 里每行是独立的 Reader 缓冲，不 dupe 会指向已被复用的内存。
        const key = try e.a.dupe(u8, name);
        const top = &e.scopes.items[e.scopes.items.len - 1];
        try top.put(e.a, key, .{ .value = v, .mutable = mutable });
    }
    /// 从**内**向外找：内层同名遮蔽外层，这是词法作用域的全部含义。
    fn lookup(e: *Env, name: []const u8) ?Binding {
        var i = e.scopes.items.len;
        while (i > 0) {
            i -= 1;
            if (e.scopes.items[i].get(name)) |b| return b;
        }
        return null;
    }
```

⚠️ **出作用域靠 `pop()`，不靠逐个 `free`。** 块里的绑定（键和槽）
都从 arena 分配，`pop()` 只是把 `ArrayList` 长度减一。
这对手写的不规则树结构是标准姿势：AST 节点、环境键、临时缓冲全喂一个 arena，
`deinit` 一次全清。逐节点 `free` 等于给自己埋雷（谁负责释放子树？共享的子树 free 几次？）。

```zig
// examples/33_zcalc/main.zig 第 408-414 行（push / pop 与出作用域的取舍）
    fn push(e: *Env) std.mem.Allocator.Error!void {
        try e.scopes.append(e.a, .empty);
    }
    /// 出作用域靠**弹栈**，不逐个 free。块里的绑定随 arena 一起走。
    fn pop(e: *Env) void {
        _ = e.scopes.pop();
    }
```

`execBlock` 里 `.block` 那条腿就是 push/pop 的全部：

```zig
// examples/33_zcalc/main.zig 第 600-604 行（execBlock 全体）
            .block => |b| {
                try env.push();
                defer env.pop();
                last = try execBlock(b.body, env, ctx);
            },
```

```zig
// examples/33_zcalc/main.zig 第 1020-1037 行（33.11 分节）
    begin("33.11");
    {
        _ = try runProgram(a, &env, "var x = 1");
        std.debug.print("  var x = 1              → x = {d}\n", .{try runValue(a, &env, "x")});
        std.debug.print("  {{ var x = 2; x * 10 }} → {d}（块内看到内层 x）\n", .{try runValue(a, &env, "{ var x = 2; x * 10 }")});
        std.debug.print("  块结束后 x = {d}（外层完好——弹栈而非覆盖）\n", .{try runValue(a, &env, "x")});
        // ⚠️ 名字要用**别处没声明过**的：33.7 已经在全局作用域留了 `var y = 9`，
        //    这里再读 y 会命中那个（外层）绑定，演示不出"出了作用域就没了"。
        std.debug.print("  块内定义的 t 在块内 = {d}\n", .{try runValue(a, &env, "{ var t = 7; t }")});
        if (runValue(a, &env, "t")) |v| {
            std.debug.print("  ?? 块外的 t 竟然 = {d}\n", .{v});
        } else |e| std.debug.print("  块外读 t → error.{s}（出了作用域就没了）\n", .{@errorName(e)});
        std.debug.print("  块内改内层 x = {d}，外层不受影响\n", .{try runValue(a, &env, "{ var x = 3; x = 4; x }")});
        std.debug.print("  外层 x 仍是 {d}\n", .{try runValue(a, &env, "x")});
        std.debug.print("⇒ 遮蔽 = 作用域栈：declare 写栈顶，lookup 从栈顶往回找\n", .{});
        std.debug.print("⇒ 恢复 = pop()，不 free——块里的键随 arena 一起回收\n", .{});
    }
    end("33.11");
```

运行输出（`examples/33_zcalc/main.zig`）：

```text
==== 33.11 开始 ====
  var x = 1              → x = 1
  { var x = 2; x * 10 } → 20（块内看到内层 x）
  块结束后 x = 1（外层完好——弹栈而非覆盖）
  块内定义的 t 在块内 = 7
  块外读 t → error.UnknownIdentifier（出了作用域就没了）
  块内改内层 x = 4，外层不受影响
  外层 x 仍是 1
⇒ 遮蔽 = 作用域栈：declare 写栈顶，lookup 从栈顶往回找
⇒ 恢复 = pop()，不 free——块里的键随 arena 一起回收
==== 33.11 结束 ====
```

⚠️ 那条 `⚠️ 名字要用别处没声明过的` 注释是**实测踩出来的**。
本节第一版用 `y` 做例子，结果输出是 `?? 块外的 y 竟然 = 9`——
因为 33.7 在全局作用域留了 `var y = 5; y = 9`，而 33.11 的所有分节
共享同一个 `env`（`main` 里只 push 了一次全局作用域）。
读 `y` 时从栈顶往回找，命中的是**外层**那个 9，演示不出"出作用域就没了"。

这不是 bug，是作用域栈在正确工作——但它是个**演示陷阱**：
想演示"出作用域后不可见"，必须用一个**全局从没声明过**的名字。
换成 `t` 之后输出才正确。

---

## 33.12 运算符优先级与结合性的表格化验证

前面 33.4 用树形图**定性**论证了优先级表对不对。
33.12 换一种方式：把每个优先级/结合性组合各跑一遍，用**运行结果反证**表是对的。

12 条用例，覆盖 6 类组合：

| # | 源码 | 期望 | 验证的规则 |
|---|---|---|---|
| 1 | `1 + 2 * 3` | 7 | `*` 优先于 `+` |
| 2 | `(1 + 2) * 3` | 9 | 括号改序 |
| 3 | `10 - 3 - 2` | 5 | `-` 左结合 |
| 4 | `100 / 10 / 5` | 2 | `/` 左结合 |
| 5 | `17 % 5 - 1` | 1 | `%` 与 `* /` 同级 |
| 6 | `2 ^ 3 ^ 2` | 512 | `^` 右结合（512 而非 64） |
| 7 | `2 ^ 2 ^ 3` | 256 | `^` 右结合再验一次 |
| 8 | `2 ^ 3 * 4` | 32 | `^` 优先于 `*` |
| 9 | `-4 + 10` | 6 | 一元负号最松 |
| 10 | `- - 5` | 5 | 一元右结合 |
| 11 | `1 - 2 + 3` | 2 | `+ -` 同级，左结合 |
| 12 | `8 / 4 * 2` | 4 | `* /` 同级，左结合 |

第 6 条是右结合的**判决性证据**：左结合会算成 `(2^3)^2 = 64`，
右结合是 `2^(3^2) = 512`。512 这个数字只能由右结合产生。
第 3、4、11、12 条同理，左结合的结果和右结合不同（如 `10-3-2` 左结合是 5，
右结合会是 9）。

```zig
// examples/33_zcalc/main.zig 第 1040-1067 行（33.12 分节）
    begin("33.12");
    {
        const Case = struct { src: []const u8, want: f64, note: []const u8 };
        const cases = [_]Case{
            .{ .src = "1 + 2 * 3", .want = 7, .note = "乘法紧" },
            .{ .src = "(1 + 2) * 3", .want = 9, .note = "括号改序" },
            .{ .src = "10 - 3 - 2", .want = 5, .note = "减法左结合" },
            .{ .src = "100 / 10 / 5", .want = 2, .note = "除法左结合" },
            .{ .src = "17 % 5 - 1", .want = 1, .note = "取余同级" },
            .{ .src = "2 ^ 3 ^ 2", .want = 512, .note = "幂右结合" },
            .{ .src = "2 ^ 2 ^ 3", .want = 256, .note = "幂右结合再验" },
            .{ .src = "2 ^ 3 * 4", .want = 32, .note = "幂比乘紧" },
            .{ .src = "-4 + 10", .want = 6, .note = "一元负号最松" },
            .{ .src = "- - 5", .want = 5, .note = "一元右结合" },
            .{ .src = "1 - 2 + 3", .want = 2, .note = "加减同级左" },
            .{ .src = "8 / 4 * 2", .want = 4, .note = "乘除同级左" },
        };
        std.debug.print("每行都跑一遍，用结果反证 (left,right) 表是对的：\n", .{});
        var pass: usize = 0;
        for (cases) |c| {
            const got = try runValue(a, &env, c.src);
            const ok = @abs(got - c.want) < 1e-9;
            if (ok) pass += 1;
            std.debug.print("  {s: <13} = {d: <6} 期望 {d: <6} {s}  {s}\n", .{ c.src, got, c.want, if (ok) "OK" else "FAIL", c.note });
        }
        std.debug.print("=> {d}/{d} 通过\n", .{ pass, cases.len });
    }
    end("33.12");
```

运行输出（`examples/33_zcalc/main.zig`）：

```text
==== 33.12 开始 ====
每行都跑一遍，用结果反证 (left,right) 表是对的：
  1 + 2 * 3     = 7      期望 7      OK  乘法紧
  (1 + 2) * 3   = 9      期望 9      OK  括号改序
  10 - 3 - 2    = 5      期望 5      OK  减法左结合
  100 / 10 / 5  = 2      期望 2      OK  除法左结合
  17 % 5 - 1    = 1      期望 1      OK  取余同级
  2 ^ 3 ^ 2     = 512    期望 512    OK  幂右结合
  2 ^ 2 ^ 3     = 256    期望 256    OK  幂右结合再验
  2 ^ 3 * 4     = 32     期望 32     OK  幂比乘紧
  -4 + 10       = 6      期望 6      OK  一元负号最松
  - - 5         = 5      期望 5      OK  一元右结合
  1 - 2 + 3     = 2      期望 2      OK  加减同级左
  8 / 4 * 2     = 4      期望 4      OK  乘除同级左
=> 12/12 通过
==== 33.12 结束 ====
```

这个"表格化验证"的价值在**测试里复用**。33.15 的表驱动测试
（`inline for` 跑用例表）用的是同一批用例的精简版——
演示和测试共享真相，改一处两处都跟着变。

---

## 33.13 边界与溢出：三模式差异

先回答那个问题：**`i64` 乘以 `i64` 会溢出吗？**

**会。而且在 Debug 下直接 panic。**

```zig
// examples/33_zcalc/main.zig 第 1070-1102 行（33.13 分节）
    begin("33.13");
    std.debug.print("本次构建 mode = {s}\n", .{@tagName(builtin.mode)});
    {
        // 算术结果**永不宽化**：u8 + u8 还是 u8。
        comptime {
            if (@TypeOf(@as(u8, 1) + @as(u8, 2)) != u8) @compileError("u8 加法被宽化了");
            if (@TypeOf(@as(i64, 1) * @as(i64, 2)) != i64) @compileError("i64 乘法被宽化了");
        }
        std.debug.print(" comptime 断言：u8+u8 是 u8，i64*i64 是 i64（**无隐式提升**）\n", .{});
        std.debug.print(" @sizeOf(u8)={d} @sizeOf(i64)={d} ⇒ 要提升就显式 @as / @intCast\n", .{ @sizeOf(u8), @sizeOf(i64) });
        const r = @mulWithOverflow(std.math.maxInt(i64), @as(i64, 2));
        std.debug.print(" @mulWithOverflow(maxInt(i64), 2) → 溢出标志 = {d}（0/1，不是 bool）\n", .{r[1]});
        const s = @addWithOverflow(@as(i64, 1) << 62, @as(i64, 1) << 62);
        std.debug.print(" @addWithOverflow(2^62, 2^62)     → 溢出标志 = {d}\n", .{s[1]});
        std.debug.print(" ⇒ 想要'溢出即错'就别裸乘，走 *WithOverflow 自己判\n", .{});
        std.debug.print(" @setRuntimeSafety(false) 下 200*200 = {d}（u8 回绕）\n", .{unsafedMul(200, 200)});
        std.debug.print(" 三模式：Debug/ReleaseSafe 溢出 panic；ReleaseFast 静默回绕\n", .{});
    }
    {
        // 真 panic 只能在子进程里看：它会带走整个进程。
        const gpa = init.gpa;
        const self = try std.process.executablePathAlloc(init.io, gpa);
        defer gpa.free(self);
        const r = try std.process.run(gpa, init.io, .{ .argv = &.{ self, "probe-overflow" } });
        defer {
            gpa.free(r.stdout);
            gpa.free(r.stderr);
        }
        std.debug.print(" 子进程 i64 溢出 → term={f}，success={}，stderr 有 panic={}\n", .{ r.term, r.term.success(), std.mem.indexOf(u8, r.stderr, "panic") != null });
        std.debug.print(" ⇒ 用 f64 存值正是躲这个：f64 溢出给 inf，不 panic\n", .{});
        std.debug.print(" ⚠️ 但 inf/NaN 会静默传播，所以除零我们选**报错**\n", .{});
    }
    end("33.13");
```

运行输出（`examples/33_zcalc/main.zig`）：

```text
==== 33.13 开始 ====
本次构建 mode = debug
 comptime 断言：u8+u8 是 u8，i64*i64 是 i64（**无隐式提升**）
 @sizeOf(u8)=1 @sizeOf(i64)=8 ⇒ 要提升就显式 @as / @intCast
 @mulWithOverflow(maxInt(i64), 2) → 溢出标志 = 1（0/1，不是 bool）
 @addWithOverflow(2^62, 2^62)     → 溢出标志 = 1
 ⇒ 想要'溢出即错'就别裸乘，走 *WithOverflow 自己判
 @setRuntimeSafety(false) 下 200*200 = 64（u8 回绕）
 三模式：Debug/ReleaseSafe 溢出 panic；ReleaseFast 静默回绕
 子进程 i64 溢出 → term=terminated with signal ABRT，success=false，stderr 有 panic=true
 ⇒ 用 f64 存值正是躲这个：f64 溢出给 inf，不 panic
 ⚠️ 但 inf/NaN 会静默传播，所以除零我们选**报错**
==== 33.13 结束 ====
```

### 四个层次，逐个说清

**1）永不宽化（编译期钉死）。**
`@TypeOf(@as(u8,1) + @as(u8,2)) != u8` 就在 `comptime` 里。
这段代码在**编译时**求值，如果哪天 Zig 加了隐式提升，**这个示例编不过**——
比任何注释都可靠。

**2）`*WithOverflow`：可检测的那条路。**
`@mulWithOverflow` / `@addWithOverflow` 返回 `[结果, 溢出标志]`。
⚠️ 标志类型是 **`u1`** 不是 `bool`（见 13 章坑位 16），
所以 `expect(ov[1])` 报 `expected type 'bool', found 'u1'`，得写 `ov[1] == 1`。

**3）`@setRuntimeSafety(false)`：不可检测的那条路。**
`unsafedMul(200, 200) = 64`（400 减 256）——**这就是 ReleaseFast 的行为**，
而且它在 Debug 构建里也能复现。函数级 `@setRuntimeSafety(false)`
让这一条指令不带溢出检查，于是静默回绕。

**4）子进程自举：真 panic 长什么样。**
`i64` 溢出在 Debug 下是 `panic: integer overflow`，进程带 `SIGABRT` 走。
只能在子进程里看，因为它会带走整个进程——这和 33.10 的栈溢出探针是同一个套路。

### 三模式对照表

| 模式 | 整数溢出 | 数组越界 | 除以 0（整数） | 本章解释器 |
|---|---|---|---|---|
| `Debug` | **panic** | panic | panic | 同左（但值是 f64，躲开了整数溢出） |
| `ReleaseSafe` | **panic** | panic | panic | 同左 |
| `ReleaseFast` | 静默回绕 | 未定义 | 未定义 | 同左 |

⚠️ `ReleaseFast` 的"静默回绕"是**双刃剑**：它不是 bug，是"你要快就不要安全检查"
的契约。但对一个**输入来自用户的解释器**来说，静默回绕意味着用户写
`2^64`（本该是天文数字）会悄悄得到 0。

### 解释器为什么用 f64

回到本章的核心取舍。**值统一 f64** 有两个后果：

- ✅ 整数溢出问题消失——f64 溢出给 `±inf`，不 panic
- ⚠️ 但 `inf` / `NaN` 会**静默传播**：`inf * 0 = NaN`，`NaN + 1 = NaN`，
  一路传到最终结果

所以本章对除零**显式报错**（33.6）：宁可少一种输入，也不要一个
"看起来能算但结果是 NaN"的表达式。换个语言（强制整数语义），
这个取舍会反过来——除零报错，但乘法溢出交给宿主 panic。

---

## 33.14 完整 REPL 风格演示

REPL 的核心不是"打印提示符再读一行"，而是**行协议**：怎么从字节流里
切出一行。这一步在 0.17 有个必须绕开的坑。

### ⚠️ `takeDelimiterExclusive` 不能用

`std.Io.Reader` 在 0.17 提供了 `takeDelimiterExclusive`，
听起来正是"读一行"的正确工具。**但它不消费缓冲**——分隔符原地不动。
于是第二次调用在偏移 0 处又找到同一个 `\n`，返回**空串**。

```plain
  缓冲内容 = "let a = 6\nvar b = 7\na * b\n\nb = a + 1\nb ^ 2\n"

  第一次 takeDelimiterExclusive('\n')
    → 返回 "let a = 6"     ← 对
    → 缓冲**没变**          ← 错在这里

  第二次 takeDelimiterExclusive('\n')
    → 在偏移 0 处找到 '\n' → 返回 ""    ← 拿到空串
```

### 正确姿势：`fillMore` + `indexOfScalarPos` + `toss`

```zig
// examples/33_zcalc/main.zig 第 1175-1197 行（nextLine）
/// 一行一取。缓冲可能只有半行，"没找到换行"就 fillMore 再找；EndOfStream 时缓冲里的
/// 零头就是最后一行（没有结尾换行的那种）。
fn nextLine(r: *std.Io.Reader) !?[]const u8 {
    while (true) {
        const avail = r.buffered();
        if (std.mem.indexOfScalarPos(u8, avail, 0, '\n')) |idx| {
            const line = avail[0..idx];
            r.toss(idx + 1); // 找到分隔符才 toss(idx+1)：把 '\n' 一起吃掉
            return line;
        }
        r.fillMore() catch |err| switch (err) {
            error.EndOfStream => {
                const rest = r.buffered();
                if (rest.len == 0) return null;
                // ⚠️ 没找到分隔符时只能 toss(avail.len)，无脑写 toss(idx+1) 会
                // panic: assert(r.seek <= r.end)（实测）。
                r.toss(rest.len);
                return rest;
            },
            else => |e| return e,
        };
    }
}
```

三个关键点：

1. **`indexOfScalarPos` 而不是 `indexOfScalar`**——前者带起始偏移，
   下一轮循环能从已经看过的位置继续。实际上这里每轮都从 0 开始搜，
   但用 `indexOfScalarPos` 更明确（`avail` 是当前有效窗口，不是整个缓冲）。
2. **`toss(idx + 1)` 而不是 `toss(idx)`**——要把 `\n` 一起吃掉。
3. **没找到分隔符时只能 `toss(avail.len)`**。无脑写 `toss(idx+1)` 而 `idx` 是
   `null` 会 panic：`assert(r.seek <= r.end)`（实测踩过）。

### 演示脚本与运行

```zig
// examples/33_zcalc/main.zig 第 1105-1158 行（33.14 分节）
    begin("33.14");
    {
        const script = "let a = 6\nvar b = 7\na * b\n\nb = a + 1\nb ^ 2\n";
        std.debug.print("喂给 REPL 的多行输入（空行 = 一次输入结束）：\n", .{});
        // ⚠️ `++` 不能用于运行期切片：先 append 前缀再 append 本体。
        var show: std.ArrayList(u8) = .empty;
        var it = std.mem.splitScalar(u8, script, '\n');
        while (it.next()) |l| {
            try show.appendSlice(a, "  |");
            try show.appendSlice(a, l);
            try show.appendSlice(a, "\n");
        }
        std.debug.print("{s}", .{show.items});

        // ⚠️ 0.17 的 takeDelimiterExclusive **不消费缓冲**（分隔符原地不动），
        // 所以第二次调用在偏移 0 处又找到 '\n'，返回**空串**。
        var buggy = std.Io.Reader.fixed(script);
        const l1 = try buggy.takeDelimiterExclusive('\n');
        const l2 = try buggy.takeDelimiterExclusive('\n');
        std.debug.print(" takeDelimiterExclusive：第 1 行 ={s}（{d} 字节），第 2 行 ={s}（{d} 字节）\n", .{ l1, l1.len, l2, l2.len });
        std.debug.print(" 缓冲此刻仍是 ={s}\n", .{buggy.buffered()});
        _ = buggy.toss(l1.len + 1); // 手动消费才是正确姿势
        std.debug.print(" 手动 toss({d}) 之后缓冲 ={s}\n", .{ l1.len + 1, buggy.buffered() });

        var reader = std.Io.Reader.fixed(script);
        var lines: usize = 0;
        var entries: usize = 0;
        var history: std.ArrayList(f64) = .empty;
        std.debug.print(" 手写行协议（fillMore + indexOfScalarPos + toss）：\n", .{});
        while (try nextLine(&reader)) |line| {
            lines += 1;
            const trimmed = std.mem.trim(u8, line, " \t\r");
            if (trimmed.len == 0) {
                entries += 1;
                std.debug.print("  -- 空行：本次输入结束（累计 {d} 行 / {d} 个值）\n", .{ lines, history.items.len });
                continue;
            }
            if (runValue(a, &env, trimmed)) |v| {
                try history.append(a, v);
                std.debug.print("  [输入 {d}] {s: <10} = {d}\n", .{ lines, trimmed, v });
            } else |e| {
                var d2: Diag = .{};
                _ = runProgramDiag(a, &env, trimmed, &d2, default_max_depth) catch {};
                std.debug.print("  [输入 {d}] {s: <10} → error.{s} @ {d}:{d}\n", .{
                    lines, trimmed, @errorName(e), d2.pos.line, d2.pos.col,
                });
            }
        }
        std.debug.print(" 收尾：{d} 行、{d} 次空行收束、历史 {d} 个值\n", .{ lines, entries, history.items.len });
        var sum: f64 = 0;
        for (history.items) |v| sum += v;
        std.debug.print(" 历史求和 = {d}（状态跨行保留：a/b 在第二次输入里还在）\n", .{sum});
    }
    end("33.14");
```

运行输出（`examples/33_zcalc/main.zig`）：

```text
==== 33.14 开始 ====
喂给 REPL 的多行输入（空行 = 一次输入结束）：
  |let a = 6
  |var b = 7
  |a * b
  |
  |b = a + 1
  |b ^ 2
  |
 takeDelimiterExclusive：第 1 行 =let a = 6（9 字节），第 2 行 =（0 字节）
 缓冲此刻仍是 =
var b = 7
a * b

b = a + 1
b ^ 2

 手动 toss(10) 之后缓冲 =
a * b

b = a + 1
b ^ 2

 手写行协议（fillMore + indexOfScalarPos + toss）：
  [输入 1] let a = 6  = 6
  [输入 2] var b = 7  = 7
  [输入 3] a * b      = 42
  -- 空行：本次输入结束（累计 4 行 / 3 个值）
  [输入 5] b = a + 1  = 7
  [输入 6] b ^ 2      = 49
 收尾：6 行、1 次空行收束、历史 5 个值
 历史求和 = 111（状态跨行保留：a/b 在第二次输入里还在）
==== 33.14 结束 ====
```

三层信息，逐一读：

1. **前半（`takeDelimiterExclusive` 那四行）**：`第 2 行 =（0 字节）`
   就是 bug 的直接证据。紧跟的"缓冲此刻仍是"证明**什么都没被消费**。
   再往下"手动 toss(10) 之后缓冲"证明正确姿势是 `toss(len+1)`。

2. **后半（手写协议那 9 行）**：`[输入 1]` 到 `[输入 6]`，
   空行那行单独标出。注意行号**跨过**了空行（4 是空行，5 继续），
   这就是"读多行直到空行"的语义。

3. **`历史求和 = 111`**：`6 + 7 + 42 + 7 + 49 = 111`。
   关键是 `b = a + 1` 那行在**第二次输入**里仍然能用 `a`——
   状态跨行保留。这靠的是 `main` 开头 push 的那个全局作用域
   （`Env` 活到 `main` 结束），以及 `Env.declare` 里那个 `dupe`
   （名字必须从 reader 的临时缓冲里拷出来，否则下一轮 `fillMore` 就覆盖了）。

⚠️ `std.Io.Reader.fixed(script)` 是**单参数**版本（0.17）。
如果按旧教程写 `Reader.fixed(buf, &.{})` 会报
`member function expected 1 argument(s), found 2`。

---

## 33.15 测试：26 条，覆盖每一层

三阶段接口窄，所以测试可以分层写，每层都不需要启动前一层。

```plain
  词法层（4 条）    lex() 直接喂字符串，断言 token 序列 / 位置 / BadChar
  语法层（6 条）    parseOnly() 只建树不求值，断言树形结构
  求值层（3 条）    runValue() 走全流程，断言数值
  变量/作用域（3 条）
  内建（3 条）
  错误（2 条）
  深度（2 条）
  表驱动（2 条）   inline for 跑用例表
  AST 布局（1 条）
  REPL（2 条）
  ─────────────────
  合计 26 条
```

运行输出（`examples/33_zcalc/main.zig`）：

```text
1/26 main.test.词法：记号序列与关键字定型...OK
2/26 main.test.词法：位置含行列，换行推进行号...OK
3/26 main.test.词法：小数点前瞻，非法字符走 BadChar...OK
4/26 main.test.语法：优先级把树拧成右子树...OK
5/26 main.test.语法：右结合 vs 左结合的树形...OK
6/26 main.test.语法：一元负号不进 binary...OK
7/26 main.test.语法：括号不进 AST...OK
8/26 main.test.语法：赋值与表达式靠两格前瞻区分...OK
9/26 main.test.语法错误：缺右括号 / 尾部有剩 / 缺操作数...OK
10/26 main.test.求值：六种二元运算符 + 一元负号...OK
11/26 main.test.求值：浮点要带容差，逐位相等不成立...OK
12/26 main.test.变量：let 不可赋值，var 可以...OK
13/26 main.test.变量：未定义标识符带位置...OK
14/26 main.test.作用域：遮蔽后恢复...OK
15/26 main.test.作用域：块内定义不出块...OK
16/26 main.test.内建：常量与一元二元函数...OK
17/26 main.test.内建：arity 与未知函数...OK
18/26 main.test.内建表：编译期不变量 + 按 arity 喂参数...OK
19/26 main.test.错误：除零与词法错误分离...OK
20/26 main.test.深度：括号嵌套在解析期触发 TooDeep...OK
21/26 main.test.深度：加法长链解析浅但求值深...OK
22/26 main.test.表驱动：inline for 跑优先级用例表...OK
23/26 main.test.表驱动：inline for 跑错误用例表...OK
24/26 main.test.AST：union(enum) 的 tag 与布局...OK
25/26 main.test.REPL：逐行协议、空行收束、takeDelimiterExclusive 的坑...OK
26/26 main.test.REPL：状态跨行保留...OK
All 26 tests passed.
```

### 表驱动测试：`inline for` 跑用例表

两条表驱动测试是本章测试写法的主张：**用例表是唯一真相**。

```zig
// examples/33_zcalc/main.zig 第 1467-1497 行（两条表驱动测试）
test "表驱动：inline for 跑优先级用例表" {
    // inline for 在编译期把循环体按用例数展开，每份里的用例是**编译期常量**。
    // 这让"用例表就是单一真相"成为可能：表一改，测试跟着改。
    const Case = struct { src: []const u8, want: f64 };
    const cases = [_]Case{
        .{ .src = "1 + 2 * 3", .want = 7 },
        .{ .src = "(1 + 2) * 3", .want = 9 },
        .{ .src = "10 - 3 - 2", .want = 5 },
        .{ .src = "100 / 10 / 5", .want = 2 },
        .{ .src = "2 ^ 3 ^ 2", .want = 512 },
        .{ .src = "-4 + 10", .want = 6 },
        .{ .src = "17 % 5", .want = 2 },
    };
    inline for (cases) |c| {
        comptime std.debug.assert(c.src.len > 0); // src 在这里是编译期常量
        try expectValue(c.src, c.want);
    }
}

test "表驱动：inline for 跑错误用例表" {
    const BadCase = struct { src: []const u8, want: anyerror };
    const cases = [_]BadCase{
        .{ .src = "1 $ 2", .want = error.BadChar },
        .{ .src = "1 +", .want = error.SyntaxError },
        .{ .src = "1 2", .want = error.SyntaxError },
        .{ .src = "nosuch(1)", .want = error.UnknownFunction },
        .{ .src = "sqrt(1, 2)", .want = error.ArityMismatch },
        .{ .src = "1 / 0", .want = error.DivisionByZero },
    };
    inline for (cases) |c| try expectFails(c.src, c.want);
}
```

`inline for` 的关键收益：循环体里 `c.src` 是**编译期常量**，
所以能写 `comptime std.debug.assert(c.src.len > 0)` 这种普通 `for` 写不了的断言。
表里一个空字符串会**编译失败**而不是运行期静默通过。

`expectError` 的存在让错误表可以写得和值表一样整齐——这是错误集设计的红利：
错误是**值**（同一个 `CalcError` 类型），所以能装进结构体、能进数组、能被 `inline for` 遍历。

### 两条"钉死事实"的测试

有些测试的作用不是测功能，而是**防止后来的人顺手改掉一个事实**。

```zig
// examples/33_zcalc/main.zig 第 1326-1335 行（浮点那条）
test "求值：浮点要带容差，逐位相等不成立" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var env = freshEnv(a);
    defer env.deinit();
    const v = try runValue(a, &env, "sqrt(2) * sqrt(2)");
    try std.testing.expectApproxEqAbs(@as(f64, 2), v, 1e-9);
    try std.testing.expect(v != 2.0); // 这就是为什么必须带容差
}
```

`expect(v != 2.0)` 看着奇怪，但它是**故意的**：把"浮点乘法不精确"
这个事实钉死。哪天 `std.math.sqrt` 换了实现、结果恰好是 2.0，这条会失败，
提醒你"容差断言不能省"。

```zig
// examples/33_zcalc/main.zig 第 1499-1515 行（AST 布局那条）
test "AST：union(enum) 的 tag 与布局" {
    const ti = @typeInfo(Expr).@"union";
    try std.testing.expectEqual(@as(usize, 5), ti.field_names.len);
    try std.testing.expect(ti.tag_type.? == std.meta.Tag(Expr));
    // 布局 = tag + 最大负载，所以 @sizeOf 至少要不小于最大负载
    var biggest: usize = 0;
    inline for (ti.field_types) |ft| if (@sizeOf(ft) > biggest) {
        biggest = @sizeOf(ft);
    };
    try std.testing.expect(@sizeOf(Expr) >= biggest);
    // 0.17 里 tag_type 是 u1（不是 byte）：5 个 tag 只需 1 位
    try std.testing.expectEqual(@as(usize, 1), @sizeOf(ti.tag_type.?));
    try std.testing.expectEqual(
        std.meta.activeTag(@as(Expr, .{ .num = .{ .v = 0, .pos = pos0() } })),
        .num,
    );
}
```

`@sizeOf(ti.tag_type.?) == 1` 把"5 个 tag 编码成 u1"钉住了。
如果哪天 Zig 改用 byte 编码 tag，这条会失败——而这正是你想知道的
（`@sizeOf(Expr)` 会从 56 变成 63，触发其他性能假设）。

⚠️ `inline for (ti.field_types)` 必须用 `inline for`：元素类型是 `type`，
普通 `for` 报 `values of type 'type' must be comptime-known`
（见 13 章坑位 6）。

### 测试的内存姿势

每条 test 都自己开一个 `ArenaAllocator`：

```zig
// examples/33_zcalc/main.zig 第 1203-1225 行（freshEnv / expectValue / expectFails）
fn freshEnv(a: std.mem.Allocator) Env {
    var env = Env.init(a);
    env.scopes.append(a, .empty) catch unreachable; // 顶层作用域必须存在，否则 declare 越界
    return env;
}

fn expectValue(src: []const u8, want: f64) !void {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var env = freshEnv(a);
    defer env.deinit();
    try std.testing.expectApproxEqAbs(want, try runValue(a, &env, src), 1e-9);
}

fn expectFails(src: []const u8, want: anyerror) !void {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var env = freshEnv(a);
    defer env.deinit();
    try std.testing.expectError(want, runProgram(a, &env, src));
}
```

为什么是 arena 而不是 `std.testing.allocator` 直连？因为 `testing.allocator`
对**每一次**分配都会记账，AST 是几百个节点逐个从 arena 分配的——
用 testing.allocator 的话每条 test 都要保证零泄漏，而 arena 的
"一次 deinit 全清"正好和解释器的内存模型对齐（33.11 讲过这个取舍）。

注意 `freshEnv` 里那句 `catch unreachable`：**顶层作用域必须存在**，
否则 `declare` 里的 `scopes.items[len-1]` 会越界。这是把"必须先 push"
这个前置条件封在一个函数里，比在每条 test 里手写一遍 `try env.push()` 更难漏。

---

## 33.16 坑位清单

以下每一条都是本章**实际踩到或实测确认**的 0.17 行为。

1. **结合性判据和直觉相反**：`left < right` 才是**左结合**（`+ -` 给 1/2），
   `left > right` 是右结合（`^` 给 7/6）。因为右操作数用 `parseBinary(bp.right)`
   解析，`bp.right` 是右侧门槛：门槛高就吃不下同级（留给外层 = 左结合）。
   教科书式的"左严右松"在这里是错的。实测反证：`10-3-2 = 5`（左结合）、
   `2^3^2 = 512`（右结合）。

2. **`let` / `var` / `error` / `void` / `u1` 不能当字段名或变量名**。
   关键字直接编译错；原始类型名报 `name shadows primitive`。
   所以关键字记号只能叫 `let_kw` / `var_kw`，AST 字段只能叫 `variable`。
   同理 `var u1` 报 `name shadows primitive 'u1'`，`const error` / `const void` 同理。

3. **`++` 不能拼接运行期切片**。`"a" ++ @tagName(x)` 报
   `slice being concatenated must be comptime-known` + `note: slice being
   concatenated must be comptime-known`。正解是自带缓冲 + `std.fmt.bufPrint`。
   本章踩了两次（`Diag.set` 的参数、REPL 打印输入脚本）。

4. **doc 注释（`///`）不能挂在 `comptime {}` 块上**，报
   `documentation comments cannot be attached to comptime blocks`。
   容器级的 `comptime { ... }` 只能用 `//`。

5. **`comptime { }` 块里 `comptime var` 和 `inline for` 都是多余的**，
   各报一条 `redundant inline keyword in comptime scope` /
   `'comptime var' is redundant in comptime scope`。在 `comptime` 块里
   直接写 `var` + `for`（13 章坑位 3 的同款现象）。

6. **`@typeInfo(T).@"union".tag` 在 0.17 不存在**，报
   `no field named 'tag' in struct 'lang.Type.Union'`。新名字是
   **`tag_type`**（`?type`，因为普通 union 可以无 tag），要写 `.tag_type.?`。
   `field_names` / `field_types` / `field_attrs` 三条平行数组代替了 0.15 的 `.fields`。

7. **`Diag` 按值传递会让 `msg` 悬空**。`msg` 是指向自身 `buf` 的切片；
   值拷贝 + `errdefer diag.* = ctx.diag` 回写之后，`msg` 仍指向
   `runProgramDiag` 栈帧上的临时，函数一返回就是垃圾。实测症状
   `位置 1:4  ⟨乱码⟩`（位置对、文案乱）。**必须用 `*Diag`**，
   这样回写代码整个不需要。

8. **`!?f64` 双层可选会让 `{d}` 打印失败**：
   `if (runProgram(..)) |v|` 捕获的 `v` 是 `?f64` 而非 `f64`，报
   `invalid format string 'd' for type '?f64'`。要么两层 `if` 各拆一层，
   要么加个 `runValue` 压平成 `!f64`。

9. **`catch |e| { ...; return; }` 里的 `return` 会结束整个 `main`**。
   本章第一版在 33.2 的 `BadChar` 演示里写了 `return`，结果 33.3~33.14
   **全部不执行**，产物只有两节，而 `run-all.sh` 仍然报"验证通过"
   （退出码 0）。**教训：自检型输出必须检查分节标记齐不齐**，
   不能只看退出码。

10. **`catch` 块的类型必须和成功侧匹配**。`runProgram(...) catch |e| { print(); return; }`
    里块是 `void`，成功侧是 `?f64` → `incompatible types: '?f64' and 'void'`。
    用 `if (x) |v| {...} else |e| {...}` 两条腿分开。

11. **`zig test` 不编译未被引用的 `main`**。三处错误（`?f64` 格式串、
    `++` 运行期拼接、错误的 `if/else` 腿）全都先在 `zig test` 阶段"通过"，
    `zig build-exe` 才报。**调试 main 路径必须直接 `build-exe`**，
    定位用 `-freference-trace=12` 追到 `main:` 那一行。

12. **`takeDelimiterExclusive` 在 0.17 不消费缓冲**（实测 std bug）。
    第一次返回 `"let a = 6"`，缓冲一字未动；第二次在偏移 0 处又找到 `\n`，
    返回**空串**。行协议必须自己 `fillMore` + `indexOfScalarPos` + `toss`。
    参见 20 章 20.4 的同类记录。

13. **`toss` 的长度不能超**。没找到分隔符时无脑写 `toss(idx+1)`（`idx` 是 `null`）
    会 panic：`assert(r.seek <= r.end)` + `reached unreachable code`。
    只能 `toss(avail.len)`。

14. **`std.Io.Reader.fixed` 在 0.17 是单参数**（`fixed(buffer: []const u8) Reader`）。
    旧写法 `Reader.fixed(buf, &.{})` 报
    `member function expected 1 argument(s), found 2`。

15. **`std.process.executablePathAlloc` 的参数顺序是 `(io, allocator)`**，
    不是旧版的 `(allocator)`。传错报
    `expected 2 argument(s), found 1`。
    而 `std.process.run` 是 **`(gpa, io, opts)`**（gpa 在前）——
    同一套 API 里两个函数的参数顺序不一致，容易记混。

16. **`union(enum)` 的 tag 是 `u1` 不是 byte**。5 个 tag 在 0.17 编码成 1 字节。
    `@sizeOf(@typeInfo(Expr).@"union".tag_type.?) == 1`。33.15 有 test 钉住。

17. **`@mulWithOverflow` 的溢出标志是 `u1` 不是 `bool`**（13 章坑位 16）。
    `expect(ov[1])` 报 `expected type 'bool', found 'u1'`，得写 `ov[1] == 1`。

18. **函数体里不许声明 `fn`**（13 章坑位 17）。所有辅助函数必须放顶层
    或做成结构体方法。本章的 `biPi`/`biMin` 等全在顶层。

19. **错误集成员打印顺序不等于声明顺序**。实测
    `OutOfMemory` 排最前、`TooDeep` 排最后。写 `inline for` 断言错误集时
    要照实际输出，别按声明顺序想当然。

20. **`errdefer toks.deinit(a)` 在 `ArrayList` 上要显式写 `a`**。
    0.17 的 `ArrayList` 是非托管的（unmanaged），`append` / `toOwnedSlice` /
    `deinit` 全部要传 allocator 参数。`std.StringHashMap` 在 0.17 也是
    非托管语义：初始化用 `= .empty`，没有 `.init(a)`。

21. **`@setRuntimeSafety(false)` 在 Debug 下也能复现 ReleaseFast 的回绕**：
    `unsafedMul(200, 200) = 64`。想在 Debug 里观察"不检查"的行为，
    不必真去构建 ReleaseFast。

22. **子进程 panic/段错误会带走整个进程**。想在示例里展示宿主行为，
    只能用 `std.process.run` 自举（33.10 / 33.13 各一次）。
    ⚠️ `probe-*` 参数的判断必须放在 `main` **开头**并直接 `return`，
    否则子进程会继续跑完整个 33.1~33.14，输出多出一大坨。

23. **`Zig 不检查栈溢出`**，没有 canary。`probeRecurse` 无界递归的结果是
    `term=terminated with signal ABRT`（Zig 运行时查信号后 abort），
    `stderr` 里有 `Segmentation fault at address 0x7ff...`。深度必须自己数。

24. **共享 `Env` 时演示作用域会有陷阱**。33.11 第一版用 `y` 做"出作用域就不可见"
    的例子，但 33.7 已在全局作用域留了 `var y = 9`，于是读 `y` 命中外层绑定，
    输出 `?? 块外的 y 竟然 = 9`——作用域栈在**正确工作**，但演示失效了。
    讲作用域时必须用一个**全局从没声明过**的名字。

25. **`.none` / `0:0` 位置是"没带位置"的信号**。`lex` 早期版本收 `?*Diag`
    但 `runProgramDiag` 传的是 `null`，于是 `1 $ 2` 的 `BadChar` 报 `@ 0:0`。
    现在 `runProgramDiag` 把真 `diag` 传进 `lex`，八个错误位置全部非零。

---

## 33.17 扩展练习

1. **比较运算** `< <= > >= == !=`，返回 0/1，优先级在 `+ -` 之下。
   注意 `==` 和 `=` 的 token 冲突（要区分 `eq` 和 `eq_eq`）。
2. **`min` / `max` 参数化到任意元数**：`call.args` 已经是切片，
   只要把 `builtin_table` 的 `arity` 放宽 + 在 `comptime` 块里校验上限。
3. **真 REPL**：把 `std.Io.Reader.fixed(script)` 换成
   `std.Io.File.stdin().reader(init.io, &buf)`，其余一行不改——
   这正是把 I/O 和核心逻辑解耦的回报（33.1 说的"三段只靠数据通信"）。
4. **比较运算的短路**：`a && b` / `a || b` 需要 `eval` 支持"不求值右侧"
   的调用形式，当前 `eval` 签名（`!f64`）做不到，得改成
   `fn eval(e, env, ctx) ?f64` 或加 `evalMaybe`。
5. **栈虚拟机**：把树遍求值改成"编译到字节码 + 循环执行"。
   性能差异立现，而且深度问题从"递归栈"变成"显式栈"——
   33.10 的两道闸门会变成一道（字节码数组的长度检查）。
6. **`comptime` 求值**：`let x = comptime 2 + 3` 让部分表达式在编译期算完，
   接上 13 章的 `inline for` 查表思路。

---

上一章：[32 SQLite 实战](32-sqlite.md) · 下一章：[34 LRU 缓存服务器](34-zcache.md)
