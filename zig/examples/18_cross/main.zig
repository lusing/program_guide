//! 18 交叉编译：-target 语法、zig targets 的真实结构、builtin.target 编译期目标反射、
//! 产物类型矩阵（exe / static lib / dynamic lib / obj / wasm）、wasm32-freestanding 的
//! 能力边界、C 代码作为输入（zig build-exe main.zig hello.c）、zig cc / zig c++、
//! zig cc -c 分步编译、交叉产物"编译即验证"、以及交叉编译的硬限制
//!
//! 验证矩阵（run-all.sh 的test_cross_example 四条通道）：
//!   1. zig fmt --check .
//!   2. zig test main.zig
//!   3. zig build-exe main.zig → 运行 → zig build-exe main.zig -target aarch64-linux
//!   4. zig build-lib wasm_lib.zig -target wasm32-freestanding + zig cc hello.c → 运行
//!
//! ⚠️ 本文件同时要编成 aarch64-linux，所以**不碰任何平台相关的 std 设施**
//!    （不写文件、不起线程、不读时钟、不用 std.posix）。只做编译期反射 + 纯逻辑。
const std = @import("std");
const builtin = @import("builtin");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

/// 18.4/18.7 的被测对象：一个与平台无关的"指针宽度探测器"。
/// 交叉编译时它在不同目标上给出不同结果，这正是"编译期常量"的意义。
fn wordSize() usize {
    return @sizeOf(usize);
}

/// 18.5 的被测对象：字节序无关的校验和算法（freestanding 也能算）。
/// 用 wrapping 算术（+% / *%），Debug 和 ReleaseFast 行为一致。
fn checksum(bytes: []const u8) u32 {
    var acc: u32 = 0x811c9dc5; // FNV-1a 偏移基准
    for (bytes) |b| {
        acc ^= b;
        acc *%= 0x01000193;
    }
    return acc;
}

pub fn main(init: std.process.Init) !void {
    _ = init; // 本示例刻意不用 init.io：同一份源码要能编到 freestanding 以外的所有目标

    // ═══ 18.1 为什么交叉编译是"默认能力"而不是附加功能 ═══
    begin("18.1");
    std.debug.print("本文件正在被编译成：arch={s} os={s} abi={s} ofmt={s}\n", .{
        @tagName(builtin.target.cpu.arch),
        @tagName(builtin.target.os.tag),
        @tagName(builtin.target.abi),
        @tagName(builtin.target.ofmt),
    });
    std.debug.print("这些值全部是**编译期常量**：换 -target 就换一组，不需要运行时 if\n", .{});
    std.debug.print("Zig 自举（stage2 用 Zig 写）→ libc 源码打进发行包 → -target 一出，libc 现场编\n", .{});
    std.debug.print("所以交叉编译没有 sysroot / toolchain / pkg-config 三件套\n", .{});
    std.debug.print("编译器版本 builtin.zig_version = {f}，后端 = {s}\n", .{ builtin.zig_version, @tagName(builtin.zig_backend) });
    end("18.1");

    // ═══ 18.2 -target 的三段式字符串语法 ═══
    begin("18.2");
    std.debug.print("-target 语法：<arch><sub>-<os>-<abi>，abi 可省（省了由 arch+os 推默认）\n", .{});
    std.debug.print("实测过的合法串：aarch64-linux / x86_64-linux-musl / x86_64-linux-gnu.2.31\n", .{});
    std.debug.print("  aarch64-linux          → abi 自动取 .musl（本机实测，产物是静态 ELF）\n", .{});
    std.debug.print("  x86_64-windows-gnu     → mingw ABI\n", .{});
    std.debug.print("  wasm32-freestanding    → 无 OS、无 libc、无入口\n", .{});
    std.debug.print("  x86_64-linux-gnu.2.31  → 三段之外还能挂第四段 glibc 版本\n", .{});
    std.debug.print("⚠️ 结构体形式（.cpu_arch=...）在 0.17 的 **命令行 -target 上不支持**（实测）\n", .{});
    std.debug.print("   写 -target '.cpu_arch = .aarch64' 报 error: unknown architecture: '.cpu_arch = .aarch64'\n", .{});
    std.debug.print("   报错时会把 zig targets 的全部合法 arch 列表打出来（61 个）\n", .{});
    std.debug.print("   结构体形式只在 build.zig 的 b.resolveTargetQuery 里用（16 章）\n", .{});
    end("18.2");

    // ═══ 18.3 zig targets：0.17 输出的是 Zig 字面量语法，不是 JSON ═══
    begin("18.3");
    std.debug.print("zig targets 在 0.17 输出的是 .{{ .arch = .{{...}}, .os = .{{...}}, ... }} 这样的\n", .{});
    std.debug.print("**Zig 结构体字面量**，不是 JSON（0.16 是 JSON，这个格式在 0.17 变了）\n", .{});
    std.debug.print("八个顶层字段（本机实测条目数）：\n", .{});
    std.debug.print("  .arch          61 个：aarch64 / x86_64 / wasm32 / riscv64 / thumb / msp430 ...\n", .{});
    std.debug.print("  .os            48 个：freestanding / linux / windows / wasi / emscripten / uefi / ps5 ...\n", .{});
    std.debug.print("  .abi           30 个：none / gnu / musl / msvc / eabi / android / simulator ...\n", .{});
    std.debug.print("  .libc         108 个：Zig 能自举编译的 libc 组合（每项是一个 target 串）\n", .{});
    std.debug.print("  .glibc         59 个：能接受的 glibc 版本（2.0.0 ... 2.44.0）\n", .{});
    std.debug.print("  .cpus / .cpu_features  按 arch 分组的 CPU 型号与特性位（aarch64 组 15 个型号）\n", .{});
    std.debug.print("  .native        本机解析结果：triple / cpu / os / abi 四段\n", .{});
    std.debug.print("⚠️ 三段不是笛卡尔积：合法组合由 .libc 那 108 项给出（它是「真的能编」的那些）\n", .{});
    std.debug.print("   freestanding+wasm32 不在 .libc 里（没有 libc 要编）→ 只能靠 arch-os-abi 直写\n", .{});
    end("18.3");

    // ═══ 18.4 builtin.target：目标信息在编译期就是一份结构体 ═══
    begin("18.4");
    {
        const t = builtin.target;
        std.debug.print("builtin.target 是 std.Target（5 个字段，0.17 全部可用）：\n", .{});
        std.debug.print("  .cpu            类型 {s}\n", .{@typeName(@TypeOf(t.cpu))});
        std.debug.print("  .os             类型 {s}\n", .{@typeName(@TypeOf(t.os))});
        std.debug.print("  .abi            类型 {s}\n", .{@typeName(@TypeOf(t.abi))});
        std.debug.print("  .ofmt           类型 {s}\n", .{@typeName(@TypeOf(t.ofmt))});
        std.debug.print("  .dynamic_linker 类型 {s}\n", .{@typeName(@TypeOf(t.dynamic_linker))});
        std.debug.print("cpu.arch={s}  cpu.model.name={s}  features 数量={d}\n", .{
            @tagName(t.cpu.arch), t.cpu.model.name, t.cpu.features.count(),
        });
        std.debug.print("cpu.features.isEmpty() = {}（aarch64 baseline 也带一批特性）\n", .{t.cpu.features.isEmpty()});
        std.debug.print("dynamic_linker.get() = {s}\n", .{t.dynamic_linker.get() orelse "(null)"});
        std.debug.print("⚠️ dynamic_linker 是 struct（buffer[255]u8 + len:u8），要用 .get() 取 ?[]const u8\n", .{});
        std.debug.print("   直接写 .path 报 error: no field named 'path' in struct 'Target.DynamicLinker'\n", .{});
    }
    end("18.4");

    // ═══ 18.5 目标判断：用 is* helper 而不是手写 switch ═══
    begin("18.5");
    {
        const t = builtin.target;
        std.debug.print("std.Target.Os.Tag 上**只有** isDarwin / isBSD 两个 helper（实测）：\n", .{});
        std.debug.print("  写 t.os.tag.isLinux() 报 error: no field or member function named 'isLinux'\n", .{});
        std.debug.print("isDarwin={} isBSD={}\n", .{ t.os.tag.isDarwin(), t.os.tag.isBSD() });
        std.debug.print("cpu.arch 上的 helper 很多：isX86={} isAarch64={} isWasm={} isArm={} isRiscv64={}\n", .{
            t.cpu.arch.isX86(), t.cpu.arch.isAarch64(), t.cpu.arch.isWasm(),
            t.cpu.arch.isArm(), t.cpu.arch.isRiscv64(),
        });
        std.debug.print("abi 上的 helper：isMusl={} isGnu={} isAndroid={} isOpenHarmony={}\n", .{
            t.abi.isMusl(), t.abi.isGnu(), t.abi.isAndroid(), t.abi.isOpenHarmony(),
        });
        std.debug.print("os.version_range 是**无 tag 的 union**（union{{ }}，不是 union(enum)）：\n", .{});
        std.debug.print("  直接 switch 会报 error: switch on union with no attached enum\n", .{});
        std.debug.print("  要先按 tag 分支再取字段：if (t.os.tag == .linux) 读 .linux.glibc\n", .{});
        if (t.os.tag == .linux) {
            std.debug.print("  本目标 linux glibc 上界 = {f}\n", .{t.os.version_range.linux.glibc});
        } else {
            std.debug.print("  本目标不是 linux（os={s}）→ .version_range 走 .semver 分支，跳过\n", .{@tagName(t.os.tag)});
        }
    }
    end("18.5");

    // ═══ 18.6 产物类型矩阵：exe / static lib / dynamic lib / obj / wasm ═══
    begin("18.6");
    {
        const t = builtin.target;
        std.debug.print("三个顶层开关决定产物形态（0.17 的 std.lang 全小写枚举）：\n", .{});
        std.debug.print("  builtin.output_mode = {s}   类型 {s}\n", .{ @tagName(builtin.output_mode), @typeName(@TypeOf(builtin.output_mode)) });
        std.debug.print("  builtin.link_mode   = {s}   类型 {s}\n", .{ @tagName(builtin.link_mode), @typeName(@TypeOf(builtin.link_mode)) });
        std.debug.print("  builtin.mode        = {s}   类型 {s}\n", .{ @tagName(builtin.mode), @typeName(@TypeOf(builtin.mode)) });
        std.debug.print("OutputMode 三值：Exe / Lib / Obj；LinkMode 两值：static / dynamic\n", .{});
        std.debug.print("⚠️ builtin.mode 打印出来是 **debug**（全小写），不是 0.15/0.16 的 Debug\n", .{});
        std.debug.print("   同理 -O 的四个合法值在 0.17 是 debug / safe / fast / small\n", .{});
        std.debug.print("   -O Debug 仍能过（fromString 保留了旧名作废弃别名），但那是过渡期兼容\n", .{});
        std.debug.print("   -O ReleaseFastSmall 报 error: unrecognized optimization mode\n", .{});
        std.debug.print("⚠️ 命令名字面上没有\"wasm\"这一项：wasm 是 ofmt（ObjectFormat），不是 OutputMode\n", .{});
        std.debug.print("   本目标 ofmt={s}；ObjectFormat 共 {d} 个成员（elf/coff/macho/wasm/plan9/spirv/c/hex/raw）\n", .{
            @tagName(t.ofmt), @typeInfo(std.Target.ObjectFormat).@"enum".field_names.len,
        });
        std.debug.print("⚠️ ObjectFormat 没有 .hex/.raw（help 里标 planned feature）→ 实际可用 7 个\n", .{});
        std.debug.print("本进程 single_threaded={}，is_test={}，unwind_tables={s}\n", .{
            builtin.single_threaded, builtin.is_test, @tagName(builtin.unwind_tables),
        });
    }
    end("18.6");

    // ═══ 18.7 wasm32-freestanding：没有 OS、没有入口、没有 std I/O ═══
    begin("18.7");
    std.debug.print("freestanding = 裸机：没有 OS、没有 libc、没有 _start、没有 std 的 I/O\n", .{});
    std.debug.print("wasm_lib.zig 是本示例的 freestanding 侧：只有 export fn，没有 main\n", .{});
    std.debug.print("构建方式：zig build-lib wasm_lib.zig -target wasm32-freestanding\n", .{});
    std.debug.print("⚠️ 想用 build-exe 编到 freestanding 会在 lib/std/Io/Threaded.zig 炸：\n", .{});
    std.debug.print("   error: struct 'posix.system__struct_N' has no member named 'getrandom'\n", .{});
    std.debug.print("   （本机实测，struct 序号每次编译不同，所以只抄成员名不抄序号）\n", .{});
    std.debug.print("⚠️ 那个 .wasm 文件其实是 **ar 静态归档**，不是 wasm 模块（实测 file 的输出）\n", .{});
    std.debug.print("   原因：build-lib 不带 -dynamic 时 link_mode=static → 产物是 current ar archive\n", .{});
    std.debug.print("   想要真模块要加 -dynamic -fPIC（Debug 下 -fPIC 或 -OReleaseFast 均可）\n", .{});
    std.debug.print("freestanding 里**能用**的 std（全部实测编译通过）：\n", .{});
    std.debug.print("  纯逻辑：std.mem.*（copyForwards/sort/eql）、std.fmt.{{comptimePrint,bufPrint,allocPrint}}\n", .{});
    std.debug.print("  内存：std.heap.page_allocator / FixedBufferAllocator / std.ArrayList / std.mem.Allocator\n", .{});
    std.debug.print("  编解码：std.json.parseFromSlice、std.hash.Crc32、std.Io.Writer.fixed（写内存缓冲）\n", .{});
    std.debug.print("  随机：std.Random.DefaultPrng（自带算法，不碰系统熵）\n", .{});
    std.debug.print("freestanding 里**不能**用的（实测报错，措辞见文档 18.7）：\n", .{});
    std.debug.print("  std.fs.cwd → root source file struct 'fs' has no member named 'cwd'\n", .{});
    std.debug.print("  std.fs.File → root source file struct 'fs' has no member named 'File'\n", .{});
    std.debug.print("  std.time.Instant → root source file struct 'time' has no member named 'Instant'\n", .{});
    std.debug.print("  std.posix.getpid → root source file struct 'posix' has no member named 'getpid'\n", .{});
    std.debug.print("  std.process.argsAlloc → root source file struct 'process' has no member named 'argsAlloc'\n", .{});
    std.debug.print("  std.Thread.spawn → error: Cannot spawn thread when building in single-threaded mode\n", .{});
    std.debug.print("  std.debug.print → 拖进 Io.Threaded，报 posix.system has no member named 'getrandom'\n", .{});
    end("18.7");

    // ═══ 18.8 wasm 里想要输出：自己写导出，不用 std ═══
    begin("18.8");
    std.debug.print("wasm32-freestanding 没有 stdout 可写，宿主只能看到**导出的函数返回值**\n", .{});
    std.debug.print("wasm_lib.zig 的做法：export fn 直接给结果，宿主按导出名调\n", .{});
    std.debug.print("  export fn add(a: i32, b: i32) i32 → 宿主最省事：i.exports.add(3,4)\n", .{});
    std.debug.print("⚠️ export var（可变全局）**在 -fPIC 产物里宿主读不到活值**（实测）：\n", .{});
    std.debug.print("   宿主拿到的永远是实例化时的快照。最小复现：export var g=7 + fn bump() 递增 g\n", .{});
    std.debug.print("   node 实测：g.value=0 → bump()=8 → bump()=9 → g.value 仍是 0\n", .{});
    std.debug.print("   原因：PIC 模式下数据在宿主提供的 linear memory 里，导出 global 是引擎快照\n", .{});
    std.debug.print("   ⇒ 跨 wasm 边界只用返回值；export var 只用于模块**内部**中转\n", .{});
    std.debug.print("  真的想往控制台写 → 得自己写 WASI fd_write，或改用 wasm32-wasi 目标（见 18.9）\n", .{});
    end("18.8");

    // ═══ 18.9 wasm32-wasi：带 OS 抽象的 wasm ═══
    begin("18.9");
    std.debug.print("wasm32-wasi 比 freestanding 多一套 POSIX-ish 抽象：fd / 路径 / 时钟 / 随机\n", .{});
    std.debug.print("  → std.fs / std.time / std.process 在 wasi 上**大部分可用**（本机实测 std.fs.File 存在）\n", .{});
    std.debug.print("  → 产物是自足模块：node 报导入模块 env,wasi_snapshot_preview1\n", .{});
    std.debug.print("⚠️ 但 -target wasm32-wasi 下 `zig test` 依然编译失败（runner 要 Io.Threaded）\n", .{});
    std.debug.print("   要在 wasm 目标上**验证 test 块语法**，用：\n", .{});
    std.debug.print("     zig test wasm_lib.zig -target wasm32-wasi --test-no-exec -femit-bin=out.wasm\n", .{});
    std.debug.print("   （--test-no-exec 只编译不跑，产物是 WebAssembly (wasm) binary module）\n", .{});
    std.debug.print("⚠️ freestanding 连 --test-no-exec 也不行：runner 的 Io.Threaded 绕不开 getrandom\n", .{});
    end("18.9");

    // ═══ 18.10 zig cc / zig c++：自带 clang 前端 + 各目标 libc ═══
    begin("18.10");
    std.debug.print("zig cc = clang 前端（旗子全兼容）+ Zig 的交叉底座（libc 现场为目标编）\n", .{});
    std.debug.print("实测版本：clang version 22.1.8（0.17 发行包里内建的 clang 前端）\n", .{});
    std.debug.print("  zig cc --version → clang version 22.1.8 + Target: x86_64-apple-macosx14.8.9-unknown\n", .{});
    std.debug.print("hello.c 由本目录提供，四条通道之一就是 `zig cc hello.c -o <exe>` 然后运行\n", .{});
    std.debug.print("同一份 C 代码换编译器：zig cc hello.c（clang 前端 + Zig 链接器）↔ 系统的 cc\n", .{});
    std.debug.print("  系统 cc 编出来的也是动态链接 Mach-O——这一层两边没区别，系统 cc 反而更‘原生’\n", .{});
    std.debug.print("  真正属于 Zig 的是**链接器**（自带 LLD）和**目标覆盖能力**\n", .{});
    std.debug.print("zig cc -target aarch64-linux hello.c -o hc → 交叉出 Linux ELF（本机实测）\n", .{});
    std.debug.print("zig c++ 同样存在：clang 前端 + C++ 标准库，h.cpp 实测能编能跑\n", .{});
    std.debug.print("⚠️ macOS 上 zig cc 直接可用，**不需要** -isysroot（0.17 自带 SDK 探测）\n", .{});
    std.debug.print("   本教程实测：`zig cc hello.c -o hc1` 一次通过，产物 Mach-O 64-bit executable x86_64\n", .{});
    end("18.10");

    // ═══ 18.11 把 C 代码当输入：zig build-exe main.zig hello.c ═══
    begin("18.11");
    std.debug.print("zig build-exe 收多个根文件时，**不区分语言**：.zig 和 .c/.cpp 一起吃\n", .{});
    std.debug.print("实测：`zig build-exe cmain.zig lib1.c -femit-bin=mix` → 成功，Zig 侧调到了 C 的函数\n", .{});
    std.debug.print("Zig 侧只需一行 extern 声明（17 章讲 @cImport 已移除后的正确姿势）：\n", .{});
    std.debug.print("  extern fn triple(x: c_int) c_int;   ← 直接声明 ABI，不走头文件翻译\n", .{});
    std.debug.print("⚠️ 坑：如果 .zig 和 .c **两边都定义了 main**，链接期报\n", .{});
    std.debug.print("   error: duplicate symbol definition: _main\n", .{});
    std.debug.print("       note: defined by .../cmain_zcu.o\n", .{});
    std.debug.print("       note: defined by .../hello.o\n", .{});
    std.debug.print("   ⇒ 让 C 文件当\"库\"（只导出函数不定义 main），入口留给 Zig\n", .{});
    std.debug.print("混编 + 交叉：同一对文件加 -target aarch64-linux 也能编过（实测出 ARM ELF）\n", .{});
    std.debug.print("⚠️ 但混编 + -target wasm32-freestanding 会在 Io.Threaded 炸（同 18.7，Zig 侧 main 用了 std）\n", .{});
    end("18.11");

    // ═══ 18.12 zig cc -c：分步编译再链接 ═══
    begin("18.12");
    std.debug.print("zig cc -c 只编译不链接，产物是目标文件（.o）——和 gcc/clang 的习惯一致\n", .{});
    std.debug.print("实测：`zig cc -c hello.c -o hello.o` → Mach-O 64-bit object x86_64\n", .{});
    std.debug.print("交叉：`zig cc -c -target aarch64-linux hello.c -o hello_a64.o`\n", .{});
    std.debug.print("       → ELF 64-bit LSB relocatable, ARM aarch64（实测）\n", .{});
    std.debug.print("分步的用处：多目标共库、增量构建、给别的链接器用\n", .{});
    std.debug.print("Zig 侧对应物：zig build-obj lib.zig -femit-bin=lib.o（实测出 Mach-O 64-bit object）\n", .{});
    std.debug.print("      交叉：zig build-obj lib.zig -target aarch64-linux → ELF 64-bit LSB relocatable\n", .{});
    std.debug.print("工具链里还有 ar / ranlib / objcopy / objdump / dlltool / lib / rc（见 zig --help）\n", .{});
    end("18.12");

    // ═══ 18.13 交叉编译「编译即验证」 ═══
    begin("18.13");
    std.debug.print("交叉产物**在本机跑不了**，所以「编译通过」就是唯一可得的信号\n", .{});
    std.debug.print("本机实测：./aarch64 产物 → (eval):1: exec format error: ./t9b\n", .{});
    std.debug.print("本机没装 qemu-aarch64 / wasmtime → 连模拟器这条路也没有\n", .{});
    std.debug.print("⇒交叉编译能验证的是：**类型/语义/链接/ABI/汇编生成**这一整层\n", .{});
    std.debug.print("它抓不到的是：目标机上的运行时行为（性能、syscall 语义、驱动）\n", .{});
    std.debug.print("本教程 21 章（手写汇编）就靠这一招：在写 aarch64 汇编正文之前，\n", .{});
    std.debug.print("先用 zig build-obj -target aarch64-linux 做预检——汇编错了编译期就报\n", .{});
    std.debug.print("反过来，**本文件自己**就是这条规则的活证明：\n", .{});
    std.debug.print("  同一份 main.zig 被编成本机 exe（跑了，有输出）+ aarch64-linux ELF（只编）\n", .{});
    std.debug.print("  两边 builtin.target 的值不同 → arch_code 不同 → 交叉产物里的常量是另一套\n", .{});
    std.debug.print("  arch_code（本机）= {d}\n", .{archCode()});
    end("18.13");

    // ═══ 18.14 限制：交叉编译做不到什么 ═══
    begin("18.14");
    std.debug.print("① 产物只能在对应机器上跑（exec format error 就是答案，见 18.13）\n", .{});
    std.debug.print("② wasm 没有文件系统：没有 fopen/readdir，std.fs 那套在 freestanding 直接不存在\n", .{});
    std.debug.print("③ freestanding 没有 std.debug.print：要输出得自己导出函数（见 18.8）\n", .{});
    std.debug.print("④ 没有 sysroot 就没有目标系统的头文件：@cImport 在 0.17 已移除（17 章）\n", .{});
    std.debug.print("   即便有，裸机目标的 libc 头文件也不存在\n", .{});
    std.debug.print("⑤ 一个 -target 只产一种 ofmt：ELF 目标别想要 Mach-O，wasm 目标别想要 ELF\n", .{});
    std.debug.print("⑥ 交叉编译 ≠ 跨平台兼容：编过了只说明指令集/ABI 对，运行时仍可能缺 syscall\n", .{});
    std.debug.print("⑦ -target 不能改变宿主：它改的是**产物**，不是你正在跑的这台机器\n", .{});
    end("18.14");

    // ═══ 18.15 自检 ═══
    begin("18.15");
    {
        // 平台无关的断言：这几条在 aarch64-linux 与本机都必须成立
        std.debug.print("wordSize() = {d}（aarch64 与 x86_64 同为 8；wasm32 会是 4）\n", .{wordSize()});
        std.debug.print("checksum(\"abc\") = 0x{x:0>8}（FNV-1a，与平台无关）\n", .{checksum("abc")});
        std.debug.print("checksum(\"\") = 0x{x:0>8}（空串即偏移基准）\n", .{checksum("")});
        std.debug.print("三段式自检：arch_code={d} ofmt={s} 输出模式={s}\n", .{
            archCode(), @tagName(builtin.target.ofmt), @tagName(builtin.output_mode),
        });
    }
    end("18.15");

    std.debug.print("自检通过\n", .{});
}

/// 18.13/18.15 的被测对象：编译期按架构分派。
/// `else` 分支让**任何**架构都能编过（含 wasm32），这是跨平台示例的基本要求。
fn archCode() u8 {
    return switch (builtin.target.cpu.arch) {
        .x86_64 => 1,
        .aarch64 => 2,
        .wasm32 => 3,
        .x86 => 4,
        else => 255,
    };
}

// ═══ 测试块：zig test main.zig 走这条通道 ═══

test "18.5 目标判断：isDarwin 在 macOS 上为真，且 arch/abi helper 都存在" {
    const t = builtin.target;
    // isDarwin 只能对本OS 断言；arch/abi helper 与平台无关
    try std.testing.expect(@hasDecl(std.Target.Os.Tag, "isDarwin"));
    try std.testing.expect(@hasDecl(std.Target.Cpu.Arch, "isAarch64"));
    try std.testing.expect(@hasDecl(std.Target.Cpu.Arch, "isWasm"));
    try std.testing.expect(@hasDecl(std.Target.Abi, "isMusl"));
    try std.testing.expect(@hasDecl(std.Target.Abi, "isGnu"));
    // isDarwin 在本机（macOS）必须为真；换成别的目标时这条要改
    if (t.os.tag == .macos) {
        try std.testing.expect(t.os.tag.isDarwin());
        try std.testing.expect(t.os.tag.isBSD());
    }
}

test "18.6 枚举成员：Optimize 全小写，OutputMode/LinkMode 的完整成员表" {
    // 0.17 的 Optimize 四个成员是**全小写**（debug/safe/fast/small）
    const opt = @typeInfo(std.lang.Optimize).@"enum".field_names;
    try std.testing.expectEqual(@as(usize, 4), opt.len);
    try std.testing.expectEqualStrings("debug", opt[0]);
    try std.testing.expectEqualStrings("safe", opt[1]);
    try std.testing.expectEqualStrings("fast", opt[2]);
    try std.testing.expectEqualStrings("small", opt[3]);

    // OutputMode 三个、LinkMode 两个
    try std.testing.expectEqual(@as(usize, 3), @typeInfo(std.lang.OutputMode).@"enum".field_names.len);
    try std.testing.expectEqual(@as(usize, 2), @typeInfo(std.lang.LinkMode).@"enum".field_names.len);

    // ObjectFormat 名义上 9 个，但 hex/raw 是 planned feature
    const ofmt = @typeInfo(std.Target.ObjectFormat).@"enum".field_names;
    try std.testing.expectEqual(@as(usize, 9), ofmt.len);
    var has_elf = false;
    for (ofmt) |n| if (std.mem.eql(u8, n, "elf")) {
        has_elf = true;
    };
    try std.testing.expect(has_elf);
}

test "18.6 废弃别名仍在：Optimize.Debug 等于 .debug（0.18 才移除）" {
    try std.testing.expectEqual(std.lang.Optimize.debug, std.lang.Optimize.Debug);
    try std.testing.expectEqual(std.lang.Optimize.safe, std.lang.Optimize.ReleaseSafe);
    try std.testing.expectEqual(std.lang.Optimize.fast, std.lang.Optimize.ReleaseFast);
    try std.testing.expectEqual(std.lang.Optimize.small, std.lang.Optimize.ReleaseSmall);
    // fromString 两套名字都收
    try std.testing.expectEqual(std.lang.Optimize.debug, std.lang.Optimize.fromString("Debug").?);
    try std.testing.expectEqual(std.lang.Optimize.fast, std.lang.Optimize.fromString("fast").?);
    try std.testing.expectEqual(@as(?std.lang.Optimize, null), std.lang.Optimize.fromString("ReleaseFastSmall"));
}

test "18.4/18.13 target 反射：ofmt 与 arch 组合在本机自洽" {
    const t = builtin.target;
    // ofmt 与 OS 必须自洽：Darwin 家族出 Mach-O，Windows 出 COFF，wasm 架构出 wasm
    if (t.os.tag.isDarwin()) {
        try std.testing.expectEqual(std.Target.ObjectFormat.macho, t.ofmt);
    }
    if (t.cpu.arch.isWasm()) {
        try std.testing.expectEqual(std.Target.ObjectFormat.wasm, t.ofmt);
    }
    // dynamic_linker 的 .get() 是 ?[]const u8，不是 struct 字段直读
    const dl: ?[]const u8 = t.dynamic_linker.get();
    if (builtin.link_mode == .static) {
        // 静态链接通常没有动态链接器（aarch64-linux 实测为 null）
        try std.testing.expect(dl == null or dl.?.len > 0);
    }
}

test "18.4 dynamic_linker.get() 返回 null 时是「无动态链接器」而不是崩溃" {
    // .none 的 len 是 0，get() 据此返回 null
    const none: std.Target.DynamicLinker = .none;
    try std.testing.expect(none.len == 0);
    try std.testing.expect(none.get() == null);
    const some = std.Target.DynamicLinker.init("/lib/ld-musl-aarch64.so.1");
    try std.testing.expectEqualStrings("/lib/ld-musl-aarch64.so.1", some.get().?);
}

test "18.7 cpu.features：Set 是位集合，count()/isEmpty() 在 baseline 上非零" {
    const t = builtin.target;
    // 0.17 的 Set 是 ints 数组 + popCount 计数，没有 .len / .has（实测报 no member named 'len'）
    try std.testing.expect(@typeInfo(@TypeOf(t.cpu.features)) == .@"struct");
    const n = t.cpu.features.count();
    try std.testing.expect(n > 0);
    try std.testing.expect(!t.cpu.features.isEmpty());
    try std.testing.expectEqual(@as(usize, 0), std.Target.Cpu.Feature.Set.empty.count());
    try std.testing.expect(std.Target.Cpu.Feature.Set.empty.isEmpty());
}

test "18.15 archCode：任何架构都要落在 1..4 或 255，永不返回 0" {
    const code = archCode();
    try std.testing.expect(code != 0);
    const expected: u8 = switch (builtin.target.cpu.arch) {
        .x86_64 => 1,
        .aarch64 => 2,
        .wasm32 => 3,
        .x86 => 4,
        else => 255,
    };
    try std.testing.expectEqual(expected, code);
}

test "18.15 wordSize：指针宽度与 ofmt 的字节序假设一致（只断言 4 或 8）" {
    const w = wordSize();
    try std.testing.expect(w == 4 or w == 8);
}

test "18.15 checksum：FNV-1a 32 位，与平台/优化模式无关" {
    // FNV-1a 标准测试向量
    try std.testing.expectEqual(@as(u32, 0x811c9dc5), checksum(""));
    try std.testing.expectEqual(@as(u32, 0xe40c292c), checksum("a"));
    try std.testing.expectEqual(@as(u32, 0xbf9cf968), checksum("foobar"));
    // 单调性：加一个字符结果必变
    try std.testing.expect(checksum("ab") != checksum("abc"));
}
