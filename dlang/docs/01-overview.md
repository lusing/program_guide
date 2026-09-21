# 01 · 全景：D 是一门什么语言

> 本章无对应示例——先建立地图，02 章开始动手。

## 1.1 一句话定位

D 是 **Walter Bright**（Digital Mars C/C++ 编译器作者）从 1999 年起设计的系统级语言：目标是"**C++ 的表达力 + C 的性能 + 现代语言的开发体验**"。2001 年发布 1.0，2010 年进入当前的 **D2**（2007 年起重构），此后语义稳定、持续小步演进——本教程基于 **DMD 2.113**。

```text
C 的性能/底层控制 ──┐
C++ 的抽象表达力 ───┼─→ D：GC 默认、契约、模板、CTFE、UFCS、ranges
Java/Python 的开发体验 ─┘
```

## 1.2 设计哲学：实用主义

| 决策 | 说明 | 对照 |
|---|---|---|
| **默认 GC，但可逃逸** | `new` 不用管释放；热路径有 `@nogc`/malloc/BetterC | Go 全家桶 GC；Zig/Rust 无 GC |
| **模板是一等公民** | 约束比 C++ concepts 早 15 年落地 | C++20 |
| **CTFE 无关键字** | 普通函数在编译期上下文自动求值 | C++ 要 `constexpr` |
| **代码生成内建** | string mixin / template mixin 是语言特性 | 其他语言靠宏/代码生成器 |
| **契约与单测内建** | `in`/`out`/`invariant`、`unittest` 块 | 生态各自造轮子 |
| **默认内存安全分级** | `@safe`/`@trusted`/`@system` | Rust 的 unsafe 思路 |
| **消息传递并发** | `shared` 类型 + std.concurrency | Erlang/Go 风格 |

## 1.3 工具链一览

| 工具 | 角色 | 本机（Win / Linux / macOS 均有） |
|---|---|---|
| **DMD** | 参考实现编译器（前端 + Digital Mars 后端），语言新特性最先落地 | 2.113.0（scoop / apt / 官方包） |
| **LDC** | 同前端 + LLVM 后端，优化激进，发布版首选 | 未安装 |
| **GDC** | 同前端 + GCC 后端，Linux 发行版标配 | 未安装 |
| **Phobos** | 标准库（`std.*`），链接形态 `libphobos2` | 随 DMD（26 章全景） |
| **druntime** | 运行时（GC、线程、TypeInfo），`core.*` | 随 DMD（26 章全景） |
| **DUB** | 官方包管理 + 构建工具（1.42） | `dub` |
| **rdmd** | "编译即运行"脚本工具 | 随 DMD（25 章深入） |

三家编译器前端一致——本教程代码三者通吃（内联汇编一节除外，那是 DMD 语法）。

## 1.4 和邻居语言的差异速览

```d
// 同一段逻辑，D 的写法（UFCS：函数当方法链）
auto result = 100.iota
    .filter!(n => n % 3 == 0)
    .map!(n => n * n)
    .array;
```

| 你来自 | 会惊讶的地方 |
|---|---|
| C++ | 没有 `->`/`&`/头文件/隐式拷贝构造；GC 默认；模板约束不用 SFINAE |
| Go | 有真正的泛型/模板、编译期求值、运算符重载、null 安全（Nullable）仍弱 |
| Zig | GC 存在且默认；comptime 对应 CTFE 但无 comptime 参数；错误处理用异常而非错误集 |
| Java/C# | struct 是值类型有 RAII；`const`/`immutable` 是传递性的；无 JVM |

## 1.5 D 的"两面"

1. **常规 D**：GC + Phobos + 全部语言特性——业务代码、工具、科研脚本。
2. **BetterC**（22 章）：`-betterC` 编译——无 GC、无运行时、无异常，D 当"更好的 C"用（语法检查、内联汇编、模板还在）。实际项目里两者可以共存（核心库 BetterC、外围常规 D）。

## 1.6 本教程怎么读

- 每章：读讲解 → 跑示例 → 改代码再跑。
- 示例全部**三平台实测**：**DMD 2.113.0（Windows x64 + Linux x86_64 + macOS x86_64）**——`dmd -w -unittest -run main.d` 通过 + 编译产物运行 exit 0；DUB 工程 `dub test`/`dub build` 通过。示例代码零平台改动（跨平台坑位都收录在各章清单，macOS 的 3 个环境坑见本章坑位 5/6）。
- ⭐ 标记的是 D 独有/招牌特性章：UFCS（05）、scope guards（09）、CTFE/mixin（12）、ranges（13/14）、消息并发（16）。
- 每章尾部**坑位清单**是本机实测踩过的坑——网上旧教程（2.07x/2.08x 时代）很多行为已变。

## 1.7 坑位清单

1. **DMD 2.11x 是当前版本**，网上大量教程停留在 2.07x（2017）：`enum` 函数、`approxEqual`、`std.json` 新 API、`Task.force` 等均已变——本教程逐条实测。
2. **Windows 上 dmd 的 `-of` 参数**：PowerShell 里必须 `'-of=name.exe'` 整体加引号，否则静默产出空名文件（详见 02 章坑位）。Linux/bash 无此坑，但建议同样整体引号 `"-ofapp"`。
3. DMD 在 Windows 用 **MSVC link.exe** 链接（自动探测 VS 安装），Linux 通过 `gcc` 驱动 GNU ld（链接 `libphobos2.a` + `libdruntime.a` + glibc），**macOS 通过 `cc`（Xcode CLT 的 clang）**，实测命令行 `cc x.o -o x -Xlinker -no_compact_unwind -L<dmd2>/osx/lib -lphobos2 -lpthread -lm`。三边都不用手动指定库，但 macOS 必须先装 Xcode Command Line Tools。
4. Windows 中文控制台乱码先 `chcp 65001`（build.ps1 已代设 UTF-8）；Linux / macOS 终端原生 UTF-8 无需处理。
5. **macOS 官方包的二进制未签名**：`codesign -v dmd` 报 "code object is not signed at all"。在策略严格的机器上，未签名进程对 `~/` 下文件 `unlink` 会返回 **EPERM**，最典型的症状是 `dub` 起手就崩：`Failed to remove file ~/.dub/cache/.../__dub_write_test_XXXX: Operation not permitted`。两条路：`export DUB_HOME=<非 $HOME 目录>`（build.sh 在 Darwin 上已自动这么做），或 `codesign -s - <dmd2>/osx/bin/*` 做 ad-hoc 签名（实测签名后 unlink 立即正常）。
6. **macOS 没有动态版 libphobos**：官方包只给 `osx/lib/libphobos2.a`（24 MB），`-defaultlib=libphobos2.so` **静默无效**（产物体积与静态版一致），`-defaultlib=libphobos2.dylib` 则链接报 `library 'libphobos2.dylib' not found`。26 章"瘦 30 倍"的动态链实验只在 Linux/WIN 成立。

---
