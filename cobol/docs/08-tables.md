# 08 · 表（OCCURS）与 SEARCH ⭐

> 示例：[`examples/08_tables/08_tables.cob`](../examples/08_tables/08_tables.cob)
> 运行：`./run-all.sh 08`

COBOL 没有"数组类型"——它用 `OCCURS` 子句把同一个数据项**重复 n 次**形成"表（table）"。
访问表有两种方式：**下标（subscript，一个普通整数）**和**索引（index，`INDEXED BY` 声明的
特殊量）**。`SEARCH`/`SEARCH ALL` 必须用索引。这是 COBOL 数据处理的深水区。

## 1. OCCURS：声明一张表

```cobol
       01 WS-NUMS.
           05 WS-NUM PIC 9(3) OCCURS 5 TIMES.   *> 5 个 PIC 9(3) 元素
```

`OCCURS 5 TIMES` 表示重复 5 次。访问用括号下标（**从 1 开始，不是 0**）：

```cobol
           MOVE 10 TO WS-NUM(1).
           MOVE 50 TO WS-NUM(5).
```

> 坑：COBOL 下标从 **1** 开始。`WS-NUM(0)` 是非法/未定义。

## 2. 下标 vs 索引：两套访问机制

| | 下标（subscript） | 索引（index） |
|---|---|---|
| 声明 | 普通 `PIC 9` 数据项 | `OCCURS ... INDEXED BY 名` |
| 本质 | 一个整数（第几个元素） | 运行时维护的"字节偏移量"，**不是普通整数** |
| 赋值 | `MOVE 3 TO WS-I` | `SET 索引 TO 1` / `SET 索引 UP BY 1` |
| 用于 | 直接 `WS-NUM(WS-I)` | `SEARCH`/`SEARCH ALL` 必需 |
| 算术 | 普通加减 | 只能用 `SET ... UP/DOWN BY n` |

```cobol
       01 WS-SORTED.
           05 WS-ENTRY OCCURS 6 TIMES
                        INDEXED BY WS-IDX.        *> 声明索引 WS-IDX
               10 WS-EKEY PIC 9(3).
       PROCEDURE DIVISION.
           SET WS-IDX TO 1.                        *> 索引只能用 SET 赋值
           SET WS-IDX UP BY 1.                     *> 索引 +1（不是 ADD）
```

> 索引不能用 `MOVE`/`ADD`，只能用 `SET ... TO n`（设值）和 `SET ... UP/DOWN BY n`（增减）。
> 想把索引当整数用，`SET 整数项 TO 索引` 可取出它代表的序号。

## 3. 记录表：每个元素含多字段

表的元素可以是一个组项（含多个子字段），这是处理"记录数组"的标准方式：

```cobol
       01 WS-EMPLOYEES.
           05 WS-EMP OCCURS 3 TIMES.
               10 WS-EMP-NAME PIC X(8).
               10 WS-EMP-SAL  PIC 9(5).
       PROCEDURE DIVISION.
           MOVE "张三" TO WS-EMP-NAME(1).
           MOVE 5000  TO WS-EMP-SAL(1).
           DISPLAY "第2员工=[" WS-EMP-NAME(2) "]".
```

```text
第2员工=[李四  ]
  薪资=06000
```

子字段名后跟下标 `WS-EMP-NAME(2)` 访问第 2 个元素的 name。

## 4. 多维表：嵌套 OCCURS

```cobol
       01 WS-GRID.
           05 WS-ROW OCCURS 2 TIMES.
               10 WS-CELL PIC 9 OCCURS 3 TIMES.    *> 2×3 网格
       PROCEDURE DIVISION.
           MOVE 1 TO WS-CELL(1, 1).
           MOVE 9 TO WS-CELL(2, 3).
           DISPLAY "GRID(2,3)=" WS-CELL(2, 3).
```

访问用逗号分隔的多下标 `WS-CELL(行, 列)`。

## 5. 变长表：OCCURS DEPENDING ON

表的"实际元素个数"可在运行时变化（但上限固定）：

```cobol
       01 WS-VAR-TABLE.
           05 WS-COUNT   PIC 9.
           05 WS-ITEM    PIC X(4) OCCURS 1 TO 5 TIMES
                              DEPENDING ON WS-COUNT.
       PROCEDURE DIVISION.
           MOVE 3 TO WS-COUNT.        *> 设定当前实际个数为 3
```

`OCCURS 1 TO 5 TIMES DEPENDING ON WS-COUNT`：最多 5 个，实际个数由 `WS-COUNT` 决定。
改 `WS-COUNT` 就改"当前有几个元素"。常用于读入不定条数的记录。

> 坑：`WS-COUNT` 必须在表项**之前**声明，且取值要在 `1 TO 5` 范围内，否则越界。

## 6. SEARCH：线性查找

`SEARCH` 从索引当前位置开始**逐项**判断 `WHEN`，命中即停，全不中走 `AT END`：

```cobol
           SET WS-IDX TO 1.
           SEARCH WS-ENTRY
               AT END
                   DISPLAY "SEARCH 没找到"
               WHEN WS-EKEY(WS-IDX) = 40
                   DISPLAY "SEARCH 找到 40"
                   MOVE WS-EKEY(WS-IDX) TO WS-HIT
           END-SEARCH.
```

- `SEARCH` 自动推进索引，对每个元素试各 `WHEN`。
- `WHEN` 里用 `索引(WS-IDX)` 引用当前元素。
- `AT END` 是"搜到表尾都没命中"的分支。

```text
SEARCH 找到 40
```

## 7. SEARCH ALL：二分查找（要求有序 + ASCENDING KEY）

表**已按某键排序**时，`SEARCH ALL` 用二分查找，O(log n)：

```cobol
       01 WS-SORTED.
           05 WS-ENTRY OCCURS 6 TIMES
                        ASCENDING KEY WS-EKEY     *> 声明升序键
                        INDEXED BY WS-IDX.
               10 WS-EKEY PIC 9(3).
       PROCEDURE DIVISION.
           SET WS-IDX TO 1.
           SEARCH ALL WS-ENTRY
               AT END
                   DISPLAY "SEARCH ALL 没找到"
               WHEN 50 = WS-EKEY(WS-IDX)
                   DISPLAY "SEARCH ALL 找到 50"
           END-SEARCH.
```

```text
SEARCH ALL 找到 50
```

要求与坑：

- **表必须真的按 `ASCENDING KEY`（或 `DESCENDING KEY`）有序**——`SEARCH ALL` 不会帮你排序，
  数据无序则结果错误（且不报错）。
- 子句顺序：实测 GnuCOBOL 要求 **`ASCENDING KEY` 写在 `INDEXED BY` 之前**（写反报
  `INDEXED should follow ASCENDING/DESCENDING`）。
- `WHEN` 条件里把**键值写在左边**（`WHEN 50 = WS-EKEY(WS-IDX)`）是惯例，`SEARCH ALL`
  靠它做二分。
- 可以有多个 `ASCENDING KEY`/`DESCENDING KEY`（多键排序）。

## 8. 排序整张表

COBOL 没有内建的"表排序动词"对 WORKING-STORAGE 表直接排序（`SORT` 动词是给文件的，
第 11/12 章）。要给内存表排序，常见做法：

- 自己写排序（冒泡/插入），用 `PERFORM` + 下标交换；
- 或把表写进文件用 `SORT` 动词排，再读回。

> 实践中大量 COBOL 批处理就是"读文件 → 排序 → 控制断点报表"，第 17 章会串起来。

## 9. 完整实测输出

```text
下标遍历求和 = 00150
第2员工=[李四  ]
  薪资=06000
GRID(1,1)=1
GRID(2,3)=9
变长表 count=3
  item(2)=[BBBB]
SEARCH 找到 40
SEARCH ALL 找到 50
==== 08 结束 ====
```

## 10. 坑位清单（实测）

1. **下标从 1 开始**：`WS-NUM(0)` 非法。
2. **索引 ≠ 整数**：只能 `SET ... TO/UP BY/DOWN BY`，不能 `MOVE`/`ADD`；`SEARCH` 必需索引。
3. **`SEARCH ALL` 要求表已排序**：它只做二分，不排序；数据乱序则静默给错结果。
4. **子句顺序**：`ASCENDING KEY` 必须在 `INDEXED BY` 之前（GnuCOBOL 实测）。
5. **`OCCURS DEPENDING ON` 的计数控件要在表前声明**，且取值在 `1 TO n` 范围内。
6. **表元素是组项时**，子字段访问写 `子字段名(下标)`，不是 `组名(下标).子字段`。
7. **内存表没有排序动词**：要么手写排序，要么借 `SORT` 动词过一遍文件。

---
上一章：[07 循环：PERFORM](07-perform.md) ｜ 下一章：[09 子程序与 CALL](09-subprograms.md) ｜ 返回：[README](../README.md)
