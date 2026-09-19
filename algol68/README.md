# Algol 68 开发指南（Algol 68 Genie 3.13.3 / a68g 实测）

面向**会编程（C/C++/任意现代语言背景皆可）、初学 Algol 68** 的读者：从零教到能写出正交、
强类型、含文件处理与并行的程序。20 章打透 a68g——从上戳写法、模式（mode）系统、一切皆表达式
的 unit、自定义运算符与优先级、过程与闭包（含臭名昭著的**作用域规则**）、行/结构/联合/引用、
transput 文件、FORMAT 格式化、事件式异常处理，到**内建并行**（`PAR`/`SEMA`）、测试方法论，
第 19 章实战**库存管理系统**（建档 → 过账 → 按类别控制break 估值报表 → 落盘读回 → 低库存预警 →
全程断言）。每章"读讲解 → 跑示例 → 改代码再跑"，全部 18 个示例在本机**双通道验证**通过。

> ⚠️ Algol 68 是"设计极其自洽、上手极其反直觉"的语言：关键字靠**大小写（上戳）**区分、没有
> "语句 vs 表达式"之分（统称 unit，都产值）、`/` 永远是实数除法、`CASE` 按**位置**而非值匹配、
> 捕获局部量的闭包**导出即运行期错误**、`create+associate` 是静默 no-op、`whole`/`fixed` 永远带
> 符号位、并行 `+:=` 会丢更新还可能碰巧对。网上资料多停留在 1968 年的报告原文或几十年前的实现。
> 本教程所有代码在 **Algol 68 Genie 3.13.3（macOS + MacPorts + clang 后端）** 实测，每章末
> "坑位清单"收录版本差异与实测陷阱——[CHEATSheet.md](CHEATSheet.md) 汇总语法速查 + 约 **130 条
> 实测坑位**，[docs/20-pitfalls.md](docs/20-pitfalls.md) 是完整分类索引。

## 目录结构

```text
algol68/
├── README.md       本文件
├── docs/           20 章教程（01 → 20 顺序阅读；⭐ 为特色重点章）
├── examples/       18 个示例目录（章号 = 目录号，02–19；01 为全景无示例，20 为坑位索引无示例）
├── build.ps1       统一验证脚本（pwsh 7 运行，Windows 入口）
├── run-all.sh      等价的 bash 验证入口（macOS / Linux / Git Bash）
├── CHEATSheet.md   语法速查 + 约 130 条实测坑位索引
└── build/          运行产物（check/ 与 release/ 两通道，gitignore）
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景与工具链](docs/01-overview.md) | Algol 68 家族史、a68g 定位（解释器+C 后端）、上戳写法、编译模型、验证方法论、macOS 链接坑 | — |
| [02 第一个程序](docs/02-hello.md) | BEGIN...END 骨架、分号纪律、print/put 到 stand out、结束标记 + 断言习惯、双通道验证 | `02_hello` |
| [03 模式系统](docs/03-modes.md) ⭐ | MODE 与正交类型、INT/REAL/BOOL/CHAR/STRING、强制转换、值模式 vs 引用模式、别名不隔离 | `03_modes` |
| [04 数值与运算](docs/04-numeric.md) | `/` 永远实数除、OVER vs MOD 对负数不自洽、ENTIER 是 floor、INT 溢出中止、whole/fixed | `04_numeric` |
| [05 条件与控制流](docs/05-control.md) | IF/ELIF/ELSE/FI、CASE 按位置匹配、`/=` 不等于、NOT/AND/OR 优先级、一切皆表达式 | `05_control` |
| [06 循环](docs/06-loops.md) | FOR FROM/TO/BY/DOWNTO/WHILE、控制变量只读且块内作用域、无 break/continue | `06_loops` |
| [07 字符串处理](docs/07-strings.md) ⭐ | STRING=[]CHAR、按字节非字符、CJK 切片会切坏、`+` 拼接、无反斜杠转义、ABS/REPR | `07_strings` |
| [08 运算符](docs/08-operators.md) | 优先级体系、自定义 PRIO/OP、运算符名不可含空格、`$`/`|` 不可用、重载无限递归坑 | `08_operators` |
| [09 过程](docs/09-procedures.md) | PROC 语法、传值 vs REF、多值返回、过程名可含空格、无参调用不加括号、导出作用域坑 | `09_procedures` |
| [10 数组与行](docs/10-arrays.md) | 行显示隐含下界恒 1、LWB/UPB、切片重基化、FLEX、多维 `m[1,2]`、`[] INT` 合规过程 | `10_arrays` |
| [11 结构](docs/11-structures.md) | MODE STRUCT、OF 字段访问（右结合）、嵌套结构、结构数组、UNION + CASE 分派 | `11_structures` |
| [12 引用与堆](docs/12-refs.md) | REF/HEAP/LOC、`:=` 重绑 vs 改值、IS/ISNT 不可靠、typed NIL 链表、自动 GC | `12_refs` |
| [13 闭包与一等过程](docs/13-closures.md) ⭐ | 高阶过程、PROC 数组、捕获 HEAP 全局可导出、★作用域规则★（导出捕获局部即运行期错）、REF 传状态、柯里化 | `13_closures` |
| [14 文件与 transput](docs/14-transput.md) | establish/open/close、put/get、on logical file end 安全读回、append、create+associate no-op、幂等 | `14_transput` |
| [15 格式化输出](docs/15-formats.md) ⭐ | FORMAT `$...$`、printf 双层括号、★相邻整数图形必须加逗号★、Na 精确宽度、whole/fixed 带符号 | `15_formats` |
| [16 异常与事件](docs/16-exceptions.md) | 无 try/catch、事件 routine（value error/文件结束）、不可捕获的除零/越界/溢出、防御式哨兵 | `16_exceptions` |
| [17 并行](docs/17-parallel.md) ⭐ | PAR 并列子句、汇合、SEMA `LEVEL n` 临界区、生产者-消费者握手、竞态坑、确定性设计 | `17_parallel` |
| [18 测试方法论](docs/18-testing.md) | 纯函数被测库、断言夹具（FAIL 走 stand error）、边界用例、内建 ASSERT、双通道哲学、四条判定 | `18_testing` |
| [19 综合实战：库存管理](docs/19-capstone.md) ⭐ | MODE 数据模型 + INT 分定点金额 + 过账（拒无效 SKU、超卖为负）+ 控制break 报表落盘读回 + 低库存预警 | `19_capstone` |
| [20 坑位总清单](docs/20-pitfalls.md) | 全书约 130 条实测坑的 16 类索引 + 三个"静默算错"警示 + 防御清单 | — |

## 构建工具链

- **Algol 68 Genie 3.13.3**（`a68g`）：macOS 走 MacPorts `/opt/local/bin/a68g`（`port install
  algol68g`），**解释器 + C 后端编译器二合一**——默认解释执行，`-O2` 翻译成 C 再交 clang 编成原生
  代码运行；Linux/Windows 可用发行版包或官网构建。官方主页 <https://algol68genie.nl/>。
- 源码一律 **UTF-8、上戳写法**（关键字全大写，见 [docs/01](docs/01-overview.md)），扩展名 `.a68`。
- 脚本按 **环境变量 `A68G` → 固定路径 → PATH** 顺序探测，不硬编码。
- macOS 专属：`a68g -O2` 的链接步骤缺 `-syslibroot`，报 `ld: library 'System' not found`；脚本自动造
  一个 `ld` 垫片放进 PATH 最前补上 `-syslibroot`（仅 Darwin 且能取到 SDK 时安装，Linux/Windows 不触发）。
  `run-all.sh` 开头还会把 locale 切到 UTF-8——`C` locale 下 bash 会把紧邻全角标点的 `$var` 误分词。

## 验证命令

```bash
cd /Volumes/mac004/code/programming/algol68
./run-all.sh                 # 全部 18 示例：check + release 双通道
./run-all.sh 19              # 单个示例（编号或目录名）
./run-all.sh 02 08 19        # 多个
./run-all.sh -v              # 附带每个示例的完整输出
./run-all.sh --clean         # 清理 build/ 产物
```

```powershell
pwsh -File build.ps1                 # Windows 等价入口（与 run-all.sh 同判定）
pwsh -File build.ps1 -Example 19_capstone
pwsh -File build.ps1 -Clean
```

**判定标准**：每个示例跑两条通道——

```text
check 通道：  a68g --warnings --notices   解释器，全运行时检查 + 告警 + notice
release 通道：a68g -O2                    C 后端编译，优化，真实出货形态
```

每通道四条判定：① 运行退出码 0 ② stderr 空（告警/提示/FAIL/运行错误都走 stderr）③ stdout 无控制
字符（TAB/LF/CR 除外）④ 含结束标记 `==== NN 结束 ====`（证明跑到了尾而非中途崩溃）；外加**跨通道**：
check/release 两通道 stdout **逐字节一致**（排除依赖未定义行为或"优化改变语义"的"碰巧对"）。

> a68g **没有可移植的"自定义退出码"设施**（不像 COBOL `STOP RUN RETURNING n`），所以本教程把断言
> 失败写进 `stand error`，靠"stderr 是否为空"判成败；内建 `ASSERT` 失败则以退出码 1 fail-fast，
> 作为唯一非零退出途径，守"绝不该被违反"的硬不变量。

## 学习路线

- **语言篇（02–13）**：顺序读。03（模式）、07（字符串按字节）、13（闭包与作用域规则）是 Algol 68
  特有的深水区，值得两遍——Algol 68 的一切"反直觉"几乎都源于"正交设计 + 一切皆表达式 + 强作用域规则"。
- **系统篇（14–18）**：transput 文件、FORMAT 格式化、事件式异常、内建并行、测试方法论。17（并行）
  是 Algol 68 早在 1968 年就内建的看家特性，18（测试）解释了本仓库每个示例"凭什么可信"。
- **实战（19）**：跟着源码读，`fails` 断言就是功能清单；INT"分"定点金额 + 手写无符号格式化 +
  控制break 报表落盘读回，是把前 18 章组装成真正会动的程序的范本。
- **速查**：[CHEATSheet.md](CHEATSheet.md)（语法 + 约 130 条坑位）；[docs/20-pitfalls.md](docs/20-pitfalls.md)（坑位分类索引）。

## 相关教程

- [cobol](../cobol/README.md)、[freebasic](../freebasic/README.md)、[freepascal](../freepascal/README.md)
  ——同为"经典语言 + 现代编译器"视角，验证方法论同源（双通道 + 逐字节比对）；本教程的章节结构、
  断言纪律与第 19 章库存实战直接对齐 COBOL 教程的标准。
- [forth](../forth/README.md)、[prolog](../prolog/README.md)、[sml](../sml/README.md)、[ocaml](../ocaml/README.md)
  ——另几门范式迥异的经典语言，可与 Algol 68 的"正交命令式 + 内建并行"对照。
- [fortran](../fortran/README.md)——同为科学计算时代的元老语言，可对照两者的数值与数组模型。
