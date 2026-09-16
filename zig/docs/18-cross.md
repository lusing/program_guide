# 18 · 交叉编译与 zig cc ⭐

> 对应示例：`examples/18_cross/`（main.zig + wasm_lib.zig + hello.c）
>
> 交叉编译是 Zig 的招牌能力：**一个 `-target` 参数，四十多个目标全通**。

## 18.1 -target：三段式语法

```bash
zig build-exe main.zig -target aarch64-linux       # 架构-系统[-ABI]
zig build-exe main.zig -target x86_64-windows-gnu  # GNU ABI（mingw）
zig targets                                      # 查询全部支持的目标
```

目标写成 `arch-os-abi`（abi 可省）。`zig targets` 列出所有合法组合——包括 wasm、freestanding（裸机）这些" exotic"目标。**没有 sysroot 要配、没有工具链要装**：Zig 内置了各目标的 libc 源码，按需现场编译。本仓库 build.ps1 对 18 章示例自动执行：

```text
build-exe main.zig -target aarch64-linux   → 4 MB 的 Linux ELF（本机是 Windows！）
build-lib wasm_lib.zig -target wasm32-freestanding → 8 KB 的 wasm 模块
cc hello.c                                 → zig cc 编的 Windows exe
```

## 18.2 编译期感知目标：builtin

```zig
const builtin = @import("builtin");

std.debug.print("架构 {s}，系统 {s}，模式 {s}\n", .{
    @tagName(builtin.cpu.arch),      // .x86_64 / .aarch64 / ...
    @tagName(builtin.os.tag),        // .windows / .linux / ...
    @tagName(builtin.mode),          // .Debug / .ReleaseFast / ...
});

const arch_code: u8 = switch (builtin.cpu.arch) {   // 编译期分派
    .x86_64 => 1,
    .aarch64 => 2,
    else => 255,
};
```

`builtin` 模块描述"正在编译的目标"——全部编译期常量。`switch (builtin.cpu.arch)` 分支在**构建时**就选定（13 章 comptime 的天然应用）：aarch64 产物里根本不存在 x86_64 分支的代码。**不能运行的分支不会被编译**——这就是 `if (builtin.os.tag == .windows)` 模式平台代码不冲突的原因（else 分支里的代码在别的目标才实例化）。

## 18.3 为什么零配置

C 世界交叉编译 = 目标 sysroot + 交叉 gcc + 目标 libc + pkg-config 三件套玄学。Zig 的答案：**把 musl/glibc/mingw-w64/libunwind 等的源码打进发布包**，`-target` 一出，libc 现场为目标编译。这也是 `zig cc` 能当"万能 C 交叉编译器"的底座（18.6）。

## 18.4 wasm32-freestanding：无 OS 目标

```zig
// wasm_lib.zig——没有 main（无 OS 可言），只有导出
export fn add(a: i32, b: i32) i32 {
    return a + b;
}
```

```bash
zig build-lib wasm_lib.zig -target wasm32-freestanding   # 产 .wasm
```

freestanding = 裸机：没有 OS、没有 std 的高层设施（文件/线程/时钟全无），能用的只有语言核心 + 可计算的标准库（`std.mem` 这类纯逻辑）。入口不存在——**用 `build-lib` 产模块**（`build-exe` 会要入口 `_start`，0.16 已移除 `--no-entry` 旗子）。产物交给宿主加载：wasmtime/node（命令见下）或嵌入应用。

```bash
wasmtime run --invoke add 18_cross.wasm 3 4    # 若装了 wasmtime
```

WASI（`-target wasm32-wasi`）则是"带 OS 抽象的 wasm"——有 fd/时钟，std 更大子集可用；本机没装 wasm 运行时，教程只验证到编译通过。

## 18.5 实战姿势

```bash
# 给 Linux 服务器产静态二进制（musl：无 glibc 版本地狱）
zig build-exe tool.zig -target x86_64-linux-musl -O ReleaseFast

# 给旧 Windows 产 GNU ABI 版
zig build-exe tool.zig -target x86_64-windows-gnu
```

**验证 = 编译通过**：交叉产物本机跑不了，CI 里再上真机/qemu 冒烟。musl 静态链接是部署神器——单文件扔上去就跑，没有"目标机 glibc 太老"。

## 18.6 zig cc / zig c++：把 Zig 当 C 编译器

```bash
zig cc hello.c -o hello.exe          # 本教程 18 章实测：hello from C
zig cc -target aarch64-linux foo.c   # C 代码交叉编译，同样白送
zig c++ -std=c++20 main.cpp          # clang 兼容：多数旗子直接认
```

`zig cc` 是 clang 的前端（旗子兼容）+ Zig 的交叉底座——**C/C++ 项目也能白嫖 Zig 的交叉能力**，不用换构建系统。很多团队装 Zig 就为这个：一个 50MB 的压缩包替代整套交叉工具链。

## 18.7 坑位清单

1. **`--no-entry` 已移除**（0.16）：freestanding wasm 用 `zig build-lib`（库形态天生无入口）；`build-exe` 会找 `_start`。
2. **交叉产物本机不能跑**：aarch64 ELF 在 x86_64 Windows 上只有"编译成功"这一个信号——运行验证要在目标环境做。
3. **freestanding 里别 import std 高层设施**：文件/线程/时间全没有，`std.debug.print` 也悬——纯逻辑 + export 才是安全区。
4. **`-target` 拼写错误**：报错信息不会猜你意思——`zig targets` 对照合法值（`.x86_64` 不是 `.amd64`）。
5. **Windows 双 ABI**：默认原生 MSVC ABI，`-windows-gnu` 是 mingw——链接行为和依赖不同，混着用会出"符号找不到"的怪错。

---
