# 05 · 字符串处理 ⭐

> 示例：[`examples/05_strings/05_strings.cob`](../examples/05_strings/05_strings.cob)
> 运行：`./run-all.sh 05`

COBOL 没有"字符串类型"——字符串就是**定长的 `PIC X(n)` 字节数组**，右侧补空格。所有
字符串操作都围绕这个事实展开：拼接、拆分、查找、替换全是"按字节搬运"。这是 COBOL 字符串
的深水区，也是新手最容易翻车的地方。

## 1. 定长与补空格：一切的前提

```cobol
       01 WS-WORD  PIC X(12) VALUE "COBOL".   *> 实际存 "COBOL" + 7 个空格
```

```text
WORD=[COBOL       ]
```

`PIC X(12)` 永远占 12 字节，`"COBOL"`（5 字节）后面补 7 个空格。**没有"实际长度"概念**——
长度信息不在数据里，得靠 `FUNCTION TRIM` 或自己算。这跟 C 的 `\0` 结尾、Pascal 的长度字节
都不同。

## 2. 引用修改（Reference Modification）：按字节切片

`项(起始:长度)` 取出/写入子串，**起始与长度都按字节**：

```cobol
           DISPLAY "WORD(1:3)=[" WS-WORD(1:3) "]".   *> 取第 1 字节起、3 个字节
           MOVE "G" TO WS-WORD(1:1).                 *> 只改第 1 个字节
```

```text
WORD(1:3)=[COB]
改首字母后 WORD=[GOBOL       ]
```

- 起始位置从 **1** 开始（不是 0）。
- 长度可省：`WS-WORD(4:)` 表示"从第 4 字节到末尾"。
- **中文硬坑**（见第 03 章）：`WS-CN(1:3)` 取 3 个字节 = 一个汉字；`(1:2)` 会切到半个
  汉字 → 乱码。多字节文本切片必须按 3 的倍数对齐。

## 3. STRING：拼接

```cobol
           MOVE SPACES TO WS-FULL.
           MOVE 1 TO WS-PTR.
           STRING WS-LAST  DELIMITED BY SIZE
                  WS-FIRST DELIMITED BY SIZE
                  INTO WS-FULL WITH POINTER WS-PTR.
```

`STRING` 把多个"发送项"依次拼进接收项。关键在 `DELIMITED BY`：

| 形式 | 含义 | 对定长项的效果 |
|---|---|---|
| `DELIMITED BY SIZE` | 取**整个定长**（含尾随空格） | `"三丰"`(X(10)) → 拼进 10 字节（带 7 个空格） |
| `DELIMITED BY SPACE` | 取到**第一个空格**为止 | 只拼有效内容 `"三丰"` |
| `DELIMITED BY "字面量"` | 取到指定分隔符为止 | 自定义截断 |

`WITH POINTER WS-PTR`：`WS-PTR` 指定从接收项的第几字节开始写，写完后 `WS-PTR` 自动前进
（可连续多次 STRING 拼到同一缓冲）。`WS-PTR` 必须先初始化为 1。

实测（`WS-LAST="三丰"` X(10)、`WS-FIRST="张"` X(10)，都用 `BY SIZE`）：

```text
STRING 拼接 => [三丰    张                 ]
```

> **大坑**：`DELIMITED BY SIZE` 把 `WS-LAST` 的尾随空格也拼了进去（`三丰` 后跟一串空格），
> 再接 `张`。想紧凑拼接要用 `DELIMITED BY SPACE` 或先 `FUNCTION TRIM`。本示例**故意**用
> `BY SIZE` 来暴露这个坑——这是 COBOL 字符串最经典的翻车点。

## 4. UNSTRING：拆分

`STRING` 的逆操作，按分隔符把一串拆成多个接收项：

```cobol
       01 WS-CSV  PIC X(30) VALUE "red,green,blue".
           UNSTRING WS-CSV DELIMITED BY ","
               INTO WS-C1 WS-C2 WS-C3
               TALLYING IN WS-TALLY.
```

```text
拆分 => [red       ][green     ][blue      ] 段数=03
```

- `DELIMITED BY ","`：以逗号为分隔符。可写多个 `DELIMITED BY`（`ALL` 前缀处理连续分隔符）。
- `INTO` 后跟一串接收项，依次填入各段（每段仍按各自 PIC 定长补空格）。
- `TALLYING IN WS-TALLY`：把拆出的段数记进 `WS-TALLY`。
- 还可 `WITH POINTER`（指定起点）、`ON OVERFLOW`（接收项不够时触发）。

## 5. INSPECT：计数、替换、转换

`INSPECT` 在一个字符串里**计数**或**替换**字符，是 COBOL 的"查找替换"主力：

```cobol
       01 WS-TEXT  PIC X(30) VALUE "banana".
       01 WS-REP   PIC X(10) VALUE "abcabc".
           INSPECT WS-TEXT TALLYING WS-CNT FOR ALL "a".       *> 数 a 的个数
           INSPECT WS-REP  REPLACING ALL "a" BY "X".          *> a→X
           INSPECT WS-REP  CONVERTING "Xb" TO "Yz".           *> 逐字符映射
```

```text
'banana' 里 a 的个数=003
REPLACING a->X => [XbcXbc    ]
CONVERTING Xb->Yz => [YzcYzc    ]
```

三种形态：

| 形态 | 作用 |
|---|---|
| `TALLYING 计数项 FOR ALL/LEADING/CHARACTERS ...` | 计数：`ALL "a"` 所有 a；`LEADING` 只数前导；`CHARACTERS` 数字符总数 |
| `REPLACING ALL/LEADING/FIRST "x" BY "y"` | 替换：把所有/前导/第一个 x 换成 y |
| `CONVERTING "abc" TO "xyz"` | **逐字符一一映射**：a→x、b→y、c→z（不是子串替换！） |
| `TALLYING ... REPLACING ...` | 组合：边数边换 |

> **`CONVERTING` 是逐字符映射，不是子串替换**。`CONVERTING "Xb" TO "Yz"` 把 `X`→`Y`、
> `b`→`z` 各自独立替换，所以 `"XbcXbc"` → `"YzcYzc"`。想做子串替换用 `REPLACING` 或
> `FUNCTION SUBSTITUTE`（第 10 章）。

## 6. 内部字符串函数

GnuCOBOL 提供一批 `FUNCTION`（完整表见第 10 章）：

```cobol
           FUNCTION TRIM(WS-WORD)          *> 去掉尾随空格："GOBOL       " → "GOBOL"
           FUNCTION UPPER-CASE("banana")   *> "BANANA"
           FUNCTION LOWER-CASE("BANANA")   *> "banana"
           FUNCTION REVERSE("COBA")        *> "ABOC"
           FUNCTION LENGTH(WS-CN)          *> 字节长度
           FUNCTION NUMVAL("42")           *> 字符串→数值
           FUNCTION CONCATENATE(a, b)      *> 拼接（等价 STRING）
           FUNCTION SUBSTITUTE(s, "a","X") *> 子串替换（等价多次 REPLACING）
```

实测：

```text
TRIM(WORD)=[GOBOL]
UPPER(banana)=[BANANA]
REVERSE(COBA)=[ABOC]
NUMVAL('42')+1=043
```

> `FUNCTION TRIM` 是处理定长字符串的救命函数——几乎所有"取出有效内容"的场景都要它。
> `TRIM(s, LEADING)` 去前导空格，`TRIM(s, BOTH)` 去两端。

## 7. 坑位清单（实测）

1. **字符串就是定长字节数组**：`PIC X(n)` 右补空格，没有"实际长度"，要用 `FUNCTION TRIM`。
2. **`STRING ... DELIMITED BY SIZE` 带尾随空格**：拼接定长项会拼进补位空格；用 `BY SPACE`
   或先 `TRIM`。
3. **引用修改/所有字符串操作按字节**：中文切片要按 3 字节对齐，否则切到半个汉字成乱码。
4. **`INSPECT CONVERTING "ab" TO "xy"` 是逐字符映射**，不是子串替换。
5. **`DISPLAY` 不求值，`STRING`/`UNSTRING`/`INSPECT` 才有这些花活**：别指望 `DISPLAY` 帮你拼接算式。
6. **`UNSTRING` 接收项也按各自 PIC 定长补空格**：拆出来的每段仍要 `TRIM` 才干净。
7. **`WS-PTR`（STRING 的 POINTER）必须先 `MOVE 1`**：否则从未定义位置开始写。

---
上一章：[04 数值与运算](04-numeric.md) ｜ 下一章：[06 条件与控制流](06-control.md) ｜ 返回：[README](../README.md)
