# 03 · 数据部与 PICTURE 子句 ⭐

> 示例：[`examples/03_data/03_data.cob`](../examples/03_data/03_data.cob)
> 运行：`./run-all.sh 03`

PICTURE（`PIC`）子句是 COBOL 的灵魂：它一次性声明了一个数据项的**类型、长度、符号、
小数位、内部存储方式、显示编辑**。读懂 PIC 就读懂了 COBOL 的数据模型。本章是深水区，
值得慢读。

## 1. DATA DIVISION 的四个节

```text
DATA DIVISION.
   FILE SECTION.            文件的记录布局（用到文件才写，第 11/12 章）
   WORKING-STORAGE SECTION. 程序级静态变量（最常用，全程存在）
   LOCAL-STORAGE SECTION.   每次 CALL 进入时清零的局部存储（子程序用，第 09 章）
   LINKAGE SECTION.         子程序参数区（接收 CALL 传来的数据，第 09 章）
```

本章只讲 `WORKING-STORAGE SECTION.`——它是你声明变量的主战场，类似 C 的全局变量、
但生命周期是整个程序运行。

## 2. 层级号（Level Number）：组项与基本项

COBOL 用**层级号**表达数据的嵌套结构，从 `01` 开始逐级细化：

```cobol
       01 WS-CUSTOMER.              *> 组项（group item）：本身不存数据，是下面的容器
           05 WS-ID        PIC 9(5).
           05 WS-NAME      PIC X(20).
           05 WS-BALANCE   PIC S9(7)V99.
```

| 层级号 | 含义 |
|---|---|
| `01` | 记录/组项的根。一个 `01` 可以带 PIC（成为独立基本项），也可不带（成为组项容器） |
| `02`–`49` | 从属层，逐级嵌套。常用 `05`、`10`、`15`（习惯每级跳 5，方便插入） |
| `77` | **独立的单项基本数据**，不属于任何组、也不能再有从属项（类似"标量变量"） |
| `88` | **条件名**（condition-name），给某个数据项的特定值起名字（见 §6） |
| `66` | `RENAMES`：给已有数据项起别名/重新划定范围（高级，少用） |

```cobol
       77 WS-COUNTER    PIC 9(4) VALUE 0.    *> 77：独立标量，不归任何组
```

> **组项的整体操作**：对组项 `WS-CUSTOMER` 做 `MOVE`、`DISPLAY` 会作用于它**全部从属项
> 拼成的字节串**。`DISPLAY WS-CUSTOMER` 会把 ID+NAME+BALANCE 的原始字节连起来打印——
> 一般不这么用，但理解"组项 = 一段连续字节"很关键（文件记录、CALL 传参全靠它）。

## 3. PIC 字符总表

PIC 子句由一串"图片字符"组成，描述数据的形态：

| PIC 字符 | 含义 | 例 | 实测显示 |
|---|---|---|---|
| `X(n)` | 字母数字串，**定长 n 字节**，右补空格 | `PIC X(20) VALUE "张三"` | `张三` + 空格（共 20 字节） |
| `9(n)` | n 位数字（无符号），**左补零** | `PIC 9(4) VALUE 42` | `0042` |
| `A(n)` | n 个字母字符（只允许字母/空格） | `PIC A(5) VALUE "ABCDE"` | `ABCDE` |
| `S` | 带符号（sign），放在 PIC 最前 | `PIC S9(4) VALUE -1234` | `-1234` |
| `V` | **隐含**小数点（不占存储、不显示） | `PIC 9(3)V99 VALUE 12.34` | `012.34` |
| `P` | 假定小数位（缩放，少用） | `PIC 9(3)P99` | — |
| `Z(n)` | 编辑：前导零显示成空格 | `PIC Z(4) VALUE 42` | ` 42`（见第 04 章） |
| `B` | 编辑：插入一个空格 | — | — |

**几个要点**：

- `X(n)` 与 `9(n)` 里的 `(n)` 是**重复次数**，等价于把字符写 n 遍（`9(4)` = `9999`）。
- `V` 是"**隐含**小数点"：存储里没有小数点字符，但运算时按它对齐小数位。显示时
  GnuCOBOL 会把 `V` 渲染成 `.`（实测 `PIC 9(3)V99 VALUE 12.34` 显示 `012.34`）。
- `S` 表示带符号：`PIC S9(7)V99` = 带符号、7 位整数、2 位小数。
- **`A` 只接受字母**：往 `PIC A` 里塞数字/中文，行为依方言而定，别滥用——绝大多数字符串
  都用 `X`。

## 4. 字节 vs 字符：中文的硬坑

COBOL 的 `PIC X(n)`、`9(n)`、`LENGTH` 全部**按字节**计，不是按"字符"。在 UTF-8 下，
一个汉字占 **3 字节**：

```cobol
       01 WS-CN  PIC X(12) VALUE "中文测试".    *> 4 个汉字 = 12 字节，正好填满 X(12)
       01 WS-LEN PIC 9(3).
           COMPUTE WS-LEN = FUNCTION LENGTH(WS-CN).   *> WS-LEN = 12（字节，不是 4！）
```

实测 `examples/03_data` 与 `05_strings`：`FUNCTION LENGTH("中文测试"占位项)` = `012`。

> 后果：
> - 引用修改 `WS-CN(1:3)` 取的是**前 3 个字节**，正好是"中"一个字；`WS-CN(1:2)` 会切到
>   半个汉字，显示乱码。
> - 定长 `X(n)` 装中文要按字节算容量（n 至少是字数 ×3）。
> - `STRING`/`UNSTRING`/`INSPECT` 都以字节为单位（第 05 章）。
>
> 想按"字符"处理多字节文本，要么全程用单字节（ASCII/拉丁），要么自己按字节步进——
> COBOL 本身没有"宽字符"概念。

## 5. USAGE：内部存储方式（决定字节数与运算速度）

`PIC` 描述"逻辑形态"，`USAGE` 描述"物理存储"。同一个 `PIC S9(9)`，不同 USAGE 占的字节
完全不同。实测（`examples/03_data`，对 `PIC S9(9)`）：

| USAGE | 别名 | 存储方式 | S9(9) 实测字节 | 说明 |
|---|---|---|---|---|
| `DISPLAY` | （默认） | 每位数字 1 个 ASCII 字符 | **9** | 默认；便于显示/文件文本，运算慢 |
| `BINARY` | `COMP`、`COMP-4` | 机器二进制整数 | **4** | 运算快；大小由机器字决定 |
| `COMP-5` | `COMP-BINARY` | 原生二进制（不做显示转换） | **4** | 与 C 的 int 互通（第 16 章） |
| `COMP-3` | `PACKED-DECIMAL` | 压缩十进制（BCD，每字节 2 位） | **5** | 大机/金融最常用；(位数+符号)/2 向上取整 |
| `INDEX` | — | 表索引专用 | 机器字 | 只用于 `INDEXED BY`（第 08 章） |
| `POINTER` | — | 内存地址 | 机器字 | `ADDRESS OF` / C 互操作 |

```cobol
       01 WS-USAGE.
           05 WS-DISP    PIC S9(9) USAGE DISPLAY.    *> 9 字节
           05 WS-BIN     PIC S9(9) USAGE BINARY.     *> 4 字节
           05 WS-PACKED  PIC S9(9) USAGE COMP-3.     *> 5 字节
           05 WS-COMP5   PIC S9(9) USAGE COMP-5.     *> 4 字节
```

实测输出：

```text
S9(9) 各 USAGE 字节：DISPLAY=09 BINARY=04 COMP-3=05 COMP-5=04
```

**怎么选**：

- **文本文件 / 显示 / 与外部按字符交互** → `DISPLAY`（默认，所见即所得）。
- **大量算术、性能敏感** → `BINARY`/`COMP-5`（机器字，快）。
- **金融/大机兼容、要精确十进制又要省空间** → `COMP-3`（packed，存量系统里到处都是）。

> **COMP-3 字节数公式**：无符号 `9(n)` = `ceil((n+1)/2)`；带符号 `S9(n)` = `ceil((n+1)/2)`
> 再加半个字节放符号——实测 `S9(9)` = `(9+1)/2 = 5` 字节。别拿 `DISPLAY` 的字节数去推断
> `COMP-3` 的，二者完全不同。

> **实测坑**：`BINARY`/`COMP-5` 的大小由**机器字**决定，不是由 PIC 位数决定。`PIC S9(9)`
> 在 32 位/64 位机上都是 4 字节（够装 9 位）；但 `PIC S9(18)` 会用 8 字节。跨平台移植时
> 若依赖 BINARY 的字节布局（如直接读写二进制文件），要当心字长差异。

## 6. 88 层条件名：给值起名字

`88` 层是 COBOL 的特色——它给某个数据项的**特定值**起一个布尔式的名字，配合 `SET` 使用：

```cobol
       01 WS-STATUS     PIC X(8) VALUE "OPEN".
           88 IS-OPEN    VALUE "OPEN".       *> 当 WS-STATUS = "OPEN" 时为真
           88 IS-CLOSED  VALUE "CLOSED".
       PROCEDURE DIVISION.
           IF IS-OPEN                         *> 等价于 IF WS-STATUS = "OPEN"
               DISPLAY "状态为 OPEN"
           END-IF.
           SET IS-CLOSED TO TRUE.             *> 把 WS-STATUS 置成 "CLOSED"
```

实测：

```text
状态为 OPEN（88 条件名命中）
SET 之后 STATUS=[CLOSED  ]      *> X(8) 定长，CLOSED 后补 2 空格
```

- `IF 条件名` 判断底项是否等于该条件名的 `VALUE`。
- `SET 条件名 TO TRUE` 把底项设成该值。
- 一个 `88` 可以有多个 `VALUE`（`VALUE "A" "B"`，任一命中即为真）。
- 好处：代码读起来像英语，且"魔数"集中定义——COBOL 的结构化惯用法。

## 7. VALUE 初始化

```cobol
       01 WS-NAME  PIC X(20) VALUE "张三".     *> 声明即赋初值
       77 WS-RATE  PIC 9V99  VALUE 1.05.
       01 WS-FLAG  PIC X     VALUE "Y".
```

- `VALUE` 在程序加载时设置初值（WORKING-STORAGE 只设一次）。
- 不给 `VALUE` 的项初值依实现而定（GnuCOBOL 一般清零/空格，但**别依赖**，显式给 VALUE）。
- `VALUE` 的字面量会被 PIC 截断/补位到声明长度。

## 8. 实测输出（examples/03_data 全量）

```text
ID=[01001] NAME=[张三              ]
BAL=+0012345.67
COUNTER=0001 RATE=1.05
ALPHA=[ABCDE] ALNUM=[A1中文]
INT=[0042] SIGNED=-1234 DEC=012.34
S9(9) 各 USAGE 字节：DISPLAY=09 BINARY=04 COMP-3=05 COMP-5=04
状态为 OPEN（88 条件名命中）
SET 之后 STATUS=[CLOSED  ]
==== 03 结束 ====
```

读几个细节：

- `NAME=[张三              ]`：`PIC X(20)`，`张三`（6 字节）+ 14 个空格。
- `BAL=+0012345.67`：`PIC S9(7)V99` 带符号 DISPLAY——**显示时带 `+`/`-` 前缀**，整数部分
  左补零到 7 位，`V` 渲染成小数点。
- `ALNUM=[A1中文]`：`PIC X(8)`，`A`+`1`+`中文`(6字节) = 正好 8 字节。
- `INT=[0042]`：`9(4)` 左补零；`DEC=012.34`：`9(3)V99`。

## 9. 坑位清单（实测）

1. **PIC 全按字节**：`X(n)`/`9(n)`/`LENGTH` 数字节；汉字 UTF-8 占 3 字节，容量与切片都要按字节算。
2. **`V` 是隐含小数点**：存储里没有小数点字符，但 DISPLAY 会渲染成 `.`；运算按它对齐。
3. **带符号 DISPLAY 显示带 `+`/`-` 前缀**：`PIC S9(7)V99` 的 12345.67 显示成 `+0012345.67`。
4. **USAGE 决定字节数，与 PIC 位数不是一回事**：`S9(9)` 在 DISPLAY=9、BINARY=4、COMP-3=5 字节。
5. **`BINARY`/`COMP-5` 大小由机器字决定**：跨平台依赖二进制布局要小心字长。
6. **`FUNCTION LENGTH(定长项)` 是编译期常量**：直接跟字面量比触发 `-Wconstant-numlit-expression`
   告警——先 `COMPUTE` 进数据项再比（本示例的 `WS-LENS` 就是这么做的）。
7. **数据声明不能写在 PROCEDURE DIVISION 里**：`01`/`77` 必须在 DATA DIVISION（嵌套程序除外）。
8. **`A` 只收字母**：字符串一律用 `X`，别用 `A` 装数字/中文。

---
上一章：[02 第一个程序与四大部](02-hello.md) ｜ 下一章：[04 数值与运算](04-numeric.md) ｜ 返回：[README](../README.md)
