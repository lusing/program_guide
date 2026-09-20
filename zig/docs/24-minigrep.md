# 24 · 实战：迷你 grep

> 对应示例：`examples/24_minigrep/`（build.zig 工程）
>
> 前面 23 章的合体：递归遍历 + 多线程 + 高亮 + 测试。与 cpp20 教程的收官章对齐。

## 24.0 需求与效果

```bash
cd examples/24_minigrep
zig build run -- zig src          # 在 src 里找 "zig"
```

实测输出（`\x1b[1;31m` 是 ANSI 红色加粗，终端里"zig"高亮）：

```text
src\main.zig:3: const search = @import("search.\x1b[1;31mzig\x1b[0m");
src\main.zig:52:     // ═══ 参数：模式 + 目录（默认 src，保证 \x1b[1;31mzig\x1b[0m build run 输出确定）
src\main.zig:101:     try tmp.dir.writeFile(io, .{ .sub_path = "a.txt", .data = "hello \x1b[1;31mzig\x1b[0m\nno match\n\x1b[1;31mzig\x1b[0m again" });
src\main.zig:103:     const hits = try search.searchLines(a, "hello \x1b[1;31mzig\x1b[0m\nno match\n\x1b[1;31mzig\x1b[0m again", "\x1b[1;31mzig\x1b[0m");
共 4 处命中，扫了 2 个文件（2 线程）
```

## 24.1 工程结构与可测试性设计

```text
24_minigrep/
├── build.zig / build.zig.zon    # 16 章模板
└── src/
    ├── search.zig               # 纯逻辑：搜索 + 高亮（不碰线程/IO/文件）→ 好测
    └── main.zig                 # 编排：参数、遍历、线程、输出
```

**核心决策：search 与 main 分层**——`searchLines`/`printHighlighted` 是纯函数（内存进内存出），线程和文件系统这种"难测的"全推给 main。于是核心逻辑的测试又快又稳（不建线程不碰盘），main 薄到不需要单测（端到端 tmpDir 兜底）。这是"可测试性设计"的最小示范。

## 24.2 search.zig：搜索核心

```zig
pub const Match = struct {
    path: []const u8,
    line_no: usize,
    line: []const u8,          // 借用 text 的内存——不拷贝
};

pub fn searchLines(allocator: std.mem.Allocator, text: []const u8, needle: []const u8) ![]Match {
    var hits: std.ArrayList(Match) = .empty;
    errdefer hits.deinit(allocator);                    // 10 章模式
    var line_it = std.mem.splitScalar(u8, text, '\n');  // 逐行切
    var n: usize = 0;
    while (line_it.next()) |line| {
        n += 1;
        if (std.mem.indexOf(u8, line, needle) != null) {
            try hits.append(allocator, .{ .path = "", .line_no = n, .line = line });
        }
    }
    return hits.toOwnedSlice(allocator);                // 12 章所有权转移
}

pub fn printHighlighted(w: *std.Io.Writer, path: []const u8, m: Match, needle: []const u8) !void {
    try w.print("{s}:{d}: ", .{ path, m.line_no });
    var rest = m.line;
    while (std.mem.indexOf(u8, rest, needle)) |at| {    // 每个命中段包一层转义
        try w.print("{s}\x1b[1;31m{s}\x1b[0m", .{ rest[0..at], rest[at .. at + needle.len] });
        rest = rest[at + needle.len ..];
    }
    try w.print("{s}\n", .{rest});
}
```

细品几个设计：**Match.line 借用不拷贝**（调用方保证 text 活着，性能零拷贝——24.5 主流程再 dupe）；`splitScalar` 逐行（空行也是行，行号才准）；高亮函数吃的是 02 章的 Writer 接口（stdout/文件/内存缓冲通吃）。

## 24.3 递归遍历

```zig
fn walkDir(io: std.Io, alloc: std.mem.Allocator, dir_path: []const u8,
           out: *std.ArrayList([]const u8)) !void {
    const cwd = std.Io.Dir.cwd();
    var dir = cwd.openDir(io, dir_path, .{ .iterate = true }) catch return;  // 无权限：跳过
    defer dir.close(io);
    var it = dir.iterate();
    while (try it.next(io)) |entry| {
        const full = try std.fs.path.join(alloc, &.{ dir_path, entry.name });
        switch (entry.kind) {
            .directory => try walkDir(io, alloc, full, out),   // 递归下钻
            .file => try out.append(alloc, full),
            else => {},                                         // 符号链接等：忽略
        }
    }
}
```

20 章目录 API 的实战应用：`entry.kind` 三分派，目录递归、文件收集、其余忽略。错误策略：**单目录打不开就跳过**（grep 遇到权限错误的目录不该整体失败）。返回文件列表而不是边走边搜——下一步要把"文件列表"分给线程（关注点分离）。

## 24.4 多线程：原子游标抢任务

```zig
var next: std.atomic.Value(usize) = std.atomic.Value(usize).init(0);
const Task = struct {
    fn run(w: *Worker, fl: []const []const u8, nx: *std.atomic.Value(usize),
           a: std.mem.Allocator) void {
        while (true) {
            const i = nx.fetchAdd(1, .monotonic);   // 原子抢号
            if (i >= fl.len) break;                  // 号超了 = 收工
            w.searchFile(a, fl[i]);                  // 快的线程多干，天然均衡
        }
    }
};
var threads: [4]std.Thread = undefined;
for (0..nt) |i| threads[i] = try std.Thread.spawn(.{}, Task.run, .{ &worker, files.items, &next, mem });
for (threads[0..nt]) |t| t.join();
```

19.6 的模式落地：**没有任务队列**——共享一个原子计数器，谁空谁抢（`fetchAdd` 保证不重号），慢文件不会卡住别人。`Worker.searchFile` 里读文件、搜行、**上锁合并结果**（锁区只有 append，符合 19 章锁区最小化）。线程数 `@min(4, 文件数)`——文件比线程少时不开空线程。

## 24.5 main 编排与内存策略

```zig
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();          // ← argv、文件列表、命中文本，一把全收
    const mem = arena_state.allocator();
    // ... 参数解析（22 章 Iterator）→ 遍历（24.3）→ 线程（24.4）
    var w = std.Io.File.stdout().writer(io, &buf);   // 02 章缓冲输出
    const out = &w.interface;
    for (worker.out.items) |m| try search.printHighlighted(out, m.path, m, needle);
    try out.print("共 {d} 处命中...\n", .{...});
    try out.flush();
}
```

**一次性程序 = arena 的完美场景**（11.4）：所有中间数据（路径、命中文本）同生共死，程序退出统一归还——全程没有一次手写 free，也没有泄漏。这是 11 章"分配器哲学"的收尾：选对了分配器，内存管理从"责任"变"背景"。

## 24.6 测试

```zig
test "searchLines 行号正确" { ... }            // 纯逻辑单测（快）
test "printHighlighted 含 ANSI 转义" {         // 输出逻辑用 fixed Writer 断言
    var buf: [128]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    try printHighlighted(&w, "f.txt", .{ .path = "f.txt", .line_no = 1, .line = "abxcd" }, "x");
    try std.testing.expect(std.mem.indexOf(u8, w.buffered(), "\x1b[1;31mx\x1b[0m") != null);
}
test "端到端：临时目录搜索" {                   // tmpDir 落盘 → 全链路
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(io, .{ .sub_path = "a.txt", .data = "hello zig\n..." });
    ...
}
```

三层测试各管一段：纯逻辑单测、输出断言（fixed Writer 把"打印"变"可断言的字符串"——20 章技巧）、tmpDir 端到端。`zig build test` 一键全跑（16 章）。

## 24.7 扩展练习

1. `-i` 大小写不敏感（提示：搜索前统一 `std.ascii.toLower` 到临时缓冲）
2. 二进制文件跳过（提示：前 1KB 出现 `\x00` 即判二进制）
3. 输出进管道时关颜色（提示：`File.Stat` / `Io.File` 的 isTty 判断，实测 API）
4. 行缓冲流式读大文件（替换 readFileAlloc，固定内存上限）

## 24.8 坑位清单

1. **Windows 旧终端不吃 ANSI**：Win10 1511+ 默认支持 VT 序列；老环境乱码——练习 3 的 isTty 判断顺便解决。
2. **`zig build run` 无参数打印用法并 exit 0**：这是设计（验证脚本友好）——真 grep 没参数该退非零，练习：区分"用法错误"与"无命中"。
3. **borrowed Match 的生命周期**：searchLines 的结果借用入参 text——main 里先 dupe 再存（Worker.searchFile 已做），否则 text free 后悬空。
4. **递归遍历的路径分隔符**：`path.join` 平台自适应——输出里 Windows 是 `\`、POSIX 是 `/`。断言路径的测试别写死 `\`，用 `"x" ++ std.fs.path.sep_str ++ "y.txt"` 拼平台常量（22 章示例即此跨平台写法）。

---
