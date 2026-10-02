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

- [Agda](./agda) — Agda 教程（28 章分章文档 docs/：依赖类型语言与证明助手心智模型 / 类型宇宙与 Level / 数据与模式匹配 / 递归与终止检查 / 命题等式与归纳证明 / 逻辑与可判定性 / Vec·Fin·Σ 依赖编程实战 / 推理框架与同构 / 关系与抽象代数 / Monad·IO·文本·余归纳 / 反射与立方类型论 / 类型良好表达式解释器与可验证插入排序双实战 / 标准库阅读 / 106 条实测坑位收束），**章号 = 示例编号**（01–27 共 27 个示例，Ex 前缀，04/22 因 `syntax`/`codata` 是关键字用连字符），Agda 2.8.0 + stdlib 2.3（Debian/WSL）类型检查 27/27 全绿，`Ex20_io` 另 `--compile` 编译运行输出 `hello agda 42`，`build.sh` 单入口，详见 [agda/README.md](./agda/README.md)
- [Ada](./Ada) — Ada 教程与示例（19 章分章文档 docs/：全景与工具链 / 语言核心 / Tasking 并发 / 受保护对象 / Ada 2012 契约式编程 / SPARK 形式化验证压轴），**章号 = 示例编号**（17 个示例，02–18），Windows MSYS2 UCRT64 GNAT 16.1.0→16.2.0 + Linux GNAT 16.2.1 双平台实测（17/17 编译运行通过；libm / `-gnata` 平台差异已内置到脚本），双入口 `run-all.sh` / `build.ps1`，详见 [Ada/README.md](./Ada/README.md)
- [algol68](./algol68) — Algol 68 教程与示例（20 章对齐 cobol 标准：上戳写法 / 模式 mode 系统 / 一切皆表达式 / 自定义运算符与优先级 / 过程与闭包（含作用域规则）/ 行·结构·联合·引用 / transput 文件 / FORMAT 格式化 / 事件式异常 / 内建并行 PAR·SEMA / 测试方法论 / 库存管理实战），使用 Algol 68 Genie 3.13.3（macOS MacPorts + clang 后端，解释器+C 后端二合一）双通道验证（check `--warnings --notices` / release `-O2`，四条判定 + 两通道输出逐字节一致），18 个示例（02–19）全部通过，双入口 `run-all.sh` / `build.ps1`，CHEATSheet 收录约 130 条实测坑位，详见 [algol68/README.md](./algol68/README.md)
- [android](./android) — Android 应用开发教程（Kotlin，33 章分章文档 docs/：平台架构 / 工程工具链 / Kotlin 子集 / Activity 生命周期 / 传统 View 体系 / Intent / 列表 / 线程网络 / 存储 / 广播 Service 通知 / 权限硬件 / **传统深水区七章**（12–18：布局菜单样式 / 自定义 View 与绘图 / 动画三体系 / Fragment 与任务栈 / 多媒体 / 桌面组件与系统管理器 / WebView 混合开发）/ **Jetpack Compose 八章主线**（19–26：基础 / 组件 / 架构 / 状态与重组深入 / 自定义布局与绘制 / 动画进阶 / 手势处理 / 依赖注入与生态）/ **JNI/NDK 原生线六章**（27–32：边界与构建沿革 / JNI 深入（字符串·数组·NIO·域·异常·引用）/ Bionic 与 C++ 运行库 / 原生线程与同步 / POSIX Socket / 图形音频与 NEON）/ 实战 MemoPad 便签应用——传统 View 与 Compose 双 UI 范式并存），三层编译验证：`examples/` 27 条 Kotlin API 示例（kotlinc + android.jar 静态编译）+ `compose_examples/` Gradle 工程（AGP 8.7.3 / Compose 1.7.8 + fragment-ktx，compileDebugKotlin，含 70 条 Gradle 侧示例）+ JNI（NDK 30 + CMake 交叉编译 libguide_native.so，六个 cpp 镜像六个 bridge object）；运行需真机不在验证范围；build.ps1 为 UTF-8 无 BOM 须 PowerShell 7，详见 [android/README.md](./android/README.md)
- [asm/intel](./asm/intel) — x86-64 汇编编程指南，三平台验证：Windows 用 NASM `-f win64` + MSVC link.exe（61 个），macOS 用 NASM `-f macho64` + clang/ld（59 个），Linux 用 NASM `-f elf64` + `gcc -no-pie`（59 个）。macOS 侧已在 macOS 13.1/14.8.9 两套 Intel 配置上实测（13.1/Ivy Bridge 56/56，14.8.9/Haswell 59/59；本机复核修掉了 PIE 绝对地址重定位、构建脚本 BSD grep 判据、ld64 参数改名三个问题并查出 `adc_sbb` 的 `pushfq` 抓错标志位）；12 章正文 + 三份平台移植指南，含 `cpuid`/`xgetbv` 特性探测、混合架构 P核/E核 双机对照、AVX/AVX2/FMA 的 VEX 三操作数与 FMA 单次舍入（新增 3 个 AVX 示例，Windows/Linux 侧只做汇编级核查，链接与运行未实测）
- [boost](./boost) — Boost C++ 教程与示例，使用 MSVC + Boost 头文件验证
- [coq](./coq) — Coq 教程（25 章分章文档 docs/：证明助手心智模型 / 类型系统 / 归纳类型 / tactic 证明技法（归纳证明、rewrite 方向学、命题与谓词逻辑）/ 高阶函数与模块 / 实战四连（AST 求值器、列表定律、插入排序正确性、表达式解释器与优化器）/ 坑清单收束），**章号 = 示例编号**（01–24，coqc 8.20.1 编译验证全绿；25 章为 60+ 条实测坑位总清单），详见 [coq/README.md](./coq/README.md)
- [coq-hott](./coq-hott) — **Coq-HoTT（同伦类型论）教程**（25 章分章文档 docs/，**从类型论原理讲起**：命题即类型 / 依赖类型 Π 与 Σ / 恒等类型与路径归纳 / transport 与路径代数 / 等价与 hfiber / 截断层级 / 函数外延与泛等公理 / HIT（区间、圆 S¹、编码-解码）/ 类型构造器的路径 / 截断操作与商类型 / 截断映射与嵌入 / 泛等应用 / 余极限 / 范畴论 / 点化类型与环路空间 / 自然数与整数 / 元理论与证明工程 / **综合实战：圆上的螺旋覆叠**（自造覆叠 + 单值变换 + 证明 `loop ≠ 1`）/ 291 条坑位总清单），**章号 = 示例编号**（01–24 个 `.v` 示例，基于本地 HoTT 库源码 `/Volumes/mac004/lang/Coq-HoTT`，582 个 `.v` 全量编译通过），**Rocq 9.2**（MacPorts coqc）七条判定 + **运行间确定性**（区间两遍逐字节比对）；公理用量全部经 `Print Assumptions` 实测（路径代数与等价论零公理，泛等/外延单列）；另配 `build/check-docs.py` 五关文档机器核查（节号对应 / ```text 块输出行**子序列**逐字节可溯 / 坑位数一致 / 导航链 / CHEATSheet 引用），`run-all.sh` 全量模式自动追加调用；各章坑位清单合计 **291 条**（第 25 章按主题汇总，CHEATSheet 另收跨章通用 30 条与按症状速查表）（数字字面量默认不是 nat（`0` 是截断层级、`1` 是 `idpath`）、`path_universe` 不可计算致 `simpl` 失效、`HoTT.v` 不导出公理、裸 `Check` 记号报 `Abbreviation is not applied enough`、typeclass 缺信息时"任意统一"到 `ordinal_carrier ?o`/`GenNo ?S`/`CRing`、`Coeq` 变量顺序与 `Coeq_rec` 参数序、`loopexp` 在 Int/BinInt 同名遮蔽、上游 Makefile CRLF 致 bash 5 报语法错等），详见 [coq-hott/README.md](./coq-hott/README.md)
- [clojure](./clojure) — Clojure 教程与示例（28 章分章文档 docs/ + CHEATSheet 46 语言坑 8 工具坑 / 24 示例 + lein-lab 工程），双工具链验证：Windows 用 Leiningen 2.13 + OpenJDK 26（`build.ps1`，25 个验证单元全绿），macOS 用 Clojure CLI 1.12.6（`build.sh`）；覆盖函数式编程 / 惰性序列 / 宏 / 多方法 / 记录与协议 / 并发与 STM / Java 互操作 / clojure.spec / Transducer / 性能优化（类型提示实测 537 倍）/ core.async / Ring Web 真实 HTTP / Leiningen 全流程（test→uberjar→java -jar）/ MiniLisp 解释器压轴（TCO + 33 断言）
- [cobol](./cobol) — GNU COBOL 教程与示例（20 章对齐 freepascal/freebasic 标准：固定格式列位 / PIC 数据模型 / PERFORM / 表与 SEARCH / 子程序与 C 互操作 / 三类文件 / 状态码异常 / SCREEN 终端界面 / 控制break 报表 / 测试方法论 / 库存管理实战），使用 GnuCOBOL 3.2.0（macOS MacPorts + clang 后端）双通道验证（check `-Wall -std=default` / release `-O2`，六条判定 + 两通道输出逐字节一致），18 个示例（02–19）全部通过，双入口 `run-all.sh` / `build.ps1`，CHEATSheet 收录 106 条实测坑位，详见 [cobol/README.md](./cobol/README.md)
- [cpp20](./cpp20) — C++ 从零到 C++20/23 教程（35 章，按《Beginning C++23》+《The C++ Standard Library 4th》扩充指针/字符串/词汇类型/运算符重载/一等函数/继承多态/预处理器/迭代器/数值随机/时间/流 I/O/async-future + 迷你 grep 实战）；Windows 走 MSVC 主线，macOS/Linux 用 clang++ 23（自带 libc++）+ g++ 15 双工具链对照，34 个示例 × 2 通道全部通过（Windows：MSVC + scoop clang 输出逐字节一致；macOS/Linux：clang 23 + gcc 15），双入口 `run-all.sh` / `build.ps1`，六条判定（退出码 0 + stderr 空 + 编译零告警 + 输出非空 + 无控制字符 + 结束标记），详见 [cpp20/README.md](./cpp20/README.md) 的「macOS / Linux 上的兼容性」
- [cppgui](./cppgui) — C++ GUI 编程指南（**四框架四范式 24 章**：wxWidgets 保留模式 01–07 / Dear ImGui 即时模式 08–13 / FTXUI 声明式 14–19 / tvision 桌面隐喻 20–24，同一批任务四框架各写一遍），**章号 = 示例号**（25 个单文件示例，08 章 win32+D3D11 主线外附 SDL2+OpenGL3 变体），Windows MSVC x64 （CMake 4.4.3 + Ninja；wx 3.3.4 静态库预构建 / imgui 源码编入 / FTXUI·tvision add_subdirectory）`build.ps1 -Clean` 后 `-All` **从零 25/25 全绿**（5m10s），四框架 selftest 通路各异（wx=wxTimer+Close / imgui=40 帧计数 / FTXUI=无头 Post 事件 / tvision=setTimer 广播+cmQuit），`tools/check_docs.py` 五关文档核查（输出块对当前二进制子序列对账·反假绿）全绿，CHEATSheet 收录 **134 条实测坑位**（tvision 广播 clearEvent 吃事件挂死、调色板三级间接 0x87 上限、imgui SimplifiedCommon 无 Full、FTXUI ToString 自带 CRLF 叠管道 \r\r\n 等），`run-all.sh` 非 Windows 声明式跳过，详见 [cppgui/README.md](./cppgui/README.md)
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
- [fortran](./fortran) — 现代 Fortran（F2018）教程与示例（32 章分章指南，每章一个文件，对齐清华教材体系 + **31 个示例**：28 个现代 `.f90` + 3 个 FORTRAN 77 固定格式 `.f` 老格式三连），**Windows + macOS 双平台 × 双编译器**验证：LLVM flang 23（主通道）+ GNU Fortran 15/16（对照通道），四条判定（退出码 0 + stderr 空 + 无控制字符 + 结束标记）+ 两编译器 stdout 逐字节比对（8 项按设计差异已登记原因）；macOS（MacPorts flang 23.1.0 / gfortran 15.2.0）2026-09-26 全量复验 **62/62 全绿**，Windows（scoop flang 23.1.1 / MSYS2 UCRT64 gfortran 16.2.0）扩充校验同口径 **62/62 全绿**；覆盖 KIND 类型系统 / 数组与列主序 / 格式化输入输出 / 过程·模块·OOP·指针 / 泛型与 submodule / C 互操作 / OpenMP 与 do concurrent / Gauss-Jordan 求逆与 RK4 数值专题 / 调试与单元测试 / CSV 综合实战，README 收录 flang × gfortran 15 条实测差异清单、Windows 7 坑与语言级坑清单，详见 [fortran/README.md](./fortran/README.md)
- [sml](./sml) — Standard ML（SML'97）教程与示例：**33 章分章文档 + 29 个示例**（2026-09 按 Harper《Programming in Standard ML》与 Myers/Clack/Poon 两本书扩充书本篇 25–31 章：惰性与流 / 记忆化与递归挂起 / 持久队列与摊还 / n 皇后三解（option/异常/续延）/ 续延风格正则匹配器 / 归纳定律可执行化 / 词典 functor 与表示独立性），SML/NJ 110.99.9 + Poly/ML 5.9.2 + MLton 20241230 三通道验证 **87/87 全绿**（27 个逐字节一致 + 2 个已登记差异，Windows/WSL Arch 与 macOS 双环境），坑清单 47 条，详见 [sml/README.md](./sml/README.md)
- [ocaml](./ocaml) — OCaml 教程与示例（31 章 / 26 示例），Windows MSYS2 UCRT64 OCaml 5.4.1 + **macOS 12.7 MacPorts OCaml 5.5.0 双平台验证**（macOS 侧两个入口各 77/77：25 示例 × 3 通道 + ocamllex × 2，零告警），覆盖模块系统 / functor / GADT / Domain+Effect 并发 / 绑定运算符 / ocamllex / 综合实战，附 Windows 六坑与 macOS 坑两节
- [llvm](./llvm) — LLVM 应用开发教程（24 章 / 24 示例），**Windows + macOS 双平台**实测：Windows 走 MSYS2 UCRT64 **LLVM 22.1.8 完整版**（scoop clang 23 为精简版无 opt/lli/开发库——只能当前端工具集），macOS 走 MacPorts **LLVM 23.1.0**（MacPorts 没有 22；选 23 的判据是 `llvm/Plugins/PassPlugin.h` 已就位，21 还是老位置，6/7 章编不过）。覆盖手写 IR / 类型系统与 GEP / SSA 与 phi / 优化管线 / 新 PM pass 插件 / IRBuilder / Value 对象模型 / llc 交叉 / ORC LLJIT JIT / MiniLang 九章连载（前端→IR→JIT→可变变量→自定义运算符→优化层→短路逻辑→统计 pass→原生可执行文件，压轴曼德博 ASCII + 四路径一致性回归）/ FileCheck 测试 / clang 工具链 / llvm-project 源码导览；`build.ps1 -All`（Windows）与 `./run-all.sh`（macOS）均 24/24 全绿，后者另加两条判定——编译日志必须为空（`-Wall -Wextra` 零告警，抓到过一个没用到的 `BasicBlock *LBB`）与 shared/static 双通道输出逐字节一致；CHEATSheet 收录 34 条实测坑位（PassPlugin 搬家 / ConstantExpr 删除 / CloneFunction 双重插入死循环 / 跨 Context 类型错乱 / dllexport / PowerShell 吞 `--` / macOS 的 isysroot、FileCheck 缺失、JIT 符号下划线前缀、OptimizationLevel 变裸 enum 等）
- [go](./go) — Go 1.27 教程（24 章对齐 cpp20/zig 标准：接口/泛型/迭代器/测试/并发三连细讲，全部示例四层验证 gofmt+vet+test+运行，并发章加 -race）
- [godot](./godot) — Godot 4 / GDScript 教程与示例，使用 Godot headless 执行脚本验证
- [julia](./julia) — Julia 1.13 教程（24 章对齐 cpp20/zig 标准：多重派发/类型系统/广播/元编程/性能/Pkg 环境细讲，23 个示例三层验证运行+测试+工程，24 为迷你 ODE 求解器包工程——问题-算法-解三件套 + 自适应步长 + 收敛阶测试）
- [haskell](./haskell) — Haskell 教程（GHC 9.12.1，24 章对齐 julia/swift 标准：模式匹配/ADT/类型类/惰性求值/函子-应用-单子/单子变换器/parsec/TH/STM 特色细讲，主线纯 boot 库离线可验证；23 个示例两层验证 编译+运行+测试 六条判定，20/24 为 stack 工程（清华镜像 + compiler 覆盖实测链路），24 为 MiniLang 迷你解释器——词法/语法/求值三层管线 + 递归绑定打结 + 词法作用域闭包；CHEATSheet 收录 32 条实测坑位（GBK 编码/runghc 41s/-Wx-partial/惰性句柄锁/优先级表序/坏 strip shim）
- [prolog](./prolog) — Prolog 逻辑编程教程（24 章对齐 haskell/julia/elixir 标准：合一/回溯/剪枝/DCG 解析/动态库/元编程/CLP(FD)/模块与加载边界/测试与性质测试细讲；23 个示例 × **三通道** SWI 解释 + GNU 解释 + `gplc` 本地二进制，六条判定含**跨通道输出区间逐字节比对**，`run-all.sh` 与 `build.ps1` 双入口均 119/0 全绿；24 为四百行迷你语言解释器——词法→DCG 分层语法→环境求值→断言与错误路径测试，其中两处语义（整除 `//`、比较返 1/0）是被可移植性逼出来的；双引擎差异是主线教学材料：GNU 无模块系统且**静默忽略** `module/2`、`consult/1` 往 stdout 打编译进度、`gplc` 静态链接需 `=..`+`call/1` 绕符号解析、CLP(FD) 两套独立实现需可移植适配层、`%` 在格式串里语义不同；CHEATSheet 收录 **226 条实测坑位** + 跨引擎「安全子集」清单）
- [io](./io) — Io 语言教程（24 章对齐 haskell/julia/elixir/prolog 标准：纯原型对象模型 / 三种消息形状与优先级 / 槽与 proto 链 / 块与闭包 / `try`-`catch`-`signal` / 协程与 Future / 元编程内省 / `DynLib` FFI 细讲；Io 从源码编译（CMake + `build.sh`），**不用包管理器里的老版本**；23 个示例 × **两条通道**（动态链接 `io` + 静态 `io_static`）**七条判定**含跨通道输出区间逐字节比对，`run-all.sh` 与 `build.ps1` 双入口均 **94/0** 全绿；24 为访问日志分析器（解析 → 聚合 → 排序 → 渲染 → 落盘）；CHEATSheet 收录 **240 条实测坑位**——其中一批是「跟直觉相反」的硬骨头：未捕获异常横幅走 **stdout** 且退出码仍是 **0**、`try(expr)` 成功也返回 `nil`、无参 `split` **按字节**扫空白（`"上" split` 得 `list("")`）、`"abc" asNumber` 给 **`nan`** 而不是 0、`method(...)` 造的块 `isActivatable=true` 一进形参就被零参调用（`withHandler` 的处理器**必须**用 `block(...)`）、`do(...)` 里逗号分隔的槽定义只有第一个被求值且看不见外层局部槽（要 `lexicalDo`）、`setEnvironmentVariable(name, nil)` **段错误** rc=139、`DynLib` 调浮点签名 C 函数（`pow(2,10)` ≠ 1024）返回的是整数寄存器残留——详见 [io/README.md](./io/README.md)）
- [isabelle](./isabelle) — Isabelle/HOL 教程（24 章对齐 coq/lean4/agda 标准：机器当裁判的心智模型 / 项与类型 / datatype / 递归与终止性 / 归纳与 `arbitrary:` / `simp` 调教 / 两种证明风格 / 逻辑规则手动档 / 列表库 / nat 算术 / Isar 基础与进阶 / 集合与关系良基 / 函数定义深水区 / 自动化边界 / **霍尔逻辑大案例** / 代码生成 / locale / 会话工程 / 诊断 / 工程风格 / **编译器正确性收官**），**章号 = 示例编号**（`examples/T01..T24_*.thy` 扁平布局 + `ROOT` 会话 `IsaTut`），Isabelle2025-2 + polyml-5.9.2（macOS x86_64_32-darwin）四关验证：`isabelle build -D examples` 退出码 0 且日志无溃逃痕迹 + `process_theories -O` 标记区间提取 + 连跑两遍 + **区间逐字节比对**（单引擎无跨通道可比，用运行间确定性替代；实测靠这一关抓到 `parallel_print` 导致 12/24 示例消息顺序漂移，关掉后归零），24/24 全绿；正文每段输出都从 `build/` 产物抽字节；CHEATSheet 收录 **240 条实测坑位**（字面 Unicode 在项里报 `Inner lexical error` 而字面 cartouche 分隔符直接 `Malformed command syntax`、**8 个全大写词 `ALL/EX/SUM/PROD/INT/UN/INF/SUP` 被词法层整词替换**致 `definition SUM` 报 `Failed to parse prop`、`ISABELLE_HOME_USER` 与 `ISABELLE_HEAPS` 不能靠环境变量改（只有 `USER_HOME` 能改）、未签名二进制在 `~/` 下 unlink EPERM 致 SQLite `[SQLITE_IOERR_DELETE]`、归纳规则名撞构造器名、`measure` 方向、`add_assoc` → `add.assoc` 改名等），详见 [isabelle/README.md](./isabelle/README.md)
- [hol4](./hol4) — HOL4 教程（24 章对齐 isabelle/coq 标准：LCF 心智模型（定理就是 ML 值）/ 项与引号 / ML 那半边 / 内核十条规则 / 数据类型 / 递归与终止性 / 归纳与泛化 / 化简器 / 战术与算子 / 转换 / 算术 / 列表 / 量词与一阶自动化 / 集合 / 关系与闭包 / 归纳定义 / 记录 / 类型 / simpset / 自动化工具箱 / 理论与数据库 / 脚本工程 / **表达式编译器正确性收官**），**章号 = 示例编号**（`examples/NN_topic/NN_topic.sml`），HOL4 **Trindemossen 2** + Poly/ML 5.9.2（macOS x86_64，从转过 LF 的克隆 `hol4-build` 构建——上游工作副本整棵树 CRLF 会让 ml-yacc 翻车）；**两条入口**（`hol run` 与 `Holmake`）**三条通道**七条判定含**跨入口输出区间逐字节比对**，`run-all.sh` 与 `build.ps1` 双入口均 **120/0** 全绿（24 章 × 5 项）；`metis_tac`/`rw` 被喂进方向不对称的定理时会**不终止**，故脚本带看门狗（默认 120s）把它变成可诊断的失败；正文每段输出都从 `build/` 产物抽字节，另有两个机器核查：`check-quotes.py`（SML 字符串里的 ASCII 双引号，写作时踩了 6 次）+ `check-docs.py`（节号与 `sec()` 一一对应、```text 块逐字节可在产物里找到、导航链、坑位数）；CHEATSheet 收录 **240 条实测坑位**（字面量 `3` 不是 `SUC (SUC (SUC 0))` 致按 SUC 写的模式匹配算不动、`(n - m) + m = n` 在 `num` 上不成立、`metis_tac` 不展开定义/造不出 witness/做不了归纳、把 `ADD_COMM` 当重写规则喂给 `rw` 会绕圈跑不完、`CONV_TAC`/`REWR_CONV` 不钻子项、`Definition` 的定理不在 `DB.theorems` 而在 `DB.definitions`、`WF_measure` 在 `prim_recTheory` 而非 `relationTheory`、`RTC_INDUCT` 与 `RTC_INDUCT_RIGHT1` 方向相反、`tautLib.TAUT_PROVE` 接项不是战术、裸 `ARITH_CONV` 未绑定等），详见 [hol4/README.md](./hol4/README.md)
- [sel4](./sel4) — seL4 形式化验证教程（24 章，按 isabelle 教程体例搭：能力模型（对象/权利掩码/CSpace 解析/派生树 CDT/回收删除）→ 内核代码的"形状"（非确定性状态单子/错误单子/系统调用入口/解码器）→ 各类对象与调度（IPC/通知/TCB/调度/Untyped 再类型化）→ 证明工具（霍尔逻辑与 wp/不变式 `invs`）→ 精化链与信任基（A→D→cspec→ASM）→ **完整性**与**非干扰**两个安全定理 → capDL 与分区隔离收官），**章号 = 示例编号**（`examples/S01..S24_*.thy` + `ROOT` 会话 `SeL4Tut`，父会话必须是 `"HOL-Library"`——do 记号要 `Monad_Syntax`），示例**只 import `Main` / `HOL-Library`**，不依赖 l4v 会话（全量两分钟跑完，真实 l4v 构建要几小时）；Isabelle2025-2 **五关**验证：`isabelle build -D examples` 退出码 0 且日志无溃逃痕迹 + `process_theories -O` 标记区间提取 + 连跑两遍 + **区间逐字节比对** + **真实代码引用存在性检查**（`docs/` 与 `README.md` 里每个 `l4v/…`、`seL4/…` 路径都要在 `/Volumes/mac004/lang/seL4` 下 `test -e` 通过，教程不写想象中的引用），24/24 全绿；正文每段输出都从 `build/` 产物抽字节；CHEATSheet 收录 **240 条实测坑位**（`record` 字段用 `|` 分隔报 `Outer syntax error`（`|` 只属 `datatype`）、记录相等用 `rule ext` 无效须 `cases` 拆字段、等式假设在 `simp` 里方向不确定致 `fun_upd` 的 `if` 判不了要显式 `case_tac`、`type_synonym cslot = nat` 却按 `(x,0)` 用致类型冲突、`process_theories` 基线会话写 `-l HOL` 时 run.log **为空**而错误只进 stderr（表现为 24/24 区间为空）、控制字符判据用 `[[:cntrl:]]` 而非 `[^[:print:][:space:]]`（中文标记的 CJK 字节 ≥0x80 会被后者 24/24 误判）、溃逃判据须锚定横幅否则 `throwError`/`DError` 恒误报等），详见 [sel4/README.md](./sel4/README.md)
- [renpy](./renpy) — Ren'Py 视觉小说与叙事游戏教程，使用 Ren'Py `compile` 验证
- [kotlin](./kotlin) — Kotlin 2.4 教程（24 章对齐 cpp20/zig/go/rust 标准：空安全/密封与穷尽 when/委托/型变 reified/作用域函数/扩展/协程+Flow/Java 互操作/DSL 细讲，24 个示例四层验证 kotlinc -Werror + kotlin.test + 运行 + 输出快照；17 为 Gradle 多模块工程（JUnit5 + fat jar），18 为 Java/Kotlin 混编两遍法，24 为迷你待办 CLI（手写 JSON 解析器 + 文件存储 + 退出码约定），25 为多平台四目标（js/wasm-js/wasm-wasi/native；native 需 konanc，macOS 无包时跳过）。macOS 与 Windows 双平台实测，classpath 分隔符与产物后缀差异已由脚本吸收）
- [lean4](./lean4) — Lean4/Mathlib4 教程与示例，使用 Lake + Lean 校验
- [iosdev](./iosdev) — iOS 应用开发教程（Xcode / Swift / Objective-C / C / SwiftUI / UIKit，34 章七篇 + 34 个示例），使用 Xcode 16.2（Swift 6.0.3）+ iOS 18.2 SDK 在 iPhone 模拟器里验证（34 个示例 × debug/release 两配置全部通过，两配置 stdout 逐字节一致；示例全部纯命令行编译成 headless 自测，`simctl spawn` 跑，含 ObjC 语言/混编/运行时三章、C 语言层（.c + .m + Swift 三方混编）、SwiftUI 主线（状态/布局/列表/绘图动画）、UIKit 补充（Auto Layout/列表复用/手势响应链/滚动容器）、Quartz 2D 直接绘制（每条断言都回读自己提供的位图缓冲区，含 CoreText 文本、PDF 与画板案例）、Interface Builder（`ibtool` 编故事板/XIB + outlet/segue 的运行时接线）、Controller 层架构（MVC 三层与五种更新机制）、网络并发、持久化（SQLite3 与 CoreData）、权限通知、动画、音视频、传感器定位、依赖管理（SwiftPM 离线版，`swift build` 先跑一遍再交 swiftc）、设备端机器学习（Core ML：模型字节由 Swift 现场写出，仓库不入库任何 `.mlmodel`）、打包签名上架；`tools/check_docs.py` 做文档快照漂移检查，索引与「验证状态」都在 [iosdev/README.md](./iosdev/README.md)（一个 track 只留一份索引，不再单开目录页））
- [macosdev](./macosdev) — macOS 应用开发教程（Xcode / Swift / Objective-C / Cocoa / AppKit，20 章 + 20 个示例），使用 Xcode 16.2（Swift 6.0.3）SDK + Command Line Tools 双工具链验证（20 个示例 × 2 通道全部通过，双通道输出逐字节一致；示例全部纯命令行编译，含 Objective-C 语言与混编、XIB/nib 编译与 outlet 连线、Cocoa Bindings、打包签名；六条判定标准 + 反向验证，详见 [macosdev/README.md](./macosdev/README.md) 的「验证状态」节）
- [mfc](./mfc) — MFC 桌面应用开发指南，使用 MSVC + MFC 库编译验证
- [win32](./win32) — Win32 API 桌面编程指南，使用 MSVC + Win32 API 编译验证
- [winforms](./winforms) — WinForms 编程指南（**C#/F#/C++/CLI 三语言**，20 章 / 19 章示例，按《WinForm程序设计与实践》(清华 2018，OCR 目录) 骨架 + 现代 .NET 10 重写：控件族谱 / 菜单工具栏 / 对话框 / MDI / GDI+ 柱形图与验证码 / 数据绑定 / DataGridView / UI 线程模型 / AES+PBKDF2 文件保险箱 / SQLite 参数化三层 / dotnet publish 三形态实测 / 客房管理系统实战收官），02–18 章每章 csharp+fsharp+cpp 三份同功能实现——C++/CLI 走"混合模式 DLL + C# 启动器"路线（NETSDK1116 只能产 DLL、WinForms 引用须 HintPath 指目标包、/utf-8、属性名遮蔽枚举名、NuGet 不经 vcxproj 流动等实测硬事实见 docs/01），`build.ps1`（pwsh 7 + VS MSBuild）全量 0 失败、`smoke.ps1` 冒烟 55 exe 全过（含 Timer 启动竞态加 IsHandleCreated 守卫后 5/5 稳定），详见 [winforms/README.md](./winforms/README.md)
- [WinUI3](./WinUI3) — WinUI 3 C++/WinRT 教程（10 篇 + README），使用 MSVC + Windows App SDK 1.8 编译验证：`examples/` 下 5 个工程（first-app / controls / layout / binding-mvvm / os-integration）经 `build.ps1` 全部编过，再用 `tools/ui-smoke/` 启动 + 合成点击 + 前后截图做运行时验证；`tools/winmd-probe/` 做元数据级签名核对。三条通道逼出的修正（WinUI 3 上 `resume_foreground` 失效须改 `DispatcherQueue::TryEnqueue`、非打包 `ApplicationData::GetDefault()` 抛"该进程没有程序包标识符"、ViewModel IDL 须声明 `INotifyPropertyChanged`、事件处理器不必进 IDL、跨 `.idl` 引用触发 `MIDL2011` 须合并等）已写回正文，详见 [WinUI3/README.md](./WinUI3/README.md) 的「验证状态」节
- [OpenCL](./OpenCL) — OpenCL Windows 教程，使用 Visual Studio + CUDA CL 头文件验证
- [ruby](./ruby) — Ruby 4.0 教程（24 章对齐 julia/haskell/elixir 标准：类与模块/Data/Enumerable/模式匹配/块与闭包/元编程/GC 与性能/标准库/线程/Ractor 并行/Fiber/Fiddle FFI 特色细讲，23 个示例（02–24）双层验证：运行层六条判定（退出码 0 + stderr 空 + stdout 非空 + 无控制字符 + 结束标记 + 诊断字样兜底）+ minitest 测试层，双入口 `run-all.sh` / `build.ps1` 全绿；24 为迷你 Markdown→HTML 渲染器压轴（纯函数引擎 + 14 条端到端测试）；输出确定性纪律（不打印耗时/随机值，文档引用 build 产物逐字节一致）；Ruby 4.0.7 实测，CHEATSheet 收录 **274 条实测坑位**（4.0 chilled strings 告警 / case-in 不能单行 / Ractor `.take` 已删 / minitest 6 拆 mock / `Time#utc` 原地修改 / ensure return 吞异常等），详见 [ruby/README.md](./ruby/README.md)）
- [rust](./rust) — Rust 教程与示例（24 章 + 23 个 cargo 工程），四层验证：fmt + clippy `-D warnings` + test + run；macOS 12.7 上用 MacPorts rustc **1.98.1** 实测 23/23 通过（Windows scoop 同版本亦通过），双入口 `run-all.sh` / `build.ps1` 判定一致；详见 [rust/README.md](./rust/README.md) 的「macOS 上的兼容性」节
- [rustgui](./rustgui) — Rust GUI/TUI 教程（**五框架五范式 37 章**：egui 0.36 即时模式 01–09 / iced 0.14 Elm 架构 10–16 / Slint 1.18 声明式 DSL 17–23 / **GTK4 gtk4 0.11 retained 模式 24–30**（Windows 用 gvsbuild 2026.8.0 / GTK 4.22）/ 横评选型 31 / **Ratatui 0.30 即时模式 TUI 支线 32–37**），**章号 = 示例号**（35 个 cargo 工程，01/31 无示例），五大断代全按新 API 实测编写（egui 0.34/0.35 `App::ui`+统一 Panel、iced 0.13 删 Sandbox+Task、Slint 1.18 移除 `slint::testing`、GTK 4.16 DrawingArea 回调 cairo 化、ratatui 0.30 workspace 拆分），特色是**五条无头测试通道**（egui_kittest / iced_test / i-slint-backend-testing / `#[gtk::test]`+直连句柄 / TestBackend buffer 断言）让全部示例 `--selftest` 自动判卷，GTK 部分含隐形窗口 realize 与 cairo 像素断言、Ratatui 的 TestBackend 断言即"真渲染验证"（TUI 渲染边界在 buffer，vhs 录像链实测不稳后放弃）；同一待办应用五份实现（09/16/23/30/37）供 31 章横评 + 37.3 immediate mode 两端对照；rustc 1.98.1 实测 `-All` 35/35 全绿 + `tools/check_docs.py` 五关全过；CHEATSheet 收录**断代翻译表 + 100+ 条实测坑位**，详见 [rustgui/README.md](./rustgui/README.md)
- [commonlisp](./commonlisp) — Common Lisp 教程与示例（SBCL + GNU CLISP **双实现**，33 章 = 27 章语言/工程主线 + **书本实践篇 28–33**（按《Practical Common Lisp》六个 Practical：CD 数据库 where 宏三代 / 单元测试框架 / 可移植路径名库 / 垃圾邮件过滤器（有理数算术纪律）/ 二进制+ID3 合成回读 / HTML 解释器 vs 宏编译器对账）），Linux（WSL2，SBCL 2.6.8 + CLISP 2.49.95）实测 32 个示例 × **双通道**：27 个可移植示例 SBCL 与 CLISP 的 stdout **逐字节一致**（跨实现比对为第五条判定）+ 5 个 SBCL 专属章（ASDF/run-program/线程/FFI sb-alien/性能），`run-all.sh` 59/59 全绿，双入口 `build.ps1`；正文 `; =>` 断言由 `verify-guide.py` 在 docs/ 上逐条回跑（mismatch 0）；22 章收录 **27 条双实现实测差异**总账 + CHEATSheet 报错速查
- [sdl2](./sdl2) — SDL2 C++ 教程与示例（11 章 + 10 个单文件示例，跨平台代码），macOS 兼容性已校验：Apple clang 16.0.0 + MacPorts SDL2 2.32.10 下 `run-all.sh` 双通道（shared 动态 / static 静态带 frameworks）**10 示例 × 2 通道 = 20/20 通过**，`SDL_VIDEODRIVER=dummy` 无窗口会话 10/10 通过；校验逼出并修掉 3 处真实缺陷（02 无条件要 `SDL_RENDERER_ACCELERATED` 在 dummy 下必然失败→改事实降级、10 的 `unique_ptr` 析构晚于 `SDL_Quit()`→显式 `reset()`、06 的帧长/fps 无法字节比对→区间内只留跨机器恒真结论），新增 `run-all.sh` 并让 `build.ps1` 判定逐条对齐，CHEATSheet 收录 **22 条实测坑位**，详见 [sdl2/README.md](./sdl2/README.md)
- [swift](./swift) — Swift 6.3.3 教程（24 章对齐 cpp20/rust/go/zig 标准：可选/协议/some-any/actor/Sendable/swift-testing/SPM 特色细讲，23 个示例四层验证 format+build+test+run；scoop 6.4.0 坏包实测复盘，钉 6.3.3 + 环境三件套配方）
- [typetheory](./typetheory) — **类型论指南（七书为纲 × 四实现横评）**：从罗素悖论到同伦类型论的 25 章全程——无类型 λ（de Bruijn 三镜像 + Church 算术/SKK=I/Ω 机器验证）→ λ→（检查器/推导即数据/内在式三路线 + progress 完整证明）→ Curry 指派与主类型算法（Robinson 合一 + occurs check 拒 ω 实测）→ Curry–Howard（**居留项搜索器**：Peirce=0、a→a→a=2、S=1 的机器实锤 + 经典公理入账三面对照）→ λ 立方体（**mini-PTS 内核**：规则三元组即配置，λ→/λ2/λP/λω/λC 八角差别变成可执行测试）→ MLTT 十章（自造 ℕ/List/Σ/Sum + add_comm Peano 三步走、W 类型 ℕ=W Bool 编码、**加法递归方向学三连**：Coq/Agda 第一参数 vs Lean 第二参数的 defeq 缝隙各用 lia/omega/+-suc 缝合）→ 证明助手实战（rev·rev 一题三文化、Coq Extraction 提取 rev_rev 成哑元 `__`、Lean `--run` 与 **Agda MAlonzo→GHC 原生编译执行**（guardedness 旗标/`_>>_` 导入/97 模块重编三坑））→ **自包含 mini-HoTT 五章**（零公理自造 paths 库：· 与 ! 优先级、motive idpath 端点注解、q-retype 三硬仗；泛等 UA+β 公理记账制 Bool 取反新路；截断三层 + noconf；HIT 区间/圆/商公理化；S¹ 环路代数 `iterate (m+n) = iterate m · iterate n` 完整机器证明）→ 元理论（de Bruijn 提升中性律）+ 坑位总清单（Lean「冒号前参数不匹配」四连踩、Coq ltac-in-term 失灵、Agda `inductive` 保留字连目录名都拒等 **60+ 条**）；七读本（Hindley BSTT/TTAFP/TAPL 中译/Nordström 中译/HoTT 书/Farmer STT/《现代类型论的发展与应用》）逐章挂接；61 个验证单元三通道全绿（coqc 8.20.1 / WSL Agda 2.8.0+stdlib 2.3 / Lean 4.25.0 + 运行通道），`build.ps1` 单入口，CHEATSheet 记号-规则-四家语法速查，详见 [typetheory/README.md](./typetheory/README.md)
- [category](./category) — **范畴论指南（三书为纲 × 三实现横评）**：23 章全程——范畴 record（01）→ 反范畴对偶定律互译（02）→ mono/epi/iso 与泛性质推理（03-04）→ 函子与 hom-函子（05）→ 自然变换与 Godement 积（06）→ 范畴等价（07）→ **Yoneda 引理完整机器证明**（08 旗舰）→ 积/拉回/极限泛性质（09-11）→ 可表函子保积（12）→ 伴随三面孔（13-14）→ CCC 与单子（16/18）→ 幺半/Abel/层论文档章（19-21）→ 压轴串联与坑位清单（22-23）；两条暗线贯穿全书：NT 依赖字段 record 相等三文化（Coq 分量级/Agda setoid/Lean 结构 η+内核 PI）、funext 三待遇（公理/postulate/核心定理）；三书（贺伟《范畴论》研究生主线、《高级范畴论》图与泛性质+CS 章、Simmons Solutions 200+ 习题）逐章挂接；39 个验证单元三通道全绿（coqc 8.20.1 / WSL Agda 2.8.0+stdlib 2.3 / Lean 4.25.0），`build.ps1` 单入口，CHEATSheet 速查，详见 [category/README.md](./category/README.md)
- [mathlogic](./mathlogic) — **数理逻辑指南（八书为纲 × 六证明助手横评，施工中）**：01-06 章已交付——全景账本（01）→ 命题语义判定器双向可靠（02）→ 自然演绎 NJp（03）→ 经典加成五原理等价矩阵（04）→ Hilbert 系统与演绎定理（05，推导归纳元定理范本）→ 矢列演算 G 与可靠性旗舰（06）；六通道全绿：coqc 8.20.1 / WSL Agda 2.8.0 / Lean 4.25 / **Windows Isabelle2025-2（Cygwin）** / **WSL HOL4（Poly/ML 5.9.2 源码全量构建）** / **Rocq 9.1 + Coq-HoTT（597 .vo 全量构建）**；总蓝图 26 章（tableau/DPLL/BDD/直觉主义/Kripke/FOL/归结/Herbrand/不可判定/不完备/完备性/模型检查/霍尔逻辑）见 [mathlogic/PLAN.md](./mathlogic/PLAN.md)，详见 [mathlogic/README.md](./mathlogic/README.md)
- [csharp](./csharp) — C# 语言教程（45 章 + 45 示例，章号=示例号，零 NuGet 依赖：编译 + 逐个运行验证；C# 14 扩展成员实测；主线收束 MiniLang 解释器，37-42 书本实践篇，43-45 查缺补漏篇）
- [wpf](./wpf) — WPF 编程指南（**C#/F#/C++/CLI 三语言**，25 章 / 21 示例章，骨架按《WPF编程基础》(清华 2018，OCR 目录) 12 章体系 + 现代 .NET 10 重写：XAML/布局/控件族谱 / 路由事件（含自定义）/ 绑定与 MVVM 核心四连 / 样式触发器模板（含换肤）/ 验证 / DataGrid / TreeView / 绘图（含 3D 一瞥）/ 动画（含路径动画）/ 异步 / 发布三形态 / 记事本+ 实战收官），03–23 章每章 csharp(XAML)+fsharp+C++/CLI 三份同功能实现——XAML 编译器只生成 C# 分部类，F#/C++ 走纯代码 UI；C++/CLI 走"混合模式 DLL + C# 启动器"路线（NETSDK1116 / WPF 四引用含 System.Xaml / 属性名遮蔽类型名 / template 关键字等实测硬事实见 docs/01 §8），`build.ps1`（pwsh 7 + VS MSBuild）clean 全量 0 失败、`smoke.ps1` 冒烟 61 exe 全过，详见 [wpf/README.md](./wpf/README.md)
- [zig](./zig) — Zig 0.16 教程（24→34 章：原 24 章分配器/comptime/构建/交叉编译 + 书本扩充篇 25–34 十章——二进制布局/编码流处理/SIMD/目录树/文件监视（Windows RDCW extern）/网络双协议（std.Io.net AFD 缺陷实录 + ws2_32 直调）/手写 HTTP/并发进阶（Io 原语迁移 + 线程池）/SQLite winsqlite3.dll 直链 comptime 行映射/Pratt 解释器/LRU 缓存服务器，取材《Systems Programming with Zig》《Learning Zig》两书 0.16 改写实测；33 个示例三层验证 fmt+test+运行；macOS/Linux/Windows 三平台实测，21 章内联汇编 x86_64/aarch64 双实现）

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
29. [commonlisp](./commonlisp)
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
44. [isabelle](./isabelle)
45. [hol4](./hol4)
46. [ruby](./ruby)
47. [sel4](./sel4)
48. [cppgui](./cppgui)
49. [rustgui](./rustgui)
50. [category](./category)
51. [mathlogic](./mathlogic)

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
- Rocq 9.2 / coqc（Coq-HoTT 同伦类型论；macOS macports 安装 `/opt/local/bin/coqc`，`COQLIB=/opt/local/lib/coq/`；HoTT 库源码在 `/Volumes/mac004/lang/Coq-HoTT`，编译开关 `-q -noinit -indices-matter -R theories HoTT`；**上游 Makefile 与 `etc/generate_coqproject.sh` 是 CRLF 行尾**，bash 5 解析直接语法错，故用 `build-hott.sh` 以 `coqdep` + 自制两行 Makefile 绕过，582/582 个 `.vo` 编译通过）
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
- LLVM 23.1.0（**macOS 侧主线**，MacPorts `/opt/local/libexec/llvm-23`：opt/lli/llc/llvm-config + clang++-mp-23 + libLLVM（动态库与 742 个组件静态库齐备）。MacPorts 上没有 22，也不装 FileCheck 可执行文件——第 21 章用官方 `libLLVMFileCheck.a` 自链驱动；clang 必须显式 `-isysroot $(xcrun --show-sdk-path)`，否则连 `stdio.h` 都找不到）
- Julia 1.13.0（macOS 实测通道：MacPorts `/opt/local/bin/julia`；Windows 可 scoop/juliaup；两个验证入口都自动探测，不硬编码路径）
- Io（**从源码编译**：CMake + `build.sh`，落在 `~/.workbuddy/binaries/io/bin/{io,io_static}`；**刻意不用包管理器里的 Io** —— 发行版自带的多停在 2009 年，缺 `actorRun`/`Future`/`serialized` 产物格式等本教程依赖的行为；两条通道语义相同、只差加载方式，跨通道逐字节比对用来查「示例有没有偷偷依赖动态库加载或安装前缀」；核心库 `lib/io/*.io` 是**用 Io 自己写的**）
- SWI-Prolog 10.0.2 + GNU Prolog 1.5.0 / gplc（逻辑编程，macOS macports 安装）
- HOL4 Trindemossen 2 + Poly/ML 5.9.2（定理证明，macOS 从 `/Volumes/mac004/lang/hol` 转 LF 克隆到 `hol4-build` 后用 `bin/build -F` 构建：上游工作副本整棵树 CRLF 会让 `ml-yacc`（`.grm`）与 mlton 翻车；`tools-poly/poly-includes.ML` 里写 `val MLTON = NONE;`，先 `poly < tools/smart-configure.sml`；两个验证入口自动探测 `hol`，可用 `HOLBIN=` 覆盖）
- Ren'Py
- Rust 1.98.1 / cargo 1.98.0（edition 2024；macOS 实测通道：MacPorts `/opt/local/bin/cargo`；Windows 可 scoop/rustup；两个验证入口都自动探测，不硬编码路径）
- SBCL 2.6.8 + GNU CLISP 2.49.95（Common Lisp **双实现通道**：SBCL 用 `--load`、CLISP 用 `-q -q -norc -E UTF-8`；语言主线示例要求两实现 stdout 逐字节一致，线程/FFI/性能/ASDF 为 SBCL 专属章；Linux/WSL2 `pacman -S sbcl clisp`，macOS `port install sbcl clisp`，Windows scoop 装 SBCL、CLISP 官网 zip）
- Swift
- Kotlin Compiler 2.4.20（macOS：MacPorts `/opt/local/share/java/kotlin`；Windows：scoop。两个验证入口 `run-all.sh` / `build.ps1` 自动探测 JDK 21；Kotlin/Native（konanc）macOS 上无包，25 章 native 目标自动跳过）
- MFC / Win32 桌面框架
- Xcode 16.2（Swift 6.0.3）SDK + Command Line Tools（macOS 应用开发 / Swift + Objective-C + AppKit + XIB，macports 装 `pwsh`；`ibtool` / `actool` 只在装了 Xcode.app 的机器上存在）
- Xcode 16.2（Swift 6.0.3）+ iOS 18.2 SDK + iPhone 模拟器（iOS 应用开发 / SwiftUI + UIKit + Swift + Objective-C；iOS SDK 只随 Xcode 提供，故单工具链，用 debug/release 两配置逐字节比对代替双通道；`xcrun simctl spawn` 跑 headless 自测）
- Win32 API 原生桌面编程
- CUDA OpenCL Headers
- SDL2 2.32.10（macOS：MacPorts `libsdl2` + `sdl2-config`，静态链接须带 Cocoa/CoreAudio/CoreVideo 等 frameworks；Windows：scoop + MSVC `SDL2.lib`；双入口 `run-all.sh` / `build.ps1` 判定对齐）
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

