//! 33 实战：表达式解释器 zcalc——lexer → 优先级爬升解析器 → union(enum) AST → 树遍求值 → REPL
//!
//! 取材：Systems Programming with Zig ch12。设计取舍：值统一 f64（除法无陷阱）；^ 右结合；
//! let/var 双模式 + 块作用域；错误带行列位置。输出全走 std.debug.print（stderr），
//! 因此**无参数运行**即可得到完全确定的产物。
const std = @import("std");
const builtin = @import("builtin");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}
fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ═══ 词法层：字符 → 记号 ═══

/// ⚠️ 0.17 坑：`let`/`var`/`error`/`void`/`u1` 全是关键字或原始类型名，拿来当字段名
/// 直接编译错（`name shadows primitive`）。关键字 token 只能叫 `*_kw`。
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

/// 逐字符扫描器。**不写正则**——正则要把"识别"和"定位"分成两趟，
/// 而手写扫描器一次前進就同时拿到 kind、text、pos 三样东西。
/// `diag` 可为 null（测试里只要 token 时用）。给了就在 BadChar 时记下出错位置——
/// ⚠️ 不带位置的词法错误在报告里就是 `0:0`，用户完全不知道是哪个字符坏了。
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
            },
            'a'...'z', 'A'...'Z', '_' => {
                // 贪吃最长匹配。关键字识别放在**词法**而不是解析器——
                // 这样 `let` 在 token 流里已是 let_kw，解析器不必再看字符串。
                const start = i;
                while (i < src.len and (std.ascii.isAlphanumeric(src[i]) or src[i] == '_')) i += 1;
                const text = src[start..i];
                col += @intCast(i - start);
                const kw: TokenKind = if (std.mem.eql(u8, text, "let"))
                    .let_kw
                else if (std.mem.eql(u8, text, "var"))
                    .var_kw
                else
                    .ident;
                try toks.append(a, .{ .kind = kw, .text = text, .pos = pos });
                continue;
            },
            else => {
                if (diag) |d| d.set(pos, "非法字符 {c}", .{ch});
                return error.BadChar;
            },
        };
        try toks.append(a, .{ .kind = kind, .text = src[i .. i + 1], .pos = pos });
        i += 1;
        col += 1;
    }
    try toks.append(a, .{
        .kind = .eof,
        .text = "",
        .pos = .{ .offset = @intCast(src.len), .line = line, .col = col },
    });
    return toks.toOwnedSlice(a);
}

// ═══ 语法层：记号 → 树 ═══

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

const default_max_depth: u32 = 64;

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

const Parser = struct {
    toks: []Token,
    i: usize = 0,
    a: std.mem.Allocator,
    diag: *Diag,
    depth: u32 = 0,
    max_depth: u32 = default_max_depth,

    fn peek(p: *Parser) Token {
        return p.toks[p.i];
    }
    fn peekAt(p: *Parser, n: usize) Token {
        return p.toks[@min(p.i + n, p.toks.len - 1)];
    }
    fn advance(p: *Parser) Token {
        const t = p.toks[p.i];
        if (t.kind != .eof) p.i += 1;
        return t;
    }
    fn expect(p: *Parser, kind: TokenKind) CalcError!Token {
        const t = p.peek();
        if (t.kind != kind) {
            p.diag.set(t.pos, "此处应为 {s}，实际是 {s}", .{ @tagName(kind), @tagName(t.kind) });
            return error.SyntaxError;
        }
        return p.advance();
    }
    fn alloc(p: *Parser, e: Expr) std.mem.Allocator.Error!*Expr {
        const node = try p.a.create(Expr);
        node.* = e;
        return node;
    }

    /// 程序 := stmt (';' stmt)*，末尾可省分号
    fn parseProgram(p: *Parser) CalcError![]Stmt {
        var list: std.ArrayList(Stmt) = .empty;
        errdefer list.deinit(p.a);
        while (p.peek().kind != .eof) {
            try list.append(p.a, try p.parseStmt());
            if (p.peek().kind == .semi) {
                _ = p.advance();
                continue;
            }
            break;
        }
        if (p.peek().kind != .eof) {
            p.diag.set(p.peek().pos, "语句后有多余记号 {s}", .{@tagName(p.peek().kind)});
            return error.SyntaxError;
        }
        return list.toOwnedSlice(p.a);
    }

    fn parseStmt(p: *Parser) CalcError!Stmt {
        const t = p.peek();
        switch (t.kind) {
            .let_kw, .var_kw => {
                _ = p.advance();
                const name = try p.expect(.ident);
                _ = try p.expect(.eq);
                return .{ .decl = .{
                    .name = name.text,
                    .mutable = t.kind == .var_kw,
                    .value = try p.parseExpr(),
                    .pos = t.pos,
                } };
            },
            .lbrace => {
                _ = p.advance();
                var list: std.ArrayList(Stmt) = .empty;
                errdefer list.deinit(p.a);
                while (p.peek().kind != .rbrace and p.peek().kind != .eof) {
                    try list.append(p.a, try p.parseStmt());
                    if (p.peek().kind == .semi) {
                        _ = p.advance();
                        continue;
                    }
                    break;
                }
                _ = try p.expect(.rbrace);
                return .{ .block = .{ .body = try list.toOwnedSlice(p.a), .pos = t.pos } };
            },
            .ident => {
                // 两格前瞻区分"赋值"与"表达式"：光看 ident 猜不出来。
                if (p.peekAt(1).kind == .eq) {
                    const name = p.advance();
                    _ = p.advance();
                    return .{ .assign = .{ .name = name.text, .value = try p.parseExpr(), .pos = name.pos } };
                }
                return .{ .expr = try p.parseExpr() };
            },
            // 裸表达式语句。交给 parsePrimary 报错更准（它知道自己在解表达式）。
            .num, .lparen, .minus => return .{ .expr = try p.parseExpr() },
            else => {
                p.diag.set(t.pos, "语句不能以 {s} 开头", .{@tagName(t.kind)});
                return error.SyntaxError;
            },
        }
    }

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

    fn parseUnary(p: *Parser) CalcError!*Expr {
        const t = p.peek();
        if (t.kind == .minus) {
            _ = p.advance();
            // 递归调自己而非 parseBinary：一元负号因此天然右结合，`- - 5` 合法。
            return p.alloc(.{ .unary = .{ .op = .minus, .child = try p.parseUnary(), .pos = t.pos } });
        }
        return p.parsePrimary();
    }

    fn parsePrimary(p: *Parser) CalcError!*Expr {
        const t = p.advance();
        switch (t.kind) {
            .num => {
                const v = std.fmt.parseFloat(f64, t.text) catch {
                    p.diag.set(t.pos, "数字字面量无法解析成 f64", .{});
                    return error.SyntaxError;
                };
                return p.alloc(.{ .num = .{ .v = v, .pos = t.pos } });
            },
            .ident => {
                if (p.peek().kind == .lparen) {
                    _ = p.advance();
                    var args: std.ArrayList(*Expr) = .empty;
                    errdefer args.deinit(p.a);
                    if (p.peek().kind != .rparen) {
                        while (true) {
                            try args.append(p.a, try p.parseExpr());
                            if (p.peek().kind == .comma) {
                                _ = p.advance();
                                continue;
                            }
                            break;
                        }
                    }
                    _ = try p.expect(.rparen);
                    return p.alloc(.{ .call = .{ .name = t.text, .args = try args.toOwnedSlice(p.a), .pos = t.pos } });
                }
                // 0 元内建（pi / e）写成"无括号调用"：语法上多一种形态，
                // 求值器却完全不用改——同一个 `.call` 标签，args 为空。
                if (builtinIndex(t.text)) |bi| {
                    if (builtin_table[bi].arity == 0) {
                        const none: []const *Expr = &.{};
                        return p.alloc(.{ .call = .{ .name = t.text, .args = none, .pos = t.pos } });
                    }
                }
                return p.alloc(.{ .variable = .{ .name = t.text, .pos = t.pos } });
            },
            .lparen => {
                const inner = try p.parseExpr();
                _ = try p.expect(.rparen);
                return inner; // 括号不进 AST：它只影响树形，不影响语义
            },
            else => {
                p.diag.set(t.pos, "表达式不能以 {s} 开头", .{@tagName(t.kind)});
                return error.SyntaxError;
            },
        }
    }
};

// ═══ 运行时：环境 + 内建表 + 求值 ═══

const Env = struct {
    const Binding = struct { value: f64, mutable: bool };
    const Scope = std.StringHashMapUnmanaged(Binding);

    a: std.mem.Allocator,
    scopes: std.ArrayList(Scope),

    fn init(a: std.mem.Allocator) Env {
        return .{ .a = a, .scopes = .empty };
    }
    fn deinit(e: *Env) void {
        e.scopes.deinit(e.a);
    }
    fn push(e: *Env) std.mem.Allocator.Error!void {
        try e.scopes.append(e.a, .empty);
    }
    /// 出作用域靠**弹栈**，不逐个 free。块里的绑定随 arena 一起走。
    fn pop(e: *Env) void {
        _ = e.scopes.pop();
    }
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
    }
};

const Builtin = struct {
    name: []const u8,
    arity: usize,
    apply: *const fn (args: []const f64) f64,
};

fn biPi(args: []const f64) f64 {
    _ = args;
    return std.math.pi;
}
fn biE(args: []const f64) f64 {
    _ = args;
    return std.math.e;
}
fn biSqrt(a: []const f64) f64 {
    return @sqrt(a[0]);
}
fn biAbs(a: []const f64) f64 {
    return @abs(a[0]);
}
fn biMin(a: []const f64) f64 {
    return @min(a[0], a[1]);
}
fn biMax(a: []const f64) f64 {
    return @max(a[0], a[1]);
}
fn biFloor(a: []const f64) f64 {
    return @floor(a[0]);
}
fn biCeil(a: []const f64) f64 {
    return @ceil(a[0]);
}

/// 内建表是**普通 const 数组**。加一个内建只改这一处，名字查找、arity 校验、
/// 求值分发全都不用动——数据驱动的三合一。
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

fn builtinIndex(name: []const u8) ?usize {
    for (builtin_table, 0..) |b, i| {
        if (std.mem.eql(u8, b.name, name)) return i;
    }
    return null;
}

/// 求值上下文。`diag` 必须是**指针**而非 `Diag` 值：Diag 里 `msg` 指向自己 `buf`
/// 的内部，按值拷贝会让 `msg` 指向**旧对象**的缓冲区，旧对象一返回读到的就是
/// 垃圾字节（实测 33.3 曾打出 `位置 1:4 ⟨乱码⟩`）。指针让所有递归层共享同一块缓冲。
const Ctx = struct {
    diag: *Diag,
    depth: u32 = 0,
    max_depth: u32 = default_max_depth,
};

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

fn execBlock(stmts: []const Stmt, env: *Env, ctx: *Ctx) CalcError!?f64 {
    var last: ?f64 = null;
    for (stmts) |s| {
        switch (s) {
            .decl => |d| {
                // 顺序不能反：先求值（此时 d.name 未绑定，`var x = x + 1` 里的 x 是外层的），
                // 再落定。声明写进**当前栈顶**作用域，不 push/pop——否则绑完就被弹掉。
                const v = try eval(d.value, env, ctx);
                try env.declare(d.name, v, d.mutable);
                last = v;
            },
            .assign => |asg| {
                const v = try eval(asg.value, env, ctx);
                try env.assign(asg.name, v);
                last = v;
            },
            .expr => |x| last = try eval(x, env, ctx),
            .block => |b| {
                try env.push();
                defer env.pop();
                last = try execBlock(b.body, env, ctx);
            },
        }
    }
    return last;
}

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

fn runProgram(a: std.mem.Allocator, env: *Env, src: []const u8) CalcError!?f64 {
    var diag: Diag = .{};
    return runProgramDiag(a, env, src, &diag, default_max_depth);
}

/// 把 `!?f64` 压平成 `!f64`。⚠️ 不做这层转换的话，`if (runProgram(..)) |v|`
/// 捕获到的 v 是 **?f64 而不是 f64**，拿去 `{d}` 打印就报
/// "invalid format string 'd' for type '?f64'"（实测踩过）。
fn runValue(a: std.mem.Allocator, env: *Env, src: []const u8) (CalcError || error{NoValue})!f64 {
    return (try runProgram(a, env, src)) orelse error.NoValue;
}

// ── 展示辅助 ──

/// ⚠️ 0.17 没有 `**` 幂运算符（见 13 章），缩进用切片截取而不是重复拼接。
fn indent(n: u32) []const u8 {
    const pad = "                                                                ";
    return pad[0..@min(n * 2, pad.len)];
}

fn dumpExpr(e: *const Expr, level: u32) void {
    switch (e.*) {
        .num => |n| std.debug.print("{s}num {d}\n", .{ indent(level), n.v }),
        .variable => |v| std.debug.print("{s}var {s}\n", .{ indent(level), v.name }),
        .unary => |u| {
            std.debug.print("{s}unary {s}\n", .{ indent(level), @tagName(u.op) });
            dumpExpr(u.child, level + 1);
        },
        .binary => |b| {
            std.debug.print("{s}binary {s}\n", .{ indent(level), @tagName(b.op) });
            dumpExpr(b.lhs, level + 1);
            dumpExpr(b.rhs, level + 1);
        },
        .call => |c| {
            std.debug.print("{s}call {s}/{d}\n", .{ indent(level), c.name, c.args.len });
            for (c.args) |arg| dumpExpr(arg, level + 1);
        },
    }
}

fn dumpStmts(stmts: []const Stmt, level: u32) void {
    for (stmts) |s| {
        switch (s) {
            .decl => |d| {
                std.debug.print("{s}decl {s} ({s})\n", .{
                    indent(level), d.name, if (d.mutable) "var" else "let",
                });
                dumpExpr(d.value, level + 1);
            },
            .assign => |asg| {
                std.debug.print("{s}assign {s}\n", .{ indent(level), asg.name });
                dumpExpr(asg.value, level + 1);
            },
            .block => |b| {
                std.debug.print("{s}block\n", .{indent(level)});
                dumpStmts(b.body, level + 1);
            },
            .expr => |x| {
                std.debug.print("{s}expr\n", .{indent(level)});
                dumpExpr(x, level + 1);
            },
        }
    }
}

fn parseOnly(a: std.mem.Allocator, src: []const u8) CalcError![]Stmt {
    var diag: Diag = .{};
    var p: Parser = .{ .toks = try lex(a, src, null), .a = a, .diag = &diag };
    return p.parseProgram();
}

fn lineText(src: []const u8, line_no: u32) []const u8 {
    var it = std.mem.splitScalar(u8, src, '\n');
    var n: u32 = 1;
    while (it.next()) |l| {
        if (n == line_no) return l;
        n += 1;
    }
    return "";
}

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

// ═══ 33.13 溢出探针（子进程自举） ═══

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

// ═══ main：三阶段流水线自演 ═══

pub fn main(init: std.process.Init) !void {
    const a = init.arena.allocator();
    const args = try init.minimal.args.toSlice(a);
    for (args[@min(1, args.len)..]) |arg| {
        if (std.mem.eql(u8, arg, "probe-overflow")) {
            std.debug.print("child mode={s} {d}*2={d}\n", .{
                @tagName(builtin.mode),            std.math.maxInt(i64),
                probeMul(std.math.maxInt(i64), 2),
            });
            return;
        }
        if (std.mem.eql(u8, arg, "probe-stack")) {
            std.debug.print("child depth={d}\n", .{probeRecurse(std.math.maxInt(u32))});
            return;
        }
    }
    var env = Env.init(a);
    defer env.deinit();
    try env.push(); // 全局作用域：REPL 靠它跨行保留状态
    defer env.pop();

    // ── 33.1 三阶段流水线 ────────────────────────────────────────
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

    // ── 33.2 词法 ────────────────────────────────────────────────
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

    // ── 33.3 位置 ────────────────────────────────────────────────
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

    // ── 33.4 优先级爬升 ──────────────────────────────────────────
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

    // ── 33.5 union(enum) 布局 ────────────────────────────────────
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

    // ── 33.6 求值 ────────────────────────────────────────────────
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

    // ── 33.7 let / var ───────────────────────────────────────────
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

    // ── 33.8 内建表 ──────────────────────────────────────────────
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

    // ── 33.9 错误 ────────────────────────────────────────────────
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

    // ── 33.10 深度闸门 ───────────────────────────────────────────
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

    // ── 33.11 遮蔽与作用域 ───────────────────────────────────────
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

    // ── 33.12 优先级/结合性表验证 ────────────────────────────────
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

    // ── 33.13 边界与溢出 ─────────────────────────────────────────
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

    // ── 33.14 REPL 行协议 ────────────────────────────────────────
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

    // ── 收尾自检 ─────────────────────────────────────────────────
    {
        _ = try runProgram(a, &env, "var w = 5");
        const v = try runValue(a, &env, "w * w + 1");
        std.debug.print("自检：w*w+1 = {d}（期望 26）\n", .{v});
        for ([_][]const u8{ "nosuch(1)", "q + 1", "1 / 0" }) |bad| {
            if (runValue(a, &env, bad)) |_| {
                std.debug.print("自检失败：{s} 竟然成功了\n", .{bad});
                return error.SelfCheckFailed;
            } else |_| {}
        }
        std.debug.print("自检通过\n", .{});
    }
}

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

// ═══ 33.15 测试：每层都能单独测 ═══

/// 测试侧的"开一个全局作用域"辅助。⚠️ 顶层作用域必须存在，
/// 否则 Env.declare 里的 scopes.items[len-1] 会越界。
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

fn pos0() Pos {
    return .{ .offset = 0, .line = 1, .col = 1 };
}

test "词法：记号序列与关键字定型" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const toks = try lex(arena.allocator(), "let x = 1", null);
    const kinds = [_]TokenKind{ .let_kw, .ident, .eq, .num, .eof };
    try std.testing.expectEqual(kinds.len, toks.len);
    for (kinds, toks) |want, got| try std.testing.expectEqual(want, got.kind);
}

test "词法：位置含行列，换行推进行号" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const toks = try lex(arena.allocator(), "1 +\n  2", null);
    try std.testing.expectEqual(@as(u32, 1), toks[0].pos.line);
    try std.testing.expectEqual(@as(u32, 1), toks[0].pos.col);
    try std.testing.expectEqual(@as(u32, 3), toks[1].pos.col); // '+' 在第 3 格
    try std.testing.expectEqual(@as(u32, 2), toks[2].pos.line);
    try std.testing.expectEqual(@as(u32, 3), toks[2].pos.col); // 换行后列号归 1 再数两格
}

test "词法：小数点前瞻，非法字符走 BadChar" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const toks = try lex(a, "1.5", null);
    try std.testing.expectEqual(@as(usize, 2), toks.len);
    try std.testing.expectEqualStrings("1.5", toks[0].text);
    // 前瞻的用处：第二个 '.' 后面没有数字，不是小数点，
    // 孤立的 '.' 落到 switch 的 else ⇒ BadChar（而不是被并进数字）
    try std.testing.expectError(error.BadChar, lex(a, "1..2", null));
    try std.testing.expectError(error.BadChar, lex(a, "1 $ 2", null));
}

test "语法：优先级把树拧成右子树" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const e = (try parseOnly(arena.allocator(), "1 + 2 * 3"))[0].expr;
    try std.testing.expectEqual(@as(f64, 1), e.*.binary.lhs.*.num.v); // 左边是裸 1
    try std.testing.expectEqual(@as(TokenKind, .plus), e.*.binary.op);
}

test "语法：右结合 vs 左结合的树形" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const right = try parseOnly(a, "2 ^ 3 ^ 2");
    try std.testing.expectEqual(@as(f64, 2), right[0].expr.*.binary.lhs.*.num.v);
    const left = try parseOnly(a, "1 - 2 - 3");
    // 左结合 ⇒ 顶层是第二个 -，左孩子是 (1 - 2) 子树，最左才是裸 1
    try std.testing.expectEqual(@as(f64, 1), left[0].expr.*.binary.lhs.*.binary.lhs.*.num.v);
    try std.testing.expectEqual(@as(f64, 2), left[0].expr.*.binary.lhs.*.binary.rhs.*.num.v);
}

test "语法：一元负号不进 binary" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const e = (try parseOnly(arena.allocator(), "- - 5"))[0].expr;
    try std.testing.expectEqual(@as(TokenKind, .minus), e.*.unary.op);
    try std.testing.expectEqual(@as(TokenKind, .minus), e.*.unary.child.*.unary.op);
}

test "语法：括号不进 AST" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    // 括号被 parsePrimary 丢掉了，剩下的就是一个裸 num 节点
    try std.testing.expectEqual(@as(f64, 1), (try parseOnly(arena.allocator(), "(1)"))[0].expr.*.num.v);
}

test "语法：赋值与表达式靠两格前瞻区分" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const stmts = try parseOnly(arena.allocator(), "x = 1; x + 1");
    try std.testing.expectEqual(std.meta.activeTag(stmts[0]), .assign);
    try std.testing.expectEqual(std.meta.activeTag(stmts[1]), .expr);
}

test "语法错误：缺右括号 / 尾部有剩 / 缺操作数" {
    try expectFails("(1", error.SyntaxError);
    try expectFails("1 2", error.SyntaxError);
    try expectFails("1 +", error.SyntaxError);
    try expectFails("1 $ 2", error.BadChar);
}

test "求值：六种二元运算符 + 一元负号" {
    try expectValue("1 + 2 * 3", 7);
    try expectValue("(1 + 2) * 3", 9);
    try expectValue("10 - 3 - 2", 5);
    try expectValue("100 / 10 / 5", 2);
    try expectValue("17 % 5", 2);
    try expectValue("2 ^ 10", 1024);
    try expectValue("-4 + 10", 6);
    try expectValue("- - 5", 5);
    try expectValue("7 / 2", 3.5);
}

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

test "变量：let 不可赋值，var 可以" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var env = freshEnv(a);
    defer env.deinit();
    _ = try runProgram(a, &env, "let x = 5");
    try std.testing.expectError(error.ImmutableBinding, runProgram(a, &env, "x = 9"));
    _ = try runProgram(a, &env, "var y = 5");
    try std.testing.expectApproxEqAbs(@as(f64, 9), try runValue(a, &env, "y = 9"), 1e-9);
}

test "变量：未定义标识符带位置" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var env = freshEnv(a);
    defer env.deinit();
    var diag: Diag = .{};
    try std.testing.expectError(
        error.UnknownIdentifier,
        runProgramDiag(a, &env, "  q + 1", &diag, default_max_depth),
    );
    try std.testing.expectEqual(@as(u32, 3), diag.pos.col); // 两个空格后 q 在第 3 格
}

test "作用域：遮蔽后恢复" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var env = freshEnv(a);
    defer env.deinit();
    _ = try runProgram(a, &env, "var x = 1");
    try std.testing.expectApproxEqAbs(@as(f64, 20), try runValue(a, &env, "{ var x = 2; x * 10 }"), 1e-9);
    try std.testing.expectApproxEqAbs(@as(f64, 1), try runValue(a, &env, "x"), 1e-9);
}

test "作用域：块内定义不出块" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var env = freshEnv(a);
    defer env.deinit();
    try std.testing.expectApproxEqAbs(@as(f64, 7), try runValue(a, &env, "{ var y = 7; y }"), 1e-9);
    try std.testing.expectError(error.UnknownIdentifier, runProgram(a, &env, "y"));
}

test "内建：常量与一元二元函数" {
    try expectValue("pi", std.math.pi);
    try expectValue("e", std.math.e);
    try expectValue("pi()", std.math.pi);
    try expectValue("abs(0 - 7)", 7);
    try expectValue("min(3, 7)", 3);
    try expectValue("max(3, 7)", 7);
    try expectValue("floor(7 / 2)", 3);
    try expectValue("ceil(7 / 2)", 4);
    try expectValue("sqrt(9)", 3);
}

test "内建：arity 与未知函数" {
    try expectFails("sqrt(1, 2)", error.ArityMismatch);
    try expectFails("sqrt()", error.ArityMismatch);
    try expectFails("nosuch(1)", error.UnknownFunction);
}

test "内建表：编译期不变量 + 按 arity 喂参数" {
    try std.testing.expectEqual(@as(usize, 8), builtin_count);
    try std.testing.expectEqual(@as(usize, 2), builtin_max_arity);
    for (builtin_table, 0..) |b, i| {
        for (builtin_table, 0..) |c, j| {
            if (i != j) try std.testing.expect(!std.mem.eql(u8, b.name, c.name));
        }
    }
    // ⚠️ 传 0 个参数给 1 元内建会**运行期越界 panic**（args[0] 越界），
    // 所以必须按表里的 arity 切片，不能一律传空。
    const one: [1]f64 = .{9};
    const pair: [2]f64 = .{ 3, 7 };
    for (builtin_table) |b| switch (b.arity) {
        0 => try std.testing.expect(b.apply(&.{}) > 2.5), // pi 或 e
        1 => try std.testing.expect(b.apply(one[0..1]) > 0),
        2 => try std.testing.expect(b.apply(pair[0..2]) == 3 or b.apply(pair[0..2]) == 7),
        else => unreachable,
    };
}

test "错误：除零与词法错误分离" {
    try expectFails("1 / 0", error.DivisionByZero);
    try expectFails("10 / (4 - 4)", error.DivisionByZero);
    try expectFails("1 $ 2", error.BadChar);
}

test "深度：括号嵌套在解析期触发 TooDeep" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const src = try a.alloc(u8, 201);
    for (0..100) |k| {
        src[k] = '(';
        src[200 - k] = ')';
    }
    src[100] = '1';
    var env = freshEnv(a);
    defer env.deinit();
    try std.testing.expectError(error.TooDeep, runProgram(a, &env, src));
}

test "深度：加法长链解析浅但求值深" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var chain: std.ArrayList(u8) = .empty;
    try chain.appendSlice(a, "1");
    for (0..999) |_| try chain.appendSlice(a, " + 1");
    // 解析**成功**：左结合由 while 循环消化，递归层数恒为 1。
    var diag: Diag = .{};
    var p: Parser = .{ .toks = try lex(a, chain.items, null), .a = a, .diag = &diag };
    const stmts = try p.parseProgram();
    try std.testing.expectEqual(@as(usize, 1), stmts.len);
    try std.testing.expectEqual(@as(u32, 0), p.depth); // 已回落
    // 但求值沿左脊递归 1000 层 ⇒ eval 侧闸门开火。解析浅 ≠ 求值浅。
    var env = freshEnv(a);
    defer env.deinit();
    try std.testing.expectError(error.TooDeep, runProgram(a, &env, chain.items));
    // 短链两端都过得去
    var short: std.ArrayList(u8) = .empty;
    try short.appendSlice(a, "1");
    for (0..30) |_| try short.appendSlice(a, " + 1");
    try std.testing.expectApproxEqAbs(@as(f64, 31), try runValue(a, &env, short.items), 1e-9);
}

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

test "REPL：逐行协议、空行收束、takeDelimiterExclusive 的坑" {
    const script = "var t = 4\nt * t\n\nt = t + 1\nt\n";
    var reader = std.Io.Reader.fixed(script);
    var n: usize = 0;
    while (try nextLine(&reader)) |line| {
        n += 1;
        try std.testing.expect(line.len <= 9); // 最长的一行是 "var t = 4"
    }
    try std.testing.expectEqual(@as(usize, 5), n); // 4 行内容 + 中间 1 个空行
    try std.testing.expectEqual(@as(?[]const u8, null), try nextLine(&reader));
    // 反证：0.17 的 takeDelimiterExclusive 不消费缓冲，第二次拿到空串
    var buggy = std.Io.Reader.fixed("var k = 3\nk + 1\n");
    try std.testing.expectEqualStrings("var k = 3", try buggy.takeDelimiterExclusive('\n'));
    try std.testing.expectEqualStrings("", try buggy.takeDelimiterExclusive('\n'));
    try std.testing.expectEqualStrings("\nk + 1\n", buggy.buffered());
}

test "REPL：状态跨行保留" {
    const script = "var k = 3\nk + 1\n";
    var reader = std.Io.Reader.fixed(script);
    var env = Env.init(std.heap.page_allocator);
    defer env.deinit();
    try env.push();
    defer env.pop();
    var seen: usize = 0;
    while (try nextLine(&reader)) |line| {
        const t = std.mem.trim(u8, line, " \t\r");
        if (t.len == 0) continue;
        const v = try runValue(std.heap.page_allocator, &env, t);
        if (seen == 1) try std.testing.expectApproxEqAbs(@as(f64, 4), v, 1e-9);
        seen += 1;
    }
    try std.testing.expectEqual(@as(usize, 2), seen);
}
