# 01 · 全景：Zig 是什么，为什么值得学

> 本章无示例（从第 02 章起每章配一个可运行示例）。

## 1.1 一段话定位

Zig 是一门**直接的、显式的、零运行时**的系统编程语言——自称"C 语言的现代继任者"。它保留 C 的心智模型（手动管理内存、贴近硬件、编译成原生代码），但把 C 里靠纪律和运气的东西变成语言保证：错误是类型（不是返回码约定）、没有隐藏控制流（没有异常、没有宏、没有运算符重载）、分配器是显式参数（不是藏在 malloc 后面的全局堆）、编译期计算是一等公民（comptime 替代预处理器宏）。

一句话：**Zig 是一门更好的 C，不是一门更好的 Rust**。它不承诺编译期内存安全，换来的是极低的心智负担和与 C 的无缝互操作。

## 1.2 设计哲学四大支柱

| 支柱 | 做法 | 对比 |
|---|---|---|
| 无隐藏控制流 | 没有异常、没有宏、没有运算符重载、没有隐藏分配 | C++ 的构造函数/异常/RVO 都是"看不见的代码" |
| 显式分配器 | 内存从哪来是参数：`fn f(allocator, ...)` | C 的全局 malloc、C++ 的 new、Rust 的全局分配器 |
| 错误即类型 | `!T` 错误联合 + `try`/`catch`，编译器强制处理路径 | C 的 errno 约定、Go 的多返回值 |
| comptime | 编译期执行是同一种语言（不是宏语言、不是模板语言） | C 预处理器、C++ 模板元编程是"另一门语言" |

第 09/10 章讲错误、第 11 章讲分配器、第 13/14 章讲 comptime——这四样是 Zig 的灵魂，也是本教程着墨最多的部分。

### 与 C / C++ / Rust 对照

| 特性 | Zig | C | C++ | Rust |
|---|---|---|---|---|
| 内存安全 | 可选运行期检查 | 无 | 部分（智能指针） | 编译期强制 |
| 错误处理 | `!T` 类型化 | 返回码 | 异常/expected | Result 枚举 |
| 泛型 | comptime type 参数 | 无 | 模板 | trait + 泛型 |
| 编译期计算 | comptime（同语言） | 预处理器 | constexpr（可选） | const fn（受限） |
| C 互操作 | 一等公民（`@cImport`/translate-c） | 本尊 | 兼容 C 但重 | 需要 FFI 声明 |
| 交叉编译 | 内置任意目标 | 要配工具链 | 要配工具链 | 一般 |
| 学习曲线 | 低（语言小） | 低（语言小坑多） | 高 | 高 |
| 运行时 | 零 | 零 | 有（异常/RTTI） | 接近零 |

## 1.3 版本现状：0.16，黎明前

Zig 尚未到 1.0（本文写作时最新 **0.16.0**）。代价是标准库仍在破坏性演进——0.13 到 0.16 连续三次大改：

| 版本 | 破坏性变化（本教程直接相关） |
|---|---|
| 0.14 | `ArrayList` 转向 unmanaged 形态（分配器成为方法参数） |
| 0.15 | Writer/Reader 全面重构（"Writergate"），缓冲所有权归调用者 |
| 0.16 | `std.fs.File/Dir` 并入 `std.Io`；`Mutex/Condition` 移入 `std.Io` 且带 `io` 参数；新增 `std.process.Init` main 入口；`WaitGroup`、`BoundedArray`、`std.time` 计时函数、`c"..."` 字面量移除 |

**这意味着：网上多数教程/博客的代码（0.13/0.14 时代）直接照抄会编译不过**。本教程所有代码在 0.16.0 实测通过，每章末尾的"坑位清单"专门收录这些迁移差异——即使你读的是旧资料，也能对上号。

## 1.4 工具链一览

一个 `zig` 二进制就是全家桶：

| 命令 | 用途 | 本教程 |
|---|---|---|
| `zig run x.zig` | 编译 + 立即运行（开发节奏最快） | 02 章 |
| `zig build-exe / build-lib` | 产可执行文件 / 库 | 02、18 章 |
| `zig test x.zig` | 跑 test 块（测试内建于语言） | 15 章 |
| `zig build` | 按 build.zig 描述构建工程 | 16 章 |
| `zig fmt` | 官方格式化（格式即规范） | 02 章 |
| `zig cc / zig c++` | 当 C/C++ 编译器用（交叉编译白送） | 18 章 |
| `zig translate-c` | 把 C 头文件翻译成 Zig 绑定 | 17 章 |
| `zig fetch` | 包管理：拉取并登记依赖 | 16 章 |
| `zig targets` | 列出全部支持的目标三元组 | 18 章 |
| `zig init` | 生成工程骨架 | 16 章 |
| `zig doc` / `zig ast-check` | 文档生成 / 语法诊断 | 23 章 |

## 1.5 安装与版本管理

```powershell
# Windows（scoop，本教程环境）
scoop install zig
# 或 chocolatey
choco install zig
```

```bash
# macOS
brew install zig
# Linux：官网下载解压即可（无依赖、单文件）
wget https://ziglang.org/download/0.16.0/zig-linux-x86_64-0.16.0.tar.xz
```

多版本管理用 **zvm**（Windows 友好）或 **zigup**：`zvm install 0.16.0 && zvm use 0.16.0`。验证：`zig version` → `0.16.0`。

## 1.6 本教程怎么学

- **读者定位**：会编程（C/C++/Rust 背景最佳），从零学 Zig。不教编程本身。
- **主线是 0.16 现代写法**：`std.Io` 新接口、`Init` 入口、unmanaged 集合从第一天就是默认姿势，旧写法只在坑位里教"认得"。
- **每章节奏**：读讲解 → 跑示例 → 改代码再跑。示例全在 `examples/NN_topic/`，章号 = 目录号。
- **三层验证**：`build.ps1` 对每个示例执行 `zig fmt --check`（格式）+ `zig test`（断言）+ `zig build-exe` 运行 exit 0——全部通过才收工，你手上的代码是可信的。
- 与本仓库其他教程对照：[cpp20](../cpp20/README.md)（同为系统语言主线）、[rust](../rust/README.md)、[dlang](../dlang/README.md)。

## 1.7 坑位清单

1. **版本坑（最大的坑）**：网上资料多为 0.13/0.14 语法——`std.ArrayList(T).init(alloc)`、`std.io.getStdOut()`、`std.fmt.print` 这些已不存在或已改名。看到编译错先查版本。
2. **`zig run` 传参要 `--`**：`zig run main.zig -- arg1 arg2`，否则参数被当成文件名（报 "unrecognized file extension"）。
3. **中文乱码**：Windows 控制台先 `chcp 65001`（本仓库 build.ps1 已代设 UTF-8）。
4. **源文件须 UTF-8 无 BOM**：带 BOM 的 .zig 文件直接编译错。
5. **官网文档滞后于版本**：ziglang.org 的语言手册讲语法（大体稳定），但 std 文档要看本机 `zig` 对应版本——读标准库源码（`G:\scoop\apps\zig\0.16.0\lib\std\`）是最可靠的文档，这不是玩笑是日常。
