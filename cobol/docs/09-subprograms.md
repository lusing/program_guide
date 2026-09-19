# 09 · 子程序与 CALL

> 示例：[`examples/09_subprograms/`](../examples/09_subprograms/)（一个主程序 + 两个子程序，静态链接）
> 运行：`./run-all.sh 09`

大程序要拆成多个程序单元，靠 `CALL` 互相调用。COBOL 的子程序用 **`LINKAGE SECTION`**
声明参数，调用方用 **`CALL ... USING`** 传参，参数传递方式有 **BY REFERENCE / BY CONTENT /
BY VALUE** 三种。本章把这套机制讲清，并演示如何把多个 `.cob` 静态链接成一个可执行文件。

## 1. 三个程序，一个可执行文件

本示例目录有三个源文件：

```text
examples/09_subprograms/
├── 09_subprograms.cob   PROGRAM-ID. DRIVER.    （主程序，调用方）
├── subadd.cob           PROGRAM-ID. SUBADD.     （子程序：求和+求积）
└── subinc.cob           PROGRAM-ID. SUBINC.     （子程序：把参数 +1）
```

编译时把它们一起交给 cobc，**静态链接**成一个可执行文件：

```bash
cobc -x -o driver 09_subprograms.cob subadd.cob subinc.cob
```

cobc 会把没被 `CALL` 的程序（DRIVER）当主入口，被 `CALL` 的（SUBADD/SUBINC）作为内部
程序链接进去。`CALL "SUBADD"` 在编译期就能解析到同链接单元里的 SUBADD。

> **PROGRAM-ID 是调用的钥匙**：`CALL "名字"` 里的字符串必须与被调程序的 `PROGRAM-ID`
> 一致（大小写在静态链接时不敏感，动态加载时依平台）。文件名可以随便取。

## 2. 子程序：LINKAGE SECTION 声明参数

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SUBADD.
       DATA DIVISION.
       LINKAGE SECTION.              *> 参数区：声明"外部传进来的视图"
       01 LS-A          PIC 9(3).
       01 LS-B          PIC 9(3).
       01 LS-SUM        PIC 9(4).
       01 LS-PROD       PIC 9(4).
       PROCEDURE DIVISION USING LS-A LS-B LS-SUM LS-PROD.
       SUB-MAIN.
           COMPUTE LS-SUM = LS-A + LS-B.
           COMPUTE LS-PROD = LS-A * LS-B.
           GOBACK.                   *> 返回调用方（子程序用 GOBACK，不是 STOP RUN）
```

要点：

- **`LINKAGE SECTION`** 里的数据项**不分配存储**——它们只是"调用方传进来的内存的视图"。
  所以 LINKAGE 项**不能给 `VALUE`**（没有自己的存储可初始化）。
- **`PROCEDURE DIVISION USING 参数列表`**：声明本程序接收哪些参数，顺序与调用方一致。
- **`GOBACK`**：从子程序返回调用方（`STOP RUN` 会结束整个程序，子程序里应该用 `GOBACK`）。

## 3. 调用方：CALL ... USING

```cobol
       PROCEDURE DIVISION.
           CALL "SUBADD" USING BY REFERENCE WS-A WS-B WS-SUM WS-PROD.
```

`CALL "程序名" USING 实参列表`——实参按位置对应子程序 `USING` 的形参。

## 4. 三种参数传递方式

| 方式 | 传什么 | 子程序能改实参吗 | 用途 |
|---|---|---|---|
| `BY REFERENCE`（默认） | 实参的**地址** | **能**，改动直接作用于实参 | 要回传结果（最常用） |
| `BY CONTENT` | 实参的**副本**（只读） | 不能（改的是副本） | 保护实参不被改 |
| `BY VALUE` | 实参的**值** | 不能 | 传字面量/表达式 |

实测演示（子程序 SUBINC 把参数 +1）：

```cobol
           MOVE 10 TO WS-X.
           CALL "SUBINC" USING BY REFERENCE WS-X.   *> 实参被改：10 → 11
           DISPLAY "BY REFERENCE 后 WS-X=" WS-X.
           MOVE 10 TO WS-X.
           CALL "SUBINC" USING BY CONTENT WS-X.     *> 传副本：实参不变，仍 10
           DISPLAY "BY CONTENT 后 WS-X=" WS-X.
```

```text
调用前 WS-X=010
BY REFERENCE 后 WS-X=011（改了）
BY CONTENT 后 WS-X=010（没变）
```

- **BY REFERENCE**（默认）：子程序拿到地址，`ADD 1 TO LS-N` 直接改调用方的 `WS-X`。
  要"返回结果"就靠它——把结果写进某个 BY REFERENCE 参数。
- **BY CONTENT**：传只读副本，子程序怎么改都不影响实参。
- **BY VALUE**：传值。

> **实测坑 1**：GnuCOBOL 3.2 的 `BY VALUE` 标记为 **unfinished**，编译会喷
> `-Wunfinished` 告警（破坏"stderr 为空"纪律）。本教程改用 **BY CONTENT** 演示副本语义。
>
> **实测坑 2**：`BY CONTENT` 只能写在**调用方**的 `CALL ... USING` 里，**不能**写进子程序的
> `PROCEDURE DIVISION USING`（子程序头只接受 `BY REFERENCE`/`BY VALUE`，写 `BY CONTENT`
> 报 `syntax error, unexpected CONTENT`）。子程序按"收到一个参数"处理即可，传法由调用方定。

## 5. 返回值：RETURNING 尚未实现，用参数代替

COBOL 2002+ 有 `CALL ... RETURNING 项` 取函数式返回值，但：

> **实测坑 3**：GnuCOBOL 3.2 在子程序头写 `PROCEDURE DIVISION USING ... RETURNING x` 会报
> `program RETURNING is not implemented [-Wpending]`。**要"返回值"就再开一个 BY REFERENCE
> 参数**——本示例的 SUBADD 用第 4 个参数 `LS-PROD` 把"积"回传，等价于返回值。

```cobol
      *  调用方：和写进 WS-SUM，积写进 WS-PROD（都是 BY REFERENCE 回传）
           CALL "SUBADD" USING BY REFERENCE WS-A WS-B WS-SUM WS-PROD.
```

```text
SUBADD: 7+5=0012  7*5=0035
```

## 6. ON EXCEPTION：调用出错的处理

```cobol
           CALL "NO-SUCH-PROG"
               ON EXCEPTION
                   DISPLAY "ON EXCEPTION：调不到的程序被拦截"
           END-CALL.
```

当被调程序不存在/加载失败时，`ON EXCEPTION` 分支执行。

> **实测坑 4（重要）**：GnuCOBOL 3.2 里，动态 `CALL` 一个不存在的程序失败时，
> **`ON EXCEPTION` 与 `NOT ON EXCEPTION` 两个分支会【都执行】**——这是已知怪异行为。
> 所以本示例**只写 `ON EXCEPTION` 分支**，避免打印出自相矛盾的信息。依赖 `NOT ON EXCEPTION`
> 判断"调用成功"时要当心这个坑。

```text
ON EXCEPTION：调不到的程序被拦截
```

## 7. 动态调用与 cobcrun：模块化运行

除了静态链接，COBOL 程序也能编成**共享模块**运行时动态加载：

```bash
cobc -m subadd.cob              # 编成模块（.so/.dylib/.dll），模块名 = PROGRAM-ID
COB_LIBRARY_PATH=. cobcrun driver   # cobcrun 按 PROGRAM-ID 找模块运行
```

- `cobc -m` 产出共享模块；`cobcrun 程序名` 运行它（按 PROGRAM-ID 查找）。
- `COB_LIBRARY_PATH` 指定模块搜索目录。
- `CALL "名字"` 在运行时动态解析——这是大机时代"程序分开部署、运行时拼装"的延续。

## 8. 嵌套程序与递归（了解）

- **嵌套程序**：一个程序可以写在另一个程序的 PROCEDURE DIVISION 之后（`END PROGRAM 名.`
  收尾），内层程序对外层可见。`-fnested` 相关行为依方言。
- **递归**：`PROGRAM-ID` 后加 `RECURSIVE`，程序可 `CALL` 自己。注意 WORKING-STORAGE 在
  递归中是**共享**的（要每层独立数据用 `LOCAL-STORAGE SECTION`，每次进入清零）。

## 9. 完整实测输出

```text
SUBADD: 7+5=0012  7*5=0035
调用前 WS-X=010
BY REFERENCE 后 WS-X=011（改了）
BY CONTENT 后 WS-X=010（没变）
ON EXCEPTION：调不到的程序被拦截
==== 09 结束 ====
```

## 10. 坑位清单（实测）

1. **`LINKAGE SECTION` 项不能给 `VALUE`**：它没有自己的存储，只是外部内存的视图。
2. **子程序用 `GOBACK` 返回**，不是 `STOP RUN`（后者结束整个程序）。
3. **`BY VALUE` 在 3.2 是 unfinished**，会告警；演示副本语义改用 `BY CONTENT`。
4. **`BY CONTENT` 只能写在调用方**，子程序头只认 `BY REFERENCE`/`BY VALUE`。
5. **`RETURNING` 未实现**：要返回值就再开一个 BY REFERENCE 参数。
6. **`ON EXCEPTION`/`NOT ON EXCEPTION` 在调用失败时都会执行**（3.2 怪异行为）。
7. **`CALL "名字"` 的字符串要对上 `PROGRAM-ID`**，不是文件名。
8. **递归里 WORKING-STORAGE 是共享的**：要每层独立数据用 `LOCAL-STORAGE SECTION`。

---
上一章：[08 表与 SEARCH](08-tables.md) ｜ 下一章：[10 内部函数](10-functions.md) ｜ 返回：[README](../README.md)
