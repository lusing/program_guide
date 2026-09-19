# 12 · 文件 II：相对文件与索引文件（ISAM）

> 示例：[`examples/12_isam/`](../examples/12_isam/)
> 运行：`./run-all.sh 12`

顺序文件只能从头读到尾。要**按 key 直接跳到某条记录**，得用另外两种组织：

- **相对文件（RELATIVE）**：记录按"第几条"（相对记录号）定位，像数组下标。快，但记录号
  必须自己管、可能有空洞。
- **索引文件（INDEXED）**：记录按**键**定位，底层维护索引，支持随机读、按序遍历、
  插入/改写/删除。这就是经典的 **ISAM**（Indexed Sequential Access Method）——
  既能随机（直接按 key 读）又能顺序（`START` + `READ NEXT` 遍历）。

GnuCOBOL 3.2 的索引文件后端是 **BDB（Berkeley DB）**（`cobc --info` 里
`indexed file handler : BDB`），装好即用，无需额外配置。

## 1. 相对文件：按记录号定位

```cobol
       FILE-CONTROL.
           SELECT REL-FILE ASSIGN TO "rel.dat"
               ORGANIZATION RELATIVE
               ACCESS MODE IS RANDOM          * 随机访问：按 RELATIVE KEY 直接读写
               RELATIVE KEY IS REL-KEY        * 键变量必须在 WORKING-STORAGE
               FILE STATUS IS REL-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD  REL-FILE.
       01  REL-REC.
           05 REL-NAME    PIC X(10).
           05 REL-VAL     PIC 9(4).
       WORKING-STORAGE SECTION.
       01 REL-KEY         PIC 9(4).          * ← RELATIVE KEY 住这里，不在 FD 里
```

**写**：把记录号放进 `REL-KEY`，再 `WRITE`。记录会落在第 `REL-KEY` 个槽位。

```cobol
           OPEN OUTPUT REL-FILE.
           PERFORM VARYING REL-KEY FROM 1 BY 1 UNTIL REL-KEY > 3
               MOVE SPACES TO REL-NAME
               STRING "R" REL-KEY DELIMITED BY SIZE INTO REL-NAME
               COMPUTE REL-VAL = REL-KEY * 100
               WRITE REL-REC
           END-PERFORM.
           CLOSE REL-FILE.
```

**读/改**：`OPEN I-O`，把目标记录号放进 `REL-KEY`，`READ` 定位，改记录区，`REWRITE`。

```cobol
           OPEN I-O REL-FILE.
           MOVE 2 TO REL-KEY.
           READ REL-FILE.              * 随机读第 2 条
           COMPUTE REL-VAL = 999.
           REWRITE REL-REC.            * 原地改写刚读出的那条
```

> **坑（实测）：`RELATIVE KEY` 变量必须声明在 `WORKING-STORAGE SECTION`，不能放 `FILE
> SECTION`。** 它是"定位用的输入"，不是记录的一部分。同理索引文件的 `RECORD KEY` 才是
> 记录内的字段（见下）。

## 2. 索引文件：按键定位 + 自动排序

```cobol
           SELECT IDX-FILE ASSIGN TO "idx.dat"
               ORGANIZATION INDEXED
               ACCESS MODE IS DYNAMIC         * 随机 + 顺序混用
               RECORD KEY IS IDX-ID           * 键是记录里的字段（在 FD 内）
               FILE STATUS IS IDX-STATUS.
       FD  IDX-FILE.
       01  IDX-REC.
           05 IDX-ID      PIC 9(4).          * ← RECORD KEY 指向这个字段
           05 IDX-NAME    PIC X(10).
           05 IDX-VAL     PIC 9(4).
```

- **`RECORD KEY IS IDX-ID`**：主键是记录内的字段（与相对文件的 `RELATIVE KEY` 在
  WORKING-STORAGE 不同）。写入时 GnuCOBOL 自动按主键维护索引，**乱序写、顺序读**。
- **`ACCESS MODE IS DYNAMIC`**：允许同一文件既随机读又顺序遍历。只随机用 `RANDOM`，
  只顺序用 `SEQUENTIAL`。
- 还可以声明 `ALTERNATE RECORD KEY`（备用键，允许重复用 `WITH DUPLICATES`），本例从简。

### 2.1 随机读

把键值放进 `RECORD KEY` 字段，`READ` 直接命中：

```cobol
           MOVE 30 TO IDX-ID.
           READ IDX-FILE.              * 随机读 key=30
```

### 2.2 顺序遍历：START + READ NEXT

`START` 把游标定位到"第一个 ≥（或 =、>）某键"的记录，然后 `READ ... NEXT RECORD` 逐条推进：

```cobol
           MOVE 10 TO IDX-ID.
           START IDX-FILE KEY IS >= IDX-ID.    * 定位到第一个 key>=10
           PERFORM UNTIL WS-EOF = 1
               READ IDX-FILE NEXT RECORD
                   AT END MOVE 1 TO WS-EOF
                   NOT AT END
                       ADD 1 TO WS-IDXCNT
                       ADD IDX-VAL TO WS-SUM
               END-READ
           END-PERFORM.
```

`START` 的比较符可用 `=`、`>=`、`>`。这是索引文件"顺序"能力的来源——按主键升序吐出记录。

### 2.3 改写与删除

```cobol
           MOVE 40 TO IDX-ID.
           READ IDX-FILE.              * 先 READ 定位（DELETE/REWRITE 前必须先读中）
           DELETE IDX-FILE RECORD.     * 删掉这条
```

`REWRITE`/`DELETE` 都要求**先 `READ` 命中目标记录**，否则 status 43（未定位）。

## 3. 实测输出（含各状态码）

`./run-all.sh 12 -v`，check/release 两通道逐字节一致：

```text
REL OPEN OUTPUT status = 00
REL OPEN I-O status = 00
REL 随机读 key=2: 名=[R0002     ] 值=0200 status=00
REL REWRITE status = 00
REL 改后读 key=2: 值=0999
REL 读缺失 key=9 status = 23（23=记录未找到）
IDX OPEN OUTPUT status = 00
IDX 重复写 key=30 status = 22（22=键重复）
IDX 随机读 key=30: 名=[K0030     ] 值=0300 status=00
IDX START >=10 status = 00
  顺序: key=0010 名=[K0010     ] 值=0100
  顺序: key=0020 名=[K0020     ] 值=0200
  顺序: key=0030 名=[K0030     ] 值=0300
  顺序: key=0040 名=[K0040     ] 值=0400
IDX DELETE key=40 status = 00
IDX 删后读 key=40 status = 23（23=已删除）
IDX 顺序条数=004 值合计=001000
==== 12 结束 ====
```

几个关键观察：

- **乱序写、顺序读**：写入时键是 10/20/30/40，`START >=10` + `READ NEXT` 严格按升序吐出。
- **相对文件读空槽（key=9 从未写）**：status `23`（记录未找到）。
- **索引文件写重复键**：status `22`（键重复）——主键不允许重复，这是索引的约束。
- **删后再读**：status `23`（已删除）。

## 4. "先建后改"模式（本章第二个实测坑）

> **对【不存在】的索引/相对文件直接 `OPEN I-O`，会得到 status `35`（文件不存在）；
> 紧接着 `WRITE` 会得到 status `48`（该文件未以输出模式打开）。**

也就是说，`I-O` 模式**只能打开已存在的文件**，不能凭空创建。要新建一个可读写的索引文件，
必须走"先建后改"三步：

```cobol
           OPEN OUTPUT IDX-FILE.       * ① 以 OUTPUT 建文件（并写入初始记录）
           WRITE ...
           CLOSE IDX-FILE.             * ② 关闭
           OPEN I-O IDX-FILE.          * ③ 再以 I-O 打开做后续读/改/删
```

我在探查本章时先撞了这个坑：对一个还没建的 `idx.dat` 直接 `OPEN I-O`，status 35；
不死心接着 `WRITE`，status 48。改成"先 `OPEN OUTPUT` 建好再 `OPEN I-O`"才通。
**这是索引/相对文件编程的固定套路**，务必记牢。

## 5. 三种文件组织对比

| | 顺序 (LINE SEQUENTIAL) | 相对 (RELATIVE) | 索引 (INDEXED) |
|---|---|---|---|
| 定位方式 | 只能顺序 | 相对记录号（数组下标式） | 键（自动索引） |
| 随机访问 | ✗ | ✓ | ✓ |
| 顺序遍历 | ✓（唯一方式） | 需自己扫记录号 | ✓（`START`+`READ NEXT`，按键序） |
| 改/删单条 | 难（要重写整个文件） | ✓（`REWRITE`） | ✓（`REWRITE`/`DELETE`） |
| 键约束 | 无 | 记录号可有空洞 | 主键唯一（重复报 22） |
| 后端 | 文本文件 | 定长记录文件 | BDB（Berkeley DB） |
| 典型用途 | 报表、导出 | 记录号天然连续的场景 | 需要按键快速检索的主数据 |

## 6. 状态码速查（随机/索引文件新增）

在第 11 章的基础上，随机与索引文件还会遇到：

| 码 | 含义 |
|---|---|
| `02` | 成功，但命中重复备用键（索引文件，有 `ALTERNATE KEY ... WITH DUPLICATES` 时） |
| `14` | 相对文件：记录号超出范围 |
| `21` | 索引文件：键顺序违规（`SEQUENTIAL` 访问模式下乱序写） |
| `22` | 键重复（主键已存在） |
| `23` | 记录未找到（随机读的键不存在 / 记录已删） |
| `24` | 键边界违规 |
| `43` | `REWRITE`/`DELETE` 前没有先 `READ` 命中记录 |
| `48` | 该文件未以输出模式打开却 `WRITE`（"先建后改"没做对） |

## 7. 坑位清单（实测）

1. **`OPEN I-O` 不能创建文件**：对缺失文件得 35，接着 WRITE 得 48。必须"先 `OPEN OUTPUT`
   建好、`CLOSE`，再 `OPEN I-O`"。
2. **`RELATIVE KEY` 在 WORKING-STORAGE，`RECORD KEY` 在 FD 记录内**——两者位置不同，别搞反。
3. **`REWRITE`/`DELETE` 前必须先 `READ` 命中**，否则 status 43。
4. **主键重复写入得 status 22**：索引文件的主键天然唯一。
5. **`START` 后才能 `READ NEXT`**：顺序遍历索引文件要先用 `START ... KEY IS >= ...` 定位游标。
6. **索引文件后端是 BDB**：生成的 `.dat` 是 Berkeley DB 格式，不是文本，别用 `cat` 看。
7. **相对文件读空槽得 23**：记录号可以不连续，读没写过的槽就是"未找到"。

---
上一章：[11 文件 I：顺序文件](11-files-seq.md) ｜ 下一章：[13 状态码、异常与调试](13-status-debug.md) ｜ 返回：[README](../README.md)
