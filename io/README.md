# Io 编程指南

面向**会编程（C++ / Python 背景最佳）、初学 Io** 的读者：24 章从零讲到能写一个完整程序。

Io 是 Steve Dekorte 2002 年发布的**纯原型、纯消息传递**动态语言。它的极简程度在主流语言里
几乎找不到对手：**没有类、没有关键字、没有语句——只有消息**。`if`、`while`、`for`、`and`、
`return` 全都是普通方法，`1 + 2` 也不是语法，而是「把消息 `+` 发给 `1`」。

这不是为了炫技。把语言拆到只剩「对象」和「消息」两块积木之后，**你可以用消息本身去改写语言**——
自定义控制流、自定义运算符优先级、给不存在的消息挂兜底处理（`forward`），全都在普通代码里完成，
不需要宏、不需要改编译器。第 17 章（元编程）和第 24 章（实战）就是这条能力线的终点。

> ⚠️ 本教程的结论**全部来自本机实测**，且跑在**两条通道**上（动态链接的 `io` 与静态的 `io_static`），
> 输出逐字节一致。Io 是个相当小众、文档稀薄且新旧版本行为差异很大的语言——
> 网上能找到的写法有相当一部分在本机构建（`System version` = `20260302`）上**跑不通或行为相反**。
> 每条「实测」背后都有一个跑出来的数字，不是猜的。

## 目录结构

```text
io/
├── README.md       本文件
├── docs/           24 章教程（01 → 24 顺序阅读）
├── examples/       23 个示例目录（章号 = 目录号；01 为纯文档章）
│                   另含 2 个观察项 observe_*.io（只要求跑到底，不参与字节比对）
├── run-all.sh      shell 入口（双入口之一）
├── build.ps1       PowerShell 入口（双入口之一，须 PowerShell 7 / pwsh，判定与 run-all.sh 逐条一致）
└── CHEATSheet.md   语法速查 + 全部 240 条实测坑位索引
```

## 章节索引

24 章分四段：**地基（02–08）→ 数据与抽象（09–13）→ 系统能力（14–17）→ 并发、工程与实战（18–24）**。

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景](docs/01-overview.md) | Io 是什么、三条心智模型、章节地图、工具链 | — |
| [02 第一行输出与最小心智模型](docs/02-hello.md) | `writeln` / `println`、字面量、注释、中文字面量 | `02_hello` |
| [03 数字：只有一种 Number](docs/03-numbers.md) | 除法给浮点、`%` 带符号、`**` 左结合、`round` 远离零、位运算 | `03_numbers` |
| [04 序列：字节串、码点串与不可变字面量](docs/04-sequences.md) | `size` / `sizeInBytes`、`at` 给码点、就地方法与 `asMutable` | `04_sequences` |
| [05 控制流：没有 if，只有消息](docs/05-control.md) | 真值只有 `nil`/`false`、`and`/`or` 短路、`switch`、`?` 消息 | `05_control` |
| [06 消息：三种形状与优先级](docs/06-messages.md) | 一元/关键字/二元、优先级表、`perform`、`resend` | `06_messages` |
| [07 原型：克隆、槽与 proto 链](docs/07-prototypes.md) | 三种槽操作符、proto 链、`clone` 自动 `init`、`do` 的可见性 | `07_prototypes` |
| [08 方法：参数、作用域与 return](docs/08-methods.md) | 位置参数、变参、`call` 现场、方法自动激活、自省 | `08_methods` |
| [09 列表](docs/09-lists.md) | `list(...)`、负索引、`sort` / `sortBy`、`reduce`、嵌套表打印 | `09_lists` |
| [10 映射](docs/10-maps.md) | `atPut` / `at` / `hasKey`、键必须是 Sequence、顺序不可依赖 | `10_maps` |
| [11 块与闭包](docs/11-blocks.md) | 块是对象、闭包捕获上下文、`=` 与 `:=` 的分工、惰性 | `11_blocks` |
| [12 迭代与集合遍历](docs/12-iteration.md) | `foreach` 三种形状、`map`/`select`/`detect`、遍历中改集合 | `12_iteration` |
| [13 异常与错误处理](docs/13-exceptions.md) | `try` 成功也给 `nil`、`catch` 是副作用、`raise`、`signal` | `13_exceptions` |
| [14 文件与目录](docs/14-files.md) | `Path` 就是 `Sequence`、`setContents` 的编码坑、`Directory` 遍历 | `14_files` |
| [15 系统、进程与环境](docs/15-system.md) | `System args` / 环境变量、`runCommand` 的两侧编码坑 | `15_system` |
| [16 文本处理](docs/16-text.md) | 编码三件套、`interpolate` 三个坑、无参 `split` 的字节级雷 | `16_text` |
| [17 元编程与反射](docs/17-meta.md) | 槽内省、运行时造方法、`doString`、`OperatorTable`、`forward` | `17_meta` |
| [18 协程与 Future](docs/18-coroutines.md) | `Coroutine` / `Scheduler`、`coroDo`、`yield`、`Future` | `18_coroutines` |
| [19 Actor 与并发](docs/19-actors.md) | `actorRun`、`@` / `@@` 投递、单生产者单消费者流水线 | `19_actors` |
| [20 单元测试](docs/20-testing.md) | 手写 `chk`、`UnitTest`、确定性输出、异常断言 | `20_testing` |
| [21 序列化与持久化](docs/21-serialize.md) | `serialized` 往返、本地槽导致栈溢出、自己写键值持久化 | `21_serialize` |
| [22 性能陷阱与基准](docs/22-performance.md) | 字符串 O(n²)、`getSlot` 取本体、递归上限、Profiler 现状 | `22_performance` |
| [23 外部函数接口](docs/23-ffi.md) | `DynLib`、整数签名能过、浮点签名过不去、自己编 C 库 | `23_ffi` |
| [24 实战：一个完整的 Io 程序](docs/24-capstone.md) | 访问日志分析器：解析 → 聚合 → 排序 → 渲染 → 落盘 | `24_capstone` |

只想查语法就直奔 [CHEATSheet.md](./CHEATSheet.md)，里面有一张覆盖 **240 条**实测坑位的总索引。

## 构建工具链

本教程**不用任何包管理器里的 Io**——发行版自带的 Io 大多停在 2009 年的老版本，
本教程涉及的若干行为（`actorRun`、`Future`、`serialized` 的具体产物格式、`Slot x not found`
的报错措辞）在旧二进制里根本不存在，装一个出来只会得到一堆对不上的实测输出。

本机两通道都是**从源码编译**得到的（CMake + `build.sh`），落在：

```text
~/.workbuddy/binaries/io/bin/io          动态链接版（十几 KB，运行时按 rpath / 安装前缀找库与 addon）
~/.workbuddy/binaries/io/bin/io_static   静态单文件版（约 1.5 MB，不依赖任何外部动态库）
```

两者报同一个版本号（Io 拿日期当版本号，本机 `System version` 是 `20260302`），
都从 `System installPrefix` 下的 `lib/io` 加载 `Object.io` / `List.io` / `Exception.io`
这些**用 Io 自己写成的核心库**。

> **为什么要两条通道**：`io` 与 `io_static` 语义相同，差别只在**加载方式**。
> 所以「两条通道输出逐字节一致」这条判定，检验的不是两种语义，
> 而是**示例没有偷偷依赖动态库加载或安装前缀**。本仓库里管这叫「跨通道比对」。

两个入口都**探测**解释器路径，**不硬编码**：环境变量 `IO_BIN` → `System installPrefix` 下的
`bin/io_static` / `bin/io` → `PATH` 上的 `io_static` / `io`。找不到的通道自动跳过。

## 验证命令

```bash
cd io
bash run-all.sh                 # shell 入口：23 个示例 × 两条通道
bash run-all.sh 07 13 24        # 只跑指定章（章节号即示例号）
pwsh -File build.ps1            # PowerShell 入口，判定与上者逐条一致
pwsh -File build.ps1 -Example 24
```

产物落在 `io/build/`（`<章>_<名>.dyn.out` / `.static.out` / `.sec` / `.exit` 等），可随时删。

### 七条判定 + 观察项

| # | 判定 | 为什么需要这一条 |
|---|---|---|
| 1 | 退出码为 0 | 基础 |
| 2 | stderr 为空 | 合法输出走 stdout、诊断走 stderr；等价于「零告警」 |
| 3 | stdout 里同时出现 `==== NN 开始 ====` 与 `==== NN 结束 ====` | **Io 的未捕获异常会中断脚本、退出码却仍是 0**，只判退出码会放过「跑到一半就死了」 |
| 4 | 两个标记之间的区间非空 | 保证真的跑了内容，不是空壳 |
| 5 | 区间不含 `\r` 或 `ESC` | 原始内存字节打出来能退 0、有标记，肉眼却看不出来 |
| 6 | 区间里没有**未捕获异常横幅** | 横幅形状是「`  Exception: …` + **紧邻的下一行**是纯 `-`」这个**组合**，不是任何单独一行 |
| 7 | 两条通道的区间逐字节一致 + 同通道连跑两次一致 | 抓 `Map` 迭代序、对象地址、墙钟时间等非确定性 |

第 6 条的判据写细是有原因的：**单看一行判不出来**。13 章的示例会主动打印异常消息
（`try(...) error`）做演示，24 章的表格会打 26 个 `-` 当分隔线——两者都像「溃逃痕迹」。
这个调整本身就是被 24 章的一次误报逼出来的。

有两类文件**不参与逐字节比对**，另立判定：

```text
examples/13_exceptions/observe_13_uncaught.io   观察「未捕获异常横幅走 stdout + 退出码仍是 0」
examples/15_system/observe_15_relpath.io        观察「换个调用方式，launchPath / launchScript 怎么变」
```

**观察项（`observe_*.io`）** 只要求跑到底 + 打印自己的观察标记 + 出现预期痕迹，
**不要求输出确定性、不参与跨通道比对**。它专门用来装那些「一个脚本中途死掉」
「同一份代码两种调用方式结果不同」的**客观行为**——这类东西放进普通示例会把
「输出可比性」这条纪律捅个洞。

### 验证状态

| 入口 | 结果 |
|---|---|
| `bash run-all.sh` | **全部通过**（23 示例 × 4 项 + 2 观察项） |
| `pwsh -File build.ps1` | **全部通过**，通过总数与上者一致 |

两个入口的核心算法一致：跑 dyn 通道 → 跑 static 通道 → 抽区间逐字节比对 → 同通道重跑一次比对 →
判 stderr / 标记 / 控制字符 / 溃逃横幅 → 再跑观察项。`build.ps1` 在读取产物时显式指定
UTF-8 编码（否则 pwsh 的默认编码会把中文输出读花）。

## 本机实测的几个代表性坑位

完整 240 条见 [CHEATSheet.md](./CHEATSheet.md)。挑几条最能说明「Io 跟你想的不一样」的：

| 坑 | 实测结果 |
|---|---|
| 以为未捕获异常会让退出码非零 | 横幅打 **stdout**、脚本中断、`rc` **仍是 0**（13.3） |
| `"abc" asNumber` 以为是 `0` | 是 **`nan`**，且 `nan < 100` 为 `true`、`nan > 599` 为 `false`——只写单边范围判断拦不住（24.1） |
| 无参 `split` 以为是「按空白」 | **按字节**扫空白：`"上" split` 得 `list("")`（U+4E0A 低字节 0x0A）；中文文本必须 `split(" ")`（16.4） |
| 以为 `try(expr)` 返回表达式的值 | 成功也返回 **`nil`**——它就是 7 行 Block，克隆 Coroutine 跑一遍（13.1） |
| `method(a, b := 10, a + b)` 当默认参数 | `:=` 被当成第二个**形参名** `setSlot`，`argumentNames` = `list("a", "setSlot")`（08.3） |
| `(method(a, b, b))(1)` 当立即调用 | 那是**两个相邻括号组**，方法被整个丢掉，结果是 `1`；要 `.call(1)`（08.2） |
| `do(...)` 里用逗号分隔多个槽定义 | **只有第一个实参被求值**，后面的静默丢掉（07.9） |
| `do(...)` 读外层方法的局部变量 | 作用域链只到「接收者 + Lobby」，报 `Object does not respond to 'x'`；要 `lexicalDo`（07.10） |
| 把 `method(...)` 当 `withHandler` 的处理器 | `method` 造的块 `isActivatable = true`，一进形参就被零参调用；必须 `block(...)`（13.9） |
| `2.5 round` 以为是银行家舍入 | 是 **`.5` 一律远离零**：`2.5 round` = 3、`-2.5 round` = -3（03.7） |
| `setEnvironmentVariable(name, nil)` 清变量 | **段错误**，`rc=139`，两个二进制都一样（15.2） |
| `File setContents("中文")` | 写的是**内部表示**（UCS4，每码点 4 字节），读回来 size 是 12 而不是 3；必须 `asUTF8`（14.2） |
| `DynLib` 调 `pow(2, 10)` | 不是 `1024`——浮点签名过不去，返回值是整数寄存器残留，连跑三次值都不同（23.4） |
| `"中文#{1 + 2}" interpolate` | 得到 `中文1`（丢尾巴）；`"中文#{(1 + 2)}"` 直接**段错误** `rc=139`（16.5） |
| 拿 `String` 当一个实在的类型 | 它是 `ImmutableSequence` 的别名，`slotNames` 只有 `list("type")`，`isKindOf` 也是 false（04.1） |

## 与其它教程的关系

结构、章节数（24）、双入口验证纪律、`docs/` + `examples/` + `CHEATSheet.md` 的布局都与仓库里
[julia](../julia/) / [haskell](../haskell/) / [elixir](../elixir/) / [prolog](../prolog/) 等保持一致。
Io 这一套的特殊之处在于：**它的核心库是自己写自己的**（`libs/iovm/io/*.io` 就是 Io 源码），
所以很多「为什么是这样」在本仓库里能直接翻到实现——第 13 章 `try` 那 7 行、第 8 章
`raise` 覆盖 `error` 的那一行，都是从源码里读出来的。
