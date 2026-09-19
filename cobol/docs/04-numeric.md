# 04 · 数值与运算

> 示例：[`examples/04_numeric/04_numeric.cob`](../examples/04_numeric/04_numeric.cob)
> 运行：`./run-all.sh 04`

COBOL 的算术有两套写法：**算术动词**（`ADD`/`SUBTRACT`/`MULTIPLY`/`DIVIDE`，英语化、
精确控制结果去向）和 **`COMPUTE`**（表达式形式，像普通语言）。两套都要会——存量代码里
算术动词更多，新写时 `COMPUTE` 更顺手。

## 1. 算术动词：TO / FROM / GIVING 的方向学

四个算术动词的核心区别是"**结果放哪、谁被修改**"，由 `TO`/`FROM`/`GIVING`/`INTO`/`BY` 决定：

| 动词 | 形式 | 含义 | 谁被改 |
|---|---|---|---|
| `ADD` | `ADD A TO B` | B = B + A | **B**（B 既是加数也是结果） |
| `ADD` | `ADD A TO B GIVING C` | C = B + A | C（A、B 不变） |
| `ADD` | `ADD A B GIVING C` | C = A + B | C |
| `SUBTRACT` | `SUBTRACT A FROM B` | B = B − A | **B** |
| `SUBTRACT` | `SUBTRACT A FROM B GIVING C` | C = B − A | C |
| `MULTIPLY` | `MULTIPLY A BY B` | B = B × A | **B** |
| `MULTIPLY` | `MULTIPLY A BY B GIVING C` | C = B × A | C |
| `DIVIDE` | `DIVIDE A INTO B` | B = B ÷ A | **B**（注意是 INTO，A 是除数） |
| `DIVIDE` | `DIVIDE A INTO B GIVING C` | C = B ÷ A | C |
| `DIVIDE` | `DIVIDE A BY B GIVING C` | C = A ÷ B | C |

> **最大的坑是 `DIVIDE ... INTO`**：`DIVIDE A INTO B` 是 `B / A`（A 是除数，B 是被除数），
> 语序和直觉相反。`DIVIDE A BY B` 才是 `A / B`。记法：**INTO 把后面那个"除进来"**。

实测（`WS-A=100.50` 起）：

```cobol
           ADD 10 TO WS-A.                          *> WS-A = 110.50
           SUBTRACT 0.50 FROM WS-A GIVING WS-RESULT. *> WS-RESULT = 110.00（WS-A 不变）
           MULTIPLY WS-A BY 2 GIVING WS-RESULT.      *> WS-RESULT = 221.00
           DIVIDE WS-B INTO WS-A GIVING WS-RESULT.   *> WS-RESULT = 110.50 / 3 = 36.83
```

```text
ADD 10 TO 100.50 => +00110.50
SUBTRACT 0.50 FROM 110.50 GIVING => +0000110.00
MULTIPLY 110 BY 2 GIVING => +0000221.00
DIVIDE 3 INTO 110.50 GIVING => +0000036.83
```

（`WS-RESULT` 是 `PIC S9(7)V99`，带符号显示前缀 `+`，整数 7 位左补零，2 位小数。）

## 2. DIVIDE 的整数商与余数：REMAINDER

`DIVIDE ... GIVING 商 REMAINDER 余` 一次拿到整数商和余数：

```cobol
           DIVIDE 7 INTO 22 GIVING WS-INT REMAINDER WS-REM.
```

```text
22 / 7 商=00003 余=00001
```

`WS-INT`、`WS-REM` 是 `PIC 9(5)`——商截断成整数（22/7=3，不是 3.14），余 1。这是 COBOL
做整除/取模的标准方式（没有 C 那样的 `%` 运算符）。

## 3. COMPUTE：表达式形式

```cobol
           COMPUTE WS-RESULT = (WS-A + WS-B) * 2 - 1.
```

支持的运算符：`+` `-` `*` `/` `**`（幂）、括号。`COMPUTE` 比算术动词灵活，适合复杂表达式。

```text
COMPUTE (110.50+3)*2-1 => +0000226.00
```

> 记住第 02 章的坑：**`DISPLAY` 不求值算术**，但 `COMPUTE` 右边是完整表达式，可以随便算。
> 要显示运算结果，先 `COMPUTE` 进数据项再 `DISPLAY`。

## 4. ROUNDED 与小数位截断

结果项的小数位由它的 `PIC` 决定。多余的小数位**默认直接截断**（不是四舍五入）；加
`ROUNDED` 才四舍五入：

```cobol
           COMPUTE WS-RESULT = 2 / 3.            *> 0.6666… 截断成 .66
           COMPUTE WS-RESULT ROUNDED = 2 / 3.    *> 四舍五入成 .67
```

```text
2/3 不 ROUNDED => +0000000.66
2/3 ROUNDED     => +0000000.67
```

> `ROUNDED` 可以加在算术动词和 `COMPUTE` 上（`ADD A TO B ROUNDED`）。**金融计算几乎总要
> `ROUNDED`**，否则截断误差会累积。存量批处理里漏 `ROUNDED` 是经典对账差异来源。

## 5. ON SIZE ERROR：溢出与除零保护

当结果装不进接收项（溢出）或除零时，触发 `ON SIZE ERROR`：

```cobol
           COMPUTE WS-BIG = 1000.         *> WS-BIG 是 PIC 9(3)，1000 装不下
           DISPLAY "9(3) 装 1000（未捕获）=> " WS-BIG.
           COMPUTE WS-BIG = 9999
               ON SIZE ERROR
                   DISPLAY "ON SIZE ERROR 命中：9999 装不进 9(3)"
           END-COMPUTE.
```

```text
9(3) 装 1000（未捕获）=> 000
ON SIZE ERROR 命中：9999 装不进 9(3)
```

- **不捕获时**，溢出的行为是实现定义的——实测把高位丢掉后得到 `000`（静默错误，最危险）。
- 加了 `ON SIZE ERROR ... END-COMPUTE`，溢出被拦截，可记录/补救。
- 算术动词也有 `ON SIZE ERROR`（`ADD A TO B ON SIZE ERROR ... END-ADD`）。
- **范围/精度检查不是默认开的**：COBOL 不像有些语言会主动报溢出，**得自己写 `ON SIZE ERROR`**。

## 6. 数值编辑 PIC：给人看的格式

`PIC` 里混入**编辑字符**就能控制显示格式（这类项是"编辑过的数值项"，只用于显示/打印，
不参与算术）：

| 编辑字符 | 作用 |
|---|---|
| `Z` | 前导零显示成空格（suppress leading zeros） |
| `*` | 前导零显示成 `*`（防篡改，支票常用） |
| `$` | 固定/浮动货币符 |
| `,` | 千分位分隔符 |
| `.` | 小数点（编辑项里要显式写） |
| `+` `-` | 显示符号 |
| `CR` `DB` | 负数显示成 `CR`（credit）/`DB`（debit） |

实测：

```cobol
       01 WS-EDIT-1     PIC ZZ,ZZ9.99.
       01 WS-EDIT-2     PIC $$$$9.99.
       01 WS-EDIT-3     PIC --,--9.99.
       01 WS-EDIT-4     PIC ZZ9.99CR.
           MOVE 1234.5  TO WS-EDIT-1.
           MOVE 1234.5  TO WS-EDIT-2.
           MOVE -1234.5 TO WS-EDIT-3.
           MOVE -12.5   TO WS-EDIT-4.
```

```text
ZZ,ZZ9.99 <= 1234.5  => [ 1,234.50]
$$$$9.99  <= 1234.5  => [$1234.50]
--,--9.99 <= -1234.5 => [-1,234.50]
ZZ9.99CR  <= -12.5   => [ 12.50CR]
```

逐个读：

- `ZZ,ZZ9.99` ← 1234.5 → ` 1,234.50`：前导零变空格、插入千分位逗号、补足 2 位小数。
- `$$$$9.99` ← 1234.5 → `$1234.50`：浮动 `$` 紧贴数字。
- `--,--9.99` ← −1234.5 → `-1,234.50`：负号浮动显示。
- `ZZ9.99CR` ← −12.5 → ` 12.50CR`：**负数**显示成 `CR`（贷方），正数则该位置是空格。

> 编辑项的字节数 = PIC 里所有字符（含编辑符）的个数。`ZZ,ZZ9.99` 共 9 个字符位。
> 编辑项**不能再参与算术**（`ADD` 到编辑项是错的）——它只是"显示快照"。

## 7. NUMVAL：把字符串转回数值

编辑是"数值→字符串"，反向用 `FUNCTION NUMVAL`：

```cobol
           COMPUTE WS-NUM = FUNCTION NUMVAL("42") + 1.   *> 43
```

（见第 05 章字符串函数、第 10 章内部函数总表。）

## 8. 坑位清单（实测）

1. **`DIVIDE A INTO B` 是 `B / A`**，语序反直觉；`DIVIDE A BY B` 才是 `A / B`。
2. **`TO`/`FROM`/`BY`/`INTO` 会就地修改操作数**，`GIVING` 才把结果写进第三项、不动操作数。
3. **小数默认截断不是四舍五入**：要 `ROUNDED`。金融计算漏 `ROUNDED` = 对账差异。
4. **溢出/除零默认静默**（实测 `9(3)` 装 1000 变 `000`）：要自己写 `ON SIZE ERROR`。
5. **编辑项不能参与算术**：`PIC Z`/`$`/`,`/`CR` 的项只用于显示，`ADD` 到它会出错。
6. **带符号数值 DISPLAY 带 `+`/`-` 前缀**（`PIC S9(7)V99` 的 110 显示 `+0000110.00`）。
7. **整除/取模用 `DIVIDE ... GIVING ... REMAINDER`**，COBOL 没有 `%` 运算符。

---
上一章：[03 数据部与 PICTURE](03-data-pic.md) ｜ 下一章：[05 字符串处理](05-strings.md) ｜ 返回：[README](../README.md)
