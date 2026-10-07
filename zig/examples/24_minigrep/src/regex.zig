//! 24.4–24.6 迷你 grep 的正则引擎：递归下降解析 → 指令数组 → 回溯执行
//!
//! 三层结构，逐层对应文档的 24.4 / 24.5 / 24.6：
//!
//!   1. **语法层**（parseAlt / parseConcat / parseRepeat / parseAtom）：递归下降。
//!      四层函数对应文法的四个产生式，每层只管一层，靠"上一层决定下一层的边界"消歧。
//!   2. **指令层**（Program / Op）：把语法树**压平成一条线性指令数组**。
//!      树形结构彻底丢掉，只剩 `Split(x, y)` / `Jump(x)` 两种控制流。
//!   3. **执行层**（find）：带回溯栈的栈式虚拟机。栈里存"回到哪个 pc、
//!      从文本的哪个位置继续"——**这就是回溯的全部实现**，没有别的魔法。
//!
//! 一个刻意的决定：**解析器只有一份**（`parsePattern` 用 `comptime ct` 参数
//! 同时服务运行期与 comptime 期），不给 comptime 写第二遍。
//! 重复一遍解析器 = 两处逻辑可能不同步 = 一类极难查的 bug。
const std = @import("std");

/// 指令数组的容量上限（运行期与 comptime 共用同一个值）。
/// 超了编译期/运行期直接报 TooManyOps，不做静默截断。
pub const max_ops = 256;

/// 编译期（模式串 → 指令）可能出的错
pub const CompileError = error{
    /// `(` 没闭合
    UnclosedGroup,
    /// 有多余的 `)`
    UnmatchedClose,
    /// `[` 没闭合，或 `[]` 空类
    UnclosedClass,
    /// `*` `+` `?` 前面没有可重复的原子（如 `*abc`）
    NothingToRepeat,
    /// 同一个原子连写两个量词（`a**`）。POSIX 也禁止，这里显式拒绝而不是猜
    RepeatedQuantifier,
    /// `[z-a]` 反向区间
    ReversedRange,
    /// `\` 后面啥都没有，或 `\x` 位数不足
    DanglingEscape,
    /// `{}` 重复计数本引擎不支持——显式报错，好过默默当字面量
    UnsupportedRepeat,
    /// 字符类区间段数超上限（max_ranges）
    TooManyRanges,
    /// 指令条数超上限（max_ops）
    TooManyOps,
    OutOfMemory,
};

/// 运行期（指令 → 匹配）可能出的错
pub const ExecError = error{
    /// 回溯步数超预算：典型的灾难性回溯，见 24.6 的实测。
    /// 这是**手写回溯引擎唯一的护栏**
    TooManySteps,
    OutOfMemory,
};

/// 编译产物：一条平坦的指令数组。
/// **注意这里没有 AST**——这是整个引擎设计的核心决定（24.5）。
pub const Program = struct {
    ops: []const Op,
    /// 模式串里 `()` 的个数
    group_count: usize = 0,
    /// 模式以 `^` 开头：只需从位置 0 起试（省一个 O(n) 因子）
    anchored_start: bool = false,
    /// 编译诊断：模式多长、编出多少条指令（"指令膨胀比"）
    pattern_len: usize = 0,
    op_count: usize = 0,

    pub fn deinit(self: Program, gpa: std.mem.Allocator) void {
        gpa.free(self.ops);
    }
};

/// 一条指令。用 `union(enum)` 而非"enum + payload 数组"，因为各变体载荷
/// 差异极大（char 只要 1 字节，class 要整张区间表），塞进 union 最省内存。
///
/// 载荷里的 `u32` 是**指令下标（pc）**，指向 ops 数组内的位置。
/// pc 0 是第一条指令——执行器的初始 pc 恒为 0。
pub const Op = union(enum) {
    /// 匹配一个字面字节
    char: u8,
    /// 匹配任意字节，但**不含换行**（正则默认语义：`.` 不跨行）
    any: void,
    /// 匹配字符类（正向）
    class: Class,
    /// 匹配字符类（取反，即 `[^...]`）
    class_neg: Class,
    /// 分支：先试 `pc[0]`，失败则回溯走 `pc[1]`。
    /// **谁在 pc[0] 谁就是贪婪**——非贪婪就是把两个下标对调（24.4.3）。
    split: [2]u32,
    /// 无条件跳转。**允许往回跳**，`X*` 的回边就靠它
    jump: u32,
    /// `^`：只在文本位置 0 处成功
    bol: void,
    /// `$`：只在文本末尾处成功
    eol: void,
    /// 匹配终点。指令数组的**最后一条**必须是它
    accept: void,

    /// 反汇编成一行人类可读文本（24.5 展示用）。返回借用 `buf` 的切片。
    /// `std.Io.Writer.fixed(buf)` 直接返回 `Writer`（**没有** `.interface` 字段，
    /// 与 `File.writer(io, buf)` 不同——后者才要 `.interface`，20 章实测）。
    pub fn text(self: Op, i: u32, buf: []u8) []const u8 {
        var fw = std.Io.Writer.fixed(buf);
        const w = &fw;
        w.print("{d:>3}  ", .{i}) catch return buf[0..0];
        switch (self) {
            .char => |c| {
                if (c >= 0x20 and c < 0x7f) {
                    w.print("char    '{c}'  (0x{x:0>2})", .{ c, c }) catch return buf[0..0];
                } else {
                    w.print("char    0x{x:0>2}", .{c}) catch return buf[0..0];
                }
            },
            .any => w.writeAll("any     任意字节（除 \\n）") catch return buf[0..0],
            .class => |c| {
                w.writeAll("class   ") catch return buf[0..0];
                writeClass(w, c, false) catch return buf[0..0];
            },
            .class_neg => |c| {
                w.writeAll("class⁻  ") catch return buf[0..0];
                writeClass(w, c, true) catch return buf[0..0];
            },
            .split => |t| {
                w.print("split   x={d} y={d}", .{ t[0], t[1] }) catch return buf[0..0];
                // 往回跳 = 环 = 量词；两个下标里"先试的那个"决定贪婪性
                if (t[0] > t[1]) w.writeAll("   ← 非贪婪") catch return buf[0..0];
                if (t[1] < t[0]) w.writeAll("   ← 回边（量词）") catch return buf[0..0];
            },
            .jump => |t| {
                w.print("jump    → {d}", .{t}) catch return buf[0..0];
                if (t <= i) w.writeAll("   ← 回边") catch return buf[0..0];
            },
            .bol => w.writeAll("bol     ^ 行首锚点") catch return buf[0..0],
            .eol => w.writeAll("eol     $ 行尾锚点") catch return buf[0..0],
            .accept => w.writeAll("accept  匹配终点") catch return buf[0..0],
        }
        return w.buffered();
    }
};

/// 字节区间集合。上限 16 段——够写所有现实字符类；
/// 超了返回 TooManyRanges 而**不是**静默截断
/// （静默截断会让 `[a-zA-Z0-9_]` 少匹配一半，还不报错）。
pub const max_ranges = 16;

pub const Range = struct { lo: u8, hi: u8 };

pub const Class = struct {
    ranges: [max_ranges]Range,
    len: u8 = 0,

    pub const empty: Class = .{ .ranges = undefined, .len = 0 };

    pub fn add(self: *Class, lo: u8, hi: u8) CompileError!void {
        if (self.len >= max_ranges) return error.TooManyRanges;
        self.ranges[self.len] = .{ .lo = lo, .hi = hi };
        self.len += 1;
    }

    /// `-i` 时把待匹配字节的小写与大写形式都试一遍。
    /// 比编译期把每段区间展开成大小写两份更省指令，运行期也只多两次比较。
    pub fn matches(self: *const Class, ch: u8, ignore_case: bool) bool {
        if (self.rawMatch(ch)) return true;
        if (!ignore_case) return false;
        const lower = std.ascii.toLower(ch);
        if (lower != ch and self.rawMatch(lower)) return true;
        const upper = std.ascii.toUpper(ch);
        return upper != ch and self.rawMatch(upper);
    }

    fn rawMatch(self: *const Class, ch: u8) bool {
        for (self.ranges[0..self.len]) |r| {
            if (ch >= r.lo and ch <= r.hi) return true;
        }
        return false;
    }
};

fn writeClass(w: *std.Io.Writer, c: Class, negated: bool) !void {
    if (negated) try w.writeAll("[^");
    for (c.ranges[0..c.len], 0..) |r, i| {
        if (i > 0) try w.writeAll(",");
        if (r.lo == r.hi) {
            try w.print("{c}", .{r.lo});
        } else {
            try w.print("{c}-{c}", .{ r.lo, r.hi });
        }
    }
    try w.writeByte(']');
}

// ════════════════════════════════════════════════════════════════════
//  第一层 + 第二层：递归下降解析 → 指令数组
// ════════════════════════════════════════════════════════════════════
//
//  文法（Backus-Naur 形式，24.4.0 给出全文）：
//
//      alt       := concat ('|' concat)*
//      concat    := repeat*
//      repeat    := atom quantifier?
//      quantifier := ('*' | '+' | '?') '?'?
//      atom      := '(' alt ')' | '[' class ']'
//                 | '.' | '^' | '$' | '\' escape | 普通字节
//
//  每个 parseXxx 都往 `out`（指令数组）**追加**指令。指令下标就是数组下标，
//  所以"回填"只是改写某个下标上的值——**一个字节都不用挪**。
//  这是把树压平之后最大的好处：没有重排，全是原地打补丁。

/// 指令数组写入器。
///
/// 刻意**不**为 comptime / 运行期各写一份：`put` 统一返回 `error.TooManyOps`，
/// 编译期调用点上用 `catch @panic(...)` 转成编译错误。于是 24.4 的解析器
/// 只有这一份实现，24.5 的 comptime 生成不需要重写逻辑——
/// 重复一遍解析器 = 两处逻辑可能不同步 = 一类极难查的 bug。
const Emitter = struct {
    buf: *[max_ops]Op,
    n: *usize,

    fn put(self: *Emitter, op: Op) CompileError!u32 {
        const pc: u32 = @intCast(self.n.*);
        if (self.n.* >= max_ops) return error.TooManyOps;
        self.buf[self.n.*] = op;
        self.n.* += 1;
        return pc;
    }

    /// 原地回填。pc 一定 < n，不会越界（所有回填点都是刚 append 过的）
    fn set(self: *Emitter, pc: u32, op: Op) void {
        if (pc < self.n.*) self.buf[pc] = op;
    }
};

/// 解析游标。刻意做成"一个位置 + 一个写入器 + 一个分组计数"，
/// 让「递归下降 = 函数调用栈」这件事看得最清楚。
const Parser = struct {
    pat: []const u8,
    pos: usize = 0,
    em: *Emitter,
    group_count: usize = 0,
    /// **会消费输入**的指令条数（char / any / class / class_neg / 锚点）。
    /// 用来判断一个 atom 是否"什么都没匹配"——`()` 就是这种：
    /// 它会产出两条占位 jump（不算消费），所以光比 em.n 看不出来。
    consuming: usize = 0,

    fn peek(self: *const Parser) ?u8 {
        return if (self.pos < self.pat.len) self.pat[self.pos] else null;
    }

    fn at(self: *const Parser, ahead: usize) ?u8 {
        return if (self.pos + ahead < self.pat.len) self.pat[self.pos + ahead] else null;
    }

    fn advance(self: *Parser) void {
        self.pos += 1;
    }

    fn put(self: *Parser, op: Op) CompileError!u32 {
        return self.em.put(op);
    }

    fn set(self: *Parser, pc: u32, op: Op) void {
        self.em.set(pc, op);
    }
};

/// alt := concat ('|' concat)*
///
/// 消歧：`|` 的优先级最低，所以 alt 调 concat、concat 遇 `|` 就停——
/// 两边天然互不越界，**不需要任何优先级表**。
///
/// 右递归：`a|b|c` 解析成 `a | (b | c)`（右结合）。
/// 对 `|` 来说结合方向不影响语义（`(a|b)|c` 与 `a|(b|c)` 等价），
/// 但代码只写一遍就够。
fn parseAlt(p: *Parser) CompileError!void {
    // 先占一个槽：即使后面发现没有 `|`，这个槽也留着一指令宽，
    // 这样 concat 里 atom 的起始下标不会因为"有没有分支"而漂移。
    // 占位值先填 0，稍后由 p.set 回填——此处 slot 还没定义，不能自引用。
    const slot = try p.put(.{ .jump = 0 });
    const left_start = slot + 1;

    try parseConcat(p);

    if (p.peek() != '|') {
        // 没有 `|`：这条指令退化成"跳到下一条"，语义等价于空操作。
        // 保留它（而不是删掉）是为了让所有 pc 保持稳定——这是压平指令的代价。
        p.set(slot, .{ .jump = slot + 1 });
        return;
    }
    p.advance(); // 吃掉 '|'

    const jmp = try p.put(.{ .jump = 0 }); // 汇合跳转，先占位
    const right_start: u32 = @intCast(p.em.n.*);
    try parseAlt(p); // 右侧递归
    const join: u32 = @intCast(p.em.n.*);

    p.set(slot, .{ .split = .{ left_start, right_start } });
    p.set(jmp, .{ .jump = join });
}

/// concat := repeat*
///
/// 消歧：终止符 `|` 和 `)` **不在任何 atom 的起始字符集里**，
/// 所以 concat 吃到它们就自然收手，把控制权交还 alt。
/// 这就是"`|` 优先级最低"的全部实现——一个 if，不用查表。
fn parseConcat(p: *Parser) CompileError!void {
    while (p.peek()) |c| {
        if (c == '|' or c == ')') break;
        try parseRepeat(p);
    }
}

/// repeat := atom quantifier?
///
/// 消歧（**本章最核心的一段**）：量词只作用于**紧邻的前一个 atom**。
/// 所以 `ab*` 是 `a` 后跟 `b*`，不是 `(ab)*`。
/// 这不靠"贪心"或"就近结合"这类约定，靠的是文法本身——
/// repeat 每次只吃一个 atom，然后立刻吃掉它后面所有连续量词（至多一个）。
///
/// 量词后紧跟的另一个 `?` 是**非贪婪修饰**（`a*?` = 懒惰的 `a*`），
/// 这和 `a?`（可选的 a）是两件事，靠"吃掉量词后再看一个字符"区分开。
fn parseRepeat(p: *Parser) CompileError!void {
    const before = p.consuming;
    const slot = try parseAtom(p);
    var quantified = false;
    if (p.peek()) |c| {
        if (c == '*' or c == '+' or c == '?') {
            // 量词必须作用于**能消费输入的** atom。
            // `()` 只产出占位 jump（consuming 不变），`()*` 属于"重复零宽"，
            // POSIX 明确不定义，各引擎行为不一——我们直接报错，不猜。
            if (p.consuming == before) return error.NothingToRepeat;
            p.advance();
            // 惰性标志：紧跟量词之后的另一个 '?'
            const lazy = if (p.peek() == '?') blk: {
                p.advance();
                break :blk true;
            } else false;
            try applyQuantifier(p, slot, c, lazy);
            quantified = true;
            // 连写量词（a**、a*?*）一律拒绝：语义各实现分歧，别猜
            if (p.peek()) |c2| {
                if (c2 == '*' or c2 == '+' or c2 == '?') return error.RepeatedQuantifier;
            }
        }
    }
    if (!quantified) {
        // 没有量词 ⇒ 预留槽位退化成"跳到 slot+1"，也就是**原子指令本身**。
        // 注意不能跳到 p.em.n.*：原子指令就排在 slot+1 之后，跳到 n 会把
        // 它们整段跳过（`abc` 会编译成 jump,char,jump,char,jump,char → 直接 accept）。
        // 漏掉这一步更糟：槽位保持占位值 0，执行器从 pc=0 跳回 pc=0 死循环。
        p.set(slot, .{ .jump = slot + 1 });
    }
}

/// 把落在 `[slot+1, atom_end)` 的原子包进量词。
///
/// **预留槽位**是这段代码的全部技巧：`parseAtom` 先 append 一条占位指令占住
/// 下标 `slot`，真正的原子指令追加在它**后面**。于是量词要把分支指令放在
/// 原子**前面**时，只要把 `slot` 原地改写成分支即可——**一个字节都不用挪**。
///
/// 四种量词的编法（`X` = 原子指令，脚手架 `slot`，原子起点 `xs = slot+1`，
/// `atom_end` = 原子结束后的下一个下标）：
///
///     X?   ⇒  slot:  Split(xs, atom_end)      贪婪：先试一次 X
///             xs:    <X>
///             atom_end:
///
///     X??  ⇒  slot:  Split(atom_end, xs)      **两个下标对调** = 非贪婪
///
///     X*   ⇒  slot:  Split(xs, after)         贪婪：先跑一遍 X 再问要不要停
///             xs:    <X>
///             after: Split(xs, done)          跑完还能再来一次
///             done:
///
///     X*?  ⇒  slot:  Split(after, xs)         **入口就倒过来**：能停就停
///             xs:    <X>
///             after: Split(done, xs)          回边也倒过来
///             done:
///
///     X+   ⇒  xs:    <X>                      至少先匹配一个（顺序执行保证）
///             after: Split(xs, done)          之后等价于 X*
///             done:
///
///     X+?  ⇒  after 的下标对调
///
/// ⚠️ **惰性要改两处，不是一处**。这是本章最容易写错的地方：
/// `X*` 有两个决策点——"要不要进第一次 X"（slot）和"要不要再来一次"（after）。
/// 只倒转 after 的话，`a*?` 匹配 "aaaa" 仍会先吃掉一个 a（实测得到 0-1 而不是 0-0）。
/// 两处都倒转，`a*?` 才真的"能停就停"（实测 0-0）。
fn applyQuantifier(p: *Parser, slot: u32, q: u8, lazy: bool) CompileError!void {
    const xs = slot + 1;
    const atom_end: u32 = @intCast(p.em.n.*);

    switch (q) {
        '?' => {
            // 0 或 1 次：分支的两条路分别是"进 X"和"跳过 X"
            p.set(slot, if (lazy)
                .{ .split = .{ atom_end, xs } }
            else
                .{ .split = .{ xs, atom_end } });
        },
        '*' => {
            // 回边放在原子**之后**（而不是之前）：跑完 X 再问"再来一次？"
            // 这与"进循环前先问"的语义等价，但不需要移动任何指令。
            const after = try p.put(.{ .split = .{ xs, atom_end + 1 } });
            const done = after + 1;
            p.set(after, if (lazy)
                .{ .split = .{ done, xs } }
            else
                .{ .split = .{ xs, done } });
            // 入口也要按贪婪性翻转（惰性的第一处，见上面的警告）
            p.set(slot, if (lazy)
                .{ .split = .{ after, xs } }
            else
                .{ .split = .{ xs, after } });
        },
        '+' => {
            // 与 X* 的回边一模一样；区别只是 slot 不做分支——
            // "至少先跑一次 X"由顺序执行天然保证
            const after = try p.put(.{ .split = .{ xs, atom_end + 1 } });
            const done = after + 1;
            p.set(after, if (lazy)
                .{ .split = .{ done, xs } }
            else
                .{ .split = .{ xs, done } });
            p.set(slot, .{ .jump = xs });
        },
        else => unreachable, // parseRepeat 只传 * + ?
    }
}

/// atom := '(' alt ')' | '[' class ']' | '.' | '^' | '$' | '\' escape | 普通字节
///
/// 返回"预留槽位"的下标。**空分组 `()` 也返回有效槽位**——
/// parseRepeat 用 `p.consuming` 前后差值判断它没消费任何输入，
/// 于是 `()*` 被报成 NothingToRepeat，而不是编出一条什么都不做的 `*`。
fn parseAtom(p: *Parser) CompileError!u32 {
    const c = p.peek() orelse return error.NothingToRepeat;
    const slot = try p.put(.{ .jump = 0 }); // 预留槽位，稍后回填
    p.advance();

    // 注意每个分支都写成 `_ = try p.put(...)`：put 返回新指令的 pc，
    // 而这里我们不关心它（只有 parseAlt / applyQuantifier 需要拿 pc 去回填）。
    // 每条"会消费输入"的指令都要同步 p.consuming += 1。
    switch (c) {
        '(' => {
            p.group_count += 1;
            try parseAlt(p); // 内层的 consuming 增量直接累加到 p 上
            if (p.peek() != ')') return error.UnclosedGroup;
            p.advance();
        },
        '[' => {
            try parseClass(p);
            p.consuming += 1;
        },
        '.' => {
            _ = try p.put(.{ .any = {} });
            p.consuming += 1;
        },
        '^' => {
            _ = try p.put(.{ .bol = {} });
            p.consuming += 1;
        },
        '$' => {
            _ = try p.put(.{ .eol = {} });
            p.consuming += 1;
        },
        '\\' => {
            _ = try p.put(.{ .char = try escape(p) });
            p.consuming += 1;
        },
        '*', '+', '?' => return error.NothingToRepeat,
        '{' => return error.UnsupportedRepeat, // 不支持 {n,m}：显式拒绝
        ']' => {
            _ = try p.put(.{ .char = ']' }); // 单独的 ] 在正则里是字面量
            p.consuming += 1;
        },
        else => {
            _ = try p.put(.{ .char = c });
            p.consuming += 1;
        },
    }
    return slot;
}

/// `[...]` 字符类。产出 `.class` 或 `.class_neg`——**取反在编译期就定下来**，
/// 运行期不必再查一个 negated 标志位，也省掉一次分支。
fn parseClass(p: *Parser) CompileError!void {
    var negated = false;
    if (p.peek() == '^') {
        negated = true;
        p.advance();
    }
    var cls: Class = .{ .ranges = undefined, .len = 0 };
    var count: usize = 0;
    while (true) {
        const c = p.peek() orelse return error.UnclosedClass;
        if (c == ']') {
            p.advance();
            break;
        }
        count += 1;
        var lo = c;
        if (c == '\\') {
            p.advance();
            lo = try escape(p);
        } else {
            p.advance();
        }
        // `a-z` 只有在后面确实跟着 `-` 且 `-` 后面不是收尾的 `]` 时才是区间；
        // 否则 `[a-]` 是 "a 或 -"，`[a-z]` 才是区间。这是 POSIX 的规则。
        if (p.peek() == '-' and p.at(1) != null and p.at(1) != ']') {
            p.advance(); // '-'
            const hc = p.peek() orelse return error.UnclosedClass;
            var hi = hc;
            if (hc == '\\') {
                p.advance();
                hi = try escape(p);
            } else {
                p.advance();
            }
            if (hi < lo) return error.ReversedRange;
            try cls.add(lo, hi);
        } else {
            try cls.add(lo, lo);
        }
    }
    if (count == 0) return error.UnclosedClass; // `[]` 空类
    _ = try p.put(if (negated) .{ .class_neg = cls } else .{ .class = cls });
}

/// 转义后的一字节。既支持常见缩写（`\n` `\t` `\x41`），
/// 也支持"转义任意元字符"（`\.` `\\` `\[`）——这是 POSIX 的标准行为。
fn escape(p: *Parser) CompileError!u8 {
    const c = p.peek() orelse return error.DanglingEscape;
    p.advance();
    return switch (c) {
        'n' => '\n',
        't' => '\t',
        'r' => '\r',
        'f' => 0x0c,
        'v' => 0x0b,
        'a' => 0x07,
        'e' => 0x1b,
        '0' => 0,
        'b' => 0x08,
        // 类内缩写按 POSIX 展开成区间（parseClass 里 add 会拆成多段）
        'd' => '0',
        'w' => 'a',
        's' => ' ',
        'D' => 'D',
        'W' => 'W',
        'S' => 'S',
        'x' => blk: { // \xHH 两位十六进制
            var v: u16 = 0;
            var k: usize = 0;
            while (k < 2) : (k += 1) {
                const h = p.peek() orelse return error.DanglingEscape;
                const d = std.fmt.charToDigit(h, 16) catch return error.DanglingEscape;
                v = v * 16 + d;
                p.advance();
            }
            break :blk @intCast(v);
        },
        else => c, // \. \\ \[ … 任何元字符转义回自己
    };
}

/// 运行期编译：模式串来自命令行，所以要走分配器。
///
/// 两点值得注意：
/// 1. 指令先写进**栈上定长数组** `scratch`，解析完再 `dupe` 出精确长度的堆切片。
///    定长数组让"pc 就是下标"成立；最后那一次拷贝换来的是
///    "调用者只看到一个长度刚好的 `[]const Op`"，不用替它操心 scratch 容量。
/// 2. 只有这一次分配。**编译一次、匹配 N 行**——所以这摊开销可以忽略。
pub fn compile(gpa: std.mem.Allocator, pattern: []const u8) CompileError!Program {
    var scratch: [max_ops]Op = undefined;
    var n: usize = 0;
    var em: Emitter = .{ .buf = &scratch, .n = &n };
    var p: Parser = .{ .pat = pattern, .em = &em };

    try parseAlt(&p);
    // 顶层解析完必须正好走到末尾，剩下的都是多余的 ')'
    if (p.pos != p.pat.len) return error.UnmatchedClose;
    // 收尾：最后一条必须是 accept，否则执行器的栈永远弹空、永远"不匹配"
    _ = try em.put(.{ .accept = {} });

    const owned = try gpa.dupe(Op, scratch[0..n]);
    return .{
        .ops = owned,
        .group_count = p.group_count,
        .anchored_start = pattern.len > 0 and pattern[0] == '^',
        .pattern_len = pattern.len,
        .op_count = n,
    };
}

/// **comptime 版**：模式串是字面量时，正则的语法分析、量词展开、
/// pc 回填**全部在编译期完成**，二进制里只剩一条指令数组，
/// 运行期零解析开销。24.5 的核心演示。
///
/// `ops` 指向 `comptime` 局部变量——Zig 允许把 comptime 变量
/// 的地址放进返回的 `Program`，因为它的生命周期是整个程序。
pub fn compileComptime(comptime pattern: []const u8) Program {
    // 关键技巧：指令数组必须是 **const**（编译期常量，进 .rodata），
    // 不能是 `comptime var`。Zig 明令禁止把 `comptime var` 的地址泄漏到运行期
    // （实测报错：runtime value contains reference to comptime var）——
    // 因为 comptime var 是"编译器工作区里的临时量"，不是程序的静态数据。
    //
    // 所以这里在 comptime 块里解析到一个局部 scratch，最后
    // `const frozen = scratch[0..n]` **拷贝**成常量数组再返回。
    // 拷贝只发生在编译期，运行期零成本。
    const Result = struct { ops: []const Op, groups: usize, n: usize };
    const r: Result = outer: {
        @setEvalBranchQuota(20_000);
        var scratch: [max_ops]Op = undefined;
        var cnt: usize = 0;
        var em: Emitter = .{ .buf = &scratch, .n = &cnt };
        var p: Parser = .{ .pat = pattern, .em = &em };
        parseAlt(&p) catch @panic("compileComptime: 模式串非法");
        if (p.pos != pattern.len) @panic("compileComptime: 模式串有多余的 )");
        _ = em.put(.{ .accept = {} }) catch @panic("compileComptime: 指令太多");
        // 必须拷进一个**匿名 const 数组**再切片——只切 scratch 的话
        // 返回的指针仍然指向那个 comptime var，逃逸到运行期会被拒绝
        const frozen: [cnt]Op = scratch[0..cnt].*;
        break :outer .{ .ops = frozen[0..], .groups = p.group_count, .n = cnt };
    };
    return .{
        .ops = r.ops,
        .group_count = r.groups,
        .anchored_start = pattern.len > 0 and pattern[0] == '^',
        .pattern_len = pattern.len,
        .op_count = r.n,
    };
}

// ════════════════════════════════════════════════════════════════════
//  第三层：带回溯栈的执行
// ════════════════════════════════════════════════════════════════════

pub const Options = struct {
    /// `-i`：大小写不敏感
    ignore_case: bool = false,
    /// 回溯步数预算。超了返回 error.TooManySteps。
    /// **这是手写回溯引擎唯一的护栏**，也是它敢拿来搜不可信输入的底气（24.6）
    max_steps: u64 = 2_000_000,
};

/// 命中的字节区间 `[start, end)`
pub const Span = struct { start: usize, end: usize };

/// 回溯栈的一个格子：**回到哪个 pc、从文本哪个位置继续**。
/// 就这两样。没有"匹配了哪些子表达式"——因为本引擎不捕获分组。
const Frame = struct { pc: u32, pos: usize };

pub const Stats = struct {
    /// 实际消耗的回溯步数——24.6 用它把复杂度**量化成一个整数**
    steps: u64 = 0,
    /// 试过的起始位置数
    starts: u64 = 0,
};

/// 从 `start_pos` 起找第一个匹配，返回它的**结束位置**（`null` = 没匹配上）。
///
/// 返回 `end` 而不是 `Span` 是刻意的：调用方本来就知道 `start_pos`，
/// 省掉一次结构体传递。
fn matchFrom(
    gpa: std.mem.Allocator,
    prog: *const Program,
    text: []const u8,
    start_pos: usize,
    opt: Options,
    stack: *std.ArrayList(Frame),
    stats: *Stats,
) ExecError!?usize {
    stack.clearRetainingCapacity();
    try stack.append(gpa, .{ .pc = 0, .pos = start_pos });

    // 外层 while 弹栈（回溯），内层 while 顺序执行指令（前进）
    while (stack.pop()) |fr| {
        var pc = fr.pc;
        var pos = fr.pos;
        while (true) {
            stats.steps += 1;
            if (stats.steps > opt.max_steps) return error.TooManySteps;

            switch (prog.ops[pc]) {
                .char => |c| {
                    if (pos >= text.len) break;
                    if (!charEq(text[pos], c, opt.ignore_case)) break;
                    pos += 1;
                    pc += 1;
                },
                .any => {
                    // `.` 不跨行——这是正则的默认语义（POSIX 与 grep 一致），
                    // 要跨行得开 dotall，本引擎不提供这个开关
                    if (pos >= text.len or text[pos] == '\n') break;
                    pos += 1;
                    pc += 1;
                },
                .class => |cls| {
                    if (pos >= text.len) break;
                    if (!cls.matches(text[pos], opt.ignore_case)) break;
                    pos += 1;
                    pc += 1;
                },
                .class_neg => |cls| {
                    if (pos >= text.len) break;
                    if (cls.matches(text[pos], opt.ignore_case)) break;
                    pos += 1;
                    pc += 1;
                },
                .split => |t| {
                    // ★ 回溯的全部秘密就在这一行 ★
                    // 把"另一条路 + 当前文本位置"压栈，然后先走优先的那条。
                    // 优先那条走不通时，栈顶弹出来就是**回溯现场**：
                    // 文本位置一步都不用回退（因为它就存在栈里）。
                    try stack.append(gpa, .{ .pc = t[1], .pos = pos });
                    pc = t[0];
                },
                .jump => |t| pc = t,
                .bol => {
                    if (pos != 0) break;
                    pc += 1;
                },
                .eol => {
                    if (pos != text.len) break;
                    pc += 1;
                },
                .accept => return pos,
            }
        }
    }
    return null;
}

fn charEq(a: u8, b: u8, ignore_case: bool) bool {
    if (a == b) return true;
    if (!ignore_case) return false;
    return std.ascii.toLower(a) == std.ascii.toLower(b);
}

/// 找**最左匹配**：从左往右扫每个起始位置，第一个成功的即返回。
///
/// 这就是 grep 的语义。但注意：由于 `Split` 的贪婪编法，
/// 每个起点内部拿到的自然是**最长**的那个——
/// "最左" + "最长"合起来正是 POSIX 的**左长匹配**规则，
/// 它不是额外规定，而是这个执行器结构的自然结果。
pub fn find(
    gpa: std.mem.Allocator,
    prog: *const Program,
    text: []const u8,
    opt: Options,
) ExecError!?Span {
    var stats: Stats = .{};
    return findWithStats(gpa, prog, text, opt, &stats);
}

pub fn findWithStats(
    gpa: std.mem.Allocator,
    prog: *const Program,
    text: []const u8,
    opt: Options,
    stats: *Stats,
) ExecError!?Span {
    var stack: std.ArrayList(Frame) = .empty;
    defer stack.deinit(gpa);
    // 容量预分配：起点数上限就是 text.len+1
    try stack.ensureTotalCapacity(gpa, text.len + 1);

    var start: usize = 0;
    while (start <= text.len) : (start += 1) {
        stats.starts += 1;
        // `^` 开头的模式只可能从 0 起匹配，一次失败就不用再试
        if (prog.anchored_start and start > 0) break;
        if (try matchFrom(gpa, prog, text, start, opt, &stack, stats)) |end| {
            return .{ .start = start, .end = end };
        }
    }
    return null;
}

/// 找出所有不重叠的匹配（给高亮用）。
///
/// 零宽匹配（如 `a*`）的推进规则：`end == start` 时把 start 加 1，
/// 否则外层循环原地不动——这是所有"全局替换"实现都必须处理的一处。
pub fn findAll(
    gpa: std.mem.Allocator,
    prog: *const Program,
    text: []const u8,
    opt: Options,
) ExecError![]Span {
    var list: std.ArrayList(Span) = .empty;
    errdefer list.deinit(gpa);

    var at: usize = 0;
    while (at <= text.len) {
        const hit = try find(gpa, prog, text[at..], opt) orelse break;
        try list.append(gpa, .{ .start = at + hit.start, .end = at + hit.end });
        at = if (hit.end == hit.start) at + hit.start + 1 else at + hit.end;
    }
    return list.toOwnedSlice(gpa);
}

/// 判断是否匹配——grep 每行都要问一次这个，所以单列一个省掉 Span 构造
pub fn matches(
    gpa: std.mem.Allocator,
    prog: *const Program,
    text: []const u8,
    opt: Options,
) ExecError!bool {
    return (try find(gpa, prog, text, opt)) != null;
}

/// 把指令数组反汇编成人类可读文本——24.5 的展示用
pub fn dump(w: *std.Io.Writer, prog: *const Program) !void {
    for (prog.ops, 0..) |op, i| {
        var buf: [96]u8 = undefined;
        try w.print("{s}\n", .{op.text(@intCast(i), &buf)});
    }
}

// ════════════════════════════════════════════════════════════════════
//  测试（24.11）：引擎的每个分支都要被断言到
// ════════════════════════════════════════════════════════════════════

/// 测试辅助：编译 + 找第一个匹配，把区间写进 `out`（"s-e" 或 "-"）。
/// **返回借用栈上缓冲**，所以测试里不需要 free——这一条同时消掉了
/// 早期版本"每个 test 都泄漏 3 个 allocPrint"的问题。
fn matchSpan(pattern: []const u8, text: []const u8, out: []u8) ![]const u8 {
    const gpa = std.testing.allocator;
    const prog = try compile(gpa, pattern);
    defer prog.deinit(gpa);
    const hit = try find(gpa, &prog, text, .{}) orelse {
        out[0] = '-';
        return out[0..1];
    };
    return std.fmt.bufPrint(out, "{d}-{d}", .{ hit.start, hit.end }) catch out[0..0];
}

/// 逐字段比较两条指令。**不能用 `expectEqualSlices(Op, ...)`**：
/// `Op` 的 `class` 变体里 `Class.ranges` 是定长数组，`len` 之后的槽位
/// 从未写入（`undefined`），整条指令做 `==` / `meta.eql` 就是在比内存垃圾。
/// 实测这正是 24.11 那条测试最初失败的原因。
fn opsEqual(a: Op, b: Op) bool {
    if (std.meta.activeTag(a) != std.meta.activeTag(b)) return false;
    return switch (a) {
        .char => |v| v == b.char,
        .any, .bol, .eol, .accept => true,
        .split => |v| v[0] == b.split[0] and v[1] == b.split[1],
        .jump => |v| v == b.jump,
        .class => |v| classEqual(v, b.class),
        .class_neg => |v| classEqual(v, b.class_neg),
    };
}

fn classEqual(a: Class, b: Class) bool {
    if (a.len != b.len) return false;
    for (a.ranges[0..a.len], b.ranges[0..b.len]) |x, y| {
        if (x.lo != y.lo or x.hi != y.hi) return false;
    }
    return true;
}

test "字面量：最左匹配 + 精确区间" {
    var b: [16]u8 = undefined;
    try std.testing.expectEqualStrings("2-5", try matchSpan("abc", "xxabcxx", &b));
    try std.testing.expectEqualStrings("0-3", try matchSpan("abc", "abcabc", &b));
    try std.testing.expectEqualStrings("-", try matchSpan("abc", "ab", &b));
}

test "点号 any：匹配任意字节但**不跨换行**" {
    var b: [16]u8 = undefined;
    try std.testing.expectEqualStrings("0-1", try matchSpan(".", "x", &b));
    try std.testing.expectEqualStrings("-", try matchSpan(".", "\n", &b));
    try std.testing.expectEqualStrings("-", try matchSpan("a.c", "a\nc", &b));
    try std.testing.expectEqualStrings("0-3", try matchSpan("a.c", "abc", &b));
}

test "字符类：区间、单点、取反" {
    var b: [16]u8 = undefined;
    try std.testing.expectEqualStrings("1-2", try matchSpan("[abc]", "zbz", &b));
    try std.testing.expectEqualStrings("0-1", try matchSpan("[a-c]", "b", &b));
    try std.testing.expectEqualStrings("-", try matchSpan("[^a-c]", "b", &b));
    try std.testing.expectEqualStrings("0-1", try matchSpan("[^a-c]", "zb", &b));
    // `[a-]` 是"a 或 -"，不是区间——POSIX 的这条规则实测成立
    try std.testing.expectEqualStrings("0-1", try matchSpan("[a-]", "-", &b));
}

test "量词 *：贪婪吃到不能再吃，空串处给零宽匹配" {
    var b: [16]u8 = undefined;
    try std.testing.expectEqualStrings("0-4", try matchSpan("a*", "aaaa", &b));
    // "aaab" 里 a* 只吃前三个 a（b 不是 a）——实测 0-3，不是 0-4
    try std.testing.expectEqualStrings("0-3", try matchSpan("a*", "aaab", &b));
    try std.testing.expectEqualStrings("0-0", try matchSpan("a*", "bbb", &b));
}

test "量词 * 的贪婪 vs 非惰性：入口与回边都要翻转" {
    var b: [16]u8 = undefined;
    try std.testing.expectEqualStrings("0-4", try matchSpan("a*", "aaaa", &b));
    // 实测：只翻回边会得到 0-1（错），两处都翻才得到 0-0
    try std.testing.expectEqualStrings("0-0", try matchSpan("a*?", "aaaa", &b));
    try std.testing.expectEqualStrings("0-3", try matchSpan("a*?b", "aab", &b));
    try std.testing.expectEqualStrings("0-3", try matchSpan("a*b", "aab", &b));
}

test "量词 +：至少一次，与 * 的关键差别是不匹配空串" {
    var b: [16]u8 = undefined;
    try std.testing.expectEqualStrings("0-3", try matchSpan("a+", "aaab", &b));
    try std.testing.expectEqualStrings("-", try matchSpan("a+", "b", &b));
    // 非贪婪 a+? 只吃一个就停（实测 0-1）
    try std.testing.expectEqualStrings("0-1", try matchSpan("a+?", "aaab", &b));
}

test "量词 ?：可选；非贪婪 ? 让它优先不匹配" {
    var b: [16]u8 = undefined;
    try std.testing.expectEqualStrings("0-1", try matchSpan("a?", "abc", &b));
    try std.testing.expectEqualStrings("0-0", try matchSpan("a?", "bcd", &b));
    try std.testing.expectEqualStrings("0-2", try matchSpan("a??b", "ab", &b));
    try std.testing.expectEqualStrings("0-2", try matchSpan("a?b", "ab", &b));
}

test "量词只作用于紧邻的前一个 atom（消歧核心）" {
    var b: [16]u8 = undefined;
    // ab* == a + b*，**不是** (ab)*：实测 ab* 匹配 aab 只吃到 "a"
    try std.testing.expectEqualStrings("0-1", try matchSpan("ab*", "aab", &b));
    try std.testing.expectEqualStrings("0-0", try matchSpan("(ab)*", "aab", &b));
    try std.testing.expectEqualStrings("0-4", try matchSpan("(ab)*", "abab", &b));
}

test "或 |：左右分支都能到" {
    var b: [16]u8 = undefined;
    try std.testing.expectEqualStrings("4-7", try matchSpan("cat|dog", "the dog", &b));
    try std.testing.expectEqualStrings("4-7", try matchSpan("cat|dog", "the cat", &b));
    try std.testing.expectEqualStrings("-", try matchSpan("cat|dog", "the bird", &b));
}

test "分组 ()：改变优先级边界" {
    var b: [16]u8 = undefined;
    try std.testing.expectEqualStrings("0-2", try matchSpan("ab|cd", "abcd", &b));
    try std.testing.expectEqualStrings("0-3", try matchSpan("a(b|c)d", "acd", &b));
    try std.testing.expectEqualStrings("0-3", try matchSpan("a(b|c)d", "abd", &b));
    try std.testing.expectEqualStrings("0-2", try matchSpan("((ab))", "abzz", &b));
}

test "锚点 ^ 与 $：只在文本两端成立" {
    var b: [16]u8 = undefined;
    try std.testing.expectEqualStrings("0-3", try matchSpan("^abc", "abcdef", &b));
    try std.testing.expectEqualStrings("-", try matchSpan("^bcd", "abcdef", &b));
    try std.testing.expectEqualStrings("3-6", try matchSpan("def$", "abcdef", &b));
    try std.testing.expectEqualStrings("-", try matchSpan("cde$", "abcdef", &b));
    // `^` 开头的模式被记成 anchored_start，执行器只试起点 0
    const gpa = std.testing.allocator;
    const prog = try compile(gpa, "^x");
    defer prog.deinit(gpa);
    try std.testing.expect(prog.anchored_start);
    try std.testing.expect(!compile2IsUnanchored(gpa));
}

fn compile2IsUnanchored(gpa: std.mem.Allocator) bool {
    const p = compile(gpa, "x") catch return true;
    defer p.deinit(gpa);
    return p.anchored_start;
}

test "量词作用于分组：(ab)+" {
    var b: [16]u8 = undefined;
    try std.testing.expectEqualStrings("0-4", try matchSpan("(ab)+", "ababx", &b));
    try std.testing.expectEqualStrings("0-2", try matchSpan("(ab)+", "abx", &b));
}

test "findAll：所有不重叠匹配，供高亮用" {
    const gpa = std.testing.allocator;
    const prog = try compile(gpa, "ab");
    defer prog.deinit(gpa);
    const spans = try findAll(gpa, &prog, "abXabYab", .{});
    defer gpa.free(spans);
    try std.testing.expectEqual(@as(usize, 3), spans.len);
    try std.testing.expectEqual(@as(usize, 0), spans[0].start);
    try std.testing.expectEqual(@as(usize, 3), spans[1].start);
    try std.testing.expectEqual(@as(usize, 6), spans[2].start);
}

test "findAll：零宽匹配不会死循环（a* 匹配 bbb）" {
    const gpa = std.testing.allocator;
    const prog = try compile(gpa, "a*");
    defer prog.deinit(gpa);
    // 若零宽推进规则写成 at = at + hit.end，这里会 hang
    const spans = try findAll(gpa, &prog, "bbb", .{});
    defer gpa.free(spans);
    try std.testing.expectEqual(@as(usize, 4), spans.len); // 位置 0,1,2,3 各一个零宽匹配
}

test "ignore_case：-i 走 Class.matches / charEq，不改写模式" {
    const gpa = std.testing.allocator;
    const prog = try compile(gpa, "[a-z]+");
    defer prog.deinit(gpa);
    try std.testing.expect((try find(gpa, &prog, "ABC", .{})) == null);
    const hit = (try find(gpa, &prog, "ABC", .{ .ignore_case = true })).?;
    try std.testing.expectEqual(@as(usize, 0), hit.start);
    try std.testing.expectEqual(@as(usize, 3), hit.end);

    // 字面量路径走的是 charEq，同样要支持 -i
    const lit = try compile(gpa, "Error");
    defer lit.deinit(gpa);
    try std.testing.expect((try find(gpa, &lit, "an ERROR here", .{})) == null);
    try std.testing.expect((try find(gpa, &lit, "an error here", .{ .ignore_case = true })) != null);
}

test "编译错误：十种都要能报出来（而不是默默猜）" {
    const gpa = std.testing.allocator;
    try std.testing.expectError(error.UnclosedGroup, compile(gpa, "(ab"));
    try std.testing.expectError(error.UnmatchedClose, compile(gpa, "ab)"));
    try std.testing.expectError(error.UnclosedClass, compile(gpa, "[a-z"));
    try std.testing.expectError(error.UnclosedClass, compile(gpa, "[]"));
    try std.testing.expectError(error.NothingToRepeat, compile(gpa, "*ab"));
    try std.testing.expectError(error.NothingToRepeat, compile(gpa, "()*"));
    try std.testing.expectError(error.RepeatedQuantifier, compile(gpa, "a**"));
    try std.testing.expectError(error.ReversedRange, compile(gpa, "[z-a]"));
    try std.testing.expectError(error.DanglingEscape, compile(gpa, "a\\"));
    try std.testing.expectError(error.UnsupportedRepeat, compile(gpa, "a{2,3}"));
    try std.testing.expectError(error.TooManyRanges, compile(gpa, "[abcdefghijklmnopq]"));
    var long_pattern: [max_ops + 8]u8 = undefined;
    @memset(&long_pattern, 'a');
    try std.testing.expectError(error.TooManyOps, compile(gpa, &long_pattern));
}

test "转义：\\n \\xHH 与元字符自转义" {
    var b: [16]u8 = undefined;
    try std.testing.expectEqualStrings("0-3", try matchSpan("a\\nb", "a\nb", &b));
    try std.testing.expectEqualStrings("-", try matchSpan("a\\nb", "anb", &b));
    // \. 必须匹配字面点，而不是"任意字节"
    try std.testing.expectEqualStrings("0-3", try matchSpan("a\\.c", "a.c", &b));
    try std.testing.expectEqualStrings("-", try matchSpan("a\\.c", "abc", &b));
    try std.testing.expectEqualStrings("1-2", try matchSpan("\\x41", "xAy", &b));
}

test "指令膨胀比：模式 N 字节编出约 2N 条指令（24.5 的直观证据）" {
    const gpa = std.testing.allocator;
    // 每个 atom 两条（预留槽 + 本体），再加 alt 的槽与收尾 accept
    const abc = try compile(gpa, "abc");
    defer abc.deinit(gpa);
    try std.testing.expectEqual(@as(usize, 3), abc.pattern_len);
    try std.testing.expectEqual(@as(usize, 8), abc.op_count);

    // 量词只 +1 条（回边），但多出一个槽位
    const star = try compile(gpa, "a*");
    defer star.deinit(gpa);
    try std.testing.expectEqual(@as(usize, 5), star.op_count);

    // 分组比不加括号多两条槽位
    const grp = try compile(gpa, "(a)");
    defer grp.deinit(gpa);
    try std.testing.expectEqual(@as(usize, 6), grp.op_count);
    try std.testing.expectEqual(@as(usize, 1), grp.group_count);

    // 每多一个 | 多两条（分支 split + 汇合 jump）
    const alt1 = try compile(gpa, "a|b");
    defer alt1.deinit(gpa);
    const alt3 = try compile(gpa, "a|b|c");
    defer alt3.deinit(gpa);
    try std.testing.expectEqual(alt1.op_count + 4, alt3.op_count);

    // 真实世界模式：14 字节 → 20 条指令
    const real = try compile(gpa, "s*rvice=[a-z]+");
    defer real.deinit(gpa);
    try std.testing.expectEqual(@as(usize, 20), real.op_count);
}

test "comptime 生成：与运行期编译逐指令相同（24.5 的核心断言）" {
    // 这一条是全章最重要的测试：它保证 comptime 版**不是另一套实现**。
    // 如果哪天有人给 comptime 路径单独写了个简化版，这个测试立刻红。
    const gpa = std.testing.allocator;
    inline for (.{
        "abc",           "a*",      "a+?", "a??",    "^x", "[a-z]+", "(ab|cd)*", "s*rvice=[a-z]+",
        "(ERROR|WARN)+", "a(b|c)d", "\\.", "[^a-c]",
    }) |pat| {
        const ct = comptime compileComptime(pat);
        const rt = try compile(gpa, pat);
        defer rt.deinit(gpa);
        try std.testing.expectEqual(rt.op_count, ct.op_count);
        try std.testing.expectEqual(ct.ops.len, rt.ops.len);
        for (ct.ops, rt.ops) |a, b| {
            try std.testing.expect(opsEqual(a, b));
        }
        try std.testing.expectEqual(ct.group_count, rt.group_count);
        try std.testing.expectEqual(ct.anchored_start, rt.anchored_start);
        try std.testing.expectEqual(ct.pattern_len, rt.pattern_len);
    }
}

test "comptime 生成的程序能真的跑起来（不是只比形状）" {
    const gpa = std.testing.allocator;
    // ops 指向编译期常量数组（.rodata），运行期只读不写
    const prog = comptime compileComptime("(ERROR|WARN)+");
    const hit = (try find(gpa, &prog, "xxWARNEYyy", .{})).?;
    try std.testing.expectEqual(@as(usize, 2), hit.start);
    try std.testing.expectEqual(@as(usize, 6), hit.end);

    // 多个 comptime 程序可以共存，互不干扰
    const p2 = comptime compileComptime("[0-9]+");
    const h2 = (try find(gpa, &p2, "abc 12345 def", .{})).?;
    try std.testing.expectEqual(@as(usize, 4), h2.start);
    try std.testing.expectEqual(@as(usize, 9), h2.end);
}

test "回溯步数统计：字面量是线性的一档（24.6 的基线数据）" {
    const gpa = std.testing.allocator;
    const prog = try compile(gpa, "abc");
    defer prog.deinit(gpa);
    var stats: Stats = .{};
    const hit = try findWithStats(gpa, &prog, "aaaaaaaaaaaaaaaaaaaaXabc", .{}, &stats);
    try std.testing.expect(hit != null);
    // 23 个 a + X + abc：最左匹配在 offset 21 命中，起点 0..21 共试 22 次
    // （不是 25 次——命中即返回，这是 grep 语义带来的早退）
    try std.testing.expectEqual(@as(u64, 22), stats.starts);
    // 每个起点最多 8 条指令（abc 编译出 8 条）⇒ 上界 192
    try std.testing.expect(stats.steps <= 24 * 8);
    try std.testing.expect(stats.steps > 0);
}

test "max_steps 护栏：灾难性回溯被挡住而不是把机器卡死（24.6）" {
    const gpa = std.testing.allocator;
    // (a+)+b 撞上 "aaaa...a"（无 b）是教科书级的灾难性回溯输入
    const evil = try compile(gpa, "(a+)+b");
    defer evil.deinit(gpa);
    var text: [24]u8 = undefined;
    @memset(&text, 'a');

    var stats: Stats = .{};
    const res = findWithStats(gpa, &evil, &text, .{ .max_steps = 50_000 }, &stats);
    try std.testing.expectError(error.TooManySteps, res);
    // 步数确实被打到预算上限附近（而不是碰巧很快）
    try std.testing.expect(stats.steps > 40_000);
}
