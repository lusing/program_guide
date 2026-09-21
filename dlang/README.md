# D 语言编程指南（DMD 2.113）

面向**会编程（C/C++ 背景最佳）、初学 D** 的读者：从零教到现代 D 写法——UFCS 管道、ranges + 惰性算法、CTFE 与 mixin 代码生成、契约式编程、消息传递并发从对应章节起就是默认姿势。**D 特色全部独立成章细讲**：UFCS（05）、scope guards（09）、契约（10）、模板两章（11/12）、ranges 两章（13/14）、GC 与逃逸术（15）、消息并发（16）、并行（17）、DUB 构建（21）、C 互操作与 BetterC（22）、工具链深入（25）、标准库全景（26）。每章"读讲解 → 跑示例 → 改代码再跑"，全部示例**三平台双层验证**通过（`-unittest` 全绿 + 编译产物运行 exit 0）：**Windows x64（DMD 2.113.0 + DUB 1.42）、Linux x86_64（DMD 2.113.0 + DUB 1.42.0）、macOS x86_64（DMD 2.113.0 + DUB 1.42.0）**，示例代码零平台改动（macOS 侧的 3 个环境坑见下）。

> ⚠️ 网上 D 教程多为 2.07x/2.08x 时代（2017-2019）：`enum` 函数、`approxEqual`、`Task.force`、std.json 新 API 等行为都已变化。本教程所有代码在 **DMD 2.113.0 + DUB 1.42 三平台**实测，每章坑位清单收录版本差异。

## 目录结构

```text
dlang/
├── README.md       本文件
├── docs/           26 章教程（01 → 26 顺序阅读）
├── examples/       25 个示例目录（章号 = 目录号；21/24 为 DUB 工程）
├── build.ps1       Windows 统一验证脚本（PowerShell 7 / pwsh）
├── build.sh        Unix 统一验证脚本（bash；Linux + macOS，自动探测工具链）
└── CHEATSheet.md   语法速查 + 2.113 坑位索引
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景](docs/01-overview.md) | 设计哲学、工具链、D vs C++/Go/Zig | — |
| [02 第一个程序](docs/02-hello.md) | writeln/writef、-run、unittest 初见 | `02_hello` |
| [03 类型](docs/03-types.md) | 整数/浮点/三种字符、const/immutable/enum | `03_types` |
| [04 控制流](docs/04-control.md) | foreach 十八般武艺、final switch | `04_control` |
| [05 函数](docs/05-functions.md) | 参数家族、@property、⭐UFCS | `05_functions` |
| [06 数组切片 AA](docs/06-arrays.md) | 共享切片、UTF-8 陷阱、内建哈希表 | `06_arrays` |
| [07 结构体](docs/07-structs.md) | 值语义、RAII、运算符重载 | `07_structs` |
| [08 类与接口](docs/08-classes.md) | 继承、Object 三件套、typeid | `08_classes` |
| [09 错误 I](docs/09-errors1.md) | 异常、enforce、⭐scope guards | `09_errors1` |
| [10 错误 II](docs/10-errors2.md) | nothrow、Nullable、契约 in/out/invariant | `10_errors2` |
| [11 模板 I](docs/11-templates1.md) | 泛型、模板约束、特化 | `11_templates1` |
| [12 模板 II](docs/12-templates2.md) | ⭐CTFE、static if、mixin、反射 | `12_templates2` |
| [13 ⭐区间](docs/13-ranges.md) | 5 级协议、手写区间、无限流 | `13_ranges` |
| [14 ⭐算法](docs/14-algorithms.md) | map/filter/reduce、惰性管道 | `14_algorithms` |
| [15 内存](docs/15-memory.md) | GC、@nogc、malloc、RefCounted/scoped | `15_memory` |
| [16 ⭐并发 I](docs/16-concurrency.md) | spawn/send/receive、immutable 通行证 | `16_concurrency` |
| [17 并发 II](docs/17-parallel.md) | parallel、taskPool、原子/CAS | `17_parallel` |
| [18 文件与 IO](docs/18-files.md) | std.file、File.byLine、路径 | `18_files` |
| [19 格式化](docs/19-format.md) | writef 全集、std.conv、字符串工具 | `19_format` |
| [20 JSON](docs/20-json.md) | std.json（2.113 实测 API）、CSV | `20_json` |
| [21 构建与 DUB](docs/21-dub.md) | 模块/包、dmd -i、DUB 工程 | `21_dub`（工程） |
| [22 ⭐C 互操作](docs/22-cinterop.md) | extern(C)、qsort、内联汇编、BetterC | `22_cinterop`（含 betterC） |
| [23 测试与工具](docs/23-testing.md) | unittest 深入、-cov、ddoc、StopWatch | `23_testing` |
| [24 实战：迷你 grep](docs/24-minigrep.md) | 递归 + 并行 + 高亮 + 单测 | `24_minigrep`（工程） |
| [25 工具链深入](docs/25-dtools.md) | ⭐dtools：rdmd/ddemangle/dustmite/dman + 生态工具 | `25_dtools` |
| [26 标准库全景](docs/26-phobos.md) | ⭐libphobos/druntime：模块地图、链接形态、GC 开关 | `26_phobos` |

## 构建工具链

**Windows（原版验证环境）**：

- DMD **2.113.0**：`G:\scoop\apps\dmd\current\windows\bin64\dmd.exe`（scoop 安装；链接用本机 MSVC link.exe）。
- DUB **1.42.0**：随 DMD（`dub.exe`）。
- 中文控制台乱码先 `chcp 65001`（build.ps1 已代设 UTF-8）。

**Linux（本仓库复验环境，Debian 系 dmd 包 + 官方 dub）**：

- DMD **2.113.0**：`/usr/bin/dmd`（`apt install dmd`；头文件/库在 `/usr/include/dlang/dmd`、`/usr/lib/libphobos2.a`）。
- DUB **1.42.0**：`/usr/local/bin/dub`（官方包 `dmd.2.113.0.linux.tar.xz` 内提取，或 `curl https://dlang.org/install.sh | bash -s dub`）。
- 附带工具 `rdmd`/`ddemangle`/`dustmite` 随 dmd 包装好；`dman` 只在 dmd.org 发行的完整包里。

**macOS（本仓库复验环境，官方 dmd.2.113.0.darwin 包）**：

- DMD **2.113.0**：`/Volumes/mac004/lang/dmd2/osx/bin/dmd`（`dmd.conf` 用 `-I%@P%/../../src/phobos` 指到随包源码）。
- DUB **1.42.0**、以及 `rdmd`/`ddemangle`/`dustmite` 同目录；**`dman` 不随 macOS 包**（与 Linux 一样用 dlang.org/phobos 代替）。
- 库只有静态一份：`/Volumes/mac004/lang/dmd2/osx/lib/libphobos2.a`（24 MB，**没有 `.dylib`/`.so`**，见 26 章坑位）。
- 链接走系统 `cc`（Xcode CLT 的 clang）：`dmd -v` 可见 `cc x.o -o x -Xlinker -no_compact_unwind -L<dmd2>/osx/lib -lphobos2 -lpthread -lm`，因此**必须装 Xcode Command Line Tools**（`xcode-select --install`），否则链接阶段失败。
- 该包二进制**全部未签名**（`codesign -v` 报 "code object is not signed at all"）。在开了严格策略的机器上，未签名进程对 `~/` 下文件 `unlink` 会返回 **EPERM**，表现为 `dub` 报 `Failed to remove file ~/.dub/.../__dub_write_test_XXXX: Operation not permitted`。本仓库的处理方式：build.sh 在 Darwin 上自动把 `DUB_HOME` 指到 `build/dub-home`（也可自行 `export DUB_HOME=...` 或 `codesign -s - <dmd2>/osx/bin/*` 一劳永逸）。

## 验证命令

Windows（PowerShell）：

```powershell
cd G:\code\guide\dlang
pwsh -ExecutionPolicy Bypass -File build.ps1 -All              # 全部示例：unittest + 编译运行
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 13_ranges  # 单个示例
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean             # 清理
```

Linux / macOS（bash）：

```bash
cd dlang
./build.sh --all                 # 全部 25 个示例：unittest + 编译运行（21/24 走 dub test/build）
./build.sh --example 13_ranges   # 单个示例
./build.sh --clean               # 清理 build/、.o 与 DUB 工程 bin/
```

脚本会打印所用工具链（OS / dmd / dub / DUB_HOME）；工具不在 PATH 里时用环境变量指定：

```bash
DMD_ROOT=/Volumes/mac004/lang/dmd2/osx/bin ./build.sh --all   # macOS 官方包示例
DMD=/usr/bin/dmd DUB_HOME=~/.dub ./build.sh --all             # 显式指定
```

单跑某个示例（每章标准学法）——改代码后重跑：

```bash
cd dlang/examples/13_ranges
dmd -w -run main.d                 # 不带单测，跑 main（Unix：产物无 .exe 后缀，main/main.o）
dmd -w -unittest -run main.d       # 只跑 unittest
```

## 相关教程

系统语言对照：[cpp20（C++20/23）](../cpp20/README.md)、[go](../go/README.md)、[zig](../zig/README.md)、[rust](../rust/README.md)；速查见 [CHEATSheet.md](CHEATSheet.md)。
