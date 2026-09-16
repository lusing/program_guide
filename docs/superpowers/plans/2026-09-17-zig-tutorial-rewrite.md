# Zig 教程重写实施计划（2026-09-17）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 `zig/` 重写为对齐 cpp20 标准的 24 章教程（docs/ 分章 + 章号=示例号 + 递进讲解 + 坑位清单 + 三层编译验证 + 实战迷你 grep）。

**Architecture:** 先建 build.ps1 验证骨架，再按批次写 23 个示例（每示例含 main 演示 + test 自检块），随后按示例的 `═══` 分节标记撰写 24 章正文，最后清理旧文件、写 README/CHEATSheet、全量终验。

**Tech Stack:** Zig 0.16.0（`G:\scoop\apps\zig\current\zig.exe`）、PowerShell 7（pwsh）、git。

**Spec:** `docs/superpowers/specs/2026-09-17-zig-tutorial-rewrite-design.md`

## Global Constraints

- Zig 编译器固定用 `G:\scoop\apps\zig\current\zig.exe`（0.16.0）；所有代码必须在其上实测通过。
- 每个示例：`zig fmt --check` 通过 + `zig test` 全过 + `zig build-exe` 运行 exit 0（16/24 章用 `zig build test`/`zig build run`；17 章 `-lc`；18 章含交叉编译与 `zig cc`）。
- 章号 = 示例目录号：`docs/NN-topic.md` ↔ `examples/NN_topic/main.zig`（01 无示例；16/18/24 有多文件；18 含 hello.c + wasm_lib.zig）。
- 每章正文 150–250 行，特色章（11/12/13/14/15/16/17/18）不压缩；每章末尾"坑位清单"3–6 条。
- 示例代码用 `// ═══ N.M 标题 ═══` 分节标记，正文按小节号摘录/引用，保持文-码一致。
- build.ps1 为 pwsh 7 脚本、**UTF-8 无 BOM**（写后用 `xxd` 验证首字节不是 EF BB BF——BOM 会破 PowerShell 解析，这是既有教训）。
- 教程正文中文；代码注释中文为主；输出示例须来自真实运行结果。
- 提交信息末尾带 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。
- **0.16 API 不确定处**：计划内代码是最佳草案，执行时以实测为准修正代码与正文，并把偏差记录到文末"执行勘误"区（cpp20 流程）。

## 已实测的 0.16 API 基线（写作时直接采用）

| 用法 | 结论 |
|---|---|
| `pub fn main(init: std.process.Init)` | ✅ 可拿 `.io`/`.gpa`/`.arena`/`.minimal.args`/`.environ_map` |
| stdout | `var w = std.Io.File.stdout().writer(init.io, &buf); const out = &w.interface; try out.print(...); try out.flush();` |
| stderr | `std.debug.print(fmt, args)` 不变（无需 io） |
| ArrayList | unmanaged：`var l: std.ArrayList(T) = .empty; try l.append(alloc, x); defer l.deinit(alloc);` |
| HashMap | `std.AutoHashMap(K,V).init(alloc)`（managed 不变） |
| 原子/线程 | `std.atomic.Value(T)`、`std.Thread.spawn(.{}, fn, .{args})` |
| `@cImport` | 可用但必须 `-lc` |
| build.zig | `b.addExecutable(.{ .name, .root_module = b.createModule(...) })` 模式 |
| 坑 | Windows 下 `Init.minimal.args` 是 `[]const u16`；`std.fs.File` 已并入 `std.Io.File` |

---

### Task 1: build.ps1 重写（三层验证 + 工程特判 + 交叉编译特判）

**Files:**
- Create: `zig/build.ps1`（覆盖旧文件）

**Interfaces:**
- Produces: 后续所有任务的验证入口 `-All` / `-Example NN_topic` / `-Clean`；产物统一进 `zig/build/`。

- [x] **Step 1: 写 zig/build.ps1（UTF-8 无 BOM）**

```powershell
param(
    [switch]$All,
    [string]$Example,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$zigExe = "G:\scoop\apps\zig\current\zig.exe"
if (-not (Test-Path -LiteralPath $zigExe)) { throw "未找到 zig.exe：$zigExe" }
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$buildDir = Join-Path $projectRoot "build"
$examplesDir = Join-Path $projectRoot "examples"

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) { Remove-Item -LiteralPath $buildDir -Recurse -Force }
    Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    exit 0
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-Zig {
    param([string]$WorkingDir, [string[]]$ArgList)
    Push-Location $WorkingDir
    try {
        & $zigExe @ArgList
        if ($LASTEXITCODE -ne 0) { throw "命令失败: zig $($ArgList -join ' ') (cwd=$WorkingDir)" }
    } finally { Pop-Location }
}

function Invoke-Native {
    param([string]$ExePath)
    & $ExePath
    if ($LASTEXITCODE -ne 0) { throw "运行失败(退出码 $LASTEXITCODE): $ExePath" }
}

# 普通示例：fmt --check → test → build-exe → 运行
function Test-PlainExample {
    param([string]$Dir, [string[]]$ExtraArgs = @())
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name" -ForegroundColor Cyan
    Invoke-Zig $Dir (@("fmt", "--check", ".") + $ExtraArgs)
    Invoke-Zig $Dir (@("test", "main.zig") + $ExtraArgs)
    $exe = Join-Path $buildDir "$name.exe"
    Invoke-Zig $Dir (@("build-exe", "main.zig", "-femit-bin=$exe") + $ExtraArgs)
    Invoke-Native $exe
    Get-ChildItem -LiteralPath $Dir -Filter "*.pdb" -ErrorAction SilentlyContinue |
        Move-Item -Destination $buildDir -Force -ErrorAction SilentlyContinue
}

# build.zig 工程：fmt --check . → build test → build run
function Test-ProjectExample {
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name (build.zig 工程)" -ForegroundColor Cyan
    Invoke-Zig $Dir @("fmt", "--check", ".")
    Invoke-Zig $Dir @("build", "test")
    Invoke-Zig $Dir @("build", "run")
}

# 18_cross：本机三层 + 三目标交叉编译(编译即验证) + zig cc 编 C
function Test-CrossExample {
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    Write-Host "`n[Example] $name (交叉编译)" -ForegroundColor Cyan
    Invoke-Zig $Dir @("fmt", "--check", ".")
    Invoke-Zig $Dir @("test", "main.zig")
    $exe = Join-Path $buildDir "$name.exe"
    Invoke-Zig $Dir @("build-exe", "main.zig", "-femit-bin=$exe")
    Invoke-Native $exe
    Invoke-Zig $Dir @("build-exe", "main.zig", "-target", "aarch64-linux",
        "-femit-bin=$(Join-Path $buildDir "$name`_aarch64-linux")")
    Invoke-Zig $Dir @("build-exe", "wasm_lib.zig", "-target", "wasm32-freestanding", "--no-entry",
        "-femit-bin=$(Join-Path $buildDir "$name`.wasm")")
    Invoke-Zig $Dir @("cc", "hello.c", "-o", (Join-Path $buildDir "$name`_hello_c.exe"))
    Invoke-Native (Join-Path $buildDir "$name`_hello_c.exe")
}

function Test-One {
    param([string]$Dir)
    switch (Split-Path -Leaf $Dir) {
        "16_build" { Test-ProjectExample $Dir }
        "24_minigrep" { Test-ProjectExample $Dir }
        "17_cinterop" { Test-PlainExample $Dir @("-lc") }
        "18_cross" { Test-CrossExample $Dir }
        default { Test-PlainExample $Dir }
    }
}

if ($Example) {
    $dir = Join-Path $examplesDir $Example
    if (-not (Test-Path -LiteralPath $dir)) { throw "找不到示例目录: $dir" }
    Test-One $dir
    Write-Host "`n[Done] $Example 验证通过。" -ForegroundColor Green
    exit 0
}

if ($All) {
    Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name | ForEach-Object {
        Test-One $_.FullName
    }
    Write-Host "`n[Done] 全部示例三层验证通过。" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                验证 examples 下全部示例"
Write-Host "  .\build.ps1 -Example 12_collections   验证单个示例"
Write-Host "  .\build.ps1 -Clean               清理 build 目录"
```

- [x] **Step 2: 验证无 BOM + 语法**

Run: `xxd G:/code/guide/zig/build.ps1 | head -1`（首字节不得是 `efbb`）
Run: `pwsh -NoProfile -Command "G:/code/guide/zig/build.ps1"`（此时 examples/ 还是旧结构，打印用法即算通过）

- [x] **Step 3: Commit**

```bash
cd G:/code/guide && git add zig/build.ps1
git commit -m "build(zig): 重写 build.ps1——目录式示例三层验证 + 工程/交叉编译特判"
```

---

### Task 2: 示例 02_hello / 03_types / 04_control

**Files:**
- Create: `zig/examples/02_hello/main.zig`
- Create: `zig/examples/03_types/main.zig`
- Create: `zig/examples/04_control/main.zig`

**Interfaces:**
- Produces: 第 02/03/04 章引用代码（正文按 `═══` 小节号摘录）；02_hello 为 01 章引用对象。

- [x] **Step 1: 写 zig/examples/02_hello/main.zig**

```zig
//! 02 第一个程序：std.debug.print、stdout Writer、Init 入口、test 自检
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    // ═══ 2.1 std.debug.print：最省事的输出（stderr，立即落地）═══
    std.debug.print("你好，Zig 0.16！\n", .{});
    std.debug.print("编号 {d:0>3}，十六进制 {x}，二进制 {b}\n", .{ 7, 255, 10 });

    // ═══ 2.2 stdout：缓冲 Writer + flush（0.16 新接口，标准姿势）═══
    var buf: [256]u8 = undefined;
    var w = std.Io.File.stdout().writer(init.io, &buf);
    const out = &w.interface;
    try out.print("姓名：{s}，年龄：{d}\n", .{ "阿 Z", 25 });
    try out.print("PI ≈ {d:.2}\n", .{3.14159});
    try out.flush(); // 缓冲输出必须 flush，否则进程退出前可能丢尾部

    // ═══ 2.3 Init：main 的标准参数包（io/gpa/arena/args）═══
    std.debug.print("Init 字段就位：io={s} gpa={s}\n", .{
        @typeName(@TypeOf(init.io)),
        @typeName(@TypeOf(init.gpa)),
    });
    std.debug.print("自检通过\n", .{});
}

test "打印不是测试重点，先验证格式化语义" {
    const name = "阿 Z";
    try std.testing.expectEqualStrings("阿 Z", name);
    try std.testing.expectEqual(@as(u8, 7), 7);
}
```

- [x] **Step 2: 写 zig/examples/03_types/main.zig**

```zig
//! 03 基础类型：任意位宽整数、溢出运算符、comptime 整数、转型家族
const std = @import("std");

pub fn main() !void {
    // ═══ 3.1 const/var：不可变是默认，可变要申请 ═══
    const answer: u32 = 42; // const：赋值后不可改
    var count: i32 = 10; // var：可改（从不修改会编译错）
    count += 5;
    std.debug.print("answer={d} count={d}\n", .{ answer, count });

    // ═══ 3.2 任意位宽整数：u3、i128、usize ═══
    const small: u3 = 5; // 3 位无符号：只能装 0..7
    const wide: u128 = @as(u128, 1) << 100; // 128 位也内建
    const ptr_sized: usize = 1000; // 指针宽度，平台相关
    std.debug.print("u3={d} usize={d} u128>>100={d}\n", .{ small, ptr_sized, wide >> 100 });

    // ═══ 3.3 溢出运算符：+ 与 +% 的区别 ═══
    var byte: u8 = 255;
    // byte += 1;        // 编译可过，Debug 运行 panic：整数溢出（安全检查）
    byte +%= 1; // 环绕语义：255 → 0，永不出错
    var debt: i8 = -128;
    debt -%= 1; // 环绕：-128 → 127
    std.debug.print("255 +%= 1 → {d}；-128 -%= 1 → {d}\n", .{ byte, debt });

    // ═══ 3.4 comptime_int：没有类型的字面量 ═══
    const big = 123_456_789; // comptime_int：任意精度，用到时才定类型
    const hex = 0xFF; // 十六进制
    const oct = 0o77; // 八进制
    const bin = 0b1010; // 二进制
    std.debug.print("big={d} hex={d} oct={d} bin={d}\n", .{ big, hex, oct, bin });

    // ═══ 3.5 浮点与布尔 ═══
    const pi: f64 = 3.14159265358979;
    const half: f32 = 0.5;
    const flag: bool = true;
    std.debug.print("pi={d:.4} half={d} flag={}\n", .{ pi, half, flag });

    // ═══ 3.6 转型家族：每次转换都要点名 ═══
    const a: i32 = 300;
    const b = @as(u8, @truncate(a)); // 截断：只留低 8 位（300 → 44）
    const c = @as(u8, @intCast(a)); // 安全转型：越界会 panic（Debug/ReleaseSafe）
    const f = @as(i32, @intFromFloat(3.7)); // 浮→整：截断小数
    const g = @as(f64, @floatFrom(a)); // 整→浮
    std.debug.print("truncate={d} intCast={d} intFromFloat={d} floatFrom={d:.1}\n", .{ b, c, f, g });

    // ═══ 3.7 @bitCast：同宽 reinterpret ═══
    const u: u32 = 0x41424344;
    const raw: [4]u8 = @bitCast(u); // 逐字节看内存
    std.debug.print("0x{x:0>8} 的字节序：{d}\n", .{ u, raw });

    std.debug.print("自检通过\n", .{});
}

test "溢出与转型语义" {
    var x: u8 = 255;
    x +%= 1;
    try std.testing.expectEqual(@as(u8, 0), x);
    try std.testing.expectEqual(@as(u8, 44), @as(u8, @truncate(@as(i32, 300))));
    try std.testing.expectEqual(@as(u8, 4), 0b1010 & 0b0110);
}
```

- [x] **Step 3: 写 zig/examples/04_control/main.zig**

```zig
//! 04 控制流：if/while/for 的表达式语义、label、switch 穷尽与捕获
const std = @import("std");

fn gradeLabel(score: u8) []const u8 {
    // ═══ 4.1 if 是表达式：没有三元运算符 ?: ═══
    return if (score >= 90) "优秀" else if (score >= 60) "及格" else "不及格";
}

pub fn main() !void {
    // ═══ 4.1 if/else 表达式 ═══
    std.debug.print("85 → {s}，59 → {s}\n", .{ gradeLabel(85), gradeLabel(59) });

    // ═══ 4.2 while 与 continue 表达式 : (i += 1) ═══
    var i: usize = 0;
    var sum: usize = 0;
    while (i < 5) : (i += 1) {
        if (i == 2) continue; // 跳过 2，continue 表达式仍执行
        sum += i;
    }
    std.debug.print("sum(0..4 去 2) = {d}\n", .{sum}); // 0+1+3+4 = 8

    // ═══ 4.3 for：数组、范围、zip 多序列、带索引 ═══
    const names = [_][]const u8{ "C", "Zig", "Rust" };
    const years = [_]u16{ 1972, 2016, 2015 };
    for (names, years, 0..) |n, y, idx| { // 三序列并行迭代
        std.debug.print("[{d}] {s} 诞生于 {d}\n", .{ idx, n, y });
    }
    for (0..3) |k| std.debug.print("k={d} ", .{k});
    std.debug.print("\n", .{});

    // ═══ 4.4 label：从内层循环直接跳出外层 ═══
    outer: for (0..3) |row| {
        for (0..3) |col| {
            if (col == 2) continue :outer; // 直接进入外层下一轮
            if (row == 2) break :outer; // 直接终止外层
            std.debug.print("({d},{d}) ", .{ row, col });
        }
    }
    std.debug.print("\n", .{});

    // ═══ 4.5 switch：穷尽性检查是编译期保证 ═══
    for ([_]u8{ 3, 7, 20 }) |v| {
        const desc = switch (v) {
            1, 2, 3 => "低", // 多值并列
            4...9 => "中", // 范围
            10...99 => "高",
            else => "爆表", // 非穷尽类型必须 else
        };
        std.debug.print("{d}→{s} ", .{ v, desc });
    }
    std.debug.print("\n", .{});

    // ═══ 4.6 switch 也是表达式 + 捕获枚举负载（枚举见第 08 章）═══
    const Shape = union(enum) { circle: f64, rect: struct { w: f64, h: f64 } };
    const s = Shape{ .rect = .{ .w = 3, .h = 4 } };
    const area: f64 = switch (s) {
        .circle => |r| 3.14159 * r * r,
        .rect => |d| d.w * d.h,
    };
    std.debug.print("面积 = {d:.1}\n", .{area});

    // ═══ 4.7 labeled switch：状态机式 continue ═══
    const State = enum { start, running, done };
    var st: State = .start;
    var ticks: usize = 0;
    const total = sw: switch (st) {
        .start => {
            ticks += 1;
            st = .running;
            continue :sw .running; // 就地换分支继续
        },
        .running => {
            ticks += 1;
            st = .done;
            continue :sw .done;
        },
        .done => break :sw ticks,
    };
    std.debug.print("状态机走 {d} 步\n", .{total});

    std.debug.print("自检通过\n", .{});
}

test "控制流语义" {
    try std.testing.expectEqualStrings("及格", gradeLabel(70));
    var total: usize = 0;
    for (0..5) |i| total += i;
    try std.testing.expectEqual(@as(usize, 10), total);
    const d = switch (2) {
        1...2 => 100,
        else => 0,
    };
    try std.testing.expectEqual(@as(u32, 100), d);
}
```

- [x] **Step 4: 验证三个示例**

Run:
```bash
cd G:/code/guide/zig && pwsh -NoProfile -File build.ps1 -Example 02_hello && pwsh -NoProfile -File build.ps1 -Example 03_types && pwsh -NoProfile -File build.ps1 -Example 04_control
```
Expected: 三个示例 `[Done] ... 验证通过`；若 0.16 API 有出入（如 `{d:0>3}` 格式串），实测修正并记录勘误。

- [x] **Step 5: Commit**

```bash
cd G:/code/guide && git add zig/examples/02_hello zig/examples/03_types zig/examples/04_control
git commit -m "feat(zig): 示例 02_hello/03_types/04_control——打印、类型系统、控制流"
```

---
### Task 3: 示例 05_functions / 06_slices / 07_structs

**Files:**
- Create: `zig/examples/05_functions/main.zig`
- Create: `zig/examples/06_slices/main.zig`
- Create: `zig/examples/07_structs/main.zig`

**Interfaces:**
- Produces: 第 05/06/07 章引用代码。

- [x] **Step 1: 写 zig/examples/05_functions/main.zig**

```zig
//! 05 函数：defer、anytype、comptime 参数、没有重载怎么办
const std = @import("std");

// ═══ 5.1 基本形态：参数与返回类型显式写
fn add(a: i64, b: i64) i64 {
    return a + b;
}

// ═══ 5.2 defer：作用域退出时执行（LIFO 逆序）
fn deferDemo() void {
    std.debug.print("进入函数\n", .{});
    defer std.debug.print("defer A（先注册，最后跑）\n", .{});
    defer std.debug.print("defer B（后注册，先跑）\n", .{});
    {
        defer std.debug.print("块级 defer（出了块就跑）\n", .{});
        std.debug.print("块内\n", .{});
    }
    std.debug.print("函数体末尾\n", .{});
}

// ═══ 5.3 comptime 参数：让"重载"变成类型分派
fn maxOf(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}

// ═══ 5.4 anytype：编译期鸭子类型（print 的实现原理）
fn describe(value: anytype) void {
    const T = @TypeOf(value);
    std.debug.print("类型 {s}，值 {any}\n", .{ @typeName(T), value });
}

// ═══ 5.5 嵌套函数：可以定义，但不能捕获外层变量
fn outer(x: i64) i64 {
    fn square(v: i64) i64 { // 嵌套 fn 是独立函数，看不到 x
        return v * v;
    }
    return square(x) + square(x / 2);
}

pub fn main() !void {
    std.debug.print("add(3,4)={d}\n", .{add(3, 4)});
    deferDemo();

    // ═══ 5.6 没有重载：同名不同参直接编译错 → 用 comptime T / anytype 替代
    std.debug.print("max i32={d} f64={d:.1}\n", .{ maxOf(i32, 3, 9), maxOf(f64, 2.5, 1.5) });

    describe(42);
    describe(3.14);
    describe("字符串也行");
    describe(true);

    std.debug.print("outer(8)={d}\n", .{outer(8)});

    // ═══ 5.7 没有默认参数 → 用"参数结构体"惯用法
    const DrawOpts = struct {
        color: []const u8 = "黑",
        bold: bool = false,
    };
    const draw = struct {
        fn rect(opts: DrawOpts) void {
            std.debug.print("画矩形：{s}{}（参数结构体给默认值）\n", .{ opts.color, opts.bold });
        }
    };
    draw.rect(.{}); // 全默认
    draw.rect(.{ .color = "红", .bold = true }); // 覆盖个别

    std.debug.print("自检通过\n", .{});
}

test "函数语义" {
    try std.testing.expectEqual(@as(i64, 7), add(3, 4));
    try std.testing.expectEqual(@as(i32, 9), maxOf(i32, 3, 9));
    try std.testing.expectEqual(@as(f64, 2.5), maxOf(f64, 2.5, 1.5));
    try std.testing.expectEqual(@as(i64, 80), outer(8));
}
```

- [x] **Step 2: 写 zig/examples/06_slices/main.zig**

```zig
//! 06 数组、切片与字符串：长度进类型、胖指针、哨兵
const std = @import("std");

pub fn main() !void {
    // ═══ 6.1 数组 [N]T：长度是类型的一部分，本身是值
    const arr = [_]i32{ 10, 20, 30, 40, 50 }; // [_] 推断长度（也等价 [5]i32）
    var copy = arr; // 数组赋值 = 整块拷贝
    copy[0] = -1;
    std.debug.print("len={d} arr[0]={d} copy[0]={d}（赋值是拷贝）\n", .{ arr.len, arr[0], copy[0] });

    // ═══ 6.2 切片 []T：指针 + 长度的胖指针（借用的视图）
    const full: []const i32 = &arr; // 数组退化为切片
    const mid: []const i32 = arr[1..3]; // 子切片左闭右开：20, 30
    std.debug.print("full.len={d} mid=({d},{d})\n", .{ full.len, mid[0], mid[1] });
    // mid[9] —— 越界访问在 Debug/ReleaseSafe 下 panic（边界检查），正文演示

    // ═══ 6.3 字符串：没有 string 类型，就是字节切片
    const msg = "你好，Zig"; // 类型 *const [10:0]u8：UTF-8 + 末尾哨兵 0
    const s: []const u8 = msg; // 退化为切片
    std.debug.print("字节长度 {d}（UTF-8 中文每字 3 字节）\n", .{s.len});
    std.debug.print("前 3 字节：{d}（'你' 的 UTF-8 编码）\n", .{s[0..3]});

    // ═══ 6.4 哨兵切片 [:0]：保证末尾是 0，可直接交给 C
    const cz: [:0]const u8 = msg;
    std.debug.print("哨兵字节 s[len] = {d}（0 结尾，C 可直接用）\n", .{cz[cz.len]});

    // ═══ 6.5 三种指针：*T 单项 / [*]T 多项 / [*:0]T 哨兵多项
    var x: u32 = 42;
    const p: *u32 = &x; // 单项指针：解引用用 p.*
    p.* += 1;
    const many: [*]const i32 = &arr; // 多项指针：只有起点没有长度
    std.debug.print("*p={d} many[0]={d}\n", .{ p.*, many[0] });

    // ═══ 6.6 可变切片：[]u8 才能写
    var buf = [_]u8{ 'a', 'b', 'c', 'd' };
    const mut: []u8 = buf[0..];
    mut[0] = 'A';
    std.debug.print("改后：{s}\n", .{mut});
    // const s2: []const u8 = mut;   // 只读视图随时可以要
    std.debug.print("自检通过\n", .{});
}

test "数组切片语义" {
    const a = [_]i32{ 1, 2, 3, 4 };
    var total: i32 = 0;
    for (a) |v| total += v;
    try std.testing.expectEqual(@as(i32, 10), total);
    const s = a[1..3];
    try std.testing.expectEqual(@as(usize, 2), s.len);
    try std.testing.expectEqual(@as(i32, 2), s[0]);
    const lit = "hello";
    try std.testing.expectEqual(@as(usize, 5), lit.len);
    var b = [_]u8{ 1, 2 };
    const m: []u8 = &b;
    m[1] = 9;
    try std.testing.expectEqual(@as(u8, 9), b[1]);
}
```

- [x] **Step 3: 写 zig/examples/07_structs/main.zig**

```zig
//! 07 结构体：字段、方法、命名空间、匿名结构与元组
const std = @import("std");

// ═══ 7.1 定义：字段 + 默认值
const Point = struct {
    x: f64,
    y: f64 = 0, // 默认值

    // ═══ 7.2 方法：第一个参数 self（惯用名，不是关键字）
    fn dist(self: Point) f64 { // 值 self：只读
        return @sqrt(self.x * self.x + self.y * self.y);
    }
    fn translate(self: *Point, dx: f64, dy: f64) void { // 指针 self：可改字段
        self.x += dx;
        self.y += dy;
    }
};

// ═══ 7.3 类型即命名空间：关联常量 / 变量 / 函数
const Config = struct {
    const version = "1.0"; // 关联常量
    fn describe() []const u8 { // 无 self = 静态函数
        return "Config v" ++ version;
    }
};

// ═══ 7.7 惯用法：init / deinit 命名约定
const Session = struct {
    id: u32,

    fn init(id: u32) Session {
        return .{ .id = id };
    }
    fn deinit(self: *Session) void {
        self.* = undefined; // 惯例上抹掉内容
    }
};

pub fn main() !void {
    var p = Point{ .x = 3, .y = 4 }; // 缺省字段可省略
    std.debug.print("dist={d:.1}\n", .{p.dist()});
    p.translate(1, 1);
    std.debug.print("translate 后 x={d:.1} y={d:.1}\n", .{ p.x, p.y });
    const origin = Point{ .x = 0 }; // y 用默认值
    std.debug.print("origin=({d:.1},{d:.1})\n", .{ origin.x, origin.y });

    std.debug.print("{s}\n", .{Config.describe()});

    // ═══ 7.4 匿名 struct：字面量形态（.{} 的真身）
    const anon = .{ .name = "Zig", .born = 2016 };
    std.debug.print("anon: name={s} born={d}\n", .{ anon.name, anon.born });

    // ═══ 7.5 元组：匿名字段的结构体（编译期已知长度）
    const tup = .{ "Zig", 2016, true };
    std.debug.print("tup[0]={s} tup[1]={d} tup.len={d}\n", .{ tup[0], tup[1], tup.len });

    // ═══ 7.6 每个文件本身是一个 struct（本文件的 main/std 都是"字段"）
    var sess = Session.init(7);
    defer sess.deinit();
    std.debug.print("session id={d}\n", .{sess.id});

    std.debug.print("自检通过\n", .{});
}

test "结构体语义" {
    const pt = Point{ .x = 3, .y = 4 };
    try std.testing.expectEqual(@as(f64, 5), pt.dist());
    const o = Point{ .x = 1 };
    try std.testing.expectEqual(@as(f64, 0), o.y);
    const tup = .{ 1, 2 };
    try std.testing.expectEqual(@as(usize, 2), tup.len);
    try std.testing.expectEqual(@as(i32, 2), tup[1]);
}
```

- [x] **Step 4: 验证 + Commit**

Run:
```bash
cd G:/code/guide/zig && pwsh -NoProfile -File build.ps1 -Example 05_functions && pwsh -NoProfile -File build.ps1 -Example 06_slices && pwsh -NoProfile -File build.ps1 -Example 07_structs
```
Expected: 全部 `[Done]`。

```bash
cd G:/code/guide && git add zig/examples/05_functions zig/examples/06_slices zig/examples/07_structs
git commit -m "feat(zig): 示例 05_functions/06_slices/07_structs——defer、切片语义、结构体"
```

---

### Task 4: 示例 08_enums / 09_errors1 / 10_errors2

**Files:**
- Create: `zig/examples/08_enums/main.zig`
- Create: `zig/examples/09_errors1/main.zig`
- Create: `zig/examples/10_errors2/main.zig`

**Interfaces:**
- Produces: 第 08/09/10 章引用代码。

- [x] **Step 1: 写 zig/examples/08_enums/main.zig**

```zig
//! 08 枚举与联合：enum、tagged union、packed struct
const std = @import("std");

// ═══ 8.1 enum：封闭集合 + 方法
const Color = enum {
    red,
    green,
    blue,

    fn hex(self: Color) u32 {
        return switch (self) {
            .red => 0xFF0000,
            .green => 0x00FF00,
            .blue => 0x0000FF,
        };
    }
};

// ═══ 8.2 指定 tag 类型 + 非穷尽 `_`（与 C 枚举互操作）
const Level = enum(u8) {
    low = 10,
    mid = 50,
    high = 90,
    _, // 允许未知值进来
};

// ═══ 8.3 tagged union：安全的多选一（Zig 的代数数据类型）
const Value = union(enum) {
    int: i64,
    text: []const u8,
    list: []const f64,

    fn kind(self: Value) []const u8 {
        return switch (self) {
            .int => "整数",
            .text => "文本",
            .list => "列表",
        };
    }
};

// ═══ 8.5 packed struct：精确到位的内存布局
const Flags = packed struct {
    bold: bool = false, // 1 bit
    italic: bool = false, // 1 bit
    size: u6 = 0, // 6 bits —— 整体正好 1 字节
};

pub fn main() !void {
    const c = Color.green;
    std.debug.print("{s} = 0x{x:0>6}\n", .{ @tagName(c), c.hex() });

    const lv: Level = @enumFromInt(50);
    const unknown: Level = @enumFromInt(42); // 非穷尽：42 也能装
    std.debug.print("lv={s}({d})，未知值 {d} 也能装：{s}({d})\n", .{ @tagName(lv), @intFromEnum(lv), @intFromEnum(unknown), @tagName(unknown), @intFromEnum(unknown) });

    var v: Value = .{ .int = 42 }; // 推断：union 字面量
    std.debug.print("kind={s}\n", .{v.kind()});
    v = .{ .text = "hi" }; // 换标签 = 换形态
    std.debug.print("kind={s}，取值 {s}\n", .{ v.kind(), v.text });
    // 读错激活字段（如 v.int）→ Debug/ReleaseSafe 下 panic，正文演示

    // ═══ 8.4 switch 捕获负载：tagged union 的正确打开方式
    const w: Value = .{ .list = &.{ 1.5, 2.5, 3.5 } };
    switch (w) {
        .int => |i| std.debug.print("整数 {d}\n", .{i}),
        .text => |t| std.debug.print("文本 {s}\n", .{t}),
        .list => |ls| std.debug.print("列表 {d} 项：{d:.1}\n", .{ ls.len, ls[0] }),
    }

    // ═══ 8.5 packed struct（续）：整块位布局
    const f = Flags{ .bold = true, .size = 12 };
    const bits: u8 = @bitCast(f);
    std.debug.print("Flags 位布局 0b{b:0>8}（1 字节装 3 字段，bold 占 bit0）\n", .{bits});

    std.debug.print("自检通过\n", .{});
}

test "枚举与联合" {
    try std.testing.expectEqual(@as(u32, 0x00FF00), Color.green.hex());
    try std.testing.expectEqual(@as(u8, 50), @intFromEnum(Level.mid));
    const v: Value = .{ .int = 7 };
    try std.testing.expectEqualStrings("整数", v.kind());
    const got: i64 = switch (v) {
        .int => |i| i,
        else => 0,
    };
    try std.testing.expectEqual(@as(i64, 7), got);
    const f = Flags{ .italic = true };
    const bits: u8 = @bitCast(f);
    try std.testing.expectEqual(@as(u8, 0b10), bits);
}
```

- [x] **Step 2: 写 zig/examples/09_errors1/main.zig**

```zig
//! 09 可选类型与错误处理 I：?T、error set、!T、try/catch
const std = @import("std");

// ═══ 9.1 ?T：可能缺席的值（null 是类型，不是万恶空指针）
fn findFirst(hay: []const u8, needle: u8) ?usize {
    for (hay, 0..) |b, i| {
        if (b == needle) return i;
    }
    return null;
}

// ═══ 9.3 错误集合：编译期的"错误名字集合"
const ParseError = error{
    Empty,
    NotDigit,
    TooLong,
};

// ═══ 9.4 错误联合 !T：值，或者错误
fn parseScore(s: []const u8) ParseError!u8 {
    if (s.len == 0) return error.Empty;
    if (s.len > 3) return error.TooLong;
    var v: u16 = 0;
    for (s) |ch| {
        if (ch < '0' or ch > '9') return error.NotDigit;
        v = v * 10 + (ch - '0');
    }
    return @intCast(v);
}

// ═══ 9.5 try：出错就向上抛（catch |e| return e 的语法糖）
fn showScore(s: []const u8) ParseError!void {
    const score = try parseScore(s);
    std.debug.print("得分 {d}\n", .{score});
}

pub fn main() !void {
    // ═══ 9.2 解包三件套：if 捕获 / orelse / .?
    const idx = findFirst("zig-lang", '-');
    if (idx) |i| {
        std.debug.print("'-' 在下标 {d}\n", .{i});
    } else {
        std.debug.print("没找到\n", .{});
    }
    const fallback = findFirst("zig", '-') orelse 999; // 缺席给默认
    const sure = findFirst("zig", 'z').?; // 确信非 null（null 则 panic）
    std.debug.print("fallback={d} sure={d}\n", .{ fallback, sure });

    // ═══ 9.6 catch：就地处理（给后备值）
    const a = parseScore("88") catch 0;
    const b = parseScore("8x8") catch 0;
    std.debug.print("a={d} b={d}\n", .{ a, b });

    // ═══ 9.7 if/else 捕获错误：值或错误二选一
    if (parseScore("")) |v| {
        std.debug.print("值 {d}\n", .{v});
    } else |err| {
        std.debug.print("错误名：{s}\n", .{@errorName(err)});
    }

    // try 传播：showScore 自己不处理，抛给 main
    showScore("95") catch |err| std.debug.print("showScore 失败：{s}\n", .{@errorName(err)});
    showScore("95x") catch |err| std.debug.print("showScore 失败：{s}\n", .{@errorName(err)});

    // ═══ 9.8 推断错误集：签名只写 !T，集合编译器算
    const inferred = parseScore("1"); // ParseError!u8
    const val: u8 = try inferred;
    std.debug.print("inferred={d}；@TypeOf 见 test\n", .{val});
    std.debug.print("自检通过\n", .{});
}

test "可选与错误" {
    try std.testing.expectEqual(@as(?usize, 4), findFirst("zig-lang", '-'));
    try std.testing.expectEqual(@as(?usize, null), findFirst("zig", '-'));
    try std.testing.expectEqual(@as(u8, 88), try parseScore("88"));
    try std.testing.expectError(error.NotDigit, parseScore("8x"));
    try std.testing.expectError(error.Empty, parseScore(""));
    try std.testing.expectError(error.TooLong, parseScore("1234"));
    const E = ParseError; // 显式集合可做类型运算：ParseError || error{Boom}
    const Mixed = E || error{Boom};
    try std.testing.expectError(error.Boom, @as(Mixed!void, error.Boom));
}
```

- [x] **Step 3: 写 zig/examples/10_errors2/main.zig**

```zig
//! 10 错误处理 II：errdefer、?!T、panic、安全模式
const std = @import("std");

const Thing = struct { id: u32 };

// ═══ 10.1 errdefer：失败路径才执行的回滚
var made: usize = 0;
fn makeThing(gpa: std.mem.Allocator, id: u32) !*Thing {
    made += 1; // 副作用
    errdefer made -= 1; // 失败 → 回滚副作用
    const t = try gpa.create(Thing); // try 失败会先跑上面的 errdefer
    errdefer gpa.destroy(t); // 分配成功但后续失败 → 销毁
    t.* = .{ .id = id };
    return t;
}

// ═══ 10.2 分配-初始化模式：errdefer 管失败回滚，defer 管正常清理
fn buildList(gpa: std.mem.Allocator, n: usize) ![]u32 {
    const slice = try gpa.alloc(u32, n);
    errdefer gpa.free(slice); // 失败 → 释放
    for (slice, 0..) |*p, i| p.* = @intCast(i * 2);
    if (n > 8) return error.TooBig; // 这里失败，上面 errdefer 兜住
    return slice;
}

// ═══ 10.3 ?!T：可能缺席，也可能出错（先剥 null 再剥 error）
fn parseOpt(s: ?[]const u8) ?!u8 {
    const str = s orelse return null; // 缺席
    if (str.len == 0) return error.Empty;
    if (str[0] < '0' or str[0] > '9') return error.NotDigit;
    return str[0] - '0';
}

// ═══ 10.5 panic 与 unreachable：程序员的错，不是可恢复错误
fn mustPositive(x: i32) i32 {
    if (x <= 0) @panic("x 必须为正"); // 主动崩溃，带栈跟踪
    return x;
}

fn classify(x: u2) []const u8 {
    return switch (x) { // u2 只有 0..3，穷尽后 else 都不用写
        0 => "零",
        1 => "一",
        2 => "二",
        3 => unreachable, // 逻辑上到不了（编译器帮你信）
    };
}

pub fn main() !void {
    var da_state = std.heap.DebugAllocator(.{}){};
    defer {
        const st = da_state.deinit();
        std.debug.print("DebugAllocator 收尾：{s}（无泄漏）\n", .{@tagName(st)});
    }
    const gpa = da_state.allocator();

    // ═══ 10.1 演示：成功与失败两条路
    const t1 = try makeThing(gpa, 1);
    defer gpa.destroy(t1);
    if (makeThing(gpa, 99)) |t2| { // 这个会成功（made=2）
        defer gpa.destroy(t2);
        std.debug.print("made={d}\n", .{made});
    } else |e| return e;

    // ═══ 10.2 演示：失败路径内存被 errdefer 回滚，DebugAllocator 验证无泄漏
    if (buildList(gpa, 5)) |l| {
        defer gpa.free(l);
        std.debug.print("buildList(5)={d}\n", .{l});
    } else |err| {
        std.debug.print("buildList(16) 失败：{s}（内存已回滚）\n", .{@errorName(err)});
    }

    // ═══ 10.3 ?!T 解包顺序：orelse 先，catch 后
    const cases = [_]?[]const u8{ "7", null, "x", "" };
    for (cases) |cs| {
        const parsed = parseOpt(cs) orelse {
            std.debug.print("  缺席（null）\n", .{});
            continue;
        };
        const digit = parsed catch |e| {
            std.debug.print("  错误 {s}\n", .{@errorName(e)});
            continue;
        };
        std.debug.print("  数字 {d}\n", .{digit});
    }

    // ═══ 10.4 错误返回跟踪：Debug 模式下错误冒泡到顶会带完整来路（正文贴真实输出）
    std.debug.print("made 计数（失败两次都回滚了）={d}\n", .{made});

    // ═══ 10.5 panic/unreachable 正常路径
    std.debug.print("mustPositive(5)={d}，classify(2)={s}\n", .{ mustPositive(5), classify(2) });

    // ═══ 10.6 安全模式：Debug/ReleaseSafe 检查溢出/越界/坏指针（正文表格）
    // 若在函数内确信不会出问题，可关检查换性能：
    const fast = struct {
        fn addWrap(a: u8, b: u8) u8 {
            @setRuntimeSafety(false); // 本函数关闭运行期检查
            return a +% b; // 环绕加本就不查；关掉后 a + b 也不查
        }
    };
    std.debug.print("addWrap(200,100)={d}\n", .{fast.addWrap(200, 100)});

    std.debug.print("自检通过\n", .{});
}

test "errdefer 与组合错误" {
    const a = std.testing.allocator;
    const l = try buildList(a, 4);
    defer a.free(l);
    try std.testing.expectEqual(@as(u32, 6), l[3]);
    try std.testing.expectError(error.TooBig, buildList(a, 16));

    try std.testing.expectEqual(@as(u8, 7), try parseOpt("7"));
    try std.testing.expectEqual(@as(?u8, null), parseOpt(null));
    try std.testing.expectError(error.NotDigit, parseOpt("x"));
    const before = made;
    try std.testing.expectError(error.OutOfMemory, makeThing(std.testing.FailingAllocator, 1));
    // ↑ FailingAllocator 分配必失败：验证 errdefer 回滚 made
    try std.testing.expectEqual(before, made);
}
```

**注意**：`std.testing.FailingAllocator` 在 0.16 的形态未实测（可能是 `std.testing.FailingAllocator.init(alloc, 0)`），Step 4 验证时若编译不过，改为：手动构造一个 `fail alloc` 或删掉该断言并把 `made` 回滚验证改用 `buildList` 失败路径（记入勘误）。

- [x] **Step 4: 验证 + Commit**

Run:
```bash
cd G:/code/guide/zig && pwsh -NoProfile -File build.ps1 -Example 08_enums && pwsh -NoProfile -File build.ps1 -Example 09_errors1 && pwsh -NoProfile -File build.ps1 -Example 10_errors2
```
Expected: 全部 `[Done]`；`10_errors2` 的测试若因 FailingAllocator API 报错，按上文备注修正。

```bash
cd G:/code/guide && git add zig/examples/08_enums zig/examples/09_errors1 zig/examples/10_errors2
git commit -m "feat(zig): 示例 08_enums/09_errors1/10_errors2——枚举联合、可选、错误处理"
```

---

### Task 5: 示例 11_allocators / 12_collections（⭐ 特色重点）

**Files:**
- Create: `zig/examples/11_allocators/main.zig`
- Create: `zig/examples/12_collections/main.zig`

**Interfaces:**
- Produces: 第 11/12 章引用代码；后续章节沿用 `DebugAllocator(.{}){}`/`ArenaAllocator` 模式。

- [x] **Step 1: 写 zig/examples/11_allocators/main.zig**

```zig
//! 11 分配器：显式传递的内存策略（Zig 核心特色）
const std = @import("std");

// ═══ 11.7 惯用法：分配器是第一个参数（谁调用谁负责内存）
fn dupString(allocator: std.mem.Allocator, s: []const u8) ![]u8 {
    return allocator.dupe(u8, s);
}

// ═══ 11.4 Arena 场景：解析一批数据，统一回收
fn parseLine(arena: std.mem.Allocator, line: []const u8) ![]const []const u8 {
    var parts: std.ArrayList([]const u8) = .empty;
    var it = std.mem.tokenizeSequence(u8, line, " ,");
    while (it.next()) |tok| {
        try parts.append(arena, try arena.dupe(u8, tok)); // 中间产物全挂 arena
    }
    return parts.toOwnedSlice(arena);
}

pub fn main() !void {
    // ═══ 11.1 栈优先：长度已知的小东西不碰堆
    var buf: [64]u8 = undefined;
    @memset(&buf, 'A');
    std.debug.print("栈上 64 字节：{s}...\n", .{buf[0..8]});

    // ═══ 11.2 page_allocator：直接向 OS 要页（最底层，每次分配整页开销）
    {
        const page = std.heap.page_allocator;
        const big = try page.alloc(u32, 1_000_000);
        defer page.free(big);
        std.debug.print("page_allocator：{d} 万 u32 = {d} MB\n", .{ big.len / 10000, big.len * 4 >> 20 });
    }

    // ═══ 11.3 DebugAllocator（旧名 GPA）：带泄漏检测的调试堆
    {
        var da = std.heap.DebugAllocator(.{}){};
        defer {
            const st = da.deinit(); // 收尾检查：有泄漏返回 .leak
            std.debug.print("DebugAllocator 收尾：{s}\n", .{@tagName(st)});
        }
        const gpa = da.allocator();
        const msg = try dupString(gpa, "分配器显式传递");
        defer gpa.free(msg);
        std.debug.print("dup 出来：{s}\n", .{msg});
    }

    // ═══ 11.4 Arena：一次 init，批量分配，deinit 统一回收
    {
        var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena_state.deinit(); // ← 所有 arena 分配在这里一次性归还
        const arena = arena_state.allocator();
        const words = try parseLine(arena, "the quick brown fox");
        std.debug.print("arena 切了 {d} 段：", .{words.len});
        for (words) |wd| std.debug.print("{s}/", .{wd});
        std.debug.print("\n", .{});
    }

    // ═══ 11.5 FixedBuffer：拿一块缓冲当堆（嵌入式/热路径/无堆环境）
    {
        var backing: [128]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&backing);
        const f = fba.allocator();
        _ = try f.alloc(u8, 50);
        _ = try f.alloc(u8, 50);
        if (f.alloc(u8, 50)) |_| {
            unreachable;
        } else |err| {
            std.debug.print("第三次分配按预期失败：{s}（缓冲只有 128）\n", .{@errorName(err)});
        }
        fba.reset(); // 归零复用
        const again = try f.alloc(u8, 100);
        std.debug.print("reset 后又能分 {d} 字节（无需逐个 free）\n", .{again.len});
    }

    // ═══ 11.6 smp_allocator：多线程/发布版的系统级选择
    {
        const smp = std.heap.smp_allocator;
        const block = try smp.alloc(u64, 100);
        defer smp.free(block);
        std.debug.print("smp_allocator：{d} 字节\n", .{block.len * 8});
    }

    std.debug.print("自检通过\n", .{});
}

test "分配器语义" {
    const a = std.testing.allocator; // 泄漏 = 测试失败（15 章细讲）
    const s = try dupString(a, "abc");
    defer a.free(s);
    try std.testing.expectEqualStrings("abc", s);

    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const words = try parseLine(arena_state.allocator(), "a b c");
    try std.testing.expectEqual(@as(usize, 3), words.len);
    try std.testing.expectEqualStrings("quick", words[1]);
}
```

- [x] **Step 2: 写 zig/examples/12_collections/main.zig**

```zig
//! 12 集合类型：ArrayList（unmanaged）、HashMap、排序
const std = @import("std");

fn lessThan(_: void, a: u32, b: u32) bool {
    return a < b;
}

pub fn main() !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const mem = arena_state.allocator();

    // ═══ 12.1 ArrayList：unmanaged 风格（0.14+ 的唯一形态）
    var list: std.ArrayList(u32) = .empty;
    defer list.deinit(mem);
    try list.appendSlice(mem, &.{ 5, 3, 9, 1, 7 });
    try list.append(mem, 2);
    try list.insert(mem, 0, 100); // 指定位置插入
    std.debug.print("list：{d}（len={d}）\n", .{ list.items, list.items.len });
    const popped = list.pop(); // 弹出末尾
    _ = list.orderedRemove(0); // 有序删（保序搬移）
    std.debug.print("pop={d}，删首后：{d}\n", .{ popped, list.items });

    // ═══ 12.2 容量与 toOwnedSlice：把堆管理权交出去
    try list.ensureTotalCapacity(mem, 32);
    std.debug.print("capacity（已确保 ≥32）：{d}\n", .{list.capacity});
    const owned = try list.toOwnedSlice(mem); // list 变空；owned 归调用者
    defer mem.free(owned);
    std.debug.print("owned：{d}\n", .{owned});

    // ═══ 12.3 AutoHashMap：按键类型自动选哈希与相等
    var map = std.AutoHashMap(u32, []const u8).init(mem);
    defer map.deinit();
    try map.put(1, "一");
    try map.put(2, "二");
    const gop = try map.getOrPut(3); // 拿槽位自己决定插不插
    if (!gop.found_existing) gop.value_ptr.* = "三";
    std.debug.print("map[2]={s}，count={d}，含 1？{}\n", .{ map.get(2).?, map.count(), map.contains(1) });
    _ = map.remove(1);
    std.debug.print("删 1 后 count={d}\n", .{map.count()});

    // ═══ 12.4 StringHashMap：字符串按内容哈希（不是按地址）
    var colors = std.StringHashMap(u32).init(mem);
    defer colors.deinit();
    try colors.put("red", 0xFF0000);
    try colors.put("blue", 0x0000FF);
    std.debug.print("red=0x{x:0>6} blue=0x{x:0>6}\n", .{ colors.get("red").?, colors.get("blue").? });
    var it = colors.iterator(); // 迭代（顺序不保证）
    while (it.next()) |e| {
        std.debug.print("  {s} → 0x{x:0>6}\n", .{ e.key_ptr.*, e.value_ptr.* });
    }
    if (colors.fetchRemove("red")) |rm| { // 删除并取走键值
        std.debug.print("fetchRemove 拿走：{s} → 0x{x:0>6}\n", .{ rm.key, rm.value });
    }

    // ═══ 12.5 排序：std.mem.sort（pdq 家族，ctx 带比较上下文）
    var nums = [_]u32{ 42, 7, 19, 3, 88, 23 };
    std.mem.sort(u32, &nums, {}, lessThan);
    std.debug.print("升序：{d}\n", .{nums});

    // ═══ 12.6 选型速查（正文表格）：数组 / ArrayList / BoundedArray / AutoHashMap / StringHashMap / ArrayHashMap
    var bounded = std.BoundedArray(u8, 4){};
    try bounded.append('z');
    try bounded.append('i');
    try bounded.append('g');
    std.debug.print("BoundedArray（栈上定容）：{s}\n", .{bounded.slice()});

    std.debug.print("自检通过\n", .{});
}

test "集合操作" {
    const a = std.testing.allocator;
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(a);
    try list.appendSlice(a, "zig");
    try list.append(a, '!');
    try std.testing.expectEqualStrings("zig!", list.items);
    try std.testing.expectEqual(@as(u8, '!'), list.pop());

    var map = std.AutoHashMap(u8, u8).init(a);
    defer map.deinit();
    try map.put(1, 100);
    try std.testing.expectEqual(@as(u8, 100), map.get(1).?);
    try std.testing.expect(!map.contains(2));

    var arr = [_]u32{ 3, 1, 2 };
    std.mem.sort(u32, &arr, {}, lessThan);
    try std.testing.expectEqualSlices(u32, &.{ 1, 2, 3 }, &arr);
}
```

**注意**：`std.BoundedArray(u8, 4){}` 初始化形态与 `bounded.slice()`/`append` 签名未实测（0.16 可能要求 `.{ .buffer = undefined, .len = 0 }` 或提供 `.empty`），Step 3 验证时修正；不行就换 `std.ArrayList` + 预分配对比（记入勘误）。

- [x] **Step 3: 验证 + Commit**

Run:
```bash
cd G:/code/guide/zig && pwsh -NoProfile -File build.ps1 -Example 11_allocators && pwsh -NoProfile -File build.ps1 -Example 12_collections
```
Expected: `[Done]`；`DebugAllocator 收尾：ok` 字样出现。

```bash
cd G:/code/guide && git add zig/examples/11_allocators zig/examples/12_collections
git commit -m "feat(zig): 示例 11_allocators/12_collections——分配器家族、集合类型"
```

---

### Task 6: 示例 13_comptime / 14_generics（⭐ 特色重点）

**Files:**
- Create: `zig/examples/13_comptime/main.zig`
- Create: `zig/examples/14_generics/main.zig`

**Interfaces:**
- Produces: 第 13/14 章引用代码。

- [x] **Step 1: 写 zig/examples/13_comptime/main.zig**

```zig
//! 13 comptime I：编译期求值——同一份代码的两个世界
const std = @import("std");

// ═══ 13.1 普通函数 + const 实参 = 编译期算完
fn fibonacci(n: usize) usize {
    if (n < 2) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}
const fib10 = fibonacci(10); // 55：const 初始化必须编译期可得 → 在编译期算

// ═══ 13.2 comptime 参数：参数本身必须编译期已知（泛型基石）
fn pow(comptime base: u64, comptime exp: u32) u64 {
    return std.math.pow(u64, base, exp);
}
const kib = pow(2, 10); // 1024

// ═══ 13.7 编译期断言：构建期就爆错（不用等运行）
comptime {
    if (fib10 != 55) @compileError("fibonacci 算错了");
}

pub fn main() !void {
    // ═══ 13.1 同一函数，运行期也能调（一份代码两个世界）
    var n: usize = 20; // 假装来自运行期输入
    n += 1;
    std.debug.print("fib(10) 编译期={d}，fib(21) 运行期={d}\n", .{ fib10, fibonacci(n) });

    // ═══ 13.3 comptime 块：整块在编译期执行
    const table = comptime blk: {
        @setEvalBranchQuota(10000); // 编译期循环配额（防 DoS，超了要申请）
        var t: [16]u16 = undefined;
        for (0..16) |i| t[i] = i * i;
        break :blk t;
    };
    std.debug.print("平方表：{d}\n", .{table});

    // ═══ 13.4 comptime var：编译期的"变量"（while 也要配额）
    const checksum = comptime blk: {
        @setEvalBranchQuota(100000);
        var acc: u32 = 0;
        var i: usize = 0;
        while (i < 1000) : (i += 1) acc +%= @intCast(i);
        break :blk acc;
    };
    std.debug.print("0..999 求和（编译期）= {d}\n", .{checksum});

    // ═══ 13.5 inline for：编译期展开循环（序列须编译期已知）
    inline for (.{ "alpha", "beta", "gamma" }) |name, i| {
        std.debug.print("inline 展开[{d}] {s}\n", .{ i, name });
    }

    // ═══ 13.6 编译期内省一眼（@sizeOf 等本身就是 comptime）
    comptime std.debug.assert(@sizeOf(u64) == 8);
    std.debug.print("Kib={d}，自检通过\n", .{kib});
}

test "comptime 与运行期同源" {
    try std.testing.expectEqual(@as(usize, 55), fibonacci(10));
    try std.testing.expectEqual(@as(u64, 1024), kib);
    try std.testing.expectEqual(@as(u16, 9), table[3]);
    try std.testing.expectEqual(@as(u32, 499500), checksum);
}
```

- [x] **Step 2: 写 zig/examples/14_generics/main.zig**

```zig
//! 14 comptime II 泛型：type 参数、@typeInfo 反射、编译期代码生成
const std = @import("std");

// ═══ 14.1 类型构造器：函数返回 type（矩阵 = 三维数组）
fn Matrix(comptime T: type, comptime rows: usize, comptime cols: usize) type {
    return [rows][cols]T;
}

// ═══ 14.2 泛型容器：Stack(T)——内部 ArrayList，分配器显式传
fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();

        items: std.ArrayList(T) = .empty,

        pub fn push(self: *Self, allocator: std.mem.Allocator, v: T) !void {
            try self.items.append(allocator, v);
        }
        pub fn pop(self: *Self) ?T {
            if (self.items.items.len == 0) return null;
            return self.items.pop();
        }
        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            self.items.deinit(allocator);
        }
    };
}

// ═══ 14.3 anytype：编译期鸭子类型（std.debug.print 的实现原理）
fn sumAll(values: anytype) i64 {
    var total: i64 = 0;
    for (values) |v| total += @intCast(v);
    return total;
}

// ═══ 14.4 @typeInfo 反射：遍历结构体字段（serde/ORM 的地基）
const Person = struct {
    name: []const u8,
    age: u8,
    vip: bool,
};

fn dumpFields(comptime T: type) void {
    inline for (@typeInfo(T).@"struct".fields) |f| {
        std.debug.print("  {s}: {s}\n", .{ f.name, @typeName(f.type) });
    }
}

// ═══ 14.6 编译期代码生成：按类型生成分支
fn printAny(value: anytype) void {
    const info = @typeInfo(@TypeOf(value));
    switch (info) {
        .@"struct" => |s| inline for (s.fields) |f| {
            std.debug.print("  {s} = {any}\n", .{ f.name, @field(value, f.name) });
        },
        else => std.debug.print("  {any}\n", .{value}),
    }
}

pub fn main() !void {
    // 14.1 类型构造器
    const grid = Matrix(u8, 2, 3){ .{ 1, 2, 3 }, .{ 4, 5, 6 } };
    std.debug.print("2x3 矩阵 [1][2]={d}\n", .{grid[1][2]});

    // 14.2 泛型容器
    var stack = Stack(u32){};
    defer stack.deinit(std.heap.page_allocator);
    try stack.push(std.heap.page_allocator, 10);
    try stack.push(std.heap.page_allocator, 20);
    std.debug.print("pop：{d} {d} {any}\n", .{ stack.pop().?, stack.pop().?, stack.pop() });

    // 14.3 anytype
    const ints = [_]i32{ 1, 2, 3 };
    const bytes = [_]u8{ 4, 5 };
    std.debug.print("sumAll：{d} {d}\n", .{ sumAll(&ints), sumAll(&bytes) });

    // 14.4 反射
    std.debug.print("Person 的字段：\n", .{});
    dumpFields(Person);

    // 14.5 @field：按编译期名字读写
    var p = Person{ .name = "阿 Z", .age = 25, .vip = true };
    const field_name = comptime "age";
    @field(p, field_name) = 26; // 等价 p.age = 26，但名字可以是编译期变量
    std.debug.print("{s} {d} 岁 vip={}\n", .{ p.name, @field(p, field_name), p.vip });

    // 14.6 代码生成
    std.debug.print("printAny(Person)：\n", .{});
    printAny(p);

    std.debug.print("自检通过\n", .{});
}

test "泛型与反射" {
    var s = Stack(u8){};
    defer s.deinit(std.testing.allocator);
    try s.push(std.testing.allocator, 'a');
    try s.push(std.testing.allocator, 'b');
    try std.testing.expectEqual(@as(u8, 'b'), s.pop().?);
    try std.testing.expectEqual(@as(u8, 'a'), s.pop().?);
    try std.testing.expectEqual(@as(?u8, null), s.pop());

    const i64s = [_]i64{ 10, 20 };
    try std.testing.expectEqual(@as(i64, 30), sumAll(&i64s));

    var p = Person{ .name = "x", .age = 1, .vip = false };
    @field(p, "vip") = true;
    try std.testing.expect(p.vip);
}
```

- [x] **Step 3: 验证 + Commit**

Run:
```bash
cd G:/code/guide/zig && pwsh -NoProfile -File build.ps1 -Example 13_comptime && pwsh -NoProfile -File build.ps1 -Example 14_generics
```
Expected: `[Done]`；若 `@setEvalBranchQuota` 配额不足报错，调大数值（记入勘误）。

```bash
cd G:/code/guide && git add zig/examples/13_comptime zig/examples/14_generics
git commit -m "feat(zig): 示例 13_comptime/14_generics——编译期求值、泛型与反射"
```

---
### Task 7: 示例 15_testing / 16_build（⭐ 工程首例）

**Files:**
- Create: `zig/examples/15_testing/main.zig`
- Create: `zig/examples/15_testing/util.zig`
- Create: `zig/examples/16_build/build.zig`
- Create: `zig/examples/16_build/build.zig.zon`
- Create: `zig/examples/16_build/src/main.zig`
- Create: `zig/examples/16_build/src/greet.zig`

**Interfaces:**
- Produces: 第 15/16 章引用代码；16_build 是首个 build.zig 工程（build.ps1 走 `zig build test/run` 分支）。

- [x] **Step 1: 先跑 `zig init` 拿官方 0.16 模板（校准 build.zig / zon 形态）**

Run:
```bash
cd /tmp/zigprobe && rm -rf init16 && mkdir init16 && cd init16 && G:/scoop/apps/zig/current/zig.exe init
```
Expected: 生成 `build.zig`、`build.zig.zon`、`src/main.zig`、`src/root.zig`。
检查：`addExecutable`/`addTest` 的参数形态（`root_module` 还是 `root_source_file`）、zon 的 `name`（枚举字面量？）与 `fingerprint` 字段。**16_build 的 build.zig/zon 以此模板为基线改写**，与本计划草案的偏差以模板为准（记入勘误）。

- [x] **Step 2: 写 zig/examples/15_testing/main.zig**

```zig
//! 15 测试：test 块、std.testing 断言、testing.allocator 泄漏检测
const std = @import("std");
const util = @import("util.zig");

// 被测函数：把字符串重复 n 遍（分配失败要回滚）
fn repeat(allocator: std.mem.Allocator, s: []const u8, n: usize) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    for (0..n) |_| try out.appendSlice(allocator, s);
    return out.toOwnedSlice(allocator);
}

const parseLike = struct {
    fn f(x: u8) error{TooBig}!u8 {
        return if (x > 3) error.TooBig else x;
    }
}.f;

pub fn main() !void {
    const a = std.heap.page_allocator;
    const r = try repeat(a, "ab", 3);
    defer a.free(r);
    std.debug.print("repeat(ab,3) = {s}\n", .{r});
    const slug = try util.sluggify(a, "Hello World!");
    defer a.free(slug);
    std.debug.print("sluggify = {s}\n", .{slug});
    std.debug.print("本文件的全部断言用 zig test 运行（自检通过）\n", .{});
}

test "repeat 重复拼接" {
    const a = std.testing.allocator;
    const r = try repeat(a, "ab", 3);
    defer a.free(r);
    try std.testing.expectEqualStrings("ababab", r);
}

test "repeat 零次得到空串" {
    const a = std.testing.allocator;
    const r = try repeat(a, "x", 0);
    defer a.free(r);
    try std.testing.expectEqual(@as(usize, 0), r.len);
}

test "断言族速览" {
    try std.testing.expect(true);
    try std.testing.expectEqual(@as(u8, 4), 2 + 2);
    try std.testing.expectEqualStrings("zig", "z" ++ "ig");
    try std.testing.expectEqualSlices(u8, "abc", "abc");
    try std.testing.expectError(error.TooBig, parseLike(9));
    const opt: ?u8 = null;
    try std.testing.expectNull(opt);
}

test "testing.allocator 抓泄漏" {
    const a = std.testing.allocator;
    const buf = try a.alloc(u8, 10);
    a.free(buf); // ← 注释掉这行再 zig test：直接判泄漏失败
}

test {
    _ = util; // 引用其它文件的测试（不引用就不跑）
}
```

- [x] **Step 3: 写 zig/examples/15_testing/util.zig**

```zig
//! 15 测试：模块也带自己的测试
const std = @import("std");

/// slug 化：小写 + 空格换连字符
pub fn sluggify(allocator: std.mem.Allocator, s: []const u8) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    for (s) |ch| {
        try out.append(allocator, if (ch == ' ') '-' else std.ascii.toLower(ch));
    }
    return out.toOwnedSlice(allocator);
}

test "sluggify 行为" {
    const a = std.testing.allocator;
    const r = try sluggify(a, "Hello World!");
    defer a.free(r);
    try std.testing.expectEqualStrings("hello-world!", r);
}
```

- [x] **Step 4: 写 16_build 工程四个文件（以 Step 1 模板为基线）**

`zig/examples/16_build/build.zig`（草案，以 `zig init` 实测模板为准）：

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "16_build",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&b.addRunArtifact(unit_tests).step);
}
```

`zig/examples/16_build/build.zig.zon`（fingerprint 用 `zig init` 生成的值）：

```zig
.{
    .name = .@"16_build",
    .version = "0.1.0",
    .fingerprint = 0x0, // ← 用 zig init 生成的真实指纹替换
    .minimum_zig_version = "0.16.0",
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src/main.zig",
        "src/greet.zig",
    },
}
```

`zig/examples/16_build/src/main.zig`：

```zig
//! 16 构建系统：工程入口（多文件模块 + 测试步骤）
const std = @import("std");
const greet = @import("greet.zig");

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();
    const gpa = da.allocator();

    const msg = try greet.hello(gpa, "构建系统");
    defer gpa.free(msg);
    std.debug.print("{s}\n", .{msg});
    std.debug.print("本工程由 build.zig 驱动：zig build / build run / build test\n", .{});
}

test "greet 模块可用" {
    const a = std.testing.allocator;
    const m = try greet.hello(a, "t");
    defer a.free(m);
    try std.testing.expectEqualStrings("你好，t！", m);
}
```

`zig/examples/16_build/src/greet.zig`：

```zig
//! 16 构建系统：被 main 相对导入的模块
const std = @import("std");

pub fn hello(allocator: std.mem.Allocator, who: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "你好，{s}！", .{who});
}

test "hello 拼接" {
    const a = std.testing.allocator;
    const m = try hello(a, "Z");
    defer a.free(m);
    try std.testing.expectEqualStrings("你好，Z！", m);
}
```

- [x] **Step 5: 验证 + Commit**

Run:
```bash
cd G:/code/guide/zig && pwsh -NoProfile -File build.ps1 -Example 15_testing && pwsh -NoProfile -File build.ps1 -Example 16_build
```
Expected: `[Done]`；16_build 走 `zig build test` + `zig build run` 分支。`zig-out/`/`.zig-cache/` 生成在示例目录内——**检查 .gitignore 是否需要补充**（仓库根 .gitignore 若未忽略 `zig-out/`、`.zig-cache/`，在 Task 17 一并处理）。

```bash
cd G:/code/guide && git add zig/examples/15_testing zig/examples/16_build
git commit -m "feat(zig): 示例 15_testing/16_build——测试框架、build.zig 工程"
```

---

### Task 8: 示例 17_cinterop / 18_cross（⭐ 特色重点）

**Files:**
- Create: `zig/examples/17_cinterop/main.zig`
- Create: `zig/examples/18_cross/main.zig`
- Create: `zig/examples/18_cross/wasm_lib.zig`
- Create: `zig/examples/18_cross/hello.c`
- Modify: `zig/build.ps1`（wasm 构建加 `--no-entry`）

**Interfaces:**
- Produces: 第 17/18 章引用代码；17 走 `-lc` 分支；18 走交叉编译分支。

- [x] **Step 0: 修 build.ps1 的 wasm 构建（freestanding 无入口须 --no-entry）**

把 Task 1 里 `Test-CrossExample` 的 wasm 一行改为：

```powershell
    Invoke-Zig $Dir @("build-exe", "wasm_lib.zig", "-target", "wasm32-freestanding", "--no-entry",
        "-femit-bin=$(Join-Path $buildDir "$name`.wasm")")
```

- [x] **Step 1: 写 zig/examples/17_cinterop/main.zig**

```zig
//! 17 C 互操作：extern 声明、@cImport、export 导出（构建需 -lc）
const std = @import("std");

// ═══ 17.1 extern fn：手写 C 函数声明（直接链接 libc）
extern fn printf(format: [*:0]const u8, ...) c_int;

// ═══ 17.2 @cImport：引入整个 C 头文件（符号进 c 命名空间）
const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("string.h");
});

// ═══ 17.3 export fn：Zig 函数按 C ABI 导出（供 C/其他语言调用）
export fn zig_add(a: i32, b: i32) i32 {
    return a + b;
}

pub fn main() !void {
    // 17.1 手写 extern：c"..." 是 C 字符串字面量（保证 0 结尾）
    _ = printf(c"printf 直连：zig_add(3,4)=%d\n", zig_add(3, 4));

    // 17.2 @cImport 的符号全在 c 下（类型/宏/函数）
    _ = c.printf(c"cImport 版：strlen(\"hello\")=%d\n", @as(c_int, @intCast(c.strlen("hello"))));

    // ═══ 17.7 切片 ↔ C 指针：哨兵保证 0 结尾，std.mem.span 走回头路
    const zig_str = "哨兵切片互转";
    const c_ptr: [*:0]const u8 = zig_str.ptr; // 切片首指针
    const back: [:0]const u8 = std.mem.span(c_ptr); // 指针 → 哨兵切片
    std.debug.print("span 回来长度 {d}（两侧字节一致）\n", .{back.len});

    std.debug.print("自检通过\n", .{});
}

test "C ABI 与 cImport 可用（须 zig test -lc）" {
    try std.testing.expectEqual(@as(i32, 7), zig_add(3, 4));
    try std.testing.expectEqual(@as(usize, 5), c.strlen("hello"));
}
```

**注意**：`c"..."` 字符串字面量语法在 0.16 若已移除（probe：报错即知），改用 `const fmt_c = "…%d\n";` 传 `fmt_c.ptr`（`[*:0]const u8` 从哨兵数组自动退化）。`%d` 与 `@as(c_int, ...)`：c.strlen 返回 usize，printf `%d` 直传在 Windows 上可能告警，故显式转 c_int。

- [x] **Step 2: 写 zig/examples/18_cross/main.zig**

```zig
//! 18 交叉编译：同一份源码，多个目标（build.ps1 交叉验证 aarch64-linux 与 wasm）
const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    // ═══ 18.1 builtin：目标在编译期就知道
    std.debug.print("架构 {s}，系统 {s}，模式 {s}\n", .{
        @tagName(builtin.cpu.arch),
        @tagName(builtin.os.tag),
        @tagName(builtin.mode),
    });

    // ═══ 18.2 编译期按架构分派（交叉产物走哪个分支在构建时就定了）
    const arch_code: u8 = switch (builtin.cpu.arch) {
        .x86_64 => 1,
        .aarch64 => 2,
        else => 255,
    };
    std.debug.print("本架构代号 {d}（交叉编译时代码随之切换）\n", .{arch_code});
    std.debug.print("自检通过\n", .{});
}

test "native 可运行" {
    try std.testing.expect(arch_code_ok);
}

const arch_code_ok = switch (builtin.cpu.arch) {
    .x86_64, .aarch64 => true,
    else => true, // 教学示例：任何架构都过；演示 switch 穷尽
};
```

**注意**：测试块在 native 上跑（`zig test`），交叉产物只验证编译不运行——这个差异本身就是 18 章的教学点，正文展开。

- [x] **Step 3: 写 zig/examples/18_cross/wasm_lib.zig**

```zig
//! 18 交叉编译：wasm32-freestanding 模块（无 OS：没有 main，只有导出）
// 构建：zig build-exe wasm_lib.zig -target wasm32-freestanding --no-entry

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

export fn fib(n: u32) u32 {
    if (n <= 1) return n;
    var a: u32 = 0;
    var b: u32 = 1;
    var i: u32 = 1;
    while (i < n) : (i += 1) {
        const t = a + b;
        a = b;
        b = t;
    }
    return b;
}
```

- [x] **Step 4: 写 zig/examples/18_cross/hello.c**

```c
/* 18 交叉编译：这份 C 由 zig cc 编译（build.ps1 实测 zig cc hello.c） */
#include <stdio.h>

int main(void) {
    printf("hello from C, compiled by zig cc\n");
    return 0;
}
```

- [x] **Step 5: 验证 + Commit**

Run:
```bash
cd G:/code/guide/zig && pwsh -NoProfile -File build.ps1 -Example 17_cinterop && pwsh -NoProfile -File build.ps1 -Example 18_cross
```
Expected: 17 走 `-lc`；18 输出含 aarch64-linux、wasm32-freestanding 两条交叉构建 + `hello from C, compiled by zig cc`。

```bash
cd G:/code/guide && git add zig/build.ps1 zig/examples/17_cinterop zig/examples/18_cross
git commit -m "feat(zig): 示例 17_cinterop/18_cross——C 互操作、交叉编译与 zig cc"
```

---

### Task 9: 示例 19_threads / 20_files / 21_asm

**Files:**
- Create: `zig/examples/19_threads/main.zig`
- Create: `zig/examples/20_files/main.zig`
- Create: `zig/examples/21_asm/main.zig`

**Interfaces:**
- Produces: 第 19/20/21 章引用代码。

- [x] **Step 0: API 探针（一次探清 20 章全部未定项）**

Run:
```bash
Z=/g/scoop/apps/zig/0.16.0/lib/std
grep -n "pub fn writeFile" $Z/fs/Dir.zig | head -3      # 是否带 io 参数
grep -n "pub fn readFileAlloc" $Z/fs/Dir.zig | head -3
grep -n "pub const fixed\|pub fn fixed" $Z/Io/Writer.zig | head -3   # fixed writer
grep -n "pub const Stringify\|pub fn stringify" $Z/json.zig | head -5
grep -n "pub fn sleep" $Z/Thread.zig $Z/time.zig | head -3
grep -n "pub fn run\b" $Z/process.zig $Z/process/Child.zig 2>/dev/null | head -5
grep -n "pub fn iterator\|pub fn initAllocator" $Z/process/Args.zig | head -5
grep -n "pub fn startMany\|pub fn start\b" $Z/Thread.zig | head -5
```
按结果修正 Task 9/10 的草案代码（偏差记入勘误）。

- [x] **Step 1: 写 zig/examples/19_threads/main.zig**

```zig
//! 19 并发：Thread、Mutex、atomic.Value、Condition、WaitGroup
const std = @import("std");

// ═══ 19.2 Mutex：互斥保护共享计数
var counter: usize = 0;
var mutex: std.Thread.Mutex = .{};

fn addLocked(n: usize) void {
    for (0..n) |_| {
        mutex.lock();
        defer mutex.unlock();
        counter += 1;
    }
}

// ═══ 19.4 有界队列：Condition 双条件（经典生产者-消费者）
const Queue = struct {
    buf: [8]u32 = undefined,
    head: usize = 0,
    count: usize = 0,
    mtx: std.Thread.Mutex = .{},
    not_empty: std.Thread.Condition = .{},
    not_full: std.Thread.Condition = .{},

    fn push(self: *Queue, v: u32) void {
        self.mtx.lock();
        defer self.mtx.unlock();
        while (self.count == self.buf.len) {
            self.not_full.wait(&self.mtx); // 满了：等消费者腾位置
        }
        self.buf[(self.head + self.count) % self.buf.len] = v;
        self.count += 1;
        self.not_empty.signal(); // 唤醒一个消费者
    }

    fn pop(self: *Queue) u32 {
        self.mtx.lock();
        defer self.mtx.unlock();
        while (self.count == 0) {
            self.not_empty.wait(&self.mtx); // 空了：等生产者
        }
        const v = self.buf[self.head];
        self.head = (self.head + 1) % self.buf.len;
        self.count -= 1;
        self.not_full.signal();
        return v;
    }
};

fn producer(q: *Queue, n: u32, base: u32) void {
    var i: u32 = 0;
    while (i < n) : (i += 1) q.push(base + i);
}

fn consumer(q: *Queue, total: usize, out: *std.ArrayList(u32), alloc: std.mem.Allocator) void {
    var i: usize = 0;
    while (i < total) : (i += 1) {
        const v = q.pop();
        out.append(alloc, v) catch @panic("OOM");
    }
}

pub fn main() !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const mem = arena_state.allocator();

    // ═══ 19.1 spawn / join
    const worker = struct {
        fn run(id: u32) void {
            std.debug.print("  worker {d} 跑在线程 {d}\n", .{ id, std.Thread.getCurrentId() });
        }
    };
    const t1 = try std.Thread.spawn(.{}, worker.run, .{1});
    const t2 = try std.Thread.spawn(.{}, worker.run, .{2});
    t1.join();
    t2.join();

    // ═══ 19.2 Mutex 计数（去掉锁必错——正文演示）
    const ta = try std.Thread.spawn(.{}, addLocked, .{50_000});
    const tb = try std.Thread.spawn(.{}, addLocked, .{50_000});
    ta.join();
    tb.join();
    std.debug.print("Mutex 计数 = {d}（期望 100000）\n", .{counter});

    // ═══ 19.3 atomic.Value：无锁计数
    var hits = std.atomic.Value(usize).init(0);
    const atomic_worker = struct {
        fn run(h: *std.atomic.Value(usize), n: usize) void {
            for (0..n) |_| _ = h.fetchAdd(1, .monotonic);
        }
    };
    const tc = try std.Thread.spawn(.{}, atomic_worker.run, .{ &hits, 25_000 });
    const td = try std.Thread.spawn(.{}, atomic_worker.run, .{ &hits, 25_000 });
    tc.join();
    td.join();
    std.debug.print("atomic 计数 = {d}（期望 50000）\n", .{hits.load(.seq_cst)});

    // ═══ 19.4 生产者-消费者
    var q: Queue = .{};
    var out: std.ArrayList(u32) = .empty;
    const N: u32 = 16;
    const tp1 = try std.Thread.spawn(.{}, producer, .{ &q, N / 2, 100 });
    const tp2 = try std.Thread.spawn(.{}, producer, .{ &q, N / 2, 200 });
    const tcon = try std.Thread.spawn(.{}, consumer, .{ &q, N, &out, mem });
    tp1.join();
    tp2.join();
    tcon.join();
    var sum: u64 = 0;
    for (out.items) |v| sum += v;
    // 100..107 + 200..207 的和是定值，用闭式验证
    const expect: u64 = blk: {
        var e: u64 = 0;
        for (100..108) |v| e += v;
        for (200..208) |v| e += v;
        break :blk e;
    };
    std.debug.print("队列消费 {d} 件，总和 {d}（期望 {d}）\n", .{ out.items.len, sum, expect });

    // ═══ 19.5 WaitGroup：不需要线程句柄，等"活"干完
    var wg: std.Thread.WaitGroup = .{};
    const job = struct {
        fn run(g: *std.Thread.WaitGroup, k: u8) void {
            defer g.finish();
            std.debug.print("  WaitGroup 作业 {d} 完成\n", .{k});
        }
    };
    wg.startMany(4);
    var jts: [4]std.Thread = undefined;
    for (&jts, 0..) |*jt, k| jt.* = try std.Thread.spawn(.{}, job.run, .{ &wg, @intCast(k) });
    wg.wait();
    for (jts) |jt| jt.join();

    std.debug.print("自检通过\n", .{});
}

test "无锁与有锁都算对" {
    var h = std.atomic.Value(u32).init(0);
    const t = try std.Thread.spawn(.{}, struct {
        fn run(x: *std.atomic.Value(u32)) void {
            for (0..1000) |_| _ = x.fetchAdd(1, .monotonic);
        }
    }.run, .{&h});
    t.join();
    try std.testing.expectEqual(@as(u32, 1000), h.load(.seq_cst));

    var qq: Queue = .{};
    qq.push(9);
    try std.testing.expectEqual(@as(u32, 9), qq.pop());
}
```

- [x] **Step 2: 写 zig/examples/20_files/main.zig（先按 Step 0 探针结果修正 API）**

```zig
//! 20 文件与 IO：std.fs、读写、目录遍历、std.json
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const mem = arena_state.allocator();

    // ═══ 20.1 写文件：Dir.writeFile 一行落地
    try std.fs.cwd().writeFile(.{
        .sub_path = "build_demo.txt",
        .data = "第一行：Zig 写文件\n第二行：fin",
    });

    // ═══ 20.2 读文件：readFileAlloc（一次读完，第二参防失控上限）
    const text = try std.fs.cwd().readFileAlloc(mem, "build_demo.txt", 1024 * 1024);
    std.debug.print("读回 {d} 字节，前 12 字节：{s}\n", .{ text.len, text[0..12] });

    // ═══ 20.3 元数据
    const st = try std.fs.cwd().statFile("build_demo.txt");
    std.debug.print("文件大小 {d} 字节\n", .{st.size});

    // ═══ 20.4 目录：makePath + openDir(.iterate) 遍历
    try std.fs.cwd().makePath("build_demo_dir/sub");
    try std.fs.cwd().writeFile(.{ .sub_path = "build_demo_dir/sub/a.txt", .data = "A" });
    try std.fs.cwd().writeFile(.{ .sub_path = "build_demo_dir/b.txt", .data = "B" });
    var dir = try std.fs.cwd().openDir("build_demo_dir", .{ .iterate = true });
    defer dir.close();
    var it = dir.iterate();
    while (try it.next()) |entry| {
        std.debug.print("  [{s}] {s}\n", .{ @tagName(entry.kind), entry.name });
    }

    // ═══ 20.5 路径工具（跨平台分隔符）
    const joined = try std.fs.path.join(mem, &.{ "build_demo_dir", "sub", "a.txt" });
    std.debug.print("join：{s}，basename={s}\n", .{ joined, std.fs.path.basename(joined) });

    // ═══ 20.6 新 Writer 写文件（0.16 Io 接口 + 缓冲 + flush）
    {
        const f = try std.fs.cwd().createFile("build_demo_w.txt", .{});
        defer f.close();
        var fbuf: [128]u8 = undefined;
        var fw = f.writer(init.io, &fbuf);
        const w = &fw.interface;
        try w.print("缓冲写入 {s}\n", .{"OK"});
        try w.flush(); // 忘了 flush 是新手第一大坑
    }

    // ═══ 20.7 std.json：结构 ↔ JSON 互转
    const Score = struct { name: []const u8, points: u32 };
    const s1 = Score{ .name = "阿 Z", .points = 99 };
    var jbuf: [256]u8 = undefined;
    var jw = std.Io.Writer.fixed(&jbuf);
    try std.json.Stringify.value(s1, .{}, &jw);
    std.debug.print("JSON：{s}\n", .{jw.buffered()});
    const back = try std.json.parseFromSlice(Score, mem, jw.buffered(), .{});
    defer back.deinit();
    std.debug.print("回读：{s} {d} 分\n", .{ back.value.name, back.value.points });

    // ═══ 20.8 清理演示产物（deleteTree 递归删）
    std.fs.cwd().deleteFile("build_demo.txt") catch {};
    std.fs.cwd().deleteFile("build_demo_w.txt") catch {};
    std.fs.cwd().deleteTree("build_demo_dir") catch {};
    std.debug.print("自检通过\n", .{});
}

test "读写与 JSON 回环" {
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(.{ .sub_path = "x.txt", .data = "abc" });
    const got = try tmp.dir.readFileAlloc(a, "x.txt", 64);
    defer a.free(got);
    try std.testing.expectEqualStrings("abc", got);

    const P = struct { n: u8 };
    var jbuf: [64]u8 = undefined;
    var jw = std.Io.Writer.fixed(&jbuf);
    try std.json.Stringify.value(P{ .n = 3 }, .{}, &jw);
    const back = try std.json.parseFromSlice(P, a, jw.buffered(), .{});
    defer back.deinit();
    try std.testing.expectEqual(@as(u8, 3), back.value.n);
}
```

**注意**：`Dir.writeFile`/`readFileAlloc`/`File.writer`/`Io.Writer.fixed`/`json.Stringify.value` 均以 Step 0 探针为准（0.16 可能给这些 API 加了 `io` 参数或改名），偏差改代码 + 记勘误。

- [x] **Step 3: 写 zig/examples/21_asm/main.zig**

```zig
//! 21 内联汇编与底层：asm 语法、约束、volatile、extern struct
const std = @import("std");
const builtin = @import("builtin");

comptime {
    if (builtin.cpu.arch != .x86_64) {
        @compileError("本章汇编示例针对 x86_64（其他架构思路见正文）");
    }
}

// ═══ 21.2 最小示例："+r" 读写在同一寄存器
fn addImm(x: u64) u64 {
    var r = x;
    asm volatile (
        "add $5, {[r]}" // AT&T 语法：立即数加到寄存器
        : [r] "+r" (r), // +r：输入输出同寄存器
    );
    return r;
}

// ═══ 21.5 rdtsc：绑定固定寄存器的多输出
fn rdtsc() u64 {
    var lo: u32 = undefined;
    var hi: u32 = undefined;
    asm volatile (
        \\rdtsc
        : [lo] "={eax}" (lo), // =：只输出；{eax}：固定用 eax
          [hi] "={edx}" (hi),
    );
    return (@as(u64, hi) << 32) | lo;
}

pub fn main() !void {
    std.debug.print("addImm(37) = {d}（汇编 +5）\n", .{addImm(37)});

    const t0 = rdtsc();
    var sink: u64 = 0;
    for (0..1000) |i| sink +%= i;
    const t1 = rdtsc();
    std.debug.print("1000 次加法 ≈ {d} tick（rdtsc 计时）sink={d}\n", .{ t1 - t0, sink });

    // ═══ 21.6 extern struct：与 C 完全一致的内存布局
    const Pair = extern struct { a: u32, b: u32 };
    const p = Pair{ .a = 1, .b = 2 };
    const as_u64: u64 = @bitCast(p);
    std.debug.print("extern struct 位模式 0x{x:0>16}（低位是 a=1）\n", .{as_u64});

    std.debug.print("自检通过\n", .{});
}

test "汇编与位模式" {
    try std.testing.expectEqual(@as(u64, 42), addImm(37));
    const t = rdtsc();
    try std.testing.expect(t > 0);
    const Pair = extern struct { a: u32, b: u32 };
    const p = Pair{ .a = 7, .b = 0 };
    try std.testing.expectEqual(@as(u64, 7), @bitCast(p));
}
```

**注意**：0.14+ 具名操作数模板占位是 `{[r]}`（不是旧 `%[r]`）；`asm` 多行用 `\\`。若 MSVC 目标下内联汇编报错（backend 差异），试 `-target x86_64-windows-gnu` 或 `-mcpu` 相关参数（记入勘误并正文说明）。

- [x] **Step 4: 验证 + Commit**

Run:
```bash
cd G:/code/guide/zig && pwsh -NoProfile -File build.ps1 -Example 19_threads && pwsh -NoProfile -File build.ps1 -Example 20_files && pwsh -NoProfile -File build.ps1 -Example 21_asm
```
Expected: 全部 `[Done]`；19 输出两处"期望"数值均吻合。

```bash
cd G:/code/guide && git add zig/examples/19_threads zig/examples/20_files zig/examples/21_asm
git commit -m "feat(zig): 示例 19_threads/20_files/21_asm——并发、文件 IO、内联汇编"
```

---

### Task 10: 示例 22_process / 23_debug / 24_minigrep（实战工程）

**Files:**
- Create: `zig/examples/22_process/main.zig`
- Create: `zig/examples/23_debug/main.zig`
- Create: `zig/examples/24_minigrep/build.zig`
- Create: `zig/examples/24_minigrep/build.zig.zon`
- Create: `zig/examples/24_minigrep/src/main.zig`
- Create: `zig/examples/24_minigrep/src/search.zig`

**Interfaces:**
- Produces: 第 22/23/24 章引用代码；`search.searchLines` / `search.printHighlighted` 是 24 章测试的核心被测接口（签名见 Step 4）。

- [x] **Step 1: 写 zig/examples/22_process/main.zig（API 按 Task 9 Step 0 探针修正）**

```zig
//! 22 进程与系统编程：argv、环境变量、子进程、路径、时间
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const mem = arena_state.allocator();

    // ═══ 22.1 argv：跨平台迭代器（Windows 原生 UTF-16 被抹平）
    var it = try init.minimal.args.iterator(mem);
    var argc: usize = 0;
    while (try it.next()) |arg| {
        std.debug.print("  argv[{d}] = {s}\n", .{ argc, arg });
        argc += 1;
    }

    // ═══ 22.2 环境变量（Init.environ_map：已解析好的 map）
    if (init.environ_map.get("USERNAME") orelse init.environ_map.get("USER")) |user| {
        std.debug.print("当前用户：{s}\n", .{user});
    }
    const path_len = if (init.environ_map.get("PATH")) |p| p.len else 0;
    std.debug.print("PATH 长度：{d}\n", .{path_len});

    // ═══ 22.3 子进程：跑命令收输出
    const res = try std.process.Child.run(.{
        .allocator = mem,
        .argv = &.{ "cmd", "/c", "echo", "hello from child" },
    });
    std.debug.print("子进程 stdout：{s}", .{res.stdout});

    // ═══ 22.4 当前目录
    var pbuf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd_len = try std.process.currentPath(init.io, &pbuf);
    std.debug.print("cwd：{s}\n", .{pbuf[0..cwd_len]});

    // ═══ 22.5 时间
    const t0 = std.time.nanoTimestamp();
    std.Thread.sleep(2 * std.time.ns_per_ms);
    const t1 = std.time.nanoTimestamp();
    std.debug.print("打算睡 2ms，实测 {d} ns；Unix 时间戳 {d}\n", .{ t1 - t0, std.time.timestamp() });

    std.debug.print("自检通过\n", .{});
}

test "路径与时间" {
    const a = std.testing.allocator;
    const j = try std.fs.path.join(a, &.{ "x", "y.txt" });
    defer a.free(j);
    try std.testing.expectEqualStrings("x\\y.txt", j); // Windows 分隔符
    try std.testing.expectEqualStrings("y", std.fs.path.basename(j));
    try std.testing.expect(std.time.timestamp() > 1_700_000_000);
}
```

**注意**：`init.minimal.args.iterator(mem)`、`Child.run(.{...})`、`std.Thread.sleep` 均以探针为准（0.16 可能是 `Iterator.initAllocator` 形态、`Child.run` 可能要 io 参数）；测试里 `x\\y.txt` 分隔符断言在非 Windows 会反——本教程以 Windows 为准，正文说明。

- [x] **Step 2: 写 zig/examples/23_debug/main.zig**

```zig
//! 23 调试与工具链：assert、panic 开关、计时、@breakpoint、环境变量联动
const std = @import("std");
const builtin = @import("builtin");

fn risky(x: u32) u32 {
    std.debug.assert(x != 0); // Debug/ReleaseSafe 生效，ReleaseFast 编译掉
    return 100 / x;
}

pub fn main(init: std.process.Init) !void {
    // ═══ 23.1 构建模式与 assert 生死
    std.debug.print("构建模式：{s}\n", .{@tagName(builtin.mode)});
    std.debug.print("risky(4) = {d}\n", .{risky(4)});

    // ═══ 23.2 纳秒计时做微基准
    var sink: u64 = 0;
    const t0 = std.time.nanoTimestamp();
    for (0..1_000_000) |i| sink +%= @intCast(i % 7);
    const t1 = std.time.nanoTimestamp();
    std.debug.print("百万次循环 {d} ns（sink={d}，防优化）\n", .{ t1 - t0, sink });

    // ═══ 23.3 可开关的 panic / @breakpoint 演示（build.ps1 不开这些变量）
    if (init.environ_map.get("ZIG_PANIC") != null) {
        @panic("演示 panic：看栈跟踪（正文贴真实输出）");
    }
    if (init.environ_map.get("ZIG_BREAK") != null) {
        @breakpoint(); // 调试器里等价 int3；无调试器时会崩——正文说明
    }

    // ═══ 23.4 错误返回跟踪演示：让一个错误冒到顶（开关控制）
    if (init.environ_map.get("ZIG_ERT") != null) {
        return error.DemoErrorReturnTrace; // Debug 下 stderr 打印完整来路
    }

    std.debug.print("自检通过\n", .{});
}

test "risky 正常路径" {
    try std.testing.expectEqual(@as(u32, 25), risky(4));
}
```

- [x] **Step 3: 写 24_minigrep 的 build.zig / build.zig.zon**

`build.zig`（以 Task 7 Step 1 的 `zig init` 模板为基线，name 换 `minigrep`，run 步骤透传 args）：

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "minigrep",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args); // zig build run -- <args> 透传
    const run_step = b.step("run", "Run minigrep");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&b.addRunArtifact(unit_tests).step);
}
```

`build.zig.zon`（fingerprint 用 zig init 实值）：

```zig
.{
    .name = .minigrep,
    .version = "0.1.0",
    .fingerprint = 0x0, // ← 用 zig init 生成的真实指纹替换
    .minimum_zig_version = "0.16.0",
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src/main.zig",
        "src/search.zig",
    },
}
```

- [x] **Step 4: 写 zig/examples/24_minigrep/src/search.zig**

```zig
//! 24 实战：搜索核心（纯逻辑，好测试）
const std = @import("std");

pub const Match = struct {
    path: []const u8,
    line_no: usize,
    line: []const u8,
};

/// 在多行文本中找 needle，返回全部命中（line 借用 text 的内存）
pub fn searchLines(allocator: std.mem.Allocator, text: []const u8, needle: []const u8) ![]Match {
    var hits: std.ArrayList(Match) = .empty;
    errdefer hits.deinit(allocator);
    var line_it = std.mem.splitScalar(u8, text, '\n');
    var n: usize = 0;
    while (line_it.next()) |line| {
        n += 1;
        if (needle.len == 0) continue;
        if (std.mem.indexOf(u8, line, needle) != null) {
            try hits.append(allocator, .{ .path = "", .line_no = n, .line = line });
        }
    }
    return hits.toOwnedSlice(allocator);
}

/// 高亮打印：path:行号: 行内容（命中段红色加粗，ANSI 转义）
pub fn printHighlighted(w: *std.Io.Writer, path: []const u8, m: Match, needle: []const u8) !void {
    try w.print("{s}:{d}: ", .{ path, m.line_no });
    var rest = m.line;
    while (std.mem.indexOf(u8, rest, needle)) |at| {
        try w.print("{s}\x1b[1;31m{s}\x1b[0m", .{ rest[0..at], rest[at .. at + needle.len] });
        rest = rest[at + needle.len ..];
    }
    try w.print("{s}\n", .{rest});
}

test "searchLines 行号正确" {
    const a = std.testing.allocator;
    const hits = try searchLines(a, "aa\nbb\naa", "aa");
    defer a.free(hits);
    try std.testing.expectEqual(@as(usize, 2), hits.len);
    try std.testing.expectEqual(@as(usize, 1), hits[0].line_no);
    try std.testing.expectEqual(@as(usize, 3), hits[1].line_no);
    try std.testing.expectEqualStrings("bb", (try searchLines(a, "aa\nbb\naa", "bb"))[0].line);
}

test "printHighlighted 含 ANSI 转义" {
    var buf: [128]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    try printHighlighted(&w, "f.txt", .{ .path = "f.txt", .line_no = 1, .line = "abxcd" }, "x");
    const out = w.buffered();
    try std.testing.expect(std.mem.indexOf(u8, out, "\x1b[1;31mx\x1b[0m") != null);
    try std.testing.expect(std.mem.startsWith(u8, out, "f.txt:1: "));
}
```

- [x] **Step 5: 写 zig/examples/24_minigrep/src/main.zig**

```zig
//! 24 实战迷你 grep：minigrep <模式> [目录]（递归 + 多线程 + 高亮）
const std = @import("std");
const search = @import("search.zig");

const Worker = struct {
    needle: []const u8,
    out: std.ArrayList(search.Match) = .empty,
    mtx: std.Thread.Mutex = .{},

    fn searchFile(self: *Worker, alloc: std.mem.Allocator, path: []const u8) void {
        const text = std.fs.cwd().readFileAlloc(alloc, path, 16 * 1024 * 1024) catch return;
        defer alloc.free(text);
        const hits = search.searchLines(alloc, text, self.needle) catch return;
        defer alloc.free(hits);
        if (hits.len == 0) return;
        self.mtx.lock();
        defer self.mtx.unlock();
        for (hits) |h| {
            const owned = search.Match{
                .path = alloc.dupe(u8, path) catch return,
                .line_no = h.line_no,
                .line = alloc.dupe(u8, h.line) catch return,
            };
            self.out.append(alloc, owned) catch return;
        }
    }
};

fn walkDir(alloc: std.mem.Allocator, dir_path: []const u8, out: *std.ArrayList([]const u8)) !void {
    var dir = std.fs.cwd().openDir(dir_path, .{ .iterate = true }) catch return; // 无权限等：跳过
    defer dir.close();
    var it = dir.iterate();
    while (try it.next()) |entry| {
        const full = try std.fs.path.join(alloc, &.{ dir_path, entry.name });
        switch (entry.kind) {
            .directory => try walkDir(alloc, full, out),
            .file => try out.append(alloc, full),
            else => {},
        }
    }
}

pub fn main(init: std.process.Init) !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const mem = arena_state.allocator();

    // ═══ 参数：模式 + 目录（默认 src，保证 zig build run 输出确定）
    var args_it = try init.minimal.args.iterator(mem);
    _ = args_it.next() orelse {}; // 跳过程序名
    const needle = args_it.next() orelse {
        std.debug.print("用法：minigrep <模式> [目录]（默认搜 src）\n", .{});
        return;
    };
    const root = args_it.next() orelse "src";

    // ═══ 递归收集文件
    var files: std.ArrayList([]const u8) = .empty;
    walkDir(mem, root, &files) catch |e| {
        std.debug.print("打开目录 {s} 失败：{s}\n", .{ root, @errorName(e) });
        return e;
    };

    // ═══ 多线程：原子游标抢任务 + WaitGroup 收工
    var worker: Worker = .{ .needle = needle };
    const nt = @min(4, @max(1, files.items.len));
    var next: std.atomic.Value(usize) = std.atomic.Value(usize).init(0);
    var wg: std.Thread.WaitGroup = .{};
    const Task = struct {
        fn run(w: *Worker, fl: []const []const u8, nx: *std.atomic.Value(usize), g: *std.Thread.WaitGroup, a: std.mem.Allocator) void {
            defer g.finish();
            while (true) {
                const i = nx.fetchAdd(1, .monotonic);
                if (i >= fl.len) break;
                w.searchFile(a, fl[i]);
            }
        }
    };
    var threads: [4]std.Thread = undefined;
    wg.startMany(nt);
    for (0..nt) |i| threads[i] = try std.Thread.spawn(.{}, Task.run, .{ &worker, files.items, &next, &wg, mem });
    wg.wait();
    for (threads[0..nt]) |t| t.join();

    // ═══ 输出（缓冲 Writer + ANSI 高亮）
    var buf: [4096]u8 = undefined;
    var w = std.Io.File.stdout().writer(init.io, &buf);
    const out = &w.interface;
    for (worker.out.items) |m| {
        try search.printHighlighted(out, m.path, m, needle);
    }
    try out.print("共 {d} 处命中，扫了 {d} 个文件（{d} 线程）\n", .{ worker.out.items.len, files.items.len, nt });
    try out.flush();
}

test "端到端：搜索核心 + 临时目录" {
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(.{ .sub_path = "a.txt", .data = "hello zig\nno match\nzig again" });
    const hits = try search.searchLines(a, "hello zig\nno match\nzig again", "zig");
    defer a.free(hits);
    try std.testing.expectEqual(@as(usize, 2), hits.len);
    try std.testing.expectEqual(@as(usize, 3), hits[1].line_no);
}
```

**注意**：`args_it.next()` 的错误联合形态以探针为准（可能要 `try` 或返回 `?`）；`zig build run` 无 args 时打印用法并正常退出（exit 0）满足验证。

- [x] **Step 6: 验证 + Commit**

Run:
```bash
cd G:/code/guide/zig && pwsh -NoProfile -File build.ps1 -Example 22_process && pwsh -NoProfile -File build.ps1 -Example 23_debug && pwsh -NoProfile -File build.ps1 -Example 24_minigrep
cd examples/24_minigrep && G:/scoop/apps/zig/current/zig.exe build run -- zig src && cd ../..
```
Expected: 22/23 `[Done]`；24 走工程分支且手动 `build run -- zig src` 能高亮命中。

```bash
cd G:/code/guide && git add zig/examples/22_process zig/examples/23_debug zig/examples/24_minigrep
git commit -m "feat(zig): 示例 22_process/23_debug/24_minigrep——进程、调试工具、实战 grep"
```

---
### Task 11: docs/01–04 章

**Files:**
- Create: `zig/docs/01-overview.md`
- Create: `zig/docs/02-hello.md`
- Create: `zig/docs/03-types.md`
- Create: `zig/docs/04-control.md`

**Interfaces:**
- Consumes: Task 2 的三个示例（正文按 `═══` 小节号摘录）。
- Produces: 教程前 4 章；后续章节延续同一格式（`# N · 标题`、`> 对应示例`、`N.M` 小节、末尾"坑位清单"）。

- [x] **Step 1: 写 01-overview.md（约 180 行，唯一无示例章）**

结构（吸收旧 README 的对比表/版本管理，压缩重写）：
- `# 01 · 全景：Zig 是什么，为什么值得学`
- 1.1 一段话定位：C 的现代继任者、显式哲学（无隐藏控制流/无隐藏分配/无宏）；"Zig 是一门更好的 C，不是更好的 Rust"
- 1.2 设计哲学四大支柱：comptime 替代宏、显式分配器、错误即类型、零运行时（每个一小段 + 对比表：Zig vs C vs C++ vs Rust，旧 README 三表合并精简成一张）
- 1.3 版本现状：0.16.0（2026），1.0 未到、std 仍在破坏性演进（0.13→0.16 三次大改：ArrayList unmanaged、Io 接口、File 移入 std.Io——一句话点到，正文各章有坑位）；**教程代码全部在 0.16.0 实测**
- 1.4 工具链一览表：`zig run / build-exe / build-lib / test / build / fmt / cc / c++ / translate-c / fetch / targets / init / doc`（每个一行说明，后文各有专章/专节）
- 1.5 安装与版本管理：官方包/scoop/choco/brew + zvm/zigup 各一段命令（压缩旧 README 两节为半页）
- 1.6 本教程怎么学：环境（0.16.0 + pwsh）、每章"读讲解→跑示例→改代码再跑"、三层验证含义、与 cpp20 教程结构对照表
- 1.7 坑位清单：① 版本坑——网上教程多为 0.13/0.14 语法，`ArrayList.init(alloc)` 等直接抄必编译错；② Windows 控制台中文乱码先 `chcp 65001`；③ zig 命令行参数与文件之间用 `--` 分隔（`zig run x.zig -- args`）

- [x] **Step 2: 写 02-hello.md（约 200 行）**

- `# 02 · 第一个程序`（`> 对应示例：examples/02_hello/`）
- 2.1 std.debug.print：为什么新手先用它（stderr 立即落地、无缓冲、线程安全），格式串速览表（`{d}/{s}/{}/{x}/{b}/{d:.2}/{d:0>3}`）
- 2.2 stdout 的正确姿势：缓冲 Writer 四步（stdout() → writer(io, &buf) → interface → flush）；**忘 flush 丢输出是第一大坑**；对照 cpp20 的 std::print
- 2.3 `std.process.Init`：0.16 新入口（io/gpa/arena/minimal.args/environ_map 五件套表格；main() 仍可零参——两代入口对比）；什么时候需要 init
- 2.4 编译运行分解：`zig run`（编译+跑）、`zig build-exe`（产 exe+pdb）、`zig test`；构建模式表 Debug/ReleaseSafe/ReleaseFast/ReleaseSmall（默认 Debug 及其含义：安全检查全开）
- 2.5 test 块初见（示例已埋一个）：`zig test main.zig`，15 章细讲
- 2.6 `zig fmt`：格式即规范（build.ps1 用 --check 把关）
- 2.7 坑位清单：① 忘 flush；② print 格式符用错（`{}` 对数字可用但对切片/结构体会打印类型展开，字符串必须 `{s}`）；③ 中文源文件须 UTF-8（无 BOM）；④ `zig run` 后传参数要 `--`；⑤ Windows 的 exe 旁会生成 .pdb，别提交进 git

- [x] **Step 3: 写 03-types.md（约 220 行）**

- `# 03 · 类型与变量`（`> 对应示例：examples/03_types/`）
- 3.1 const 优先（示例 3.1）；未使用的 var 是编译错（对比 C 的 warning）
- 3.2 任意位宽整数（u3/i19/u128）：位宽是类型的一部分、`@sizeOf` 表；usize/isize 何时用；与 C 固定宽度类型的对照
- 3.3 溢出家族运算符表：`+ - *`（安全模式 panic）、`+% -% *%`（环绕）、`|` 溢出检查相关；有符号环绕演示（-128→127）；何时选环绕（哈希、序列号）
- 3.4 comptime_int/comptime_float：字面量没有类型；`const big = 1 << 40` 合法（编译期大整数），`var x = 1 << 40` 推成什么要显式
- 3.5 浮点（f16/f32/f64/f128）与布尔；f16 注意事项
- 3.6 转型家族表格：@as（推导协调）/@intCast（运行期检查）/@truncate（砍位）/@bitCast（同宽重解释）/@intFromFloat/@floatFrom/@enumFromInt/@intFromEnum——"Zig 没有隐式转换"的设计意图
- 3.7 @bitCast 字节序一瞥（示例 3.7 的字节序输出按实测贴）
- 3.8 坑位清单：① `+` 溢出 Debug 必 panic，要环绕写 `+%`；② @intCast 越界 panic（它是检查不是魔术）；③ 字面量参与位运算的类型推导陷阱；④ 浮点相等比较别用 `==`（整数思维）；⑤ u1..u7 赋 8 直接编译错（值域检查）

- [x] **Step 4: 写 04-control.md（约 220 行）**

- `# 04 · 控制流`（`> 对应示例：examples/04_control/`）
- 4.1 if 是表达式（示例 4.1）；没有三元运算符
- 4.2 while 与 continue 表达式 `: (i += 1)`（示例 4.2）；`while (opt) |v|` 可选迭代预告
- 4.3 for 全家福（示例 4.3）：数组/切片/范围 `0..5`/zip 多序列 `for (a, b, 0..)`；**没有 C 风格 for(;;)** 的设计意图
- 4.4 label（示例 4.4）：`break :outer` / `continue :outer`；何时用（嵌套跳出）何时不用（深嵌套是味道）
- 4.5 switch（示例 4.5）：穷尽性编译期检查、多值 `1, 2 =>`、范围 `4...9 =>`、非穷尽类型要 else；与 C switch 的本质区别（无 fallthrough、必须是表达式可用）
- 4.6 tagged union 捕获（示例 4.6，预告第 08 章）
- 4.7 labeled switch（示例 4.7）：`continue :sw .next` 状态机写法（0.14+）
- 4.8 坑位清单：① switch 忘 else（非穷尽类型）编译错；② 范围写法是 `4...9` 三个点（切片是两点，新手常混）；③ for 循环里修改集合长度（应索引遍历）；④ label 冒号语法 `break :label value` 中间有空格

- [x] **Step 5: 一致性自检 + Commit**

Run: `ls zig/docs/` 应有 4 个文件；`grep -c "坑位清单" zig/docs/0[1-4]*.md` 每文件 ≥1；正文引用的示例小节号与 `grep "═══" zig/examples/0[2-4]_*/main.zig` 对齐。

```bash
cd G:/code/guide && git add zig/docs
git commit -m "docs(zig): 第 01–04 章——全景、第一个程序、类型、控制流"
```

---

### Task 12: docs/05–08 章

**Files:**
- Create: `zig/docs/05-functions.md`、`06-slices.md`、`07-structs.md`、`08-enums.md`

- [x] **Step 1: 写 05-functions.md（约 200 行）**

小节：5.1 基本形态与显式类型；5.2 defer（LIFO、块级、与错误路径关系——**本教程把 defer 提前到函数章讲**，内存章/错误章复用）；5.3 comptime 参数（泛型预告）；5.4 anytype 与 @TypeOf（print 原理）；5.5 嵌套函数不能捕获；5.6 没有重载：三种替代（comptime T、anytype、参数结构体，示例 5.7）；坑位：① 无默认参数→参数结构体；② 无重载同名冲突直接编译错；③ defer 在 return 表达式求值后执行；④ 递归函数需要显式返回类型（不能靠推导）。

- [x] **Step 2: 写 06-slices.md（约 240 行，概念密度高）**

小节：6.1 数组是值（赋值拷贝、len 进类型）；6.2 切片 = 胖指针（ptr+len 图示 ASCII）；边界检查与安全模式；6.3 字符串真相（`*const [N:0]u8` → `[]const u8`，UTF-8 只是字节，`{s}` 打印）；6.4 哨兵 `[:0]`（cz[cz.len] 为 0；与 C 互操作的地基）；6.5 指针三兄弟表（`*T`/`[*]T`/`[*:0]T` + `?*T` 可选指针零开销一瞥）；6.6 const 与可变切片（`[]const u8` 视角）；坑位：① 字符串 len 是字节数不是字符数；② 切片指向栈数组逃逸后悬空；③ `arr` 与 `&arr` 在函数传参时的类型差异；④ 修改字面量（`*const`）编译错；⑤ for 遍历切片是拷贝值（要改用 `|*v|` 或索引）。

- [x] **Step 3: 写 07-structs.md（约 200 行）**

小节：7.1 字段与默认值（必须全初始化，缺省字段可省）；7.2 方法与 self（值/指针两种，自动取址 `p.translate(...)` 语法糖）；7.3 类型即命名空间（关联常量/静态函数/关联变量）；7.4 匿名 struct 与 `.{}` 字面量真身；7.5 元组（匿名字段、.len 编译期）；7.6 文件即 struct（@import 的模块观）；7.7 init/deinit 惯例（与 C++ 构造/析构对照：**Zig 没有构造函数**，初始化就是普通函数）；坑位：① 部分初始化漏字段编译错；② self 值传递后修改无效；③ 元组不能运行期索引；④ struct 字段默认值不能引用其他字段。

- [x] **Step 4: 写 08-enums.md（约 200 行）**

小节：8.1 enum 基础与方法、@tagName/@intFromEnum/@enumFromInt；8.2 enum(u8) 与非穷尽 `_`（C 互操作场景）；8.3 tagged union：union(enum)（图示 tag+payload 内存布局）；8.4 switch 捕获 `|val|`（读错激活字段 = 安全模式 panic，错误用法演示）；8.5 packed struct（位域对照 C bitfield、@bitCast 整体取位）；8.6 与 C++ variant/optional 的对照表；坑位：① 非穷尽枚举漏 else；② packed struct 字段顺序影响位布局（写 C 头文件对照时按声明顺序）；③ union 未初始化读取是 UB→Debug 下也能抓；④ enum 值必须唯一/可表达。

- [x] **Step 5: 一致性自检 + Commit**

```bash
cd G:/code/guide && git add zig/docs
git commit -m "docs(zig): 第 05–08 章——函数、切片、结构体、枚举联合"
```

---

### Task 13: docs/09–12 章

**Files:**
- Create: `zig/docs/09-optionals-errors.md`、`10-errors-advanced.md`、`11-allocators.md`、`12-collections.md`

- [x] **Step 1: 写 09-optionals-errors.md（约 220 行）**

小节：9.1 ?T 与 null（类型安全）；9.2 解包三件套 if/orelse/.?；9.3 error set（编译期集合、@errorName）；9.4 !T 与显式/推断集合（`fn f() !T` vs `fn f() E!T` 怎么选）；9.5 try 语法糖；9.6 catch 值/块/|err|；9.7 if-else 捕获错误联合；9.8 错误集合并集 `||`；对照表：?T vs !T vs C 返回码 vs C++ optional/expected；坑位：① .? 遇 null 直接 panic（只用于"逻辑上不可能"）；② catch 吞错误不打印是坏味道；③ 错误集合膨胀（推断集合跨函数传染，库边界写显式集合）；④ `?*T` 与 `*?T` 是两个东西。

- [x] **Step 2: 写 10-errors-advanced.md（约 220 行）**

小节：10.1 errdefer（回滚演示，与 defer 对照表：成功/失败路径各自跑什么）；10.2 分配-初始化模式（create→errdefer destroy→初始化，本教程最重要的惯用法之一）；10.3 ?!T 解包顺序（orelse 先剥 null，catch 后剥 error）；10.4 错误返回跟踪（贴实测 Debug 输出，说明只有 Debug/ReleaseSafe 有、零成本设计）；10.5 panic/@panic/unreachable 语义（程序员的错 vs 可恢复错误）；10.6 安全模式表（Debug/ReleaseSafe/ReleaseFast/ReleaseSmall × 检查项矩阵）+ @setRuntimeSafety；10.7 坑位清单：① errdefer 写在 try 之后（回滚不到已失败的分配）；② defer/errdefer 同函数混用顺序；③ unreachable 在 Debug 也是 UB 崩溃（它不是 assert）；④ panic 消息拼接要编译期字符串。

- [x] **Step 3: 写 11-allocators.md（⭐ 约 260 行，特色重点不压缩）**

小节：11.1 分配器哲学（对比 C malloc 全局堆/C++ new 隐藏分配/Rust 全局分配器——Zig 把"用什么策略"变成参数；无分配器全局状态的收益：测试注入、嵌入式、热路径可控）；11.2 Allocator 接口解剖（alloc/free/dupe/create/destroy/resize 表格；slice vs 单项）；11.3 六个分配器选型表+逐个细讲：page（底层、粒度）、DebugAllocator（泄漏检测输出贴实测、`.{}` 配置项 thread_safe）、Arena（适用：解析/请求生命周期；**arena 里不要单 free**）、FixedBuffer（reset 复用、OOM 行为）、smp_allocator（默认多线程）、testing.allocator 预告；11.4 传参惯例（第一参数 allocator；库函数永不自带分配器）；11.5 所有权约定（返回切片谁 free、toOwnedSlice 转移、文档注释写明）；11.6 调试实践（DebugAllocator 收尾 .leak 时 stderr 贴实测输出）；11.7 坑位：① 跨分配器 free；② arena.free 单个对象是 no-op 但语义坑；③ 忘 deinit（DebugAllocator 会报）；④ 大对象误用 page_allocator 碎片；⑤ c_allocator 需 -lc。

- [x] **Step 4: 写 12-collections.md（⭐ 约 240 行）**

小节：12.1 ArrayList 全 API（unmanaged 形态讲解：**0.13→0.14 变化史一小段**，为什么去 managed——减小体积/显式分配器；append/insert/pop/orderedRemove/swapRemove 对比表：保序 vs O(1)）；12.2 容量机制（ensureTotalCapacity、增长策略、toOwnedSlice 所有权转移）；12.3 AutoHashMap/StringHashMap（getOrPut 惯例、count/contains/remove/fetchRemove）；12.4 迭代与删除（迭代中删除的坑、fetchRemove 返回 Optional 结构）；12.5 排序（std.mem.sort 与比较函数、ctx 参数用途——按字段排序示例）；12.6 选型表：数组/ArrayList/BoundedArray/HashMap 族/ArrayHashMap（保序需求）；坑位：① items 与容量混淆；② 迭代器持有期间 put 触发 rehash 悬空；③ StringHashMap 键生命周期（hash 后改字节查不到）；④ swapRemove 不保序。

- [x] **Step 5: 一致性自检 + Commit**

```bash
cd G:/code/guide && git add zig/docs
git commit -m "docs(zig): 第 09–12 章——错误处理两章、分配器、集合"
```

---

### Task 14: docs/13–16 章（⭐ 核心）

**Files:**
- Create: `zig/docs/13-comptime.md`、`14-generics.md`、`15-testing.md`、`16-build.md`

- [x] **Step 1: 写 13-comptime.md（⭐ 约 260 行）**

小节：13.1 一份代码两个世界（fibonacci 两用；对照 cpp20 第 17 章 constexpr——**语言级 comptime 比可选的 constexpr 更根本**）；13.2 comptime 参数（与 runtime 参数的本质区别：类型/普通值两类）；13.3 comptime 块与 comptime var（示例 13.3/13.4）；@setEvalBranchQuota（为什么有配额：防编译期死循环）；13.4 inline for/while（展开语义、何时用：需要"每轮不同类型"时；普通循环别加 inline）；13.5 编译期断言（comptime { @compileError }、std.debug.assert 在 comptime 的用法）；13.6 comptime 函数能做什么的限制表（不能 IO/不能读运行期全局；可以：循环/分支/递归/分配？——分配不行，说明）；13.7 @compileLog 调试技巧；13.8 坑位：① 分支配额不足编译错；② comptime 递归无界；③ 把运行期值传进 comptime 参数直接编译错（这是特性不是 bug）；④ inline for 序列必须编译期已知。

- [x] **Step 2: 写 14-generics.md（⭐ 约 260 行）**

小节：14.1 类型构造器 `fn F(comptime T: type) type`（Zig 泛型 = 返回 struct 的函数；对照 C++ 模板：实例化是函数调用，报错信息更直白）；14.2 泛型容器实战（Stack(T) 全文，@This() 讲解）；14.3 anytype 与鸭子类型（对照 C++ 模板 duck typing/concepts：Zig 用 comptime 反射做"concepts"）；14.4 @typeInfo 全景表（.@"struct"/.enum/.union/.@"fn"/.int 各字段）；14.5 @field 读写与序列化模式（serde 雏形示例）；14.6 编译期代码生成（printAny；inline for 遍历 fields 生成分支）；14.7 惯用法：Stack/Queue/HashMap 都是 std 里 `fn(T) type` 的实例；14.8 坑位：① anytype 参数报错在调用处（错误信息读法）；② @typeInfo 返回联合要 switch；③ 泛型代码膨胀（每种实例化一份）；④ 反射只在 comptime（运行期没有反射，别找）。

- [x] **Step 3: 写 15-testing.md（⭐ 约 240 行）**

小节：15.1 test 块与 zig test（对照 C++ 各测试框架：**零依赖内建**）；15.2 断言族速查表（expect/expectEqual/expectEqualStrings/expectEqualSlices/expectError/expectNull，expectEqual 的类型参数陷阱）；15.3 testing.allocator（泄漏即失败——**把 11 章 DebugAllocator 的能力接进测试**，贴实测泄漏报错输出）；15.4 多文件测试（`test { _ = @import("util.zig"); }` 引用语义、zig build test 汇总）；15.5 过滤与调试（`zig test --test-filter`? 以实测为准、`-lc` 传链接参数）；15.6 doc 注释与 ///（文档习惯；zig doc 一瞥）；15.7 tmpDir 临时目录测试；15.8 坑位：① expectEqual 两参数类型必须严格一致（comptime_int vs u8 报错）；② 忘引用子模块测试没跑还以为过了；③ 测试里的 defer 才清理（expect 失败也走 defer）；④ panic 型测试用 expectError 不是 @panic。

- [x] **Step 4: 写 16-build.md（⭐ 约 260 行）**

小节：16.1 为什么构建脚本用 Zig 写（对照 CMake DSL：全功能语言+comptime+可调试）；16.2 工程解剖（build.zig/build.zig.zon/src 三件套，zig init 模板逐行讲）；16.3 step 体系（install/run/test 三个默认 step 的依赖图、b.step 自定义）；16.4 module 与多文件（root_module、@import 相对路径 vs 命名模块、创建第二个模块的完整写法）；16.5 命令行约定（`zig build run/test`、`--` 透传 args、-Doptimize/-Dtarget 标准选项）；16.6 build.zig.zon 与包管理（.name/.version/.fingerprint/.paths 字段表；`zig fetch --save=<name>=<url+hash>` 拉依赖、本地 `.{ .path = "..." }` 依赖写法、依赖在 build.zig 里 b.dependency 接线——用本地路径演示完整流程）；16.7 缓存与 zig-out（.zig-cache 增量、不要提交）；16.8 坑位：① 改 build.zig 后缓存不刷新时 `zig build --cacheless`?（实测为准）② run 透传参数忘 `--`；③ zon fingerprint 缺失报错；④ 依赖默认只编译不链接（要 addModule/import）。

- [x] **Step 5: 一致性自检 + Commit**

```bash
cd G:/code/guide && git add zig/docs
git commit -m "docs(zig): 第 13–16 章——comptime、泛型、测试、构建系统"
```

---

### Task 15: docs/17–20 章（⭐）

**Files:**
- Create: `zig/docs/17-c-interop.md`、`18-cross.md`、`19-threads.md`、`20-files-io.md`

- [x] **Step 1: 写 17-c-interop.md（⭐ 约 240 行）**

小节：17.1 extern fn 手写声明（c_int 等映射表、变参函数）；17.2 @cImport 实战（**必须 -lc**；c 命名空间、常见错误 "libc headers not available"）；17.3 export fn（C ABI 导出、调用约定表 c/inline；`zig build-lib` 产 .dll/.a 一瞥）；17.4 extern struct（布局保证、与 packed struct 对照、对齐 align）；17.5 c"..." 字符串与 `[*:0]const u8`（0.16 实测状态，c 字面量若已移除以勘误为准）；17.6 std.mem.span 双向桥；17.7 translate-c 工作流（`zig translate-c header.h > bindings.zig`、什么时候用它替代 @cImport：需要看代码/裁剪/预生成）；17.8 链接 C 源码（build-exe 混编、build.zig 里 addCSourceFile 写法示例段落）；17.9 坑位：① -lc 忘加；② Windows 上 printf 缓冲与退出码；③ C 头里的宏不是函数（@cImport 后是常量）；④ 结构体对齐差异（extern struct 必须）。

- [x] **Step 2: 写 18-cross.md（⭐ 约 240 行）**

小节：18.1 -target 三段式语法与 `zig targets` 查询；18.2 实战交叉编译（build.ps1 实际执行的命令逐条解释：aarch64-linux 产物用 qemu/wsl 验证的一段话）；18.3 为什么零配置（内置各 libc 源码、交叉是第一公民——对比 C 交叉工具链地狱）；18.4 wasm32-freestanding（--no-entry、export fn、无 OS 无 std 高层设施；产物给 wasmtime/node 的示例命令）；18.5 wasm32-wasi（有 OS 抽象、能 std.debug.print，一段命令演示，本地无 wasmtime 则只讲编译）；18.6 zig cc / zig c++（hello.c 实测命令、当 drop-in 编译器、交叉编 C `-target`、与 clang 的关系）；18.7 musl 静态链接（`-target x86_64-linux-musl` 一段话 + 命令）；18.8 坑位：① freestanding 没有 main/std 大部分；② Windows GNU vs MSVC ABI 二选一（默认原生）；③ 交叉产物在本机不能跑（验证=编译过）；④ -target 拼错架构名时 `zig targets` 对照。

- [x] **Step 3: 写 19-threads.md（约 220 行）**

小节：19.1 spawn/join/detach（spawn 配置项 .stack_size）；19.2 Mutex（去掉锁的实验：正文演示输出错乱/丢计数）；19.3 atomic.Value（方法表 fetchAdd/fetchSub/compareExchange/load/store；内存序三档 monotonic/acq_rel/seq_cst 实用建议表：计数用 monotonic、发布数据用 acq_rel、拿不准 seq_cst）；19.4 Condition + 有界队列（经典双条件模板全文精讲：while 不是 if 的原因——虚假唤醒）；19.5 WaitGroup（startMany/finish/wait）；19.6 线程与分配器（DebugAllocator(.{.thread_safe=true})? 实测配置项、smp_allocator）；19.7 async 的历史（一段话：已移除，Io 接口是未来方向，链接 20 章）；19.8 坑位：① detach 后用句柄；② 忘 join 主线程先退；③ Condition.wait 不在 while 里；④ 持锁做耗时 IO。

- [x] **Step 4: 写 20-files-io.md（约 240 行）**

小节：20.1 std.fs 心智模型（cwd()/绝对路径/Dir；对照 C++ filesystem）；20.2 写：Dir.writeFile 一行式 + createFile+writer 分解式（trunc/append 选项表）；20.3 读：readFileAlloc（上限参数的意义）；20.4 0.16 新 Writer/Reader（**Io 接口为什么重构**：缓冲所有权归调用者、io 参数可接异步后端；本教程只教同步用法 File.writer(io,&buf)+flush）；20.5 目录（makePath/openDir(.iterate)/iterate entry.kind、deleteTree）；20.6 statFile 与元数据；20.7 路径（path.join/basename/dirname/resolve、跨平台分隔符）；20.8 std.json（Stringify.value + parseFromSlice/Parsed(T).deinit 生命周期、动态 Value 一小段）；20.9 坑位：① 忘 flush；② readFileAlloc 上限传太小；③ 迭代目录时删条目；④ json 字符串借用 Parsed 内存（deinit 后悬空）；⑤ Windows 路径大小写与 WTF-8。

- [x] **Step 5: 一致性自检 + Commit**

```bash
cd G:/code/guide && git add zig/docs
git commit -m "docs(zig): 第 17–20 章——C 互操作、交叉编译、并发、文件 IO"
```

---

### Task 16: docs/21–24 章

**Files:**
- Create: `zig/docs/21-asm.md`、`22-process.md`、`23-debugging.md`、`24-minigrep.md`

- [x] **Step 1: 写 21-asm.md（约 200 行）**

小节：21.1 asm 语法解剖（模板串/输出/输入/破坏四段、`\\` 多行、具名操作数 `{[r]}`——**0.14 从 %[r] 改形**的历史一段）；21.2 约束速查（"r"/"+r"/"=r"/固定寄存器 "{eax}"）；21.3 volatile 何时要（有副作用的指令）；21.4 AT&T 语法提醒（Zig x86 默认 AT&T：`add $5, {[r]}` 读法）；21.5 实战 rdtsc 计时；21.6 comptime 架构守卫（@compileError 模式、builtin.cpu.arch switch）；21.7 extern struct/@bitCast/packed（C ABI 工具箱）；21.8 坑位：① 忘列 clobber 破坏寄存器；② 无 volatile 被优化掉；③ 用 Intel 语法写模板串；④ MSVC 目标差异（实测为准）。

- [x] **Step 2: 写 22-process.md（约 200 行）**

小节：22.1 argv 跨平台真相（Windows 原生 UTF-16 → Init.minimal.args；Iterator 抹平；对照 0.13 的 argsAlloc）；22.2 环境变量（environ_map、getEnvMap 旧 API 对比）；22.3 子进程 Child.run（argv/env/cwd 选项表、拿 stdout/stderr/term）；22.4 更细控制（spawn + pipe 一瞥）；22.5 currentPath 与路径处理串联；22.6 时间（timestamp/nanoTimestamp/Thread.sleep/timer 模式）；22.7 退出码语义（main 返回 error → 非零）；22.8 坑位：① Windows 上 argv[0] 编码差异；② Child.run 的 argv 是字符串切片不是 shell 命令（要 shell 用 cmd /c）；③ nanoTimestamp 单调性不保证跨平台；④ 环境变量名大小写（Windows 不敏感）。

- [x] **Step 3: 写 23-debugging.md（约 200 行）**

小节：23.1 三层排错观：编译错（comptime）→ panic（运行期断言）→ 错误跟踪（error 传播）；23.2 panic 栈跟踪（贴实测输出；触发方式 ZIG_PANIC=1）；23.3 错误返回跟踪（贴实测输出 ZIG_ERT=1；与 panic 栈的区别）；23.4 assert/@panic/unreachable/@breakpoint 分工表；23.5 LLDB 实战（编译默认带调试信息；`zig build-exe -g`? 实测说明；break/print/bt 命令表——沿用旧 README 的命令表修正版）；23.6 std.debug.print 的线程安全与 stdout 混排注意；23.7 微基准与 Release 对比（示例 23.2 数据 + 优化等级表）；23.8 工具链收尾（zig fmt/ast-check/doc/targets/fetch 速查表）；23.9 坑位：① ReleaseFast 下 assert 消失踪之bug；② 栈跟踪行号不准时 `--strip=false`?（实测）；③ @breakpoint 无调试器直接崩；④ 环境变量开关法的好处（构建不变行为变）。

- [x] **Step 4: 写 24-minigrep.md（约 240 行，实战收官）**

小节：24.0 需求与效果演示（贴真实高亮输出）；24.1 工程结构（build.zig/zon/src 分层：search 纯逻辑 + main 编排——**可测试性设计**）；24.2 search.zig 精讲（splitScalar 行迭代、indexOf、Match 借用语义、printHighlighted 的 ANSI 转义）；24.3 递归目录遍历（walkDir 递归、entry.kind 分派、错误容忍策略）；24.4 多线程模型（原子游标抢任务 vs 队列分发；WaitGroup 收工；Mutex 只护合并——设计取舍讨论）；24.5 main 编排（argv 解析、arena 统一回收——**11 章哲学的实战应用**、缓冲输出）；24.6 测试（searchLines 单测 + tmpDir 端到端；测试与实现同步演进）；24.7 扩展练习（正则? 大小写不敏感 -i、并行读文件、彩色开关）；24.8 坑位：① 二进制文件误当文本搜（可以加魔数检查——练习）；② Windows 控制台 ANSI 支持需 Win10+（VT 开关，一段说明）；③ 高亮输出进管道时建议关颜色（isTty 判断，实测 API）；④ 文件读取上限防超大文件。

- [x] **Step 5: 一致性自检 + Commit**

```bash
cd G:/code/guide && git add zig/docs
git commit -m "docs(zig): 第 21–24 章——汇编、进程、调试、实战迷你 grep"
```

---

### Task 17: 清理旧文件 + README + CHEATSheet + .gitignore

**Files:**
- Delete: `zig/examples/`（旧 108 个）、`zig/snippets/`、`zig/build.sh`、`zig/README.md`（旧）
- Create: `zig/README.md`（新）、`zig/CHEATSheet.md`
- Modify: `.gitignore`（若无 `zig-out/`、`.zig-cache/`、`zig/build/` 条目则补）

**Interfaces:**
- Consumes: 全部 24 章 docs 与 23 个示例（README 索引表与之对应）。

- [x] **Step 1: 删旧文件（git rm）**

```bash
cd G:/code/guide && git -c core.quotepath=false rm -r -q zig/examples zig/snippets zig/build.sh zig/README.md
```
（中文文件名须 `core.quotepath=false`——cpp20 时的教训；删除后 `git status` 应只剩新增。）

- [x] **Step 2: 写 zig/README.md（对齐 cpp20 README 结构，约 70 行）**

内容：标题 `# Zig 编程指南（0.16）`；一段定位（会编程、初学 Zig；0.16 现代写法为主线；每章"读讲解→跑示例→改代码再跑"，三层验证全过）；目录结构树（README/docs/examples/build.ps1/CHEATSheet）；24 章索引表（章/主题/示例三列，特色章加 ⭐）；构建工具链（zig 0.16.0 路径、构建模式说明）；验证命令块（-All / -Example / -Clean，pwsh 7 说明）；与其他教程互链（cpp20/rust/dlang 对照一句话）。

- [x] **Step 3: 写 zig/CHEATSheet.md（约 200 行）**

分区（速查 + 坑位索引双职能）：
1. 命令速查：run/build-exe/build-lib/test/build/fmt/cc/translate-c/fetch/targets（一行一命令）
2. 类型与字面量：整数位宽/溢出运算符/转型家族表
3. 控制流与解包：if/while/for/switch/orelse/./try/catch 速记
4. 错误与可选：!T/?T/?!T/errdefer 模式卡
5. 分配器选型卡（六分配器一表）
6. 集合 API 卡（ArrayList/HashMap 常用一行）
7. comptime 卡（参数/块/inline/@typeInfo）
8. 0.16 迁移坑位索引：ArrayList unmanaged、Io.File、Init 入口、@cImport -lc、args UTF-16、Writer flush——每条一行 + 对应章号

- [x] **Step 4: .gitignore 检查**

Run: `grep -nE "zig-out|\.zig-cache|zig/build" G:/code/guide/.gitignore`
若无则追加：
```
zig-out/
.zig-cache/
zig/build/
```

- [x] **Step 5: 根 README 核查 + Commit**

Run: `grep -n "zig" G:/code/guide/README.md`——有 zig 条目则按新结构微调描述；无则跳过。

```bash
cd G:/code/guide && git add -A zig .gitignore README.md
git commit -m "docs(zig): 重写 README、新增 CHEATSheet、清理旧示例与 snippets"
```

---

### Task 18: 终验（全量 -All + 一致性 + 记忆收尾）

**Files:**
- Modify: 本计划文件（勾选 + 执行勘误）
- Create: `G:\xulun\.claude\projects\G--code-guide\memory\zig-tutorial-build.md` + 更新 `MEMORY.md`

- [x] **Step 1: 全量验证**

```bash
cd G:/code/guide/zig && pwsh -NoProfile -File build.ps1 -All
```
Expected: 23 个示例全部三层验证通过（16/24 工程分支、17 -lc、18 交叉编译分支），末尾 `[Done] 全部示例三层验证通过。`。任何失败：修复后重跑（不放过）。

- [x] **Step 2: 结构一致性检查**

```bash
cd G:/code/guide/zig
ls docs/ | wc -l                      # = 24
ls examples/ | wc -l                  # = 23
for f in docs/[0-9][0-9]-*.md; do n=${f:5:2}; grep -q "examples/${n}_" $f && echo "OK $f"; done
grep -L "坑位清单" docs/*.md          # 应无输出（每章都有坑位清单）
grep -c "═══" examples/*/main.zig examples/*/src/*.zig | awk -F: '$2==0'   # 应无输出（每个示例有分节标记）
```
README 章节索引表逐行与 `ls docs/` 比对。

- [x] **Step 3: 勾选计划 + 填执行勘误**

把本文件所有 `- [ ]` 改 `- [x]`；在文末"执行勘误"区记录实施中实际发生的 API 偏差与修法（cpp20 流程）。

- [x] **Step 4: 写记忆并提交**

`memory/zig-tutorial-build.md` 要点：24 章结构（章号=示例号）、0.16 实测坑（Init 入口、Io.File、ArrayList unmanaged、@cImport -lc、Windows args UTF-16、Writer flush、asm `{[r]}` 语法、build.zig 模板要点）、build.ps1 特判分支、CHEATSheet 位置。更新 `MEMORY.md` 索引一行。

```bash
cd G:/code/guide && git add docs/superpowers/plans/2026-09-17-zig-tutorial-rewrite.md
git commit -m "docs: 勾选 zig 教程实施计划全部任务并记录执行勘误"
```

---

## 执行勘误

实施（2026-09-17）中实际发生的偏差与修正，均已同步进示例代码与章节正文：

**语言/标准库 API（来源：各示例编译实测）**

1. `@floatFrom` 不存在 → 正名 `@floatFromInt`（Task 2 / 03 章）。
2. `@truncate` 只接受无符号整数，i32 输入要先 `@intCast`（Task 2 / 03 章）。
3. **comptime 已知的越界 `@intCast` 是编译错**（不是运行期 panic）——教学点写入 03.6（Task 2）。
4. 0.16 格式化：数组/切片不能用 `{d}`，须 `{any}`（Task 2 起全程适用）。
5. **Zig 不允许函数体内声明 `fn`**——5.5 节改讲"匿名 struct 命名空间"惯用法（Task 3 / 05 章）。
6. 有符号除法 `/` 禁用，须 `@divTrunc/@divFloor/@divExact`（Task 3 / 05 章坑位）。
7. `?!T` 不可解析——可选-错误联合必须写显式集合 `?E!T`；`catch` 不能直接作用于它，先 `orelse`（Task 4 / 10.3）。
8. 非穷尽枚举的未知值调 `@tagName` 是编译错（Task 4 / 08 章坑位）。
9. `tokenizeSequence` 是整段匹配；字符集分隔用 `tokenizeAny`（Task 5 / 11 章）。
10. `ArrayList.pop()` 返回 `?T`；`std.BoundedArray` 已从 0.16 移除——12.6 改"数组+计数"（Task 5 / 12 章）。
11. 容器级 const 里 `comptime` 关键字 redundant 报错；顶层 const 天然编译期（Task 6 / 13.3）。
12. `inline for` 不支持索引捕获（Task 6 / 13.5）。
13. `std.testing.expectNull` 已移除，用 `expect(opt == null)`（Task 7 / 15 章）。
14. zon 包名必须是合法标识符（`@"16_build"` 也不行）；fingerprint 与包名绑定，写 `0x0` 后按编译器提示值替换（Task 7/10 / 16 章）。
15. `c"..."` C 字符串字面量已移除——普通字面量即 0 结尾直接传（Task 8 / 17 章）。
16. `--no-entry` 旗子已移除——freestanding wasm 用 `zig build-lib`（Task 8 / 18 章）。
17. **`std.fs.File/Dir` 并入 `std.Io`**：`Io.Dir.cwd()`，writeFile/readFileAlloc/createFile/openDir/statFile/deleteFile/deleteTree/close/iterate().next() 全部带 io 参数；`makePath` 改名 `createDirPath`；Windows 下 `openDir` 不开 `.iterate = true` 迭代时 AccessDenied（Task 9 / 20 章）。
18. `std.Thread.Mutex/Condition` 移入 `std.Io`：`.init` 命名常量初始化、lock/unlock/wait/signal 带 io；`WaitGroup` 已移除（join 即同步点）；`Thread.sleep` 没了（Task 9 / 19 章）。
19. `std.time` 只剩常量：计时用 `std.Io.Timestamp.now(io, .awake/.real)`（Clock 枚举是 real/awake/boot，没有 monotonic）；sleep 是 `(std.Io.Clock.Duration{ .raw = Io.Duration.fromMilliseconds(n), .clock = .awake }).sleep(io)`——`Io.Duration` 上没有 sleep（Task 10 / 22 章）。
20. argv：`std.process.Args.Iterator.initAllocator(init.minimal.args, alloc)` + `deinit` + `skip`；Windows 原生 args 是 UTF-16（Task 10 / 22 章）。
21. 子进程：`std.process.run(gpa, io, .{ .argv })`（`Child.run(.{})` 旧形态失效）（Task 10 / 22 章）。
22. 内联汇编模板占位是 `%[名]`（AT&T），`{[名]}` 是不存在的旧提案语法（Task 9 / 21 章）。

**流程教训（Task 17）**

23. `git rm -r zig/examples` 会把**同路径下已提交的新示例一并删除**——清理旧文件须逐个列出旧路径或先移动；误删后 `git checkout HEAD~1 -- <path>` 恢复，且 checkout 写盘是 CRLF、`zig fmt` 归一为 LF 后 `--check` 才过。
24. bash 循环里 `case "|$d" in *"$keep"*)` 方向写反（应判 d 在 keep 集合中）会把保留集删光——恢复靠 git 历史，教训是破坏性循环先 echo 演练。

**验证结论**：`build.ps1 -All` 23 个示例三层验证全过（fmt + test + 运行 exit 0；16/24 走 zig build 工程；17 加 -lc；18 含 aarch64-linux/wasm 交叉编译与 zig cc）。
