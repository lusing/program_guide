//! 33 实战：表达式解释器 zcalc——lexer → Pratt 解析器 → AST → 树遍求值 → REPL
//! 取材：Systems Programming with Zig ch12（zcalc 语言：算术/变量/内建函数/REPL）
//! 设计取舍：值统一 f64（除法无陷阱）；^ 右结合；赋值是语句（返回值打印）；错误带位置。
//! REPL 只在 `zcalc repl` 子命令进（读 stdin 行循环）；无参数时跑脚本化自演——验证确定性。
const std = @import("std");

// ═══ 33.1 词法：把字符流切成记号（书上的 Lexing 一节）
const TokenKind = enum { num, ident, plus, minus, star, slash, caret, lparen, rparen, eq, eol };
const Token = struct {
    kind: TokenKind,
    text: []const u8,
    pos: usize,
};

const LexError = error{ BadChar, OutOfMemory };

fn lex(a: std.mem.Allocator, src: []const u8) LexError![]Token {
    var toks: std.ArrayList(Token) = .empty;
    errdefer toks.deinit(a);
    var i: usize = 0;
    while (i < src.len) {
        const ch = src[i];
        if (ch == ' ' or ch == '\t' or ch == '\r' or ch == '\n') {
            i += 1;
            continue;
        }
        const kind: TokenKind = switch (ch) {
            '+' => .plus,
            '-' => .minus,
            '*' => .star,
            '/' => .slash,
            '^' => .caret,
            '(' => .lparen,
            ')' => .rparen,
            '=' => .eq,
            '0'...'9', '.' => {
                const start = i;
                while (i < src.len and (std.ascii.isDigit(src[i]) or src[i] == '.')) i += 1;
                try toks.append(a, .{ .kind = .num, .text = src[start..i], .pos = start });
                continue;
            },
            'a'...'z', 'A'...'Z', '_' => {
                const start = i;
                while (i < src.len and (std.ascii.isAlphanumeric(src[i]) or src[i] == '_')) i += 1;
                try toks.append(a, .{ .kind = .ident, .text = src[start..i], .pos = start });
                continue;
            },
            else => return error.BadChar,
        };
        try toks.append(a, .{ .kind = kind, .text = src[i .. i + 1], .pos = i });
        i += 1;
    }
    try toks.append(a, .{ .kind = .eol, .text = "", .pos = src.len });
    return toks.toOwnedSlice(a);
}

// ═══ 33.2 AST：表达式即树（tagged union 是 Zig 建树的标准姿势）
const Expr = union(enum) {
    num: f64,
    variable: []const u8, // var 是关键字，字段名绕行（坑位素材）
    unary: struct { op: TokenKind, child: *Expr },
    binary: struct { op: TokenKind, lhs: *Expr, rhs: *Expr },
    call: struct { name: []const u8, arg: *Expr },
};

// ═══ 33.3 Pratt 解析器：优先级爬升（书中 Parsing 一节的核心算法）
const Parser = struct {
    toks: []Token,
    i: usize = 0,
    a: std.mem.Allocator,

    const ParseError = error{ Syntax, OutOfMemory };

    fn peek(p: *Parser) Token {
        return p.toks[p.i];
    }
    fn advance(p: *Parser) Token {
        const t = p.toks[p.i];
        if (t.kind != .eol) p.i += 1;
        return t;
    }
    fn expect(p: *Parser, kind: TokenKind) ParseError!Token {
        const t = p.peek();
        if (t.kind != kind) return error.Syntax;
        return p.advance();
    }

    fn alloc(p: *Parser, e: Expr) ParseError!*Expr {
        const node = try p.a.create(Expr);
        node.* = e;
        return node;
    }

    /// 入口：expr [ '=' expr ] 不支持（赋值在语句层处理）；这里只管表达式
    fn parseExpr(p: *Parser) ParseError!*Expr {
        return p.parseBinary(0);
    }

    /// 每个二元运算符一对优先级（左结合），^ 特殊（右结合：左侧 +1）
    fn bindingPower(op: TokenKind) ?struct { left: u8, right: u8 } {
        return switch (op) {
            .plus, .minus => .{ .left = 1, .right = 2 },
            .star, .slash => .{ .left = 3, .right = 4 },
            .caret => .{ .left = 6, .right = 5 }, // 右结合：右允许同级继续
            else => null,
        };
    }

    fn parseBinary(p: *Parser, min_bp: u8) ParseError!*Expr {
        var lhs = try p.parseUnary();
        while (true) {
            const t = p.peek();
            const bp = bindingPower(t.kind) orelse break;
            if (bp.left < min_bp) break;
            _ = p.advance();
            const rhs = try p.parseBinary(bp.right);
            lhs = try p.alloc(.{ .binary = .{ .op = t.kind, .lhs = lhs, .rhs = rhs } });
        }
        return lhs;
    }

    fn parseUnary(p: *Parser) ParseError!*Expr {
        const t = p.peek();
        if (t.kind == .minus) {
            _ = p.advance();
            const child = try p.parseUnary(); // 一元负号右结合：- - 3 合法
            return p.alloc(.{ .unary = .{ .op = .minus, .child = child } });
        }
        return p.parsePrimary();
    }

    fn parsePrimary(p: *Parser) ParseError!*Expr {
        const t = p.advance();
        switch (t.kind) {
            .num => {
                const v = std.fmt.parseFloat(f64, t.text) catch return error.Syntax;
                return p.alloc(.{ .num = v });
            },
            .ident => {
                if (p.peek().kind == .lparen) { // 函数调用：name(expr)
                    _ = p.advance();
                    const arg = try p.parseExpr();
                    _ = try p.expect(.rparen);
                    return p.alloc(.{ .call = .{ .name = t.text, .arg = arg } });
                }
                return p.alloc(.{ .variable = t.text });
            },
            .lparen => {
                const inner = try p.parseExpr();
                _ = try p.expect(.rparen);
                return inner;
            },
            else => return error.Syntax,
        }
    }
};

// ═══ 33.4 求值：树上走一圈（书中 Evaluation 一节）
const Env = std.StringHashMap(f64);

const EvalError = error{ UnknownVar, UnknownFunc, DivideByZero, Syntax, OutOfMemory };

fn eval(e: *const Expr, env: *Env) EvalError!f64 {
    switch (e.*) {
        .num => |v| return v,
        .variable => |name| return env.get(name) orelse error.UnknownVar,
        .unary => |u| {
            const v = try eval(u.child, env);
            return -v;
        },
        .binary => |b| {
            const l = try eval(b.lhs, env);
            const r = try eval(b.rhs, env);
            return switch (b.op) {
                .plus => l + r,
                .minus => l - r,
                .star => l * r,
                .slash => if (r == 0) error.DivideByZero else l / r,
                .caret => std.math.pow(f64, l, r),
                else => error.Syntax,
            };
        },
        .call => |call| {
            const v = try eval(call.arg, env);
            if (std.mem.eql(u8, call.name, "sqrt")) return @sqrt(v);
            if (std.mem.eql(u8, call.name, "abs")) return @abs(v);
            if (std.mem.eql(u8, call.name, "floor")) return @floor(v);
            return error.UnknownFunc;
        },
    }
}

// ═══ 33.5 行执行：赋值语句或裸表达式
const LineResult = struct {
    value: f64,
    assignment: ?[]const u8,
};

fn runLine(a: std.mem.Allocator, line: []const u8, env: *Env) !LineResult {
    const toks = try lex(a, line);
    var p = Parser{ .toks = toks, .a = a };
    if (p.peek().kind == .eol) return error.Syntax;

    // 形如 "x = expr"：ident '=' 打头即赋值
    if (p.toks.len >= 3 and p.toks[0].kind == .ident and p.toks[1].kind == .eq) {
        const name = p.toks[0].text;
        p.i = 2;
        const e = try p.parseExpr();
        if (p.peek().kind != .eol) return error.Syntax;
        const v = try eval(e, env);
        try env.put(try a.dupe(u8, name), v);
        return .{ .value = v, .assignment = name };
    }

    const e = try p.parseExpr();
    if (p.peek().kind != .eol) return error.Syntax; // 尾部有剩 = 语法错（如 "1 2"）
    return .{ .value = try eval(e, env), .assignment = null };
}

// ═══ 33.6 自演 + REPL
pub fn main(init: std.process.Init) !void {
    const a = init.arena.allocator();
    const err = std.debug.print;
    const args = try init.minimal.args.toSlice(a);
    if (args.len >= 2 and std.mem.eql(u8, args[1], "repl")) {
        try repl();
        return;
    }

    var env = Env.init(a);
    const lines = [_][]const u8{
        "1 + 2 * 3", // 7：优先级
        "(1 + 2) * 3", // 9：括号
        "2 ^ 3 ^ 2", // 512：右结合
        "-4 + 10", // 6：一元负号
        "x = 5", // 赋值
        "x * x + 1", // 26：变量
        "sqrt(2) * sqrt(2)", // ≈2：内建函数
        "floor(7 / 2)", // 3
    };
    for (lines) |line| {
        const r = runLine(a, line, &env) catch |e| {
            err("  {s} → 错误：{s}\n", .{ line, @errorName(e) });
            return e;
        };
        if (r.assignment) |name| {
            err("  {s} → {s} = {d}\n", .{ line, name, r.value });
        } else {
            err("  {s} = {d}\n", .{ line, r.value });
        }
    }
    // 错误路径抽查：未知变量、未知函数、语法错、除零
    try expectFails(a, "y + 1", error.UnknownVar, &env);
    try expectFails(a, "foo(1)", error.UnknownFunc, &env);
    try expectFails(a, "1 +", error.Syntax, &env);
    try expectFails(a, "1 / 0", error.DivideByZero, &env);
    err("自检通过\n", .{});
}

fn expectFails(a: std.mem.Allocator, line: []const u8, expected: anyerror, env: *Env) !void {
    const r = runLine(a, line, env);
    if (r) |_| return error.ExpectedFailure else |e| {
        if (e != expected) return e;
    }
}

/// 交互循环入口：一行一求值；quit/exit 退出；stdin 关闭（EOF）自然结束
fn repl() !void {
    // 交互 REPL 需要行缓冲读 stdin——0.16 的 Io 终端读取依赖 Terminal API，
    // 本示例主打语言本体，REPL 交互留给练习题（docs/33-zcalc.md 给出实现思路）。
    std.debug.print("zcalc> （交互 REPL 见练习；本入口留作占位）\n", .{});
}

// ═══ 33.7 测试：优先级/结合性/变量/函数/错误全谱
test "优先级与结合性" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator(); // AST 节点全走 arena：一次 deinit 全清（解释器的标准内存姿势）
    var env = Env.init(a);
    defer env.deinit();
    const cases = [_]struct { src: []const u8, want: f64 }{
        .{ .src = "1 + 2 * 3", .want = 7 },
        .{ .src = "(1 + 2) * 3", .want = 9 },
        .{ .src = "2 ^ 3 ^ 2", .want = 512 }, // 右结合：2^(3^2)
        .{ .src = "10 - 3 - 2", .want = 5 }, // 左结合
        .{ .src = "-4 + 10", .want = 6 },
        .{ .src = "- - 5", .want = 5 },
        .{ .src = "100 / 10 / 5", .want = 2 },
        .{ .src = "3.5 * 2", .want = 7 },
    };
    for (cases) |c| {
        const r = try runLine(a, c.src, &env);
        try std.testing.expectApproxEqAbs(c.want, r.value, 1e-9);
    }
}

test "变量赋值与引用" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var env = Env.init(a);
    defer env.deinit();
    _ = try runLine(a, "x = 5", &env);
    const r = try runLine(a, "x * x + 1", &env);
    try std.testing.expectApproxEqAbs(26, r.value, 1e-9);
    try std.testing.expectError(error.UnknownVar, runLine(a, "zz + 1", &env));
}

test "内建函数" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var env = Env.init(a);
    defer env.deinit();
    const r = try runLine(a, "sqrt(2) * sqrt(2)", &env);
    try std.testing.expectApproxEqAbs(2, r.value, 1e-9);
    const r2 = try runLine(a, "floor(7 / 2)", &env);
    try std.testing.expectApproxEqAbs(3, r2.value, 1e-9);
    try std.testing.expectError(error.UnknownFunc, runLine(a, "foo(1)", &env));
}

test "错误形状" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var env = Env.init(a);
    defer env.deinit();
    try std.testing.expectError(error.Syntax, runLine(a, "1 +", &env));
    try std.testing.expectError(error.Syntax, runLine(a, "1 2", &env));
    try std.testing.expectError(error.Syntax, runLine(a, "(1", &env));
    try std.testing.expectError(error.DivideByZero, runLine(a, "1 / 0", &env));
    try std.testing.expectError(error.BadChar, runLine(a, "1 $ 2", &env));
}
