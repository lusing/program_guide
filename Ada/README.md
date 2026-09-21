# Ada 教程（GNAT / SPARK）

面向**会编程（任意语言背景）、初学 Ada** 的读者：从 GNAT 环境搭建讲到类型系统、
包、泛型、OOP、Tasking 并发、受保护对象，再到 Ada 2012 **契约式编程**与
**SPARK 形式化验证**这两门"皇冠特性"。**章号 = 示例编号**——02–18 章每章对应
`examples/` 里一个可编译、可运行的完整示例，Windows / Linux 双平台实测通过。

> 核心理念：**把错误消灭在编译期，而不是让它在生产环境爆炸。** Ada 的强类型、
> 范围检查、契约与 SPARK 证明，都是这句话的落地；详见
> [01 章](docs/01-overview.md) 与 [17 章](docs/17-contracts.md)。

## 目录结构

```text
Ada/
├── README.md        本文件
├── docs/            19 章教程（01 → 19 顺序阅读）
├── examples/        17 个示例（章号 = 示例编号，02–18）
├── build.ps1        Windows 编译脚本（PowerShell）
├── run-all.sh       编译并运行全部示例（bash：Linux/macOS/Git Bash）
└── build/           构建输出（已 gitignore）
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景与工具链](docs/01-overview.md) | 诞生史、标准演进、设计哲学、应用案例、GNAT 安装与编译命令 | — |
| [02 Hello World](docs/02-hello.md) | `with`/`use`、过程基本结构 | `ch02_hello` |
| [03 基本数据类型与变量](docs/03-types.md) | 整型/浮点/枚举/子类型/常量 | `ch03_types` |
| [04 控制结构](docs/04-control.md) | if / case / loop / exit when | `ch04_control` |
| [05 子程序](docs/05-subprograms.md) | 过程与函数、参数模式、默认/命名参数 | `ch05_subprograms` |
| [06 数组与字符串](docs/06-arrays-strings.md) | 约束/无约束数组、属性、有界字符串 | `ch06_arrays` |
| [07 记录类型](docs/07-records.md) | 记录、默认值、变体记录、嵌套 | `ch07_records` |
| [08 包与模块化编程](docs/08-packages.md) | 规范（.ads）与体（.adb）分离 | `ch08_packages`（+ `ch08_math_lib`） |
| [09 异常处理](docs/09-exceptions.md) | raise / exception / 传播与重抛 | `ch09_exceptions` |
| [10 泛型编程](docs/10-generics.md) | 泛型过程/函数/包与实例化 | `ch10_generics` |
| [11 面向对象编程](docs/11-oop.md) | tagged record、派生、动态分发 | `ch11_oop` |
| [12 并发编程：Tasking](docs/12-tasking.md) | task、rendezvous、生产者-消费者 | `ch12_tasking` |
| [13 文件 I/O](docs/13-file-io.md) | 写/读/追加、三种文件模式 | `ch13_fileio` |
| [14 与 C 语言互操作](docs/14-c-interop.md) | Import/Export、Interfaces.C、libm 坑 | `ch14_c_interop` |
| [15 标准容器库](docs/15-containers.md) | Vectors / Lists / Hashed_Maps / Sets | `ch15_containers` |
| [16 受保护对象](docs/16-protected-objects.md) | protected、entry 守卫、有界缓冲区 | `ch16_protected` |
| [17 契约式编程（Ada 2012）](docs/17-contracts.md) | Pre/Post/Type_Invariant/Predicate/Loop_Invariant | `ch17_contracts` |
| [18 SPARK 形式化验证](docs/18-spark.md) | SPARK 子集、证明级别、GNATprove 工具链 | `ch18_spark` |
| [19 附录](docs/19-appendix.md) | 编译测试汇总、常用编译选项、编码规范 | — |

## 工具链

| 平台 | 工具链 | 验证记录 |
|---|---|---|
| Windows | GNAT 16.2.0（MSYS2 UCRT64，scoop 安装） | 2026-09-22 章号对齐重构后 17/17 通过 |
| Windows | GNAT 16.1.0（MSYS2 UCRT64） | 首轮验证 17/17 通过 |
| Linux | GNAT 16.2.1（`sudo apt install gnat` 等） | 2026-09-21 复验 17/17 通过 |

## 验证命令

```bash
cd Ada
./run-all.sh            # 编译并运行全部 17 个示例，打印通过/失败摘要
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

- `ch14_c_interop` 导入 C 的 `sqrtf`：Windows UCRT 已把数学函数并入主 C 运行时，
  直接编译即可；Linux/macOS 的数学函数在独立的 libm，必须附加 `-largs -lm`
  （`run-all.sh` 已自动处理）。
- `ch17_contracts` / `ch18_spark` 需 `-gnata` 启用契约断言检查（脚本已自动处理）。
- 手动编译示例：

```bash
gnatmake -o ch02_hello examples/ch02_hello.adb                # 一般示例
gnatmake -o ch14_c_interop examples/ch14_c_interop.adb -largs -lm   # 需 libm
gnatmake -gnata -o ch17_contracts examples/ch17_contracts.adb       # 需断言
```

## 示例怎么读

- **文件名 = 单元名**：GNAT 要求主程序文件名与过程名一致（如 `ch02_hello.adb` ↔
  `procedure Ch02_Hello`）。`ch` 前缀是因为 **Ada 标识符不能以数字开头**。
- 08 章的包由三个文件组成：`ch08_math_lib.ads`（规范）、`ch08_math_lib.adb`（体）、
  `ch08_packages.adb`（主程序）。
- 改代码后重跑对应章号即可：`./run-all.sh 08`。

## 相关教程

同为"安全导向系统语言"的 [rust](../rust/README.md)；C 互操作底层对照
[cpp20](../cpp20/README.md)；同属"老牌标准语言"系列的
[cobol](../cobol/README.md) 与 [algol68](../algol68/README.md)。
