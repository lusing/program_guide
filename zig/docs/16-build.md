# 16 · 构建与包管理 ⭐

> 对应示例：`examples/16_build/`（**build.zig 工程**）
>
> 本章是全教程唯一的"工程组织"章：前面 15 章都是 `main.zig` 单文件 + `zig build-exe`，
> 从这一章起换成 `build.zig` + `build.zig.zon` + `zig build`。
>
> ⚠️ **本章按 0.17 重写**。0.17 的构建系统改动比语言本身还多，
> 最要命的一条是 **`b.args` 被移除**——照抄 0.16 的 build.zig 会在
> run step 上静默丢参数。完整迁移对照见 [00 · 0.16 → 0.17 迁移手册](00-migration-0.17.md)。

---

## 导读

其他语言配构建系统要装三件套：CMake（生成构建文件）+ Make/ninja（执行）+ 包管理器（拉依赖）。Zig 把三件套合并成**一个用 Zig 写的程序**：你写 `build.zig`，`zig build` 编译它、运行它，它输出一张构建图（节点 = 编译/链接/运行/生成文件，边 = 依赖），runner 再按拓扑并行执行。

这不是"少装一个工具"的便利，而是**表达力**的差别：CMake 的 DSL 是当年为了"够用且跨平台"发明的，它表达不了"编译完顺便把这个 `.a` 的符号表打出来喂给下一步"；而构建脚本本身就是 Zig 源码，能调文件、解析 JSON、读环境变量、循环生成几十个目标，不需要退回 CMake 自己的小语言再发明一遍。

本章的示例工程 `examples/16_build/` 把这一章的概念全部做成能跑的东西：三个产物、两个可执行文件、四个自定义 step、一个路径依赖、一份 C 代码、一个子包。

## 16.1 为什么构建系统是语言的一部分

没有 Makefile，没有 CMakeLists.txt。工程里只有一个 `build.zig`：

```zig
// examples/16_build/build.zig 第 1-11 行
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
```

入口签名是 `pub fn build(b: *std.Build) void`——**只有一个参数**（构建器指针），返回 `void`。这个签名本身就是设计声明：build.zig 不返回任何结果，它只往 `b` 里登记东西；`void` 也堵死了"把编译结果 return 出去"的可能性。

`std.Build` 这个结构体就是构建图的 API 门面。它内部持有 `graph: *Graph`，所有 `addXxx` 方法都在图里加节点。`b` 的类型是 `*std.Build` 而不是 `*Graph`，是为了让 API 面保持稳定——`Graph` 内部结构在 0.11 → 0.17 之间改过好几轮。

程序侧能看到的只有编译期事实：

```text
=== 16.1 没有 CMake：构建系统就是 Zig 程序 ===
  没有 Makefile / build.gradle / CMakeLists.txt，只有一个 build.zig
  它本身是 Zig 源码，被 Zig 编译后运行，输出是一张构建图
  可执行文件名（addExecutable 的 .name）= 16_build
  argv[0] = 16_build
  运行期能看到的构建期事实，只有下面这些：
    @import("builtin").mode = debug
    @import("builtin").target.cpu.arch = x86_64
    @import("builtin").target.os.tag = macos
--- 16.1 完毕 ---
```

（`$ zig build run` 的输出，节选。`argv[0]` 那行用了 `shorten()` 掐掉目录，不掐的话长这样：`argv[0] = ./.zig-cache/o/da2a24a78eef9d759fd5659e51201339/16_build`——哈希是构建图节点的身份，16.17 会再回来说它。）

## 16.2 install / run / test 三个默认 step

`zig build` 不带参数时跑什么？答案是 `install`。这一点是**内建**的，不是你的 build.zig 写的——你写的每个 `b.step("…")` 都是往默认 step 旁边加邻居。

```text
$ zig build --help
Usage: zig build [steps] [options]

Steps:
  install (default)            Copy build artifacts to prefix path
  uninstall                    Remove build artifacts from prefix path
  run                          运行 16_build（-- 之后的参数会透传给程序）
  run-tool                     运行 16_build_tool
  test                         跑单元测试
  test-deps                    只跑依赖包的测试
  info                         打印当前构建配置
  size                         打印各产物的字节数（顺序不保证，步是并行跑的）
  deps                         打印依赖树
  cross                        为常见交叉目标各编一份（不安装）
```

（`Usage:` 那行在你的机器上会带完整解释器路径，这里替换成了 `zig`。）

读法：前两行 `install` / `uninstall` 是**框架内建**的，描述文字是英文；从第三行开始全是本工程 `b.step()` 注册的，描述文字是我们自己写的中文——这个对比本身就是"哪些是语言给的、哪些是你给的"最直观的分界。`install (default)` 里的 `(default)` 标记就是"裸 `zig build` 跑这个"。

多 step 可以一次跑多个，runner 按依赖关系调度：

```bash
zig build            # 等价 zig build install
zig build test       # 只跑测试
zig build run        # 编译 + 运行
zig build run -- x y # -- 之后的 x y 透传给程序（需 addPassthruArgs）
zig build size deps  # 两个自定义 step 一起跑
zig build uninstall  # 清空 zig-out
```

`run-all.sh` 验证 16 章时跑的三条命令就是 `zig fmt --check .` → `zig build test` → `zig build run`。

## 16.3 build.zig.zon：包的身份证

`build.zig.zon` 是 zson 格式（Zig 自己的字面量语法，ZON = Zig Object Notation）。它描述的是**包**，不是构建过程。

```zig
// examples/16_build/build.zig.zon 第 1-29 行
.{
    // ① .name 必须是**合法标识符**（写成枚举字面量 `.build16`，不是字符串）。
    //    数字开头会报 "expected enum literal" —— 这就是为什么本工程
    //    不能叫 `.build16` 之外还写个 `."16_build"`。
    //    它同时是包的身份：zig build 拿 name + version + paths 等算出 fingerprint。
    .name = .build16,
    .version = "0.1.0",
    // ② .fingerprint 是包的**内容哈希**，作用是「防缓存串味」：
    //    全局包里缓存的构建产物按 hash 索引，改了身份就必须换 hash，
    //    否则会命中别的包的缓存。**不要自己编**，把 0 写上跑一次
    //    `zig build`，报错里会给出正确值（本工程 = 0x7941b290a7f6b461）。
    .fingerprint = 0x7941b290a7f6b461,
    // ③ 0.17 起必须写最低版本。低于它会在解析依赖时被拒。
    .minimum_zig_version = "0.17.0",
    // ④ 路径依赖：不写版本/URL，直接指向仓库内的另一个包。
    //    第一层接线就在这里——build.zig 里 b.dependency("zmath", …) 找的就是它。
    .dependencies = .{
        .zmath = .{ .path = "vendor/zmath" },
    },
    // ⑤ 这个包包含哪些文件。父包 vendoring 本包时按它裁剪；
    //    本地构建只是校验这些路径存在。
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src",
        "csrc",
        "vendor",
    },
}
```

### 逐字段实测

| 字段 | 必填 | 类型 | 实测行为 |
|---|---|---|---|
| `.name` | ✅ | 枚举字面量 | 缺失报 `missing top-level 'name' field`；写成数字报 `expected enum literal` |
| `.version` | ✅ | 字符串 | 缺失报 `missing top-level 'version' field` |
| `.fingerprint` | ✅ | 整数字面量 | 不匹配报 `invalid fingerprint: …; use this value: 0x…` |
| `.paths` | ✅ | 字符串数组 | 缺失报 `missing top-level 'paths' field` |
| `.minimum_zig_version` | 建议 | 字符串 | **实测缺失不报错**（0.17 只在依赖解析时校验） |
| `.dependencies` | 可选 | 映射表 | 缺失 = 无依赖 |

几个实测出来的关键点：

**`.name` 必须写枚举字面量，不能写字符串。** 写 `.name = "build16"` 或数字开头的名字都会被 ZON 解析器挡下来：

```text
$ cat > build.zig.zon   # .name = 16 时的报错
build.zig.zon:1:12: error: expected enum literal
.{ .name = 16, .version = "0.1.0", .fingerprint = 0x7941b290a7f6b461, .minimum_zig_version = "0.17.0", … }
           ^~
```

这就是为什么本工程的目录叫 `16_build` 但包名必须叫 `build16`。

**`.fingerprint` 不是随便填的，它是一个真算出来的哈希。** 把 0 写上跑一次：

```text
$ zig build
build.zig.zon:1:2: error: invalid fingerprint: 0x0; if this is a new or forked package, use this value: 0x7941b290a7f6b461
.{
 ^
```

报错直接给你正确答案，抄回去就完事。

**但要注意：改了身份，指纹就变。** 我实测过同一个 `.name` 下改各个字段：

```text
.name = .build16, .version = "0.0.0"                                → 0x7941b290bb0f305e
.name = .build16, .version = "0.1.0"                                → 0x7941b29083dca791
.name = .build16, .version = "0.1.0" + .dependencies = .{}          → 0x7941b29095e7b397
.name = .build16, .version = "0.1.0" + .paths = .{"build.zig"}      → 0x7941b290a387fe42
.name = .build16, .version = "0.1.0" + minimum_zig_version = "0.16.0" → 0x7941b290cf694370
.name = .probe_two（只改名字）                                       → 0xec2a6776f40caffd（完全不同）
```

也就是说指纹覆盖了**除依赖本身以外的几乎所有顶层字段**。这正是它的用途：全局构建缓存按 `name+fingerprint` 索引，如果你 fork 了一个包改了 `.paths`，但沿用原指纹，就会命中别人的缓存产物——构建出来的东西看着对，其实某个文件是旧版本。所以 fork 的第一件事就是换指纹，工具链会逼你换。

**`.minimum_zig_version` 缺失并不报错**（我实测把整行删掉，`zig build` 照样过）。但它是给依赖链用的：你依赖的包声明最低 0.18，而你手上是 0.17，才会被拒。所以**作为库作者必须写，作为应用作者写了不吃亏**。

**未知字段被静默忽略**——我加了个 `.unknown_field = 1`，`zig build` 一声不吭。别把它当 schema 校验用。

### 子包的 zon

路径依赖指向的子包也得有自己的 zon：

```zig
// examples/16_build/vendor/zmath/build.zig.zon 第 1-15 行
.{
    // .name 必须是合法标识符（枚举字面量，不能以数字开头，也不是字符串）。
    // 它同时是包的身份，zig build 拿它算 .fingerprint。
    .name = .zmath,
    .version = "0.1.0",
    // 由 `zig build` 的报错提示给出，不要自己编。
    .fingerprint = 0xfd23d4228f5d0d1c,
    .minimum_zig_version = "0.17.0",
    // .paths 是「这个包包含哪些文件」，父包把它 vendoring 进自己时按它裁剪。
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src",
    },
}
```

子包指纹 `0xfd23d422…` 和主包 `0x7941b290…` 高位完全不同——高位段编码了依赖图里的身份（本地包 vs 全局缓存包），低位段才是包内容哈希。

## 16.4 build() 返回时什么都没编译

这是整个构建系统的核心机制，也是它比 CMake 快的原因。

`build()` 是一个**配置阶段**（configure phase）：它只往 `b` 里登记。所有 `b.addExecutable` / `b.addTest` / `b.addRunArtifact` / `b.addSystemCommand` 返回的都是**节点对象**（`*Step.Compile` / `*Step.Run`），不是"已编译的东西"。

真正执行是 `build()` 返回**之后**由 runner 做的，runner 读这张图、按拓扑排序、并行跑没有依赖冲突的节点。所以：

- `build()` 里能做的事 = 纯图操作 + 你自己的计算（`b.fmt` 拼字符串、循环、读文件）；
- `build()` 里做不到的事 = 依赖"上一个 step 的产物"（图是静态的，无数据流）；
- 因此 `build()` 跑两次的耗时与工程规模无关，只与你的脚本复杂度有关。

**步与步之间没有顺序保证。** 这是最容易踩的隐含假设。我第一版 `deps` step 是这么写的：

```zig
// ✗ 错误写法：三行输出挂三条 echo step
const deps_cmd = b.addSystemCommand(&.{"echo"});
deps_cmd.addArg("build16 的模块依赖树：");
deps_step.dependOn(&deps_cmd.step);
for (dep_lines) |line| {
    const echo = b.addSystemCommand(&.{"echo"});
    echo.addArg(line);
    deps_step.dependOn(&echo.step);   // 三条互不依赖 → runner 并行跑 → 顺序乱
}
```

实测输出（header 跑到了中间）：

```text
  |- build_options   (b.addOptions() 生成的模块)
  `- zmath           -> src/root.zig
build16 的模块依赖树：
  |- build16_lib     -> src/lib.zig
```

要修就得让**一条命令**打印所有行：

```zig
// examples/16_build/build.zig 第 210-215 行
// ⚠️ 用 `sh -c 'echo "$@"'` 一次打印多行：不能挂多条 echo step，
//    因为 runner 会**并行**跑它们，输出顺序就乱了。
//    这是本章最值得记住的构建系统特性：步与步之间没有顺序保证。
const deps_cmd = b.addSystemCommand(&.{ "sh", "-c", "printf '%s\\n' \"$@\"", "sh" });
deps_cmd.addArgs(dep_lines);
deps_step.dependOn(&deps_cmd.step);
```

修正后的输出（`zig build deps`）：

```text
build16 的模块依赖树：
  |- build_options   (b.addOptions() 生成的模块)
  |- build16_lib     -> src/lib.zig
  `- zmath           -> src/root.zig
```

想让 B 必须在 A 之后跑，正确写法是 `b.step` + `dependOn` 建一条边，而不是"碰巧在同一次调用前后写"。

`build.zig` 里也有 `b.fmt` 这个便利函数（等价 `std.fmt.allocPrint` 到构建器的 arena），它返回的切片在构建脚本结束后失效，但足够喂给 `addArg` / `addOption`：

```zig
// examples/16_build/build.zig 第 163-170 行
const info_lines = [_][]const u8{
    b.fmt("target   = {s}-{s}", .{
        @tagName(target.result.cpu.arch),
        @tagName(target.result.os.tag),
    }),
    b.fmt("optimize = {s}", .{@tagName(optimize)}),
    b.fmt("verbose  = {}", .{verbose}),
};
```

⚠️ `b.fmt` 的结果**不能和字面量用 `++` 拼接**——那是编译期操作：

```text
build.zig:192:59: error: unable to resolve comptime value
        deps_cmd.addArgs(&.{"└── zmath -> " ++ b.fmt("{}", .{…})});
                                                     ~~~~~^~~~~~~~~~~~~~~~~~~~~~~~~~~>
build.zig:192:59: note: slice being concatenated must be comptime-known
```

把整个字符串塞进 `b.fmt` 的格式串里就行。

## 16.5 目标与优化选项

两行代码打开了所有构建选项：

```zig
// examples/16_build/build.zig 第 12-19 行
// ── 16.5 目标与优化选项 ────────────────────────────────────────────
// 这两行是 `-Dtarget=` / `-Doptimize=` 的唯一来源。0.17 签名：
//   standardTargetOptions(args: StandardTargetOptionsArgs) ResolvedTarget
//   standardOptimizeOption(options: StandardOptimizeOptionOptions) std.builtin.Optimize
// standardTargetOptions 返回的是 ResolvedTarget（结构体，含 .query 与 .result），
// 不是 0.11 时代的裸 ResolvedTarget 指针——用 target.result 拿具体 Target。
const target = b.standardTargetOptions(.{});
const optimize = b.standardOptimizeOption(.{});
```

`standardTargetOptions` 返回的是**结构体**不是指针：

```zig
pub const ResolvedTarget = struct {
    query: Target.Query,
    result: Target,
};
```

所以 `target.result.cpu.arch` / `target.result.os.tag` / `target.result.abi` 是最终值，`target.query` 保留用户原始输入。注意 `Target.Abi` 是 `std.Target.Abi`（**不是** `std.builtin.Abi`——后者在 0.17 不存在，写了会报 `root source file struct 'lang' has no member named 'Abi'`）。

`StandardTargetOptionsArgs` 还有两个字段可以筛选项：

```zig
pub const StandardTargetOptionsArgs = struct {
    whitelist: ?[]const Target.Query = null,   // 只允许这几个目标
    default_target: Target.Query = .{},        // 默认目标
};
```

只允许本机和 wasm：`b.standardTargetOptions(.{ .whitelist = &.{ .{}, .arch_os_abi = "wasm32-freestanding" } })`。

### 四个选项值

`-Doptimize=` 接受四个值，注意它们是**小写**的：

| 值 | `std.builtin.Optimize` | 含义 |
|---|---|---|
| `debug` | `.debug` | 运行时检查全开，无优化。**默认** |
| `safe` | `.ReleaseSafe` | 优化 + 保留运行时检查 |
| `fast` | `.ReleaseFast` | 只优化不检查（C 世界在这） |
| `small` | `.ReleaseSmall` | 优先体积 |

⚠️ 0.17 的枚举第一个成员是**小写** `.debug`（旧版是 `.Debug`），但后三个仍是驼峰——这是个不对称的历史遗留，抄的时候容易顺手写成全小写。main.zig 里写 `builtin.mode == .Debug` 会报：

```text
src/main.zig:256:45: error: no field named 'Debug' in enum 'lang.Optimize'
    try std.testing.expect(builtin.mode == .Debug or builtin.mode == .ReleaseFast or
                                           ~^~~~~
/Volumes/…/lib/std/lang.zig:113:22: note: enum declared here
pub const Optimize = enum {
                     ^~~~~
```

实测：

```bash
$ zig build info
target   = x86_64-macos
optimize = debug
verbose  = false

$ zig build info -Dverbose -Doptimize=ReleaseFast
target   = x86_64-macos
optimize = fast
verbose  = true
```

（`optimize = fast` 是 `@tagName(.ReleaseFast)`——tag 名和 CLI 值不一样，CLI 的 `ReleaseFast` 是枚举全名，`fast` 是简写。）

程序侧读的是 `@import("builtin")`：

```zig
// examples/16_build/src/main.zig 第 79-88 行
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
```

```bash
$ zig build run
=== 16.5 -Dtarget= / -Doptimize= ===
  mode   = debug（-Doptimize=debug/safe/fast/small）
  arch   = x86_64（-Dtarget= 决定）
  os     = macos
--- 16.5 完毕 ---

$ zig build run -Doptimize=ReleaseFast
=== 16.5 -Dtarget= / -Doptimize= ===
  mode   = fast（-Doptimize=debug/safe/fast/small）
  arch   = x86_64（-Dtarget= 决定）
  os     = macos
--- 16.5 完毕 ---
```

`--help` 里列出的选项比 target/optimize 多：

```text
Project-Specific Options:
  -Dtarget=[string]            The CPU architecture, OS, and ABI to build for
  -Dcpu=[string]               Target CPU features to add or subtract
  -Dofmt=[string]              Target object format
  -Ddynamic-linker=[string]    Path to interpreter on the target system
  -Doptimize=[enum]            Prioritize performance, safety, or binary size
                                 Supported Values:
                                   debug
                                   safe
                                   fast
                                   small
```

输错值的话，错误信息会**列出所有可用项**（实测）：

```text
$ zig build info -Dnosuch
error: invalid option: "nosuch"
info: available option: "target": The CPU architecture, OS, and ABI to build for
info: available option: "cpu": Target CPU features to add or subtract
info: available option: "ofmt": Target object format

$ zig build info -Doptimize=Turbo
error: expected -Doptimize to be of type "lang.Optimize"
info: available option: "target": The CPU architecture, OS, and ABI to build for
info: available option: "cpu": Target CPU features to add or subtract

$ zig build info -Dtarget=bogusos
unable to parse target "bogusos": UnknownArchitecture
info: available option: "target": The CPU architecture, OS, and ABI to build for
```

注意第三行的错误类型不是 `error:` 而是裸的 `unable to parse target`——target 解析走的是另一条路径。

## 16.6 b.path 与路径处理

```zig
// examples/16_build/build.zig 第 37-41 行
const lib_mod = b.createModule(.{
    .root_source_file = b.path("src/lib.zig"),
    .target = target,
    .optimize = optimize,
});
```

`b.path(sub_path)` 返回 `LazyPath`——一个**延迟路径**：配置阶段它只是"包根目录 + 相对路径"的一对值，等 runner 真正执行到某个节点时才拼出绝对路径。这就是为什么 `root_source_file` 字段类型是 `?LazyPath` 而不是 `[]const u8`：它可能不是文件，也可能是**构建期生成的文件**（`addOptions` 的产物就在 `.zig-cache/o/…/options.zig`）。

⚠️ **0.17 不接受裸字符串了。** 实测：

```text
build.zig:38:10: error: expected type '?Build.LazyPath', found '*const [11:0]u8'
        .root_source_file = "src/lib.zig",
        ~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/Volumes/…/lib/std/Build.zig:2192:22: note: union declared here
pub const LazyPath = union(enum) {
                     ^~~~~
```

`LazyPath` 在 0.17 是个联合体，有五个变体：

| 变体 | 含义 |
|---|---|
| `.src_path` | 相对**包根目录**（`b.path` 产的就是它） |
| `.generated` | 构建期生成的缓存文件（`addOptions`、`addWriteFile`） |
| `.cwd_relative` | 相对当前工作目录（**已 Deprecated**） |
| `.dependency` | 某个依赖包里的文件 |
| `.relative` | 相对某个已知基准（cache_root / local_cache / zig_lib / zig_exe） |

有几个固定的常量路径可以直接用：`LazyPath.zig_exe`、`LazyPath.zig_lib`、`LazyPath.cache_root`。

**`b.path` 相对包根，不相对 cwd。** 这一点在"从子目录跑 zig build"时特别重要——本教程的 `run-all.sh` 就是 `cd "$dir"` 之后再跑，包根和 cwd 一致；但如果你在仓库根跑 `zig build --build-file examples/16_build/build.zig`，`b.path("src/main.zig")` 依然指向 `examples/16_build/src/main.zig`，不会错。

## 16.7 模块系统：一个模块 = 根源文件 + imports + 选项

这是 0.12 之后 Zig 最重要的概念变化。**模块（Module）** 是编译的最小单位，它把三件事绑在一起：

1. **根源文件**（`root_source_file`）——入口；
2. **imports 表**——`@import("名字")` 能看到哪些模块；
3. **编译选项**——target / optimize / link_libc / single_threaded / strip / pic / sanitize_thread …

```zig
// examples/16_build/build.zig 第 57-70 行
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
```

`Module.CreateOptions` 完整字段（0.17 实测，共 24 个）：

```zig
pub const CreateOptions = struct {
    root_source_file: ?LazyPath = null,
    imports: []const Import = &.{},
    target: ?std.Build.ResolvedTarget = null,
    optimize: ?std.builtin.Optimize = null,
    link_libc: ?bool = null,
    link_libcpp: ?bool = null,
    single_threaded: ?bool = null,
    strip: ?bool = null,
    unwind_tables: ?std.builtin.UnwindTables = null,
    dwarf_format: ?std.dwarf.Format = null,
    code_model: std.builtin.CodeModel = .default,
    stack_protector: ?bool = null,
    stack_check: ?bool = null,
    sanitize_c: ?std.zig.SanitizeC = null,
    sanitize_thread: ?bool = null,
    fuzz: ?bool = null,
    valgrind: ?bool = null,
    pic: ?bool = null,
    red_zone: ?bool = null,
    omit_frame_pointer: ?bool = null,
    error_tracing: ?bool = null,
    no_builtin: ?bool = null,
    patchable_function_entry: u16 = 0,
};
```

程序侧对应地只用 `@import("名字")`，**没有相对路径**：

```zig
// examples/16_build/src/main.zig 第 8-11 行
// 三个具名模块：全部来自 build.zig 的 imports 表，不存在相对路径 @import。
const opts = @import("build_options"); // b.addOptions() 生成的模块
const lib = @import("build16_lib"); // b.createModule(.{ src/lib.zig })
const zmath = @import("zmath"); // b.dependency("zmath").module("zmath")
```

```text
=== 16.7 一个模块 = 根源文件 + imports + 选项 ===
  @import("build_options") → 类型 options
  @import("build16_lib")    → build16_lib
  @import("zmath")         → root
  三个名字都必须在 build.zig 的 imports 表里，否则编不过
--- 16.7 完毕 ---
```

（`@typeName` 显示成 `options` / `root` 是因为这两个模块的根源文件在各自目录里叫 `root.zig`，而 `build16_lib` 显式写了 `pub const module_name`。）

**imports 表不继承**，这是最容易漏的地方。16.16 的交叉编译 step 第一次就是漏了这个：

```text
$ zig build cross
cross
+- compile exe 16_build-aarch64-linux small aarch64-linux 1 errors
src/main.zig:9:22: error: no module named 'build_options' available within module 'root'
const opts = @import("build_options"); // b.addOptions() 生成的模块
                     ^~~~~~~~~~~~~~~
```

模块的 imports 是**逐模块声明**的，不是全工程可见。新建一个产物模块，就得把它需要的 imports 重挂一遍。

## 16.8 产物：三个文件、两种 add

### addExecutable

```zig
// examples/16_build/build.zig 第 81-88 行
// ── 16.8 产物：addExecutable ─────────────────────────────────────
// 0.17 签名：addExecutable(options: ExecutableOptions) *Step.Compile
// ExecutableOptions 只有 name / root_module 是必填，其余可选。
// （0.11 时代的 b.addExecutable("name", "root.zig") 两参数形式已不存在）
const exe = b.addExecutable(.{
    .name = "16_build",
    .root_module = main_mod,
});
```

`ExecutableOptions` 完整字段：`name`（必填）、`root_module`（必填）、`version` / `linkage` / `max_rss` / `use_llvm` / `use_lld` / `zig_lib_dir` / `win32_manifest`。

⚠️ **0.11 时代的两参数形式 `b.addExecutable("name", "root.zig")` 已经不行。** 0.12 之后统一成"一个 options 结构体"，而 `root.zig` 那个位置现在必须传 `*std.Build.Module`（不是路径）。

### addLibrary

```zig
// examples/16_build/build.zig 第 90-98 行
// ── 16.8 产物：addLibrary ────────────────────────────────────────
// 0.17 只有统一的 addLibrary，链接方式由 .linkage 决定（.static 默认 /
// .dynamic）。注意：addStaticLibrary / addSharedLibrary / installLibrary
// 在 0.17 已被移除，实测报 "no field or member function named …"。
const lib = b.addLibrary(.{
    .name = "build16",
    .linkage = .static,
    .root_module = lib_mod,
});
```

**这是 0.17 的一处 API 收敛**：三合一。`addLibrary(.{ .linkage = .static })` 等价于旧的 `addStaticLibrary`，`.linkage = .dynamic` 等价于 `addSharedLibrary`。旧的写法实测报错（三个都在 0.17 被删）：

```text
$ # 写 b.addStaticLibrary
build.zig:94:18: error: no field or member function named 'addStaticLibrary' in 'Build'
    const lib = b.addStaticLibrary(.{
                ~^~~~~~~~~~~~~~~~~
/Volumes/…/lib/std/Build.zig:1:1: note: struct declared here
const Build = @This();
^~~~~
build.zig:94:18: note: method invocation only supports up to one level of implicit pointer dereferencing
build.zig:94:18: note: use '.*' to dereference pointer
```

（`b.addSharedLibrary` 和 `b.installLibrary` 的报错是同一个形状，只是名字不同。）

`LibraryOptions` 比 `ExecutableOptions` 多的字段是 `win32_module_definition`；`linkage` 默认 `.static`。

### 第二个可执行文件

```zig
// examples/16_build/build.zig 第 100-113 行
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
```

`dep.module("zmath")` **只调用了一次**（build.zig 第 55 行），两个产物 import 的是同一个 `*Module` 实例，所以 zmath 的机器码只编一次，两份产物各自链接一份。共享 Module 实例是构建系统的"公共编译单元"机制——跟 C 里头文件只编译一次是完全同构的思路。

产物落地情况：

```bash
$ ls -R zig-out
zig-out:
bin  lib

zig-out/bin:
16_build  16_build_tool

zig-out/lib:
libbuild16.a
```

## 16.9 installArtifact 与 zig-out

```zig
// examples/16_build/build.zig 第 115-120 行
// ── 16.9 安装：installArtifact ────────────────────────────────────
// 挂到 install step 上（install 是默认 step，裸 `zig build` 就跑它）。
// 可执行文件进 zig-out/bin/，库进 zig-out/lib/。
b.installArtifact(exe);
b.installArtifact(lib);
b.installArtifact(tool);
```

`installArtifact` 做两件事：把产物**复制**（不是硬链接）到 `zig-out/` 对应目录，并往 install step 挂一条边。目录由产物类型自动决定：可执行文件 → `bin/`，库 → `lib/`（Windows 上库还会带 import lib）。

⚠️ **一个高频误解**：`run` step 跑的不是 `zig-out/bin/` 里的副本，而是 `.zig-cache/` 里的编译产物。两者内容相同但路径不同：

```text
=== 16.9 installArtifact 与 zig-out/ ===
  install step 是 default step，裸 `zig build` 就跑它
  但本 run step 跑的是缓存里的产物，所以 argv[0] 带 .zig-cache：
    ./.zig-cache/o/da2a24a78eef9d759fd5659e51201339/16_build
  它和 zig-out/bin/16_build 是同一个二进制，只是路径不同
--- 16.9 完毕 ---
```

为什么这样设计？因为 install 是**有副作用的写操作**，把 run step 挂在它下面会让"只想跑一下"变成"先复制一份到 zig-out"。构建系统故意让 run 直接跑缓存产物——省掉一次 I/O，也让 `run` 在 install 失败时依然能跑。

（需要顺序保证时再显式挂：`run_cmd.step.dependOn(b.getInstallStep());`）

## 16.10 传递命令行参数：addPassthruArgs

**这是照抄旧 build.zig 最容易撞的一条。** 0.17 移除了 `b.args`：

```text
$ # 写 _ = b.args;
build.zig:160:11: error: no field named 'args' in struct 'Build'
    _ = b.args;
          ^~~~
/Volumes/…/lib/std/Build.zig:1:1: note: struct declared here
const Build = @This();
^~~~~
```

0.17 的正确写法是三个方法，各管一段：

```zig
// examples/16_build/build.zig 第 122-136 行
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
```

| 方法 | 作用 |
|---|---|
| `addArg(x)` | 追加一个字面参数 |
| `addArgs(&.{a, b})` | 追加一批 |
| `addPassthruArgs()` | 把 `zig build run -- …` 的 `--` 之后部分**转发**给程序 |

⚠️ 不调 `addPassthruArgs()` **不报错**，只是参数被静默丢弃——这是它比 `b.args` 更隐蔽的地方。

程序侧用 `std.process.Args` 拿参数。⚠️ **0.17 的 args API 整体重写过**，`std.process.argsAlloc` 已移除：

```text
src/main.zig:4:82: error: root source file struct 'process' has no member named 'argsAlloc'
    std.debug.print("…", .{ std.process.argsAlloc(std.heap.page_allocator) … });
                                                     ~~~~~~~~~~~^~~~~~~~~~
/Volumes/…/lib/std/process.zig:1:1: note: struct declared here
const builtin = @import("builtin");
^~~~~
```

0.17 的新形态是**给 `main` 传一个 `std.process.Init` 参数**：

```zig
// examples/16_build/src/main.zig 第 26-34 行
/// main 收一个 `std.process.Init` 参数（0.17 起的新入口签名）。
/// 它自带 arena / gpa / io / args，比自己再造一遍强。
/// 也可以写 `pub fn main() !void`（无参），或 `pub fn main(init: std.process.Init.Minimal)`。
pub fn main(init: std.process.Init) !void {
    const a = init.arena.allocator();
    // init.minimal.args.toSlice 拿到全部命令行参数（含 argv[0]）。
    // 注意 argv[0] 是 .zig-cache 里的路径，不是 zig-out/bin/16_build——
    // 因为 run step 跑的是「编译产物」而不是「安装后的副本」。
    const argv = try init.minimal.args.toSlice(a);
```

`std.process.Init` 的字段（0.17）：

```zig
pub const Init = struct {
    minimal: Minimal,                  // { args: Args, environ: Environ }
    arena: *std.heap.ArenaAllocator,   // 进程级临时分配器，退出时统一释放
    gpa: Allocator,                    // Debug 模式下带泄漏检测
    io: Io,                            // 按目标配置选好的 Io 实现
    environ_map: *Environ.Map,
    preopens: Preopens,
};
```

⚠️ `std.process.Args` **没有 `init()` 方法**——它是个纯数据结构，`Iterator.init(args)` / `toSlice(arena)` 是它的方法。误写成 `std.process.Args.init()` 会得到：

```text
error: root source file struct 'process.Args' has no member named 'init'
    const args = try std.process.Args.init().toSlice(arena.allocator());
                     ~~~~~~~~~~~~~~~~^~~~~
```

实测输出：

```bash
$ zig build run
=== 16.10 addArg / addArgs / addPassthruArgs ===
  build.zig 写死了 3 个参数，再透传你在 -- 之后给的：
    argv[0] = ./.zig-cache/o/da2a24a78eef9d759fd5659e51201339/16_build
    argv[1] = --from-build-zig
    argv[2] = --label
    argv[3] = 16 章
  0.17 没有 b.args：不调 addPassthruArgs() 就只剩写死的那些
--- 16.10 完毕 ---

$ zig build run -- extra1
=== 16.10 addArg / addArgs / addPassthruArgs ===
  build.zig 写死了 3 个参数，再透传你在 -- 之后给的：
    argv[0] = ./.zig-cache/o/da2a24a78eef9d759fd5659e51201339/16_build
    argv[1] = --from-build-zig
    argv[2] = --label
    argv[3] = 16 章
    argv[4] = extra1
  0.17 没有 b.args：不调 addPassthruArgs() 就只剩写死的那些
--- 16.10 完毕 ---
```

## 16.11 把 -D 选项送进程序内部

构建选项要在程序里用，第一步是声明它：

```zig
// examples/16_build/build.zig 第 21-31 行
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
```

`b.option` 返回 `?T`（0.17 签名 `fn(b: *Build, comptime T: type, name, desc) ?T`），所以惯例是 `orelse` 给默认值。声明后 `zig build --help` 的 "Project-Specific Options" 段会自动多出一行 `-Dverbose=[bool]`。

`addOptions()` 的机制值得说清楚：它**生成一个真实的 .zig 文件**（落在 `.zig-cache/o/<hash>/options.zig`），内容大致是 `pub const verbose: bool = false;`，然后 `createModule()` 把它变成模块。所以 `@import("build_options")` 里的东西是**编译期常量**，`if (opts.verbose)` 会被完全优化掉——比运行时读环境变量强在**值进缓存键**：改了 `-Dverbose` 就必然重编，不会出现"改了选项但跑的还是旧二进制"。

`addOptions` 上还有 `addOptionPath` / `addOptionPathDirectory` / `addOptionPathUntracked`，用于把路径也送进去。

程序侧：

```zig
// examples/16_build/src/main.zig 第 141-153 行
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
```

```bash
$ zig build run
=== 16.11 -Dverbose 通过 addOptions 进到程序内部 ===
  opts.verbose = false（由 zig build -Dverbose=true 决定）
  → 没开 verbose，只打印第一个非 argv[0] 的参数
    --from-build-zig
--- 16.11 完毕 ---

$ zig build run -Dverbose
=== 16.11 -Dverbose 通过 addOptions 进到程序内部 ===
  opts.verbose = true（由 zig build -Dverbose=true 决定）
  → 开了 verbose，下面列出全部参数：
    [0] ./.zig-cache/o/a731e3ca437579e4ce97a8c593528336/16_build
    [1] --from-build-zig
    [2] --label
    [3] 16 章
--- 16.11 完毕 ---
```

## 16.12 同工程多模块：src/lib.zig

相对导入 vs 具名模块的区别，是这一节要说的：

```zig
// examples/16_build/build.zig 第 33-41 行
// ── 16.12 同工程多模块 ────────────────────────────────────────────
// src/lib.zig 不通过 @import("lib.zig") 相对导入，而是当成一个**具名模块**
// 挂进主模块的 imports 表。这样它有自己的 target/optimize 作用域，
// 也能被第二个可执行文件独立复用。
const lib_mod = b.createModule(.{
    .root_source_file = b.path("src/lib.zig"),
    .target = target,
    .optimize = optimize,
});
```

如果 main.zig 里写 `@import("lib.zig")`，lib.zig 就只是"main 目录里的另一个文件"——它跟着 main 的 target/optimize 走，没法被第二个产物复用，也没法单独给不同的编译选项。提升成独立模块后它有自己的作用域，还能直接当 `addLibrary` 的 root（16.8 那个 `.a` 就是它）。

```zig
// examples/16_build/src/lib.zig 第 12-42 行
/// 这个模块的自我标识（用它证明 @import 拿到的确实是 build16_lib）。
pub const module_name = "build16_lib";

/// 编译期版本：n 必须是编译期已知，返回哨兵切片，长度也是编译期常量。
/// 适合"分隔线""缩进"这类长度固定、调用点都写死字面量的场景。
pub fn dash_line(comptime n: usize) *const [n:0]u8 {
    comptime var buf: [n:0]u8 = undefined;
    inline for (0..n) |i| buf[i] = '-';
    return &buf;
}

/// 运行时版本：n 是普通参数，循环填 '-'。
/// 这里刻意用 `alloc` 而不是 `allocSentinel` —— 后者分配 n+1 字节
///（哨兵不计入切片长度），把它当 `[]u8` 交给 allocator.free() 会触发
/// testing.allocator 的 "free ... mismatches allocation" 报警。
/// comptime 参数 vs 运行时参数的区别见 13 章。
pub fn separator(allocator: std.mem.Allocator, n: usize) ![]u8 {
    const s = try allocator.alloc(u8, n);
    errdefer allocator.free(s);
    @memset(s, '-');
    return s;
}

/// 需要 0 结尾字符串时，在 separator 后面手工补一个哨兵位——
/// 这就是 06 章"哨兵切片"的用处：多分配一个字节换 strlen 能力。
pub fn separatorZ(allocator: std.mem.Allocator, n: usize) ![:0]u8 {
    const s = try allocator.allocSentinel(u8, n, 0);
    errdefer allocator.free(s[0..n :0]);
    @memset(s[0..n], '-');
    return s;
}
```

`separatorZ` 那段注释是本章唯一一处"构建系统无关"的坑，但值得留：我第一版写 `separator` 用 `allocSentinel` 然后返回哨兵切片让调用方 `a.free(s)`，`zig build test` 直接崩：

```text
test
+- run test 5 pass, 1 crash (6 total)
error: 'main.test.16.12 lib.separator 跨模块可用' terminated with signal ABRT with stderr:
       thread 1418872 panic: free of [addr: 10acfa010, len: 5 (0x5) align: 1] mismatches allocation of [addr: 10acfa010, len: 6 (0x6) align: 1]
       alloc:
       …/src/lib.zig:26:42: 0x10abe0157 in separator (test)
           const s = try allocator.allocSentinel(u8, n, 0);
                                                ^
```

`allocSentinel(u8, 5, 0)` 分配 **6** 字节，返回的切片 `.len == 5`，所以 free 时长度对不上。**带哨兵的切片不能当普通 `[]u8` 释放**——要么用 `alloc`/`free` 成对，要么 free 时写 `s[0..s.len :0]`。

程序侧输出：

```text
=== 16.12 src/lib.zig 作为独立模块 ===
  lib.module_name = build16_lib
  lib.separator(16) = ----------------（16 字节）
  它是独立模块，所以 lib_mod 被 addLibrary 装出的 .a 就是它
--- 16.12 完毕 ---
```

## 16.13 依赖管理：b.dependency 三层接线

路径依赖的接线分**三层**，缺一层都不行。

### 第一层：zon 里声明

```zig
// examples/16_build/build.zig.zon 第 19-21 行
    .dependencies = .{
        .zmath = .{ .path = "vendor/zmath" },
    },
```

`.dependencies` 的每个值可以是：
- `.{ .path = "vendor/zmath" }` —— 仓库内路径（**本例用这个**）；
- `.{ .url = "...", .hash = "..." }` —— 远端 tarball（需要联网）；
- `.{ .version = "1.2.3", .hash = "..." }` —— 从全局缓存按版本取。

远端依赖的 `.hash` 同样由工具链给：先写一个假的，`zig build` 会报错并把正确值给你。

### 第二层：b.dependency 拿 Dependency

```zig
// examples/16_build/build.zig 第 43-55 行
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
```

⚠️ **转发 target/optimize 不是可选的。** 子包也有自己的 `build(b: *std.Build)`，它内部照样会调 `b.standardTargetOptions(.{})`。你不转发，子包就看到"命令行上没给 -Dtarget"的默认值——用户编 aarch64，主包是 arm，子包还是 x86_64。**不报错，只是交叉编译悄悄错了。**

### 第三层：dep.module(name)

`dep.module(name)` 的 `name` 必须是**子包 build.zig 里 `b.addModule` 的第一个参数**，不是 zon 里的 key。子包长这样：

```zig
// examples/16_build/vendor/zmath/build.zig 第 1-17 行
//! 子包：a "vendor" 风格的路径依赖。
//! 它只通过 b.addModule 暴露一个具名模块，不产出任何可执行文件——
//! 这是库包最典型的形态：主工程 b.dependency("zmath", …).module("zmath") 取的就是它。
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // addModule("zmath", …) 的第一个参数是「模块名」，
    // 主工程 dep.module("zmath") 里的字符串必须和它一模一样。
    _ = b.addModule("zmath", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
}
```

我实测过：如果子包 `addModule("mathmod", …)` 而主包 `dep.module("zmath")`，会 panic（**不是**编译错误，是运行 build.zig 时 panic）：

```text
panic: unable to find module "zmath"
/Volumes/…/lib/std/Build.zig:1876:18: 0x10889dfe2 in module (configurer)
            panic("unable to find module {q}", .{name});
                 ^
/private/tmp/zigprobe/build.zig:4:19: 0x10889ddf9 in build (configurer)
    _ = dep.module("zmath");
                  ^~
```

名字写错时的报错没有源码位置（panic 里只有 build.zig 的行号），调试时容易迷路——第一反应应该是去子包 build.zig 看 `addModule` 的名字。

依赖名写错（zon 里没声明）则是另一个 panic：

```text
info: all dependencies used by build.zig must be declared in corresponding build.zig.zon
panic: no dependency named zmathx
/Volumes/…/lib/std/Build.zig:1907:35: 0x10f351998 in findPkgHashOrFatal (configurer)
    if (b.pkg_hash.len == 0) panic("no dependency named {s}", .{name});
                                  ^
```

第一行 `info:` 是有用的提示——它明确说了"要在对应的 build.zig.zon 里声明"。

### lazyDependency

`b.dependency` 会**立刻**要求依赖可用（没 fetch 就先 fetch 再重跑 build.zig）。`b.lazyDependency` 则允许"这次先不要"：

```zig
// examples/16_build/build.zig 第 186-215 行
// ── 16.15 自定义 step ③：deps ────────────────────────────────────
// 打印依赖树。lazyDependency 在依赖已 fetch 时返回非 null；
// 未 fetch 时返回 null 并把包登记为"懒依赖"，
// 下次重跑 build.zig 之前 runner 会先把它下载下来再重跑一次。
// 0.17 里 lazyDependency 已标注 Deprecated，新代码用 dependencyLazy。
const deps_step = b.step("deps", "打印依赖树");
const dep_lines: []const []const u8 = if (b.lazyDependency("zmath", .{
    .target = target,
    .optimize = optimize,
})) |dep| …;
```

实测存在性：**`b.lazyDependency` 在 0.17 存在，但源码注释是 `/// Deprecated in favor of `dependencyLazy`.`** 新代码应该用：

```zig
const dep = b.dependencyLazy("zmath", .{ .target = target, .optimize = optimize })
    catch |err| switch (err) {
        error.LazyDependencyNeeded => { /* 本次不需要，回去 null */ },
    };
```

三者的语义差别（读 `std/Build.zig:1936-2025` 源码确认）：

| API | 依赖不可用时的行为 |
|---|---|
| `b.dependency` | 序列化配置、退出，让 runner 下载后**重跑一遍 build.zig** |
| `b.lazyDependency` | 同上，但返回 `null`；函数本身标了 Deprecated |
| `b.dependencyLazy` | 返回 `error.LazyDependencyNeeded`，由你决定传播还是吞掉 |

实测：`b.lazyDependency` 在依赖已 fetch 时正常返回非 null（16.13 的 `deps` step 就能打出 `zmath -> src/root.zig`），所以本例两种写法都能跑。

### 共享依赖的产物

程序侧输出——同一份 zmath 被两个产物共享：

```text
=== 16.13 b.dependency 三层接线 ===
  第一层 build.zig.zon: .dependencies = .{ .zmath = .{ .path = "vendor/zmath" } }
  第二层 build.zig    : b.dependency("zmath", .{ .target, .optimize })
  第三层 build.zig    : dep.module("zmath")
  结果 —— 同一份子包代码被两个产物共享：
    zmath.triple(7)  = 21
    zmath.sum_to(10) = 55
    zmath.pi         = 3.14159
  版本信息也能带过来：dep 有 .version（子包 zon 的 .version）
--- 16.13 完毕 ---
```

第二个可执行文件 `zig build run-tool` 拿到的也是同一个模块：

```bash
$ zig build run-tool
16_build_tool：第二个可执行文件
  zmath.triple(7)  = 21
  zmath.sum_to(10) = 55
  zmath.pi         = 3.14159
```

## 16.14 把 C 混进来：addCSourceFiles

C 源文件当输入（**不是**头文件翻译，那是 17 章的事）：

```zig
// examples/16_build/build.zig 第 72-79 行
// ── 16.14 把 C 混进来 ────────────────────────────────────────────
// addCSourceFiles 把 .c 交给内置 clang 前端，与 Zig 一起链接。
// （头文件翻译是另一件事：0.17 起 @cImport 已移除，改 b.addTranslateC，见 17 章）
main_mod.addCSourceFiles(.{
    .root = b.path("csrc"),
    .files = &.{"helper.c"},
    .flags = &.{ "-I", "csrc" },
});
```

注意它挂在 **`Module`** 上（`main_mod.addCSourceFiles`）而不是 `b` 上——因为 C 源文件是模块的一部分，和 Zig 源文件平级。

```c
// examples/16_build/csrc/helper.c 第 1-9 行
/* 16 章的 C 侧：一个纯整数函数，故意不带任何 libc 依赖，
   这样不 link_libc 也能链接成功——证明 addCSourceFiles 走的是
   同一个编译单元列表，而不是"顺带帮你链了 libc"。 */
int build16_c_triple(int x) {
    return x * 3;
}

int build16_c_add(int a, int b) {
    return a + b;
}
```

Zig 侧手写 `extern` 声明（0.17 **没有 `@cImport` 了**，见 17 章）：

```zig
// examples/16_build/src/main.zig 第 13-16 行
// 16.14 addCSourceFiles 链进来的 C 函数。
// 这里必须手写 extern 声明——0.17 已经没有 @cImport 了（见 17 章）。
extern fn build16_c_triple(x: c_int) callconv(.c) c_int;
extern fn build16_c_add(a: c_int, b: c_int) callconv(.c) c_int;
```

⚠️ `callconv(.c)` 是小写 `c`——0.17 从 `.C` 改名了。

```text
=== 16.14 addCSourceFiles ===
  Zig 侧调 C 函数：build16_c_triple(7) = 21
  build16_c_add(20, 22)            = 42
  两侧同属一个编译单元列表，互相直接可见符号
  ⚠️ 头文件翻译（@cInclude）已经不在语言里了：0.17 用 b.addTranslateC，见 17 章
--- 16.14 完毕 ---
```

**`addTranslateC` 是什么？** 一句话：把整个 C 头文件翻译成 Zig 模块。0.17 起 `@cImport` / `@cInclude` 已被移除（实测 `error: invalid builtin function: '@cImport'`），头文件翻译必须由构建系统发起，产物是一个具名模块。完整用法（`tc.createModule()` + 挂进 imports）见 [17 章](17-c-interop.md) 的 17.2。

链系统库用 `module.linkSystemLibrary("ssl", .{})` / `module.linkLibrary(...)`。

## 16.15 自定义 step

`b.step(name, desc)` 在图里建一个**命名节点**。它自己什么都不做，纯粹靠 `dependOn` 挂别的 step——本质是个"用户可见的分组标签"。

```zig
// examples/16_build/build.zig 第 156-173 行
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
```

⚠️ **`b.step` 返回 `*Step`，不能当语句丢弃。** 实测：

```text
build.zig:192:11: error: value of type '*Build.Step' ignored
    b.step("deps2", "x");
    ~~~~~~^~~~~~~~~~~~~~
build.zig:192:11: note: all non-void values must be used
build.zig:192:11: note: to discard the value, assign it to '_'
```

```zig
// examples/16_build/build.zig 第 175-185 行
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
```

⚠️ 这个 `size` step 用 `sh -c`，**不是跨平台的**。Windows 上要换成 PowerShell 或 `cmd /c`。本教程的 `build.ps1` 只跑 `build test` / `build run`，所以不影响验证，但真要跨平台得处理。（`addSystemCommand` 接受任意 argv，不限于 Zig 程序。）

四个自定义 step 的实测输出：

```bash
$ zig build info
target   = x86_64-macos
optimize = debug
verbose  = false

$ zig build deps
build16 的模块依赖树：
  |- build_options   (b.addOptions() 生成的模块)
  |- build16_lib     -> src/lib.zig
  `- zmath           -> src/root.zig

$ zig build size
2280
2205078
2127608
```

`size` 的三行**顺序不固定**（2280 是 `.a`，另两行是 exe，每次跑可能换位置）——因为三条 step 之间没有依赖边，runner 并行跑。step 描述里那句"顺序不保证"就是这个意思。

`zig build --help` 会列出所有 step（见 16.2 开头）——**这是发现"这个工程支持哪些命令"的唯一入口**。

## 16.16 交叉编译在构建系统里怎么表达

答案是：**它什么都不用表达。** 交叉编译就是换一个 `-Dtarget=`：

```bash
zig build -Dtarget=aarch64-linux
zig build -Dtarget=x86_64-windows -Doptimize=ReleaseSmall
```

`src/main.zig` 里一行代码都不用改。这就是 Zig 交叉编译相对 CMake 的最大优势——CMake 需要 toolchain file、需要 `if(CMAKE_SYSTEM_NAME STREQUAL …)` 分支、每个依赖库都要单独搞一套。Zig 里 target 是编译的**一等参数**，被塞进 `Module`，编译器据此选后端。

想在构建系统里**一次编多个目标**，就是循环 + `resolveTargetQuery`：

```zig
// examples/16_build/build.zig 第 216-246 行
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
```

两个关键点：

- **`std.Target.Query.parse(.{ .arch_os_abi = triple })`** —— `"aarch64-linux"` 这种三段式字符串的解析入口。返回 `!Query`，失败时带诊断信息。
- **`b.resolveTargetQuery(q)`** —— 把 `Query` 落成完整 `Target`。⚠️ **0.17 的 `zigTriple` 要 allocator 了**：`target.result.zigTriple(gpa)` 和 `target.query.zigTriple(gpa)` 都是 `fn (…) Allocator.Error![]u8`，0.11 时代那个无参版本没有了。

不调 `installArtifact` 是故意的：交叉产物只编不装，留在 `.zig-cache` 里。`zig build cross` 实测无输出、退出码 0（两个目标都编成功了）。

⚠️ imports 表必须重挂（16.7 那个坑）。第一次写这个 step 时我漏了，报的就是 `no module named 'build_options' available within module 'root'`。

更完整的交叉编译（wasm、QEMU 里真跑起来、交叉编译 C）见 [18 交叉编译](18-cross.md)。

## 16.17 缓存：.zig-cache 与 zig-out

```
.zig-cache/     中间产物 + 编译产物，文件名带内容哈希
zig-out/        installArtifact 的落地结果
```

- **`.zig-cache/`**（本地缓存，`--cache-dir` 可改）：所有中间产物和最终二进制都在这，文件名形如 `.zig-cache/o/da2a24a78eef9d759fd5659e51201339/16_build`——`da2a24a7…` 是这个产物的**内容哈希**。内容变了哈希就变、目录就换，所以改一行代码不会污染旧产物。**删了会全量重编。**
- **全局缓存**（`--global-cache-dir`，默认 `~/.cache/zig`）：下载的依赖包、编译器的中间产物都在这，跨工程共享。
- **`zig-out/`**：install 的结果。**删了只要重跑 `zig build` 就能重新生成。**

```text
=== 16.17 .zig-cache 与 zig-out ===
  .zig-cache  = 中间产物 + 编译产物（哈希命名，删了会全量重编）
  zig-out/    = installArtifact 的落地结果（删了只要重跑 install）
  本次 run 的 argv[0] 就在 .zig-cache 里：./.zig-cache/o/da2a24a78eef9d759fd5659e51201339/16_build
  「删缓存不删产物」：rm -rf .zig-cache 后 zig build 会重新生成 zig-out
--- 16.17 完毕 ---
```

**"删缓存不删产物"实测**：

```bash
$ ls zig-out/bin
16_build
16_build_tool

$ rm -rf .zig-cache        # 只删缓存
$ ls zig-out/bin           # 产物还在
16_build
16_build_tool

$ zig build                # 重新生成 .zig-cache
$ ls zig-out/bin           # 产物被重新安装（内容相同）
16_build
16_build_tool
```

这个不对称是刻意的：`.zig-cache` 是**可再生的中间态**，`zig-out/` 是**交付物**。CI 上典型做法是两者都删（保证干净），本地调试只删 `.zig-cache`（保留上次编好的东西，省得重编）。

想看构建系统到底干了什么，加 `--verbose`；失败时它还会给出**失败的那条命令**，这是排查构建问题最有用的信息：

```text
error: 1 compilation errors
failed command: zig build-exe -cflags -I csrc -- csrc/helper.c -Odebug --dep build_options --dep build16_lib --dep zmath -Mroot=src/main.zig -Mbuild_options=.zig-cache/o/363ef4ddb4546f98556e5688f9075c41/options.zig -Odebug -Mbuild16_lib=src/lib.zig -Odebug -Mzmath=vendor/zmath/src/root.zig --cache-dir .zig-cache --global-cache-dir ~/.cache/zig --build-root . --name 16_build --zig-lib-dir … --listen=-

Build Summary: 5/8 steps succeeded (1 failed)
install transitive failure
+- install 16_build transitive failure
   +- compile exe 16_build debug native 1 errors
```

这条命令把 16.7 的模块模型完整摊开给你看了：三个 `--dep` 对应三个 imports，`-M<名字>=<文件>` 是模块声明，`--dep` 的顺序就是 `@import` 的可见性来源。

## 16.18 完整命令清单与验证

工程支持的全部命令，`zig build run` 的 16.18 节会把这份清单打出来：

```text
=== 16.18 这个工程支持的全部命令 ===
    zig build                    构建全部产物
    zig build run                       跑本程序
    zig build run -- x                  透传参数给本程序
    zig build run -Dverbose             构建期选项进程序
    zig build run-tool                  跑第二个可执行文件
    zig build test                      跑单元测试（成功时静默）
    zig build test-deps                 只跑依赖包的测试
    zig build info                      打印 target/optimize/verbose
    zig build size                      打印各产物字节数
    zig build deps                      打印模块依赖树
    zig build cross                     交叉编译两个目标
    zig build --help                    列出所有 step
    zig build uninstall                 清空 zig-out
--- 16.18 完毕 ---
```

手敲一遍也很快：

zig build                              # 装三个产物到 zig-out/
zig build run                          # 跑主程序
zig build run -- extra1                # 透传参数
zig build run -Dverbose                # 构建期选项进程序
zig build run-tool                     # 跑第二个可执行文件
zig build test                         # 跑单元测试
zig build test-deps                    # 只跑依赖包的测试
zig build info                         # 打印 target/optimize/verbose
zig build size                         # 打印产物字节数
zig build deps                         # 打印模块依赖树
zig build cross                        # 交叉编译 aarch64-linux / x86_64-windows
zig build --help                       # 列出所有 step
zig build uninstall                    # 清空 zig-out
```

`zig build test` 成功时**完全没有输出**（实测 exit 0，stdout 空）——这是 15 章讲过的"测试通过就安静"。失败时才有输出：

```text
test
+- run test 0 pass, 1 fail (1 total)
error: 'main.test.probe' failed:
       …/lib/std/testing.zig:584:14: 0x1004409bf in expect (test)
           if (!ok) return error.TestUnexpectedResult;
                    ^
       /private/tmp/zigprobe/src/main.zig:12:5: 0x100440a15 in test.probe (test)
           try @import("std").testing.expect(1 == 2);
           ^
failed command: ./.zig-cache/o/d309c498439078b61126ac790d5efec5/test --cache-dir=./.zig-cache --seed=0xaddb3ff --listen=-

Build Summary: 1/3 steps succeeded (1 failed); 0/1 tests passed (1 failed)
```

仓库的回归脚本对 build.zig 工程跑三条：`zig fmt --check .` → `zig build test` → `zig build run`。

### 0.17 Build API 实测签名表

以下签名全部来自 `/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Build.zig` 源码 + 实测验证：

| API | 0.17 签名 | 备注 |
|---|---|---|
| `standardTargetOptions` | `fn (b: *Build, args: StandardTargetOptionsArgs) ResolvedTarget` | 返回结构体，非指针 |
| `standardOptimizeOption` | `fn (b: *Build, options: StandardOptimizeOptionOptions) std.builtin.Optimize` | |
| `createModule` | `fn (b: *Build, options: Module.CreateOptions) *Module` | 24 个字段 |
| `addModule` | `fn (b: *Build, name: []const u8, options: Module.CreateOptions) *Module` | 供被依赖方导出模块 |
| `addExecutable` | `fn (b: *Build, options: ExecutableOptions) *Step.Compile` | 单结构体参数 |
| `addLibrary` | `fn (b: *Build, options: LibraryOptions) *Step.Compile` | `.linkage` 决定静态/动态 |
| `addObject` | `fn (b: *Build, options: ObjectOptions) *Step.Compile` | |
| `addTest` | `fn (b: *Build, options: TestOptions) *Step.Compile` | **只有 `root_module`**，且不运行 |
| `addRunArtifact` | `fn (b: *Build, exe: *Step.Compile) *Step.Run` | 不自动透传参数 |
| `addRunFile` | `fn (b: *Build, executable: LazyPath) *Step.Run` | |
| `addSystemCommand` | `fn (b: *Build, argv: []const []const u8) *Step.Run` | |
| `addTranslateC` | `fn (b: *Build, options: Step.TranslateC.Options) *Step.TranslateC` | 0.17 新增，替代 `@cImport` |
| `addOptions` | `fn (b: *Build) *Step.Options` | 生成 Zig 源文件 |
| `addWriteFile` | `fn (b: *Build, file_path: []const u8, data: []const u8) *Step.WriteFile` | |
| `addFmt` | `fn (b: *Build, options: Step.Fmt.Options) *Step.Fmt` | |
| `addFail` | `fn (b: *Build, error_msg: []const u8) *Step.Fail` | |
| `installArtifact` | `fn (b: *Build, artifact: *Step.Compile) void` | 返回 void |
| `addInstallArtifact` | `fn (b: *Build, …) *Step.InstallArtifact` | 可改安装目录 |
| `installFile` / `addInstallBinFile` / `addInstallLibFile` / `addInstallHeaderFile` | `fn (b: *Build, src, dest_rel_path) void` / 返回 `*Step.InstallFile` | |
| `step` | `fn (b: *Build, name: []const u8, description: []const u8) *Step` | **返回值不可丢弃** |
| `getInstallStep` | `fn (b: *Build) *Step` | |
| `path` | `fn (b: *Build, sub_path: []const u8) LazyPath` | |
| `pathList` / `pathJoin` / `pathResolve` | `fn (b: *Build, …) …` | |
| `resolveTargetQuery` | `fn (b: *Build, query: Target.Query) ResolvedTarget` | |
| `parseTargetQuery` | `fn (options: std.Target.Query.ParseOptions) error{ParseFailed}!std.Target.Query` | 静态方法，不收 b |
| `dependency` | `fn (b: *Build, name: []const u8, args: anytype) *Dependency` | |
| `lazyDependency` | `fn (b: *Build, name: []const u8, args: anytype) ?*Dependency` | **已 Deprecated** |
| `dependencyLazy` | `fn (b: *Build, name, args) error{LazyDependencyNeeded}!*Dependency` | lazyDependency 的继任者 |
| `dependencyFromBuildZig` | `fn (b: *Build, comptime build_zig: type, args: anytype) *Dependency` | |
| `lazyImport` | `fn (b: *Build, comptime asking_build_zig: type, comptime dep_name) ?type` | |
| `option` | `fn (b: *Build, comptime T: type, name: []const u8, desc: []const u8) ?T` | 返回可选 |
| `fmt` | `fn (b: *Build, comptime format: []const u8, args: anytype) []u8` | |

**`Dependency` 上：**

| API | 0.17 形状 |
|---|---|
| `module` | `fn (dep: *Dependency, name: []const u8) *Module` — 名字错则 **panic** |
| `path` | `fn (dep: *Dependency, name: []const u8) LazyPath` |
| `version` | 字段 `?std.SemanticVersion` |

**`Step.Run` 上（0.17 实测存在）：** `addArg` / `addArgs` / `addPassthruArgs` / `addFileArg` / `addPrefixedFileArg` / `addFileArg2` / `addArtifactArg` / `addPrefixedArtifactArg` / `addArtifactArg2` / `addFileContentArg` / `addOutputFileArg` / `addPrefixedOutputFileArg` / `addOutputDirectoryArg` / `addDirectoryArg` / `addDecoratedDirectoryArg` / `addDepFileOutputArg` / `setCwd` / `setEnvironmentVariable` / `removeEnvironmentVariable` / `getEnvMap` / `clearEnvironment` / `setStdIn` / `setPreopen` / `enableTestRunnerMode` / `enableProtocolMode` / `captureStdOut` / `captureStdErr` / `hasTermCheck` / `expectStdOutEqual` / `expectStdOutMatch` / `expectStdErrEqual` / `expectStdErrMatch` / `expectExitCode` / `addCheck`。

⚠️ **没有 `expectStdEqual`**（0.17 拆成 `expectStdOutEqual` + `expectStdErrEqual`）。

### 0.17 已移除 / 已改名的 API（照抄旧代码必撞）

| 旧写法 | 0.17 实测报错 |
|---|---|
| `b.args` | `error: no field named 'args' in struct 'Build'` |
| `b.addStaticLibrary` | `error: no field or member function named 'addStaticLibrary' in 'Build'` |
| `b.addSharedLibrary` | 同上（`'addSharedLibrary'`） |
| `b.installLibrary` | 同上（`'installLibrary'`） |
| `b.standardReleaseOptions()` | `error: no field or member function named 'standardReleaseOptions' in 'Build'` |
| `b.addExecutable("n","f.zig")` | `error: expected type '*Module', found …` |
| `b.addTest(.{ .root_source_file = … })` | `error: no field named 'root_source_file' in struct 'Build.TestOptions'` |
| `root_source_file = "src/x.zig"` | `error: expected type '?Build.LazyPath', found '*const [N:0]u8'` |
| `@cImport` / `@cInclude` | `error: invalid builtin function: '@cImport'` |
| `run.expectStdEqual(...)` | 已拆为 `expectStdOutEqual` / `expectStdErrEqual` |
| `target.result.zigTriple`（无参） | 现在要 `Allocator` 参数 |
| `std.process.argsAlloc(...)` | `error: root source file struct 'process' has no member named 'argsAlloc'` |
| `std.process.Args.init()` | `error: root source file struct 'process.Args' has no member named 'init'` |
| `builtin.mode == .Debug` | `error: no field named 'Debug' in enum 'lang.Optimize'`（应为 `.debug`） |
| `std.builtin.Abi` | `error: root source file struct 'lang' has no member named 'Abi'`（应为 `std.Target.Abi`） |
| `LazyPath.path` 字段 | `error: no field named 'path' in union 'Build.LazyPath'`（0.17 是联合体） |
| `{s}` 格式化 `LazyPath` | `error: invalid format string 's' for type 'Build.LazyPath'`（用 `{f}`） |
| `{s}` 格式化 `Target.Abi` | 同类错误（先 `@tagName` 或 `@as`） |

## 16.19 坑位清单

1. **`b.args` 在 0.17 已移除**。`run_cmd.addPassthruArgs()` 是唯一正确写法，否则 `zig build run -- x y` 里的 `x y` 被**静默丢弃**——不报错，只是参数没了。这是本章最难发现的坑之一，也是照抄 0.16 build.zig 时优先要查的一条。
2. **`addStaticLibrary` / `addSharedLibrary` / `installLibrary` 全部被移除**，合并成 `addLibrary(.{ .linkage = .static / .dynamic })`。`standardReleaseOptions()` 也没了，用 `standardOptimizeOption`。
3. **`addTest` 只接受 `root_module`**，没有 `root_source_file` / `target` / `optimize` 字段——这些都搬进 `Module.CreateOptions` 了。而且 **`addTest` 只编译不运行**，必须再包一层 `addRunArtifact`。
4. **`root_source_file` 必须传 `b.path(...)`，裸字符串编译不过**（`expected type '?Build.LazyPath'`）。
5. **`b.step()` 返回 `*Step`，当语句写会报 `value of type '*Build.Step' ignored`**。要么 `const s = b.step(...)`，要么 `_ = b.step(...)`。
6. **`dep.module(name)` 的 name 是子包 `addModule` 的参数，不是 zon 的 key**。写错的症状是 **panic**（不是编译错误）：`panic: unable to find module "…"`，且报错里只有 build.zig 的行号、没有源码位置。
7. **依赖必须先在 `build.zig.zon` 的 `.dependencies` 里声明**，否则 `panic: no dependency named …`（前面有一行 `info: all dependencies used by build.zig must be declared in corresponding build.zig.zon`）。
8. **`b.dependency` 必须转发 `target` / `optimize`**。漏转发时子包会拿到本机默认值，用户编 arm 结果子包还是 x86——**不报错，只是交叉编译悄悄错了**。
9. **模块的 imports 表不继承**。新建产物模块（尤其是循环里的交叉编译 step）必须重挂全部 imports，漏一个报 `error: no module named 'xxx' available within module 'root'`。
10. **`.fingerprint` 覆盖 name + version + paths 等几乎所有顶层字段**，fork 或改版本后必须换。工具链会在报错里给正确值，抄回去即可。**未知字段被静默忽略**（实测加 `.unknown_field = 1` 不报错），所以拼错字段名不会有任何提示。
11. **`.minimum_zig_version` 缺失不报错**（实测），但它是给依赖链用的——作为库作者必须写。
12. **步与步之间没有顺序保证**。想按顺序输出就得用一条命令（`sh -c 'printf …'`），不能挂多条 `echo` step——runner 会并行跑它们。`size` step 的三行输出顺序每次都不同，这是特性不是 bug。
13. **`run` step 跑的是 `.zig-cache` 里的产物，不是 `zig-out/bin/` 的副本**。所以 `argv[0]` 里带哈希路径，且在 `run` 里读相邻文件要用构建系统给的路径，不能假设 cwd。
14. **`b.fmt` 的结果不能和字面量 `++`**（编译期操作），要么整个塞进格式串，要么用运行时拼接。
15. **`LazyPath` 格式化用 `{f}` 不是 `{s}`**；而且它没有 `.path` 字段了（0.17 是联合体：`.src_path` / `.generated` / `.cwd_relative` / `.dependency` / `.relative`），`.cwd_relative` 变体本身已 Deprecated。
16. **`Target.Abi` 在 `std.Target` 不在 `std.builtin`**；`zigTriple` 方法现在要 `Allocator` 参数；`{s}` 不能直接格式化枚举，得先 `@tagName` / `@as`。
17. **0.17 的 `std.builtin.Optimize` 第一个成员是小写 `.debug`**，后三个仍是驼峰。写 `.Debug` 报 `no field named 'Debug'`。
18. **`std.process.argsAlloc` 已移除**，改成给 `main` 传 `std.process.Init` 参数，再用 `init.minimal.args.toSlice(init.arena.allocator())`。注意 `std.process.Args` 没有 `init()` 方法。
19. **`run.expectStdEqual` 已拆成 `expectStdOutEqual` / `expectStdErrEqual`**。
20. **`allocSentinel(u8, n, 0)` 分配 n+1 字节**，把返回的哨兵切片当 `[]u8` 交给 `allocator.free()` 会让 `zig build test` panic（`free of … len: 5 mismatches allocation of … len: 6`）。要么用 `alloc`/`free` 成对，要么 free 时写 `s[0..s.len :0]`。
21. **`@cImport` / `@cInclude` 在 0.17 已移除**（`invalid builtin function`），头文件翻译只能走 `b.addTranslateC`，见 [17 章](17-c-interop.md)。
22. **`zig build test` 成功时完全静默**（exit 0，stdout 空）——别以为它没跑。

---

上一章：[15 测试](15-testing.md) · 下一章：[17 C 互操作](17-c-interop.md)