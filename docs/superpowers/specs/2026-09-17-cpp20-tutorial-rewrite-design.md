# cpp20 教程重写设计（2026-09-17）

## 1. 背景与问题

`cpp20/` 目录现状：单个 2467 行 `README.md` 充当整份指南（7 大章"特性手册"式组织，
每节一两句定义 + 一段代码，无递进讲解、无坑位清单）；`snippets/` 82 个代码片段
**从不参与编译**；`examples/` 16 个文件编号混乱（04、57–76），其中"模块示例"是假的
（单文件编译做不了模块，用普通函数冒充）。与 dotnet/fsharp/dart/flutter 教程标准
（docs/ 分章 + 章号=示例 + 递进讲解 + 坑位清单 + 全量编译验证）差距大。

根 `README.md` 两处引用 `cpp20`（目录名保留，仅微调描述文字）。

## 2. 目标与非目标

**目标**：重写为 24 章独立文档（每章 150–250 行，内容厚实不压缩——用户明确要求）、
章号 = 示例目录号（02–24 共 23 个示例）；定位"会编程、初学 C++，从零教到 C++20/23"，
C++20/23 作为主线标准（`std::print`、concepts、ranges、smart pointer 优先等现代写法
从第一天就教）；全部示例 MSVC 编译 + 运行 + 自检通过；第 24 章实战迷你 grep。

**非目标**：
- 不教 GUI（win32/mfc/wpf/sdl2 教程已存在，交叉引用）
- 不引第三方库（仅标准库；boost 有独立教程）
- 不做 CMake/vcpkg 工程化主线（第 23 章一瞥带过）
- 不覆盖 C 兼容、嵌入式、C++26 展望（一段话带过）
- 编译器支持矩阵不做全量维护（以本机 MSVC 实测为准 + cppreference 链接）

## 3. 已确认决策

| 决策点 | 结论 |
|---|---|
| 读者定位 | 会编程、初学 C++，从零教（C++20/23 为主线标准） |
| 章节规模 | 24 章，每章 150–250 行（不压缩内容） |
| 实战项目 | 第 24 章迷你 grep（目录递归 + 多线程 + 高亮 + 测试） |
| 工具链 | MSVC `cl /std:c++latest /EHsc /utf-8 /permissive- /Zc:__cplusplus /W4`，vcvars 路径沿用现 build.ps1 |
| 示例形态 | 每章一个目录 `examples/NN_name/main.cpp`（18/24 多文件），章号=目录号 |
| 验证策略 | 三层：编译零告警 + 运行 exit 0 + 示例内置 assert 自检输出 |
| 旧文件 | 删 `snippets/`（82 个）、`examples/`（16 个）；重写 README、build.ps1；新增 CHEATSheet |
| 目录名 | 保留 `cpp20`（外部引用不破坏） |

## 4. 环境实测结论（2026-09-17，VS 2026 工具集 14.51.36231）

| 特性 | 结果 |
|---|---|
| `std::print`/`std::println`（`<print>`） | ✅ 可用 |
| `std::expected`（`<expected>`） | ✅ 可用（value/unexpected 全通） |
| `std::generator`（`<generator>`，C++23） | ✅ 可用（co_yield 正常） |
| `std::mdspan`（`<mdspan>`） | ✅ 可用，但访问语法是 **`m[i, j]`**（无 `m(i,j)`——那是 Kokkos 旧接口） |
| `std::stacktrace`（`<stacktrace>`） | ✅ 头文件可用 |
| C++20 模块 | ✅ 两步编译可用：`cl /interface /c math.ixx` → `cl main.cpp math.obj` |

vcvars 阶段的 `vswhere.exe` 警告无害，忽略。

## 5. 章节结构（docs/，24 章）

| # | 文件 | 主题 | 示例 | 吸收旧内容 |
|---|---|---|---|---|
| 01 | `01-overview.md` | 全景：C++ 是什么、编译→链接→运行模型、98→23 演进、三大编译器、工具链与学习方法 | — | 编译器支持表（简化+cppreference 链接） |
| 02 | `02-hello.md` | 第一个程序：main、注释、`std::print`/iostream 对比、编译运行分解 | `02_hello` | 2.2 入门部分 |
| 03 | `03-types.md` | 类型与变量：基本类型、字面量、auto、初始化三种写法、narrowing、constexpr 入门 | `03_types` | 1.5/1.6 入门、2.8 `<numbers>` |
| 04 | `04-control.md` | 表达式与控制流：运算符、隐式转换坑、if/switch（含初始化语句）、循环、range-for | `04_control` | 1.1/3.2 |
| 05 | `05-functions.md` | 函数：值/引用/const 引用传参、返回、重载、默认实参、作用域与生命周期 | `05_functions` | — |
| 06 | `06-compound.md` | 复合类型：struct、指定初始化器、结构化绑定、enum class、string、string_view、span 入门 | `06_compound` | 1.5、3.1、2.1 |
| 07 | `07-errors.md` | 错误处理：异常、optional（含单子操作）、**expected (C++23)**、断言、错误策略选型 | `07_errors` | 5.2 部分 |
| 08 | `08-classes.md` | 类与 RAII：构造/析构、拷贝控制、rule of zero/five、**spaceship**、运算符重载、deducing this (C++23) 一瞥 | `08_classes` | 1.7、1.8、5.1 部分 |
| 09 | `09-smartptr.md` | 动态内存与智能指针：new/delete 危险、unique/shared/weak、make_*、所有权惯用法 | `09_smartptr` | 3.4、4.1–4.4（压缩重讲） |
| 10 | `10-containers.md` | 容器与迭代器：vector、map/set、unordered_*、迭代器分类、删除惯用法、flat_map (C++23) 一瞥 | `10_containers` | 2.8 部分 |
| 11 | `11-algorithms.md` | 算法与 lambda：sort/find/count、谓词、捕获、泛型 lambda、std::function | `11_algorithms` | — |
| 12 | `12-ranges.md` | **Ranges**：views 管道、惰性求值证明、投影、ranges 算法 | `12_ranges` | 2.4 |
| 13 | `13-templates.md` | 模板基础：函数/类模板、实参推导、成员函数模板、编译期 vs 运行期多态 | `13_templates` | 3.3 入门 |
| 14 | `14-concepts.md` | **概念**：requires 表达式、标准库 concepts、约束重载、错误信息对比 | `14_concepts` | 1.2 |
| 15 | `15-moves.md` | 移动语义：值类别、右值引用、移动构造、std::move、完美转发、RVO | `15_moves` | 4.5 部分 |
| 16 | `16-inheritance.md` | 继承与多态：虚函数、override、抽象类、虚析构、dynamic_cast、组合优于继承 | `16_inheritance` | — |
| 17 | `17-compiletime.md` | 编译期编程：constexpr 函数、if constexpr、变参模板、fold 表达式 | `17_compiletime` | 1.6 深入、3.3 部分 |
| 18 | `18-modules.md` | 编译单元与**模块**：头文件机制、ODR、静态/动态库、C++20 modules 实战（真 .ixx） | `18_modules` | 1.4（去掉造假版本） |
| 19 | `19-threads.md` | 并发 I：thread/**jthread**、stop_token、mutex、lock_guard/unique_lock、条件变量 | `19_threads` | 6.1/6.2 |
| 20 | `20-atomic.md` | 并发 II：atomic、内存序入门、**latch/barrier/semaphore**、并行算法 | `20_atomic` | 6.3/6.5 |
| 21 | `21-coroutines.md` | **协程**：co_await/co_yield、手写 generator、**std::generator (C++23)**、异步生态一段 | `21_coroutines` | 1.3、6.4、6.7 部分 |
| 22 | `22-textfiles.md` | 文本与文件：**format** 深入、regex、filesystem、UTF-8 编码、mdspan 一瞥 | `22_textfiles` | 2.2 深入、5.2 部分、2.7 |
| 23 | `23-tooling.md` | 测试调试与生态：assert 自造单测、VS 调试器、并发调试、CMake/vcpkg 一瞥、g++/clang 差异 | `23_tooling` | 第 7 章调试指南压缩 |
| 24 | `24-minigrep.md` | **实战**：迷你 grep——参数解析、目录递归、多线程搜索、高亮输出、测试 | `24_minigrep` | 6.6 线程池素材 |

每章结构沿用 dotnet 模板：标题 + 对应示例引用 + 编号小节（递进讲解 → 走读示例 →
心智模型）+ 坑位清单收尾。C++23 特性标注版本徽记，未在 MSVC 落地的特性明确说明。

## 6. 示例规划

- 每章一个目录 `examples/NN_name/`，含 `main.cpp`（自包含、可独立编译运行），
  章号=目录号；01 无示例。
- 自检约定：示例输出确定性文本 + `assert` 关键行为（供 build.ps1 运行层验证 exit 0）。
- 多文件示例：`18_modules/`（`math.ixx` + `main.cpp`，已验证两步编译流程）、
  `24_minigrep/`（`main.cpp` + `search.cpp` + `output.cpp` 拆分，练第 18 章头文件组织）。
- 代表性示例内容：
  - 07：`expected` 链式解析（字符串→int→除法，错误传播对比异常）
  - 09：所有权转移/共享观察演示，weak_ptr 打破循环
  - 12：管道组合 + 惰性证明（元素访问打点计数）
  - 14：约束重载分派 + 无约束模板的错误信息对比
  - 15：拷贝/移动计数器对比 RVO
  - 19：jthread + stop_token 协作取消 + 生产者消费者
  - 20：latch 同步的并行分段求和 + 数据竞争反例（注释形式）
  - 21：手写 30 行 generator + std::generator 对照
  - 24：`minigrep <dir> <pattern> [-i] [-t N]`，多线程搜索、命中行高亮、单测函数

## 7. build.ps1 重写设计

1. **pwsh 7 运行**（UTF-8 无 BOM，与其他教程一致）；脚本内设
   `[Console]::OutputEncoding = UTF8`。
2. vcvars 路径沿用：`G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat`（vswhere 警告忽略）。
3. 编译参数：`cl /nologo /std:c++latest /EHsc /utf-8 /permissive- /Zc:__cplusplus /W4`，
   obj/exe 输出到根 `build/`。
4. **三层验证**（`-All`）：逐示例 ① 编译（零告警目标，教学必要时用
   `[[maybe_unused]]` 消参告警）→ ② 运行 exe → ③ exit 0 即过，输出供人工抽查。
5. **模块特判**：目录含 `*.ixx` → 先 `cl /interface /c` 编 .ixx 再编译 main.cpp 链接
   .obj（实测可行流程）。
6. `-Example <name>` 单示例全流程；`-Clean` 清理根 `build/`。
7. 编译命令经 `%ComSpec% /c` 中转 bat 串（现脚本模式，规避引号问题）。

## 8. 文件操作清单

| 操作 | 文件 |
|---|---|
| 删除 | `snippets/` 全部 82 个文件 |
| 删除 | `examples/` 全部 16 个旧文件 |
| 新增 | `docs/01-overview.md` … `docs/24-minigrep.md` 共 24 章 |
| 新增 | `examples/02_hello/` … `examples/24_minigrep/` 共 23 个示例目录 |
| 重写 | `README.md`（目录结构 + 24 章索引表 + 验证说明，60 行内） |
| 重写 | `build.ps1`（见 §7） |
| 新增 | `CHEATSheet.md`（语法速查 + 编译命令 + 坑位索引） |
| 修改 | 根 `README.md` 两处 cpp20 描述（改为"从零到 C++20/23 的 C++ 教程"） |

## 9. 验证方案

1. `pwsh -ExecutionPolicy Bypass -File build.ps1 -All`：23 个示例全部编译
   （零告警目标）+ 运行 exit 0。
2. 每章文档代码片段与示例实际内容一致（按小节核对）；版本敏感特性
   （mdspan 下标语、expected、generator、print）与 §4 实测结论一致。
3. README 索引表与 docs/ 实际文件一一对应；对 `../win32/`、`../mfc/`、`../boost/`
   等交叉引用链接可达。
4. 模块示例走真实两步编译（不得再出现"普通函数冒充模块"）。

## 10. 风险与对策

| 风险 | 对策 |
|---|---|
| /W4 下教学代码告警噪音（未用参数等） | 约定 `[[maybe_unused]]`；个别示例整体 `#pragma warning(disable: …)` 并注释原因 |
| C++23 特性 API 与记忆有出入（mdspan 即实例） | 一切以 §4 实测为准；写每章前先编译验证再落笔 |
| 模块示例构建流程易碎 | build.ps1 特判集中在一处；18 章文档同时给出手动命令行步骤 |
| 24 章写作量大 | 分 4 章一批提交（01–04、05–08、…），每批跑一次 -All |
| `expected`/`generator` 等头文件名与编译器支持差异 | 01 章工具链表注明本教程按 MSVC 14.51+ 实测；g++/clang 差异在 23 章集中讲 |
| 线程示例输出不确定性 | 输出前 join 全部线程；时序演示用确定性顺序结构 |
