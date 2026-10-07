# 18 · 交叉编译与 zig cc ⭐

> 对应示例：`examples/18_cross/main.zig`（419 行）、`examples/18_cross/wasm_lib.zig`（约 200 行）、`examples/18_cross/hello.c`（约 40 行）
>
> 全部内容在 **Zig 0.17.0**（`/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/zig`）上实测。
> 宿主：macOS，Darwin 23.6.0 x86_64，`zig env` 报告 `target = "x86_64-macos.14.8.9...14.8.9-none"`。
>
> ⚠️ **本章示例不是普通示例，它是一条四通道验证路径。**
> `run-all.sh` 对 18 章走专门的 `test_cross_example`（第 54-69 行），八步缺一不可：
>
> ```text
> zig fmt --check .
> zig test main.zig
> zig build-exe main.zig -femit-bin=build/18_cross
> ./build/18_cross
> zig build-exe main.zig -target aarch64-linux -femit-bin=build/18_cross_aarch64-linux
> zig build-lib wasm_lib.zig -target wasm32-freestanding -femit-bin=build/18_cross.wasm
> zig cc hello.c -o build/18_cross_hello_c
> ./build/18_cross_hello_c
> ```
>
> 这带来一条**硬约束**：`main.zig` 必须能同时编成本机 exe **和** aarch64-linux ELF。
> 所以它里面**不碰任何平台相关的 std 设施**——不写文件、不起线程、不读时钟、不用 `std.posix`、
> 不用 `init.io`。只有编译期反射 + 纯逻辑。
>
> ---
>
> 本章有五条结论会**推翻 0.16 版本文档里的说法**，全部实测：
>
> 1. **`zig targets` 在 0.17 不再输出 JSON**，改成 **Zig 结构体字面量**语法
>    （`.{ .arch = .{"aarch64", ...}, ... }`）。任何 `jq` 管道都会当场失效。
> 2. **`-O` 的四个合法值变成全小写**：`debug` / `safe` / `fast` / `small`。
>    旧名（`Debug` / `ReleaseFast` / …）还能用，但源码里标注是"0.18.0 移除"的废弃别名。
>    所以 `@tagName(builtin.mode)` 打印出来是 **`debug`**，不是 `Debug`。
> 3. **命令行 `-target` 不支持结构体形式**。`zig build-exe x.zig -target '.cpu_arch = .aarch64'`
>    报 `error: unknown architecture: '.cpu_arch = .aarch64'`。结构体形式只在 `build.zig` 里用。
> 4. **`build-lib -target wasm32-freestanding -femit-bin=x.wasm` 产出的不是 wasm 模块，
>    是 ar 静态归档**。`file` 的输出是 `current ar archive`。要真模块必须加 `-dynamic -fPIC`。
> 5. **wasm32-freestanding 上连 `zig test` 都编译不过**——runner 依赖 `std.Io.Threaded`，
>    它需要 `posix.system.getrandom`。`--test-no-exec` 也救不了。
>    唯一能验证 wasm 目标上 test 块语法的路子是切到 `wasm32-wasi`。
>
> 另外三个「文档抄错就踩」的 API 事实：
> `os` 上**没有** `isLinux()`（只有 `isDarwin` / `isBSD`）；
> `builtin.cpu.features` 是位集合，**没有** `.len` 也没有 `.has`（用 `.count()` / `.isEmpty()`）；
> `target.dynamic_linker` 是 struct，要用 **`.get()`** 取 `?[]const u8`，没有 `.path` 字段。

---

## 18.1 为什么交叉编译是"默认能力"而不是附加功能

先把因果链摆出来，因为后面所有现象都是这条链的结果。

C 世界的交叉编译是**四件套玄学**：目标 sysroot（目标系统的头文件和库）、交叉 gcc、目标 libc、`pkg-config` 的 `.pc` 文件。少一件就在链接期报 `cannot find -lfoo`，而错误信息通常不告诉你缺的是哪一件。

Zig 的做法是把三件事折叠成一个：

1. **编译器自举**。stage2 后端用 Zig 写（`builtin.zig_backend` 实测是 `stage2_llvm`），
   所以发行包里没有"只支持宿主"的假设。
2. **libc 源码打进发行包**。musl / glibc / mingw-w64 / libunwind 的源码在 `lib/` 下，
   `-target` 一出，Zig 就**现场把它们编译成目标平台的 .o**，再和你的代码一起链接。
3. **目标描述是数据不是代码**。`zig targets` 列出全部合法目标（18.3），
   `builtin.target` 把它以结构体形式交给你的代码（18.4）。

所以"交叉"对它不是一条特殊代码路径，而是**默认路径多了一个参数**。

```zig
// examples/18_cross/main.zig 第 45-57 行
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
```

运行输出（`./build/18_cross`，本机 x86_64-macos）：

```text
==== 18.1 开始 ====
本文件正在被编译成：arch=x86_64 os=macos abi=none ofmt=macho
这些值全部是**编译期常量**：换 -target 就换一组，不需要运行时 if
Zig 自举（stage2 用 Zig 写）→ libc 源码打进发行包 → -target 一出，libc 现场编
所以交叉编译没有 sysroot / toolchain / pkg-config 三件套
编译器版本 builtin.zig_version = 0.17.0，后端 = stage2_llvm
==== 18.1 结束 ====
```

同一行代码用 `zig build-exe main.zig -target aarch64-linux` 编，**编译成功、无 stdout**
（产物是 ELF，本机跑不了，见 18.13）。这个"同一个文件、两个身份"就是本章全部内容的主题。

## 18.2 `-target` 的三段式字符串语法

`--help` 里的原文（`zig build-exe --help` 第 90 行，逐字抄）：

```text
  -target [name]            <arch><sub>-<os>-<abi> see the targets command
```

注意是 **`<arch><sub>-<os>-<abi>`**——四段，不是三段。`<sub>` 是子架构（`thumb`、`thumbeb` 这些
在 `zig targets` 的 `.arch` 里作为独立条目列出，但语法上仍算 arch 段的修饰）。abi 可省，
省了由 arch + os 推一个默认值。

```zig
// examples/18_cross/main.zig 第 59-71 行
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
```

运行输出：

```text
==== 18.2 开始 ====
-target 语法：<arch><sub>-<os>-<abi>，abi 可省（省了由 arch+os 推默认）
实测过的合法串：aarch64-linux / x86_64-linux-musl / x86_64-linux-gnu.2.31
  aarch64-linux          → abi 自动取 .musl（本机实测，产物是静态 ELF）
  x86_64-windows-gnu     → mingw ABI
  wasm32-freestanding    → 无 OS、无 libc、无入口
  x86_64-linux-gnu.2.31  → 三段之外还能挂第四段 glibc 版本
⚠️ 结构体形式（.cpu_arch=...）在 0.17 的 **命令行 -target 上不支持**（实测）
   写 -target '.cpu_arch = .aarch64' 报 error: unknown architecture: '.cpu_arch = .aarch64'
   报错时会把 zig targets 的全部合法 arch 列表打出来（61 个）
   结构体形式只在 build.zig 的 b.resolveTargetQuery 里用（16 章）
==== 18.2 结束 ====
```

### ⚠️ 报错文本实测（三种形式都被拒）

`std.Target.Query` 的字段名确实是 `cpu_arch` / `cpu_model` / `os_tag` / `abi`
（`lib/std/Target/Query.zig` 第 18-48 行），但**命令行解析器不吃这一套**。三种试法：

```bash
zig build-exe t.zig -target '.cpu_arch = .aarch64'
zig build-exe t.zig -target '{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .musl }'
zig build-exe t.zig -target '{cpu_arch=aarch64,os_tag=linux,abi=musl}'
```

三种全部报同一个错（尾部逐字抄，`info:` 行是被折叠的 61 个 arch 列表）：

```text
 native

error: unknown architecture: '.cpu_arch = .aarch64'
```

第四种（正确）就过了：

```text
$ zig build-exe t.zig -target aarch64-linux-musl -femit-bin=sf
$ file sf
sf: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, with debug_info, not stripped
```

**怎么区分自己写错了还是 arch 名不对**：报错会先打一份完整的合法 arch 清单
（`aarch64` / `aarch64_be` / `alpha` / … / `xcore` / `xtensa` / `xtensaeb`，最后一个是 `native`），
然后才说 `unknown architecture: '<你写的东西>'`。**把 `<你写的东西>` 那段原样贴出来看**——
如果它长得像 `.cpu_arch = ...`，那就是形式用错了；如果长得像 `amd64`，那是名字用错了
（Zig 叫 `x86_64`，不叫 `amd64`）。

### `-mcpu`：在 arch 之上再指定 CPU 型号

```bash
zig build-exe t.zig -target aarch64-linux -mcpu baseline      # ✅
zig build-exe t.zig -target aarch64-linux -mcpu generic       # ✅
zig build-exe t.zig -target aarch64-linux -mcpu cortex_a72    # ✅
zig build-exe t.zig -target aarch64-linux -mcpu bogus         # ❌
```

`bogus` 的报错：

```text
error: unknown CPU: 'bogus'
```

`-mcpu native` 在交叉时**会炸**，而且报得莫名其妙：

```text
error: sub-compilation of compiler_rt failed
```

（它要为本机 CPU 编译 `compiler_rt`，交叉语境下这一步失败。**交叉时永远别写 `native`**。）

合法型号清单在 `zig targets` 的 `.cpus.<arch>` 段里——`aarch64` 组实测 15 个
（`a64fx` / `a64fx_vector` / `apple_m1` / `baseline` / `cortex_a53` / `cortex_a57` / …）。

## 18.3 `zig targets`：0.17 输出的是 Zig 字面量，不是 JSON

这是本章最容易让人卡住的一条，因为**格式变了**。

```bash
$ zig targets | head -8
```

```text
.{
    .arch = .{
        "aarch64",
        "aarch64_be",
        "alpha",
        "amdgcn",
        "arc",
        "arceb",
        "arm",
```

0.16 输出的是 JSON（`{"arch": ["aarch64", ...]}`），0.17 换成了 **Zig 结构体字面量**。
所以 `zig targets | jq '.arch | length'` 这类管道在 0.17 上**全部失效**。

本机（0.17.0）实测的完整结构，逐段抄：

```text
$ zig targets | grep -n '^    \.'
    2:    .arch = .{
   65:    .os = .{
  115:    .abi = .{
  147:    .libc = .{
  257:    .glibc = .{
  316:    .cpus = .{
29530:    .cpu_features = .{
34921:    .native = .{
```

八段，总共 **34980 行**。各段条目数（本机实测）：

| 段 | 条目数 | 是什么 | 举例 |
|---|---|---|---|
| `.arch` | 61 | 架构名 | `aarch64` `x86_64` `wasm32` `riscv64` `thumb` `msp430` `avr` |
| `.os` | 48 | 操作系统 | `freestanding` `linux` `windows` `wasi` `emscripten` `uefi` `ps5` |
| `.abi` | 30 | ABI / libc 变体 | `none` `gnu` `musl` `msvc` `eabi` `android` `simulator` |
| `.libc` | 108 | **Zig 真能自举编译的 libc 组合** | `aarch64-linux-musl` `x86_64-linux-gnu` |
| `.glibc` | 59 | 可接受的 glibc 版本 | `2.0.0` … `2.44.0` |
| `.cpus` | 按 arch 分组 | CPU 型号 + 特性位表 | `aarch64` 组 15 个型号 |
| `.cpu_features` | 按 arch 分组 | 特性名清单 | `neon` `sve` `crc32` |
| `.native` | 1 | 本机解析结果 | `.triple` / `.cpu` / `.os` / `.abi` |

`.abi` 的 30 个值全文（实测，这是最容易抄错的一张表——`musl` 后面还有 7 个变体）：

```text
    .abi = .{
        "none",
        "gnu",
        "gnuabin32",
        "gnuabi64",
        "gnueabi",
        "gnueabihf",
        "gnuf32",
        "gnusf",
        "gnux32",
        "eabi",
        "eabihf",
        "abin32",
        "x32",
        "ilp32",
        "android",
        "androideabi",
        "musl",
        "muslabin32",
        "muslabi64",
        "musleabi",
        "musleabihf",
        "muslf32",
        "muslsf",
        "muslx32",
        "msvc",
        "itanium",
        "simulator",
        "ohos",
        "ohoseabi",
        "call0",
    },
```

`.native` 段实测（本机）：

```text
    .native = .{
        .triple = "x86_64-macos.14.8.9...14.8.9-none",
        .cpu = .{
            .arch = "x86_64",
            .name = "haswell",
            .features = .{
                "64bit", "aes", "allow_light_256_bit", "avx", "avx2", "bmi", "bmi2",
                "cmov", "crc32", "cx16", "cx8", "ermsb", "f16c",
                ... （实测 48 个）
            },
        },
        .os = "macos",
        .abi = "none",
    },
}
```

### ⚠️ 三段**不是**笛卡尔积

`61 × 48 × 30 = 87840` 种组合，但**绝大部分是非法的**。真正的合法集合是 `.libc` 那 108 项
——它是"Zig 能真的把 libc 编出来"的那些目标。

`wasm32-freestanding` **不在** `.libc` 里（它没有 libc 要编），但它**是**合法目标。
所以查合法性时不能只看 `.libc`，要三段各自对：

```text
arch  ∈ .arch 的 61 个
os    ∈ .os 的 48 个
abi   ∈ .abi 的 30 个
并且这个三元组要能被解析（`.libc` 是充分而不必要的参考）
```

```zig
// examples/18_cross/main.zig 第 73-87 行
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
```

运行输出：

```text
==== 18.3 开始 ====
zig targets 在 0.17 输出的是 .{ .arch = .{...}, .os = .{...}, ... } 这样的
**Zig 结构体字面量**，不是 JSON（0.16 是 JSON，这个格式在 0.17 变了）
八个顶层字段（本机实测条目数）：
  .arch          61 个：aarch64 / x86_64 / wasm32 / riscv64 / thumb / msp430 ...
  .os            48 个：freestanding / linux / windows / wasi / emscripten / uefi / ps5 ...
  .abi           30 个：none / gnu / musl / msvc / eabi / android / simulator ...
  .libc         108 个：Zig 能自举编译的 libc 组合（每项是一个 target 串）
  .glibc         59 个：能接受的 glibc 版本（2.0.0 ... 2.44.0）
  .cpus / .cpu_features  按 arch 分组的 CPU 型号与特性位（aarch64 组 15 个型号）
  .native        本机解析结果：triple / cpu / os / abi 四段
⚠️ 三段不是笛卡尔积：合法组合由 .libc 那 108 项给出（它是「真的能编」的那些）
   freestanding+wasm32 不在 .libc 里（没有 libc 要编）→ 只能靠 arch-os-abi 直写
==== 18.3 结束 ====
```

**想在脚本里解析它**：输出是合法的 Zig 表达式，但不是 JSON。
最省事的办法是别解析——`zig targets | grep` 出 `.libc` 段就够了，
或者直接靠"试编一次看报不报错"来验证（`zig build-obj p.zig -target <你的串> -femit-bin=/dev/null`）。

## 18.4 `builtin.target`：目标信息在编译期就是一份结构体

`@import("builtin")` 描述"正在编译的目标"。0.17 里**该用 `builtin.target`**（`std.Target`），
旧的 `builtin.cpu` / `builtin.os` / `builtin.abi` / `builtin.object_format`
都还留着但**标注了废弃**（生成的 `builtin.zig` 里逐字写着
`/// Deprecated; to be removed in 0.18.0. Use 'target.abi' instead.`）。

`std.Target` 只有 5 个字段（`lib/std/Target.zig` 第 8-14 行）：

```zig
// examples/18_cross/main.zig 第 89-107 行
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
```

运行输出：

```text
==== 18.4 开始 ====
builtin.target 是 std.Target（5 个字段，0.17 全部可用）：
  .cpu            类型 Target.Cpu
  .os             类型 Target.Os
  .abi            类型 Target.Abi
  .ofmt           类型 Target.ObjectFormat
  .dynamic_linker 类型 Target.DynamicLinker
cpu.arch=x86_64  cpu.model.name=haswell  features 数量=48
cpu.features.isEmpty() = false（aarch64 baseline 也带一批特性）
dynamic_linker.get() = /usr/lib/dyld
⚠️ dynamic_linker 是 struct（buffer[255]u8 + len:u8），要用 .get() 取 ?[]const u8
   直接写 .path 报 error: no field named 'path' in struct 'Target.DynamicLinker'
==== 18.4 结束 ====
```

### ⚠️ `dynamic_linker` 为什么不是字符串

`lib/std/Target.zig` 第 2405-2412 行：

```zig
pub const DynamicLinker = struct {
    /// Contains the memory used to store the dynamic linker path. This field
    /// should not be used directly. See `get` and `set`. This field exists so
    /// that this API requires no allocator.
    buffer: [255]u8,

    /// Used to construct the dynamic linker path. This field should not be used
    /// directly. See `get` and `set`.
    len: u8,

    pub const none: DynamicLinker = .{ .buffer = undefined, .len = 0 };
```

**设计意图是"这个 API 不需要分配器"**——路径直接内联在一个 255 字节的数组里。
代价是它不是 `[]const u8`（那需要分配器或哨兵），所以得配一个 `.get()` 方法。

写 `.path` 的报错（实测）：

```text
ta.zig:8:66: error: no field named 'path' in struct 'Target.DynamicLinker'
 std.debug.print("dynamic_linker.path={s}\n", .{t.dynamic_linker.path orelse "(null)"});
                                                                 ^~~~
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Target.zig:2405:27: note: struct declared here
pub const DynamicLinker = struct {
                          ^~~~~~~~~~
```

`.get()` 的实现（`lib/std/Target.zig` 第 2430 行起）按 `len == 0` 判断"无动态链接器"，
返回 `null`。所以 `none` 那个常量的语义是"静态链接，无动态链接器"：

```zig
// examples/18_cross/main.zig 第 374-380 行
test "18.4 dynamic_linker.get() 返回 null 时是「无动态链接器」而不是崩溃" {
    // .none 的 len 是 0，get() 据此返回 null
    const none: std.Target.DynamicLinker = .none;
    try std.testing.expect(none.len == 0);
    try std.testing.expect(none.get() == null);
    const some = std.Target.DynamicLinker.init("/lib/ld-musl-aarch64.so.1");
    try std.testing.expectEqualStrings("/lib/ld-musl-aarch64.so.1", some.get().?);
}
```

`zig test main.zig` 的对应输出（实测，完整 9 条）：

```text
1/9 main.test.18.5 目标判断：isDarwin 在 macOS 上为真，且 arch/abi helper 都存在...OK
2/9 main.test.18.6 枚举成员：Optimize 全小写，OutputMode/LinkMode 的完整成员表...OK
3/9 main.test.18.6 废弃别名仍在：Optimize.Debug 等于 .debug（0.18 才移除）...OK
4/9 main.test.18.4/18.13 target 反射：ofmt 与 arch 组合在本机自洽...OK
5/9 main.test.18.4 dynamic_linker.get() 返回 null 时是「无动态链接器」而不是崩溃...OK
6/9 main.test.18.7 cpu.features：Set 是位集合，count()/isEmpty() 在 baseline 上非零...OK
7/9 main.test.18.15 archCode：任何架构都要落在 1..4 或 255，永不返回 0...OK
8/9 main.test.18.15 wordSize：指针宽度与 ofmt 的字节序假设一致（只断言 4 或 8）...OK
9/9 main.test.18.15 checksum：FNV-1a 32 位，与平台/优化模式无关...OK
All 9 tests passed.
```

### ⚠️ `cpu.features` 是位集合，**没有** `.len` 也没有 `.has`

`lib/std/Target.zig` 第 1241-1262 行：

```zig
        pub const Set = struct {
            ints: [usize_count]usize,

            pub const needed_bit_count = 347;
            pub const byte_count = @divCeil(needed_bit_count, 8);
            pub const usize_count = (byte_count + (@sizeOf(usize) - 1)) / @sizeOf(usize);
            ...
            pub const empty: Set = .{ .ints = @splat(0) };

            pub fn isEmpty(set: Set) bool {
                return for (set.ints) |x| {
                    if (x != 0) break false;
                } else true;
            }

            pub fn count(set: Set) std.math.IntFittingRange(0, needed_bit_count) {
                var sum: usize = 0;
                for (set.ints) |x| sum += @popCount(x);
                return @intCast(sum);
            }
```

347 个特性位打包进 `ints: [6]usize`（64 位平台）。
所以 `.len`（数组长度）和 `.has(某特性)` 都不存在——按名字找某个特性得走
`Target.Cpu.Feature.Set` 的 arch 相关索引表，那是 `@import("builtin")` 之外的
`std.Target.aarch64` 之类模块。

写 `.len` 的报错（实测）：

```text
ta.zig:10:74: error: no field or member function named 'len' in 'Target.Cpu.Feature.Set'
 std.debug.print("cpu.features len={d} has(neon)={}\n", .{ t.cpu.features.len(), t.cpu.features.has(.neon) });
                                                           ^~~~~~~~~~~^~~~
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Target.zig:1241:25: note: struct declared here
        pub const Set = struct {
                ^~~~~~~~~
```

想在代码里按目标能力分派，可用的写法是 `.count()` / `.isEmpty()`，
或者**直接问 arch**：`t.cpu.arch.isAarch64()`。

## 18.5 目标判断：用 `is*` helper 而不是手写 switch

### ⚠️ `os` 上只有 `isDarwin` 和 `isBSD`

这是最容易踩的一个。`std.Target.Os.Tag` 的 helper 只有两个
（`lib/std/Target.zig` 第 79 行和第 94 行）：

```zig
        pub inline fn isDarwin(tag: Tag) bool {
            return switch (tag) {
                .macos, .ios, .tvos, .watchos, .visionos => true,
                else => false,
            };
        }

        pub inline fn isBSD(tag: Tag) bool { ... }
```

写 `t.os.tag.isLinux()` 的报错（实测）：

```text
ta.zig:6:33: error: no field or member function named 'isLinux' in 'Target.Os.Tag'
   t.os.tag.isDarwin(), t.os.tag.isLinux(), t.cpu.arch.isWasm(), t.os.tag.isWindows(), t.os.tag.isFreeBSD() });
                        ^~~~~~~~~
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Target.zig:18:21: note: enum declared here
    pub const Tag = enum {
                    ^~~~~~~~~
```

**`cpu.arch` 和 `abi` 上的 helper 就很多了**（`lib/std/Target.zig` 第 1506 行起）：

| 类型 | helper |
|---|---|
| `Target.Cpu.Arch` | `isX86` `isArm` `isThumb` `isAarch64` `isArc` `isHppa` `isWasm` `isLoongarch` `isRiscv` `isRiscv32` `isRiscv64` `isMicroblaze` `isMips` `isMips32` `isMips64` … |
| `Target.Abi` | `isGnu` `isMusl` `isOpenHarmony` `isAndroid` |

`Os.Tag` 想要"是不是 linux"就自己比：`t.os.tag == .linux`。

```zig
// examples/18_cross/main.zig 第 109-132 行
    // ═══ 18.5 目标判断：用 is* helper 而不是手写 switch ═══
    begin("18.5");
    {
        const t = builtin.target;
        std.debug.print("std.Target.Os.Tag 上**只有** isDarwin / isBSD 两个 helper（实测）：\n", .{});
        std.debug.print("  写 t.os.tag.isLinux() 报 error: no field or member function named 'isLinux'\n", .{});
        std.debug.print("isDarwin={} isBSD={}\n", .{ t.os.tag.isDarwin(), t.os.tag.isBSD() });
        std.debug.print("cpu.arch 上的 helper 很多：isX86={} isAarch64={} isWasm={} isArm={} isRiscv64={}\n", .{
            t.cpu.arch.isX86(), t.cpu.arch.isAarch64(), t.cpu.arch.isWasm(),
            t.cpu.arch.isArm(),   t.cpu.arch.isRiscv64(),
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
```

运行输出：

```text
==== 18.5 开始 ====
std.Target.Os.Tag 上**只有** isDarwin / isBSD 两个 helper（实测）：
  写 t.os.tag.isLinux() 报 error: no field or member function named 'isLinux'
isDarwin=true isBSD=true
cpu.arch 上的 helper 很多：isX86=true isAarch64=false isWasm=false isArm=false isRiscv64=false
abi 上的 helper：isMusl=false isGnu=false isAndroid=false isOpenHarmony=false
os.version_range 是**无 tag 的 union**（union{ }，不是 union(enum)）：
  直接 switch 会报 error: switch on union with no attached enum
  要先按 tag 分支再取字段：if (t.os.tag == .linux) 读 .linux.glibc
  本目标不是 linux（os=macos）→ .version_range 走 .semver 分支，跳过
==== 18.5 结束 ====
```

### ⚠️ `os.version_range` 是**无 tag 的 union**

`lib/std/Target.zig` 第 388-395 行：

```zig
    pub const VersionRange = union {
        none: void,
        semver: std.SemanticVersion.Range,
        hurd: HurdVersionRange,
        linux: LinuxVersionRange,
        windows: WindowsVersion.Range,
```

**没有 `enum` 标签**（不是 `union(enum)`），所以不能直接 `switch`。
报错（实测）：

```text
ta.zig:7:14: error: switch on union with no attached enum
 switch (t.os.tag == .linux) { else => {}, .linux => |l| ... }
         ~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^~~~~~
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Target.zig:388:30: note: consider 'union(enum)' here
    pub const VersionRange = union {
                             ^~~~~~~~~~
```

`if (x) |r|` 也不行（它不是 optional）：

```text
ta.zig:6:23: error: expected optional type, found 'Target.Os.VersionRange'
 if (t.os.version_range) |r| std.debug.print("  os min={any}\n", .{r.min});
     ~~~~^~~~~~~~~~~~~~
```

**正确写法是先按 tag 分支**（这样编译器知道当前激活的是哪个字段）：

```zig
if (t.os.tag == .linux) {
    const g = t.os.version_range.linux.glibc;   // SemanticVersion，例：2.31.0
}
```

这一节对应的测试（`examples/18_cross/main.zig` 第 308-321 行）在 macOS 上**不能**直接断言
`isDarwin == true`，因为换成 aarch64-linux 编译时它就是 false。所以测试里加了守卫：

```zig
// examples/18_cross/main.zig 第 308-321 行
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
```

**这是"一份代码编多个目标"这个示例的核心技巧**：平台相关的断言必须包在
`if (t.os.tag == .xxx)` 里，或者干脆只断言 `@hasDecl`（声明存在性是目标无关的）。

## 18.6 产物类型矩阵：exe / static lib / dynamic lib / obj / wasm

三个顶层开关决定产物形态。0.17 的枚举全在 `std.lang` 下，**名字全小写**：

| `builtin` 字段 | 类型 | 成员 | 含义 |
|---|---|---|---|
| `builtin.output_mode` | `std.lang.OutputMode` | `Exe` `Lib` `Obj` | 产物是程序 / 库 / 目标文件 |
| `builtin.link_mode` | `std.lang.LinkMode` | `static` `dynamic` | 静态链接 / 动态链接 |
| `builtin.mode` | `std.lang.Optimize` | `debug` `safe` `fast` `small` | 优化级别（**0.17 全小写**） |

```zig
// examples/18_cross/main.zig 第 134-156 行
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
```

运行输出：

```text
==== 18.6 开始 ====
三个顶层开关决定产物形态（0.17 的 std.lang 全小写枚举）：
  builtin.output_mode = Exe   类型 lang.OutputMode
  builtin.link_mode   = dynamic   类型 lang.LinkMode
  builtin.mode        = debug   类型 lang.Optimize
OutputMode 三值：Exe / Lib / Obj；LinkMode 两值：static / dynamic
⚠️ builtin.mode 打印出来是 **debug**（全小写），不是 0.15/0.16 的 Debug
   同理 -O 的四个合法值在 0.17 是 debug / safe / fast / small
   -O Debug 仍能过（fromString 保留了旧名作废弃别名），但那是过渡期兼容
   -O ReleaseFastSmall 报 error: unrecognized optimization mode
⚠️ 命令名字面上没有"wasm"这一项：wasm 是 ofmt（ObjectFormat），不是 OutputMode
   本目标 ofmt=macho；ObjectFormat 共 9 个成员（elf/coff/macho/wasm/plan9/spirv/c/hex/raw）
⚠️ ObjectFormat 没有 .hex/.raw（help 里标 planned feature）→ 实际可用 7 个
本进程 single_threaded=false，is_test=false，unwind_tables=async
==== 18.6 结束 ====
```

### ⚠️ `Optimize` 的枚举成员在 0.17 **全小写**了

`lib/std/lang.zig` 第 113-140 行：

```zig
pub const Optimize = enum {
    /// Safety checks enabled. Optimize for bug detection, accurate debug info,
    /// and compilation speed (in that order).
    debug,
    /// Safety checks enabled. Optimize for runtime performance.
    safe,
    /// Safety checks disabled. Optimize for runtime performance.
    fast,
    /// Safety checks disabled. Optimize for machine code size, then runtime performance.
    small,

    /// Deprecated, to be removed after 0.18.0
    pub const Debug: @This() = .debug;
    /// Deprecated, to be removed after 0.18.0
    pub const ReleaseSafe: @This() = .safe;
    /// Deprecated, to be removed after 0.18.0
    pub const ReleaseFast: @This() = .fast;
    /// Deprecated, to be removed after 0.18.0
    pub const ReleaseSmall: @This() = .small;
    /// Deprecated, to be removed after 0.18.0
    pub fn fromString(s: []const u8) ?@This() {
        return std.StaticStringMap(@This()).initComptime(&.{
            .{ "Debug", .debug },
            .{ "ReleaseSafe", .safe },
            .{ "ReleaseFast", .fast },
            .{ "ReleaseSmall", .small },
            .{ "debug", .debug },
            .{ "safe", .safe },
            ...
```

**四个成员现在是对称的全小写**（这修正了本教程早期记的"第一个小写、后三个驼峰"的说法——
那是 0.16 的状态，0.17 已经统一了）。旧名保留为**废弃别名**，注释明说 0.18.0 移除。

`-O` 命令行实测（八个值逐个试）：

| `-O` 的值 | 结果 |
|---|---|
| `debug` / `safe` / `fast` / `small` | ✅ 新的规范名 |
| `Debug` / `ReleaseSafe` / `ReleaseFast` / `ReleaseSmall` | ✅ 走 `fromString` 的废弃别名 |
| `ReleaseFastSmall` | ❌ `error: unrecognized optimization mode: "ReleaseFastSmall"` |

而 `zig build-exe --help` 里的 `Per-Module Compile Options` 段现在直接列新的：

```text
  -O [mode]                 Choose what to optimize for
    debug (default)         Prioritize bug detection, accurate debug info, compilation speed
    fast                    Prioritize runtime performance. Safety checks off.
    safe                    Enable both safety checks and machine code optimizations
    small                   Prioritize small binary size. Safety checks off.
```

`OutputMode` 和 `LinkMode` **没改**（还是 `Exe` / `static` 那种大写 / 小写混合）：

```text
  builtin.output_mode = Exe   类型 lang.OutputMode
  builtin.link_mode   = dynamic   类型 lang.LinkMode
```

枚举成员表由 `zig test main.zig` 的第 2 条测试逐个断言（`examples/18_cross/main.zig` 第 323-344 行）：

```zig
// examples/18_cross/main.zig 第 323-344 行
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
```

### ⚠️ wasm **不是** OutputMode，是 ObjectFormat

命令行的三个"产物形态"命令是 `build-exe` / `build-lib` / `build-obj`，
对应 `OutputMode` 的 `Exe` / `Lib` / `Obj`。**wasm 不在里面**——
wasm 是 `ofmt`（`ObjectFormat`）的九个成员之一，和 elf / coff / macho / plan9 / spirv / c 平级。

`zig build-exe --help` 的 `Object Formats` 段（逐字抄）：

```text
                         .so    ELF shared object (dynamic link)
                        .dll    Windows Dynamic Link Library
                      .dylib    Mach-O (macOS) dynamic library
                           .s    Target-specific assembly source code
```

（这一段是 `-femit-bin` 的**后缀推断表**。而 `ofmt` 本身的成员在同文件第 96-106 行：
`elf` / `c` / `wasm` / `coff` / `macho` / `spirv` / `plan9` / `hex (planned feature)` / `raw (planned feature)`。）

所以"生成一个 wasm 模块"是**两个维度**的事：`build-lib`（或 `build-obj`）决定形态，
`-target wasm32-freestanding` 决定 ofmt。实测矩阵（全部在本机跑通）：

| 命令 | 产物 | `file` 的输出（实测逐字） |
|---|---|---|
| `zig build-exe lib.zig -femit-bin=a.out` | 可执行 | `Mach-O 64-bit executable x86_64` |
| `zig build-exe lib.zig -target aarch64-linux -femit-bin=a64` | 可执行 | `ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, with debug_info, not stripped` |
| `zig build-exe lib.zig -target x86_64-linux-musl -femit-bin=m` | 可执行 | `ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, with debug_info, not stripped` |
| `zig build-lib lib.zig -femit-bin=l.a` | 静态归档 | `current ar archive` |
| `zig build-lib lib.zig -dynamic -femit-bin=l.so` | 动态库 | `Mach-O 64-bit dynamically linked shared library x86_64` |
| `zig build-lib lib.zig -dynamic -target aarch64-linux -femit-bin=la.so` | 动态库 | `ELF 64-bit LSB shared object, ARM aarch64, version 1 (SYSV), static-pie linked, with debug_info, not stripped` |
| `zig build-obj lib.zig -femit-bin=l.o` | 目标文件 | `Mach-O 64-bit object x86_64` |
| `zig build-obj lib.zig -target aarch64-linux -femit-bin=la.o` | 目标文件 | `ELF 64-bit LSB relocatable, ARM aarch64, version 1 (SYSV), with debug_info, not stripped` |
| `zig build-obj lib.zig -target wasm32-freestanding -femit-bin=l.wasm` | wasm 模块 | `WebAssembly (wasm) binary module version 0x1 (MVP)` |
| `zig build-lib lib.zig -target wasm32-freestanding -femit-bin=l.wasm` | ⚠️ **ar 归档** | `current ar archive` |

⚠️ **最后一行是本章最容易被忽略的坑**，18.7 展开。

⚠️ 另外 `aarch64-linux` 实测默认 `link_mode = .static`（生成的 `builtin.zig` 里写着
`pub const link_mode: std.lang.LinkMode = .static;`），产物是 `statically linked`。
本机 macOS 默认是 `dynamic`。**同一个 `-target` 语法在两边的默认链接模式不同**——
写"部署到 Linux 服务器"的脚本时想静态链接，要显式加 `-static` 或用 `x86_64-linux-musl`（它总是静态）。

## 18.7 wasm32-freestanding：没有 OS、没有入口、没有 std I/O

freestanding（裸机）意味着：**没有操作系统**。所以没有进程、没有文件系统、没有时钟、
没有线程、没有 `_start`。它只有语言核心 + 可计算的纯逻辑。

### ⚠️ `build-exe` 编到 freestanding 会炸

```bash
$ zig build-exe t.zig -target wasm32-freestanding -femit-bin=out
```

```text
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:2061:45: error: struct 'posix.system__struct_121' has no member named 'getrandom'
const use_dev_urandom = @TypeOf(posix.system.getrandom) == void and native_os == .linux;
                                ~~~~~~~~~~~~^~~~~~~~~~
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/posix.zig:57:13: note: struct declared here
    else => struct {
            ^~~~~~
referenced by:
    RandomFile: /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:376:17
    Io.Threaded: /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:81:14
    4 reference(s) hidden; use '-freference-trace=6' to see more references
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/posix.zig:90:27: error: struct 'posix.system__struct_121' has no member named 'IOV_MAX'
pub const IOV_MAX = system.IOV_MAX;
                    ~~~~~~^~~~~~~~
```

**为什么**：`std.process.Init` 里有 `io`，程序入口 `std.start` 要构造 `Io.Threaded`，
它要一个随机源（`RandomFile`），freestanding 的 `posix.system` 是个空 struct，什么都没有。

⚠️ **注意 `posix.system__struct_121` 里的序号每次编译都不一样**（本机实测见过 2 / 4 / 121 / 125），
因为它是编译器内部生成的匿名 struct 编号。**抄错误文本时不要抄序号**，只抄成员名。

**所以 wasm 场景必须用 `build-lib`**（库形态天生无入口），这是本章第一条硬规则。

### ⚠️⚠️ 那个 `.wasm` 文件其实是 ar 归档

这是本章最反直觉的一条。`run-all.sh` 的第三条 wasm 通道是：

```bash
zig build-lib wasm_lib.zig -target wasm32-freestanding -femit-bin=build/18_cross.wasm
```

命令成功、文件名是 `.wasm`，但产物到底是什么？

```bash
$ file build/18_cross.wasm
build/18_cross.wasm: current ar archive
```

**是 ar 静态归档，不是 wasm 模块。** 里面装的是那个 wasm 目标文件：

```bash
$ zig ar t build/18_cross.wasm
/Users/xulun/.cache/zig/tmp/492a0fb4b7f889ce/wasm_lib_zcu.o

$ nm build/18_cross.wasm | grep ' T '
00000190 T add
00000001 T fib
```

**原因**：`build-lib` 不带 `-dynamic` 时 `link_mode = static`，
所以走的是"打一个静态库"这条路径——`.wasm` 只是 `-femit-bin` 后面跟的**文件名**，
扩展名不决定产物类型（实测：`zig build-lib lib.zig -femit-bin=libstatic.a` 也是 `current ar archive`，
而 `zig build-lib lib.zig -dynamic -femit-bin=libdyn2.so` 是 `Mach-O 64-bit dynamically linked shared library x86_64`）。

**要真模块**，加 `-dynamic -fPIC`。实测两条路：

```bash
$ zig build-lib lib.zig -target wasm32-freestanding -dynamic -femit-bin=w.wasm
error: wasm-ld:
error: wasm-ld: .../w_zcu.o: relocation R_WASM_MEMORY_ADDR_SLEB cannot be used against symbol `__anon_2156`; recompile with -fPIC
w.wasm: cannot open `w.wasm' (No such file or directory)

$ zig build-lib lib.zig -target wasm32-freestanding -dynamic -OReleaseFast -femit-bin=w.wasm
warning(link): unexpected LLD stderr:
wasm-ld: warning: creating shared libraries, with -shared, is not yet stable
w.wasm: WebAssembly (wasm) binary module version 0x1 (MVP)

$ zig build-lib lib.zig -target wasm32-freestanding -dynamic -fPIC -femit-bin=w.wasm
warning(link): unexpected LLD stderr:
wasm-ld: warning: creating shared libraries, with -shared, is not yet stable
w.wasm: WebAssembly (wasm) binary module version 0x1 (MVP)
```

**Debug 模式下必须加 `-fPIC`**（否则那个 `R_WASM_MEMORY_ADDR_SLEB` 链接错误）；
`-OReleaseFast` 也能绕过（因为 Release 模式下那些匿名常量被优化掉了）。
wasm-ld 自己还会警告 `creating shared libraries, with -shared, is not yet stable`——
**wasm 的动态库支持在 0.17 还不算稳定**，这是官方警告。

### freestanding 里**能用**的 std（全部实测编译通过）

我用 `export fn` 强制语义分析逐个试（`build-lib` 只编译被**引用**到的声明，
写 `_ = std.X` 不会触发分析，所以必须真的调用）：

| 设施 | 状态 | 备注 |
|---|---|---|
| `std.mem.copyForwards` / `std.mem.sort` / `std.mem.eql` | ✅ | 纯内存操作 |
| `std.fmt.comptimePrint` / `bufPrint` / `allocPrint` | ✅ | 写调用方的缓冲 |
| `std.heap.page_allocator` / `FixedBufferAllocator` | ✅ | 线性内存里的分配器 |
| `std.ArrayList` | ✅ | 配 page_allocator |
| `std.mem.Allocator` | ✅ | 接口本身 |
| `std.json.parseFromSlice` | ✅ | 纯解析 |
| `std.hash.Crc32` | ✅ | 不碰系统熵 |
| `std.Io.Writer.fixed` | ✅ | **只写内存缓冲，不碰 fd** |
| `std.Random.DefaultPrng` | ✅ | 自带算法，不读 `/dev/urandom` |

`std.Io.Writer.fixed` 能用这点很重要：它让"格式化"在 freestanding 上完全可用，
而 `std.debug.print` 不行（18.8 会讲这个区别）。

### freestanding 里**不能**用的（实测报错原文）

| 写法 | 报错（逐字，`posix.system` 那个除外） |
|---|---|
| `std.fs.cwd()` | `error: root source file struct 'fs' has no member named 'cwd'` |
| `std.fs.File` | `error: root source file struct 'fs' has no member named 'File'` |
| `std.time.Instant` | `error: root source file struct 'time' has no member named 'Instant'` |
| `std.posix.getpid` | `error: root source file struct 'posix' has no member named 'getpid'` |
| `std.process.argsAlloc` | `error: root source file struct 'process' has no member named 'argsAlloc'` |
| `std.Thread.spawn` | `error: Cannot spawn thread when building in single-threaded mode` |
| `std.math.abs` | `error: root source file struct 'math' has no member named 'abs'` |
| `std.debug.print` | 拖进 `Io.Threaded` → `posix.system has no member named 'getrandom'` |

注意前五行的报错措辞是 `root source file struct 'fs' has no member named 'cwd'`——
**这些 struct 在 freestanding 目标上整个不存在**（不是"存在但没有这个成员"）。
这和本机上的报错措辞不同：本机上写 `std.fs.cwd` 是能过的（`Io.Dir.cwd()` 之类才是 0.17 的形状），
差别在于 freestanding 的 `std` 根本不导出 `fs` / `posix` / `process` 这些名字。

`std.Thread.spawn` 那条**措辞完全不同**——它不是"不存在"，而是"存在但被编译模式禁止"：

```text
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Thread.zig:346:9: error: Cannot spawn thread when building in single-threaded mode
p.zig:4:7: error: expected type 'void', found 'error{LockedMemoryLimitExceeded,OutOfMemory,SystemResources,ThreadQuotaExceeded,Unexpected}'
```

第二条是连带的：我写的 `export fn entry() void` 里用了 `try`，
而 `Thread.spawn` 返回错误联合，`void` 接不住。**这两条一起出现时先看第一条。**

```zig
// examples/18_cross/main.zig 第 158-182 行
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
```

运行输出：

```text
==== 18.7 开始 ====
freestanding = 裸机：没有 OS、没有 libc、没有 _start、没有 std 的 I/O
wasm_lib.zig 是本示例的 freestanding 侧：只有 export fn，没有 main
构建方式：zig build-lib wasm_lib.zig -target wasm32-freestanding
⚠️ 想用 build-exe 编到 freestanding 会在 lib/std/Io/Threaded.zig 炸：
   error: struct 'posix.system__struct_N' has no member named 'getrandom'
   （本机实测，struct 序号每次编译不同，所以只抄成员名不抄序号）
⚠️ 那个 .wasm 文件其实是 **ar 静态归档**，不是 wasm 模块（实测 file 的输出）
   原因：build-lib 不带 -dynamic 时 link_mode=static → 产物是 current ar archive
   想要真模块要加 -dynamic -fPIC（Debug 下 -fPIC 或 -OReleaseFast 均可）
freestanding 里**能用**的 std（全部实测编译通过）：
  纯逻辑：std.mem.*（copyForwards/sort/eql）、std.fmt.{comptimePrint,bufPrint,allocPrint}
  内存：std.heap.page_allocator / FixedBufferAllocator / std.ArrayList / std.mem.Allocator
  编解码：std.json.parseFromSlice、std.hash.Crc32、std.Io.Writer.fixed（写内存缓冲）
  随机：std.Random.DefaultPrng（自带算法，不碰系统熵）
freestanding 里**不能**用的（实测报错，措辞见文档 18.7）：
  std.fs.cwd → root source file struct 'fs' has no member named 'cwd'
  std.fs.File → root source file struct 'fs' has no member named 'File'
  std.time.Instant → root source file struct 'time' has no member named 'Instant'
  std.posix.getpid → root source file struct 'posix' has no member named 'getpid'
  std.process.argsAlloc → root source file struct 'process' has no member named 'argsAlloc'
  std.Thread.spawn → error: Cannot spawn thread when building in single-threaded mode
  std.debug.print → 拖进 Io.Threaded，报 posix.system has no member named 'getrandom'
==== 18.7 结束 ====
```

## 18.8 wasm 里想要输出：自己写导出，不用 std

### ⚠️ `export fn` 不能收切片

这是写 wasm 导出函数的第一条 ABI 规则。写：

```zig
export fn checksum(bytes: []const u8) u32 { ... }
```

编译报错（实测）：

```text
examples/18_cross/wasm_lib.zig:56:20: error: parameter of type '[]const u8' not allowed in function with calling convention 'x86_64_sysv'
export fn checksum(bytes: []const u8) u32 {
                   ^~~~~~~~~~~~~~~~~
examples/18_cross/wasm_lib.zig:56:20: note: slices have no guaranteed in-memory representation
```

⚠️ 报错里的 calling convention 是 **`x86_64_sysv`**（本机架构），不是 wasm——
因为 `zig test wasm_lib.zig` 是在本机目标下检查的（wasm 侧 `build-lib` 时这条不报，
但 ABI 一样不成立）。这个措辞有点误导人，看第 2 行 `note:` 才对。

**正确形态是"裸指针 + 长度"两个参数**：

```zig
// examples/18_cross/wasm_lib.zig 第 63-77 行
/// ⚠️ 参数是 `[*]const u8` + `usize` **两个参数**，不是 `[]const u8` 切片。
/// 原因（实测报错）：`export fn` 走的是目标 ABI，切片没有保证的内存布局——
///
///     error: parameter of type '[]const u8' not allowed in function with
///            calling convention 'x86_64_sysv'
///     note: slices have no guaranteed in-memory representation
///
///    这是 wasm 侧写导出函数的一条通用规则：ABI 边界上只能用标量和裸指针。
export fn checksum(ptr: [*]const u8, len: usize) u32 {
    var acc: u32 = 0x811c9dc5;
    var i: usize = 0;
    while (i < len) : (i += 1) {
        acc ^= ptr[i];
        acc *%= 0x01000193;
    }
    return acc;
}
```

Zig 侧调用时，切片要先取 `.ptr` 和 `.len`（`examples/18_cross/wasm_lib.zig` 第 142-149 行）：

```zig
test "checksum：FNV-1a 32 位标准测试向量（与平台无关）" {
    try std.testing.expectEqual(@as(u32, 0x811c9dc5), checksum("".ptr, 0));
    try std.testing.expectEqual(@as(u32, 0xe40c292c), checksum("a".ptr, 1));
    try std.testing.expectEqual(@as(u32, 0xbf9cf968), checksum("foobar".ptr, 6));
    // 切片要先取 .ptr 和 .len —— 因为导出函数的签名是 ABI 形态
    const s = "hello";
    try std.testing.expectEqual(checksum(s.ptr, s.len), checksum(s.ptr, s.len));
}
```

### ⚠️⚠️ `export var`（可变全局）在 `-fPIC` 产物里宿主读不到活值

这是本节最反直觉的一条。直觉上"导出一个可变全局，宿主读它"应该成立。**实测不成立。**

最小复现：

```zig
export var g: i32 = 7;
export fn bump() i32 { g += 1; return g; }
```

编成 `-dynamic -fPIC` 之后在 node 里实测：

```text
g.value 初始 = 0 (源码初值是 7)
bump() = 8
bump() = 9
g.value = 0
```

**宿主看到的 `g.value` 永远是 0**，而 `bump()` 返回的 8、9 是对的（说明模块内部的 `g` 确实在变）。

**原因**：PIC 模式下模块的数据段放在**宿主提供的 linear memory** 里，
而导出的 global 是 wasm 引擎在实例化时**快照**出来的一个独立 JS 对象，
它不跟着模块内存的写更新。

所以规则是：**跨 wasm 边界只用返回值**。`export var` 只能用于模块**内部**中转
（`wasm_lib.zig` 里的 `last` 就是这个用途——给 `fmtWidth` 和 `sum3` 之间传值）。

```zig
// examples/18_cross/wasm_lib.zig 第 44-52 行
/// 「跑一次取一批结果」的形态：结果写进一个导出的可变全局。
///
/// ⚠️ **实测坑**：在 `-dynamic -fPIC` 产出的 wasm 里，宿主读这个 global 拿到的是
///    **加载时的快照**（永远是初值0），不是模块内部那个活的值。
///    最小复现（`export var g: i32 = 7; export fn bump() i32 { g += 1; return g; }`）：
///    node 里 `g.value` 初始 0、`bump()` 返回 8、再 `bump()` 返回 9、`g.value` 仍是 0。
///    原因：PIC 模式下模块数据在宿主提供的 linear memory 里，
///    而导出的 global 是 wasm 引擎在实例化时快照出来的独立对象。
///    ⇒ **跨边界只用返回值**。这个 `last` 只是给"同一模块内别的导出函数"中转用的。
export var last: i32 = 0;
```

### `wasm_lib.zig` 的完整导出面

```zig
// examples/18_cross/wasm_lib.zig 第 1-24 行
//! 18 交叉编译：wasm32-freestanding 侧的模块。
//!
//! freestanding = 裸机目标：没有 OS、没有 libc、没有 `_start`、没有 std 的 I/O。
//! 所以这个文件：
//!   · **没有 `main`**（没有 OS 可言，就没有程序入口的概念）
//!   · **没有 `std.debug.print`**（它会拖进 std.Io.Threaded → 报 posix.system has no member 'getrandom'）
//!   · 只有 `export fn` / `export var` —— 宿主（wasmtime / node / 浏览器）按名字调
//!
//! 四条验证通道里它对应第三条：
//!   zig build-lib wasm_lib.zig -target wasm32-freestanding -femit-bin=18_cross.wasm
//!
//! ⚠️ **产物其实不是 wasm 模块**：不带 `-dynamic` 时 `link_mode=static`，
//!    `file` 看到的是 `current ar archive`（ar 归档里装着那个 wasm 目标文件）。
//!    想要能被宿主直接实例化的真模块，见文档 18.8 的 `-dynamic -fPIC` 路线。
//!
//! ⚠️ **本文件的 test 块不参与 `zig test main.zig`**（那是另一个编译单元）。
//!    而且在 freestanding 上**连编译测试二进制都做不到**——runner 要 std.Io.Threaded。
//!    真正能跑的语法验证是切到 wasi（实测通过）：
//!      zig test wasm_lib.zig -target wasm32-wasi --test-no-exec -femit-bin=out.wasm
```

六个导出（`add` / `fib` / `sum3` / `checksum` / `fmtWidth` / `sortAndSpan`）
加一个 `last` 全局。**真在 node 里跑一遍**（`-dynamic -fPIC -OReleaseFast` 编出来的那份）：

```text
$ node -e '...实例化并调用...'
导入模块: env
导出: sortAndSpan:function, fmtWidth:function, checksum:function, sum3:function, last:global, fib:function, add:function, __wasm_apply_data_relocs:function
add(3,4) = 7
fib(10) = 55
fmtWidth(0x1) = 6
```

需要宿主提供的 `env` 导入（实测 `WebAssembly.Module.imports` 的输出）：

```text
[{"module":"env","name":"memory","kind":"memory"},
 {"module":"env","name":"__indirect_function_table","kind":"table"},
 {"module":"env","name":"__stack_pointer","kind":"global"},
 {"module":"env","name":"__memory_base","kind":"global"},
 {"module":"env","name":"__table_base","kind":"global"}]
```

⚠️ **这是 `-fPIC`（位置无关）模式的代价**——它假设宿主会分配内存并告诉你基址。
如果不想要这些导入，就用 wasmtime 之类的运行时（它会替你准备），
或者用 `wasm32-wasi` 目标（自带 syscall 抽象，见 18.9）。

### `std.debug.print` 在 freestanding 上不行，但 `std.Io.Writer.fixed` 行

这个区别值得单独说，因为它决定你在 wasm 里能不能"打印"：

- `std.debug.print` → 走 `std.Io.Threaded` → 要真实 fd + 随机源 → freestanding 直接编译失败
- `std.Io.Writer.fixed(&buf)` → 只往你给的内存缓冲写 → **freestanding 完全可用**

所以 `wasm_lib.zig` 里的 `fmtWidth` 就是这个技巧的演示：格式化照做，结果留在内存里：

```zig
// examples/18_cross/wasm_lib.zig 第 79-94 行
/// 演示 `std.Io.Writer.fixed` 在 freestanding 上可用：它只写调用方给的内存缓冲，
/// 不碰任何 fd。返回写进去的**字节数**。
///
/// 格式串是 `"0x{x:0>4}"`——注意 `0x` 是**字面量**不是格式符，
/// 而 `{x:0>4}` 至少 4 位十六进制。所以 `fmtWidth(0x1)` 写出 `"0x0001"`，宽度是 6。
export fn fmtWidth(x: u32) usize {
    var buf: [16]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    w.print("0x{x:0>4}", .{x}) catch return 0;
    last = @intCast(w.buffered().len);
    return w.buffered().len;
}
```

⚠️ 我第一次写这个测试时断言 `fmtWidth(0x1) == 4`，**失败了**：

```text
5/7 wasm_lib.test.fmtWidth：std.Io.Writer.fixed 在 freestanding 可用（只写内存不碰 fd）...expected 4, found 6
FAIL (TestExpectedEqual)
```

因为 `0x` 是字面量（2 字节）+ `{x:0>4}` 至少 4 位 = 6 字节。
**教训**：带字面前缀的格式串，宽度要**连字面量一起算**。

```zig
// examples/18_cross/main.zig 第 184-196 行
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
```

运行输出：

```text
==== 18.8 开始 ====
wasm32-freestanding 没有 stdout 可写，宿主只能看到**导出的函数返回值**
wasm_lib.zig 的做法：export fn 直接给结果，宿主按导出名调
  export fn add(a: i32, b: i32) i32 → 宿主最省事：i.exports.add(3,4)
⚠️ export var（可变全局）**在 -fPIC 产物里宿主读不到活值**（实测）：
   宿主拿到的永远是实例化时的快照。最小复现：export var g=7 + fn bump() 递增 g
   node 实测：g.value=0 → bump()=8 → bump()=9 → g.value 仍是 0
   原因：PIC 模式下数据在宿主提供的 linear memory 里，导出 global 是引擎快照
   ⇒ 跨 wasm 边界只用返回值；export var 只用于模块**内部**中转
  真的想往控制台写 → 得自己写 WASI fd_write，或改用 wasm32-wasi 目标（见 18.9）
==== 18.8 结束 ====
```

## 18.9 `wasm32-wasi`：带 OS 抽象的 wasm

`wasm32-wasi` 比 freestanding 多一整层 POSIX-ish 抽象：fd、路径、时钟、随机数、进程参数。
所以 `std.fs` / `std.time` / `std.process` 在 wasi 上**大部分可用**。

产物的性质也不同——实测 `-dynamic` 编出来的 wasi 模块的导入：

```text
导入模块: env,wasi_snapshot_preview1
导出: add,__wasm_apply_data_relocs
```

多了 `wasi_snapshot_preview1`（这才是真正有用的那个），少了 freestanding 那套纯 PIC 基址导入。
wasi 的产物是**自足模块**——宿主（wasmtime / node 的 WASI 支持）能直接跑起来。

### ⚠️ wasm 目标上 `zig test` 编不过——runner 绕不开 std.Io.Threaded

这是本节最实际的一条。实测四种试法：

| 命令 | 结果 |
|---|---|
| `zig test wt.zig -target wasm32-freestanding` | ❌ `posix.system has no member named 'getrandom'` |
| `zig test wt.zig -target wasm32-freestanding --test-no-exec -femit-bin=wt1` | ❌ 同一个错（`--test-no-exec` 救不了） |
| `zig test wt.zig -target wasm32-freestanding -fsingle-threaded` | ❌ 同一个错 |
| `zig test wt.zig -target wasm32-wasi --test-no-exec -femit-bin=wt5` | ✅ `WebAssembly (wasm) binary module version 0x1 (MVP)` |

**唯一可行的路子是切到 `wasm32-wasi` + `--test-no-exec`**：

```bash
zig test wasm_lib.zig -target wasm32-wasi --test-no-exec -femit-bin=out.wasm
```

⚠️ `test-obj` 也要求 `--test-no-exec`（不给就报 `error: test-obj requires --test-no-exec`），
但加上之后在 freestanding 上还是同一个 `getrandom` 错——**问题在 runner，不在命令形式**。

**所以 `wasm_lib.zig` 的 test 块是怎么验证的**：靠**本机目标**跑。
纯逻辑与平台无关，所以 `zig test wasm_lib.zig`（本机）全绿就说明那套算法在 wasm 侧也对：

```text
$ zig test examples/18_cross/wasm_lib.zig
1/7 wasm_lib.test.add：两数相加（含负数与回绕，验证 i32 wrapping 语义）...OK
2/7 wasm_lib.test.fib：标准斐波那契数列前若干项...OK
3/7 wasm_lib.test.sum3：结果同时写进 last（模块内中转用，不是给宿主读的）...OK
4/7 wasm_lib.test.checksum：FNV-1a 32 位标准测试向量（与平台无关）...OK
5/7 wasm_lib.test.fmtWidth：std.Io.Writer.fixed 在 freestanding 可用（只写内存不碰 fd）...OK
6/7 wasm_lib.test.sortAndSpan：std.mem.sort 真的把数据排好了...OK
7/7 wasm_lib.test.本文件没有 main：freestanding 模块不是程序...OK
All 7 tests passed.
```

⚠️ 注意 `run-all.sh` 的 `test_cross_example` **只跑 `zig test main.zig`**，
不跑 `wasm_lib.zig` 的测试。所以上面这 7 条是**我手动验证的**，不在自动通道里。
这一点在 `wasm_lib.zig` 的文件头注释里写明了。

```zig
// examples/18_cross/main.zig 第 197-207 行
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
```

运行输出：

```text
==== 18.9 开始 ====
wasm32-wasi 比 freestanding 多一套 POSIX-ish 抽象：fd / 路径 / 时钟 / 随机
  → std.fs / std.time / std.process 在 wasi 上**大部分可用**（本机实测 std.fs.File 存在）
  → 产物是自足模块：node 报导入模块 env,wasi_snapshot_preview1
⚠️ 但 -target wasm32-wasi 下 `zig test` 依然编译失败（runner 要 Io.Threaded）
   要在 wasm 目标上**验证 test 块语法**，用：
     zig test wasm_lib.zig -target wasm32-wasi --test-no-exec -femit-bin=out.wasm
   （--test-no-exec 只编译不跑，产物是 WebAssembly (wasm) binary module）
⚠️ freestanding 连 --test-no-exec 也不行：runner 的 Io.Threaded 绕不开 getrandom
==== 18.9 结束 ====
```

## 18.10 `zig cc` / `zig c++`：自带 clang 前端 + 各目标 libc

`zig cc` 是"drop-in C 编译器"：clang 前端（旗子全兼容）+ Zig 的链接器（自带 LLD）+ libc 现场编译。

实测版本（`zig cc --version`，逐字抄）：

```text
clang version 22.1.8
Target: x86_64-apple-macosx14.8.9-unknown
Thread model: posix
```

**22.1.8** 这个数字说明 0.17 发行包里内建了一个相当新的 clang 前端。

`zig --help` 里的相关命令（逐字抄，这是"Zig 自带工具链"的完整清单）：

```text
  ar               Combine object files into static archive
  cc               Use Zig as a drop-in C compiler
  c++              Use Zig as a drop-in C++ compiler
  dlltool          Use Zig as a drop-in dlltool.exe
  lib               Use Zig as a drop-in lib.exe
  objcopy          Manipulate executables and relocatables
  objdump          Print information about executables and relocatables
  ranlib           Use Zig as a drop-in ranlib
  rc               Use Zig as a drop-in rc.exe
```

**这一串是"一个压缩包替代整套交叉工具链"的字面含义**——连 Windows 的 `dlltool` / `lib` / `rc` 都有。

### "同一份 C 代码换编译器"到底换掉了什么

`examples/18_cross/hello.c` 的全部内容（40 行左右，注释从简）：

```c
/* 18 交叉编译：这份 C 由 zig cc 编译。
 *
 * 四条验证通道之一：
 *   zig cc hello.c -o build/18_cross_hello_c && ./build/18_cross_hello_c
 *
 * 本章的点是「**同一份 C 代码换编译器**」：
 *   · zig cc hello.c   → clang 前端（0.17 内建 clang 22.1.8）+ Zig 自带的 LLD 链接器
 *   · 系统的 cc hello.c → Apple 的 clang + ld64
 * 两边编出的机器码一样，**区别在链接器和目标覆盖能力**：
 * `zig cc -target aarch64-linux hello.c -o hc` 能直接交叉出 Linux ELF，
 * 系统 cc 做不到（除非你先装好交叉工具链 + sysroot）。
 *
 * ⚠️ macOS 上 `zig cc` **不需要** -isysroot：0.17 会自己探测 SDK 路径
 *    （`zig cc -v hello.c` 的输出里能看到 -isystem .../MacOSX15.2.sdk/usr/include）。
 *    老版本教程里"zig cc 必须配 -isysroot $(xcrun --show-sdk-path)"的说法已过时。
 *
 * ⚠️ 0.17 已移除 @cImport（见 17 章），所以 C 侧的头文件不会自动翻译成 Zig。
 *    Zig 侧要调本文件的函数，只写一行 extern 声明即可（见 18.11）：
 *      extern fn c_triple(x: c_int) c_int;
 */
#include <stdio.h>
#include <stdint.h>

/* 与 Zig 混编时用的入口：Zig 侧用 `extern fn c_triple(x: c_int) c_int;` 声明它。
 * 故意**不**定义 main —— 两边都定义 main 会在链接期报 duplicate symbol _main（18.11）。 */
int32_t c_triple(int32_t x)
{
    return x * 3;
}

int main(void)
{
    printf("hello from C, compiled by zig cc\n");
    /* 顺带证明 libc 头文件与实现都就位：printf 能用说明 zig cc 补齐了
     * 目标平台的 libc，而不是只过了个语法检查。 */
    printf("c_triple(7) = %d\n", c_triple(7));
    /* printf 计算宽度用到了运行期数据 → 真正跑起来的代码，不只是常量折叠 */
    printf("sizeof(int) = %zu, sizeof(void*) = %zu\n", sizeof(int), sizeof(void *));
    return 0;
}
```

运行输出（`./build/18_cross_hello_c`，`run-all.sh` 第四条通道）：

```text
hello from C, compiled by zig cc
c_triple(7) = 21
sizeof(int) = 4, sizeof(void*) = 8
```

### ⚠️ macOS 上 `zig cc` **不需要** `-isysroot`

本教程早期版本记过一条坑："`zig cc` 缺 libc 时症状是 `mbstate_t`/`EOF` 未声明、`ld: library 'System' not found`，需要 `-isysroot $(xcrun --show-sdk-path)`"。

**在 0.17 上这条不适用**。实测：

```bash
$ zig cc hello.c -o hc1
$ echo $?
0
$ file hc1
hc1: Mach-O 64-bit executable x86_64
$ ./hc1
hello from C
```

一次通过，**零参数**。`zig cc -v hello.c` 的输出里能看到它自己找到了 SDK：

```text
 ... -isystem /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/include
     -isystem /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX15.2.sdk/usr/include
     -isystem /Applications/Xcode.app/.../MacOSX15.2.sdk/usr/include
     -iframework /Applications/Xcode.app/.../MacOSX15.2.sdk/System/Library/Frameworks
     -F /Applications/Xcode.app/.../MacOSX15.2.sdk/System/Library/Frameworks ...
```

（`zig env` 里还有个 `ZIG_IS_DETECTING_LIBC_PATHS` 环境变量，说明这是 0.17 内建的探测流程。）

⚠️ **零配置不等于所有场景都通**。如果你设了 `C_INCLUDE_PATH` / `LIBRARY_PATH` 这类环境变量
（`zig env` 的 `.env` 段里能看到这些槽位），Zig 会**优先用环境变量里的路径**，
那时才可能撞上 `ld: library 'System' not found`。遇到时先 `unset` 掉这些变量试一遍，
确认是不是环境污染。

### `zig cc` 的交叉能力

同一份 C 代码，`-target` 一换就换目标：

```bash
$ zig cc hello.c -o hc1
$ file hc1
hc1: Mach-O 64-bit executable x86_64

$ zig cc -target aarch64-linux hello.c -o hc_a64
$ file hc_a64
hc_a64: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, with debug_info, not stripped
```

`zig c++` 一样可用（实测 `h.cpp` 用 `<cstdio>` 能编能跑，输出 `from c++`）。

```zig
// examples/18_cross/main.zig 第 209-222 行
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
```

运行输出：

```text
==== 18.10 开始 ====
zig cc = clang 前端（旗子全兼容）+ Zig 的交叉底座（libc 现场为目标编）
实测版本：clang version 22.1.8（0.17 发行包里内建的 clang 前端）
  zig cc --version → clang version 22.1.8 + Target: x86_64-apple-macosx14.8.9-unknown
hello.c 由本目录提供，四条通道之一就是 `zig cc hello.c -o <exe>` 然后运行
同一份 C 代码换编译器：zig cc hello.c（clang 前端 + Zig 链接器）↔ 系统的 cc
  系统 cc 编出来的也是动态链接 Mach-O——这一层两边没区别，系统 cc 反而更‘原生’
  真正属于 Zig 的是**链接器**（自带 LLD）和**目标覆盖能力**
zig cc -target aarch64-linux hello.c -o hc → 交叉出 Linux ELF（本机实测）
zig c++ 同样存在：clang 前端 + C++ 标准库，h.cpp 实测能编能跑
⚠️ macOS 上 zig cc 直接可用，**不需要** -isysroot（0.17 自带 SDK 探测）
   本教程实测：`zig cc hello.c -o hc1` 一次通过，产物 Mach-O 64-bit executable x86_64
==== 18.10 结束 ====
```

## 18.11 把 C 代码当输入：`zig build-exe main.zig hello.c`

`zig build-exe` 收多个根文件时**不区分语言**：`.zig` 和 `.c` / `.cpp` 一起吃，编成一个产物。

```bash
$ zig build-exe cmain.zig lib1.c -femit-bin=mix
$ ./mix
Zig 调 C triple(7) = 21
```

Zig 侧只需一行 `extern` 声明（**0.17 已移除 `@cImport`**，17 章的结论）：

```zig
const std = @import("std");
extern fn triple(x: c_int) c_int;
pub fn main(init: std.process.Init) !void {
    _ = init;
    std.debug.print("Zig 调 C triple(7) = {d}\n", .{triple(7)});
}
```

C 侧只导出函数、不定义 `main`：

```c
#include <stdint.h>
int32_t triple(int32_t x) { return x * 3; }
```

### ⚠️ 两边都定义 `main` → `duplicate symbol definition: _main`

我第一次写混编示例时，`.zig` 和 `.c` 都有 `main`，链接期报（实测逐字）：

```text
error: duplicate symbol definition: _main
    note: defined by /Users/xulun/.cache/zig/tmp/e0b45e1164026a1a/cmain_zcu.o
    note: defined by /Users/xulun/.cache/zig/o/38a85ffe3787791bc854bed94c13abdd/hello.o
mix1: empty
```

**规则**：混编时让 `.c` 文件当"库"（只导出函数），**入口留给 Zig**。
这正是 `examples/18_cross/hello.c` 的设计——它有 `main`（给 `zig cc` 单独编那条通道用），
也有 `c_triple`（给混编那条通道用）。两条通道各取所需，不会撞。

⚠️ 注意报错里那个 `mix1: empty`——**产物文件被创建了但是 0 字节**。
如果你的脚本只看"文件存不存在"会误判成功，**要看 `zig` 的退出码**。

### 混编 + 交叉

同一对文件加 `-target` 也能编过：

```bash
$ zig build-exe cmain.zig lib1.c -target aarch64-linux -femit-bin=mix2a
$ file mix2a
mix2a: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, with debug_info, not stripped
```

⚠️ 但**混编 + `-target wasm32-freestanding` 会在 `Io.Threaded` 炸**（同 18.7）——
因为 Zig 侧的 `main` 用了 `std.debug.print`：

```text
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:2061:45: error: struct 'posix.system__struct_121' has no member named 'getrandom'
```

**C 代码本身是 freestanding 友好的**（`c_triple` 只做一次乘法），
炸的是 Zig 侧的 `std`。**混编到 wasm 要让 Zig 侧也 freestanding 干净**——
和 18.7 是同一条要求。

```zig
// examples/18_cross/main.zig 第 224-237 行
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
```

运行输出：

```text
==== 18.11 开始 ====
zig build-exe 收多个根文件时，**不区分语言**：.zig 和 .c/.cpp 一起吃
实测：`zig build-exe cmain.zig lib1.c -femit-bin=mix` → 成功，Zig 侧调到了 C 的函数
Zig 侧只需一行 extern 声明（17 章讲 @cImport 已移除后的正确姿势）：
  extern fn triple(x: c_int) c_int;   ← 直接声明 ABI，不走头文件翻译
⚠️ 坑：如果 .zig 和 .c **两边都定义了 main**，链接期报
   error: duplicate symbol definition: _main
       note: defined by .../cmain_zcu.o
       note: defined by .../hello.o
   ⇒ 让 C 文件当"库"（只导出函数不定义 main），入口留给 Zig
混编 + 交叉：同一对文件加 -target aarch64-linux 也能编过（实测出 ARM ELF）
⚠️ 但混编 + -target wasm32-freestanding 会在 Io.Threaded 炸（同 18.7，Zig 侧 main 用了 std）
==== 18.11 结束 ====
```

## 18.12 `zig cc -c`：分步编译再链接

`-c` 的语义和 gcc/clang 一致：**只编译不链接**，产物是目标文件。

```bash
$ zig cc -c hello.c -o hello.o
$ file hello.o
hello.o: Mach-O 64-bit object x86_64

$ zig cc -c -target aarch64-linux hello.c -o hello_a64.o
$ file hello_a64.o
hello_a64.o: ELF 64-bit LSB relocatable, ARM aarch64, version 1 (SYSV), with debug_info, not stripped
```

Zig 侧对应的命令是 `build-obj`：

```bash
$ zig build-obj lib.zig -femit-bin=lib.o
$ file lib.o
lib.o: Mach-O 64-bit object x86_64

$ zig build-obj lib.zig -target aarch64-linux -femit-bin=liba.o
$ file liba.o
liba.o: ELF 64-bit LSB relocatable, ARM aarch64, version 1 (SYSV), with debug_info, not stripped
```

⚠️ **`-c` 加 `-target` 的顺序不重要**（`zig cc -c -target X` 和 `zig cc -target X -c` 都行），
但 `zig build-obj` **必须** `build-obj` 在前（它是子命令，不是旗子）。

**分步的用处**：

- **多目标共库**：编一次 `.o`（或 `.a`），链给不同的目标
- **增量构建**：`.o` 可以缓存，`zig cc` / `zig build-obj` 都支持 `--listen` 走构建服务器
- **给别的链接器用**：Zig 编出来的 `.o` 和 clang 产出的没有区别，可以混着链

配合 `zig ar` / `zig ranlib` 就能手工做静态库：

```bash
$ zig ar t libstatic.a
/Users/xulun/.cache/zig/tmp/.../lib_zcu.o
```

⚠️ `zig objdump` 对 wasm 目标文件**不支持**（实测 `error: unrecognized file: cur.wasm`），
对 ELF 也只打了 `TODO dump elf file`。**要看产物用什么工具，看 18.6 那张表 + 系统 `file` / `nm`**。

```zig
// examples/18_cross/main.zig 第 239-249 行
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
```

运行输出：

```text
==== 18.12 开始 ====
zig cc -c 只编译不链接，产物是目标文件（.o）——和 gcc/clang 的习惯一致
实测：`zig cc -c hello.c -o hello.o` → Mach-O 64-bit object x86_64
交叉：`zig cc -c -target aarch64-linux hello.c -o hello_a64.o`
       → ELF 64-bit LSB relocatable, ARM aarch64（实测）
分步的用处：多目标共库、增量构建、给别的链接器用
Zig 侧对应物：zig build-obj lib.zig -femit-bin=lib.o（实测出 Mach-O 64-bit object）
      交叉：zig build-obj lib.zig -target aarch64-linux → ELF 64-bit LSB relocatable
工具链里还有 ar / ranlib / objcopy / objdump / dlltool / lib / rc（见 zig --help）
==== 18.12 结束 ====
```

## 18.13 交叉编译「编译即验证」

这是本章的**方法论**部分，也是交叉编译最实用的地方。

### 交叉产物在本机跑不了

实测：

```bash
$ ./aarch64 产物
(eval):1: exec format error: ./t9b
```

本机还**没装** `qemu-aarch64`（也没有 `wasmtime`）：

```bash
$ which qemu-aarch64 qemu-aarch64-static wasmtime
（全部 not found）
```

所以连"模拟器冒烟"这条退路都没有。**"编译通过"就是唯一能拿到的信号。**

### 但这个信号比想象的有价值

交叉编译一次性验证了**一整层**：

| 验证了什么 | 谁负责 |
|---|---|
| 类型 / 语义 | Zig 前端（AOT，`ReleaseSafe` 下全部检查都在） |
| 链接（符号解析、重定位） | LLD |
| **ABI 正确性**（调用约定、结构体布局、对齐） | 编译器 + 目标描述 |
| **汇编生成**（指令选择、指令是否合法） | LLVM 后端 |

LLVM 后端在生成 aarch64 汇编时如果用了目标上不存在的指令，**编译期就报**。
这就是本教程 21 章（手写汇编）能靠它做 aarch64 预检的原因。

### 抓不到什么

| 抓不到 | 为什么 |
|---|---|
| 运行时性能 | Debug 模式的数字没意义（02 章 2.5 节） |
| syscall 语义差异 | 编过了只说明"能调"，不说明"调了行为对" |
| 目标机特有的运行时问题 | 比如 Linux 上的 `errno` 覆盖、macOS 上的主线程检查 |
| 动态库的 ABI 兼容性 | 静态编译过了，动态链接到目标机上可能缺符号 |

### 本示例自己就是活证明

`main.zig` 被编了两次（`run-all.sh` 的第 3、5 步）：

| 步骤 | 命令 | 结果 |
|---|---|---|
| 3 | `zig build-exe main.zig -femit-bin=build/18_cross` | ✅ 跑起来了，179 行输出 |
| 5 | `zig build-exe main.zig -target aarch64-linux -femit-bin=build/18_cross_aarch64-linux` | ✅ 编译成功，**无 stdout**（跑不了） |

而 `archCode()`（`examples/18_cross/main.zig` 第 415-423 行）这个纯编译期函数
在两边的值**必然不同**——本机返回 1，aarch64 产物里编译进的是 2：

```zig
// examples/18_cross/main.zig 第 294-305 行
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
```

测试里断言的是"**当前目标下的期望值**"而不是硬编码某个数字
（`examples/18_cross/main.zig` 第 394-405 行）：

```zig
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
```

这是**跨目标测试的通用写法**：断言"函数和目标一致"，不���言"函数等于某个字面量"。
这样同一份测试代码在任何目标上都能编过。

```zig
// examples/18_cross/main.zig 第 251-264 行
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
```

运行输出：

```text
==== 18.13 开始 ====
交叉产物**在本机跑不了**，所以「编译通过」就是唯一可得的信号
本机实测：./aarch64 产物 → (eval):1: exec format error: ./t9b
本机没装 qemu-aarch64 / wasmtime → 连模拟器这条路也没有
⇒交叉编译能验证的是：**类型/语义/链接/ABI/汇编生成**这一整层
它抓不到的是：目标机上的运行时行为（性能、syscall 语义、驱动）
本教程 21 章（手写汇编）就靠这一招：在写 aarch64 汇编正文之前，
先用 zig build-obj -target aarch64-linux 做预检——汇编错了编译期就报
反过来，**本文件自己**就是这条规则的活证明：
  同一份 main.zig 被编成本机 exe（跑了，有输出）+ aarch64-linux ELF（只编）
  两边 builtin.target 的值不同 → arch_code 不同 → 交叉产物里的常量是另一套
  arch_code（本机）= 1
==== 18.13 结束 ====
```

### ⚠️ 别用 `-femit-bin=/dev/null` 做交叉验证

这条是我在探查时踩到的。`-femit-bin=/dev/null` 在**本机目标**上是常见的"只检查不产出"技巧，
但**交叉到 Linux musl 目标会 panic**：

```bash
$ zig build-exe t.zig -target x86_64-linux-musl -femit-bin=/dev/null
thread 1578769 panic: DWARF TODO: 'InputOutput' while updating constant

Cannot print stack trace: stack tracing is disabled
```

换成真实路径就正常：

```bash
$ zig build-exe t.zig -target x86_64-linux-musl -femit-bin=out_musl
$ file out_musl
out_musl: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, with debug_info, not stripped
```

（`aarch64-linux` 目标用 `/dev/null` 反而没事——**这是 musl 目标的特有问题**。
所以验证交叉编译时老老实实给个真实输出路径。）

## 18.14 限制：交叉编译做不到什么

七条，按"踩到频率"排：

```zig
// examples/18_cross/main.zig 第 266-276 行
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
```

运行输出：

```text
==== 18.14 开始 ====
① 产物只能在对应机器上跑（exec format error 就是答案，见 18.13）
② wasm 没有文件系统：没有 fopen/readdir，std.fs 那套在 freestanding 直接不存在
③ freestanding 没有 std.debug.print：要输出得自己导出函数（见 18.8）
④ 没有 sysroot 就没有目标系统的头文件：@cImport 在 0.17 已移除（17 章）
   即便有，裸机目标的 libc 头文件也不存在
⑤ 一个 -target 只产一种 ofmt：ELF 目标别想要 Mach-O，wasm 目标别想要 ELF
⑥ 交叉编译 ≠ 跨平台兼容：编过了只说明指令集/ABI 对，运行时仍可能缺 syscall
⑦ -target 不能改变宿主：它改的是**产物**，不是你正在跑的这台机器
==== 18.14 结束 ====
```

第 ⑦ 条值得多说一句，因为它是最容易误解的：`-target` **不改你的宿主**。
在 macOS 上写 `-target aarch64-linux`，你的 macOS 还是 macOS，`zig env` 的 `.target` 不变，
只是产物变成了 Linux ELF。**"交叉"是关于产物的，不是关于运行环境的。**

第 ⑤ 条也是硬的：一个 `-target` 只对应一个 `ofmt`。
想要"一个二进制同时是 ELF 和 wasm"在 0.17 做不到（`--ofmt` 旗子存在但那是给特殊流程用的，
实测 `zig build-exe --help` 第 96 行有 `-ofmt=[fmt]   Override target object format`，
列出 elf/c/wasm/coff/macho/spirv/plan9/hex/raw）。

## 18.15 自检

最后这一节把本章的东西落到两个**平台无关的断言**上。

```zig
// examples/18_cross/main.zig 第 25-40 行
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
```

⚠️ `checksum` 用 `*%=` 而不是 `*=`：**FNV-1a 的乘法本来就设计成回绕的**，
写 `*=` 会在 Debug 模式下溢出报错。而 `%` 对 `i32` 要用 `@mod`、对无符号数才是 `*%` 那个语法——
这里 `acc` 是 `u32` 所以 `*%` 正确。

```zig
// examples/18_cross/main.zig 第 278-290 行
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
```

运行输出：

```text
==== 18.15 开始 ====
wordSize() = 8（aarch64 与 x86_64 同为 8；wasm32 会是 4）
checksum("abc") = 0x1a47e90b（FNV-1a，与平台无关）
checksum("") = 0x811c9dc5（空串即偏移基准）
三段式自检：arch_code=1 ofmt=macho 输出模式=Exe
==== 18.15 结束 ====
自检通过
```

`checksum("abc")` 的值 `0x1a47e90b` 和 `main.zig` 与 `wasm_lib.zig` 里都能算出来
（两个文件都有 FNV-1a 实现），**这本身就是一条交叉验证**：
两个独立的编译单元、不同的目标约束，算出同一个数。

⚠️ `{x:0>8}` 的 `0>` 是"补零到至少 8 位"——所以 `0x811c9dc5` 正好 8 位不用补。
如果换成更短的数会看到前导零。

---

## 18.x 坑位清单

1. **`zig targets` 在 0.17 不再输出 JSON**，改成 Zig 结构体字面量
   （`.{ .arch = .{"aarch64", ...}, ... }`，本机实测 34980 行）。
   `zig targets | jq ...` 这类管道全部失效。八个顶层字段：
   `.arch`(61) `.os`(48) `.abi`(30) `.libc`(108) `.glibc`(59) `.cpus` `.cpu_features` `.native`。

2. **命令行 `-target` 不支持结构体形式**。`-target '.cpu_arch = .aarch64'` 报
   `error: unknown architecture: '.cpu_arch = .aarch64'`（`{...}` 和 `{k=v}` 两种写法同样被拒）。
   字段名（`cpu_arch` / `cpu_model` / `os_tag` / `abi`，见 `std/Target/Query.zig`）是对的，
   但那是给 `build.zig` 的 `b.resolveTargetQuery` 用的。

3. **`-O` 的四个合法值在 0.17 变成全小写**：`debug` / `safe` / `fast` / `small`。
   所以 `@tagName(builtin.mode)` 打印 **`debug`** 不是 `Debug`。
   旧名（`Debug` / `ReleaseSafe` / `ReleaseFast` / `ReleaseSmall`）走 `fromString` 仍能过，
   但源码标注 "Deprecated, to be removed after 0.18.0"。
   `OutputMode`（`Exe`/`Lib`/`Obj`）和 `LinkMode`（`static`/`dynamic`）**没改**。

4. **`build-lib -target wasm32-freestanding -femit-bin=x.wasm` 产出的是 ar 归档**，
   `file` 输出 `current ar archive`（扩展名不决定产物类型）。
   要真 wasm 模块必须 `-dynamic`，且 **Debug 模式下还要 `-fPIC`**
   （否则 `relocation R_WASM_MEMORY_ADDR_SLEB cannot be used against symbol ...; recompile with -fPIC`）。
   wasm-ld 会警告 `creating shared libraries, with -shared, is not yet stable`。

5. **`wasm32-freestanding` 上 `zig test` 编译失败**，报
   `lib/std/Io/Threaded.zig:2061: error: struct 'posix.system__struct_N' has no member named 'getrandom'`。
   `--test-no-exec` / `-fsingle-threaded` 都救不了（问题在 runner）。
   唯一可行：`zig test x.zig -target wasm32-wasi --test-no-exec`。
   ⚠️ `posix.system__struct_N` 的 **N 每次编译都不同**（实测见过 2/4/121/125），抄错误时别抄序号。

6. **`export fn` 不能收切片**：
   `error: parameter of type '[]const u8' not allowed in function with calling convention 'x86_64_sysv'`
   + `note: slices have no guaranteed in-memory representation`。
   ABI 边界上只能用标量和裸指针——写成 `ptr: [*]const u8, len: usize` 两个参数。

7. **`export var` 在 `-fPIC` 的 wasm 里宿主读不到活值**。
   最小复现（`export var g: i32 = 7; export fn bump() i32 { g += 1; return g; }`）：
   node 里 `g.value` 恒为 0，而 `bump()` 正确返回 8、9。
   原因：PIC 模式下数据在宿主提供的 linear memory，导出 global 是引擎实例化时的快照。
   ⇒ **跨 wasm 边界只用返回值**。

8. **`std.Target.Os.Tag` 只有 `isDarwin` 和 `isBSD` 两个 helper**。
   写 `t.os.tag.isLinux()` 报
   `error: no field or member function named 'isLinux' in 'Target.Os.Tag'`。
   `Cpu.Arch`（`isX86`/`isArm`/`isAarch64`/`isWasm`/`isRiscv64`…）
   和 `Abi`（`isGnu`/`isMusl`/`isAndroid`/`isOpenHarmony`）上的才很多。

9. **`os.version_range` 是无 tag 的 `union{}`**（不是 `union(enum)`）。
   `switch` 报 `error: switch on union with no attached enum`；
   `if (x) |r|` 报 `error: expected optional type, found 'Target.Os.VersionRange'`。
   正确写法：`if (t.os.tag == .linux) { t.os.version_range.linux.glibc }`。

10. **`builtin.cpu.features` 是位集合**（`ints: [6]usize`，347 个特性位），
    **没有 `.len` 也没有 `.has`**：
    `error: no field or member function named 'len' in 'Target.Cpu.Feature.Set'`。
    用 `.count()` / `.isEmpty()` / `== .empty`。要按名字查特性得走 arch 相关索引表。

11. **`target.dynamic_linker` 是 struct（`buffer: [255]u8` + `len: u8`），不是字符串**。
    写 `.path` 报 `error: no field named 'path' in struct 'Target.DynamicLinker'`。
    要用 **`.get()`** 取 `?[]const u8`（`len == 0` → `null`，即"无动态链接器"）。
    设计目的是"这个 API 不需要分配器"。

12. **freestanding 上这些 `std` struct 整个不存在**（不是"缺成员"）：
    `std.fs` / `std.fs.File` / `std.time.Instant` / `std.posix.getpid` /
    `std.process.argsAlloc` / `std.math.abs` 全报
    `error: root source file struct 'fs' has no member named 'cwd'` 这种措辞。
    `std.Thread.spawn` 是另一类：`error: Cannot spawn thread when building in single-threaded mode`。
    ⚠️ 但 **`std.Io.Writer.fixed` 可用**（只写内存缓冲），
    所以"格式化"在 freestanding 上没问题，坏的只是 `std.debug.print`。

13. **`build-lib` 只编译被引用到的声明**。探"某个 std 设施在 freestanding 上能不能用"时，
    写 `_ = std.X` **不会触发语义分析**（会误报"可用"）。必须用 `export fn` 包住真实调用。

14. **混编时两边都定义 `main` → `error: duplicate symbol definition: _main`**，
    后面跟两行 `note: defined by .../<name>_zcu.o` / `note: defined by .../<name>.o`。
    ⚠️ 产物文件会被创建成 **0 字节**（`mix1: empty`），脚本只看文件存在会误判成功——看退出码。
    规则：`.c` 当库（只导出函数），入口留给 Zig。

15. **`-femit-bin=/dev/null` 在交叉到 musl 目标时会 panic**：
    `thread N panic: DWARF TODO: 'InputOutput' while updating constant`。
    换真实输出路径就正常。验证交叉编译时别用 `/dev/null`。

16. **同一个 `-target` 语法在两边的默认 `link_mode` 不同**：
    `aarch64-linux` 实测 `link_mode = .static`（产物 `statically linked`），
    本机 macOS 默认 `.dynamic`。要静态链接显式加 `-static` 或用 `x86_64-linux-musl`。
    另外 `-mcpu native` 交叉时必炸（`error: sub-compilation of compiler_rt failed`）。

---

上一章：[17 C 互操作](17-c-interop.md) · 下一章：[19 并发](19-threads.md)
