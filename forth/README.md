# Forth / GForth 教程（gforth 0.7.3）

面向**已经会一门命令式语言**的读者：从栈机器的心智模型讲到算术、词与变量、
控制流、内存与字符串，再深入到 `CREATE ... DOES>`、局部变量、堆、异常、
结构体、浮点、文件、OO、词表、元编程、生成器与测试，最后以速查表和
60+ 条实测坑清单收束。**章号 = 示例编号**——01–19 章每章对应 `examples/`
里一个经 gforth 0.7.3 运行验证的完整 .fs 文件，20 章为速查表，21 章为
本机实测坑总清单。

> 核心理念：**一切靠栈传参，词典可以自扩展。** Forth 里没有「标准库 /
> 用户代码」的边界，你定义的新词和内置词完全等价；详见
> [01 章](docs/01-intro.md) 与 [21 章](docs/21-pitfalls.md)。

## 目录结构

```text
forth/
├── README.md        本文件
├── build.ps1        统一构建入口（PowerShell）
├── run-all.sh       macOS / Linux 下的一键运行与回归验证
├── docs/            21 章教程（01 → 21 顺序阅读）
├── examples/        19 个 .fs 示例（章号 = 示例编号，01–19）
└── build/           构建输出（PowerShell 通道使用）
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 认识 Forth：三套栈与第一个程序](docs/01-intro.md) | 栈机器、栈效应注释、工具链、数据栈/返回栈/浮点栈 | `01-hello-stack.fs` |
| [02 算术与数字](docs/02-arithmetic.md) | 整数/定标/双精度/进制/`<# #>` 格式化 | `02-arithmetic.fs` |
| [03 词、常量与变量](docs/03-words-variables.md) | 冒号定义、CONSTANT、VARIABLE、VALUE/TO、DEFER/IS | `03-words-variables.fs` |
| [04 分支与循环](docs/04-control-flow.md) | IF/CASE/DO LOOP/BEGIN UNTIL，九九表、FizzBuzz、素数筛 | `04-control-flow.fs` |
| [05 字符串](docs/05-strings.md) | `S"`、`C"`、`S\"`、比较、切分、拼接、`>number` | `05-strings.fs` |
| [06 数组与内存](docs/06-arrays-memory.md) | 一维/二维数组、越界检查、FILL/ERASE/MOVE/CMOVE | `06-arrays-memory.fs` |
| [07 递归](docs/07-recursion.md) | RECURSIVE、备忘化、相互递归、阿克曼、汉诺塔、UTIME 计时 | `07-recursion.fs` |
| [08 CREATE ... DOES>](docs/08-create-does.md) | 定义「定义词的词」：counter、table: 生成器 | `08-create-does.fs` |
| [09 局部变量](docs/09-locals.md) | `{ }` 与 `locals\| \|` 局部变量、点积、解一元二次方程 | `09-locals.fs` |
| [10 堆内存](docs/10-heap-alloc.md) | ALLOCATE/RESIZE/FREE、可增长动态数组、堆上链表 | `10-heap-alloc.fs` |
| [11 异常处理](docs/11-exceptions.md) | CATCH/THROW、自定义异常码、资源清理 | `11-exceptions.fs` |
| [12 结构体](docs/12-structures.md) | `struct/field/end-struct`、嵌套、结构体数组 | `12-structures.fs` |
| [13 浮点数](docs/13-floats.md) | 浮点字面量、运算、精度、牛顿法、数值积分 | `13-floats.fs` |
| [14 文件读写](docs/14-file-io.md) | 文本/二进制读写、追加、slurp、一个能用的 wc | `14-file-io.fs` |
| [15 面向对象](docs/15-oop.md) | 手工 vtable OO、多态、mini-oof.fs 继承 | `15-oop.fs` |
| [16 词典、词表与搜索顺序](docs/16-vocabulary.md) | 词表、搜索顺序、命名空间、MARKER | `16-vocabulary.fs` |
| [17 元编程](docs/17-metaprogramming.md) | 编译期计算、immediate、postpone、DSL | `17-metaprogramming.fs` |
| [18 生成器与惰性序列](docs/18-generators.md) | 生成器协议、惰性序列、map/filter/take、管道 | `18-generators.fs` |
| [19 测试与基准](docs/19-testing.md) | 自制断言库、栈平衡检查、异常断言、基准 | `19-testing.fs` |
| [20 速查表](docs/20-cheatsheet.md) | 栈/返回栈/内存/控制流/工具词速查 | — |
| [21 gforth 0.7.3 坑清单](docs/21-pitfalls.md) | 60+ 条本机实测坑位与替代写法总清单 | — |

学习路线：

- **刚接触 Forth**：01 → 02 → 03 → 04，先把手感练出来；
- **写过别的语言**：重点看 03（`DEFER/IS` 就是函数指针）、08（`CREATE DOES>`）、
  17（编译期编程），这三个是 Forth 和其它语言思路差得最远的地方；
- **要写正经项目**：11（异常）、16（命名空间）、19（测试）是工程化三件套；
- **被坑了**：直接翻 [21 章](docs/21-pitfalls.md)，或 `grep -n "坑" examples/*.fs`。

## 工具链

| 组件 | 路径 / 版本 |
|---|---|
| GForth | 0.7.3，直接用 PATH 中的 `gforth`（Linux：`/usr/bin/gforth`；macOS MacPorts：`/opt/local/bin/gforth`） |
| PowerShell | `pwsh`（`build.ps1` 入口；Linux 下可只用 `./run-all.sh`，无需安装 pwsh） |

## 验证命令

```bash
gforth --version

./run-all.sh            # 跑全部，只看结果摘要
./run-all.sh -v         # 跑全部并显示每个例子的完整输出
./run-all.sh 07 15      # 只跑指定编号
gforth examples/04-control-flow.fs     # 单个示例
```

PowerShell 通道（写 build/ 日志，可用于 CI）：

```powershell
pwsh ./build.ps1 -All                        # 全量验证
pwsh ./build.ps1 -File 04-control-flow.fs    # 单个示例
pwsh ./build.ps1 -Clean                      # 清理 build 目录
```

**判定标准**（三条全绿才算过）：

1. 退出码为 0；
2. stderr 没有任何输出；
3. 结束最后一行显示 `<0>`（数据栈为空）。

第 3 条是 Forth 特有的：某个词悄悄在栈上多留一个值，程序照样跑完不报错，
但后续代码全被污染。所以每个示例末尾都写了 `.s` 兜底——**写 Forth 时养成
习惯，每个词跑完都看一眼栈**。

当前状态：19 个示例全部通过（gforth 0.7.3，macOS 与 Linux/WSL2 双平台经
`./run-all.sh` 实测；macOS 上另有 `build.ps1 -All` 双通道验证）。

## 平台差异说明

- `.fs` 文件为 UTF-8 **LF** 行尾，中文注释与中文词名双平台直接运行；
- 示例的临时文件统一写在 `/tmp/`（14 文件 IO、16 词表），macOS / Linux 通用；
- `build.ps1` 里 gforth 路径有 PATH 兜底；Linux 无 pwsh 时用 `run-all.sh`
  即可，判定标准一致；
- 在 Windows 原生环境运行需自行安装 gforth 并处理行尾，坑清单结论以
  macOS / Linux 实测为准。

## 示例怎么读

- **章号 = 示例编号**：`docs/05-strings.md` ↔ `examples/05-strings.fs`，
  每章开头一行「对应示例」标注；
- 20、21 章无示例：20 是全文速查表，21 是坑位汇总清单——写代码前先查它；
- 改示例后重跑对应文件：`./run-all.sh NN`（如 `./run-all.sh 07`）。

## 相关教程

同为「交互式、可自扩展」 Lisp 家族对照 [commonlisp](../commonlisp/README.md)；
面向过程底层视角与内存布局对照 [cobol](../cobol/README.md)；
直接操作机器字的 [asm](../asm/intel/README.md)。
