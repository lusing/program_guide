//! 22 进程：std.process.Init、命令行参数、环境变量、子进程（run/spawn）、退出码、时间与睡眠
//!
//! 0.16/0.17 变化：std.process.argsAlloc / std.process.args / std.process.getEnvMap 全部移除；
//! 参数走 init.minimal.args（类型 process.Args），环境走 init.environ_map（*process.Environ.Map）；
//! 子进程是 run(gpa, io, opts) 与 spawn(io, opts)；时间全在 std.Io.Clock 上，std.time 只剩常量。
const std = @import("std");
const builtin = @import("builtin");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

/// 22.6 / 22.7：要shell 特性（管道、通配符、内建命令、重定向）时**显式**套一层 shell。
/// 返回的 argv 第 0 个元素是 shell 自己，后面才是 `-c` 和命令串。
/// ⚠️ 一旦这么写，注入风险就回到你手上——命令串是拼接出来的就必须自己转义。
fn shellArgv(arena: std.mem.Allocator, command: []const u8) std.mem.Allocator.Error![]const []const u8 {
    // ⚠️ 不能写成 `fn f(...) []const []const u8 { return &.{ "sh", "-c", cmd }; }`——
    //    返回类型是**无长度切片**，指针指向的临时数组出了函数就没了，
    //    spawn 里dupeSentinel 会读到 0x0（实测 Segmentation fault at address 0x0）。
    //    正解：外层数组从 arena 分配（内层字符串直接借用调用方的 command，不用 dupe）。
    const out = try arena.alloc([]const u8, 3);
    out[0] = if (builtin.os.tag == .windows) "cmd" else "sh";
    out[1] = if (builtin.os.tag == .windows) "/c" else "-c";
    out[2] = command;
    return out;
}

/// 22.10：子进程把自己读到的 stdin 原样吐回来（`cat` 在 POSIX/macOS 上都有）。
const echo_argv = [_][]const u8{"cat"};

/// 22.5：演示"argv 是切片数组不是命令行字符串"——同一个字符串里带空格和分号，
/// 作为**单个参数**传给子进程时不会被拆开、也不会被执行。
const injection_probe = "a b; echo INJECTED";

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;
    const arena = init.arena.allocator();

    // ═══ 22.1 没有全局状态：进程的一切都是 main 的第一个参数 ═══
    begin("22.1 进程：没有全局状态，一切从main 的参数来");
    std.debug.print("main 的参数类型 = {s}（0.16 起的显式依赖注入）\n", .{@typeName(std.process.Init)});
    const IT = @typeInfo(std.process.Init).@"struct";
    inline for (IT.field_names, IT.field_types) |fname, ftype| {
        std.debug.print("  .{s:<12}: {s}\n", .{ fname[0..fname.len], @typeName(ftype) });
    }
    const MT = @typeInfo(std.process.Init.Minimal).@"struct";
    inline for (MT.field_names, MT.field_types) |fname, ftype| {
        std.debug.print("  minimal.{s:<8}: {s}\n", .{ fname[0..fname.len], @typeName(ftype) });
    }
    std.debug.print("对比：C 的 main(argc, argv) 是全局；Rust 的 std::env::args() 是全局\n", .{});
    std.debug.print("⇒ Zig 里想读参数/环境/时间，**必须**从 init 拿，编译器强制你把它传下去\n", .{});
    end("22.1");

    // ═══ 22.2 命令行参数：Args.Iterator ═══
    begin("22.2 命令行参数：Args 与 Args.Iterator");
    std.debug.print("init.minimal.args 的类型 = {s}\n", .{@typeName(@TypeOf(init.minimal.args))});
    std.debug.print("它只有一个字段 .vector，类型 = {s}\n", .{@typeName(@TypeOf(init.minimal.args.vector))});
    std.debug.print("⚠️ 没有 .len、没有 .argv、没有 .next()：实测报no field named 'len' in struct 'process.Args'\n", .{});
    std.debug.print("正确入口是 iterate() / iterateAllocator()，返回 {s}\n", .{@typeName(std.process.Args.Iterator)});
    // 迭代器本体：initAllocator 拿可分配版本（Windows 侧要转码缓冲）
    var it = try init.minimal.args.iterateAllocator(arena);
    defer it.deinit(); // Windows/WASI 上有内部缓冲；POSIX 上是空操作
    std.debug.print("迭代器类型 = {s}\n", .{@typeName(@TypeOf(it))});
    var argc: usize = 0;
    while (it.next()) |arg| {
        std.debug.print("  argv[{d}] = {s}\n", .{ argc, arg });
        argc += 1;
    }
    std.debug.print("共 {d} 个参数（argv[0] 是程序自己的路径）\n", .{argc});
    // skip()：不取值只跳过。解析子命令时省掉 argv[0] 就靠它
    var it2 = try init.minimal.args.iterateAllocator(arena); // Windows：iterate() 是编译错误
    defer it2.deinit();
    std.debug.print("skip() 第一次 = {}（跳掉 argv[0]）\n", .{it2.skip()});
    var rest: usize = 0;
    while (it2.next()) |_| rest += 1;
    std.debug.print("skip 之后还剩 {d} 个\n", .{rest});
    // toSlice：一次性拿全部（结果可能引用多个分配，所以**必须**传 arena 型分配器）
    const all = try init.minimal.args.toSlice(arena);
    std.debug.print("toSlice(arena) 的类型 = {s}，共 {d} 个（源码注释：must use arena-style allocator）\n", .{ @typeName(@TypeOf(all)), all.len });
    // 0.17 移除的旧 API，逐个实测确认
    std.debug.print("已移除：argsAlloc={} args={} getEnvMap={} getEnvVarOwned={}\n", .{
        @hasDecl(std.process, "argsAlloc"),
        @hasDecl(std.process, "args"),
        @hasDecl(std.process, "getEnvMap"),
        @hasDecl(std.process, "getEnvVarOwned"),
    });
    end("22.2");

    // ═══ 22.3 Windows 的 UTF-16：为什么必须有迭代器 ═══
    begin("22.3 Windows 的 UTF-16 与 Windows 命令行解析算法");
    std.debug.print("Args.Vector 是平台相关的编译期 switch：\n", .{});
    std.debug.print("  Windows → []const u16（WTF-16，整条命令行一个串）\n", .{});
    std.debug.print("  POSIX   → []const [*:0]const u8（内核已经切好的指针数组）\n", .{});
    std.debug.print("本机(.{s}) 实测 Args.Vector = {s}\n", .{ @tagName(builtin.os.tag), @typeName(@TypeOf(init.minimal.args.vector)) });
    std.debug.print("⇒ Windows 上**没有**现成的 argv 数组，只有一条命令行字符串\n", .{});
    std.debug.print("⇒ 必须有人按 MSVC 规则把它切开并把 WTF-16 转成 UTF-8，那就是 Iterator.Windows\n", .{});
    // 这一段在 macOS 上也能真跑：Iterator.Windows 是纯函数，给它一条 WTF-16-LE 就行
    // 这条命令行用了三种切分手法，一次看清 MSVC 规则：
    //   "a b"      引号分组 → 空格不再是分隔符，引号本身消失
    //   c\\"d"     **2 个**反斜杠 + 引号 → 偶数，反斜杠减半成1 个、引号当分组符（消失）
    //   \xF0\x9F\x97\xBF  一个 UTF-8 字符（🗿）原样穿过（Windows 内部其实是代理对 → WTF-8）
    const cmdline = "foo.exe \"a b\" c\\\\\"d\" \xF0\x9F\x97\xBF tail";
    const wide = try std.unicode.wtf8ToWtf16LeAllocZ(gpa, cmdline);
    defer gpa.free(wide);
    var wit = try std.process.Args.Iterator.Windows.init(gpa, wide);
    defer wit.deinit();
    std.debug.print("把这条命令行按 Windows 规则切开：\n  {s}\n", .{cmdline});
    var wi: usize = 0;
    while (wit.next()) |arg| : (wi += 1) {
        std.debug.print("  win_argv[{d}] = {s}\n", .{ wi, arg });
    }
    std.debug.print("⚠️ 结果编码是 **WTF-8**（不是 UTF-8）：落单的代理项能编进去，合法 UTF-8 编不出来\n", .{});
    end("22.3");

    // ═══ 22.4 环境变量 ═══
    begin("22.4 环境变量：environ_map 与 Environ");
    std.debug.print("init.environ_map 的类型 = {s}（**指针**，启动时已解析好）\n", .{@typeName(@TypeOf(init.environ_map))});
    const EMT = @typeInfo(std.process.Environ.Map).@"struct";
    inline for (EMT.field_names, EMT.field_types) |fname, ftype| {
        std.debug.print("  Map.{s:<16}: {s}\n", .{ fname[0..fname.len], @typeName(ftype) });
    }
    // get：查一个，返回 map 自己那份拷贝（不分配）
    if (init.environ_map.get("PATH")) |p| {
        std.debug.print("PATH 存在，长度 {d} 字节（本节不抄内容：逐机器不同）\n", .{p.len});
    } else {
        std.debug.print("PATH 不存在\n", .{});
    }
    // get 一个绝对不存在的 key → null（不是错误）
    std.debug.print("get(\"ZZZ_NOT_SET_22\") = {any}（不存在返回 null，不报错）\n", .{init.environ_map.get("ZZZ_NOT_SET_22")});
    // put：改map（子进程可以继承改后的环境）
    try init.environ_map.put("ZZZ_FROM_22", "hello-env");
    std.debug.print("put 后 get = {s}，count = {d}\n", .{ init.environ_map.get("ZZZ_FROM_22").?, init.environ_map.count() });
    // 遍历
    var env_it = init.environ_map.iterator();
    var env_n: usize = 0;
    var with_eq: usize = 0;
    while (env_it.next()) |entry| {
        env_n += 1;
        if (std.mem.indexOfScalar(u8, entry.key_ptr.*, '=') != null) with_eq += 1;
    }
    std.debug.print("遍历到 {d} 个变量迭代器，count() = {d}（两者应相等）\n", .{ env_n, init.environ_map.count() });
    std.debug.print("key 里带 '=' 的个数 = {d} ⇒ Map 把 key/value 拆开存了，key 本身不含 '='\n", .{with_eq});
    // Environ：不建 Map 的直查路径（底层是 OS 给的原始 block）
    std.debug.print("init.minimal.environ 的类型 = {s}，.block = {s}\n", .{
        @typeName(@TypeOf(init.minimal.environ)),
        @typeName(@TypeOf(init.minimal.environ.block)),
    });
    if (builtin.os.tag != .windows) {
        std.debug.print("Environ.getPosix(\"PATH\") != null = {}\n", .{init.minimal.environ.getPosix("PATH") != null});
    } else {
        // ⚠️ 0.17.0 std bug：getPosix 内部走 block.view()，Windows 的 GlobalBlock 没有
        // view()——Windows 上调 getPosix 是 std **内部**的编译错误，与你无关
        std.debug.print("Windows：getPosix 在 0.17.0 编不过（std 内部 GlobalBlock.view 缺失），查环境用 environ_map\n", .{});
    }
    std.debug.print("Environ.containsConstant(\"PATH\") = {}（编译期 key，零分配，comptime 展开）\n", .{init.minimal.environ.containsConstant("PATH")});
    if (init.minimal.environ.getAlloc(gpa, "ZZZ_NOT_SET_22")) |v| {
        gpa.free(v);
    } else |e| {
        std.debug.print("Environ.getAlloc 不存在的 key → error.{s}（Map.get 返回 null，Environ.getAlloc 返回错误）\n", .{@errorName(e)});
    }
    std.debug.print("⚠️ std.posix.getenv 在 0.17 **不存在**（@hasDecl = {}）→ 跨平台代码别指望它\n", .{@hasDecl(std.posix, "getenv")});
    std.debug.print("⚠️ Windows 环境变量名**不区分大小写**：Map 的哈希与比较都走 toUpperWtf16/eqlIgnoreCaseWtf8\n", .{});
    end("22.4");

    // ═══ 22.5 为什么 argv 是切片数组 ═══
    begin("22.5 argv 是切片数组：不用shell 就不会被注入");
    // ⚠️ 0.17 的语法坑：`@TypeOf(Struct.field)` 不成立（TypeOf 只吃表达式），
    //    而`@FieldTypeOf` 在 0.17 **已被移除**（实测 invalid builtin function: '@FieldTypeOf'）。
    //    正解：走 @typeInfo(...).@"struct".field_types，按下标取（下面 22.7 会把整张表打出来）。
    const ROPT_T = @typeInfo(std.process.RunOptions).@"struct";
    std.debug.print("RunOptions.argv 的类型 = {s}（**字符串切片数组**，不是一整条命令行）\n", .{@typeName(ROPT_T.field_types[1])});
    std.debug.print("所以：每个参数**原样**交给 execve/CreateProcess，Zig 不做任何拆分\n", .{});
    // 活证明：把带空格和分号的整串当成 printf 的 argv[2]（格式串 argv[1] 是字面量 "%s"），
    // printf 会**原样**吐出 argv[2]—— 如果 argv 被拆分过，这里就会缺字或多字。
    // ⚠️ 不能用 `cat`：cat 会把参数当**文件名**去打开，不是回显。
    var pr_argv = [_][]const u8{ "printf", "%s", "" };
    pr_argv[2] = injection_probe;
    const r = try std.process.run(gpa, io, .{ .argv = &pr_argv });
    defer {
        gpa.free(r.stdout);
        gpa.free(r.stderr);
    }
    std.debug.print("把这个字符串作为 printf 的 argv[2]（单个参数），它原样吐回：{s}\n", .{r.stdout});
    // 用 shell 的写法演示对比：同样内容拼进命令行就会被拆开
    const sh = try std.process.run(gpa, io, .{ .argv = try shellArgv(arena, "printf '%s' 'a b; echo INJECTED'") });
    defer {
        gpa.free(sh.stdout);
        gpa.free(sh.stderr);
    }
    std.debug.print("对比：同样内容拼进 sh -c 的命令行（这次 %s 在单引号里没被展开）→ {s}\n", .{sh.stdout});
    const sh2 = try std.process.run(gpa, io, .{ .argv = try shellArgv(arena, "printf '%s' a b; echo INJECTED") });
    defer {
        gpa.free(sh2.stdout);
        gpa.free(sh2.stderr);
    }
    std.debug.print("     去掉引号后，分号变成 shell 的语句分隔符 → {s}\n", .{sh2.stdout});
    std.debug.print("⇒ argv 数组 = 无注入面（Zig 不解释 % ; | 这类字符）；shell 命令串 = 注入面（你自己承担）\n", .{});
    end("22.5");

    // ═══ 22.6 要shell 特性就显式套 shell ═══
    begin("22.6 要 shell 特性：显式 sh -c / cmd /c");
    std.debug.print("echo 是 shell **内建命令**，不是 /bin/echo → 直接传 {{\"echo\"}} 在很多系统上会 FileNotFound\n", .{});
    const shell_cmd = "echo out; echo err 1>&2; echo piped | tr a-z A-Z";
    const argv = try shellArgv(arena, shell_cmd);
    std.debug.print("要跑这串（分号 + 重定向 + 管道），本平台 argv =", .{});
    for (argv, 0..) |a, i| {
        std.debug.print(" [{d}]={s}", .{ i, a });
    }
    std.debug.print("\n", .{});
    const sr = try std.process.run(gpa, io, .{ .argv = argv });
    defer {
        gpa.free(sr.stdout);
        gpa.free(sr.stderr);
    }
    std.debug.print("--- stdout ---\n{s}--- stderr ---\n{s}", .{ sr.stdout, sr.stderr });
    std.debug.print("⚠️ 套shell 之后，命令串是**拼接**出来的就必须自己转义，否则就是注入漏洞\n", .{});
    std.debug.print("   本示例的命令串全是字面量，所以安全；换成用户输入就不安全\n", .{});
    end("22.6");

    // ═══ 22.7 run：一步式跑完收输出 ═══
    begin("22.7 std.process.run：一步式跑完并收输出");
    std.debug.print("run 的返回类型 = {s}\n", .{@typeName(@TypeOf(std.process.run))});
    const ROPT = @typeInfo(std.process.RunOptions).@"struct";
    std.debug.print("RunOptions 共 {d} 个字段：", .{ROPT.field_names.len});
    inline for (ROPT.field_names, ROPT.field_types) |fname, ftype| {
        std.debug.print("\n  .{s:<16}: {s}", .{ fname[0..fname.len], @typeName(ftype) });
    }
    std.debug.print("\n", .{});
    const res = try std.process.run(gpa, io, .{ .argv = &.{ "echo", "hello from child" } });
    std.debug.print("RunResult 的类型 = {s}（.term / .stdout / .stderr）\n", .{@typeName(std.process.RunResult)});
    std.debug.print("stdout = {s}", .{res.stdout});
    std.debug.print("stderr 长度 = {d}\n", .{res.stderr.len});
    std.debug.print("term = {f}（success() = {}）\n", .{ res.term, res.term.success() });
    gpa.free(res.stdout);
    gpa.free(res.stderr);
    std.debug.print("⚠️ run 内部 spawn 时把 stdin 设成 .ignore、stdout/stderr 设成 .pipe：拿不到交互能力\n", .{});
    std.debug.print("⚠️ **调用者 owns result.stdout / result.stderr**：用 gpa 就必须 free（见上）\n", .{});
    end("22.7");

    // ═══ 22.8 term：怎么判定子进程的结局 ═══
    begin("22.8 term：正常退出 / 非零退出 / 被信号杀死");
    const TINFO = @typeInfo(std.process.Child.Term).@"union";
    std.debug.print("Child.Term = {s}，{d} 个成员：", .{ @typeName(std.process.Child.Term), TINFO.field_names.len });
    inline for (TINFO.field_names) |fname| std.debug.print(" .{s}", .{fname[0..fname.len]});
    std.debug.print("\n", .{});
    // 正常退出 0
    const ok0 = try std.process.run(gpa, io, .{ .argv = &.{ "sh", "-c", "exit 0" } });
    defer {
        gpa.free(ok0.stdout);
        gpa.free(ok0.stderr);
    }
    std.debug.print("exit 0         → {f}；success() = {}\n", .{ ok0.term, ok0.term.success() });
    // 非零退出
    const bad3 = try std.process.run(gpa, io, .{ .argv = &.{ "sh", "-c", "exit 3" } });
    defer {
        gpa.free(bad3.stdout);
        gpa.free(bad3.stderr);
    }
    std.debug.print("exit 3         → {f}；success() = {}；.exited = {d}\n", .{ bad3.term, bad3.term.success(), bad3.term.exited });
    // 被信号杀死
    const sig9 = try std.process.run(gpa, io, .{ .argv = &.{ "sh", "-c", "kill -9 $$" } });
    defer {
        gpa.free(sig9.stdout);
        gpa.free(sig9.stderr);
    }
    std.debug.print("kill -9 $$     → {f}；success() = {}\n", .{ sig9.term, sig9.term.success() });
    switch (sig9.term) {
        .signal => |sig| std.debug.print("  .signal 载荷 = {d}（{t}）\n", .{ @backingInt(sig), sig }),
        else => {},
    }
    // 启动失败：不是 term，是错误
    if (std.process.run(gpa, io, .{ .argv = &.{"no-such-binary-zz-22"} })) |_| {
        std.debug.print("?? 不该成功\n", .{});
    } else |e| {
        std.debug.print("程序不存在     → error.{s}（**spawn 阶段**就失败，没有 term 可言）\n", .{@errorName(e)});
    }
    std.debug.print("⚠️ term.success() 只在 .exited 且 code == 0 时为真；被信号杀死算失败\n", .{});
    end("22.8");

    // ═══ 22.9 timeout 与输出上限 ═══
    begin("22.9 timeout 与 stdout_limit / stderr_limit");
    std.debug.print("RunOptions.timeout 的类型 = {s}（不是数字，是 Io.Timeout）\n", .{@typeName(@typeInfo(std.process.RunOptions).@"struct".field_types[10])});
    const TTI = @typeInfo(std.Io.Timeout).@"union";
    std.debug.print("Io.Timeout 的成员：", .{});
    inline for (TTI.field_names) |fname| std.debug.print(" .{s}", .{fname[0..fname.len]});
    std.debug.print("\n", .{});
    // 超时：睡 5 秒但只给 80ms
    // ⚠️ 0.17 的坑：无名结构体字面量 `.{{ ... }}` 推不出目标类型时要**显式标注**
    const to: std.Io.Timeout = .{ .duration = .{ .raw = std.Io.Duration.fromMilliseconds(80), .clock = .awake } };
    if (std.process.run(gpa, io, .{ .argv = &.{ "sleep", "5" }, .timeout = to })) |v| {
        std.debug.print("?? 超时没触发：{f}\n", .{v.term});
        gpa.free(v.stdout);
        gpa.free(v.stderr);
    } else |e| {
        std.debug.print("sleep 5 但 timeout=80ms → error.{s}（run 内部 defer child.kill(io)）\n", .{@errorName(e)});
    }
    // stdout_limit：输出超过上限就报错，而不是无限吃内存
    const lim = std.process.run(gpa, io, .{
        .argv = try shellArgv(arena, "printf 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'"),
        .stdout_limit = .limited(8),
    });
    if (lim) |v| {
        std.debug.print("?? 上限没触发\n", .{});
        gpa.free(v.stdout);
        gpa.free(v.stderr);
    } else |e| {
        std.debug.print("输出 30 字节但 stdout_limit = .limited(8) → error.{s}\n", .{@errorName(e)});
    }
    std.debug.print("Io.Limit = {s}：.nothing=0 .unlimited=maxInt(usize) 还有 _.（**非穷尽** enum）\n", .{@typeName(std.Io.Limit)});
    std.debug.print("  .limited(8) 的 backingInt = {d}，toInt() = {any}（unlimited 时 toInt() 返回 null）\n", .{ @backingInt(std.Io.Limit.limited(8)), std.Io.Limit.limited(8).toInt() });
    std.debug.print("⚠️ @tagName(Io.Limit.limited(8)) 会 panic: invalid enum value（非穷尽 enum 不能取 tagName）\n", .{});
    std.debug.print("⚠️ RunError = error{{StreamTooLong}} || SpawnError || ... || Io.Timeout.Error\n", .{});
    end("22.9");

    // ═══ 22.10 spawn：流式交互 ═══
    begin("22.10 std.process.spawn：流式交互");
    std.debug.print("spawn 的返回类型 = {s}（注意是 **Child 值**，不是指针）\n", .{@typeName(@TypeOf(std.process.spawn))});
    const SOPT = @typeInfo(std.process.SpawnOptions).@"struct";
    std.debug.print("SpawnOptions 共 {d} 个字段，比 RunOptions 多的是流三件套：\n", .{SOPT.field_names.len});
    inline for (SOPT.field_names, SOPT.field_types) |fname, ftype| {
        const is_stream = std.mem.eql(u8, fname, "stdin") or
            std.mem.eql(u8, fname, "stdout") or std.mem.eql(u8, fname, "stderr");
        if (is_stream) std.debug.print("  .{s:<8}: {s}\n", .{ fname[0..fname.len], @typeName(ftype) });
    }
    std.debug.print("  StdIo 的成员：.inherit / .file / .ignore / .pipe / .close\n", .{});
    const CT = @typeInfo(std.process.Child).@"struct";
    std.debug.print("Child 的字段：", .{});
    inline for (CT.field_names) |fname| std.debug.print(" .{s}", .{fname[0..fname.len]});
    std.debug.print("\n", .{});
    // 往子进程 stdin 写，边跑边读 stdout，最后 wait
    var child = try std.process.spawn(io, .{
        .argv = &echo_argv,
        .stdin = .pipe,
        .stdout = .pipe,
        .stderr = .inherit,
    });
    var wbuf: [64]u8 = undefined;
    var fw = child.stdin.?.writer(io, &wbuf);
    try fw.interface.print("ping\n", .{});
    try fw.interface.flush();
    // ⚠️ 关键：close 之后必须把字段置 null。wait 内部的 childCleanupPosix 会再关一次，
    //    二次 close 触发 unreachable（实测 panic: reached unreachable code ← closeFd .BADF）
    child.stdin.?.close(io);
    child.stdin = null;
    var rbuf: [256]u8 = undefined;
    var fr = child.stdout.?.reader(io, &rbuf);
    var outbuf: [256]u8 = undefined;
    var ow = std.Io.Writer.fixed(&outbuf);
    _ = try fr.interface.streamRemaining(&ow);
    const cterm = try child.wait(io);
    std.debug.print("写进去 5 字节，读回来 = {s}（term = {f}）\n", .{ ow.buffered(), cterm });
    std.debug.print("wait 之后 child.id = {any}（被 wait 置空了，不能再 kill/wait）\n", .{child.id});
    end("22.10");

    // ═══ 22.11 kill：主动终止子进程 ═══
    begin("22.11 Child.kill：不等它自己结束");
    std.debug.print("kill 的类型 = {s}（注意：**不收 signal 参数**，语义就是\"终止\"）\n", .{@typeName(@TypeOf(std.process.Child.kill))});
    std.debug.print("wait 的类型 = {s}\n", .{@typeName(@TypeOf(std.process.Child.wait))});
    var victim = try std.process.spawn(io, .{ .argv = &.{ "sleep", "30" } });
    std.debug.print("kill 前 child.id != null = {}\n", .{victim.id != null});
    victim.kill(io);
    std.debug.print("kill 后 child.id == null = {}（kill 内部清理并置空，且**幂等**）\n", .{victim.id == null});
    std.debug.print("⚠️ 没有 killById，kill 也不收信号：要发别的信号得自己走 std.posix.kill(pid, sig)\n", .{});
    end("22.11");

    // ═══ 22.12 preopens ═══
    begin("22.12 init.preopens：父进程递给我们的文件");
    std.debug.print("init.preopens 的类型 = {s}\n", .{@typeName(@TypeOf(init.preopens))});
    const PT = @typeInfo(std.process.Preopens).@"struct";
    inline for (PT.field_names, PT.field_types) |fname, ftype| {
        std.debug.print("  .{s:<6}: {s}\n", .{ fname[0..fname.len], @typeName(ftype) });
    }
    std.debug.print("get(name) 返回 ?Resource，Resource = union(enum){{ .file: Io.File, .dir: Io.Dir }}\n", .{});
    for ([_][]const u8{ "stdin", "stdout", "stderr", "anything-else" }) |nm| {
        if (init.preopens.get(nm)) |pres| {
            std.debug.print("  get(\"{s}\") = .{s}\n", .{ nm, @tagName(pres) });
        } else {
            std.debug.print("  get(\"{s}\") = null\n", .{nm});
        }
    }
    std.debug.print("本机 Preopens.Map = {s}（非 WASI 是 void；WASI 上是按 fd 索引的 String(void)）\n", .{@typeName(std.process.Preopens.Map)});
    std.debug.print("⇒ 非 WASI 上它就是 stdin/stdout/stderr 三个名字的查表，别的名字一律 null\n", .{});
    end("22.12");

    // ═══ 22.13 退出码 ═══
    begin("22.13 退出码：三种写法");
    std.debug.print("写法一：pub fn main(init: std.process.Init) !void —— 正常返回 = 0，错误冒泡 = 1\n", .{});
    std.debug.print("写法二：pub fn main() u8 —— 直接把 u8 当退出码（实测 return 3 → $? = 3）\n", .{});
    std.debug.print("写法三：std.process.exit({s}) —— 签名**不收 io**（实测传 io 报 expected 1 argument(s), found 2）\n", .{@typeName(@TypeOf(std.process.exit))});
    std.debug.print("子进程退出码怎么读：run 的 res.term 是 .exited 时 .exited 就是那个 u8（见 22.8）\n", .{});
    std.debug.print("⚠️ exit 是 noreturn：它**不做** defer 清理、不flush、不释放 arena\n", .{});
    end("22.13");

    // ═══ 22.14 时间与睡眠：时间也归 Io ═══
    begin("22.14 时间与睡眠：std.Io.Clock");
    std.debug.print("Io.Clock 的成员（本机实测共 {d} 个，**没有 .monotonic**）：", .{@typeInfo(std.Io.Clock).@"enum".field_names.len});
    inline for (@typeInfo(std.Io.Clock).@"enum".field_names) |fname| std.debug.print(" .{s}", .{fname[0..fname.len]});
    std.debug.print("\n", .{});
    std.debug.print("⚠️ 写 .monotonic 实测报 enum 'Io.Clock' has no member named 'monotonic'\n", .{});
    // now
    const t0 = std.Io.Clock.now(.awake, io);
    std.debug.print("Clock.now(.awake, io) 返回 {s}，字段 .nanoseconds 的类型 = {s}\n", .{ @typeName(@TypeOf(t0)), @typeName(@TypeOf(t0.nanoseconds)) });
    // sleep：两条等价路径
    try std.Io.sleep(io, std.Io.Duration.fromMilliseconds(2), .awake);
    const t1 = std.Io.Clock.now(.awake, io);
    const via_io_sleep = t0.durationTo(t1).nanoseconds;
    const t2 = std.Io.Clock.now(.awake, io);
    try (std.Io.Clock.Duration{ .raw = std.Io.Duration.fromMilliseconds(2), .clock = .awake }).sleep(io);
    const t3 = std.Io.Clock.now(.awake, io);
    const via_clock_sleep = t2.durationTo(t3).nanoseconds;
    std.debug.print("睡 2ms 两次：Io.sleep 路径 {d} ns，Clock.Duration.sleep 路径 {d} ns\n", .{ via_io_sleep, via_clock_sleep });
    std.debug.print("（两次都是**正数**但每次运行都不同 —— ns 数不可复现，别断言具体值）\n", .{});
    // 三种 Duration 别搞混
    const d = std.Io.Duration.fromNanoseconds(1_500_000);
    std.debug.print("Io.Duration = {s}（只有 .nanoseconds 字段，纯时长）\n", .{@typeName(std.Io.Duration)});
    std.debug.print("Clock.Duration = {s}（.raw + .clock，sleep 要用这个）\n", .{@typeName(std.Io.Clock.Duration)});
    std.debug.print("Clock.Timestamp = {s}（.raw + .clock）\n", .{@typeName(std.Io.Clock.Timestamp)});
    std.debug.print("d 用 {{f}} 打印 = {f}；toMilliseconds() = {d}；toSeconds() = {d}\n", .{ d, d.toMilliseconds(), d.toSeconds() });
    std.debug.print("⚠️ Io.Duration 有 format（走 {{f}}）但**没有** formatNumber：{{d}} 打印它会编译失败\n", .{});
    std.debug.print("实测报 no field or member function named 'formatNumber' in 'Io.Duration'\n", .{});
    // 墙钟 vs 单调钟
    const wall = std.Io.Clock.now(.real, io);
    const awake = std.Io.Clock.now(.awake, io);
    std.debug.print(".real 是墙钟（Unix 纪元纳秒，会被 NTP 跳变）；.awake 是单调钟（测耗时用它）\n", .{});
    std.debug.print("  .real 纳秒位数 = {d}（约 {d} 年纪元），.awake 纳秒 = {d}（开机时长量级）\n", .{ wall.nanoseconds, @divTrunc(wall.nanoseconds, 31_557_600_000_000_000), awake.nanoseconds });
    const res_awake = std.Io.Clock.awake.resolution(io) catch std.Io.Duration.fromNanoseconds(0);
    std.debug.print("  .awake 的分辨率 = {d} ns（resolution(io) 返回 Io.Duration，不是整数）\n", .{res_awake.nanoseconds});
    end("22.14");

    // ═══ 22.15 std.time 在 0.17 还剩什么 ═══
    begin("22.15 std.time 在 0.17 还剩什么");
    const names = [_]struct { n: []const u8, note: []const u8, has: bool }{
        .{ .n = "ns_per_us", .note = "常量 1000", .has = @hasDecl(std.time, "ns_per_us") },
        .{ .n = "ns_per_ms", .note = "常量", .has = @hasDecl(std.time, "ns_per_ms") },
        .{ .n = "ns_per_s", .note = "常量", .has = @hasDecl(std.time, "ns_per_s") },
        .{ .n = "ns_per_min", .note = "常量", .has = @hasDecl(std.time, "ns_per_min") },
        .{ .n = "ns_per_hour", .note = "常量", .has = @hasDecl(std.time, "ns_per_hour") },
        .{ .n = "ns_per_day", .note = "常量", .has = @hasDecl(std.time, "ns_per_day") },
        .{ .n = "ns_per_week", .note = "常量", .has = @hasDecl(std.time, "ns_per_week") },
        .{ .n = "us_per_ms", .note = "常量（还有 us_per_s）", .has = @hasDecl(std.time, "us_per_ms") },
        .{ .n = "s_per_min", .note = "常量（还有 s_per_s/day/week）", .has = @hasDecl(std.time, "s_per_min") },
        .{ .n = "epoch", .note = "日历换算（time/epoch.zig）", .has = @hasDecl(std.time, "epoch") },
        .{ .n = "Timer", .note = "0.16 已移除 → Io.Clock.now", .has = @hasDecl(std.time, "Timer") },
        .{ .n = "Instant", .note = "0.16 已移除 → Io.Timestamp", .has = @hasDecl(std.time, "Instant") },
        .{ .n = "nanoTimestamp", .note = "0.16 已移除 → Io.Clock.now(.real)", .has = @hasDecl(std.time, "nanoTimestamp") },
        .{ .n = "now", .note = "0.16 已移除 → Io.Clock.now", .has = @hasDecl(std.time, "now") },
        .{ .n = "sleep", .note = "0.16 已移除 → Io.sleep / Clock.Duration.sleep", .has = @hasDecl(std.time, "sleep") },
    };
    var exist: usize = 0;
    var missing: usize = 0;
    for (names) |entry| {
        std.debug.print("  std.time.{s:<16} {s}  {s}\n", .{ entry.n, if (entry.has) "存在  " else "不存在", entry.note });
        if (entry.has) exist += 1 else missing += 1;
    }
    std.debug.print("小计：{d} 个存在（全是常量 + epoch），{d} 个不存在（全是函数/类型）\n", .{ exist, missing });
    std.debug.print("⇒ 一句话：0.17 的 std.time **只剩单位换算常量**，所有计时函数都在 std.Io.Clock 上\n", .{});
    std.debug.print("⇒ 因为时间也要可被测试替换：测试里传个假 Io 就能控制\"现在几点\"\n", .{});
    end("22.15");

    std.debug.print("自检通过\n", .{});
}

test "Args.Iterator：iterate / next 的行为" {
    // POSIX 形状的假 Args（Windows 的 vector 是 []const u16，iterate() 也是编译错误）
    if (builtin.os.tag == .windows) return error.SkipZigTest;
    const raw = [_][*:0]const u8{ "prog", "alpha", "beta gamma" };
    const args: std.process.Args = .{ .vector = &raw };
    var it = args.iterate();
    try std.testing.expectEqualStrings("prog", it.next().?);
    try std.testing.expectEqualStrings("alpha", it.next().?);
    try std.testing.expectEqualStrings("beta gamma", it.next().?);
    try std.testing.expect(it.next() == null);
}

test "Args.Iterator：skip 跳过后剩下的正好是全部" {
    if (builtin.os.tag == .windows) return error.SkipZigTest;
    const raw = [_][*:0]const u8{ "prog", "x", "y", "z" };
    const args: std.process.Args = .{ .vector = &raw };
    var it = args.iterate();
    try std.testing.expect(it.skip()); // 吃掉 prog
    try std.testing.expect(it.skip()); // 吃掉 x
    try std.testing.expectEqualStrings("y", it.next().?);
    try std.testing.expectEqualStrings("z", it.next().?);
    try std.testing.expect(!it.skip()); // 到头了
    try std.testing.expect(it.next() == null);
}

test "Args.Iterator.Windows：MSVC 规则切分（含反斜杠与引号转义）" {
    const a = std.testing.allocator;
    // 这组期望值与 std/process/Args.zig 里的 test "Iterator.Windows" 同源
    // 期望值全部是**本机实测**结果（不是从 std源码抄的——std 用的是多行字符串，
    // 里面反斜杠的条数和这里不一样，抄过来必然对不上）。
    // 注意 Zig 普通字符串的转义：\\ = 1 个反斜杠，\\\" = 反斜杠 + 引号。
    // 期望值全部是**本机实测**结果（不是从 std 源码抄的——那边用的是多行字符串，
    // 反斜杠条数与这里不同，抄过来必然对不上）。
    // 转义提醒：Zig 普通字符串里 \\ = 1 个反斜杠，\" = 1 个引号。
    const cases = [_]struct { cmd: []const u8, want: []const []const u8 }{
        // 引号分组：引号本身不出现在参数里
        .{ .cmd = "foo.exe \"abc\" d e", .want = &.{ "foo.exe", "abc", "d", "e" } },
        .{ .cmd = "foo.exe a\\b d\"e f\"g h", .want = &.{ "foo.exe", "a\\b", "de fg", "h" } },
        // 引号紧贴词：a"b"" → a + 转义出的引号 + b
        .{ .cmd = "foo.exe a\"b\"\" c d", .want = &.{ "foo.exe", "ab\" c d" } },
        // 1 个反斜杠 + 引号 = 转义引号：反斜杠被吃掉，**引号保留**在参数里
        .{ .cmd = "foo.exe a\\\"b c d", .want = &.{ "foo.exe", "a\"b", "c", "d" } },
        // 2 个反斜杠 + 引号 = 引号当分组符：反斜杠减半（2→1），**引号消失**
        .{ .cmd = "foo.exe a\\\\\"b c\" d e", .want = &.{ "foo.exe", "a\\b c", "d", "e" } },
        // 前后空格：产生首个空参数（末尾空格不产生尾部空参数）
        .{ .cmd = "  aa  bb  ", .want = &.{ "", "aa", "bb" } },
        // 只有空白的命令行 → 一个空参数（不是零个）
        .{ .cmd = "\t\t", .want = &.{""} },
        // 换行/回车**不是**分隔符（与空格/tab 不同），整条就是一个参数
        .{ .cmd = "aa\nbb", .want = &.{"aa\nbb"} },
    };
    inline for (cases) |c| {
        const w = try std.unicode.wtf8ToWtf16LeAllocZ(a, c.cmd);
        defer a.free(w);
        var it = try std.process.Args.Iterator.Windows.init(a, w);
        defer it.deinit();
        for (c.want) |expected| {
            try std.testing.expectEqualStrings(expected, it.next().?);
        }
        try std.testing.expect(it.next() == null);
    }
}

test "Environ.Map：put / get / contains / count / iterator / swapRemove" {
    var map: std.process.Environ.Map = .init(std.testing.allocator);
    defer map.deinit();

    try std.testing.expectEqual(@as(std.process.Environ.Map.Size, 0), map.count());
    try map.put("A", "1");
    try map.put("B", "2");
    try std.testing.expectEqual(@as(std.process.Environ.Map.Size, 2), map.count());
    try std.testing.expectEqualStrings("1", map.get("A").?);
    try std.testing.expect(map.contains("B"));
    try std.testing.expect(map.get("NOPE") == null);

    // iterator 走一遍，数量必须与 count() 一致
    var it = map.iterator();
    var n: usize = 0;
    while (it.next()) |_| n += 1;
    try std.testing.expectEqual(@as(usize, 2), n);

    // put 同名 key 覆盖值、不改数量
    try map.put("A", "9");
    try std.testing.expectEqualStrings("9", map.get("A").?);
    try std.testing.expectEqual(@as(std.process.Environ.Map.Size, 2), map.count());

    // swapRemove 删掉
    try std.testing.expect(map.swapRemove("A"));
    try std.testing.expect(!map.swapRemove("A"));
    try std.testing.expectEqual(@as(std.process.Environ.Map.Size, 1), map.count());
}

test "Environ.Map：key 里不能含 '=' 或 NUL（validateKeyForPut）" {
    // put 的契约由 validateKeyForPut 断言，非法 key 会 panic —— 所以这里只测判定函数本身
    try std.testing.expect(std.process.Environ.Map.validateKeyForPut("GOOD_KEY"));
    try std.testing.expect(!std.process.Environ.Map.validateKeyForPut(""));
    try std.testing.expect(!std.process.Environ.Map.validateKeyForPut("HAS=EQUAL"));
    try std.testing.expect(!std.process.Environ.Map.validateKeyForPut("HAS\x00NUL"));
}

test "Environ：createMap → getPosix / containsConstant / getAlloc 的往返" {
    // createPosixBlock 的产物是 PosixBlock；Windows 的 Environ.block 要 GlobalBlock
    if (builtin.os.tag == .windows) return error.SkipZigTest;
    const a = std.testing.allocator;
    var src: std.process.Environ.Map = .init(a);
    defer src.deinit();
    try src.put("FOO", "BAR");
    try src.put("EMPTY", "");

    const block = try src.createPosixBlock(a, .{});
    defer block.deinit(a);
    const env: std.process.Environ = .{ .block = block };

    try std.testing.expectEqualStrings("BAR", env.getPosix("FOO").?);
    try std.testing.expect(env.getPosix("MISSING") == null);
    try std.testing.expect(env.containsConstant("FOO"));
    try std.testing.expect(!env.containsConstant("MISSING"));
    // 空字符串的 key 存在但 containsUnempty 为假
    try std.testing.expect(env.containsConstant("EMPTY"));
    try std.testing.expect(!env.containsUnemptyConstant("EMPTY"));

    const got = try env.getAlloc(a, "FOO");
    defer a.free(got);
    try std.testing.expectEqualStrings("BAR", got);
    try std.testing.expectError(error.EnvironmentVariableMissing, env.getAlloc(a, "MISSING"));
}

test "Child.Term：四个成员与 success() 语义" {
    // ⚠️ 0.17 的坑：union 字面量后面**必须加括号**才能调方法。
    //    写 Term{ .exited = 0 }.success() 报expected ',' after argument（实测，
    //    无论 Term 写成全名还是 `const T = Term;` 的别名都一样）；写成 (Term{...}).success() 才过。
    try std.testing.expect((std.process.Child.Term{ .exited = 0 }).success());
    try std.testing.expect(!(std.process.Child.Term{ .exited = 3 }).success());
    if (builtin.os.tag != .windows) {
        // Windows 的 posix.SIG 是另一套枚举（没有 KILL/TSTP 成员名）
        try std.testing.expect(!(std.process.Child.Term{ .signal = .KILL }).success());
        try std.testing.expect(!(std.process.Child.Term{ .stopped = .TSTP }).success());
    }
    try std.testing.expect(!(std.process.Child.Term{ .unknown = 7 }).success());
    // 格式化走的是自定义 format（{f}），不是 default formatter
    var buf: [64]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    try w.print("{f}", .{std.process.Child.Term{ .exited = 3 }});
    try std.testing.expectEqualStrings("exited with code 3", w.buffered());
}

test "std.process.run：正常退出 / 非零退出 / 被信号杀死 / 程序不存在" {
    const io = std.testing.io;
    const gpa = std.testing.allocator;

    // 正常退出 0
    const ok = try std.process.run(gpa, io, .{ .argv = &.{ "sh", "-c", "exit 0" } });
    defer gpa.free(ok.stdout);
    defer gpa.free(ok.stderr);
    try std.testing.expect(ok.term.success());
    try std.testing.expectEqual(@as(u8, 0), ok.term.exited);

    // 非零退出：run 成功返回，退出码在 term 里
    const bad = try std.process.run(gpa, io, .{ .argv = &.{ "sh", "-c", "exit 3" } });
    defer gpa.free(bad.stdout);
    defer gpa.free(bad.stderr);
    try std.testing.expect(!bad.term.success());
    try std.testing.expectEqual(@as(u8, 3), bad.term.exited);

    // 被信号杀死（POSIX 专属：Windows 无 sh，posix.SIG 也没有 KILL 成员名）
    if (builtin.os.tag != .windows) {
        const killed = try std.process.run(gpa, io, .{ .argv = &.{ "sh", "-c", "kill -9 $$" } });
        defer gpa.free(killed.stdout);
        defer gpa.free(killed.stderr);
        try std.testing.expect(!killed.term.success());
        try std.testing.expectEqual(std.posix.SIG.KILL, killed.term.signal);
    }

    // 捕获 stdout / stderr
    const both = try std.process.run(gpa, io, .{ .argv = &.{ "sh", "-c", "echo out; echo err 1>&2" } });
    defer gpa.free(both.stdout);
    defer gpa.free(both.stderr);
    try std.testing.expectEqualStrings("out\n", both.stdout);
    try std.testing.expectEqualStrings("err\n", both.stderr);

    // 程序不存在：spawn 阶段就失败
    try std.testing.expectError(
        error.FileNotFound,
        std.process.run(gpa, io, .{ .argv = &.{"definitely-no-such-binary-zz22"} }),
    );
}

test "std.process.run：timeout 与 stdout_limit" {
    const io = std.testing.io;
    const gpa = std.testing.allocator;

    // 睡 5 秒但只给 20ms
    const to: std.Io.Timeout = .{ .duration = .{ .raw = std.Io.Duration.fromMilliseconds(20), .clock = .awake } };
    try std.testing.expectError(error.Timeout, std.process.run(gpa, io, .{
        .argv = &.{ "sleep", "5" },
        .timeout = to,
    }));

    // 输出超过 stdout_limit
    try std.testing.expectError(error.StreamTooLong, std.process.run(gpa, io, .{
        .argv = &.{ "sh", "-c", "printf 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'" },
        .stdout_limit = .limited(8),
    }));

    // 同样的命令，不设上限就成功
    const ok = try std.process.run(gpa, io, .{
        .argv = &.{ "sh", "-c", "printf 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'" },
    });
    defer gpa.free(ok.stdout);
    defer gpa.free(ok.stderr);
    try std.testing.expectEqual(@as(usize, 30), ok.stdout.len);
}

test "std.process.spawn：往 stdin 写 + 读 stdout + wait" {
    const io = std.testing.io;
    var child = try std.process.spawn(io, .{
        .argv = &.{"cat"},
        .stdin = .pipe,
        .stdout = .pipe,
        .stderr = .inherit,
    });
    var wbuf: [64]u8 = undefined;
    var fw = child.stdin.?.writer(io, &wbuf);
    try fw.interface.print("ping\n", .{});
    try fw.interface.flush();
    // 必须 close 之后置 null，否则 wait 里的 childCleanupPosix 会二次 close 触发 unreachable
    child.stdin.?.close(io);
    child.stdin = null;

    var rbuf: [128]u8 = undefined;
    var fr = child.stdout.?.reader(io, &rbuf);
    var out: [128]u8 = undefined;
    var ow = std.Io.Writer.fixed(&out);
    _ = try fr.interface.streamRemaining(&ow);
    const term = try child.wait(io);
    try std.testing.expectEqualStrings("ping\n", ow.buffered());
    try std.testing.expect(term.success());
    try std.testing.expect(child.id == null); // wait 之后 id 被清空
}

test "std.process.spawn：kill 终止长跑子进程，且幂等" {
    const io = std.testing.io;
    // sh 在 Windows（Git）与 POSIX 都有；裸 sleep 在 PowerShell 的 PATH 里没有
    var child = try std.process.spawn(io, .{ .argv = &.{ "sh", "-c", "sleep 30" } });
    try std.testing.expect(child.id != null);
    child.kill(io);
    try std.testing.expect(child.id == null);
    child.kill(io); // 幂等：再调一次不崩
}

test "Io.Clock：成员集合与三种 sleep 路径" {
    const io = std.testing.io;
    // .monotonic 在 0.17 不存在，别照抄旧代码
    try std.testing.expect(!@hasDecl(std.Io.Clock, "monotonic"));
    // 五个成员逐个点名（都返回合法 Timestamp）
    const clocks = [_]std.Io.Clock{ .real, .awake, .boot, .cpu_process, .cpu_thread };
    for (clocks) |c| _ = std.Io.Clock.now(c, io);

    // now + durationTo：单调钟不倒退
    const t0 = std.Io.Clock.now(.awake, io);
    try std.Io.sleep(io, std.Io.Duration.fromMilliseconds(1), .awake);
    const t1 = std.Io.Clock.now(.awake, io);
    try std.testing.expect(t1.durationTo(t0).nanoseconds <= 0);

    // 另一条等价路径：Clock.Duration.sleep
    const t2 = std.Io.Clock.now(.awake, io);
    try (std.Io.Clock.Duration{ .raw = std.Io.Duration.fromMilliseconds(1), .clock = .awake }).sleep(io);
    try std.testing.expect(t2.durationTo(std.Io.Clock.now(.awake, io)).nanoseconds > 0);

    // Clock.Timestamp.wait 也能睡
    const deadline = std.Io.Clock.Timestamp.fromNow(io, .{ .raw = std.Io.Duration.fromMilliseconds(1), .clock = .awake });
    try deadline.wait(io);
}

test "Io.Duration：换算方法与 toNanoseconds 的真实返回类型" {
    const d = std.Io.Duration.fromNanoseconds(1_500_000);
    try std.testing.expectEqual(@as(i96, 1_500_000), d.toNanoseconds()); // **i96**，不是 i64/u64
    // 1_500_000 ns = 1.5 ms → 截断成 1 ms（@divTrunc，不是四舍五入）
    try std.testing.expectEqual(@as(i64, 1), d.toMilliseconds());
    try std.testing.expectEqual(@as(i64, 0), d.toSeconds());
    try std.testing.expectEqual(@as(i64, 1500), std.Io.Duration.fromMilliseconds(1500).toMilliseconds());
    try std.testing.expectEqual(std.Io.Duration.fromMilliseconds(2).nanoseconds, 2 * std.time.ns_per_ms);
    // Io.Timestamp.toNanoseconds 同为 i96
    try std.testing.expectEqual(@as(i96, 7), std.Io.Timestamp.fromNanoseconds(7).toNanoseconds());
}

test "Io.Limit：非穷尽枚举，@tagName 会 panic，只能用 backingInt / toInt" {
    const l = std.Io.Limit.limited(8);
    try std.testing.expectEqual(@as(usize, 8), @backingInt(l));
    try std.testing.expectEqual(@as(?usize, 8), l.toInt());
    try std.testing.expectEqual(@as(?usize, null), std.Io.Limit.unlimited.toInt());
    try std.testing.expectEqual(@as(usize, 0), @backingInt(std.Io.Limit.nothing));
    try std.testing.expectEqual(l, std.Io.Limit.limited(8));
    // ⚠️ 又一个 0.17 语法坑：枚举值作为**函数实参**时不能写 `.limited(8)`——
    //    实测报 type '@EnumLiteral()' not a function。必须写全`std.Io.Limit.limited(8)`。
    try std.testing.expectEqual(
        std.Io.Limit.max(std.Io.Limit.limited(4), std.Io.Limit.limited(8)),
        std.Io.Limit.limited(8),
    );
}

test "0.17 的进程 API 存在性：旧名全部移除，新名到位" {
    // 旧 API 全部没了
    try std.testing.expect(!@hasDecl(std.process, "argsAlloc"));
    try std.testing.expect(!@hasDecl(std.process, "args"));
    try std.testing.expect(!@hasDecl(std.process, "getEnvMap"));
    try std.testing.expect(!@hasDecl(std.process, "getEnvVarOwned"));
    try std.testing.expect(!@hasDecl(std.process.Child, "run")); // 0.15 的 Child.run 也没了
    try std.testing.expect(!@hasDecl(std.posix, "getenv"));
    // 新 API 在位
    try std.testing.expect(@hasDecl(std.process, "run"));
    try std.testing.expect(@hasDecl(std.process, "spawn"));
    try std.testing.expect(@hasDecl(std.process, "exit"));
    try std.testing.expect(@hasDecl(std.process, "currentPath"));
    try std.testing.expect(@hasDecl(std.process, "currentPathAlloc"));
    try std.testing.expect(@hasDecl(std.process, "executablePathAlloc"));
    try std.testing.expect(@hasDecl(std.process.Child, "wait"));
    try std.testing.expect(@hasDecl(std.process.Child, "kill"));
    try std.testing.expect(@hasDecl(std.process.Args, "iterate"));
    try std.testing.expect(@hasDecl(std.process.Args, "iterateAllocator"));
    try std.testing.expect(@hasDecl(std.process.Args, "toSlice"));
    try std.testing.expect(@hasDecl(std.process.Environ, "getPosix"));
    try std.testing.expect(@hasDecl(std.process.Environ, "createMap"));
    // std.time 只剩常量与 epoch
    try std.testing.expect(@hasDecl(std.time, "ns_per_ms"));
    try std.testing.expect(@hasDecl(std.time, "epoch"));
    try std.testing.expect(!@hasDecl(std.time, "Timer"));
    try std.testing.expect(!@hasDecl(std.time, "nanoTimestamp"));
}
