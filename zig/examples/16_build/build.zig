//! 16 · 构建与包管理 —— 0.17 的 build.zig 全貌。
//!
//! 本文件是**描述**，不是执行：`build()` 返回之前一条编译命令都没跑，
//! 全部动作只是往 `b`（构建图）里登记节点和依赖边；真正的编译/链接/运行
//! 由外部 runner 按依赖拓扑并行调度。所以 build.zig 里没有 if (env.os == …)
//! 这种"运行时才知道"的信息——它拿到的是命令行选项。
//!
//! 分节对照 docs/16-build.md 的 `## 16.N`。
const std = @import("std");

pub fn build(b: *std.Build) void {
    // ── 16.5 目标与优化选项 ────────────────────────────────────────────
    // 这两行是 `-Dtarget=` / `-Doptimize=` 的唯一来源。0.17 签名：
    //   standardTargetOptions(args: StandardTargetOptionsArgs) ResolvedTarget
    //   standardOptimizeOption(options: StandardOptimizeOptionOptions) std.builtin.Optimize
    // standardTargetOptions 返回的是 ResolvedTarget（结构体，含 .query 与 .result），
    // 不是 0.11 时代的裸 ResolvedTarget 指针——用 target.result 拿具体 Target。
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ── 16.11 构建期把选项变成"编译期常量" ────────────────────────────
    // 自定义 -D 选项。0.17 签名：option(comptime T, name, desc) ?T
    // 返回可选值，所以惯例是 `orelse` 给默认值（这里默认"精简版输出"）。
    const verbose = b.option(bool, "verbose", "打印全部命令行参数") orelse false;

    // addOptions() 生成一个"由构建脚本生成的 Zig 源文件"，
    // createModule() 把它变成一个可被 @import 的模块——这是把 -Dxxx
    // 送进程序内部的正规途径（比运行时读环境变量更好：值进缓存键）。
    const opts = b.addOptions();
    opts.addOption(bool, "verbose", verbose);
    const opts_mod = opts.createModule();

    // ── 16.12 同工程多模块 ────────────────────────────────────────────
    // src/lib.zig 不通过 @import("lib.zig") 相对导入，而是当成一个**具名模块**
    // 挂进主模块的 imports 表。这样它有自己的 target/optimize 作用域，
    // 也能被第二个可执行文件独立复用。
    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // ── 16.13 依赖管理：三层接线 ──────────────────────────────────────
    // 第一层：build.zig.zon 里 .dependencies 声明 .zmath = .{ .path = "vendor/zmath" }
    // 第二层：b.dependency("zmath", .{…}) 拿到 Dependency
    // 第三层：dep.module("zmath") 取出**子包 build.zig 里 addModule 的那个名字**对应的模块
    //
    // 注意第二层的参数不是随便传的：子包 build.zig 会用 standardTargetOptions
    // 读同一批 -D 参数，所以这里必须把 target/optimize 转发过去，
    // 否则子包会拿到"本机默认值"而不是用户指定的跨编译目标。
    const zmath_dep = b.dependency("zmath", .{
        .target = target,
        .optimize = optimize,
    });
    const zmath_mod = zmath_dep.module("zmath");

    // ── 16.7 模块系统：一个模块 = 根源文件 + imports + 选项 ────────────
    // createModule 的字段见 std.Build.Module.CreateOptions（0.17 共 20+ 个，
    // 常用的：root_source_file / imports / target / optimize / link_libc /
    // single_threaded / strip / pic / sanitize_thread）。
    const main_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "build_options", .module = opts_mod },
            .{ .name = "build16_lib", .module = lib_mod },
            .{ .name = "zmath", .module = zmath_mod },
        },
    });

    // ── 16.14 把 C 混进来 ────────────────────────────────────────────
    // addCSourceFiles 把 .c 交给内置 clang 前端，与 Zig 一起链接。
    // （头文件翻译是另一件事：0.17 起 @cImport 已移除，改 b.addTranslateC，见 17 章）
    main_mod.addCSourceFiles(.{
        .root = b.path("csrc"),
        .files = &.{"helper.c"},
        .flags = &.{ "-I", "csrc" },
    });

    // ── 16.8 产物：addExecutable ─────────────────────────────────────
    // 0.17 签名：addExecutable(options: ExecutableOptions) *Step.Compile
    // ExecutableOptions 只有 name / root_module 是必填，其余可选。
    // （0.11 时代的 b.addExecutable("name", "root.zig") 两参数形式已不存在）
    const exe = b.addExecutable(.{
        .name = "16_build",
        .root_module = main_mod,
    });

    // ── 16.8 产物：addLibrary ────────────────────────────────────────
    // 0.17 只有统一的 addLibrary，链接方式由 .linkage 决定（.static 默认 /
    // .dynamic）。注意：addStaticLibrary / addSharedLibrary / installLibrary
    // 在 0.17 已被移除，实测报 "no field or member function named …"。
    const lib = b.addLibrary(.{
        .name = "build16",
        .linkage = .static,
        .root_module = lib_mod,
    });

    // ── 16.8 第二个可执行文件 ────────────────────────────────────────
    // 同一个 build.zig 可以产出多个产物：tool 有自己的根模块，
    // 复用同一个 zmath 依赖（同一个 Module 实例 ⇒ 只编译一次）。
    const tool = b.addExecutable(.{
        .name = "16_build_tool",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/tool.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zmath", .module = zmath_mod },
            },
        }),
    });

    // ── 16.9 安装：installArtifact ────────────────────────────────────
    // 挂到 install step 上（install 是默认 step，裸 `zig build` 就跑它）。
    // 可执行文件进 zig-out/bin/，库进 zig-out/lib/。
    b.installArtifact(exe);
    b.installArtifact(lib);
    b.installArtifact(tool);

    // ── 16.10 run step 与命令行参数 ──────────────────────────────────
    // addRunArtifact 造一个"运行编译产物"的 step；它**不会**自动透传
    // 命令行参数——0.17 已移除 b.args，必须显式 addPassthruArgs()。
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.addArg("--from-build-zig"); // 构建期写死的参数
    run_cmd.addArgs(&.{ "--label", "16 章" }); // 一次性给一批
    run_cmd.addPassthruArgs(); // 把 `zig build run -- x y` 的 x y 转发给程序
    const run_step = b.step("run", "运行 16_build（-- 之后的参数会透传给程序）");
    run_step.dependOn(&run_cmd.step);

    // 第二个可执行文件的 run step
    const tool_run = b.addRunArtifact(tool);
    tool_run.addPassthruArgs();
    const tool_run_step = b.step("run-tool", "运行 16_build_tool");
    tool_run_step.dependOn(&tool_run.step);

    // ── 16.4 test step ───────────────────────────────────────────────
    // addTest 只**编译**测试可执行文件（等价 zig test --test-no-exec），
    // 不负责跑；要跑必须再包一层 addRunArtifact。
    // 0.17 的 TestOptions 只有 root_module，没有 root_source_file / target /
    // optimize 字段——那些都搬进 Module.CreateOptions 里了。
    const unit_tests = b.addTest(.{ .root_module = main_mod });
    const test_run = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "跑单元测试");
    test_step.dependOn(&test_run.step);

    // 子包自己的测试：证明路径依赖的测试也能被调度
    const dep_tests = b.addTest(.{
        .name = "zmath-test",
        .root_module = zmath_mod,
    });
    const dep_test_step = b.step("test-deps", "只跑依赖包的测试");
    dep_test_step.dependOn(&b.addRunArtifact(dep_tests).step);

    // ── 16.15 自定义 step ①：info ────────────────────────────────────
    // b.step(name, desc) 在图里建一个**命名节点**，它自己什么都不做，
    // 只靠 dependOn 挂别的 step。返回值 *Step 必须用掉，不能当语句丢弃
    // （裸写 b.step("x","x"); 会报 "value of type '*Build.Step' ignored"）。
    const info_step = b.step("info", "打印当前构建配置");
    // addSystemCommand 起一个外部进程；每条 dependOn 就是图里一条边。
    const info_lines = [_][]const u8{
        b.fmt("target   = {s}-{s}", .{
            @tagName(target.result.cpu.arch),
            @tagName(target.result.os.tag),
        }),
        b.fmt("optimize = {s}", .{@tagName(optimize)}),
        b.fmt("verbose  = {}", .{verbose}),
    };
    // 同 16.15③：一次 printf 打完，避免并行执行导致顺序错乱。
    const info_cmd = b.addSystemCommand(&.{ "sh", "-c", "printf '%s\\n' \"$@\"", "sh" });
    info_cmd.addArgs(&info_lines);
    info_step.dependOn(&info_cmd.step);

    // ── 16.15 自定义 step ②：size ────────────────────────────────────
    // 对每个产物跑一次 `wc -c`。用 sh -c 把路径重定向成 stdin，
    // 这样输出里只有字节数、没有 .zig-cache 里的哈希路径。
    // ⚠️ 这一步依赖 POSIX sh，Windows 上要换成 PowerShell 写法。
    const size_step = b.step("size", "打印各产物的字节数（顺序不保证，步是并行跑的）");
    for ([_]*std.Build.Step.Compile{ exe, lib, tool }) |art| {
        const wc = b.addSystemCommand(&.{ "sh", "-c", "wc -c < \"$1\"", "sh" });
        wc.addFileArg(art.getEmittedBin());
        size_step.dependOn(&wc.step);
    }

    // ── 16.15 自定义 step ③：deps ────────────────────────────────────
    // 打印依赖树。lazyDependency 在依赖已 fetch 时返回非 null；
    // 未 fetch 时返回 null 并把包登记为"懒依赖"，
    // 下次重跑 build.zig 之前 runner 会先把它下载下来再重跑一次。
    // 0.17 里 lazyDependency 已标注 Deprecated，新代码用 dependencyLazy。
    const deps_step = b.step("deps", "打印依赖树");
    const dep_lines: []const []const u8 = if (b.lazyDependency("zmath", .{
        .target = target,
        .optimize = optimize,
    })) |dep|
        &.{
            "build16 的模块依赖树：",
            "  |- build_options   (b.addOptions() 生成的模块)",
            "  |- build16_lib     -> src/lib.zig",
            b.fmt("  `- zmath           -> {f}", .{dep.module("zmath").root_source_file.?}),
        }
    else
        &.{
            "build16 的模块依赖树：",
            "  |- build_options   (b.addOptions() 生成的模块)",
            "  |- build16_lib     -> src/lib.zig",
            "  `- zmath           (尚未 fetch，已登记为懒依赖)",
        };
    // ⚠️ 用 `sh -c 'echo "$@"'` 一次打印多行：不能挂多条echo step，
    //    因为 runner 会**并行**跑它们，输出顺序就乱了。
    //    这是本章最值得记住的构建系统特性：步与步之间没有顺序保证。
    const deps_cmd = b.addSystemCommand(&.{ "sh", "-c", "printf '%s\\n' \"$@\"", "sh" });
    deps_cmd.addArgs(dep_lines);
    deps_step.dependOn(&deps_cmd.step);

    // ── 16.16 交叉编译 ──────────────────────────────────────────────
    // 交叉编译不需要在 build.zig 里写"如果目标是 arm 就怎么怎样"——
    // 它就只是换一个 -Dtarget=。但**每个产物都是独立的 Module**，
    // imports 表不会自动继承：src/main.zig 里 @import("build_options")、
    // @import("build16_lib")、@import("zmath") 三个名字都得重新挂一遍。
    // 漏挂就报：
    //   error: no module named 'build_options' available within module 'root'
    // 这就是"模块 = 根源文件 + imports + 选项"这句话的代价：显式，但也啰嗦。
    const cross_targets = [_][]const u8{ "aarch64-linux", "x86_64-windows" };
    const cross_step = b.step("cross", "为常见交叉目标各编一份（不安装）");
    for (cross_targets) |triple| {
        // Query.parse 解析 "arch-os-abi" 三元组，再 resolveTargetQuery 落成具体 Target。
        const q = std.Target.Query.parse(.{ .arch_os_abi = triple }) catch unreachable;
        const resolved = b.resolveTargetQuery(q);
        const cross_exe = b.addExecutable(.{
            .name = b.fmt("16_build-{s}", .{triple}),
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/main.zig"),
                .target = resolved,
                .optimize = .ReleaseSmall,
                .imports = &.{
                    .{ .name = "build_options", .module = opts_mod },
                    .{ .name = "build16_lib", .module = lib_mod },
                    .{ .name = "zmath", .module = zmath_mod },
                },
            }),
        });
        // 不调 installArtifact —— 只编，产物留在 .zig-cache 里，不进 zig-out/
        cross_step.dependOn(&cross_exe.step);
    }
}
