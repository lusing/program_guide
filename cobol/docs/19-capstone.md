# 19 · 综合实战：库存管理系统

> 示例：[`examples/19_capstone/`](../examples/19_capstone/)
> 运行：`./run-all.sh 19`

前面 18 章把 COBOL 的零件一块块拆开讲：数据类型、控制流、`PERFORM`、表、子程序、内部函数、
顺序文件、索引文件、状态码与调试、结构化编程、屏幕、C 互操作、控制break 报表、测试方法论。
本章是**收官实战**——一个库存管理系统，把这些零件组装成一个真正会动的程序，并全程用断言
把它钉死在"正确"上。

读完你会看到：一个中等规模的 COBOL 程序是怎么**分层组织**的，索引文件怎么**先建后改**，
控制break 报表怎么落到真实文件上，以及本章现场踩到的一个**无符号字段吞掉负数**的经典坑。

## 1. 需求与设计

一个最小的库存系统，做四件事：

1. **建档**：5 个商品写进一个索引文件（按 SKU 为主键）。
2. **过账**：5 笔出入库交易，逐笔随机读商品、改数量、回写。
3. **报表**：按类别（外设/存储/显示）出控制break 估值报表 + 总估值。
4. **预警**：列出库存低于安全线的商品。

全程断言：交易笔数、类别数、明细行数、低库存种数、总估值——**退出码 = 失败数**
（第 18 章的纪律）。

对应的数据模型：

```cobol
       FD  INV-REC.
       01  INV-REC.
           05 INV-SKU      PIC 9(5).        * 主键：商品编号
           05 INV-NAME     PIC X(12).       * 名称
           05 INV-CAT      PIC X(8).        * 类别（报表的 break 字段）
           05 INV-PRICE    PIC 9(5)V99.     * 单价
           05 INV-QTY      PIC S9(5).       * 库存量（带符号：可为负）
           05 INV-MIN      PIC S9(5).       * 安全库存线
```

注意 `INV-QTY` 是 **`S9(5)` 带符号**——因为出库可能把库存打成负数（超卖），我们要让这个
负数**真实存在**并被后续算术正确处理，而不是被夹到 0。这个决定在第 5 节会救我们一命。

## 2. 文件声明：索引 + 动态访问

```cobol
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT INV-FILE ASSIGN TO "inv.dat"
               ORGANIZATION INDEXED
               ACCESS MODE IS DYNAMIC        * 既要随机读又要顺序扫
               RECORD KEY IS INV-SKU
               FILE STATUS IS INV-STATUS.
```

`ACCESS MODE IS DYNAMIC` 是关键：本程序**两种读法都要用**——

- 过账时按 SKU **随机读**（`READ INV-FILE` + INVALID KEY）；
- 报表和预警时**顺序扫全表**（`READ INV-FILE NEXT RECORD` + AT END）。

`DYNAMIC` 允许在同一个打开的文件上混用随机与顺序访问（第 12 章讲过三种 ACCESS MODE 的取舍）。
`RECORD KEY IS INV-SKU` 指明主键，`FILE STATUS IS INV-STATUS` 让我们能查每一步的状态码。

## 3. 先建后改：索引文件的两段式生命周期

索引文件不能一上来就 `OPEN I-O`——文件还不存在。标准套路是**先用 OUTPUT 建、CLOSE、再 I-O 改**：

```cobol
       BUILD-FILE SECTION.
           OPEN OUTPUT INV-FILE.              * 建文件（覆盖式）
           IF INV-STATUS NOT = "00"
               DISPLAY "FAIL: 建文件 status=" INV-STATUS
               ADD 1 TO WS-FAILS
               STOP RUN RETURNING WS-FAILS    * 建都建不起来，早退
           END-IF.
           PERFORM PUT-ITEM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 5.
           CLOSE INV-FILE.                    * ★ 必须 CLOSE 再重开
```

`PUT-ITEM` 用 `EVALUATE WS-I` 把 5 个商品的字段填好，再 `WRITE INV-REC`。建完 `CLOSE`，
过账阶段才 `OPEN I-O`。**为什么必须 CLOSE？** 因为 `OPEN OUTPUT` 与 `OPEN I-O` 是两种不同
的打开模式，同一个文件不能同时以两种模式打开；而且索引文件在 OUTPUT 模式下写入的结构，
要 CLOSE 后才对后续 I-O 打开完整可见（第 12 章"先建后改"实测过这一点）。

过账逐笔处理：

```cobol
       APPLY-TXNS SECTION.
           OPEN I-O INV-FILE.
           DISPLAY "OPEN I-O status=" INV-STATUS.
           MOVE 0 TO WS-N.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 5
               MOVE T-SKU(WS-I) TO INV-SKU      * 把目标 SKU 放进键字段
               READ INV-FILE                     * 随机读（DYNAMIC 下按键读）
                   INVALID KEY
                       DISPLAY "FAIL: 交易 SKU 不存在 " T-SKU(WS-I)
                       ADD 1 TO WS-FAILS
                   NOT INVALID KEY
                       COMPUTE INV-QTY = INV-QTY + T-DELTA(WS-I)
                       REWRITE INV-REC           * 原地回写
                       IF INV-STATUS NOT = "00"
                           DISPLAY "FAIL: REWRITE status=" INV-STATUS
                           ADD 1 TO WS-FAILS
                       ELSE
                           ADD 1 TO WS-N
                       END-IF
               END-READ
           END-PERFORM.
           CLOSE INV-FILE.
           DISPLAY "应用交易 " WS-N " 笔".
```

随机读的套路（第 12 章）：**把键 `MOVE` 进 RECORD KEY 字段 → `READ` → 用 INVALID KEY /
NOT INVALID KEY 分流**。改完用 `REWRITE`（不是 `WRITE`——`REWRITE` 原地更新已读出的记录，
`WRITE` 会试图插入新记录从而撞主键，status 22）。

## 4. 控制break 报表落到真实文件

第 17 章在内存表上演示了控制break；本章把它落到**索引文件的顺序扫描**上。因为文件按 SKU
升序存储，而 SKU 的前缀天然把同类商品排在一起（10001/10002 都是 PERIPH，20001/20002 都是
STORAGE，30001 是 DISPLAY），所以**顺序读文件时同类别记录自动相邻**——这正是控制break 的
前提（break 字段必须先有序，第 17 章反复强调）。

```cobol
       CATEGORY-REPORT SECTION.
           OPEN INPUT INV-FILE.
           MOVE SPACES TO WS-PREV-CAT.
           MOVE 0 TO WS-GRAND-TOT WS-CATCNT WS-ROWS.
           DISPLAY "===== 库存估值报表（按类别）=====".
           MOVE 0 TO WS-EOF.
           PERFORM UNTIL WS-EOF = 1
               READ INV-FILE NEXT RECORD          * 顺序扫
                   AT END MOVE 1 TO WS-EOF
                   NOT AT END PERFORM REPORT-ROW
               END-READ
           END-PERFORM.
           PERFORM BREAK-CATEGORY.                * ★ 尾break：收尾最后一组
           DISPLAY "------------------------------".
           DISPLAY "库存总估值 = " WS-GRAND-TOT.
           CLOSE INV-FILE.
```

`REPORT-ROW` 是 break 的核心：算估值 → 检测类别是否变了 → 变了就先结上一组小计：

```cobol
       REPORT-ROW SECTION.
           COMPUTE WS-VALUE = INV-PRICE * INV-QTY.   * 单行估值
           IF INV-CAT NOT = WS-PREV-CAT              * break 检测
               IF WS-PREV-CAT NOT = SPACES           * 第一组不结（还没东西）
                   PERFORM BREAK-CATEGORY
               END-IF
               MOVE INV-CAT TO WS-PREV-CAT
           END-IF.
           ADD 1 TO WS-ROWS.
           DISPLAY "  " INV-CAT " " INV-NAME
               " qty=" INV-QTY " x " INV-PRICE " = " WS-VALUE.
           ADD WS-VALUE TO WS-CAT-SUBTOT WS-GRAND-TOT.

       BREAK-CATEGORY SECTION.
           DISPLAY "  -- " WS-PREV-CAT " 小计 = " WS-CAT-SUBTOT.
           ADD 1 TO WS-CATCNT.
           MOVE 0 TO WS-CAT-SUBTOT.                  * 清小计，准备下一组
```

两个 break 时机缺一不可：**组间 break**（`REPORT-ROW` 里检测到类别变化）和**尾 break**
（循环结束后补一次 `BREAK-CATEGORY`，否则最后一组 DISPLAY 的小计永远打不出来）。这是控制break
最容易漏的一处（第 17 章的坑位清单第 1 条）。

## 5. 现场踩坑：无符号字段悄悄吞掉负数 ★

这是本章最有价值的一课，因为它是**真实发生、被断言当场抓住**的。

Monitor 这笔交易是 `-30`（出库 30），库存从 25 变成 **-5**（超卖）。它的估值应是
`-5 × 1299.00 = -6495.00`。三类合计应是：

```
PERIPH   18692.00
STORAGE  20963.00
DISPLAY  -6495.00   ← 负数
合计     33160.00
```

但**第一次运行**的报表打出来是这样（节选）：

```text
  DISPLAY  Monitor      qty=-00005 x 01299.00 = +0006495.00
  -- DISPLAY  小计 = +0006495.00
库存总估值 = +000046150.00
FAIL: 总估值应 33160.00 实际 000046150.00
```

`qty=-00005` 明明是对的（`INV-QTY` 带符号，负数存住了），可估值却变成了 **`+0006495.00`**
——负的变正了！合计也跟着从 33160 涨到 46150（差的正是 `2 × 6495`：本该减 6495，结果加了 6495）。

**根因**：承接估值的字段当初写成了**无符号**：

```cobol
       01 WS-VALUE        PIC 9(7)V99 VALUE 0.     * ✗ 无符号！
```

`PIC 9(7)V99` 没有前导 `S`，是**无符号**字段。`COMPUTE WS-VALUE = INV-PRICE * INV-QTY`
算出 -6495.00 后，要存进一个**装不下负号**的字段——GnuCOBOL 的处理是**取绝对值**（丢弃符号），
于是 -6495 变成 +6495。不报错、不告警、status 也正常，就这么**静默地错了**。

**修复**：凡是可能承接负数（尤其是"带符号数量 × 单价"这类乘积）的字段，必须带 `S`：

```cobol
       01 WS-CAT-SUBTOT   PIC S9(7)V99 VALUE 0.    * ✓ 带符号
       01 WS-GRAND-TOT    PIC S9(9)V99 VALUE 0.    * ✓ 带符号
       01 WS-VALUE        PIC S9(7)V99 VALUE 0.    * ✓ 带符号
```

改完再跑，`-0006495.00` 正确显示，合计 `+000033160.00`，断言全过。

> **教训**：无符号字段遇到负值不报错，而是**取绝对值静默篡改**。这种 bug 极其隐蔽——
> 每一步 status 都是 00，编译零告警，只有最终数字对不上才暴露。防御手段有两条：
> ①凡是可能为负的中间量一律用 `S` 前缀；②**用断言把最终结果钉死**（本例正是
> `WS-GRAND-TOT NOT = 33160.00` 这条断言当场抓住了它——没有断言，这个错会一路溜到生产）。
> 这也反过来说明了第 18 章"每个程序都要有断言 + 退出码"的分量。

## 6. 低库存预警：第二次顺序扫

预警复用同一套顺序扫描，只是判定条件不同：

```cobol
       LOW-STOCK SECTION.
           OPEN INPUT INV-FILE.
           MOVE 0 TO WS-LOWCNT WS-EOF.
           DISPLAY "===== 低库存预警 =====".
           PERFORM UNTIL WS-EOF = 1
               READ INV-FILE NEXT RECORD
                   AT END MOVE 1 TO WS-EOF
                   NOT AT END
                       IF INV-QTY < INV-MIN          * 低于安全线
                           ADD 1 TO WS-LOWCNT
                           DISPLAY "  [低] " INV-NAME
                               " qty=" INV-QTY " < min=" INV-MIN
                       END-IF
               END-READ
           END-READ
           CLOSE INV-FILE.
           DISPLAY "低库存商品 " WS-LOWCNT " 种".
```

交易后 5 个商品的库存是：Keyboard 80（线 20，安全）、Mouse 28（线 15，安全）、
SSD 25（线 10，安全）、HDD 12（线 12，**恰好等于**不算低）、Monitor -5（线 8，**低**）。
所以只有 Monitor 触发——注意 `INV-QTY < INV-MIN` 用的是**严格小于**，HDD 的 12=12 不报警
（又是一个 `>=` vs `>` 的边界，第 18 章讲过要专门测边界）。

## 7. 断言与实测输出

`FINAL-CHECKS` 把五个关键量全钉死：交易笔数=5、类别数=3、明细行数=5、低库存种数=1、
总估值=33160.00。`./run-all.sh 19 -v`，check/release 两通道逐字节一致：

```text
OPEN I-O status=00
应用交易 05 笔
===== 库存估值报表（按类别）=====
  PERIPH   Keyboard     qty=+00080 x 00199.00 = +0015920.00
  PERIPH   Mouse        qty=+00028 x 00099.00 = +0002772.00
  -- PERIPH   小计 = +0018692.00
  STORAGE  SSD-1TB      qty=+00025 x 00599.00 = +0014975.00
  STORAGE  HDD-4TB      qty=+00012 x 00499.00 = +0005988.00
  -- STORAGE  小计 = +0020963.00
  DISPLAY  Monitor      qty=-00005 x 01299.00 = -0006495.00
  -- DISPLAY  小计 = -0006495.00
------------------------------
库存总估值 = +000033160.00
===== 低库存预警 =====
  [低] Monitor      qty=-00005 < min=+00008
低库存商品 01 种
==== 19 结束 ====
```

逐条核对：

| 断言 | 期望 | 实测 | 验证点 |
|---|---|---|---|
| 交易笔数 | 5 | `应用交易 05 笔` | 5 笔全部随机读+REWRITE 成功 |
| 类别数 | 3 | 3 个 `-- xxx 小计` | break 正确触发 3 次（含尾break） |
| 明细行数 | 5 | 5 行商品 | 顺序扫描读全 5 条 |
| PERIPH 小计 | 18692 | `+0018692.00` | 80×199 + 28×99 |
| STORAGE 小计 | 20963 | `+0020963.00` | 25×599 + 12×499 |
| DISPLAY 小计 | -6495 | `-0006495.00` | **负库存估值为负**（第 5 节的坑） |
| 总估值 | 33160 | `+000033160.00` | 18692+20963-6495 |
| 低库存种数 | 1 | `低库存商品 01 种` | 只有 Monitor，HDD 12=12 不报 |

## 8. 程序的分层结构

整个程序是一棵清晰的 `SECTION` 调用树，`MAIN-SECTION` 只做编排：

```text
MAIN-SECTION
├── BUILD-FILE          建索引文件
│   └── PUT-ITEM        （VARYING 调 5 次）填一个商品并 WRITE
├── LOAD-TXNS           装交易表
├── APPLY-TXNS          过账：随机读 → 改 → REWRITE
├── CATEGORY-REPORT     控制break 估值报表
│   ├── REPORT-ROW      单行：算估值 + break 检测
│   └── BREAK-CATEGORY  结一组小计（组间 + 尾部共用）
├── LOW-STOCK           低库存预警
└── FINAL-CHECKS        断言
```

这就是第 14 章"结构化编程"的落地：**每个 SECTION 只干一件事，名字就是文档，MAIN 只编排
不陷入细节**。一个 200 行的 COBOL 程序，靠分层做到读起来一目了然。

## 9. 坑位清单（实测）

1. **无符号字段静默取绝对值** ★：`PIC 9(7)V99`（无 `S`）承接负数时不报错，直接丢符号
   存绝对值。凡是"带符号量 × 单价"这类可能为负的中间结果，字段必须带 `S`。这种 bug 编译
   零告警、status 全 00，只有断言最终数字才抓得住。
2. **索引文件必须先建后改**：`OPEN OUTPUT` 建档 → `CLOSE` → 才能 `OPEN I-O`。跳过 CLOSE
   或试图对不存在的文件直接 I-O 会吃 status 35/97。
3. **改记录用 REWRITE 不是 WRITE**：随机读出来后原地更新用 `REWRITE`；用 `WRITE` 会试图
   插入同主键的新记录，撞 status 22（键重复）。
4. **尾break 别漏**：控制break 循环结束后必须补一次"结最后一组"，否则最后一个小计打不出来
   （报表少一行、`WS-CATCNT` 少 1）。
5. **break 字段必须有序**：本例靠"SKU 升序 + 同类 SKU 相邻"天然满足；若数据无序，得先排序
   （第 17 章），否则同一类别会被拆成多个假 break。
6. **`<` vs `<=` 的边界**：低库存判定 `INV-QTY < INV-MIN`，恰好等于安全线（HDD 12=12）
   **不**报警。阈值语义要想清楚并专门测边界。
7. **DYNAMIC 才能混用随机+顺序**：本程序过账随机读、报表顺序扫，必须 `ACCESS MODE IS
   DYNAMIC`；若声明成 RANDOM 或 SEQUENTIAL 之一，另一种读法会失败。

---
上一章：[18 测试方法论](18-testing.md) ｜ 下一章：[20 坑位总清单](20-pitfalls.md) ｜ 返回：[README](../README.md)
