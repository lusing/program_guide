# 07 · 循环：PERFORM 全形态

> 示例：[`examples/07_perform/07_perform.cob`](../examples/07_perform/07_perform.cob)
> 运行：`./run-all.sh 07`

COBOL 没有 `for`/`while`/`do` 关键字——**所有循环都用 `PERFORM`**。一个 `PERFORM` 通过
不同后缀组合，覆盖"调用子过程、固定次数、条件循环、计数循环、嵌套循环、无限循环"全部场景。
理解 PERFORM 的几种形态，就理解了 COBOL 的控制流。

## 1. PERFORM 过程名：调用段/节（不是循环）

最基础的 `PERFORM` 是"调用一个段落或节，执行完返回"——类似函数调用：

```cobol
       PROCEDURE DIVISION.
       MAIN-SECTION.
           PERFORM SHOW-BANNER.        *> 跳到 SHOW-BANNER 段执行，完了回来
           ...
       SHOW-BANNER.                    *> 段（paragraph）：A 区，名字后跟句点
           DISPLAY "--- PERFORM 段调用 ---".
```

- 段名（paragraph）写在 **A 区**，名字后跟句点。
- `PERFORM 段名` 执行该段直到遇到下一段名或 `EXIT`，然后返回继续。
- `PERFORM 段A THRU 段B`：执行从段 A 到段 B 的连续多个段。

> 现代 COBOL 更推荐**内联 PERFORM**（见下），把循环体写在调用处，避免"跳来跳去"的
> 老式结构。但存量代码里 `PERFORM 段名` 满天飞，必须看得懂。

## 2. PERFORM n TIMES：固定次数

```cobol
           PERFORM 3 TIMES
               ADD 1 TO WS-N
           END-PERFORM.
```

内联形式：循环体写在 `PERFORM ... END-PERFORM` 之间。`3 TIMES` 可换成数据项
（`PERFORM WS-COUNT TIMES`）。

```text
PERFORM 3 TIMES 后 WS-N=003
```

## 3. PERFORM UNTIL：条件循环（while）

```cobol
           PERFORM UNTIL WS-I >= 5
               ADD WS-I TO WS-SUM
               ADD 1 TO WS-I
           END-PERFORM.
```

默认 `TEST BEFORE`：每次迭代**前**判断条件，条件为真就退出（等价 `while (!cond)`）。

```text
0+1+2+3+4 = 00010
```

## 4. PERFORM ... TEST AFTER：至少执行一次（do-while）

```cobol
           PERFORM TEST AFTER UNTIL WS-I > 0
               ADD 1 TO WS-I
           END-PERFORM.
```

**`TEST AFTER` 写在 `UNTIL` 之前**（这是新手常错的语序）。先执行一次循环体，再判断条件。

```text
TEST AFTER 至少跑一次，WS-I=001
```

> 实测坑：写成 `PERFORM UNTIL cond TEST AFTER` 会报 `syntax error, unexpected TEST`——
> `TEST BEFORE/AFTER` 必须紧跟 `PERFORM`，在 `UNTIL`/`VARYING` 之前。

## 5. PERFORM VARYING：计数循环（for）

```cobol
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 4
               ADD WS-I TO WS-SUM
           END-PERFORM.
```

`VARYING 变量 FROM 初值 BY 步长 UNTIL 条件`——标准 for 循环。每次迭代前更新变量并判断
`UNTIL`。步长可为负（递减循环）。

```text
VARYING 1..4 求和 = 00010
```

## 6. PERFORM VARYING ... AFTER ...：嵌套循环

`AFTER` 加内层循环变量，构成多层嵌套（外层走一步，内层走完一整轮）：

```cobol
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 2
               AFTER WS-J FROM 1 BY 1 UNTIL WS-J > 3
                   DISPLAY "  I=" WS-I " J=" WS-J
               END-PERFORM.
```

```text
  I=001 J=001
  I=001 J=002
  I=001 J=003
  I=002 J=001
  I=002 J=002
  I=002 J=003
```

`WS-I` 是外层、`WS-J` 是内层。可继续 `AFTER WS-K ...` 加第三层（但超过两层建议拆成
独立段，可读性更好）。

## 7. PERFORM 过程名 n TIMES / UNTIL：非内联

`TIMES`/`UNTIL`/`VARYING` 也能配"段名"用，循环体在别处的段里：

```cobol
           PERFORM BUMP 4 TIMES.       *> 把 BUMP 段执行 4 次
       ...
       BUMP.
           ADD 1 TO WS-N.
```

```text
PERFORM BUMP 4 TIMES 后 WS-N=004
```

## 8. PERFORM FOREVER + EXIT PERFORM：无限循环

```cobol
           PERFORM FOREVER
               ADD 1 TO WS-I
               IF WS-I >= 3
                   EXIT PERFORM
               END-IF
           END-PERFORM.
```

`FOREVER` 是无限循环，靠 `EXIT PERFORM` 手动跳出（类似 `while(true) { ... break; }`）。
事件循环、菜单循环常用。

```text
FOREVER 到 WS-I=003 退出
```

## 9. PERFORM 形态速查

| 形态 | 等价 | 用途 |
|---|---|---|
| `PERFORM 段名` | 函数调用 | 执行一段代码后返回 |
| `PERFORM 段A THRU 段B` | 调用连续多段 | 老式结构 |
| `PERFORM n TIMES ... END-PERFORM` | `for(i=0;i<n;i++)` | 固定次数 |
| `PERFORM UNTIL cond ... END-PERFORM` | `while(!cond)` | 前置条件循环 |
| `PERFORM TEST AFTER UNTIL cond` | `do{}while(!cond)` | 至少一次 |
| `PERFORM VARYING v FROM a BY s UNTIL c` | `for(v=a; !c; v+=s)` | 计数循环 |
| `PERFORM VARYING ... AFTER ...` | 嵌套 for | 多层循环 |
| `PERFORM FOREVER ... EXIT PERFORM` | `while(true){...break}` | 无限循环 |

其它退出动词：`EXIT PERFORM`（跳出当前内联循环）、`EXIT PARAGRAPH`/`EXIT SECTION`
（从段/节返回）、`EXIT PROGRAM`（结束当前程序，子程序用）。

## 10. 完整实测输出

```text
--- PERFORM 段调用 ---
PERFORM 3 TIMES 后 WS-N=003
0+1+2+3+4 = 00010
TEST AFTER 至少跑一次，WS-I=001
VARYING 1..4 求和 = 00010
  I=001 J=001
  I=001 J=002
  I=001 J=003
  I=002 J=001
  I=002 J=002
  I=002 J=003
PERFORM BUMP 4 TIMES 后 WS-N=004
FOREVER 到 WS-I=003 退出
==== 07 结束 ====
```

## 11. 坑位清单（实测）

1. **`TEST AFTER` 必须紧跟 `PERFORM`**：`PERFORM TEST AFTER UNTIL cond`，写成
   `PERFORM UNTIL cond TEST AFTER` 报 `syntax error, unexpected TEST`。
2. **COBOL 没有 for/while**：一切循环都是 `PERFORM` 的某种形态。
3. **内联 PERFORM 要配 `END-PERFORM`**；`PERFORM 段名 n TIMES` 则不要 END-PERFORM。
4. **`PERFORM UNTIL` 是"直到条件为真才停"**：循环继续的条件是 `NOT cond`，与 `while(cond)`
   方向相反，写反就死循环或一次不跑。
5. **`VARYING` 的 `UNTIL` 在每次自增后判断**：`FROM 1 BY 1 UNTIL WS-I > 4` 会跑 1,2,3,4
   四次（到 5 才停）。
6. **`EXIT PERFORM` 只跳出最内层的内联 PERFORM**。
7. **嵌套超过两层 `AFTER` 可读性差**：拆成独立段用 `PERFORM 段名` 调用。

---
上一章：[06 条件与控制流](06-control.md) ｜ 下一章：[08 表与 SEARCH](08-tables.md) ｜ 返回：[README](../README.md)
