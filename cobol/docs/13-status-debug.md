# 13 · 状态码、异常处理与调试

> 示例：[`examples/13_status/`](../examples/13_status/)
> 运行：`./run-all.sh 13`

前两章的文件操作处处依赖 `FILE STATUS`。本章把 COBOL 的**错误处理三件套**讲全：

1. **FILE STATUS 解码**——两位码怎么读、怎么在正确时机抓快照；
2. **DECLARATIVES**——集中式（全局）错误处理，类似别的语言的 try/catch 拦截器；
3. **内联条件处理**——`AT END` / `INVALID KEY` / `ON SIZE ERROR` / `ON EXCEPTION`，
   写在语句里的"就地"异常分支；
4. **调试手段**——第 7 列 `D` 调试行、`-fdebugging-line`、`cobc -g` + GDB。

## 1. FILE STATUS：两位码的结构

`FILE STATUS` 变量是 `PIC XX`（两位字符）。**首位是类别，次位是具体原因**：

| 首位 | 类别 | 含义 |
|---|---|---|
| `0` | 成功 | `00` 正常完成 |
| `1` | EOF / 边界 | `10` 文件尾；`14` 相对记录号越界 |
| `2` | 键错误 | `21` 顺序违规、`22` 键重复、`23` 记录未找到、`24` 键边界 |
| `3` | 永久错误 | `30` I/O 失败、`35` 文件不存在、`37` 模式不允许 |
| `4` | 逻辑错误 | `41` 已关闭、`42` 未打开、`43` 未先 READ、`47`/`48` 模式冲突 |
| `9` | 实现相关 | 厂商/后端特定码（BDB 的底层错误常落这里） |

解码就是把两位拆开看：

```cobol
           MOVE DATA-STATUS(1:1) TO WS-CAT.     * 首位：类别
           MOVE DATA-STATUS(2:1) TO WS-SPEC.    * 次位：具体
           DISPLAY "status=[" DATA-STATUS "] 类别=" WS-CAT
               " 具体=" WS-SPEC.
```

实测输出（`10` = 类别 1 的 EOF）：

```text
status=[10] 类别=1 具体=0 (1x=EOF/边界类)
```

## 2. 抓状态码的时机（本章第一个实测坑）

> **`FILE STATUS` 在【每次】文件操作后被覆写。** 想断言某一步的码，必须当场把它
> `MOVE` 进一个快照变量，否则下一个操作（哪怕是 `CLOSE`）就把它冲掉了。

我在写示例时连踩两次：

- **EOF 的 `10` 被 `CLOSE` 冲成 `00`**：`READ` 到文件尾时状态是 `10`，但紧接着的
  `CLOSE DATA-FILE` 把它改成 `00`。想显示/断言 EOF 的 `10`，要在 `CLOSE` **之前**抓：

  ```cobol
           PERFORM UNTIL WS-EOF = 1
               READ DATA-FILE AT END MOVE 1 TO WS-EOF ...
           END-PERFORM.
           MOVE DATA-STATUS TO WS-EOF-STATUS.   * ← CLOSE 之前抓快照
           CLOSE DATA-FILE.
           DISPLAY "EOF status=" WS-EOF-STATUS.  * 显示 10
  ```

- **`OPEN` 缺失文件的 `35` 被 `CLOSE` 冲成 `42`**：`OPEN INPUT` 一个不存在的文件得 `35`，
  但随后 `CLOSE`（对一个没打开成功的文件）又把它改成 `42`。同样要在 `CLOSE` 前抓 `35`。

实测输出印证了这两点：

```text
读回条数=02 EOF status=10
  [declarative] MISS-FILE status=35
OPEN 缺失文件 status=35 (35)
  [declarative] MISS-FILE status=42
declarative 触发次数=2
```

## 3. DECLARATIVES：集中式错误处理

`DECLARATIVES` 是 `PROCEDURE DIVISION` 开头的特殊段，用 `USE` 声明"当某类情况发生时，
自动跳到这个段"。相当于给文件或调试事件装一个**全局拦截器**：

```cobol
       PROCEDURE DIVISION.
       DECLARATIVES.
       MISS-ERR-SECTION SECTION.
           USE AFTER STANDARD ERROR PROCEDURE ON MISS-FILE.
      *  MISS-FILE 上任何"标准错误"处理后，自动跳到这里
           ADD 1 TO WS-DECL-FIRED.
           DISPLAY "  [declarative] MISS-FILE status=" MISS-STATUS.
       END DECLARATIVES.
       MAIN-SECTION SECTION.
           ...
```

`USE` 的几种形式：

| 形式 | 触发时机 |
|---|---|
| `USE AFTER STANDARD ERROR PROCEDURE ON 文件` | 该文件发生错误（status 非 00）后 |
| `USE AFTER STANDARD ERROR PROCEDURE` | 任何文件错误后（全局，不指定文件） |
| `USE BEFORE REPORTING` | 报表写入前（Report Writer 用） |
| `USE FOR DEBUGGING ON 标识符` | 调试：监视某标识符每次被修改（配合 `-fdebugging-line`） |

> **坑（实测）：`USE AFTER STANDARD ERROR PROCEDURE ON 文件` 会对【每一次】错误触发，
> 包括你以为无害的 `CLOSE`。** 本例里 `OPEN INPUT` 缺失文件触发一次（status 35），
> 随后 `CLOSE` 一个没打开成功的文件又触发一次（status 42）——所以 `WS-DECL-FIRED` 最终是
> **2**，不是 1。写断言时若预期"只触发一次"就会挂。示例里特意显式 `CLOSE` 并断言
> `WS-DECL-FIRED >= 1`，让两次触发都落在结束标记之前，输出对两通道确定。

`DECLARATIVES` 的价值：把散落在各处的文件错误处理**收敛到一个段**，避免每条语句后面都跟
一段 `IF status NOT = "00"`。大程序里它是错误处理的主干。

## 4. 内联条件处理：写在语句里的异常分支

不想用全局拦截器时，COBOL 的每条"可能出错"的语句都支持**就地**的异常短语：

| 语句 | 异常短语 | 触发条件 |
|---|---|---|
| `READ` | `AT END` / `NOT AT END` | 到文件尾 / 读到记录 |
| `READ`（索引/相对） | `INVALID KEY` / `NOT INVALID KEY` | 键不存在 / 命中 |
| `WRITE`/`REWRITE`（索引） | `INVALID KEY` | 键重复等 |
| `COMPUTE`/`ADD`/... | `ON SIZE ERROR` / `NOT ON SIZE ERROR` | 结果溢出接收字段 |
| `STRING`/`UNSTRING` | `ON OVERFLOW` | 目标放不下 |
| `CALL` | `ON EXCEPTION` / `NOT ON EXCEPTION` | 被调程序找不到等 |
| `DISPLAY`/`ACCEPT` | `ON EXCEPTION` | 底层 I/O 异常 |

### ON SIZE ERROR 实测

把一个超出容量的值 `COMPUTE` 进小字段，会走 `ON SIZE ERROR` 分支而非静默截断：

```cobol
           MOVE 0 TO WS-SIZE-ERR.
           COMPUTE WS-SMALL = 9999          * WS-SMALL 是 PIC 9(2)，装不下 9999
               ON SIZE ERROR MOVE 1 TO WS-SIZE-ERR
           END-COMPUTE.
```

实测输出：

```text
9999 存入 PIC 9(2)：ON SIZE ERROR 触发=1 值=00
```

`ON SIZE ERROR` 触发（标志置 1），目标字段 `WS-SMALL` 保持原值 `00`——**溢出不静默截断，
而是走异常分支**，这是 COBOL 数值安全的关键机制（第 4 章也提过）。

> 注意：`ON SIZE ERROR` 只在**检查通道**（`-Wall` 默认带尺寸检查语义）与运行期都生效；
> 但**是否触发**取决于运行时值，与优化等级无关——所以 check/release 两通道输出一致。

## 5. 调试手段

### 5.1 第 7 列 `D`：调试行

在**第 7 列**写 `D`（debugging indicator）的行，默认被编译器**整行忽略**；只有加
`-fdebugging-line` 开关时才编进程序。用来放"只在调试时想看"的 `DISPLAY`：

```cobol
      D    DISPLAY "  [debug-line] 只在 -fdebugging-line 下出现".
```

实测对比：

```text
# 默认（D 行不编入）
WS-N=05
==== dprobe end ====

# cobc -x -fdebugging-line（D 行编入）
WS-N=05
D-line: debug-line-active
==== dprobe end ====
```

> **本仓库验证脚本【不】开 `-fdebugging-line`**，所以示例里的 `D` 行在 check/release
> 两通道都不出现——这正是它不影响输出一致性的原因。`D` 行是"编译期开关控制的日志"，
> 比运行期 `IF debug-flag` 更彻底（不编入 = 零运行开销）。

### 5.2 `cobc -g` + GDB

GnuCOBOL 编译到 C，所以能用标准 C 调试器。`cobc -g -x prog.cob` 产出带调试信息的可执行
文件，`gdb ./prog` 后可以断点、单步、看变量。但**符号是 C 层的**（COBOL 段名/数据项会
映射成 C 标识符），体验不如原生调试器。实战中更多人靠 `DISPLAY` 打点 + `D` 调试行。

### 5.3 `CALL "C$..."` 运行时工具

GnuCOBOL 运行时提供一批 `C$` 开头的工具子程序，如 `C$TRACE`（打印调用栈）、
`C$COPY`（文件操作）、`C$GETENV`（读环境变量）等。调试时 `CALL "C$TRACE"` 能快速看清
调用链。详见 GnuCOBOL 运行时库文档。

## 6. 坑位清单（实测）

1. **`FILE STATUS` 每次操作后被覆写**：断言某步的码必须当场 `MOVE` 进快照变量，
   否则被下一步（尤其 `CLOSE`）冲掉。EOF 的 `10` 和 OPEN 缺失的 `35` 都极易被 `CLOSE` 冲没。
2. **`USE AFTER STANDARD ERROR ... ON 文件` 对每次错误都触发**，含 `CLOSE` 一个未成功打开
   的文件（42）。预期触发次数时要把这类"二次触发"算进去。
3. **`ON SIZE ERROR` 不静默截断**：溢出走异常分支、目标保持原值——别假设"大数塞小字段会
   取模/截断"。
4. **`D` 调试行默认不编入**，只有 `-fdebugging-line` 才生效；忘了开开关会以为"代码没执行"。
5. **`DECLARATIVES` 段必须在 `PROCEDURE DIVISION` 最前**、`END DECLARATIVES` 收口，
   且每个 `USE` 段是独立 `SECTION`。
6. **索引/相对文件的 `INVALID KEY` 与顺序文件的 `AT END` 是两套短语**：随机读键不存在用
   `INVALID KEY`（status 23），顺序读到尾用 `AT END`（status 10），别混。

---
上一章：[12 文件 II：相对与索引文件](12-files-isam.md) ｜ 下一章：[14 结构化编程与文本复用](14-structured.md) ｜ 返回：[README](../README.md)
