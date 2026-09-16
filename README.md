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
- [android](./android) — Android 应用开发教程（Kotlin），含 Jetpack Compose 与 JNI 示例，使用 Kotlin/Gradle/NDK 验证
- [asm/intel](./asm/intel) — x86-64 汇编编程指南，双平台验证：Windows 用 NASM + MSVC link.exe，macOS 用 NASM `-f macho64` + clang/ld（56 个 macOS 示例全部实际编译运行通过）
- [boost](./boost) — Boost C++ 教程与示例，使用 MSVC + Boost 头文件验证
- [coq](./coq) — Coq 教程与示例，使用 coqc 批量编译验证
- [clojure](./clojure) — Clojure 教程与示例，使用 Clojure CLI（`clojure` 1.12.6.1673 / Clojure 1.12.6）运行验证（20 个示例全部通过，覆盖函数式编程 / 惰性序列 / 宏 / 多方法 / 记录与协议 / 并发与 STM / Java 互操作 / clojure.spec / Transducer / 综合实战）
- [cpp20](./cpp20) — C++ 从零到 C++20/23 教程（24 章 + 迷你 grep 实战，MSVC 主线）
- [dart](./dart) — Dart 语言入门与示例，使用 Dart SDK 验证
- [dlang](./dlang) — D 语言教程与示例，使用 DMD 编译验证
- [emacs](./emacs) — Emacs Lisp 扩展开发教程与示例，使用 Emacs 31.1 `--batch` 验证（26 个示例，双入口 `run-all.sh` / `build.ps1`，四条判定标准：编译零警告 + 运行 stderr 为空 + 无多余控制字符 + 结束标记）
- [dotnet](./dotnet) — .NET 教程与示例工程，使用 .NET SDK (`dotnet build`) 验证
- [elixir](./elixir) — Elixir 教程与示例，使用 elixirc 编译验证
- [erlang](./erlang) — Erlang/OTP 教程与示例，使用 erlc 编译验证
- [freebasic](./freebasic) — FreeBASIC 教程与示例，使用 fbc 编译验证（含 FBIDE 使用说明）
- [freepascal](./freepascal) — Free Pascal / Lazarus 教程与示例，使用 fpc 编译并运行验证（Windows scoop + macOS MacPorts fpc 3.2.2 / Lazarus 4.8 双平台，12 个命令行示例 × objfpc/delphi 双模式 + 3 个 Lazarus 工程 lazbuild 构建全部通过）
- [fsharp](./fsharp) — F# 编程教程与示例，使用 .NET SDK (`dotnet build` / `dotnet run`) 验证
- [flutter](./flutter) — Flutter / Dart 跨平台 UI 教程与示例，使用 Flutter 桌面编译验证
- [forth](./forth) — Forth / GForth 教程与示例，使用 gforth 0.7.3 运行验证（含栈平衡与 stderr 检查）
- [fortran](./fortran) — 现代 Fortran（F2018）教程与示例，使用 LLVM flang 23.1.0 + GNU Fortran 15.2.0 双编译器验证（22 个示例 × 2 通道全部通过）
- [sml](./sml) — Standard ML（SML'97）教程与示例，使用 SML/NJ 110.99.9 + Poly/ML 5.9.2 + MLton 20241230 三实现验证（22 个示例 × 3 通道，20 个逐字节一致 + 2 个已登记差异）
- [ocaml](./ocaml) — OCaml 教程与示例，使用 ocamlc 字节码编译器验证（22 个示例，25 章教程，覆盖模块系统 / functor / 可变状态 / 算法 / 解析 / 综合实战）
- [go](./go) — Go 语言教程与示例，使用 Go 编译器编译并运行验证
- [godot](./godot) — Godot 4 / GDScript 教程与示例，使用 Godot headless 执行脚本验证
- [julia](./julia) — Julia 教程与示例，使用 julia 运行验证
- [prolog](./prolog) — Prolog 逻辑编程教程与示例，使用 SWI-Prolog 10.0.2 + GNU Prolog 1.5.0 双引擎验证（含 gplc 编译通道）
- [renpy](./renpy) — Ren'Py 视觉小说与叙事游戏教程，使用 Ren'Py `compile` 验证
- [kotlin](./kotlin) — Kotlin 教程与 JVM 示例，使用 Kotlin Compiler 验证
- [lean4](./lean4) — Lean4/Mathlib4 教程与示例，使用 Lake + Lean 校验
- [mfc](./mfc) — MFC 桌面应用开发指南，使用 MSVC + MFC 库编译验证
- [win32](./win32) — Win32 API 桌面编程指南，使用 MSVC + Win32 API 编译验证
- [OpenCL](./OpenCL) — OpenCL Windows 教程，使用 Visual Studio + CUDA CL 头文件验证
- [rust](./rust) — Rust 教程与示例，使用 rustc 编译并运行验证
- [sbcl](./sbcl) — Common Lisp / SBCL 教程与示例，运行全部示例验证（macOS + SBCL 2.6.7，17 个示例，双入口 `run-all.sh` / `build.ps1`，四条判定：退出码 0 + stderr 为空 + 无多余控制字符 + 结束标记）；教程正文 18 章 + 2 附录，文中 521 条 `; =>` 断言由 `verify-guide.py` 逐条回跑校验（mismatch 0）
- [sdl2](./sdl2) — SDL2 C++ 教程与示例，使用 MSVC + SDL2 库编译验证
- [swift](./swift) — Swift 教程与示例，使用 swiftc 编译验证
- [WinUI3](./WinUI3) — WinUI 3 C++/WinRT 教程与示例，使用 MSVC (vcvars64 + cl) 验证
- [wpf](./wpf) — WPF 编程指南，使用 .NET SDK + WPF 运行时验证
- [zig](./zig) — Zig 0.16 教程与示例，已完成 0.16 兼容修正与编译验证

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
2. [android](./android)
3. [asm/intel](./asm/intel)
4. [cpp20](./cpp20)
5. [boost](./boost)
6. [dlang](./dlang)
7. [emacs](./emacs)
8. [dotnet](./dotnet)
9. [elixir](./elixir)
10. [erlang](./erlang)
11. [freebasic](./freebasic)
12. [freepascal](./freepascal)
13. [fsharp](./fsharp)
14. [flutter](./flutter)
15. [go](./go)
16. [godot](./godot)
17. [julia](./julia)
18. [renpy](./renpy)
19. [dart](./dart)
20. [kotlin](./kotlin)
21. [mfc](./mfc)
22. [win32](./win32)
23. [rust](./rust)
24. [OpenCL](./OpenCL)
25. [sdl2](./sdl2)
26. [wpf](./wpf)
27. [sbcl](./sbcl)
28. [swift](./swift)
29. [WinUI3](./WinUI3)
30. [zig](./zig)
31. [lean4](./lean4)
32. [forth](./forth)
33. [prolog](./prolog)
34. [fortran](./fortran)
35. [sml](./sml)
36. [ocaml](./ocaml)

## 工具链说明

不同目录依赖不同工具链，常见包括：

- NASM + MSVC（x86-64 汇编，Windows / win64 COFF）
- NASM + clang + ld（x86-64 汇编，macOS / macho64 Mach-O，含 Accelerate.framework）
- GNAT (MSYS2 UCRT64)
- Android SDK + Kotlin + Gradle + NDK
- Visual Studio + VC
- MSVC + Boost
- Coq (coqc)
- Dart SDK
- DMD
- GNU Emacs 31.1 + Emacs Lisp (ELisp)（扩展开发，`emacs -Q --batch` 非交互验证；`run-all.sh` 与 `build.ps1` 双入口）
- .NET SDK
- Elixir
- Erlang/OTP
- FreeBASIC / FBIDE
- Free Pascal 3.2.2 (fpc) + Lazarus 4.8 (lazbuild)（Pascal / Object Pascal，Windows scoop + macOS macports 安装，objfpc / delphi 双语言模式对照）
- F# (.NET SDK)
- Flutter / Dart
- Go
- Godot 4 / GDScript
- GForth 0.7.3（Forth / 栈式语言，macOS macports 安装）
- flang 23.1.0（LLVM）+ GNU Fortran 15.2.0（现代 Fortran F2018，macOS macports 安装，双编译器对照）
- SML/NJ 110.99.9 + Poly/ML 5.9.2 + MLton 20241230（Standard ML SML'97，macOS macports 安装 smlnj/polyml，MLton 用官方 macOS 发行包 + macports 的 GMP，三实现对照）
- OCaml / ocamlc（OCaml 字节码编译器，macOS 默认安装或通过 opam 安装）
- Julia
- SWI-Prolog 10.0.2 + GNU Prolog 1.5.0 / gplc（逻辑编程，macOS macports 安装）
- Ren'Py
- Rust
- SBCL 2.6.7（Common Lisp；macOS macports 安装 `/opt/local/bin/sbcl`，Windows scoop 安装；sbcl 目录示例有意绑定 SBCL 扩展，为**单实现通道**）
- Swift
- Kotlin Compiler
- MFC / Win32 桌面框架
- Win32 API 原生桌面编程
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

## 收录与维护标准

本仓库采用统一的内容收录标准，确保每个技术栈都具备：

- 目录级说明与学习入口：`README.md`
- 可复现的本地构建脚本：`build.ps1`
- 独立示例目录：`examples/` 或 `cpp_examples/`
- 本地工具链验证记录，确保源代码真实可编译/可运行

仅当技术栈满足上述要求并已完成实际验证后，方纳入“已整理并验证的教程”列表。

## 维护说明

- 目录的命名、结构和内容需保持一致，以便于索引与维护
- 示例代码优先以当前本机安装的编译器/SDK 为准进行兼容处理
- 如 API 或工具链发生变更，应同步更新示例与验证脚本
- 新增目录时，需同步更新本导航页与相应的阅读顺序
