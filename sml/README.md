# Standard ML 教程与示例

Standard ML（SML'97）入门到进阶，配套 22 个可运行示例。**每个示例都在三套实现上分别跑一遍**：SML/NJ 110.99.9（主通道）、Poly/ML 5.9.2（对照通道）、MLton 20241230（最严通道），三份 stdout **逐字节比对**。macOS 与 Linux 两套环境都实测通过（结果一致：20 个示例三通道逐字节相同，2 个是登记在案的已知差异）。

这里不是「语法速览」。模块系统（`signature` / `structure` / `functor` / `:>` 不透明约束）、`eqtype`、异常与 `exnName`、`ref` 的物理相等语义、`String.tokens` 与 `String.fields` 的区别、以及三套实现真实分叉的地方，都在示例里实打实跑过。

## 目录结构

```
sml/
├── README.md                 本文件
├── StandardML编程指南.md      教程正文（26 章）
├── check-literals.py         字面量预检查：字符串里不许有非 ASCII 字节
├── build.ps1                 PowerShell 构建/验证入口（三条通道）
├── run-all.sh                等价的 shell 版验证脚本
└── examples/
    ├── 01-basics.sml             程序结构、val/fun、类型推断、嵌套注释
    ├── 02-types.sml              七种基础类型、类型标注、相等类型
    ├── 03-expressions.sml        运算符与优先级、整数/实数除法、andalso
    ├── 04-tuples.sml             元组与记录、# 选择子、解构
    ├── 05-patterns.sml           模式匹配全谱：通配、构造子、as、嵌套
    ├── 06-lists.sml              列表构造、map/filter/foldl/foldr、ListPair
    ├── 07-datatypes.sml          datatype、参数化构造子、互递归、withtype
    ├── 08-strings.sml            字符串与字符、tokens/fields、手写 indexOf
    ├── 09-recursion.sml          尾递归与累积器、互递归、Ackermann、汉诺塔
    ├── 10-exceptions.sml         raise/handle、参数化异常、exnName
    ├── 11-higher-order.sml       柯里化、偏应用、闭包、op 与组合
    ├── 12-structures.sml         structure/signature、透明约束、where type
    ├── 13-functors.sml           functor、spec 形式参数、sharing type、不透明产出
    ├── 14-abstraction.sml        透明 vs 不透明、不变量保护、eqtype
    ├── 15-modules.sml            open/local/include 与遮蔽规则
    ├── 16-mutable.sml            ref / Array / Vector、物理相等 vs 结构相等
    ├── 17-algorithms.sml         插入/归并/快速排序、二分查找、筛法、memo 斐波那契
    ├── 18-numeric.sml            二分法/牛顿法、梯形/辛普森积分、克拉默法则、插值
    ├── 19-parsing.sml            手写词法器 + 递归下降求值器、词频统计、回文
    ├── 20-io.sml                 TextIO 读写/追加、格式化、目录、环境变量
    ├── 21-testing.sml            记录+闭包写断言器、异常断言、属性测试
    └── 22-project.sml            综合实战：成绩 CSV 分析与报告写回校验
```

## 工具链

三套实现按 **环境变量 → 常见安装路径 → PATH** 三级回退解析（`run-all.sh` 的 `resolve_tool`），macOS 与 Linux 通用。也可用环境变量 `SML` / `POLY` / `MLTON` 显式指定。

| 工具 | macOS（编写机） | Linux（Arch，亦适用于其他发行版包） | 版本 | 定位 |
|---|---|---|---|---|
| `sml` | MacPorts `smlnj`，`/opt/local/bin/sml` | `pacman -S smlnj`，`/usr/lib/smlnj/bin/sml` | SML/NJ 110.99.9 | 主通道。生态最全、编译最快，但顶层会回显每一个绑定，直接跑没法做字节比对 |
| `poly` | MacPorts `polyml`，`/opt/local/bin/poly` | `pacman -S polyml`，`/usr/bin/poly` | Poly/ML 5.9.2 | 对照通道。`--script` 批量执行很干净，报错文本与 SML/NJ 完全不同 |
| `mlton` | 官方 macOS 二进制 `~/.workbuddy/binaries/mlton/mlton-20241230-1.*/bin/mlton` | `pacman -S mlton`，`/usr/bin/mlton` | MLton 20241230 | 最严通道。整体优化编译器，标准符合性最好，也最挑剔（32 位 `int`、拒绝 UTF-8 字面量） |
| GMP | MacPorts `gmp`，`/opt/local/include/gmp.h` | 系统自带 `/usr/include/gmp.h` | — | MLton 的运行时依赖。macOS 上链接时要显式指路，Linux 发行版包已配好 |
| `pwsh` | `/opt/local/bin/pwsh` | 任意 pwsh 7 | PowerShell 7.6.5 | 跑 `build.ps1`（可选入口；Linux 上直接用 `run-all.sh`） |

其他发行版：`apt install smlnj polyml mlton`（Debian/Ubuntu）。

验证安装：

```bash
sml @SMLversion                    # sml 110.99.9
sml @SMLsuffix                     # amd64-darwin（macOS）/ amd64-linux（Linux）
poly --version </dev/null          # Poly/ML 5.9.2 Release
command -v mlton                   # 各平台路径见上表
```

> `poly` 的选项写错时会转去读标准输入，表现是**卡住不动**。任何时候都加上 `</dev/null`。

macOS 注意：本机的 MLton 二进制是给 macOS 13 编的，这台机器是 12.7，所以每次链接都会刷几十 KB 的 `ld` 版本警告（走 stderr，退出码仍是 0）。验证脚本把编译日志单独收着、成功后就删掉，不让它污染判定。**Linux 上无此问题。**

Linux（Arch）注意：发行版打的 `smlnj` 包有打包 bug，`exportML`（静音堆必需）会按打包机残留路径 openIn 直接崩。`run-all.sh` 检测到后自动建符号链接修复（需要 root 写 `/build`；无权限时打印手动修复命令）。详见指南坑 38。

## 构建与验证

三条通道，每个示例都跑一遍（`quiet.<后缀>` 的后缀取 `sml @SMLsuffix`：macOS 是 `amd64-darwin`，Linux 是 `amd64-linux`）：

| 通道 | 命令 | 说明 |
|---|---|---|
| SML/NJ | `sml @SMLquiet @SMLload=build/quiet.amd64-linux` ← `use "../examples/NN.sml";` | 主通道，走「静音堆」 |
| Poly/ML | `poly -q --script ../examples/NN.sml` | 对照通道 |
| MLton | `mlton -output bin NN.sml` 然后运行 `bin` | 最严通道；macOS 上若 GMP 在 MacPorts 还需 `-cc-opt -I/opt/local/include -link-opt -L/opt/local/lib`（脚本自动检测） |
| 一致性比对 | `cmp` / 逐字节比较 | 三份 stdout 应当逐字节相同 |

PowerShell（可选入口，macOS / Windows / Linux 通用）：

```powershell
cd sml                                # 本目录
pwsh ./build.ps1 -All                 # 跑全部（22 个 × 3 通道）
pwsh ./build.ps1 -File 14-abstraction.sml
pwsh ./build.ps1 -File 14              # 只写编号也行
pwsh ./build.ps1 -All -Verbose        # 附带打印每个示例的运行输出
pwsh ./build.ps1 -Clean               # 清理 build 目录
```

macOS / Linux（等价的 shell 脚本，两平台都实测通过）：

```bash
cd sml                  # 本目录
./run-all.sh            # 跑全部，只看结果摘要
./run-all.sh -v         # 跑全部并显示每个例子的完整输出
./run-all.sh 14 15      # 只跑指定编号
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

因此示例里 print 的文案**不要写出 `error:` 或 `warning:` 这种字样**，否则会被自己的验证脚本误判。`examples/15-modules.sml` 结尾有一行注释专门记了这件事（指南第 26 章 26.6 节讲了完整的判定设计）。

失败时 `build.ps1` / `run-all.sh` 返回退出码 1，可以直接拿去做回归。

## 关键设计：SML/NJ 的「静音堆」

SML/NJ 是个 REPL，跑完每一条 `val`/`fun`/`structure` 都会回显它的类型：

```
val x = 1;
val it = 1 : int
```

拿这个和 Poly/ML、MLton 的输出做字节比对是不可能的。解法是在 `build/` 里预先导出一个**静音堆**：

```sml
val _ = Control.Print.out := { say = fn (_ : string) => (), flush = fn () => () }
val _ = SMLofNJ.exportML "quiet"
```

`Control.Print.out` 是编译器消息与顶层回显的输出流，换成空操作之后，stdout 里就只剩程序自己 `print` 的内容。之后跑示例时用 `sml @SMLquiet @SMLload=build/quiet.<后缀>` 加载它（后缀取 `sml @SMLsuffix`：macOS `amd64-darwin`，Linux `amd64-linux`）。

两个必须记住的点：

- **`exportML` 必须是文件最后一句**。堆加载后会**从 `exportML` 之后继续执行**，如果在它后面写 `OS.Process.exit`，那么每次加载堆都会立刻退出，表现为「程序一点输出都没有、退出码 0」。
- **`print` 不走 `Control.Print.out`**。所以静音堆只压掉编译器回显，压不掉程序输出——这正是我们要的效果。反过来，把 `Control.Print.out` 重定向到 stderr 也不行，那会把 `print` 和回显一起弄丢。

代价是**编译错误也被静音了**，退出码还恒为 0。所以第 4 条判定（结束标记）是必须的；脚本在 SML/NJ 失败时还会**不带静音堆重跑一遍**并过滤掉 `[opening` / `[autoloading` / `[library` 行，把真正的诊断打出来。

## 关键设计：字符串字面量只写 ASCII

**Poly/ML 和 MLton 都拒绝字符串里的原始 UTF-8 字节**，SML/NJ 却接受：

```
Poly/ML: error: unprintable character \231 found in string
MLton  : Extended text constants (using UTF-8 byte sequences) disallowed,
         compile with -default-ann 'allowExtendedTextConsts true'
```

所以本目录的规矩是：

- **中文全部写在注释里**（注释里的 UTF-8 三家都接受）；
- **`print` 的文本一律 ASCII**；
- 需要输出中文时用 `\ddd` 十进制转义，三套实现都会把它解成同一串字节。结束标记就是这么写的：

```sml
val _ = say "==== 22 \231\187\147\230\157\159 ===="   (* 结束 *)
```

`check-literals.py` 会做词法扫描（跳过嵌套注释、处理转义和 `#"x"` 字符字面量），把所有违规位置和行号列出来，并检查注释是否配平：

```bash
python3 check-literals.py examples/*.sml
# 字面量检查通过：22 个文件里没有非 ASCII 字符串
```

`run-all.sh` 与 `build.ps1` 都会在编译前跑它，几毫秒就能定位，比等 Poly/ML 报 `unprintable character` 省事得多。

## 三通道输出比对

最后会拿三条通道的 stdout 逐字节比对。绝大多数示例完全一致；下面这两个**按设计**不一致，脚本只打印原因、不计入告警（见 `diff_reason()` / `Get-DiffReason()`）：

| 示例 | 不一致的原因 |
|---|---|
| `02-types` | MLton 默认的 `int` 是 32 位，SML/NJ 与 Poly/ML 是 63 位 |
| `18-numeric` | 第 10 节**刻意**打印实数格式化的分叉点：`Real.toString`/`GEN` 对整值实数、`FIX 0` 的 .5 进位、`FIX 17` 的末位 |

`18-numeric` 那一节是故意留的：它同时也是在证明「差异检测本身是有效的」。其余示例若出现输出差异，脚本会报 `[DIFF]` 并要求人工确认。

## 各章索引

| 章 | 主题 | 关键内容 |
|---|---|---|
| 1 | 认识 Standard ML | SML'97 的定位、三套实现的分工、为什么必须多通道验证 |
| 2 | 工具链与三种运行方式 | `sml` / `poly` / `mlton` 各自的调用方式、静音堆、`</dev/null` 的必要性、MLton 的 ld 警告 |
| 3 | 程序结构与求值 | `val`/`fun`/`val _ =`、类型推断、类型标注、嵌套注释、求值顺序（示例 01） |
| 4 | 类型系统 | `int`/`real`/`bool`/`char`/`string`/`unit`/`word`、相等类型、`type` 别名、类型推断的边界（示例 02） |
| 5 | 表达式与运算符 | 优先级、`~` 取负、`div`/`mod` 与 `Int.quot`/`Int.rem`、`andalso`/`orelse`、`if` 是表达式（示例 03） |
| 6 | 元组与记录 | 元组即记录、`#n`/`#label` 选择子、解构、记录相等性、嵌套（示例 04） |
| 7 | 模式匹配 | 通配、字面量、构造子、列表、`as`、嵌套、`val`/`fn` 模式、记录模式与 `...`、穷尽性警告（示例 05） |
| 8 | 列表与高阶列表函数 | `::` 与 `@`、`map`/`filter`、`foldl` 与 `foldr` 的区别、`tabulate`、`partition`、`ListPair`（示例 06） |
| 9 | 代数数据类型 | `datatype`、参数化构造子、递归类型（BST、表达式树）、`withtype`、互递归、构造子即函数（示例 07） |
| 10 | 字符串与字符 | `sub`/`substring`/`concat`、`explode`/`implode`、`tokens` **vs** `fields`、手写可移植 `indexOf`、`\ddd` 转义（示例 08） |
| 11 | 递归与尾递归 | 尾递归与累积器、`foldl` 的等价改写、互递归 `and`、Ackermann、汉诺塔、`while`+`ref`（示例 09） |
| 12 | 异常 | 自定义异常、参数化异常、多分支 `handle`、重抛与日志、`exnName` vs `exnMessage`、异常 vs `option`（示例 10） |
| 13 | 高阶函数与闭包 | 柯里化与偏应用、闭包与独立计数器、`o` 与 `op`、函数放进列表（示例 11） |
| 14 | 结构与签名 | `structure`/`signature`、透明约束 `:`、`open`/`local`、`where type`、一个签名两套实现（示例 12） |
| 15 | functor | 匿名/具名签名参数、spec 形式多参数、`sharing type`、结果签名、不透明产出、柯里化 functor 只有 SML/NJ 认（示例 13） |
| 16 | 不透明约束与抽象数据类型 | `:>` 与不变量保护、隐藏内部辅助函数、`eqtype` 与相等性丢失、多态抽象类型、functor + `:>`（示例 14） |
| 17 | 模块的组装：open / local / include | `open` 的遮蔽顺序、`open` 嵌套路径、顶层 `local`、`include` 在签名里做继承、`include` **不能**用在 structure 里（示例 15） |
| 18 | 可变状态：ref / Array / Vector | `ref`/`!`/`:=`、`while`、`;` 顺序、**`ref`/`array` 的 `=` 比物理地址**、`Array`/`Vector` 全套、越界与 `Subscript`、闭包封状态（示例 16） |
| 19 | 排序与经典算法 | 插入/归并/快速排序互相校验、二分 vs 线性查找的步数、埃氏筛、`gcd`/`lcm`、汉诺塔计数、记忆化斐波那契、有序表去重与交集（示例 17） |
| 20 | 数值计算 | 二分法与牛顿法求根、梯形与辛普森积分、克拉默法则解方程组、拉格朗日插值、浮点三大坑、实数格式化的实现差异（示例 18） |
| 21 | 解析：词法分析与递归下降 | 手写词法器（`datatype token` + 扫描器）、递归下降求值器、错误的捕获与报告、`substring` 定位、词频统计、回文（示例 19） |
| 22 | 输入输出与文件 | `print` vs `TextIO.output`、读写/追加、逐行读与 `inputLine` 的换行符、`Int.fmt` 进制、`padLeft`/`padRight`、目录遍历、环境变量、清理（示例 20） |
| 23 | 测试与断言 | 记录+闭包写断言器、`checkInt`/`checkList`/`checkTrue`/`checkRaises`、异常断言用 `exnName`、固定输入的属性测试、失败长什么样（示例 21） |
| 24 | 综合实战：成绩 CSV 分析与报告 | CSV 生成与读回、缺失值掩码、坏行异常、逐科统计、Top-N 排名与并列规则、最小二乘拟合、报告写回后逐行校验、临时文件清理（示例 22） |
| 25 | 坑清单 | 语法层、类型推断、值限制、相等性、字符串字面量、模块系统、I/O、验证脚本共 38 条坑，每条给「现象 → 原因 → 修法」 |
| 26 | 三实现差异清单与可移植写法 | 三通道搭建、17 条实测差异逐条拆解、三家一致的部分、30 条可移植写法手册、静音堆与结束标记两个脚本设计 |

## SML/NJ、Poly/ML、MLton 的差异清单

这些是写示例时一个个撞出来的，**不是猜测**。碰到「同一份代码一边过一边不过」，先来这里对一下。

| # | 差异 | SML/NJ 110.99.9 | Poly/ML 5.9.2 | MLton 20241230 |
|---|---|---|---|---|
| 1 | 默认 `int` 位宽 | 63 位 | 63 位 | **32 位**（要 64 位得显式用 `Int64`） |
| 2 | 字符串里的原始 UTF-8 | 接受 | **拒绝**（`unprintable character \231 found in string`） | **拒绝**（可用 `-default-ann` 打开） |
| 3 | `Real.toString 1.0` | `1` | `1.0` | `1` |
| 4 | `Real.fmt (GEN (SOME 6)) 1.0` | `1` | `1.0` | `1` |
| 5 | `Real.fmt (FIX (SOME 0)) 3.5` | `3` | `4` | `4` |
| 6 | `Real.fmt (FIX (SOME 17)) 0.3` | `0.30000000000000000` | `0.29999999999999999` | `0.29999999999999999` |
| 7 | `General.exnMessage Div` | `divide by zero` | `Div` | — |
| 8 | `String.index` | 有 | 有 | **没有**（Basis 不强制要求） |
| 9 | `Int64` 结构 | 有 | `--script` 下**没有** | 有 |
| 10 | `OS.FileSys.fileSize` 返回类型 | `Int64.int` | `Position.int` | `Position.int` |
| 11 | `OS.Process.status` | 恰好实现成 `int` | 抽象类型 | 抽象类型 |
| 12 | 柯里化 functor `functor F (A:S1) (B:S2)` | 接受 | 语法错 | 语法错 |
| 13 | 无约束重载运算符的解析 | 默认 `int` | 用签名期望类型反推 | 默认 `int` |
| 14 | 编译警告的去向 | stdout | stdout | **stderr** |
| 15 | `Warning: calling polyEqual` | 会有 | 没有 | 没有 |
| 16 | 出错时的退出码 | 直接跑是 1；经静音堆变 0 | 实测有时仍是 0 | 1 |
| 17 | SML/NJ 的标准外扩展（`Option.isNone`、`List.foldli`） | **有** | 没有 | 没有 |

第 1 条的实测影响：`02-types` 会打印 `Int.maxInt`，三家给出的上限不同；写代码时**不要假设 `int` 是 64 位**，`fact 12` 安全、`fact 20` 在 MLton 上溢出。

第 2、16 两条是最费时间的坑：前者让「明明同一份源码」只有两条通道挂掉，后者让「退出码」这个最直观的判据彻底失效 —— 这就是本目录坚持用**结束标记**做主要判据的原因。

### 三套实现一致的地方（可以放心用）

这些也都实测过，值不值得信任不必猜：

- `exnName` 给出的构造子名（`Div` / `Subscript` / `Empty` / `Fail` …）三家完全一致；`exnMessage` 的**文本**不一致。
- `Real.fmt` 用 `FIX`/`GEN` 且位数在 **1..16** 之间时一致；`SCI` 一致。
- `Int.fmt` 的 `HEX` / `BIN` / `OCT`、`StringCvt.padLeft` / `padRight` 一致。
- `String.tokens` / `String.fields` / `Int.fromString` / `Real.fromString`（含它们对空串、前缀、前导空白的处理）一致。
- `ref` / `array` 的 `=` 比**物理地址**，`vector` / `list` 的 `=` 比**内容** —— 三家都是这个语义。
- `include` 不能出现在 `structure` 里 —— 三家一致拒绝（它只是 spec 层构造）。
- 未约束的记录字段（flex record）在 SML/NJ 上更严格，但**只要把记录类型写清楚**，三家行为一致。
- 不动点运算：同一份 IEEE 754 双精度算术，三家逐位相同。所以只要避开格式化差异，数值示例也能逐字节比对（`22-project` 的线性拟合就是这么过的）。

## SML 本身容易踩的坑

跟编译器无关、纯粹是语言层面的坑，值得先看一眼（详见《StandardML编程指南》第 25 章）：

- **注释可以嵌套，必须配平**。`(* a (* b *) *)` 是合法的；漏一个 `*)` 会让后面整段代码被当成注释，报错位置离真正的问题很远。
- **声明在「顶格的新行」处结束**。`handle`、`|` 这类续行千万不要顶格写；顶格会被当成本层的下一个声明，报出 `syntax error: inserting LET` 这种莫名其妙的错。
- **`quot` / `rem` 不是关键字**，必须写 `Int.quot` / `Int.rem`。而 `div` / `mod` 是。
- **`o` 是组合运算符（infix）**，不能当变量名：`val o = ...` 报 `expression or pattern begins with infix identifier "o"`。这个坑在写示例 20（`examples/20-io.sml`，指南第 22 章）时又踩了一次。
- **记录模式默认是精确匹配**，少写字段就不匹配；要允许多余字段必须写 `...`。而**漏写 `...` 又用了不完整字段集**会变成「不收敛的 flex record」，SML/NJ 直接拒绝。
- **`fun f (C : COUNTER)` 不合法**。签名不是类型，不能做参数标注；要「接收一个 structure 的函数」，唯一写法是 `functor`。
- **`type` 别名不是约束**。`type t = {...}` 声明完之后 `fun f () = {...}` 的推断类型仍然是独立的，字段里可能留着自由类型变量，用的时候才炸。返回值要老老实实标注。
- **重载运算符 + 抽象类型 + 签名约束这三样凑一起，必须显式标注类型**。`fun add (a, b) = a + b` 配 `type num = real`，Poly/ML 能过，SML/NJ 和 MLton 会把它默认成 `int` 然后在签名匹配时报错。
- **`real` 不是相等类型**。`0.1 + 0.2 = 0.3` 根本不编译，要用 `Real.==` 或 `Real.compare`。
- **`ref` 和 `array` 的 `=` 比的是「是不是同一格」**。`ref 1 = ref 1` 是 `false`，想比内容得写 `!r1 = !r2`。
- **抽象类型默认丢掉相等性**。签名里写 `type t` 之后 `=` 就用不了；要保留得写 `eqtype t`，或者自己导出比较函数。抽象类型的 `option` 同样不能 `=`。
- **`Int.fromString` 接受前缀**：`Int.fromString "42abc"` 是 `SOME 42`，不是 `NONE`。它会跳过前导空白。
- **`String.tokens` 吞掉空字段，`String.fields` 保留**。解析 CSV 必须用 `fields`，否则 `"a,,c"` 会从 3 个字段变成 2 个。
- **`TextIO.inputLine` 保留行尾的 `\n`**，直接拼接会多出空行，要自己 chomp。
- **用 `String.fields` 按 `\n` 切行时，末尾那个换行会多产生一个空串**，得滤掉。
- **`fn x => e1; e2` 是错的**，顺序执行必须写成 `fn x => (e1; e2)`；不然分号被当成声明层语法。
- **`handle` 的体必须和表达式同类型**；`(1 div 0) handle Div => ~1` 这类还要给 handler 标数值类型。
- **局部 `exception Div` 会遮蔽 `General.Div`**，内层 `handle Div` 就再也接不到除零异常了。
- **`Int.maxInt` / `Int.precision` 是 `int option`**，要 `valOf`。
- **非穷尽匹配只是警告，不是错误**（`Matches are not exhaustive`）—— 但本目录的判定把它当失败，所以每个 `case` 都要写全。
- **别用 `o` 当变量名**；别用 `val_` 之外的保留字当标识符（`val` 是关键字，`val_` 不是）。
- **`Array.copy` 收的是记录**：`Array.copy {src, dst, di}`，不是 `Array.copy dst`。而 `Array.modify` 才是「函数 + 数组」。

## 当前状态

22 个示例 × 3 条通道 = **66 项全部通过**，0 项意外输出差异。两个平台都实测过，结果一致：

- **macOS** 12.7 x86_64：SML/NJ 110.99.9（MacPorts）/ Poly/ML 5.9.2（MacPorts）/ MLton 20241230（官方二进制）。
- **Linux**（Arch，WSL2 x86_64，内核 6.18）：SML/NJ 110.99.9 / Poly/ML 5.9.2 / MLton 20241230（均为发行版包）。首次运行会自动修复 Arch `smlnj` 包的 `exportML` 打包 bug（见指南坑 38）。

`run-all.sh`（22/22，失败 0，输出差异 0，退出码 0）与 `build.ps1`（22/22，失败 0，退出码 0）均已实测，两种入口结果一致：20 个示例报 `[same]`，2 个报 `[diff] 已知差异`。

教程正文 `StandardML编程指南.md` 共 26 章（约 7000 行）：第 1–24 章对应本书的 22 个示例逐章讲解，第 25 章是 38 条坑的清单（每条给「现象 → 原因 → 修法」），第 26 章是三实现差异清单与 30 条可移植写法手册。
