# 14 · 结构化编程与文本复用

> 示例：[`examples/14_structured/`](../examples/14_structured/)（主程序 + 一个 copybook）
> 运行：`./run-all.sh 14`

COBOL 常被误解成"只能 `GO TO` 面条式"的老语言。其实标准 COBOL 85 起就有完整的结构化
设施，GnuCOBOL 还支持**文本级复用**（`COPY`/`REPLACE`）和**编译期预处理**（`>>IF` 等）。
本章把这三块讲清：怎么把大程序拆成清晰的 `SECTION`、怎么用 copybook 复用记录布局、
怎么用预处理做条件编译。

## 1. 结构化编程：SECTION 分层 + PERFORM 调度

`PROCEDURE DIVISION` 可以分成多个 `SECTION`（段），每个段有名字、可被 `PERFORM` 调用。
结构化的核心思想是：**主段只做调度，具体活儿拆进各子段**，像别的语言的函数分层。

```cobol
       PROCEDURE DIVISION.
       MAIN-SECTION SECTION.
           PERFORM INIT-RECORDS.       * 主段只负责"按顺序调子段"
           PERFORM ACCUMULATE.
           PERFORM SHOW-REPORT.
           PERFORM CHECKS.
           DISPLAY "==== 14 结束 ====".
           STOP RUN RETURNING WS-FAILS.
       INIT-RECORDS SECTION.
           ...                         * 初始化
       ACCUMULATE SECTION.
           PERFORM ADD-ONE VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 3.
       ADD-ONE SECTION.
           COMPUTE WS-TOTAL = WS-TOTAL + WS-I * 1000.
           ADD 1 TO WS-CNT.
```

`SECTION` vs `PARAGRAPH`（第 7 章讲过）：

- **`SECTION`**：有层次，可被 `PERFORM` 调用后自动返回（隐式 `EXIT SECTION`），
  适合结构化分层。段内可含多个 paragraph。
- **`PARAGRAPH`**：无层次，`PERFORM 段名` 执行到下一个段名/paragraph 名为止。

> **坑（实测）：`REPORT` 是 GnuCOBOL 的保留字**（Report Writer 的 `REPORT SECTION`）。
> 我最初把汇总段命名为 `REPORT SECTION.`，编译器报
> `PERFORM statement not terminated by END-PERFORM` + `syntax error, unexpected REPORT`——
> 错误信息还指向上面的 `PERFORM`，很有迷惑性。改名 `SHOW-REPORT SECTION.` 即通过。
> **给段/paragraph 起名避开 COBOL 保留词**（`REPORT`、`FILE`、`SORT`、`INPUT`、`DATA` 等），
> 撞上时错误信息往往"指错地方"。

## 2. COPY：文本级包含 copybook

`COPY` 把一个外部文件（copybook，惯例扩展名 `.cpy`）的内容**原样文本插入**到当前位置。
最典型的用途是复用记录布局——多个程序共享同一份 `FD`/`01` 定义，改一处即改所有引用处。

copybook（`examples/14_structured/EMPREC.cpy`）：

```cobol
      *  EMPREC.cpy — 可复用的员工记录布局
       01 CP-EMP.
           05 CP-ID       PIC 9(4).
           05 CP-NAME     PIC X(10).
           05 CP-SALARY   PIC 9(6).
```

主程序里引入：

```cobol
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FAILS        PIC 9(2) VALUE 0.
       COPY EMPREC.                      * ← CP-EMP 布局在这里展开
       01 WS-TOTAL        PIC 9(8) VALUE 0.
```

之后 `CP-ID`/`CP-NAME`/`CP-SALARY` 就像本地声明的一样可用。

> **坑（实测）：`cobc` 默认【不】搜源文件所在目录找 copybook。** `COPY` 只在**当前工作
> 目录**和 `-I` 指定的路径里找。我在 `/tmp` 下编译 `samedir/main.cob`（copybook 在同目录），
> `COPY REC.` 报 `REC: No such file or directory`；加 `-I samedir` 才通过。
>
> **本仓库验证脚本给每个示例的编译命令加了 `-I <示例目录>`**，所以 copybook 与源码放同一
> 目录即可被找到。你自己在命令行编译带 copybook 的程序时，记得 `-I` 指向 copybook 目录，
> 或设 `COBCOPY` 环境变量。

`COPY ... REPLACING` 还能在包含时替换文本（下节的 `REPLACE` 是它的独立版）：

```cobol
       COPY EMPREC REPLACING ==CP-== BY ==WS-==.   * 包含时把前缀 CP- 换成 WS-
```

## 3. REPLACE：全局记号替换

`REPLACE` 是一条编译期指令，把源码里出现的**记号**统一替换成另一段文本。适合做"占位符"，
让同一份源码在不同上下文里指向不同数据项：

```cobol
       WORKING-STORAGE SECTION.
       01 WS-LOG          PIC X(24) VALUE SPACES.
       REPLACE ==:LOG:== BY ==WS-LOG==.    * 之后源码里的 :LOG: 都替换成 WS-LOG
       PROCEDURE DIVISION.
       SHOW-REPORT SECTION.
           STRING "cnt=" WS-CNT " total=" WS-TOTAL
               DELIMITED BY SIZE INTO :LOG:.   * ← :LOG: 被替换成 WS-LOG
           DISPLAY "报表日志: [" :LOG: "]".     * ← 这里也是
```

`REPLACE` 的语法是 `REPLACE ==原文本== BY ==新文本==.`，`==...==` 是伪文本定界符。
它和 `COPY ... REPLACING` 机制相同，只是 `REPLACE` 作用于**当前源文件后续所有行**，
`COPY ... REPLACING` 只作用于**被包含的那份 copybook**。

## 4. 预处理器：编译期条件与符号

GnuCOBOL 有一套以 `>>` 开头的**预处理指令**（占据整行，第 7 列之后），在**编译期**求值，
决定哪些源码行进编译器。这是 COBOL 的"宏/条件编译"层：

| 指令 | 作用 |
|---|---|
| `>>DEFINE 名 值` | 定义一个编译期符号 |
| `>>SET 名 值` | 给已定义符号赋值 |
| `>>IF 表达式` | 条件为真才编入后续行 |
| `>>ELSE` / `>>END-IF` | 条件分支的else / 收口 |
| `>>IFDEF 名` / `>>IFNDEF 名` | 符号已定义 / 未定义时编入 |
| `>>SOURCE 文件` | 包含另一源文件（类似 COPY） |
| `>>CALL 子程序` | 调用外部预处理器子程序 |

条件编译示例：

```cobol
      >>DEFINE SHOWDETAIL 1
       ...
       SHOW-REPORT SECTION.
      >>IF SHOWDETAIL EQUAL 1
           DISPLAY "明细分支已编入（SHOWDETAIL=1）".
      >>ELSE
           DISPLAY "精简分支已编入（SHOWDETAIL 未设）".
      >>END-IF
```

判断符号是否定义用 `>>IF 名 DEFINED` / `>>IF 名 NOT DEFINED`：

```cobol
      >>DEFINE USEDEBUG 1
      >>IF USEDEBUG DEFINED
           DISPLAY "USEDEBUG is defined -> debug build".
      >>ELSE
           DISPLAY "USEDEBUG not defined -> release build".
      >>END-IF
```

实测（`>>DEFINE USEDEBUG 1` 后走 DEFINED 分支；未定义的 `NOPE` 走 NOT DEFINED 分支）：

```text
USEDEBUG is defined -> debug build
NOPE is not defined (as expected)
```

> **坑（实测）：`>>IF` 是【编译期】的，与运行期 `IF` 完全不同。** 未选中的分支**根本不会
> 进可执行文件**，运行期无从"打印"它。改 `>>DEFINE` 的值必须**重新编译**才生效——它不是
> 运行时开关。想表达"运行时可切换的调试标志"，用普通数据项 + 运行期 `IF`；想表达"这份
> 构建要不要编入某模块"，才用 `>>IF`。
>
> 另一个语法坑：判断符号定义要写 `>>IF 名 DEFINED`，**不是** `>>IF DEFINED(名)`——
> 后者报 `syntax error, unexpected DEFINED`。GnuCOBOL 的预处理语法自成一套，别套 C 的
> `#ifdef` 写法。

本仓库验证脚本不开任何 `>>DEFINE`，示例里 `SHOWDETAIL` 由源码自己 `>>DEFINE` 成 1，
所以 check/release 两通道都编入"明细分支"，输出一致。

## 5. 实测输出

`./run-all.sh 14 -v`，check/release 两通道逐字节一致：

```text
CP 记录: id=0001 名=[ANN       ] 薪=004000
报表日志: [cnt=03 total=00006000   ]
明细分支已编入（SHOWDETAIL=1）
==== 14 结束 ====
```

- `CP 记录` 一行证明 **COPY 进来的 copybook 字段生效**（`CP-ID`/`CP-NAME`/`CP-SALARY` 可用）。
- `报表日志` 一行证明 **REPLACE 记号 `:LOG:` 被替换成 `WS-LOG`** 并正确 `STRING` 填充。
- `明细分支已编入` 证明 **`>>IF SHOWDETAIL EQUAL 1` 在编译期选中了该分支**。

## 6. 结构化 vs 文本复用：三个机制的分工

| 机制 | 层次 | 时机 | 用途 |
|---|---|---|---|
| `SECTION` + `PERFORM` | 逻辑结构 | 运行期 | 把程序拆成可调用的逻辑单元 |
| `COPY` / `REPLACE` | 文本复用 | 编译期（文本插入/替换） | 复用记录布局、统一改名 |
| `>>IF` / `>>DEFINE` | 条件编译 | 编译期（选行） | 按构建配置编入不同代码 |

三者常配合：用 `COPY` 引入共享布局，用 `>>IF` 按目标平台/构建类型选分支，
用 `SECTION`+`PERFORM` 组织运行期逻辑。

## 7. 坑位清单（实测）

1. **`REPORT`（及 `FILE`/`SORT`/`INPUT`/`DATA` 等）是保留字**，别拿来当段名/paragraph 名；
   撞上时错误信息常"指错行"（报在上方的 `PERFORM`）。
2. **`cobc` 默认不搜源文件目录找 copybook**：`COPY` 只认 cwd 与 `-I` 路径。命令行编译带
   copybook 的程序要 `-I <copybook目录>` 或设 `COBCOPY`；本仓库脚本已对每个示例加 `-I`。
3. **`>>IF` 是编译期的**：未选中分支不进可执行文件，改 `>>DEFINE` 要重编；别当运行时开关用。
4. **判断符号定义写 `>>IF 名 DEFINED`**，不是 `>>IF DEFINED(名)`（后者语法错）。
5. **`REPLACE ==a== BY ==b==.` 作用于当前文件后续所有行**；只想替换某份 copybook 内的文本
   用 `COPY ... REPLACING`。
6. **`COPY` 是纯文本插入**：copybook 里的 `01`/`05` 层级、缩进必须与插入点上下文吻合，
   否则数据布局错乱——copybook 不检查"你把它插哪儿了"。

---
上一章：[13 状态码、异常与调试](13-status-debug.md) ｜ 下一章：[15 终端界面：SCREEN SECTION](15-screen.md) ｜ 返回：[README](../README.md)
