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
- [algol68](./algol68) — Algol 68 教程与示例（20 章对齐 cobol 标准：上戳写法 / 模式 mode 系统 / 一切皆表达式 / 自定义运算符与优先级 / 过程与闭包（含作用域规则）/ 行·结构·联合·引用 / transput 文件 / FORMAT 格式化 / 事件式异常 / 内建并行 PAR·SEMA / 测试方法论 / 库存管理实战），使用 Algol 68 Genie 3.13.3（macOS MacPorts + clang 后端，解释器+C 后端二合一）双通道验证（check `--warnings --notices` / release `-O2`，四条判定 + 两通道输出逐字节一致），18 个示例（02–19）全部通过，双入口 `run-all.sh` / `build.ps1`，CHEATSheet 收录约 130 条实测坑位，详见 [algol68/README.md](./algol68/README.md)
- [android](./android) — Android 应用开发教程（Kotlin），含 Jetpack Compose 与 JNI 示例，使用 Kotlin/Gradle/NDK 验证
- [asm/intel](./asm/intel) — x86-64 汇编编程指南，双平台验证：Windows 用 NASM + MSVC link.exe，macOS 用 NASM `-f macho64` + clang/ld（56 个 macOS 示例全部实际编译运行通过）
- [boost](./boost) — Boost C++ 教程与示例，使用 MSVC + Boost 头文件验证
- [coq](./coq) — Coq 教程与示例，使用 coqc 批量编译验证
- [clojure](./clojure) — Clojure 教程与示例（28 章分章文档 docs/ + CHEATSheet 46 语言坑 8 工具坑 / 24 示例 + lein-lab 工程），双工具链验证：Windows 用 Leiningen 2.13 + OpenJDK 26（`build.ps1`，25 个验证单元全绿），macOS 用 Clojure CLI 1.12.6（`build.sh`）；覆盖函数式编程 / 惰性序列 / 宏 / 多方法 / 记录与协议 / 并发与 STM / Java 互操作 / clojure.spec / Transducer / 性能优化（类型提示实测 537 倍）/ core.async / Ring Web 真实 HTTP / Leiningen 全流程（test→uberjar→java -jar）/ MiniLisp 解释器压轴（TCO + 33 断言）
- [cobol](./cobol) — GNU COBOL 教程与示例（20 章对齐 freepascal/freebasic 标准：固定格式列位 / PIC 数据模型 / PERFORM / 表与 SEARCH / 子程序与 C 互操作 / 三类文件 / 状态码异常 / SCREEN 终端界面 / 控制break 报表 / 测试方法论 / 库存管理实战），使用 GnuCOBOL 3.2.0（macOS MacPorts + clang 后端）双通道验证（check `-Wall -std=default` / release `-O2`，六条判定 + 两通道输出逐字节一致），18 个示例（02–19）全部通过，双入口 `run-all.sh` / `build.ps1`，CHEATSheet 收录 106 条实测坑位，详见 [cobol/README.md](./cobol/README.md)
- [cpp20](./cpp20) — C++ 从零到 C++20/23 教程（24 章 + 迷你 grep 实战）；Windows 走 MSVC 主线，macOS/Linux 用 clang++ 23（自带 libc++）+ g++ 15 双工具链对照，23 个示例 × 2 通道全部通过，双入口 `run-all.sh` / `build.ps1`，六条判定（退出码 0 + stderr 空 + 编译零告警 + 输出非空 + 无控制字符 + 结束标记），详见 [cpp20/README.md](./cpp20/README.md) 的「macOS / Linux 上的兼容性」
- [dart](./dart) — Dart 语言入门与示例，使用 Dart SDK 验证
- [dlang](./dlang) — D 语言教程与示例（26 章 + 25 个示例），使用 DMD 2.113.0 / DUB 1.42.0 双层验证（`-w -unittest` 全绿 + 编译产物运行 exit 0），**Windows + Linux + macOS 三平台**实测；macOS 侧记录 3 个环境坑（未签名二进制在 `~/` 下 unlink EPERM 致 dub 缓存起不来、无动态 libphobos、无 dman），详见 [dlang/README.md](./dlang/README.md)
- [emacs](./emacs) — Emacs Lisp 扩展开发教程与示例，使用 Emacs 31.1 `--batch` 验证（26 个示例，双入口 `run-all.sh` / `build.ps1`，四条判定标准：编译零警告 + 运行 stderr 为空 + 无多余控制字符 + 结束标记）
- [dotnet](./dotnet) — .NET 教程与示例工程，使用 .NET SDK (`dotnet build`) 验证
- [elixir](./elixir) — Elixir 1.20.2/1.20.4 · OTP 29 教程（24 章对齐 haskell/julia 标准：模式匹配/不可变性/Enum 管道/Unicode/协议/进程消息/Task/Agent/GenServer/监督树细讲，零外部依赖、离线可验证，macOS + Windows/scoop 双轨实测；23 个独立 mix 工程五层验证 format+零告警编译+test+运行+单调度器逐字节一致；24 收官项目=纯函数核心+容错缓存+并发词频 worker，杀 worker 显式重试、杀服务监督自愈；CHEATSheet 收录 36 条实测坑位（stdio latin1 转义/任务崩溃即调用方 exit/async 仍 link/:kill 不可 trap/Etc/UTC，Windows 三坑：autocrlf 检出 CRLF 须 .gitattributes 强制 LF、raw 文件 pread 挪顺序指针、escript 须经 escript.exe 运行），详见 [elixir/README.md](./elixir/README.md)）
- [erlang](./erlang) — Erlang/OTP 教程与示例，使用 erlc 编译验证（Erlang/OTP 29 / erts 17.0.3，28 个示例 × 2 通道全部通过；双入口 `run-all.sh` / `build.ps1`，四条判定标准 + 两通道输出逐字节一致；30 章指南正文约 4300 行）
- [freebasic](./freebasic) — FreeBASIC 教程与示例（24 章对齐 dlang/go 标准：GFX 内置图形、多线程、C 互操作、-lang qb 方言各独立成章），使用 fbc 1.10.1（win64）双层验证（`-g -exx` 断言+边界检查 / 发布形态 × 四条判定：退出码 0、stderr 空、stdout 非空、含 [OK] 标记），23 个示例全部通过（22 章含 `-lang qb` 第三通道；24 章贪吃蛇确定性回放逐字节一致）
- [freepascal](./freepascal) — FreePascal/Lazarus 开发指南（24 章对齐 cpp20/freebasic 标准：语言 13 章 ⭐含字符串编码深水区 + LCL GUI 9 章 ⭐控件两章 + 实战记事本+），**Windows + macOS 双平台实测**：FPC 3.2.2 x86_64-win64（Lazarus 4.8 自带，win32 控件集）与 macOS 12.7 x86_64-darwin（MacPorts，cocoa 控件集）；多层验证（CLI 检查/发布双通道 × 五条判定 + 输出逐字节比对；GUI lazbuild + `--selftest` 无头日志断言 × 60s 超时），23 个示例 × 46 项两个入口全部通过且结论一致，CHEATSheet 收录 55 条实测坑位（含 4 条 macOS 新增：`cwstring` / `cthreads` / `Extended` 宽度 / `external` 库名）
- [fsharp](./fsharp) — F# 编程教程与示例，使用 .NET SDK (`dotnet build` / `dotnet run`) 验证
- [flutter](./flutter) — Flutter / Dart 跨平台 UI 教程与示例，使用 Flutter 桌面编译验证
- [forth](./forth) — Forth / GForth 教程与示例，使用 gforth 0.7.3 运行验证（含栈平衡与 stderr 检查）
- [fortran](./fortran) — 现代 Fortran（F2018）教程与示例，使用 LLVM flang 23.1.0 + GNU Fortran 15.2.0 双编译器验证（22 个示例 × 2 通道全部通过）
- [sml](./sml) — Standard ML（SML'97）教程与示例，使用 SML/NJ 110.99.9 + Poly/ML 5.9.2 + MLton 20241230 三实现验证（22 个示例 × 3 通道，20 个逐字节一致 + 2 个已登记差异）
- [ocaml](./ocaml) — OCaml 教程与示例（31 章 / 26 示例），Windows MSYS2 UCRT64 OCaml 5.4.1 + **macOS 12.7 MacPorts OCaml 5.5.0 双平台验证**（macOS 侧两个入口各 77/77：25 示例 × 3 通道 + ocamllex × 2，零告警），覆盖模块系统 / functor / GADT / Domain+Effect 并发 / 绑定运算符 / ocamllex / 综合实战，附 Windows 六坑与 macOS 坑两节
- [llvm](./llvm) — LLVM 应用开发教程（24 章 / 24 示例），Windows MSYS2 UCRT64 **LLVM 22.1.8 完整版**主线实测（scoop clang 23 为精简版无 opt/lli/开发库——只能当前端工具集），覆盖手写 IR / 类型系统与 GEP / SSA 与 phi / 优化管线 / 新 PM pass 插件 / IRBuilder / Value 对象模型 / llc 交叉 / ORC LLJIT JIT / MiniLang 九章连载（前端→IR→JIT→可变变量→自定义运算符→优化层→短路逻辑→统计 pass→原生 .exe，压轴曼德博 ASCII + 四路径一致性回归）/ FileCheck 测试 / clang 工具链 / llvm-project 源码导览；`build.ps1 -All` 24/24 全绿（每步退出码 + 输出标记 + FileCheck/一致性断言），CHEATSheet 收录 23 条实测坑位（PassPlugin 搬家 / ConstantExpr 删除 / CloneFunction 双重插入死循环 / 跨 Context 类型错乱 / dllexport / PowerShell 吞 `--` 等）
- [go](./go) — Go 1.27 教程（24 章对齐 cpp20/zig 标准：接口/泛型/迭代器/测试/并发三连细讲，全部示例四层验证 gofmt+vet+test+运行，并发章加 -race）
- [godot](./godot) — Godot 4 / GDScript 教程与示例，使用 Godot headless 执行脚本验证
- [julia](./julia) — Julia 1.13 教程（24 章对齐 cpp20/zig 标准：多重派发/类型系统/广播/元编程/性能/Pkg 环境细讲，23 个示例三层验证运行+测试+工程，24 为迷你 ODE 求解器包工程——问题-算法-解三件套 + 自适应步长 + 收敛阶测试）
- [haskell](./haskell) — Haskell 教程（GHC 9.12.1，24 章对齐 julia/swift 标准：模式匹配/ADT/类型类/惰性求值/函子-应用-单子/单子变换器/parsec/TH/STM 特色细讲，主线纯 boot 库离线可验证；23 个示例两层验证 编译+运行+测试 六条判定，20/24 为 stack 工程（清华镜像 + compiler 覆盖实测链路），24 为 MiniLang 迷你解释器——词法/语法/求值三层管线 + 递归绑定打结 + 词法作用域闭包；CHEATSheet 收录 32 条实测坑位（GBK 编码/runghc 41s/-Wx-partial/惰性句柄锁/优先级表序/坏 strip shim）
- [prolog](./prolog) — Prolog 逻辑编程教程（24 章对齐 haskell/julia/elixir 标准：合一/回溯/剪枝/DCG 解析/动态库/元编程/CLP(FD)/模块与加载边界/测试与性质测试细讲；23 个示例 × **三通道** SWI 解释 + GNU 解释 + `gplc` 本地二进制，六条判定含**跨通道输出区间逐字节比对**，`run-all.sh` 与 `build.ps1` 双入口均 119/0 全绿；24 为四百行迷你语言解释器——词法→DCG 分层语法→环境求值→断言与错误路径测试，其中两处语义（整除 `//`、比较返 1/0）是被可移植性逼出来的；双引擎差异是主线教学材料：GNU 无模块系统且**静默忽略** `module/2`、`consult/1` 往 stdout 打编译进度、`gplc` 静态链接需 `=..`+`call/1` 绕符号解析、CLP(FD) 两套独立实现需可移植适配层、`%` 在格式串里语义不同；CHEATSheet 收录 **226 条实测坑位** + 跨引擎「安全子集」清单）
- [io](./io) — Io 语言教程（24 章对齐 haskell/julia/elixir/prolog 标准：纯原型对象模型 / 三种消息形状与优先级 / 槽与 proto 链 / 块与闭包 / `try`-`catch`-`signal` / 协程与 Future / 元编程内省 / `DynLib` FFI 细讲；Io 从源码编译（CMake + `build.sh`），**不用包管理器里的老版本**；23 个示例 × **两条通道**（动态链接 `io` + 静态 `io_static`）**七条判定**含跨通道输出区间逐字节比对，`run-all.sh` 与 `build.ps1` 双入口均 **94/0** 全绿；24 为访问日志分析器（解析 → 聚合 → 排序 → 渲染 → 落盘）；CHEATSheet 收录 **240 条实测坑位**——其中一批是「跟直觉相反」的硬骨头：未捕获异常横幅走 **stdout** 且退出码仍是 **0**、`try(expr)` 成功也返回 `nil`、无参 `split` **按字节**扫空白（`"上" split` 得 `list("")`）、`"abc" asNumber` 给 **`nan`** 而不是 0、`method(...)` 造的块 `isActivatable=true` 一进形参就被零参调用（`withHandler` 的处理器**必须**用 `block(...)`）、`do(...)` 里逗号分隔的槽定义只有第一个被求值且看不见外层局部槽（要 `lexicalDo`）、`setEnvironmentVariable(name, nil)` **段错误** rc=139、`DynLib` 调浮点签名 C 函数（`pow(2,10)` ≠ 1024）返回的是整数寄存器残留——详见 [io/README.md](./io/README.md)）
- [renpy](./renpy) — Ren'Py 视觉小说与叙事游戏教程，使用 Ren'Py `compile` 验证
- [kotlin](./kotlin) — Kotlin 2.4 教程（24 章对齐 cpp20/zig/go/rust 标准：空安全/密封与穷尽 when/委托/型变 reified/作用域函数/扩展/协程+Flow/Java 互操作/DSL 细讲，24 个示例四层验证 kotlinc -Werror + kotlin.test + 运行 + 输出快照；17 为 Gradle 多模块工程（JUnit5 + fat jar），18 为 Java/Kotlin 混编两遍法，24 为迷你待办 CLI（手写 JSON 解析器 + 文件存储 + 退出码约定），25 为多平台四目标（js/wasm-js/wasm-wasi/native；native 需 konanc，macOS 无包时跳过）。macOS 与 Windows 双平台实测，classpath 分隔符与产物后缀差异已由脚本吸收）
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
- [swift](./swift) — Swift 6.3.3 教程（24 章对齐 cpp20/rust/go/zig 标准：可选/协议/some-any/actor/Sendable/swift-testing/SPM 特色细讲，23 个示例四层验证 format+build+test+run；scoop 6.4.0 坏包实测复盘，钉 6.3.3 + 环境三件套配方）
- [csharp](./csharp) — C# 语言教程（36 章 + 36 示例，章号=示例号，零 NuGet 依赖：编译 + 逐个运行验证；C# 14 扩展成员实测；实战为 MiniLang 表达式解释器）
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
32. [csharp](./csharp)
32. [zig](./zig)
33. [lean4](./lean4)
34. [forth](./forth)
35. [prolog](./prolog)
36. [fortran](./fortran)
37. [sml](./sml)
38. [ocaml](./ocaml)
39. [cobol](./cobol)
40. [haskell](./haskell)
41. [algol68](./algol68)
42. [llvm](./llvm)
43. [io](./io)

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
- GnuCOBOL 3.2.0 / cobc（COBOL；macOS macports 安装 `/opt/local/bin/cobc`，clang 后端 COBOL→C→原生；Linux/Windows 用发行版包或官方构建；固定格式源码 UTF-8，含中文行须 ≤72 字节）
- Algol 68 Genie 3.13.3 / a68g（Algol 68；macOS macports 安装 `/opt/local/bin/a68g`，解释器 + clang 后端 a68g→C→原生二合一；Linux/Windows 用发行版包或官网 algol68genie.nl 构建；上戳写法源码 UTF-8，关键字全大写，扩展名 `.a68`；macOS `-O2` 链接缺 `-syslibroot`，脚本用 `ld` 垫片修复）
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
- OCaml 5.5.0 / ocamlc / ocamlopt / ocamllex（macOS macports 安装 `/opt/local/bin`，三通道对照：字节码 + 原生 + 顶层解释器；用到 `Unix` 的示例必须 `-I +unix`，否则 OCaml 5 会吐弃用告警）
- LLVM 22.1.8 完整版（MSYS2 UCRT64：opt/lli/llc/llvm-config/FileCheck + g++ 16.2 + libLLVM 开发库，scoop msys2 + `pacman -S mingw-w64-ucrt-x86_64-llvm{,-tools,-libs}`；注意 scoop 的 llvm 23 是精简 clang 工具集，做不了 IR 实操；llvm-project 源码参考 `G:\github\lang\llvm-project`）
- Julia 1.13.0（macOS 实测通道：MacPorts `/opt/local/bin/julia`；Windows 可 scoop/juliaup；两个验证入口都自动探测，不硬编码路径）
- Io（**从源码编译**：CMake + `build.sh`，落在 `~/.workbuddy/binaries/io/bin/{io,io_static}`；**刻意不用包管理器里的 Io** —— 发行版自带的多停在 2009 年，缺 `actorRun`/`Future`/`serialized` 产物格式等本教程依赖的行为；两条通道语义相同、只差加载方式，跨通道逐字节比对用来查「示例有没有偷偷依赖动态库加载或安装前缀」；核心库 `lib/io/*.io` 是**用 Io 自己写的**）
- SWI-Prolog 10.0.2 + GNU Prolog 1.5.0 / gplc（逻辑编程，macOS macports 安装）
- Ren'Py
- Rust 1.98.1 / cargo 1.98.0（edition 2024；macOS 实测通道：MacPorts `/opt/local/bin/cargo`；Windows 可 scoop/rustup；两个验证入口都自动探测，不硬编码路径）
- SBCL 2.6.7（Common Lisp；macOS macports 安装 `/opt/local/bin/sbcl`，Windows scoop 安装；sbcl 目录示例有意绑定 SBCL 扩展，为**单实现通道**）
- Swift
- Kotlin Compiler 2.4.20（macOS：MacPorts `/opt/local/share/java/kotlin`；Windows：scoop。两个验证入口 `run-all.sh` / `build.ps1` 自动探测 JDK 21；Kotlin/Native（konanc）macOS 上无包，25 章 native 目标自动跳过）
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
