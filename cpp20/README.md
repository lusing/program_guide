# C++ 编程指南（C++20/23）

面向**会编程、初学 C++** 的读者：从零教到现代 C++——主线 C++23（兼容讲 20 的 concepts/ranges/协程/模块四大件），现代写法（`std::print`、智能指针、views）从第 02 章就是默认姿势，老式写法只教"认得"。每章"读讲解 → 跑示例 → 改代码再跑"，示例全部 /W4 零告警 + 运行自检通过。

## 目录结构

```text
cpp20/
├── README.md       本文件
├── docs/           24 章教程（01 → 24 顺序阅读）
├── examples/       23 个示例目录（章号 = 目录号；18/24 多文件）
├── build.ps1       统一构建脚本（须 PowerShell 7 / pwsh 运行）
└── CHEATSheet.md   语法速查 + 坑位索引
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景](docs/01-overview.md) | 编译模型、标准演进、工具链 | — |
| [02 第一个程序](docs/02-hello.md) | main、std::print、手工编译 | `examples/02_hello` |
| [03 类型与变量](docs/03-types.md) | 基本类型、auto、{} 初始化、constexpr | `examples/03_types` |
| [04 控制流](docs/04-control.md) | if/switch、range-for | `examples/04_control` |
| [05 函数](docs/05-functions.md) | 三种传参、重载、lambda 入门 | `examples/05_functions` |
| [06 复合类型](docs/06-compound.md) | struct、enum class、string/view/span | `examples/06_compound` |
| [07 错误处理](docs/07-errors.md) | 异常、optional、**expected (C++23)** | `examples/07_errors` |
| [08 类与 RAII](docs/08-classes.md) | 构造析构、rule of zero/five、spaceship | `examples/08_classes` |
| [09 智能指针](docs/09-smartptr.md) | 所有权、unique/shared/weak | `examples/09_smartptr` |
| [10 容器](docs/10-containers.md) | vector、map/set、迭代器、flat_map | `examples/10_containers` |
| [11 算法与 lambda](docs/11-algorithms.md) | sort/find_if、捕获、std::function | `examples/11_algorithms` |
| [12 Ranges](docs/12-ranges.md) | 惰性管道、投影、ranges::to | `examples/12_ranges` |
| [13 模板基础](docs/13-templates.md) | 函数/类模板、CTAD | `examples/13_templates` |
| [14 概念](docs/14-concepts.md) | requires、约束重载 | `examples/14_concepts` |
| [15 移动语义](docs/15-moves.md) | 值类别、std::move、完美转发、RVO | `examples/15_moves` |
| [16 继承与多态](docs/16-inheritance.md) | 虚函数、切片、组合优于继承 | `examples/16_inheritance` |
| [17 编译期编程](docs/17-compiletime.md) | constexpr、if constexpr、fold | `examples/17_compiletime` |
| [18 模块](docs/18-modules.md) | ODR、头文件、C++20 modules 实战 | `examples/18_modules` |
| [19 并发 I](docs/19-threads.md) | jthread、mutex、条件变量 | `examples/19_threads` |
| [20 并发 II](docs/20-atomic.md) | atomic、latch/barrier、并行算法 | `examples/20_atomic` |
| [21 协程](docs/21-coroutines.md) | 手写 generator、**std::generator (C++23)** | `examples/21_coroutines` |
| [22 文本与文件](docs/22-textfiles.md) | format、regex、filesystem、mdspan | `examples/22_textfiles` |
| [23 测试与工具](docs/23-tooling.md) | assert 单测、调试器、CMake 一瞥 | `examples/23_tooling` |
| [24 实战：迷你 grep](docs/24-minigrep.md) | 递归 + 多线程搜索 + 高亮 | `examples/24_minigrep` |

## 构建工具链

- MSVC `cl`，经 vcvars64 进入环境（VS 2026，工具集 14.51）。
- 编译参数：`cl /nologo /std:c++latest /EHsc /utf-8 /permissive- /Zc:__cplusplus /W4`（零告警要求）。
- 直接运行 exe 中文乱码时先 `chcp 65001`（build.ps1 已代设）。

## 编译验证

```powershell
cd G:\code\guide\cpp20
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                  # 全部示例：编译+运行+自检
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 12_ranges    # 单个示例
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean                # 清理 build 目录
```

单跑某个示例（第 02 章起的标准学法）——改代码后重跑：

```bash
cd /g/code/guide/cpp20/examples/12_ranges
# 用上面 README 的手工编译命令，或 build.ps1 -Example 12_ranges
```

## 相关教程

GUI 方向：[Win32](../win32/README.md)、[MFC](../mfc/README.md)、[WPF](../wpf/README.md)；库方向：[boost](../boost/README.md)；其他语言对照：[dotnet (C#)](../dotnet/README.md)。
