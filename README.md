# Guide 导航索引

这是 `F:\code\programming` 根目录下的教程与示例总览，统一收录各语言/技术栈的入门指南、可运行代码示例以及验证状态。

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
- [cpp20](./cpp20) — C++ 从零到 C++20/23 教程（24 章 + 迷你 grep 实战）；Windows 走 MSVC 主线，macOS/Linux 用 clang++ 23（自带 libc++）+ g++ 15 双工具链对照，23 个示例 × 2 通道全部通过，双入口 `run-all.sh` / `build.ps1`，六条判定（退出码 0 + stderr 空 + 编译零告警 + 输出非空 + 无控制字符 + 结束标记），详见 [cpp20/README.md](./cpp20/README.md) 的「macOS / Linux 上的兼容性」
- [dart](./dart) — Dart 语言入门与示例，使用 Dart SDK 验证
- [dlang](./dlang) — D 语言教程与示例，使用 DMD 编译验证
- [emacs](./emacs) — Emacs Lisp 扩展开发教程与示例，使用 Emacs 31.1 `--batch` 验证（26 个示例，双入口 `run-all.sh` / `build.ps1`，四条判定标准：编译零警告 + 运行 stderr 为空 + 无多余控制字符 + 结束标记）
- [dotnet](./dotnet) — .NET 教程与示例工程，使用 .NET SDK (`dotnet build`) 验证
- [elixir](./elixir) — Elixir 教程与示例，使用 elixirc 编译验证
- [erlang](./erlang) — Erlang/OTP 教程与示例，使用 erlc 编译验证（Erlang/OTP 29 / erts 17.0.3，28 个示例 × 2 通道全部通过；双入口 `run-all.sh` / `build.ps1`，四条判定标准 + 两通道输出逐字节一致；30 章指南正文约 4300 行）
- [freebasic](./freebasic) — FreeBASIC 教程与示例（24 章对齐 dlang/go 标准：GFX 内置图形、多线程、C 互操作、-lang qb 方言各独立成章），使用 fbc 1.10.1（win64）双层验证（`-g -exx` 断言+边界检查 / 发布形态 × 四条判定：退出码 0、stderr 空、stdout 非空、含 [OK] 标记），23 个示例全部通过（22 章含 `-lang qb` 第三通道；24 章贪吃蛇确定性回放逐字节一致）
- [freepascal](./freepascal) — FreePascal/Lazarus 开发指南（24 章对齐 cpp20/freebasic 标准：语言 13 章 ⭐含字符串编码深水区 + LCL GUI 9 章 ⭐控件两章 + 实战记事本+），FPC 3.2.2 x86_64-win64（Lazarus 4.8 自带）多层验证（CLI 检查/发布双通道 × 四条判定 + 输出逐字节比对；GUI lazbuild + `--selftest` 无头日志断言 × 60s 超时），23 个示例全部通过，CHEATSheet 收录 46 条实测坑位
- [fsharp](./fsharp) — F# 编程教程与示例，使用 .NET SDK (`dotnet build` / `dotnet run`) 验证
- [flutter](./flutter) — Flutter / Dart 跨平台 UI 教程与示例，使用 Flutter 桌面编译验证
- [forth](./forth) — Forth / GForth 教程与示例，使用 gforth 0.7.3 运行验证（含栈平衡与 stderr 检查）
- [fortran](./fortran) — 现代 Fortran（F2018）教程与示例，使用 LLVM flang 23.1.0 + GNU Fortran 15.2.0 双编译器验证（22 个示例 × 2 通道全部通过）
- [sml](./sml) — Standard ML（SML'97）教程与示例，使用 SML/NJ 110.99.9 + Poly/ML 5.9.2 + MLton 20241230 三实现验证（22 个示例 × 3 通道，20 个逐字节一致 + 2 个已登记差异）
- [ocaml](./ocaml) — OCaml 教程与示例，使用 ocamlc 字节码编译器验证（22 个示例，25 章教程，覆盖模块系统 / functor / 可变状态 / 算法 / 解析 / 综合实战）
- [go](./go) — Go 1.27 教程（24 章对齐 cpp20/zig 标准：接口/泛型/迭代器/测试/并发三连细讲，全部示例四层验证 gofmt+vet+test+运行，并发章加 -race）
- [godot](./godot) — Godot 4 / GDScript 教程与示例，使用 Godot headless 执行脚本验证
- [julia](./julia) — Julia 1.13 教程（24 章对齐 cpp20/zig 标准：多重派发/类型系统/广播/元编程/性能/Pkg 环境细讲，23 个示例三层验证运行+测试+工程，24 为迷你 ODE 求解器包工程——问题-算法-解三件套 + 自适应步长 + 收敛阶测试）
- [prolog](./prolog) — Prolog 逻辑编程教程与示例，使用 SWI-Prolog 10.0.2 + GNU Prolog 1.5.0 双引擎验证（含 gplc 编译通道）
- [renpy](./renpy) — Ren'Py 视觉小说与叙事游戏教程，使用 Ren'Py `compile` 验证
- [kotlin](./kotlin) — Kotlin 2.4 教程（24 章对齐 cpp20/zig/go/rust 标准：空安全/密封与穷尽 when/委托/型变 reified/作用域函数/扩展/协程+Flow/Java 互操作/DSL 细讲，23 个示例四层验证 kotlinc -Werror + kotlin.test + 运行 + 输出快照；17 为 Gradle 多模块工程（JUnit5 + fat jar），18 为 Java/Kotlin 混编两遍法，24 为迷你待办 CLI（手写 JSON 解析器 + 文件存储 + 退出码约定））
- [lean4](./lean4) — Lean4/Mathlib4 教程与示例，使用 Lake + Lean 校验
- [iosdev](./iosdev) — iOS 应用开发教程（Xcode / Swift / Objective-C / SwiftUI / UIKit，20 章 + 20 个示例），使用 Xcode 16.2（Swift 6.0.3）+ iOS 18.2 SDK 在 iPhone 模拟器里验证（20 个示例 × debug/release 两配置全部通过，两配置 stdout 逐字节一致；示例全部纯命令行编译成 headless 自测，`simctl spawn` 跑，含 ObjC 语言与混编、SwiftUI 主线（状态/布局/列表/绘图动画）、UIKit 补充（Auto Layout/列表复用/手势响应链）、网络并发、持久化、权限通知、打包签名上架；`tools/check_docs.py` 做文档快照漂移检查，详见 [iosdev/README.md](./iosdev/README.md) 的「验证状态」节）
- [macosdev](./macosdev) — macOS 应用开发教程（Xcode / Swift / Objective-C / Cocoa / AppKit，20 章 + 20 个示例），使用 Xcode 16.2（Swift 6.0.3）SDK + Command Line Tools 双工具链验证（20 个示例 × 2 通道全部通过，双通道输出逐字节一致；示例全部纯命令行编译，含 Objective-C 语言与混编、XIB/nib 编译与 outlet 连线、Cocoa Bindings、打包签名；六条判定标准 + 反向验证，详见 [macosdev/README.md](./macosdev/README.md) 的「验证状态」节）
- [mfc](./mfc) — MFC 桌面应用开发指南，使用 MSVC + MFC 库编译验证
- [win32](./win32) — Win32 API 桌面编程指南，使用 MSVC + Win32 API 编译验证
- [WinUI3](./WinUI3) — WinUI 3 C++/WinRT 教程（10 篇 + README），使用 MSVC + Windows App SDK 1.8 编译验证：`examples/` 下 5 个工程（first-app / controls / layout / binding-mvvm / os-integration）经 `build.ps1` 全部编过，再用 `tools/ui-smoke/` 启动 + 合成点击 + 前后截图做运行时验证；`tools/winmd-probe/` 做元数据级签名核对。三条通道逼出的修正（WinUI 3 上 `resume_foreground` 失效须改 `DispatcherQueue::TryEnqueue`、非打包 `ApplicationData::GetDefault()` 抛"该进程没有程序包标识符"、ViewModel IDL 须声明 `INotifyPropertyChanged`、事件处理器不必进 IDL、跨 `.idl` 引用触发 `MIDL2011` 须合并等）已写回正文，详见 [WinUI3/README.md](./WinUI3/README.md) 的「验证状态」节
- [OpenCL](./OpenCL) — OpenCL Windows 教程，使用 Visual Studio + CUDA CL 头文件验证
- [rust](./rust) — Rust 教程与示例（24 章 + 23 个 cargo 工程），四层验证：fmt + clippy `-D warnings` + test + run；macOS 12.7 上用 MacPorts rustc **1.98.1** 实测 23/23 通过（Windows scoop 同版本亦通过），双入口 `run-all.sh` / `build.ps1` 判定一致；详见 [rust/README.md](./rust/README.md) 的「macOS 上的兼容性」节
- [sbcl](./sbcl) — Common Lisp / SBCL 教程与示例，运行全部示例验证（macOS + SBCL 2.6.7，17 个示例，双入口 `run-all.sh` / `build.ps1`，四条判定：退出码 0 + stderr 为空 + 无多余控制字符 + 结束标记）；教程正文 18 章 + 2 附录，文中 521 条 `; =>` 断言由 `verify-guide.py` 逐条回跑校验（mismatch 0）
- [sdl2](./sdl2) — SDL2 C++ 教程与示例，使用 MSVC + SDL2 库编译验证
- [swift](./swift) — Swift 教程与示例，使用 swiftc 编译验证
- [wpf](./wpf) — WPF 编程指南，使用 .NET SDK + WPF 运行时验证
- [zig](./zig) — Zig 0.16 教程（24 章对齐 cpp20 标准：分配器/comptime/构建系统/交叉编译特色细讲，全部示例三层验证）

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
22. [iosdev](./iosdev)
23. [macosdev](./macosdev)
24. [win32](./win32)
25. [rust](./rust)
26. [OpenCL](./OpenCL)
27. [sdl2](./sdl2)
28. [wpf](./wpf)
29. [sbcl](./sbcl)
30. [swift](./swift)
31. [WinUI3](./WinUI3)
32. [zig](./zig)
33. [lean4](./lean4)
34. [forth](./forth)
35. [prolog](./prolog)
36. [fortran](./fortran)
37. [sml](./sml)
38. [ocaml](./ocaml)

## 工具链说明

不同目录依赖不同工具链，常见包括：

- NASM + MSVC（x86-64 汇编，Windows / win64 COFF）
- NASM + clang + ld（x86-64 汇编，macOS / macho64 Mach-O，含 Accelerate.framework）
- GNAT (MSYS2 UCRT64)
- Android SDK + Kotlin + Gradle + NDK
- Visual Studio + VC
- clang 23.1.0 + clang 自带 libc++ / GCC 15.2.0 + libstdc++（现代 C++20/23，macOS macports 安装 `clang++-mp-23` / `g++-mp-15`；Windows 侧走 MSVC cl）
- MSVC + Boost
- Coq (coqc)
- Dart SDK
- DMD
- GNU Emacs 31.1 + Emacs Lisp (ELisp)（扩展开发，`emacs -Q --batch` 非交互验证；`run-all.sh` 与 `build.ps1` 双入口）
- .NET SDK
- Elixir
- Erlang/OTP 29 / erts 17.0.3（erlc -Werror -Wall，警告即错误）
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
- Julia 1.13.0（macOS 实测通道：MacPorts `/opt/local/bin/julia`；Windows 可 scoop/juliaup；两个验证入口都自动探测，不硬编码路径）
- SWI-Prolog 10.0.2 + GNU Prolog 1.5.0 / gplc（逻辑编程，macOS macports 安装）
- Ren'Py
- Rust 1.98.1 / cargo 1.98.0（edition 2024；macOS 实测通道：MacPorts `/opt/local/bin/cargo`；Windows 可 scoop/rustup；两个验证入口都自动探测，不硬编码路径）
- SBCL 2.6.7（Common Lisp；macOS macports 安装 `/opt/local/bin/sbcl`，Windows scoop 安装；sbcl 目录示例有意绑定 SBCL 扩展，为**单实现通道**）
- Swift
- Kotlin Compiler
- MFC / Win32 桌面框架
- Xcode 16.2（Swift 6.0.3）SDK + Command Line Tools（macOS 应用开发 / Swift + Objective-C + AppKit + XIB，macports 装 `pwsh`；`ibtool` / `actool` 只在装了 Xcode.app 的机器上存在）
- Xcode 16.2（Swift 6.0.3）+ iOS 18.2 SDK + iPhone 模拟器（iOS 应用开发 / SwiftUI + UIKit + Swift + Objective-C；iOS SDK 只随 Xcode 提供，故单工具链，用 debug/release 两配置逐字节比对代替双通道；`xcrun simctl spawn` 跑 headless 自测）
- Win32 API 原生桌面编程
- CUDA OpenCL Headers
- SDL2
- .NET SDK + WPF
- MSVC + Windows App SDK 1.8 + C++/WinRT（WinUI 3；`build.ps1` 批量编译 + `tools/ui-smoke/` 运行时截图验证 + `tools/winmd-probe/` 元数据核对）
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
