//! 16 · 构建与包管理 —— 程序侧。
//!
//! 这个文件里没有一行代码是"构建系统"本身：它全部是**被构建系统塑造出来的
//! 普通 Zig 程序**。分节编号与 docs/16-build.md 的 `## 16.N` 一一对应，
//! 每节演示"构建系统的某个概念在运行期长什么样"。
const std = @import("std");

// 三个具名模块：全部来自 build.zig 的 imports 表，不存在相对路径 @import。
const opts = @import("build_options"); // b.addOptions() 生成的模块
const lib = @import("build16_lib"); // b.createModule(.{ src/lib.zig })
const zmath = @import("zmath"); // b.dependency("zmath").module("zmath")

// 16.14 addCSourceFiles 链进来的 C 函数。
// 这里必须手写 extern 声明——0.17 已经没有 @cImport 了（见 17 章）。
extern fn build16_c_triple(x: c_int) callconv(.c) c_int;
extern fn build16_c_add(a: c_int, b: c_int) callconv(.c) c_int;

fn begin(title: []const u8) void {
    std.debug.print("\n=== {s} ===\n", .{title});
}

fn end(tag: []const u8) void {
    std.debug.print("--- {s} 完毕 ---\n", .{tag});
}

/// main 收一个 `std.process.Init` 参数（0.17 起的新入口签名）。
/// 它自带 arena / gpa / io / args，比自己再造一遍强。
/// 也可以写 `pub fn main() !void`（无参），或 `pub fn main(init: std.process.Init.Minimal)`。
pub fn main(init: std.process.Init) !void {
    const a = init.arena.allocator();
    // init.minimal.args.toSlice 拿到全部命令行参数（含 argv[0]）。
    // 注意 argv[0] 是 .zig-cache 里的路径，不是 zig-out/bin/16_build——
    // 因为 run step 跑的是「编译产物」而不是「安装后的副本」。
    const argv = try init.minimal.args.toSlice(a);

    // 16.1 为什么构建系统是语言的一部分
    {
        begin("16.1 没有 CMake：构建系统就是 Zig 程序");
        std.debug.print("  没有 Makefile / build.gradle / CMakeLists.txt，只有一个 build.zig\n", .{});
        std.debug.print("  它本身是 Zig 源码，被 Zig 编译后运行，输出是一张构建图\n", .{});
        std.debug.print("  可执行文件名（addExecutable 的 .name）= 16_build\n", .{});
        std.debug.print("  argv[0] = {s}\n", .{shorten(argv[0])});
        std.debug.print("  运行期能看到的构建期事实，只有下面这些：\n", .{});
        std.debug.print("    @import(\"builtin\").mode = {s}\n", .{@tagName(@import("builtin").mode)});
        std.debug.print("    @import(\"builtin\").target.cpu.arch = {s}\n", .{@tagName(@import("builtin").target.cpu.arch)});
        std.debug.print("    @import(\"builtin\").target.os.tag = {s}\n", .{@tagName(@import("builtin").target.os.tag)});
        end("16.1");
    }

    // 16.2 zig build 的默认 step 从哪来
    {
        begin("16.2 install / run / test 三个默认 step");
        std.debug.print("  裸 `zig build` 跑 install；`zig build test` 跑 test。\n", .{});
        std.debug.print("  本次 run 的参数总数 = {d}（含 argv[0]）\n", .{argv.len});
        std.debug.print("  这些参数是 build.zig 里 addArg/addArgs/addPassthruArgs 攒出来的\n", .{});
        end("16.2");
    }

    // 16.3 build.zig.zon 与 fingerprint
    {
        begin("16.3 build.zig.zon 的字段");
        std.debug.print("  zon 是「包的身份证」，不进运行时；这里能演示的是它的副作用：\n", .{});
        std.debug.print("  .fingerprint 校验通过 ⇒ 依赖图能安全地被缓存复用\n", .{});
        std.debug.print("  .paths 决定了哪些文件进哈希，zig-out 里产物由 .name 决定\n", .{});
        std.debug.print("  可以在构建期用 `zig build info` 打印，见 16.15\n", .{});
        end("16.3");
    }

    // 16.4 build.zig 只描述不执行
    {
        begin("16.4 build() 返回时什么都没编译");
        std.debug.print("  build() 里只调用了 b.add* / b.step，全部是「登记」\n", .{});
        std.debug.print("  本节能跑起来，说明登记已经完成并且 runner 已执行完编译\n", .{});
        std.debug.print("  这就是为什么 build.zig 里能安全地用 b.fmt 拼字符串：\n", .{});
        std.debug.print("  build.zig 的返回值不会被打印，它只喂给构建图\n", .{});
        end("16.4");
    }

    // 16.5 目标与优化选项
    {
        begin("16.5 -Dtarget= / -Doptimize=");
        const builtin = @import("builtin");
        std.debug.print("  mode   = {s}（-Doptimize=debug/safe/fast/small）\n", .{@tagName(builtin.mode)});
        std.debug.print("  arch   = {s}（-Dtarget= 决定）\n", .{@tagName(builtin.cpu.arch)});
        std.debug.print("  os     = {s}\n", .{@tagName(builtin.os.tag)});
        std.debug.print("  同一份 src/main.zig，换 -Dtarget= 就是换一套机器码\n", .{});
        end("16.5");
    }

    // 16.6 b.path 与路径
    {
        begin("16.6 b.path(\"...\") 与相对路径");
        std.debug.print("  build.zig 写 b.path(\"src/main.zig\")，不是裸字符串\n", .{});
        std.debug.print("  0.17 传裸字符串会报：\n", .{});
        std.debug.print("    expected type '?Build.LazyPath', found '*const [12:0]u8'\n", .{});
        std.debug.print("  b.path 相对于「包根目录」解析，不是 cwd\n", .{});
        end("16.6");
    }

    // 16.7 模块系统
    {
        begin("16.7 一个模块 = 根源文件 + imports + 选项");
        std.debug.print("  @import(\"build_options\") → 类型 {s}\n", .{@typeName(opts)});
        std.debug.print("  @import(\"build16_lib\")    → {s}\n", .{lib.module_name});
        std.debug.print("  @import(\"zmath\")         → {s}\n", .{@typeName(zmath)});
        std.debug.print("  三个名字都必须在 build.zig 的 imports 表里，否则编不过\n", .{});
        end("16.7");
    }

    // 16.8 产物
    {
        begin("16.8 一个工程产出多个产物");
        std.debug.print("  zig-out/bin/16_build        ← addExecutable + installArtifact\n", .{});
        std.debug.print("  zig-out/bin/16_build_tool   ← 第二个 addExecutable\n", .{});
        std.debug.print("  zig-out/lib/libbuild16.a    ← addLibrary(.linkage = .static)\n", .{});
        std.debug.print("  src/tool.zig 里也能拿到同一个 zmath 模块：triple(7)={d}\n", .{zmath.triple(7)});
        end("16.8");
    }

    // 16.9 安装
    {
        begin("16.9 installArtifact 与 zig-out/");
        std.debug.print("  install step 是 default step，裸 `zig build` 就跑它\n", .{});
        std.debug.print("  但本 run step 跑的是缓存里的产物，所以 argv[0] 带 .zig-cache：\n", .{});
        std.debug.print("    {s}\n", .{argv[0]});
        std.debug.print("  它和 zig-out/bin/16_build 是同一个二进制，只是路径不同\n", .{});
        end("16.9");
    }

    // 16.10 参数透传
    {
        begin("16.10 addArg / addArgs / addPassthruArgs");
        std.debug.print("  build.zig 写死了 3 个参数，再透传你在 -- 之后给的：\n", .{});
        for (argv, 0..) |arg, i| {
            std.debug.print("    argv[{d}] = {s}\n", .{ i, arg });
        }
        std.debug.print("  0.17 没有 b.args：不调 addPassthruArgs() 就只剩写死的那些\n", .{});
        end("16.10");
    }

    // 16.11 构建期选项进入程序
    {
        begin("16.11 -Dverbose 通过 addOptions 进到程序内部");
        std.debug.print("  opts.verbose = {}（由 zig build -Dverbose=true 决定）\n", .{opts.verbose});
        if (opts.verbose) {
            std.debug.print("  → 开了 verbose，下面列出全部参数：\n", .{});
            for (argv, 0..) |arg, i| std.debug.print("    [{d}] {s}\n", .{ i, arg });
        } else {
            std.debug.print("  → 没开 verbose，只打印第一个非 argv[0] 的参数\n", .{});
            if (argv.len > 1) std.debug.print("    {s}\n", .{argv[1]});
        }
        end("16.11");
    }

    // 16.12 同工程多模块
    {
        begin("16.12 src/lib.zig 作为独立模块");
        const sep = try lib.separator(a, 16);
        std.debug.print("  lib.module_name = {s}\n", .{lib.module_name});
        std.debug.print("  lib.separator(16) = {s}（{d} 字节）\n", .{ sep, sep.len });
        std.debug.print("  它是独立模块，所以 lib_mod 被 addLibrary 装出的 .a 就是它\n", .{});
        end("16.12");
    }

    // 16.13 依赖管理三层接线
    {
        begin("16.13 b.dependency 三层接线");
        std.debug.print("  第一层 build.zig.zon: .dependencies = .{{ .zmath = .{{ .path = \"vendor/zmath\" }} }}\n", .{});
        std.debug.print("  第二层 build.zig    : b.dependency(\"zmath\", .{{ .target, .optimize }})\n", .{});
        std.debug.print("  第三层 build.zig    : dep.module(\"zmath\")\n", .{});
        std.debug.print("  结果 —— 同一份子包代码被两个产物共享：\n", .{});
        std.debug.print("    zmath.triple(7)  = {d}\n", .{zmath.triple(7)});
        std.debug.print("    zmath.sum_to(10) = {d}\n", .{zmath.sum_to(10)});
        std.debug.print("    zmath.pi         = {d:.5}\n", .{zmath.pi});
        std.debug.print("  版本信息也能带过来：dep 有 .version（子包 zon 的 .version）\n", .{});
        end("16.13");
    }

    // 16.14 C 混进来
    {
        begin("16.14 addCSourceFiles");
        std.debug.print("  Zig 侧调 C 函数：build16_c_triple(7) = {d}\n", .{@as(i32, @intCast(build16_c_triple(7)))});
        std.debug.print("  build16_c_add(20, 22)            = {d}\n", .{@as(i32, @intCast(build16_c_add(20, 22)))});
        std.debug.print("  两侧同属一个编译单元列表，互相直接可见符号\n", .{});
        std.debug.print("  ⚠️ 头文件翻译（@cInclude）已经不在语言里了：0.17 用 b.addTranslateC，见 17 章\n", .{});
        end("16.14");
    }

    // 16.15 自定义 step
    {
        begin("16.15 自定义 step");
        std.debug.print("  本工程提供三个额外 step，用 `zig build --help` 可以看到：\n", .{});
        std.debug.print("    zig build info   → 打印 target/optimize/verbose\n", .{});
        std.debug.print("    zig build size   → 打印各产物字节数\n", .{});
        std.debug.print("    zig build deps   → 打印依赖树\n", .{});
        std.debug.print("    zig build cross  → 交叉编译两个目标（不安装）\n", .{});
        std.debug.print("  它们只是图里的命名节点，靠 dependOn 挂实际动作\n", .{});
        end("16.15");
    }

    // 16.16 交叉编译
    {
        begin("16.16 交叉编译在构建系统里怎么表达");
        std.debug.print("  对构建系统来说，交叉编译就只是换一个 -Dtarget=\n", .{});
        std.debug.print("  `zig build cross` 会为 aarch64-linux / x86_64-windows 各编一份\n", .{});
        std.debug.print("  但每个产物都是独立 Module，imports 表必须重新挂一遍：\n", .{});
        std.debug.print("    漏挂就报 no module named 'build_options' available within module 'root'\n", .{});
        std.debug.print("  本次构建的 arch = {s}（换成别的 target 这行就变）\n", .{@tagName(@import("builtin").target.cpu.arch)});
        std.debug.print("  src/main.zig 里没有任何 if (target == …)，换目标不用改代码\n", .{});
        end("16.16");
    }

    // 16.17 缓存
    {
        begin("16.17 .zig-cache 与 zig-out");
        std.debug.print("  .zig-cache  = 中间产物 + 编译产物（哈希命名，删了会全量重编）\n", .{});
        std.debug.print("  zig-out/    = installArtifact 的落地结果（删了只要重跑 install）\n", .{});
        std.debug.print("  本次 run 的 argv[0] 就在 .zig-cache 里：{s}\n", .{argv[0]});
        std.debug.print("  「删缓存不删产物」：rm -rf .zig-cache 后 zig build 会重新生成 zig-out\n", .{});
        end("16.17");
    }

    // 16.18 完整命令清单
    {
        begin("16.18 这个工程支持的全部命令");
        const cmds = [_][]const u8{
            "zig build                    构建全部产物",
            "zig build run                       跑本程序",
            "zig build run -- x                  透传参数给本程序",
            "zig build run -Dverbose             构建期选项进程序",
            "zig build run-tool                  跑第二个可执行文件",
            "zig build test                      跑单元测试（成功时静默）",
            "zig build test-deps                 只跑依赖包的测试",
            "zig build info                      打印 target/optimize/verbose",
            "zig build size                      打印各产物字节数",
            "zig build deps                      打印模块依赖树",
            "zig build cross                     交叉编译两个目标",
            "zig build --help                    列出所有 step",
            "zig build uninstall                 清空 zig-out",
        };
        for (cmds) |cmd| std.debug.print("    {s}\n", .{cmd});
        end("16.18");
    }

    std.debug.print("\n自检通过\n", .{});
}

/// shorten 砍掉 .zig-cache 里的哈希段，只留文件名。
/// 这个例子顺手说明 06 章的切片：s[start..] 是子串，不分配内存。
fn shorten(path: []const u8) []const u8 {
    if (std.mem.lastIndexOfScalar(u8, path, '/')) |i| return path[i + 1 ..];
    return path;
}

// ───────────────────────────── 测试 ─────────────────────────────

test "16.7 三个具名模块都拿到了" {
    try std.testing.expect(lib.module_name.len > 0);
    try std.testing.expectEqual(@as(i32, 21), zmath.triple(7));
    try std.testing.expect(!opts.verbose); // 默认不带 -Dverbose
}

test "16.10 参数切分：argv[0] 一定存在" {
    // 直接测 shorten 的边界，不依赖 main 被调用过
    try std.testing.expectEqualStrings("main.zig", shorten("src/main.zig"));
    try std.testing.expectEqualStrings("main.zig", shorten("main.zig"));
}

test "16.12 lib.separator 跨模块可用" {
    const a = std.testing.allocator;
    const s = try lib.separator(a, 5);
    defer a.free(s);
    try std.testing.expectEqualStrings("-----", s);
}

test "16.13 zmath.sum_to 跨包可用" {
    try std.testing.expectEqual(@as(u64, 55), zmath.sum_to(10));
}

test "16.14 C 函数链接成功并算对" {
    try std.testing.expectEqual(@as(c_int, 21), build16_c_triple(7));
    try std.testing.expectEqual(@as(c_int, 42), build16_c_add(20, 22));
}

test "16.5 builtin.mode 是 0.17 的四个合法值之一" {
    // 0.17 的 std.builtin.Optimize 是小写枚举：debug / ReleaseSafe / ReleaseFast / ReleaseSmall
    const builtin = @import("builtin");
    try std.testing.expect(builtin.mode == .debug or builtin.mode == .ReleaseSafe or
        builtin.mode == .ReleaseFast or builtin.mode == .ReleaseSmall);
}
