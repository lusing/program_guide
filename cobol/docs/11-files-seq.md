# 11 · 文件 I：顺序文件

> 示例：[`examples/11_sequential/`](../examples/11_sequential/)
> 运行：`./run-all.sh 11`

COBOL  born 在批处理时代，**文件就是它的主场**。别的语言把文件当外设、要引库要记 API，
COBOL 把文件操作刻进了语言骨架：`ENVIRONMENT DIVISION` 声明"用哪个文件"，
`DATA DIVISION` 的 `FILE SECTION` 声明"记录长什么样"，`PROCEDURE DIVISION` 里
`OPEN/READ/WRITE/CLOSE` 四个动词走完一生。本章讲最简单的**顺序文件**（sequential）——
记录一条接一条、只能顺序读；下一章讲能随机定位的相对/索引文件。

## 1. 三步接线：SELECT → FD → 动词

一个文件要在程序里能用，得先在三个地方"接线"，缺一不可：

```cobol
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *① SELECT：给文件起个程序内的名字，绑定到磁盘路径，声明组织方式与状态变量
           SELECT EMP-FILE ASSIGN TO "seqdemo.txt"
               ORGANIZATION LINE SEQUENTIAL
               FILE STATUS IS EMP-STATUS.
       DATA DIVISION.
       FILE SECTION.
      *② FD（File Description）：定义记录布局——名字必须与 SELECT 里的一致
       FD  EMP-FILE.
       01  EMP-REC.
           05 EMP-ID      PIC 9(4).
           05 EMP-NAME    PIC X(10).
           05 EMP-SALARY  PIC 9(6).
       WORKING-STORAGE SECTION.
       01 EMP-STATUS     PIC XX.        *③ 状态变量：每次文件操作后被写入两位码
```

- **`ASSIGN TO "seqdemo.txt"`**：把逻辑名 `EMP-FILE` 绑到物理文件名。相对路径按**运行时
  的当前目录**解析——本仓库验证脚本让程序在 `build/check`、`build/release` 里跑，数据文件
  就落在那儿，`--clean` 一并清掉，不污染 `examples/`。
- **`ORGANIZATION LINE SEQUENTIAL`**：行式顺序文件，每条记录存成一行文本、以换行分隔，
  能用 `cat`/记事本直接看。这是最常用的顺序组织（另一种 `SEQUENTIAL` 是定长记录、无换行）。
- **`FILE STATUS IS EMP-STATUS`**：指定一个两位字符变量接收状态码。**每个文件操作后它都被
  覆写**——`00` 成功，非 `00` 各类问题（见第 5 节）。这是 COBOL 的错误处理主线。

## 2. 写文件：OPEN OUTPUT → WRITE → CLOSE

```cobol
           OPEN OUTPUT EMP-FILE.          * 建文件（已存在则清空）；status 应为 00
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 3
               MOVE WS-I TO EMP-ID
               MOVE SPACES TO EMP-NAME    * 关键：先清空，见下方"坑"
               STRING "EMP" WS-I DELIMITED BY SIZE INTO EMP-NAME
               COMPUTE EMP-SALARY = 3000 + WS-I * 500
               WRITE EMP-REC              * 把记录区的内容写出一条
           END-PERFORM.
           CLOSE EMP-FILE.                * 落盘；不 CLOSE 数据可能还在缓冲区
```

`OPEN` 的四种模式：

| 模式 | 含义 | 允许的操作 |
|---|---|---|
| `OUTPUT` | 新建/清空，从头写 | `WRITE` |
| `INPUT` | 打开已有文件读 | `READ` |
| `I-O` | 读写改（顺序文件少用，随机/索引文件常用） | `READ`/`WRITE`/`REWRITE`/`DELETE` |
| `EXTEND` | 追加到文件末尾 | `WRITE`（接在后面） |

实测输出（`./run-all.sh 11 -v`，check/release 两通道逐字节一致）：

```text
OPEN OUTPUT status = 00
写入 3 条记录，CLOSE status = 00
OPEN INPUT status = 00
  读到: id=0001 名=[EMP01     ] 薪=003500
  读到: id=0002 名=[EMP02     ] 薪=004000
  读到: id=0003 名=[EMP03     ] 薪=004500
记录数=003 薪资合计=00012000
==== 11 结束 ====
```

> **坑（实测，本章最重要的一个）：文件记录区不会自动用空格初始化，`STRING` 也不补齐目标
> 字段的剩余部分。** `EMP-NAME` 是 `PIC X(10)`，`STRING "EMP01"` 只写进 5 个字符，尾部
> 5 字节保留记录区的初始低值（NUL, `x"00"`）。而 LINE SEQUENTIAL 默认开启 `COB_LS_VALIDATE`
> （COBOL 2022 起默认 `true`），它要求记录里都是**可显示字符**——遇到 NUL 就判为非法，
> `WRITE` 直接返回 **status 71**（记录校验失败），而且**不报编译错、不崩，只是写不进去**。
>
> 我在写本章示例时先踩了这个坑：三条 `WRITE` 全部 status 71，读回 0 条。修法有两种：
> ① 写记录前先 `MOVE SPACES TO EMP-NAME`（本例采用，最稳）；② 设环境变量
> `COB_LS_VALIDATE=FALSE` 关掉校验（治标，且会让记录里混入 NUL）。**养成"填字段前先清
> 空格"的肌肉记忆**，尤其是 `STRING`/`UNSTRING` 只填部分字节的场合。

## 3. 读文件：OPEN INPUT → READ ... AT END → CLOSE

顺序读的标准骨架是"`READ` + `AT END` 置标志 + `PERFORM UNTIL`"：

```cobol
           OPEN INPUT EMP-FILE.
           MOVE 0 TO WS-EOF.
           PERFORM UNTIL WS-EOF = 1
               READ EMP-FILE
                   AT END MOVE 1 TO WS-EOF        * 读到文件尾：置标志退出循环
                   NOT AT END
                       ADD 1 TO WS-COUNT
                       ADD EMP-SALARY TO WS-TOTAL
               END-READ
           END-PERFORM.
           CLOSE EMP-FILE.
```

- `READ EMP-FILE` 读下一条到记录区 `EMP-REC`；到文件尾时走 `AT END` 分支（此时
  `FILE STATUS` 被置为 `10`）。
- **`READ` 没有"返回条数"的概念**，只能靠 `AT END` 判尾——这是 COBOL 与 C/Python 读文件
  最大的思维差异：没有 `while(getline)`，只有"读一条，判断是不是到尾了"。
- 也可写成 `READ EMP-FILE INTO WS-AREA`，把记录读进另一个工作变量而非 FD 记录区。

## 4. 为什么用 `PERFORM UNTIL WS-EOF` 而不是 `PERFORM ... VARYING`

顺序文件不知道有多少条，无法用计数循环。惯用法是**哨兵标志**：`AT END` 里把 `WS-EOF`
置 1，`PERFORM UNTIL WS-EOF = 1` 自然收口。第 7 章讲过的 `PERFORM UNTIL` 在这里是主力。

## 5. FILE STATUS 两位码速查（顺序文件常见）

状态码是**两位字符**：首位是"类别"，次位是"具体原因"。顺序文件最常撞见的：

| 码 | 含义 | 典型场景 |
|---|---|---|
| `00` | 成功 | 正常路径 |
| `10` | 文件尾（仅 `READ`） | `AT END` 分支被触发 |
| `30` | 永久错误（I/O 底层失败） | 磁盘满、权限、路径非法 |
| `35` | 文件不存在 | `OPEN INPUT` 一个没有的文件 |
| `37` | 打开模式不被允许 | 对只读文件 `OPEN OUTPUT` |
| `41` | 文件已关闭还去 CLOSE | 重复 `CLOSE` |
| `42` | 文件没打开就去操作 | 未 `OPEN` 或 `OPEN` 失败后 `READ`/`CLOSE` |
| `43` | 未以输出打开却 `WRITE` | 模式不对 |
| `47`/`48` | 操作与打开模式冲突 | `OPEN INPUT` 后 `WRITE`（48） |
| `71` | LINE SEQUENTIAL 记录校验失败 | 记录含 NUL 等非显示字节（见第 2 节坑） |

第 13 章会系统地讲状态码解码与 `DECLARATIVES` 集中式错误处理。

## 6. LINE SEQUENTIAL vs SEQUENTIAL

| | `LINE SEQUENTIAL` | `SEQUENTIAL`（定长记录） |
|---|---|---|
| 存储 | 每条记录一行，`\n` 分隔 | 记录紧挨着，无分隔符 |
| 可读性 | 文本，能 `cat` | 二进制块，`cat` 是乱码 |
| 尾随空格 | 默认会去掉（`COB_LS_NULLS`/`STRIP_TRAILING_SPACES` 可调） | 完整保留 |
| 记录校验 | 默认 `COB_LS_VALIDATE=true`（NUL 报 71） | 无此校验 |
| 典型用途 | 报表、导出、跨工具交换 | 老式主机数据、需精确定长 |

本教程默认用 `LINE SEQUENTIAL`——文本友好、跨平台、能被别的工具读。

## 7. 坑位清单（实测）

1. **记录区不自动空格初始化 + `STRING` 不补齐 → 尾部 NUL → LINE SEQUENTIAL 校验 status 71**。
   填部分字节前先 `MOVE SPACES`。这是本章踩得最实的一个坑。
2. **`FILE STATUS` 每次操作都被覆写**：想断言某一步的码，必须**当场抓快照**到另一个变量，
   否则下一步（哪怕是 `CLOSE`）就把它改了（第 13 章展开）。
3. **`OPEN OUTPUT` 会清空已存在文件**——不是追加。要追加用 `OPEN EXTEND`。
4. **不 `CLOSE` 数据可能不落盘**：缓冲区没刷。程序异常退出前尤其要保证 `CLOSE`。
5. **相对路径按运行时 cwd 解析**，不是按源文件目录。验证脚本特意在 `build/` 里跑，
   数据文件才不散进 `examples/`。
6. **`READ` 无返回条数**，只能 `AT END` 判尾；用哨兵标志配 `PERFORM UNTIL`。

---
上一章：[10 内部函数](10-functions.md) ｜ 下一章：[12 文件 II：相对与索引文件](12-files-isam.md) ｜ 返回：[README](../README.md)
