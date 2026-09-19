# 17 · 报表与批处理：控制break

> 示例：[`examples/17_report/`](../examples/17_report/)
> 运行：`./run-all.sh 17`

如果说文件是 COBOL 的主场，那**批处理报表**就是它的主场中的主场。整个 1960-80 年代，
企业夜里跑的就是这些：读一堆排序好的交易记录，按某个字段分组，每组打小计、末尾打总计、
每 N 行换页加页眉。这套模式有个专门的名字——**控制break（control break）**，是 COBOL
程序员的看家本领。本章用一个销售报表把它讲透。

## 1. 什么是控制break

**控制字段（control key）**是你想分组的那个字段（本例是"区域"）。数据**必须先按控制字段
排序**。程序逐条读，只要控制字段的值和上一条一样，就累加进当前组；一旦**变了**（这就是
"break"，断点），就说明上一组结束了——打印上一组的小计、重置累加器、开始新组。

```text
North / Widget  1200   ┐
North / Gadget   800   ├─ North 组，累加
North / Doohic  1500   ┘
                       ← break！区域从 North 变 South，打 North 小计 3500
South / Widget  2000   ┐
South / Gizmo    950   ┘─ South 组
                       ← break！打 South 小计 2950
West  / Gadget  1750   ─ West 组
                       ← 数据结束（尾break），打 West 小计 1750
                       ← 打总计 8200
```

三个动作构成控制break的骨架：**明细行累加 → 检测断点打小计 → 末尾收尾打总计**。

## 2. 排序是前提（不是可选项）

控制break **只在数据已按控制字段排序时才正确**。如果 North/South/North 乱序进来，
程序会把第一个 North 组和第二个 North 组当成两个不同的break，小计全错。

真实批处理里排序有两来路：

- **输入文件本就有序**（上游系统按区域导出）；
- **程序内 `SORT`**：COBOL 有内建 `SORT` 动词 + `SORT` 文件描述符，能对外部文件排序
  （底层用 `INPUT PROCEDURE`/`OUTPUT PROCEDURE` 或 `USING`/`GIVING`）。

本示例为了让焦点落在控制break逻辑上，直接在 `WORKING-STORAGE` 里装了一张**已排序的表**
（`WS-ROW OCCURS 6 TIMES`），跳过文件与排序，专注分组算法。第 8 章的表 + 本章的break
是同一套思路。

## 3. 核心状态变量

```cobol
       01 WS-PREV-REGION  PIC X(6) VALUE SPACES.   * 上一条的控制字段值
       01 WS-REG-SUBTOT   PIC 9(6) VALUE 0.        * 当前组小计累加器
       01 WS-GRAND-TOT    PIC 9(7) VALUE 0.        * 全局总计
       01 WS-LINECNT      PIC 9(2) VALUE 0.        * 当前页已打行数
       01 WS-PAGECNT      PIC 9(3) VALUE 0.        * 页号
       01 WS-PAGE-LIMIT   PIC 9(2) VALUE 4.        * 每页明细行上限
```

`WS-PREV-REGION` 是控制break的心脏——**"和上一条比"就是分组的全部秘密**。

## 4. 主循环：检测break + 换页 + 累加

```cobol
       PROCESS-ROW SECTION.
      * ① 控制字段变了 → 先给上一组打小计（break），再重置
           IF WS-REGION(WS-I) NOT = WS-PREV-REGION
               IF WS-PREV-REGION NOT = SPACES      * 跳过"第一条之前"的空break
                   PERFORM BREAK-REGION
               END-IF
               MOVE WS-REGION(WS-I) TO WS-PREV-REGION
           END-IF.
      * ② 换页：明细行超过每页上限就重开一页
           IF WS-LINECNT >= WS-PAGE-LIMIT
               PERFORM PRINT-PAGE-HEAD
           END-IF.
      * ③ 明细行 + 累加到组小计与总计
           DISPLAY "  " WS-REGION(WS-I) " / "
               WS-PRODUCT(WS-I) "  " WS-AMOUNT(WS-I).
           ADD WS-AMOUNT(WS-I) TO WS-REG-SUBTOT WS-GRAND-TOT.
           ADD 1 TO WS-LINECNT.
```

三个细节：

- **`IF WS-PREV-REGION NOT = SPACES`**：第一条记录时 `WS-PREV-REGION` 还是初始空格，
  不该触发break（否则报表开头多一个空小计）。这个"哨兵判断"是控制break的经典边角。
- **break 在累加【之前】**：检测到区域变化，先给**上一个**区域结账，再开始记新区域。
  顺序反了会把新区域的第一条算进旧区域。
- **`ADD a TO x y`**：一条 `ADD` 同时累加到组小计和总计（多目标），第 4 章讲过。

## 5. 尾break：最后一组的收尾（最容易漏的一步）

> **主循环结束后，最后一个区域的小计还没打**——因为它后面没有"下一条不同区域"来触发break。
> 必须在循环外**手动补一次** `BREAK-REGION`，否则最后一组的小计永远丢失。

```cobol
       RUN-REPORT SECTION.
           ...
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 6
               PERFORM PROCESS-ROW
           END-PERFORM.
      *  收尾：最后一个区域的小计还没打，补上（控制break 的经典"尾break"）
           PERFORM BREAK-REGION.
           DISPLAY "==============================".
           DISPLAY "总计 GRAND TOTAL = " WS-GRAND-TOT.
```

这是控制break新手最常犯的错：只写了循环内的break，忘了尾break，结果报表少一个组的小计。
**记住：N 个组需要 N 次break，循环内只触发 N-1 次，最后一次靠收尾补。**

```cobol
       BREAK-REGION SECTION.
           DISPLAY "  -- " WS-PREV-REGION " 小计 = " WS-REG-SUBTOT.
           ADD 1 TO WS-REGCNT.
           MOVE 0 TO WS-REG-SUBTOT.        * 重置累加器，为下一组准备
```

## 6. 页眉与换页计数

批处理报表要打页眉、控制每页行数。用一个行计数器 + 页计数器：

```cobol
       PRINT-PAGE-HEAD SECTION.
           ADD 1 TO WS-PAGECNT.
           DISPLAY "--- 第 " WS-PAGECNT " 页 ---".
           DISPLAY "区域/产品      金额".
           MOVE 0 TO WS-LINECNT.          * 新页，行计数清零
```

每打一条明细前检查 `WS-LINECNT >= WS-PAGE-LIMIT`，超了就 `PERFORM PRINT-PAGE-HEAD`
换新页。本例设每页 4 行，6 条明细分成 2 页。

> 真实的 COBOL 报表有更正式的 **Report Writer（`REPORT SECTION` + `REPORT` 文件）**，
> 能声明式定义页眉/页脚/控制break/分页，编译器自动生成break逻辑。但 Report Writer
> 各实现支持参差、GnuCOBOL 支持有限，实战中**手写控制break（如本例）更通用可控**，
> 也是理解报表逻辑的最佳途径。

## 7. 实测输出

`./run-all.sh 17 -v`，check/release 两通道逐字节一致：

```text
--- 第 001 页 ---
区域/产品      金额
  North  / Widget    01200
  North  / Gadget    00800
  North  / Doohic    01500
  -- North  小计 = 003500
  South  / Widget    02000
--- 第 002 页 ---
区域/产品      金额
  South  / Gizmo     00950
  -- South  小计 = 002950
  West   / Gadget    01750
  -- West   小计 = 001750
==============================
总计 GRAND TOTAL = 0008200
==== 17 结束 ====
```

对照验证：

- **North 小计 3500** = 1200+800+1500 ✓（3 条后遇到 South 触发break）
- **South 小计 2950** = 2000+950 ✓（跨页：第 1 页尾打了 Widget，第 2 页打 Gizmo 后break）
- **West 小计 1750** ✓（尾break，循环外补的那次）
- **总计 8200** = 3500+2950+1750 ✓
- **2 页**：每页上限 4 行，6 条明细 → 第 1 页 4 行、第 2 页 2 行 ✓
- **3 次区域break**：North/South/West 各一次 ✓

注意 South 组**跨页**了（Widget 在第 1 页、Gizmo 在第 2 页）——控制break的组小计
不受分页影响，`WS-REG-SUBTOT` 跨页持续累加，直到区域真正变化才结账。这正是"分组"与
"分页"两个维度正交的体现。

## 8. 坑位清单（实测）

1. **数据必须先按控制字段排序**：乱序输入会让同一组被拆成多个break，小计全错。
   真实场景用内建 `SORT` 或确保上游有序。
2. **尾break 必须手动补**：循环内只触发 N-1 次break，最后一组靠循环外再 `PERFORM`
   一次结账。漏了它就少一个组的小计——新手最常见错误。
3. **第一条的哨兵判断**：`WS-PREV-REGION` 初始为空格，要 `IF WS-PREV NOT = SPACES`
   跳过"第一条之前的空break"，否则报表开头多一个空小计。
4. **break 在累加之前**：检测到控制字段变化，先给上一组结账再记新组；顺序反了会把新组
   第一条算进旧组。
5. **`MOVE` 只能一条 `TO` 链**：`MOVE a TO b c TO d` 是语法错（实测
   `syntax error, unexpected TO`），每个源→目标各写一条 `MOVE`。
6. **分组与分页正交**：组小计累加器跨页持续，不因换页清零；换页只清 `WS-LINECNT`。

---
上一章：[16 与 C 互操作](16-c-interop.md) ｜ 下一章：[18 测试方法论](18-testing.md) ｜ 返回：[README](../README.md)
