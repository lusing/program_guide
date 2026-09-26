# Forth / GForth 教程（gforth 0.7.3 · WSL Debian）

面向**已经会一门命令式语言**的读者：从栈机器的心智模型讲到算术、词与变量、
控制流、内存与字符串，再深入到 `CREATE ... DOES>`、局部变量、堆、异常、
结构体、浮点、文件、OO、词表、元编程、生成器与测试；20 章起进入
「书本扩充篇」——栈戏法、执行令牌、输入流解析、块与屏幕、词典解剖、
**用 Forth 手搓一个 mini-Forth**、协作式多任务、Thinking Forth 风格实践、
RPN 计算器实战，最后以简史与文献导读、速查表和 130+ 条实测坑清单收束。
**章号 = 示例编号**——01–28 章每章对应 `examples/` 里一个经 gforth 0.7.3
运行验证的完整 .fs 文件，29 章为简史文献，30 章为速查表，31 章为本机
实测坑总清单。

> 核心理念：**一切靠栈传参，词典可以自扩展。** Forth 里没有「标准库 /
> 用户代码」的边界，你定义的新词和内置词完全等价；25 章会带你亲手用
> 100 来行复刻这套机制。详见 [01 章](docs/01-intro.md)、
> [25 章](docs/25-outer-interp.md) 与 [31 章](docs/31-pitfalls.md)。

## 参考书（扩充篇 20–29 章的素材来源）

| 书 | 用途 |
|---|---|
| 《IBM-PC FORTH 语言》沈祖梁/潘根民（上海交大社 1988） | 词条格式、屏幕/块、USER、多任务、8086 汇编（史料） |
| 《第四代计算机高级语言 FORTH》刘大力等（人民邮电社 1988） | 栈操作、执行态/编译态、虚技术、摩尔序 |
| *Programming Forth*，S. Pelc（MPE 2005） | 执行向量、异常、文件、线程模型、嵌入式 |
| *Thinking Forth*，L. Brodie（1984/2004 开源） | 分解判据、命名、向量执行、消除控制结构 |

## 目录结构

```text
forth/
├── README.md        本文件
├── build.ps1        统一构建入口（PowerShell → wsl -d Debian 通道）
├── run-all.sh       Linux/WSL 下的一键运行与回归验证
├── docs/            31 章教程（01 → 31 顺序阅读）
├── examples/        28 个 .fs 示例（章号 = 示例编号，01–28）
└── build/           构建输出（build.ps1 通道使用）
```

## 章节索引

### 基础篇（01–19）

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

### 书本扩充篇（20–29，参考四本书扩充）

| 章 | 主题 | 示例 | 主要素材 |
|---|---|---|---|
| [20 栈戏法与返回栈](docs/20-stack-fu.md) | -rot/roll/pick、霍纳多项式、返回栈三定律、栈序重构 | `20-stack-fu.fs` | IBM-PC FORTH §1.2.1、Thinking Forth ch7 |
| [21 执行令牌与向量执行](docs/21-vectors.md) | xt/execute、跳转表、defer 全家、doer、向量状态机 | `21-vectors.fs` | Pelc ch10、Thinking Forth |
| [22 输入流与解析](docs/22-parsing.md) | source/>in、parse-name/parse、>number、evaluate、配置解析器 | `22-parsing.fs` | 第四代 FORTH ch7/8、Pelc ch7 |
| [23 块与屏幕](docs/23-blocks.md) | block/buffer/update、load/thru、list、历史存储模型 | `23-blocks.fs` | IBM-PC FORTH 下篇、第四代 FORTH ch11 |
| [24 词典内部解剖](docs/24-dictionary.md) | 词条四区、nt/xt/PFA、see、字典指针、ITC/DTC/STC | `24-dictionary.fs` | IBM-PC FORTH 下篇 ch5、Pelc ch16 |
| [25 外层解释器：mini-Forth](docs/25-outer-interp.md) | 手搓词典+解释器+编译器，词典自扩展的本体 | `25-outer-interp.fs` | 第四代 FORTH ch7 |
| [26 协作式多任务](docs/26-tasker.md) | activate 双返回、pause、user 变量隔离、任务死亡 | `26-tasker.fs` | Pelc ch14、IBM-PC FORTH §1.3 |
| [27 风格与分解](docs/27-factoring.md) | Brodie 分解判据、罗马数字对拍、纵横排版、命名、摩尔序 | `27-factoring.fs` | Thinking Forth ch5/6 |
| [28 RPN 计算器实战](docs/28-calculator.md) | 解析循环+分发表+会话回放+异常兜底的完整闭环 | `28-calculator.fs` | 综合章 |
| [29 Forth 简史与文献导读](docs/29-history.md) | 1969→FORTH-83→ANS94→gforth；四本书导读 | — | 两本中文书史料 |

### 附录（30–31）

| 章 | 主题 |
|---|---|
| [30 速查表](docs/30-cheatsheet.md) | 栈/返回栈/内存/控制流/解析/块/多任务/工具词速查 |
| [31 gforth 0.7.3 坑清单](docs/31-pitfalls.md) | 130+ 条本机实测坑位与替代写法总清单 |

学习路线：

- **刚接触 Forth**：01 → 02 → 03 → 04，先把手感练出来；
- **写过别的语言**：重点看 03（`DEFER/IS` 就是函数指针）、08（`CREATE DOES>`）、
  17（编译期编程）、25（手搓解释器），这四个是 Forth 和其它语言思路差得
  最远的地方；
- **要写正经项目**：11（异常）、16（命名空间）、19（测试）、21（向量分发）、
  28（实战闭环）是工程化五件套；
- **被坑了**：直接翻 [31 章](docs/31-pitfalls.md)，或 `grep -n "坑" examples/*.fs`。

## 工具链

| 组件 | 路径 / 版本 |
|---|---|
| GForth | 0.7.3，**WSL Debian** 的 `/usr/bin/gforth`（Windows 侧 `wsl -d Debian -- gforth …`） |
| 仓库位置 | Windows `G:\code\guide\forth` ↔ WSL `/mnt/g/code/guide/forth` |
| PowerShell | `pwsh`（`build.ps1` 入口，自动翻译路径走 WSL） |

## 验证命令

WSL Debian 内（推荐，路径直通）：

```bash
cd /mnt/g/code/guide/forth
gforth --version

./run-all.sh            # 跑全部，只看结果摘要
./run-all.sh -v         # 跑全部并显示每个例子的完整输出
./run-all.sh 07 25      # 只跑指定编号
gforth examples/04-control-flow.fs     # 单个示例
```

Windows PowerShell 通道（自动走 wsl -d Debian，写 build/ 日志）：

```powershell
pwsh ./build.ps1 -All                        # 全量验证
pwsh ./build.ps1 -File 04-control-flow.fs    # 单个示例
pwsh ./build.ps1 -Clean                      # 清理 build 目录
```

**判定标准**（三条全绿才算过）：

1. 退出码为 0；
2. stderr 没有任何输出；
3. 结束最后一行显示 `<0>`（数据栈为空）。

第 2、3 条是 Forth 特有的：某个词悄悄在栈上多留一个值，程序照样跑完不报错，
但后续代码全被污染；而 **gforth 脚本报错后退出码仍是 0**（实测），所以
stderr 干不干净才是硬门槛。每个示例末尾都写了 `.s` 兜底——**写 Forth 时
养成习惯，每个词跑完都看一眼栈**。

当前状态：28 个示例全部通过（gforth 0.7.3，WSL Debian 经 `./run-all.sh`
与 `build.ps1 -All` 双通道实测）。

## 平台差异说明

- `.fs` 文件为 UTF-8 **LF** 行尾，中文注释与中文词名直接运行；
  ⚠ `run-all.sh` 若是 CRLF，WSL 里会报 `bash\r`——先转 LF；
- 示例的临时文件统一写在 `/tmp/`（14 文件 IO、16 词表、23 块文件）；
- `build.ps1` 自动把 Windows 路径翻译成 `/mnt/g/...` 再调 WSL 内的
  gforth，并过滤 wsl.exe 自身的 NAT 提示噪音；
- macOS / 原生 Linux 亦可直接用 `run-all.sh`（装 gforth 即可），坑清单
  结论以 WSL Debian 实测为准（个别词条如 `find-name` 在不同构建上好坏
  不同，已在清单里标注）。

## 示例怎么读

- **章号 = 示例编号**：`docs/05-strings.md` ↔ `examples/05-strings.fs`，
  每章开头一行「对应示例」标注；
- 29、30、31 章无示例：29 是简史文献，30 是全文速查表，31 是坑位汇总
  清单——写代码前先查它；
- 改示例后重跑对应文件：`./run-all.sh NN`（如 `./run-all.sh 25`）。

## 相关教程

同为「交互式、可自扩展」 Lisp 家族对照 [commonlisp](../commonlisp/README.md)；
面向过程底层视角与内存布局对照 [cobol](../cobol/README.md)；
直接操作机器字的 [asm](../asm/intel/README.md)。
