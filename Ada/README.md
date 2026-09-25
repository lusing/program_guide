# Ada 教程（GNAT / SPARK）

面向**会编程（任意语言背景）、初学 Ada** 的读者：从 GNAT 环境搭建讲到类型系统、
判别与访问类型、包、泛型、OOP、Tasking 并发与 select 会合家族、文件 I/O、
C 互操作、低级程序设计与定点实数，再到标准容器、Ada 2012 **契约式编程**与
**SPARK 形式化验证**，最后落到独立编译与可见性——**章号 = 示例编号**，
02–26 章每章对应 `examples/` 里一个可编译、可运行的完整示例，
Windows / Linux 双平台实测通过。

> 核心理念：**把错误消灭在编译期，而不是让它在生产环境爆炸。** Ada 的强类型、
> 范围检查、契约与 SPARK 证明，都是这句话的落地；详见
> [01 章](docs/01-overview.md) 与 [24 章](docs/24-contracts.md)。
>
> 教程共 27 章：其中 08/09/13/17/19/21/22/26 八章为**老教材深挖篇**——
> 对照何诚《ADA 语言程序设计教程》、刘炳文《程序设计语言 Ada》、
> 张丽芬《Ada 程序设计导论》三本国内 Ada 83 时代教材的专题深挖
> （访问类型、判别类型、定点实数、低级程序设计、select 家族、
> 子单位与可见性等现代教程常略过的"硬核"），案例全部现代化重写
> 并在 GNAT 16.2 实测；术语对照见 [27 章附录](docs/27-appendix.md)。

## 目录结构

```text
Ada/
├── README.md        本文件
├── docs/            27 章教程（01 → 27 顺序阅读）
├── examples/        25 个示例（章号 = 示例编号，02–26；26 章为多文件工程）
├── build.ps1        Windows 编译脚本（PowerShell）
├── run-all.sh       编译并运行全部示例（bash：Linux/macOS/Git Bash）
└── build/           构建输出（已 gitignore）
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| **基础篇** | | |
| [01 全景与工具链](docs/01-overview.md) | 诞生史、标准演进、设计哲学、应用案例、GNAT 安装与编译命令 | — |
| [02 Hello World](docs/02-hello.md) | `with`/`use`、过程基本结构 | `ch02_hello` |
| [03 基本数据类型与变量](docs/03-types.md) | 整型/浮点/枚举/子类型/常量 | `ch03_types` |
| [04 控制结构](docs/04-control.md) | if / case / loop / exit when | `ch04_control` |
| [05 子程序](docs/05-subprograms.md) | 过程与函数、参数模式、默认/命名参数 | `ch05_subprograms` |
| [06 数组与字符串](docs/06-arrays-strings.md) | 约束/无约束数组、属性、有界字符串 | `ch06_arrays` |
| [07 记录类型](docs/07-records.md) | 记录、默认值、变体记录、嵌套 | `ch07_records` |
| **类型深入（老教材深挖）** | | |
| [08 判别类型](docs/08-discriminants.md) | 变体记录、变长数组、判别式约束、`'Constrained` | `ch08_discriminants` |
| [09 访问类型](docs/09-access-types.md) | `new`/`.all`、链表、二叉树、手动回收、访问子程序 | `ch09_access` |
| **模块化** | | |
| [10 包与模块化编程](docs/10-packages.md) | 规范（.ads）与体（.adb）分离 | `ch10_packages`（+ `ch10_math_lib`） |
| [11 异常处理](docs/11-exceptions.md) | raise / exception / 传播与重抛 | `ch11_exceptions` |
| [12 泛型编程](docs/12-generics.md) | 泛型过程/函数/包与实例化 | `ch12_generics` |
| [13 泛型进阶](docs/13-generics-deep.md) | 类属形参全种类、默认 `is <>`、类属 FIFO 缓冲 | `ch13_generics_deep` |
| [14 面向对象编程](docs/14-oop.md) | tagged record、派生、动态分发 | `ch14_oop` |
| **并发三部曲** | | |
| [15 并发编程：Tasking](docs/15-tasking.md) | task、rendezvous、生产者-消费者 | `ch15_tasking` |
| [16 受保护对象](docs/16-protected-objects.md) | protected、entry 守卫、有界缓冲区 | `ch16_protected` |
| [17 任务深入：select 家族](docs/17-select-family.md) | 选择等待/哨兵、条件/定时入口调用、terminate、入口族、信号灯 | `ch17_select` |
| **I/O** | | |
| [18 文件 I/O](docs/18-file-io.md) | 写/读/追加、三种文件模式 | `ch18_fileio` |
| [19 文件 I/O 全景](docs/19-file-io-full.md) | Sequential_IO / Direct_IO / Stream_IO、文件归并 | `ch19_files` |
| **系统与嵌入式（老教材深挖）** | | |
| [20 与 C 语言互操作](docs/20-c-interop.md) | Import/Export、Interfaces.C、libm 坑 | `ch20_c_interop` |
| [21 低级程序设计](docs/21-low-level.md) | Size/Pack、记录与枚举表示、地址覆盖、存储池配额 | `ch21_lowlevel` |
| [22 定点与十进制实数](docs/22-fixed-point.md) | delta/Small、十进制定点、数字滤波器定点实现 | `ch22_fixed` |
| **高级篇** | | |
| [23 标准容器库](docs/23-containers.md) | Vectors / Lists / Hashed_Maps / Sets | `ch23_containers` |
| [24 契约式编程（Ada 2012）](docs/24-contracts.md) | Pre/Post/Type_Invariant/Predicate/Loop_Invariant | `ch24_contracts` |
| [25 SPARK 形式化验证](docs/25-spark.md) | SPARK 子集、证明级别、GNATprove 工具链 | `ch25_spark` |
| [26 独立编译与可见性](docs/26-separate-compilation.md) | with/use/use type、renames、子单位、子库单元 | `ch26_separate`（+ 5 文件） |
| [27 附录](docs/27-appendix.md) | 测试汇总、编译选项、编码规范、Ada 83→2022 术语对照 | — |

## 工具链

| 平台 | 工具链 | 验证记录 |
|---|---|---|
| Windows | GNAT 16.2.0（MSYS2 UCRT64，scoop 安装） | 2026-09-25 老教材扩充（19→27 章）后 25/25 通过 |
| Windows | GNAT 16.2.0（MSYS2 UCRT64） | 2026-09-22 章号对齐重构后 17/17 通过 |
| Windows | GNAT 16.1.0（MSYS2 UCRT64） | 首轮验证 17/17 通过 |
| Linux | GNAT 16.2.1（`sudo apt install gnat` 等） | 2026-09-21 复验 17/17 通过 |

## 验证命令

```bash
cd Ada
./run-all.sh            # 编译并运行全部 25 个示例，打印通过/失败摘要
./run-all.sh 02 14      # 只跑指定章号（章号 = 示例编号）
./run-all.sh --clean    # 清理 build 目录
```

```powershell
pwsh ./build.ps1 -All              # Windows：编译全部示例
pwsh ./build.ps1 -File ch02_hello.adb
pwsh ./build.ps1 -Clean
```

**判定标准**：编译退出码 0 + 运行退出码 0 + stderr 为空（`run-all.sh` 内置；
`build.ps1` 只做编译验证，运行验证走 `run-all.sh`——Git Bash 下用
`GNATMAKE=/path/to/gnatmake.exe ./run-all.sh` 指定编译器）。

## 平台差异说明

- `ch20_c_interop` 导入 C 的 `sqrtf`：Windows UCRT 已把数学函数并入主 C 运行时，
  直接编译即可；Linux/macOS 的数学函数在独立的 libm，必须附加 `-largs -lm`
  （`run-all.sh` 已自动处理）。
- `ch24_contracts` / `ch25_spark` 需 `-gnata` 启用契约断言检查（脚本已自动处理）。
- `ch17_select` 是并发示例：输出顺序经会合与 delay 精心编排，
  连续多次运行输出稳定，但真机上任务调度顺序本就无保证。
- `ch21_lowlevel` 的字节序/位序输出以 x86-64（小端）为准；
  `System` 常量值随目标机不同。
- `ch26_separate` 为多文件工程：主程序 + 2 个子单位（`ch26_separate-*.adb`）
  + 父包与子库单元（`ch26_support*`），`run-all.sh`/`build.ps1` 只需指主单元。
- 手动编译示例：

```bash
gnatmake -o ch02_hello examples/ch02_hello.adb                      # 一般示例
gnatmake -o ch20_c_interop examples/ch20_c_interop.adb -largs -lm   # 需 libm
gnatmake -gnata -o ch24_contracts examples/ch24_contracts.adb       # 需断言
```

## 示例怎么读

- **文件名 = 单元名**：GNAT 要求主程序文件名与过程名一致（如 `ch02_hello.adb` ↔
  `procedure Ch02_Hello`）。`ch` 前缀是因为 **Ada 标识符不能以数字开头**。
- 10 章的包由三个文件组成：`ch10_math_lib.ads`（规范）、`ch10_math_lib.adb`（体）、
  `ch10_packages.adb`（主程序）。
- 26 章的层级结构：`ch26_separate.adb`（主程序，含体存根）+
  `ch26_separate-report.adb` / `ch26_separate-helpers.adb`（子单位，文件名 =
  父单元名 + `-` + 单元名）+ `ch26_support.ads` / `ch26_support-stats.{ads,adb}`
  （父包与子库单元）。
- 改代码后重跑对应章号即可：`./run-all.sh 08`。

## 相关教程

同为"安全导向系统语言"的 [rust](../rust/README.md)；C 互操作底层对照
[cpp20](../cpp20/README.md)；同属"老牌标准语言"系列的
[cobol](../cobol/README.md) 与 [algol68](../algol68/README.md)。
