# Guide 导航索引

这是 `G:\code\guide` 根目录下的教程与示例总览，统一收录各语言/技术栈的入门指南、可运行代码示例以及验证状态。

## 目录说明

本仓库包含多种技术栈的学习资料，目录按主题分组，核心目标是：

- 把教程中的代码片段整理为独立示例目录
- 保持各语言的构建/编译流程可复现
- 通过本机编译器或 SDK 进行最小验证
- 对于可运行示例统一保留 `README.md`、`build.ps1` 和示例源码目录（`examples/` 或 `cpp_examples/`）结构

## 已整理并验证的教程

这些目录已经按 “专门文件 + 示例目录 + 构建脚本” 的方式落地，并完成了编译验证：

- [Ada](./Ada) — Ada 语言教程与示例，使用 MSYS2 UCRT64 的 GNAT (`gnatmake`) 验证
- [asm/intel](./asm/intel) — x86-64 汇编编程指南，使用 NASM + MSVC link.exe 验证
- [boost](./boost) — Boost C++ 教程与示例，使用 MSVC + Boost 头文件验证
- [coq](./coq) — Coq 教程与示例，使用 coqc 批量编译验证
- [cpp20](./cpp20) — C++20 教程与示例，适配 MSVC/Windows 构建
- [dart](./dart) — Dart 语言入门与示例，使用 Dart SDK 验证
- [dlang](./dlang) — D 语言教程与示例，使用 DMD 编译验证
- [dotnet](./dotnet) — .NET 教程与示例工程，使用 .NET SDK (`dotnet build`) 验证
- [elixir](./elixir) — Elixir 教程与示例，使用 elixirc 编译验证
- [erlang](./erlang) — Erlang/OTP 教程与示例，使用 erlc 编译验证
- [freebasic](./freebasic) — FreeBASIC 教程与示例，使用 fbc 编译验证（含 FBIDE 使用说明）
- [julia](./julia) — Julia 教程与示例，使用 julia 运行验证
- [kotlin](./kotlin) — Kotlin 教程与 JVM 示例，使用 Kotlin Compiler 验证
- [lean4](./lean4) — Lean4/Mathlib4 教程与示例，使用 Lake + Lean 校验
- [OpenCL](./OpenCL) — OpenCL Windows 教程，使用 Visual Studio + CUDA CL 头文件验证
- [rust](./rust) — Rust 教程与示例，使用 rustc 编译并运行验证
- [sbcl](./sbcl) — Common Lisp / SBCL 教程与示例，使用 SBCL compile-file 验证
- [sdl2](./sdl2) — SDL2 C++ 教程与示例，使用 MSVC + SDL2 库编译验证
- [swift](./swift) — Swift 教程与示例，使用 swiftc 编译验证
- [WinUI3](./WinUI3) — WinUI 3 C++/WinRT 教程与示例，使用 MSVC (vcvars64 + cl) 验证
- [wpf](./wpf) — WPF 编程指南，使用 .NET SDK + WPF 运行时验证
- [zig](./zig) — Zig 0.16 教程与示例，已完成 0.16 兼容修正与编译验证

## 其他教程目录

这些目录已存在于 guide 根目录，但目前可能按原始文档状态保留，后续可进一步整理为同样的示例工程结构：

## 统一约定

各教程目录尽量遵循以下结构：

```text
<topic>/
├── README.md
├── build.ps1
├── <guide-file>.md
├── examples/ 或 cpp_examples/
│   ├── 01_xxx
│   ├── 02_xxx
│   └── ...
└── build/
```

其中：

- `README.md`：目录级简介和使用说明
- `build.ps1`：统一构建入口，可批量编译示例
- `examples/` / `cpp_examples/`：独立示例文件或工程目录
- `build/`：编译产物输出目录

## 建议的阅读顺序

如果按学习路径从基础到实践来读，可以按下面顺序：

1. [Ada](./Ada)
2. [asm/intel](./asm/intel)
3. [cpp20](./cpp20)
4. [boost](./boost)
5. [dlang](./dlang)
6. [dotnet](./dotnet)
7. [elixir](./elixir)
8. [erlang](./erlang)
9. [freebasic](./freebasic)
10. [julia](./julia)
11. [dart](./dart)
12. [kotlin](./kotlin)
13. [rust](./rust)
14. [OpenCL](./OpenCL)
15. [sdl2](./sdl2)
16. [wpf](./wpf)
17. [sbcl](./sbcl)
18. [swift](./swift)
19. [WinUI3](./WinUI3)
20. [zig](./zig)
21. [lean4](./lean4)

## 工具链说明

不同目录依赖不同工具链，常见包括：

- NASM + MSVC
- GNAT (MSYS2 UCRT64)
- Visual Studio + VC
- MSVC + Boost
- Coq (coqc)
- Dart SDK
- DMD
- .NET SDK
- Elixir
- Erlang/OTP
- FreeBASIC / FBIDE
- Julia
- Rust
- SBCL
- Swift
- Kotlin Compiler
- CUDA OpenCL Headers
- SDL2
- .NET SDK + WPF
- Zig 0.16

## 维护原则

- 以“可运行示例”为核心，而不是仅保存代码片段
- 示例优先兼容当前安装的工具链版本
- 对已知 API 变更做兼容修复并留下注释
- 每次新增内容后，应执行最小构建验证

---

如果你想继续扩展该导航页，可以在这里继续加入：

- 新教程新增后的状态说明
- 每个目录的学习目标
- 各教程之间的依赖关系
- 一键构建脚本总入口
