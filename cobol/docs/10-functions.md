# 10 · 内部函数（FUNCTION）

> 示例：[`examples/10_functions/10_functions.cob`](../examples/10_functions/10_functions.cob)
> 运行：`./run-all.sh 10`

`FUNCTION` 是 COBOL 的内置函数库，分**数值、字符串、日期时间、金融、序号**几大类。调用形式
`FUNCTION 名(参数, ...)`，可直接用在 `COMPUTE`、`MOVE`、`IF` 等需要值的地方。本章按类挑代表
演示，并钉死几个"反直觉"的实测行为。

## 1. 数值函数

```cobol
           COMPUTE WS-I = FUNCTION ABS(-5).        *> 绝对值
           COMPUTE WS-R = FUNCTION SQRT(16).       *> 平方根
           COMPUTE WS-I = FUNCTION INTEGER(3.7).   *> 取整（向零截断）
           COMPUTE WS-I = FUNCTION REM(10, 3).     *> 余数（符号随被除数）
           COMPUTE WS-I = FUNCTION MOD(-10, 3).    *> 模（符号随除数）
           COMPUTE WS-I = FUNCTION MAX(3, 9, 2).   *> 最大值（可变参数）
           COMPUTE WS-I = FUNCTION MIN(3, 9, 2).   *> 最小值
           COMPUTE WS-I = FUNCTION SUM(1, 2, 3, 4).*> 求和
           COMPUTE WS-R = FUNCTION MEAN(1, 2, 3, 4).   *> 算术平均
           COMPUTE WS-R = FUNCTION MEDIAN(5, 1, 3).    *> 中位数
```

实测输出：

```text
ABS(-5)        = +000005
SQRT(16)       = +000004.0000
INTEGER(3.7)   = +000003 (向零截断)
REM(10,3)      = +000001
MOD(-10,3)     = +000002 (负数与REM不同)
MAX(3,9,2)     = +000009
MIN(3,9,2)     = +000002
SUM(1,2,3,4)   = +000010
MEAN(1,2,3,4)  = +000002.5000
MEDIAN(5,1,3)  = +000003.0000
```

要点：

- **`REM` vs `MOD` 对负数不同**：`REM(-10,3)` 符号随被除数（= −1），`MOD(-10,3)` 符号随
  除数（= +2）。这是经典面试点，实测确认。
- `INTEGER(x)` 向零截断；要四舍五入用 `COMPUTE ... ROUNDED`（第 04 章）。
- `MAX`/`MIN`/`SUM`/`MEAN`/`MEDIAN` 接受可变个参数，也能接表（`FUNCTION SUM(表项(ALL))`）。
- 其它：`EXP`/`LOG`/`LOG10`、`SIN`/`COS`/`TAN`、`FACTORIAL`（注意：**`FACT` 在 3.2 未实现**，
  见坑位）、`TRUNC`、`SIGN`。

## 2. 字符串函数

```cobol
           FUNCTION UPPER-CASE("cobol")            *> "COBOL"
           FUNCTION LOWER-CASE("COBOL")            *> "cobol"
           FUNCTION REVERSE("COBOL")               *> "LOBOC"
           FUNCTION TRIM(s)                        *> 去尾随空格（s 是定长项）
           FUNCTION LENGTH(s)                      *> 字节长度
           FUNCTION SUBSTITUTE("banana","a","X")   *> 子串替换 → "bXnXnX"
           FUNCTION CONCATENATE("ab", "cd")        *> 拼接 → "abcd"
           FUNCTION NUMVAL("42")                   *> 字符串转数值
```

实测输出：

```text
UPPER-CASE     = [COBOL]
REVERSE        = [LOBOC]
SUBSTITUTE     = [bXnXnX]
CONCATENATE    = [abcd]
NUMVAL('42')   = +000042
```

- `SUBSTITUTE(源, 旧1, 新1, 旧2, 新2, ...)`：可一次替换多组子串（比 `INSPECT REPLACING`
  灵活，后者只能单字符）。
- `NUMVAL` 把数字字符串转成数值（反向"编辑"）。还有 `NUMVAL-C`（带货币符）、
  `DISPLAY-OF`/`NATIONAL-OF`（编码转换）。
- 完整字符串函数见第 05 章。

## 3. 序号函数 ORD / CHAR：1 基，不是 ASCII！

```cobol
           COMPUTE WS-I = FUNCTION ORD("A").       *> 66，不是 65！
           DISPLAY "CHAR(66) = [" FUNCTION CHAR(66) "]".     *> "A"
           DISPLAY FUNCTION CHAR(FUNCTION ORD("A")).          *> "A"（互逆）
```

实测输出：

```text
ORD('A')       = +000066 (1基，非65)
CHAR(66)       = [A]
CHAR(ORD('A')) = [A]
```

> **实测坑（反直觉）**：`ORD`/`CHAR` 用的是**程序字符集里的 1 基序号**，不是 ASCII 码。
> 字符 `'A'` 的 ASCII 是 65，但 `ORD("A")` = **66**；`CHAR(65)` 返回的是 `'@'`（ASCII 64），
> `CHAR(66)` 才回到 `'A'`。二者互逆：`CHAR(ORD(x)) = x`。别拿 `ORD` 当 ASCII 码用。

## 4. 日期时间函数

```cobol
           MOVE FUNCTION CURRENT-DATE TO WS-DATE.   *> 21 字节时间戳
```

`CURRENT-DATE` 返回 `PIC X(21)` 的时间戳，格式：

```text
YYYYMMDDhhmmss.ssss±hhmm
123456789012345678901
        ↑年月日时分秒.毫秒(4位)±时区
```

例如 `20260920003012345+0800` 表示 2026-09-20 00:30:12.345，东八区。用引用修改切出各段：
`WS-DATE(1:4)` 是年、`(5:2)` 月、`(9:4)` 是 hhmm。

其它日期函数：`FUNCTION YEAR/MONTH/DAY/...`（从整数日期取部分）、`INTEGER-OF-DATE`、
`DATE-OF-INTEGER`、`DAY-TO-YYYYDDD`、`FORMAT-TIME`、`WHEN-COMPILED`（编译时刻）。

> **实测坑（验证纪律）**：`CURRENT-DATE`/`WHEN-COMPILED` 的值**每次都变**。直接 `DISPLAY`
> 它会让 check 通道与 release 通道两次运行的输出**不一致**，破坏"双通道逐字节比对"。
> 本示例**只断言它的长度 = 21**，不打印实时值——这正是第 01 章说的"断言性质，不打印
> 环境相关的数字"。要用日期就 `MOVE` 进变量后按引用修改取段，需要可复现输出时固定一个
> 样例日期来讲，别打印活的时钟。

## 5. 金融函数（COBOL 的看家本领）

```cobol
           FUNCTION ANNUITY(利率, 期数)            *> 年金
           FUNCTION PRESENT-VALUE(利率, 现金流...) *> 现值
```

COBOL 生于金融，内置了年金/现值这类财务函数。涉及浮点，跨优化等级可能有末位差异，
打印时要 `ROUNDED` 到固定小数位以保证可复现（本教程示例未打印它们，避免浮点噪声）。

## 6. FUNCTION 能用在哪

- `COMPUTE 项 = FUNCTION ...`
- `MOVE FUNCTION ... TO 项`
- `IF FUNCTION ... > 0`
- `DISPLAY FUNCTION ...`（但注意第 02 章：DISPLAY 不求值**算术**，单个 FUNCTION 可以）

> 参数里还能嵌套 FUNCTION（`CHAR(ORD("A"))`），以及传表元素（`SUM(表(ALL))`，`ALL` 表示
> 整张表）。

## 7. 完整实测输出

```text
ABS(-5)        = +000005
SQRT(16)       = +000004.0000
INTEGER(3.7)   = +000003 (向零截断)
REM(10,3)      = +000001
MOD(-10,3)     = +000002 (负数与REM不同)
MAX(3,9,2)     = +000009
MIN(3,9,2)     = +000002
SUM(1,2,3,4)   = +000010
MEAN(1,2,3,4)  = +000002.5000
MEDIAN(5,1,3)  = +000003.0000
ORD('A')       = +000066 (1基，非65)
CHAR(66)       = [A]
CHAR(ORD('A')) = [A]
UPPER-CASE     = [COBOL]
REVERSE        = [LOBOC]
SUBSTITUTE     = [bXnXnX]
CONCATENATE    = [abcd]
NUMVAL('42')   = +000042
CURRENT-DATE 长度 = 021（格式 YYYYMMDDhhmmss.ssss±hhmm）
==== 10 结束 ====
```

## 8. 坑位清单（实测）

1. **`ORD`/`CHAR` 是 1 基序号，不是 ASCII**：`ORD("A")=66`、`CHAR(65)="@"`、`CHAR(66)="A"`。
2. **`REM` 与 `MOD` 对负数结果不同**：`REM(-10,3)=-1`、`MOD(-10,3)=2`。
3. **`FACT` 在 GnuCOBOL 3.2 未实现**（`FUNCTION 'FACT' unknown`）；阶乘要自己写循环。
4. **`CURRENT-DATE`/`WHEN-COMPILED` 值每次都变**：别直接打印，否则双通道输出不一致——
   只断言长度/格式，或 `MOVE` 进变量后切段使用。
5. **`DISPLAY` 不求值算术，但单个 FUNCTION 可以显示**；要显示"函数 + 运算"先 `COMPUTE`。
6. **`SUBSTITUTE` 做子串替换**，`INSPECT REPLACING` 只能单字符替换——别混用。
7. **金融/浮点函数跨优化等级可能有末位差**：打印前 `ROUNDED` 到固定小数位。

---
上一章：[09 子程序与 CALL](09-subprograms.md) ｜ 下一章：[11 文件 I：顺序文件](11-files-seq.md) ｜ 返回：[README](../README.md)
