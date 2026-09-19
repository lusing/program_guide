# 02 · 第一个程序与四大部

> 示例：[`examples/02_hello/02_hello.cob`](../examples/02_hello/02_hello.cob)
> 运行：`./run-all.sh 02`（或 `cobc -x 02_hello.cob && ./02_hello`）

## 1. 从命令行开始：不装 IDE 也能学会 COBOL

COBOL 没有"官方 IDE"，学语言阶段最好就用命令行——一条 `cobc` 完成编译链接：

```bash
cd examples/02_hello
cobc -x 02_hello.cob      # -x：产出独立可执行文件 02_hello
./02_hello                # 运行
```

本教程的 `run-all.sh 02` 做的是严格版：同一份源码编两遍（check `-Wall` / release `-O2`），
各跑一次，比对 stdout 逐字节一致，并要求 stderr 为空、退出码为 0、输出含结束标记。

## 2. 程序骨架：四大部（DIVISION）

一个 COBOL 程序由**四个部**按固定顺序组成，每个部再分节（SECTION）：

```text
IDENTIFICATION DIVISION.   身份部：程序名等元信息（必须）
ENVIRONMENT DIVISION.      环境部：文件、设备配置（用到文件才需要）
DATA DIVISION.             数据部：所有数据项声明（用到变量才需要）
PROCEDURE DIVISION.        过程部：可执行语句（必须）
```

> 只有 IDENTIFICATION 和 PROCEDURE 是必需的。最小程序可以只有这两个部。

我们的示例（节选骨架）：

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. HELLO.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FAILS     PIC 9(2) VALUE 0.
       01 WS-SUM       PIC 9(3).
       01 WS-NAME      PIC X(10) VALUE "世界".
       PROCEDURE DIVISION.
       MAIN-SECTION.
           DISPLAY "你好，GNU COBOL！".
           COMPUTE WS-SUM = 1 + 2.
           DISPLAY "1 + 2 = " WS-SUM.
           STOP RUN RETURNING WS-FAILS.
```

四条铁律：

1. **每个部/节/语句以句点 `.` 结尾**：`IDENTIFICATION DIVISION.`、`PROGRAM-ID. HELLO.`、
   每条过程语句后都有 `.`。句点是 COBOL 的语句终结符——**漏句点是最常见的编译错误**。
2. **部名是固定的四个**，且必须按 IDENTIFICATION → ENVIRONMENT → DATA → PROCEDURE 顺序。
3. **先声明后使用**：数据项必须在 DATA DIVISION 声明，过程部才能引用。
4. **PROGRAM-ID 名是程序/模块名**，与文件名无关；`cobcrun` 按它找模块。

## 3. 固定格式的列位：A 区与 B 区（本章最重要的"考古"知识）

COBOL 源码沿用 80 列打孔卡片的列位约定（详见第 01 章图）。落到键盘上，记住三个缩进量：

| 写在第几列 | 缩进几个空格 | 放什么 |
|---|---|---|
| **A 区**（第 8 列起） | **7 个空格** | DIVISION/SECTION 头、`PROGRAM-ID.`、段名、`01`/`77` 层数据项 |
| **B 区**（第 12 列起） | **11 个空格** | 过程语句、`05` 等从属层数据项 |
| 第 7 列 | 6 空格 + 指示符 | `*` 或 `/` = 整行注释；`-` = 续行 |

本教程统一用"7 空格写 A 区、11 空格写 B 区、数据从属层用 10 空格"的方案。注释行用
第 7 列的 `*`：

```cobol
      *  这是一整行注释（第 7 列是星号）
       IDENTIFICATION DIVISION.        *> A 区：7 空格
       PROGRAM-ID. HELLO.              *> A 区
       PROCEDURE DIVISION.             *> A 区
           DISPLAY "缩进 11 空格".      *> B 区：11 空格
```

> **实测坑：固定格式按【字节】数列，不是字符。** 一行里有中文时，UTF-8 每字占 3 字节，
> 很容易在第 72 列前就"超字节"，编译器报：
>
> ```text
> error: continuation character expected
> ```
>
> 实测：一行 `DISPLAY "` + 20 个"中" + `".`，字符数 42，**字节数 82** > 72，直接报错。
> 对策：含中文的行写短一点（一行 DISPLAY 的中文别超过约 16 个字），或用第 7 列 `-` 续行。

## 4. DISPLAY 与 ACCEPT：COBOL 的输入输出

```cobol
           DISPLAY "你好，GNU COBOL！".      *> 输出，末尾自动换行
           DISPLAY "A" "B" WS-SUM.           *> 多个操作数：逐个转字符串后拼接，无分隔
           DISPLAY "结果=" WS-SUM "元".       *> 字面量与数据项混排
           ACCEPT WS-NAME.                   *> 从标准输入读一行到 WS-NAME（定长会截断/补空格）
```

- `DISPLAY` 把每个操作数转成字符串后**直接拼接**（无空格分隔），末尾换行。
- `DISPLAY ... UPON SYSERR` 输出到 stderr；`DISPLAY ... WITH NO ADVANCING` 不换行。
- `ACCEPT` 读一行；目标是定长 `PIC X(n)`，超长截断、不足补空格。
- **坑（实测）**：`DISPLAY` **不求值算术表达式**。`DISPLAY "1+2=" 1 + 2` 是语法错误
  （`error: syntax error, unexpected +`）。算术必须先 `COMPUTE` 进数据项：

  ```cobol
      *  错：DISPLAY 1 + 2.
           COMPUTE WS-SUM = 1 + 2.
           DISPLAY "1 + 2 = " WS-SUM.       *> 对
  ```

## 5. 两种注释

```cobol
      *  整行注释：第 7 列放星号（或斜杠 /）
           DISPLAY "行尾注释用 *>".          *> 这是行内注释，*> 之后到行尾被忽略
```

- **整行注释**：第 7 列是 `*` 或 `/`，整行被忽略。
- **行内注释**：`*>` 之后到行尾被忽略（自由格式里也可写在行首）。

## 6. STOP RUN 与退出码

```cobol
           STOP RUN.                   *> 正常结束程序
           STOP RUN RETURNING WS-FAILS. *> 结束并把整数当进程退出码
```

`STOP RUN RETURNING <整数>` 是本教程的断言基础：`WS-FAILS` 累计失败条数，非 0 时进程
非 0 退出，验证脚本据此判失败。（等价写法 `GOBACK RETURNING n`。）

## 7. 实测输出（本机 GnuCOBOL 3.2.0）

`./run-all.sh 02` 中 check 通道的真实 stdout：

```text
你好，GNU COBOL！
1 + 2 = 003
[世界    ]
你好，世界
==== 02 结束 ====
```

逐行解释：

| 输出 | 为什么长这样 |
|---|---|
| `1 + 2 = 003` | `WS-SUM` 是 `PIC 9(3)`，3 位无符号数值**左补零**显示成 `003`（第 03/04 章细讲编辑） |
| `[世界    ]` | `WS-NAME` 是 `PIC X(10)`，**按字节定长**：`世界` 占 6 个 UTF-8 字节，补 4 个空格凑满 10 字节 |
| `你好，世界` 后面一串空格 | `STRING ... DELIMITED BY SIZE` 把 `WS-NAME`（X(10)，含 4 个尾随空格）**整段 10 字节**拼了进去——`BY SIZE` 取满定长，不去尾空格 |

> `DELIMITED BY SIZE` 的"取满定长"是新手大坑：拼接定长 `PIC X` 时会把补位空格也带上。
> 想只取有效内容用 `DELIMITED BY SPACE`，或先 `FUNCTION TRIM(...)`（第 05 章详述）。

## 8. 编译与验证

```bash
# 单个示例（双通道 + 逐字节比对 + 四条判定）
./run-all.sh 02

# 手工等价
cd examples/02_hello
cobc -x -Wall -std=default 02_hello.cob && ./02_hello   # check
cobc -x -O2 02_hello.cob && ./02_hello                  # release
```

## 9. 坑位清单（实测）

1. **漏句点**：部名、PROGRAM-ID、每条语句后都要 `.`——COBOL 最常见编译错误。
2. **列位错位**：DIVISION 头必须在 A 区（第 8 列），过程语句在 B 区（第 12 列）；写错区会
   报奇怪的语法错误。
3. **固定格式按字节数列**：中文行超第 72 列 → `continuation character expected`（见 §3）。
4. **`DISPLAY` 不求值算术**：`DISPLAY 1 + 2` 语法错误；先 `COMPUTE`。
5. **`PIC X(n)` 按字节定长**：`世界` 在 `X(10)` 里占 6 字节 + 4 空格；`FUNCTION LENGTH` 返回 10（字节，非字符）。
6. **`STRING ... DELIMITED BY SIZE`** 会把定长项的尾随空格一并拼进去（见 §7）。
7. **`PIC 9(n)` 左补零**：`1+2` 显示成 `003`，不是 `3`。

---
上一章：[01 全景与工具链](01-overview.md) ｜ 下一章：[03 数据部与 PICTURE](03-data-pic.md) ｜ 返回：[README](../README.md)
