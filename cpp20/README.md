# C++ 编程指南（C++20/23）

面向**会编程、初学 C++** 的读者：从零教到现代 C++——主线 C++23（兼容讲 20 的 concepts/ranges/协程/模块四大件），现代写法（`std::print`、智能指针、views）从第 02 章就是默认姿势，老式写法只教"认得"。每章"读讲解 → 跑示例 → 改代码再跑"，示例全部 /W4 零告警 + 运行自检通过。

## 目录结构

```text
cpp20/
├── README.md       本文件
├── docs/           24 章教程（01 → 24 顺序阅读）
├── examples/       23 个示例目录（章号 = 目录号；18/24 多文件）
├── run-all.sh      shell 入口（macOS/Linux 双工具链：clang++ 23 + g++ 15）
├── build.ps1       PowerShell 入口（Windows 走 MSVC；macOS/Linux 与 run-all.sh 等价）
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

**Windows（教程原配主线）**

- MSVC `cl`，经 vcvars64 进入环境（VS 2026，工具集 14.51）。
- 编译参数：`cl /nologo /std:c++latest /EHsc /utf-8 /permissive- /Zc:__cplusplus /W4`（零告警要求）。
- 直接运行 exe 中文乱码时先 `chcp 65001`（build.ps1 已代设）。

**macOS / Linux（2026-09-17 实测补上）**

| 通道 | 编译器 | 标准库 | 说明 |
|---|---|---|---|
| clang（主） | MacPorts `clang++-mp-23`（LLVM 23.1.0） | clang 自带的 libc++ 23 | 需要三个开关，见下面「macOS 兼容性」 |
| gcc（对照） | MacPorts `g++-mp-15`（GCC 15.2.0） | libstdc++ 15 | `-pthread` |
| ~~系统自带~~ | Apple clang 14（CommandLineTools） | libc++ 14000 | **不可用**：连 `-std=c++23` 都没有，`<print>`/`<expected>` 全无 |

- 编译参数：`-std=c++23 -Wall -Wextra -O2`（MSVC 的 `/W4` 对应 `-Wall -Wextra`，同样零告警）。
- 找不到 MacPorts 的编译器时可用环境变量指定：`CXX_CLANG=/path/to/clang++ CXX_GCC=/path/to/g++ ./run-all.sh`。

## 编译验证

```powershell
# Windows
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                  # 全部示例：编译+运行+自检
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 12_ranges    # 单个示例
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean                # 清理 build 目录
```

```bash
# macOS / Linux（与上面等价，两条通道都跑）
./run-all.sh              # 全量摘要
./run-all.sh -v           # 附带每个示例的完整输出
./run-all.sh 18 22        # 只跑指定编号
pwsh ./build.ps1 -All     # 同一个套件的 PowerShell 版，结论必须一致
```

判定标准（六条，缺一不可）：退出码 0 + **stderr 为空** + **编译日志为空（零告警）** + stdout 非空
+ stdout 无多余控制字符 + stdout 里有结束标记 `自检通过`。

> 第 3 条不能省：编译命令把 stderr 并进了日志文件，所以「stderr 为空」盖不住编译期告警 ——
> 反向验证时故意写了个 `int unused = 42;` 的样例，一开始正是漏判的。

单跑某个示例（第 02 章起的标准学法）——改代码后重跑：

```bash
cd cpp20/examples/12_ranges
# Windows：用 README 的手工编译命令，或 build.ps1 -Example 12_ranges
# macOS ：clang++-mp-23 -std=c++23 -Wall -Wextra -O2 main.cpp -o demo
#         （需要 macOS 兼容性一节里那三个开关，最简单的办法还是用 run-all.sh）
```

## macOS / Linux 上的兼容性（2026-09-17 实测）

**结论：23 个示例 × 2 条通道 = 46 项全部通过，零意外差异。** 教程正文（`docs/`）是为 MSVC 写的，
代码本身跨平台，但 macOS 上要绕开四件事才能跑起来——都写在两个入口脚本里了。

### 1. 系统自带的 Apple clang 不能用

macOS 12.7 的 CommandLineTools 是 Apple clang 14 + libc++ **14000**：没有 `-std=c++23`
（最高 `c++2b`），`<print>` / `<expected>` / `<flat_map>` / `<mdspan>` 一个都没有。
→ 必须用 MacPorts 的 `clang++-mp-23`（或者别的 LLVM ≥ 19 / GCC ≥ 15）。

### 2. libc++ 的 availability 注解（最坑的一条）

MacPorts 的 clang-23 自带完整 libc++ 23 头文件，但那些头文件里带着 **Apple 的 availability 注解**
——注解描述的是"苹果自家 libc++ 什么时候有这个符号"。本机 macOS 12.7 上它就等于给
`std::to_chars(浮点)` 打了"macOS 13.3 才可用"，于是 `<print>` 只要格式化一个浮点数就直接编译失败：

```text
__format/formatter_floating_point.h:75:30: error: 'to_chars' is unavailable: introduced in macOS 13.3
```

修法是三件一起做（缺一不可，脚本里已代劳）：

```bash
-D_LIBCPP_DISABLE_AVAILABILITY                     # 关掉注解（libc++ 官方留的逃生口）
-L/opt/local/libexec/llvm-23/lib/libc++ -Wl,-rpath,... -lc++   # 链接 clang 自带的那套 libc++
-L/opt/local/libexec/llvm-23/lib/libunwind -Wl,-rpath,...      # 它还要 libunwind
```

只做第一条会在**链接期**报 `to_chars` 没有实现（系统自带的 libc++ 14000 里确实没有）：

```text
  "std::__1::to_chars(char*, char*, float, std::__1::chars_format, int)", referenced from:
      ... in main-c7c068.o
ld: symbol(s) not found for architecture x86_64
```

而只缺 `-L/-rpath`（另两条都在）时是另一条：`ld: library not found for -lc++experimental`
（`-fexperimental-library` 会让 clang 去链 `libc++experimental`，它就躺在 clang 自带的那套里）。

### 3. `std::execution::par`：能编过，但**在本机不会真的并行**

两条独立的结论，别混起来：

- **不加 `-fexperimental-library` 连名字都没有** —— `error: no member named 'par' in namespace 'std::execution'`。
  原因是 libc++ 把 PSTL 挂在 `_LIBCPP_HAS_EXPERIMENTAL_PSTL` 后面，而它 = `_LIBCPP_HAS_EXPERIMENTAL_LIBRARY`，
  只有加了这个开关才是 1（`__configuration/experimental.h:32`）。
- **加了以后能编译能跑，但算法是串行执行的。** 本机（MacPorts clang-23）的
  `__config_site` 选的是 `_LIBCPP_PSTL_BACKEND_STD_THREAD`，而这个后端在 libc++ 里是**桩实现**——
  `backends/std_thread.h` 自己写着 *"for testing purposes only and not meant for production use"*，
  它的 `__for_each` 就是一行 `__f(__first, __last);`（在当前线程直接跑完），`__transform_reduce`
  也只是直接调 `__reduce`。

实测方法是**在并行算法里数线程 id**（`std::this_thread::get_id()` 塞进一个加锁的 `std::set`，
最后看有几个不同的 id）。`for_each(par)` / `transform(par)` / `sort(par)` / `reduce(par)` /
`reduce(par_unseq)` 五条，400 万元素的输入，**全部只有 1 个线程**（`hardware_concurrency = 4`）。

对照系统自带的 Apple clang 14（用 `-std=c++17` 就能测，不需要 C++23）：
**它的 libc++ 14000 里 `<execution>` 连 `par` 都没有**（`no member named 'execution' in namespace 'std'`）。
所以在 macOS 上「并行算法真的并行」这件事，两套 libc++ 都做不到。

> 这不影响示例 20 的判定：它只断言 `par_sum == 1000000`（`par` 的语义本来就是"**允许**并行"，
> 不保证真的并行），所以两条通道输出逐字节一致。写跨平台代码时据此推理即可：
> **要真并行就自己开 `std::thread`（示例 19/20 的前几节就是这么做的），别指望 `par`。**

### 4. 三套标准库各缺一块 C++23

实测（并对照了上游 `release/23.x` 的 185 个公开头文件清单）：

| 头文件 | libc++ 23 | libstdc++ 15.2 | MSVC 14.51 |
|---|---|---|---|
| `<print>` `<expected>` `<flat_map>` | 有 | 有 | 有 |
| `<mdspan>` | 有 | **没有这个头文件** | 有 |
| `<generator>` | **没有这个头文件** | 有 | 有 |
| `<stacktrace>` | **没有这个头文件** | 有头文件但 `std::stacktrace` 没实现 | 有 |

所以 `21_coroutines` / `22_textfiles` / `23_tooling` 里用 `__has_include` 与 `__cpp_lib_stacktrace`
做了探测，缺了就跳过对应小节并打一行说明（`MSVC` 上走的是原分支，行为不变）。

### 5. 顺带查出来的两个跨编译器坑

- MacPorts 的 `/opt/local/bin/clang++-mp-23` 是 **178 字节的 shell 包装脚本**，不是符号链接，
  `dirname/..` 猜出来是 `/opt/local`（那里没有 libc++）。稳妥做法是问编译器自己：
  `clang++ -print-resource-dir`。
- 容器析构时**元素按什么顺序销毁标准没有规定**：libc++ 逆序、libstdc++ 正序。
  示例 09 因此改成显式 `pop_back`（详见 `docs/09-smartptr.md`）。

### 校验本身抓出的三个真实缺陷

| 示例 | 问题 | 修法 |
|---|---|---|
| 05_functions | clang 报 `-Wunused-but-set-parameter`（GCC/MSVC 都不报，所以只在 macOS 暴露） | 加 `(void)x;` 表明是刻意演示 |
| 10_containers | `const std::string&` 绑字面量列表元素 → GCC 报 `-Wrange-loop-construct`，白构造临时 string | 改 `const char*` |
| 13_templates | `println("size = {}，弹出 {}", ints.size(), ints.pop())` 依赖实参求值顺序，两个通道打出 3 和 2 | 拆成两条语句 |

### 已知差异（`run-all.sh` / `build.ps1` 里各有一张表，只打印原因不计入告警）

| 示例 | 差在哪 | 原因 |
|---|---|---|
| 08_classes | `Counter: 1 2 3` vs `3 2 1` | **示例故意演示**实参求值顺序未指定（GCC/MSVC 从右往左、clang 从左往右） |
| 19_threads / 24_minigrep | 命中行/线程输出行序 | 调度不同 —— 2026-09-17 单独压过 18+8 轮，**每轮都逐字节一致**（示例把结论都放在 join 之后由主线程打印），但仍登记为差异：调度不是我们能保证的东西 |
| 20_atomic | 并行拆分方式 | 由实现决定（压了 8 轮，输出一致） |
| 21 / 22 / 23 | 缺特性那一节的说明行 | 见上表第 4 条 |

### 两个入口脚本的实现要点

- **逐字节比对两条通道的输出**（`cmp`），不一致就报 `[DIFF]` 要求人工确认；
  已登记的原因走 `[diff]` 只打印说明。
- `18_modules` 走真正的模块构建：clang 用 `--precompile` 出 `.pcm` + `-fmodule-file=math=…`；
  gcc 用 `-fmodules-ts`（产物落进 `./gcm.cache`）。两条通道输出逐字节一致。
- 运行示例时把 `TMPDIR` 固定到 `build/tmp`，这样 `22_textfiles` 打出来的临时路径可复现；
  每轮开跑前把这个目录里的 `*.s/*.o/*.d/*.ii` 清一遍 —— 中途被打断时编译器会往那儿丢中间产物。
- 编译与运行的产物一律落 `build/`，示例在 `build/` 下运行；判定的 6 条规则两个入口用同一套。

## 相关教程

GUI 方向：[Win32](../win32/README.md)、[MFC](../mfc/README.md)、[WPF](../wpf/README.md)；库方向：[boost](../boost/README.md)；其他语言对照：[dotnet (C#)](../dotnet/README.md)。
