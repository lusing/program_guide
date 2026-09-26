# Standard ML 教程与示例

Standard ML（SML'97）入门到进阶，**33 章分章文档 + 29 个可运行示例**。**每个示例都在三套实现上分别跑一遍**：SML/NJ 110.99.9（主通道）、Poly/ML 5.9.2（对照通道）、MLton 20241230（最严通道），三份 stdout **逐字节比对**。

这里不是「语法速览」。模块系统（`signature` / `structure` / `functor` / `:>` 不透明约束）、`eqtype`、异常与 `exnName`、`ref` 的物理相等语义、`String.tokens` 与 `String.fields` 的区别、以及三套实现真实分叉的地方，都在示例里实打实跑过。第 25–31 章是按两本书扩充的**书本篇进阶**：惰性与流、记忆化与递归挂起、持久队列与摊还、n 皇后三解（option/异常/续延）、续延风格正则匹配器、归纳定律的可执行化、词典 functor 与表示独立性——参考 Harper《Programming in Standard ML》第 15/24–33 章与 Myers/Clack/Poon《Programming with Standard ML》。

## 目录结构

```text
sml/
├── README.md                 本文件
├── check-literals.py         字面量预检查：字符串里不许有非 ASCII 字节
├── build.ps1                 PowerShell 构建/验证入口（Windows 上自动委托 WSL）
├── run-all.sh                等价的 shell 版验证脚本（WSL/Linux/macOS）
├── docs/                     01–33 章分章文档
│   ├── 01-overview.md        认识 SML：三套实现的分工与多通道验证的理由
│   ├── 02-toolchain.md       工具链与三种运行方式、静音堆
│   ├── 03 .. 24              核心语言 → 模块 → 实战（章号 = 示例号 + 2）
│   ├── 25 .. 31              书本篇进阶（Harper/Myers 两本书扩充）
│   ├── 32-pitfalls.md        坑清单：47 条「现象 → 原因 → 修法」
│   └── 33-differences.md     三实现差异 17 条 + 30 条可移植写法手册
└── examples/                 29 个 .sml 示例（01-basics .. 29-dictionary）
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 认识 Standard ML](docs/01-overview.md) | SML'97 的定位、三套实现的分工、为什么必须多通道验证 | — |
| [02 工具链与三种运行方式](docs/02-toolchain.md) | `sml` / `poly` / `mlton` 各自的调用方式、静音堆、`</dev/null` 的必要性 | — |
| [03 程序结构与求值](docs/03-structure.md) | `val`/`fun`/`val _ =`、类型推断、嵌套注释、求值顺序 | 01-basics |
| [04 类型系统](docs/04-types.md) | 七种基础类型、类型标注、相等类型、`type` 别名 | 02-types |
| [05 表达式与运算符](docs/05-expressions.md) | 优先级、`~` 取负、`div`/`mod` 与 `Int.quot`/`Int.rem`、`andalso` | 03-expressions |
| [06 元组与记录](docs/06-tuples-records.md) | 元组即记录、`#n`/`#label` 选择子、解构、记录相等性 | 04-tuples |
| [07 模式匹配](docs/07-patterns.md) | 通配、字面量、构造子、`as`、记录模式与 `...`、穷尽性 | 05-patterns |
| [08 列表与高阶列表函数](docs/08-lists.md) | `::` 与 `@`、`map`/`filter`、`foldl` 与 `foldr`、`ListPair` | 06-lists |
| [09 代数数据类型](docs/09-datatypes.md) | `datatype`、参数化构造子、递归类型、`withtype`、互递归 | 07-datatypes |
| [10 字符串与字符](docs/10-strings.md) | `sub`/`substring`/`concat`、`tokens` **vs** `fields`、`\ddd` 转义 | 08-strings |
| [11 递归与尾递归](docs/11-recursion.md) | 尾递归与累积器、互递归 `and`、Ackermann、汉诺塔 | 09-recursion |
| [12 异常](docs/12-exceptions.md) | 自定义异常、参数化异常、多分支 `handle`、`exnName` | 10-exceptions |
| [13 高阶函数与闭包](docs/13-higher-order.md) | 柯里化与偏应用、闭包、`o` 与 `op`、函数放进列表 | 11-higher-order |
| [14 结构与签名](docs/14-structures.md) | `structure`/`signature`、透明约束、`open`/`local`、`where type` | 12-structures |
| [15 functor](docs/15-functors.md) | 匿名/具名签名参数、`sharing type`、不透明产出 | 13-functors |
| [16 不透明约束与抽象数据类型](docs/16-abstraction.md) | `:>` 与不变量保护、`eqtype` 与相等性丢失 | 14-abstraction |
| [17 模块的组装](docs/17-modules.md) | `open` 的遮蔽顺序、顶层 `local`、`include` 的两个边界 | 15-modules |
| [18 可变状态](docs/18-mutable.md) | `ref`/`!`/`:=`、**`ref`/`array` 的 `=` 比物理地址**、`Array`/`Vector` | 16-mutable |
| [19 排序与经典算法](docs/19-algorithms.md) | 插入/归并/快速排序互证、二分查找、筛法、记忆化 fib | 17-algorithms |
| [20 数值计算](docs/20-numeric.md) | 二分法/牛顿法、梯形/辛普森积分、克拉默法则、浮点三坑 | 18-numeric |
| [21 解析](docs/21-parsing.md) | 手写词法器 + 递归下降求值器、词频统计、回文 | 19-parsing |
| [22 输入输出与文件](docs/22-io.md) | `TextIO` 读写/追加、`inputLine` 的换行符、目录、环境变量 | 20-io |
| [23 测试与断言](docs/23-testing.md) | 记录+闭包写断言器、异常断言、固定输入的属性测试 | 21-testing |
| [24 综合实战](docs/24-project.md) | 成绩 CSV 分析与报告写回校验 | 22-project |
| [25 惰性求值与流 ⭐](docs/25-laziness.md) | 挂起与记忆化、无穷流、素数筛、非严格证据、`lazy` 扩展对照 | 23-laziness |
| [26 记忆化与递归挂起 ⭐](docs/26-memoization.md) | memoize 包不住递归的大坑、开递归 `memoRec`、循环流打结 | 24-memo |
| [27 持久与易失数据结构 ⭐](docs/27-queues.md) | 双列表队列、摊还分析计步、持久性证明、易失别名 | 25-queues |
| [28 option、异常与续延 ⭐](docs/28-queens.md) | n 皇后三解：渗透/转义/CPS，枚举全部解、一发续延 | 26-queens |
| [29 续延风格正则匹配 ⭐](docs/29-regex-matcher.md) | 续延接力、Star 死循环与 proof-directed debugging、子串搜索 | 27-regex |
| [30 规格与正确性 ⭐](docs/30-correctness.md) | 循环不变量、归纳定律可执行化、确定性 LCG、双谓词排序规格 | 28-correctness |
| [31 数据抽象实战 ⭐](docs/31-dictionary.md) | ORDERED→functor、BST vs 平衡树、表示独立性、词频统计 | 29-dictionary |
| [32 坑清单](docs/32-pitfalls.md) | 47 条坑：语法/推断/值限制/相等性/字面量/模块/IO/验证 | — |
| [33 三实现差异清单](docs/33-differences.md) | 17 条实测差异、30 条可移植写法手册、静音堆设计 | — |

⭐ = 2026-09 按 Harper《Programming in Standard ML》与 Myers/Clack/Poon《Programming with Standard ML》两本书扩充的书本篇。

## 工具链

三套实现按 **环境变量 → 常见安装路径 → PATH** 三级回退解析（`run-all.sh` 的 `resolve_tool`）。也可用环境变量 `SML` / `POLY` / `MLTON` 显式指定。

**Windows 上跑**：工具链装在 WSL 里（本机是 Arch）：

```powershell
wsl -e bash -lc 'pacman -S smlnj polyml mlton'   # 或 Debian/Ubuntu：apt install smlnj polyml mlton
pwsh ./build.ps1 -All                             # build.ps1 检测到 Windows 自动委托 wsl
```

**WSL/Linux 直接跑**：

```bash
sml @SMLversion                    # sml 110.99.9
poly --version </dev/null          # Poly/ML 5.9.2 Release
mlton                              # MLton 20241230
```

> `poly` 的选项写错时会转去读标准输入，表现是**卡住不动**。任何时候都加上 `</dev/null`。

> Linux（Arch）的发行版 `smlnj` 包有打包 bug：`exportML`（静音堆必需）按打包机残留路径 `openIn` 直接崩。`run-all.sh` 检测到后自动建符号链接修复（需要 root 写 `/build`；无权限时打印手动修复命令）。详见坑 38。

> macOS 也实测过（MacPorts 的 SML/NJ、Poly/ML + 官方 MLton 二进制）：结果与 WSL/Linux 一致，脚本自动挂钩 MacPorts 的 GMP。

## 构建与验证

三条通道，每个示例都跑一遍（`quiet.<后缀>` 的后缀取 `sml @SMLsuffix`：Linux 是 `amd64-linux`，macOS 是 `amd64-darwin`）：

| 通道 | 命令 | 说明 |
|---|---|---|
| SML/NJ | `sml @SMLquiet @SMLload=build/quiet.amd64-linux` ← `use "../examples/NN.sml";` | 主通道，走「静音堆」 |
| Poly/ML | `poly -q --script ../examples/NN.sml` | 对照通道 |
| MLton | `mlton -output bin NN.sml` 然后运行 `bin` | 最严通道 |
| 一致性比对 | `cmp` / 逐字节比较 | 三份 stdout 应当逐字节相同 |

PowerShell 入口（Windows 自动委托 WSL；WSL/Linux/macOS 上原生执行）：

```powershell
cd sml                                # 本目录
pwsh ./build.ps1 -All                 # 跑全部（29 个 × 3 通道）
pwsh ./build.ps1 -File 25-queues.sml
pwsh ./build.ps1 -File 25             # 只写编号也行
pwsh ./build.ps1 -All -Verbose        # 附带打印每个示例的运行输出
pwsh ./build.ps1 -Clean               # 清理 build 目录
```

shell 入口（WSL / Linux / macOS 通用）：

```bash
cd sml                  # 本目录
./run-all.sh            # 跑全部，只看结果摘要
./run-all.sh -v         # 跑全部并显示每个例子的完整输出
./run-all.sh 25 26      # 只跑指定编号
```

两个脚本都会先跑一遍 `check-literals.py`（见下节），再编译。

### 判定标准

三条通道共用同一套判定，**五条都满足**才算通过：

1. **退出码为 0**
2. **stderr 为空**
   —— MLton 的编译错误走 stderr；SML/NJ 与 Poly/ML 的走 stdout，所以这条主要拦 MLton，第 5 条拦另外两个。
3. **stdout 里没有多余控制字符**（字节 0..31，TAB/LF/CR 除外）
4. **stdout 里出现结束标记** `==== NN 结束 ====`
   —— 这条最关键。SML/NJ 用了静音堆之后，编译错误也被一起静音、退出码恒为 0，**只有「跑没跑到最后一行」能证明它真的成功了**。
5. **stdout 里不出现编译器诊断**（`Error:` / `error:` / `Warning:` / `warning:` / `Static Errors` / `unhandled exception` / `Exception- ` / `Matches are not exhaustive`）

因此示例里 print 的文案**不要写出 `error:` 或 `warning:` 这种字样**，否则会被自己的验证脚本误判（`examples/15-modules.sml` 结尾有一行注释专门记了这件事，第 33 章 33.6 节讲了完整的判定设计）。

失败时 `build.ps1` / `run-all.sh` 返回退出码 1，可以直接拿去做回归。

## 关键设计：SML/NJ 的「静音堆」

SML/NJ 是个 REPL，跑完每一条 `val`/`fun`/`structure` 都会回显它的类型，拿这个和 Poly/ML、MLton 的输出做字节比对是不可能的。解法是在 `build/` 里预先导出一个**静音堆**：

```sml
val _ = Control.Print.out := { say = fn (_ : string) => (), flush = fn () => () }
val _ = SMLofNJ.exportML "quiet"
```

`Control.Print.out` 是编译器消息与顶层回显的输出流，换成空操作之后，stdout 里就只剩程序自己 `print` 的内容。之后跑示例时用 `sml @SMLquiet @SMLload=build/quiet.<后缀>` 加载它。

两个必须记住的点：

- **`exportML` 必须是文件最后一句**。堆加载后会**从 `exportML` 之后继续执行**，如果在它后面写 `OS.Process.exit`，那么每次加载堆都会立刻退出，表现为「程序一点输出都没有、退出码 0」。
- **`print` 不走 `Control.Print.out`**。所以静音堆只压掉编译器回显，压不掉程序输出——这正是我们要的效果。

代价是**编译错误也被静音了**，退出码还恒为 0。所以第 4 条判定（结束标记）是必须的；脚本在 SML/NJ 失败时还会**不带静音堆重跑一遍**并过滤掉 `[opening` / `[autoloading` / `[library` 行，把真正的诊断打出来。

## 关键设计：字符串字面量只写 ASCII

**Poly/ML 和 MLton 都拒绝字符串里的原始 UTF-8 字节**，SML/NJ 却接受。所以本目录的规矩是：

- **中文全部写在注释里**（注释里的 UTF-8 三家都接受）；
- **`print` 的文本一律 ASCII**；
- 需要输出中文时用 `\ddd` 十进制转义，三套实现都会把它解成同一串字节。结束标记就是这么写的：

```sml
val _ = say "==== 22 \231\187\147\230\157\159 ===="   (* 结束 *)
```

`check-literals.py` 会做词法扫描（跳过嵌套注释、处理转义和 `#"x"` 字符字面量），把所有违规位置和行号列出来，并检查注释是否配平。`run-all.sh` 与 `build.ps1` 都会在编译前跑它，几毫秒就能定位，比等 Poly/ML 报 `unprintable character` 省事得多。

## 三通道输出比对

最后会拿三条通道的 stdout 逐字节比对。绝大多数示例完全一致；下面这两个**按设计**不一致，脚本只打印原因、不计入告警（见 `diff_reason()` / `Get-DiffReason()`）：

| 示例 | 不一致的原因 |
|---|---|
| `02-types` | MLton 默认的 `int` 是 32 位，SML/NJ 与 Poly/ML 是 63 位 |
| `18-numeric` | 第 10 节**刻意**打印实数格式化的分叉点：`Real.toString`/`GEN` 对整值实数、`FIX 0` 的 .5 进位、`FIX 17` 的末位 |

`18-numeric` 那一节是故意留的：它同时也是在证明「差异检测本身是有效的」。其余示例若出现输出差异，脚本会报 `[DIFF]` 并要求人工确认。

## SML 本身容易踩的坑

跟编译器无关、纯粹是语言层面的坑，值得先看一眼（**47 条全清单见[第 32 章](docs/32-pitfalls.md)**）：

- **注释可以嵌套，必须配平**。漏一个 `*)` 会让后面整段代码被当成注释。
- **声明在「顶格的新行」处结束**。`handle`、`|` 这类续行千万不要顶格写。
- **`real` 不是相等类型**。`0.1 + 0.2 = 0.3` 根本不编译，要用 `Real.==`。
- **`ref` 和 `array` 的 `=` 比的是「是不是同一格」**。`ref 1 = ref 1` 是 `false`。
- **`String.tokens` 吞空字段，`String.fields` 保留**。解析 CSV 必须用 `fields`。
- **`memoize` 包一层递归函数不省调用**——递归不走表，要开递归（坑 40）。
- **惰性流的 `take` 惯用写法会多强制一格**——边界检查必须先于 force（坑 39）。
- **`val rec` 只收 `fn`**——循环数据用 `fun` 打结或 ref 回填（坑 41）。

## 当前状态

29 个示例 × 3 条通道 = **87 项全部通过**，0 项意外输出差异。已实测环境：

- **Windows 11 + WSL2（Arch，内核 6.18，x86_64）**：SML/NJ 110.99.9 / Poly/ML 5.9.2 / MLton 20241230（均为发行版包）。首次运行自动修复 Arch `smlnj` 包的 `exportML` 打包 bug（坑 38）。
- **macOS 12.7 x86_64**：SML/NJ 110.99.9（MacPorts）/ Poly/ML 5.9.2（MacPorts）/ MLton 20241230（官方二进制）。

`run-all.sh` 与 `build.ps1 -All`（经 WSL）结果一致：27 个示例报 `[same]`，2 个报 `[diff] 已知差异`（`02-types`、`18-numeric`，原因见上表）。

教程正文拆分为 `docs/` 下 33 个分章文档：第 1–24 章对应 22 个基础示例逐章讲解，第 25–31 章是按两本书扩充的书本篇进阶（对应示例 23–29），第 32 章是 47 条坑的清单，第 33 章是三实现差异清单与 30 条可移植写法手册。

## 相关教程

同一标准的兄弟教程：[../ocaml](../ocaml)、[../haskell](../haskell)、[../fsharp](../fsharp)。
