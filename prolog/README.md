# Prolog 教程与示例

逻辑编程入门到进阶，配套 20 个可运行示例。**每个示例都在两套引擎上分别验证**：SWI-Prolog 与 GNU Prolog（含 GNU 编译成本地可执行文件的通道）。

## 目录结构

```
prolog/
├── README.md                 本文件
├── Prolog编程指南.md          教程正文（24 章）
├── build.ps1                 PowerShell 构建/验证入口（三条通道）
├── run-all.sh                等价的 shell 版验证脚本
└── examples/
    ├── 01-hello-facts.pl             事实、规则与查询
    ├── 02-terms-unification.pl       项与合一
    ├── 03-backtracking.pl            回溯与搜索树
    ├── 04-arithmetic.pl              算术与比较
    ├── 05-lists.pl                   列表
    ├── 06-higher-order.pl            高阶谓词与元调用
    ├── 07-recursion-accumulators.pl  递归、累加器与尾调用
    ├── 08-cut-negation.pl            剪枝（!）、条件与「否定即失败」
    ├── 09-dcg-grammar.pl             定子句文法（DCG）
    ├── 10-dcg-parser.pl              用 DCG 写解析器：算术表达式计算器
    ├── 11-database.pl                动态数据库（运行时改程序本身）
    ├── 12-metaprogramming.pl         元编程：把程序当数据
    ├── 13-all-solutions.pl           收集全部解：findall / bagof / setof
    ├── 14-io-files.pl                输入输出与文件
    ├── 15-atoms-strings.pl           原子、字符码与「字符串」
    ├── 16-exceptions.pl              异常、清理与防御式编程
    ├── 17-constraints.pl             约束求解（CLP(FD) / GNU FD）
    ├── 18-modules.pl                 代码组织、命名空间与条件编译
    ├── 19-testing.pl                 测试、断言与基准
    └── 20-portability.pl             双引擎差异、可移植封装与综合实战
```

## 工具链

| 工具 | 路径 | 版本 | 用途 |
|---|---|---|---|
| `swipl` | `/opt/local/bin/swipl` | SWI-Prolog 10.0.2 | 解释执行，库最全，开发首选 |
| `gprolog` | `/opt/local/bin/gprolog` | GNU Prolog 1.5.0 | 解释执行，内置 FD 约束求解器 |
| `gplc` | `/opt/local/bin/gplc` | 随 GNU Prolog | 编译成无依赖的本地可执行文件 |
| `pwsh` | `/opt/local/bin/pwsh` | PowerShell 7.6.5 | 跑 `build.ps1`（不在默认 PATH 里） |

> **Windows 说明**：上表路径是 macOS（MacPorts）环境。Windows 下
> `scoop install swipl` 装 SWI-Prolog 即可（本仓库在 10.0.2 x64-win64 上验证
> 通过）；GNU Prolog **没有官方 Windows 构建**，gprolog / gplc 两条通道不适用，
> 脚本会自动跳过。swipl 通道需要 `-Dencoding=utf8` 加
> `set_stream(user_output, encoding(utf8))` 规避 ANSI 代码页问题（否则 UTF-8
> 中文示例会报 `Illegal multibyte Sequence`），`build.ps1` / `run-all.sh`
> 均已内置，无需感知。

验证安装：

```bash
swipl --version
gprolog --version
```

## 构建与验证

三条通道，每个示例都跑一遍：

| 通道 | 命令 | 说明 |
|---|---|---|
| swipl | `swipl -q -f FILE -g main -t halt` | SWI 解释执行 |
| gprolog | `gprolog --consult-file FILE --entry-goal main` | GNU 解释执行 |
| gplc | 拼一份到 `build/` 后 `gplc X.pl -o X.bin` 再运行 | 编成本地可执行文件 |

PowerShell：

```powershell
cd /Users/xulun/code/programming/prolog
pwsh ./build.ps1 -All                 # 跑全部（20 个 × 3 通道）
pwsh ./build.ps1 -File 04-arithmetic.pl
pwsh ./build.ps1 -All -Verbose        # 附带打印 SWI 输出
pwsh ./build.ps1 -Clean               # 清理 build 目录
```

macOS / Linux / Windows Git Bash（等价的 shell 脚本）：

```bash
cd /Users/xulun/code/programming/prolog
./run-all.sh            # 跑全部，只看结果摘要
./run-all.sh -v         # 跑全部并显示每个例子的完整输出
./run-all.sh 07 15      # 只跑指定编号
```

### 判定标准

三条通道共用同一套判定，全部满足才算通过：

1. **退出码为 0**
2. **stderr 为空**（连警告都不能有）
3. **stdout 里出现结束标记** `==== NN 结束 ====`
   —— 这一条是为了确保程序真跑到了最后一行，而不是中途失败后被 `halt(0)` 掩盖。

失败时 `build.ps1` / `run-all.sh` 返回退出码 1，可以直接拿去做回归。

## 各章索引

| 编号 | 主题 | 关键概念 |
|---|---|---|
| 01 | 事实、规则与查询 | 事实库、规则、变量、findall |
| 02 | 项与合一 | 原子/复合项、`=` vs `==`、发生检查、标准项序 |
| 03 | 回溯与搜索树 | 选择点、合取、递归搜索、generate & test |
| 04 | 算术与比较 | `is` vs `=`、整数除法、累加器阶乘 |
| 05 | 列表 | `[H\|T]`、member/append、跨引擎集合运算 |
| 06 | 高阶谓词与元调用 | `call/N`、`maplist`、`foldl`、`=..` |
| 07 | 递归、累加器与尾调用 | 尾递归、差异列表、互递归、递归的坑 |
| 08 | 剪枝与否定 | `!`、if-then-else、`\+`、绿切 vs 红切 |
| 09 | 定子句文法 | `-->` 语法、语义动作 `{}`、展开原理 |
| 10 | DCG 解析器 | 左递归、AST、运算符优先级、反向生成 |
| 11 | 动态数据库 | `assertz/asserta/retract`、缓存、动态图 |
| 12 | 元编程 | `clause/2`、`call/N`、迷你规则引擎、自解释器 |
| 13 | 收集全部解 | `findall/bagof/setof`、`V^`、`forall`、聚合 |
| 14 | 输入输出与文件 | 读写流、逐字符/逐行、项序列化 |
| 15 | 原子与字符串 | 三种文本表示、互转、`sub_atom/5` |
| 16 | 异常与清理 | `throw/catch`、ISO 错误项、`setup_call_cleanup` |
| 17 | 约束求解 | CLP(FD) vs GNU FD、N 皇后、labeling |
| 18 | 代码组织与条件编译 | 前缀命名空间、`:- if`、`:- public`、派发表 |
| 19 | 测试与基准 | 手写断言框架、性质测试、`statistics/2` |
| 20 | 可移植性与实战 | 特性探测、shim 封装、词频统计、部署 |

## 当前状态

- **macOS**（darwin）：20 个示例 × 3 条通道 = **60 项全部通过**（SWI-Prolog 10.0.2 / GNU Prolog 1.5.0）。
- **Windows 11**：swipl 通道 **20/20 通过**（SWI-Prolog 10.0.2 x64-win64，scoop 安装）。gprolog / gplc 两条通道不适用（GNU Prolog 无官方 Windows 版），脚本自动跳过。`build.ps1`（pwsh 7）与 `run-all.sh`（Git Bash）两种入口均实测，结果一致。

Windows 适配点：swipl 通道加 `-Dencoding=utf8` + `set_stream(user_output, encoding(utf8))` 规避 ANSI 代码页（详见指南第 2 章）；示例 14、16 的 `/tmp` 临时文件在 Windows 下条件编译改走 `%TEMP%`。

`build.ps1` 与 `run-all.sh` 均已在本机实测，两种入口结果一致。
