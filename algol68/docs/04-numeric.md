# 04 · 数值与运算：INT/REAL/LONG REAL、OVER/MOD 与取整

> 示例：[`examples/04_numeric/04_numeric.a68`](../examples/04_numeric/04_numeric.a68)
> 运行：`./run-all.sh 04`

Algol 68 的数值运算没有 COBOL 的 PIC 编辑图，也没有"接收项决定小数位"的规则——运算按
数学语义进行，**只有输出时才用 `whole`/`fixed` 决定长什么样**。本章讲三种数值模、运算符
全表、`OVER`/`MOD` 的实测陷阱、取整语义，以及溢出行为。

## 1. 三种数值模：INT / REAL / LONG REAL

```algol68
INT  a := 7, b := 2;
REAL q := a / b;                 # / 是实数除法，INT 自动升 REAL #
LONG REAL lq := 1.0 / 3.0;
print(("7 / 2      = ", fixed(q, 0, 4), new line));
print(("1.0/3.0    = ", fixed(lq, 0, 12), "  (LONG REAL)", new line));
print(("max int    = ", whole(max int, 0), new line));
```

- **`INT`**：有符号整数，**宽度随 a68g 构建而变**——实测 macOS（MacPorts）3.13.3 是 32 位
  （`max int = 2147483647`），Windows（scoop）3.13.3 是 64 位（`max int = 9223372036854775807`）。
  **别硬编码 `max int`**（示例断言只要求"至少 32 位"，见 §7）。
- **`REAL`**：双精度浮点（第 03 章）。
- **`LONG REAL`**：更高精度浮点，需要更多有效位时用（示例里保留 12 位小数）。
- **`/` 永远是实数除法**：`7 / 2 = 3.5`，两个 INT 相除自动升 REAL——想要整数商得用
  `OVER`（§3）。这和 C 的 `int / int` 截断完全相反。
- 一行声明多个同类变量：`INT a := 7, b := 2;`。

## 2. 算术运算符全表

```algol68
print(("a + b = ", whole(a + b, 0), "   a - b = ", whole(a - b, 0),
       "   a * b = ", whole(a * b, 0), new line));
print(("a OVER b = ", whole(a OVER b, 0), "  (整数商，向零截断)", new line));
print(("a MOD b  = ", whole(a MOD b, 0), "  (余数)", new line));
print(("2 ** 10  = ", whole(2 ** 10, 0), "  (幂)", new line));
print(("ABS(-8)  = ", whole(ABS(-8), 0), "  (绝对值，一元)", new line));
print(("-a       = ", whole(-a, 0), "  (取负，一元减)", new line));
```

| 运算符 | 含义 | 实测（a=7, b=2） |
|---|---|---|
| `+` `-` `*` | 加减乘 | `9`、`5`、`14` |
| `/` | 实数除法（INT 自动升 REAL） | `7 / 2 = 3.5000` |
| `OVER` | 整数商（向零截断） | `7 OVER 2 = 3` |
| `MOD` | 余数 | `7 MOD 2 = 1` |
| `**` | 幂 | `2 ** 10 = 1024` |
| `ABS x` | 绝对值（一元） | `ABS(-8) = 8` |
| `-x` | 取负（一元减） | `-a = -7` |

## 3. OVER 与 MOD 的语义不一致（实测坑）★

正数上 `OVER`/`MOD` 符合直觉，负数上二者**不是同一套取整方向**：

```algol68
# OVER 向零截断：-7 OVER 2 = -3；但 MOD 返回「非负余数」：-7 MOD 2 = 1。 #
# 二者不满足 a = (a OVER b)*b + (a MOD b)：(-3)*2 + 1 = -5 ≠ -7。 #
print(("-7 OVER 2 = ", whole(-7 OVER 2, 0), "   -7 MOD 2 = ", whole(-7 MOD 2, 0), new line));
INT flq := ENTIER(-7.0 / 2.0);          # floor 商 = -4 #
INT flr := -7 - flq * 2;                # 自洽余数 = 1 #
assert(flq * 2 + flr = -7, "floor 商余自洽");
```

实测输出：

```text
-7 OVER 2 = -3   -7 MOD 2 = 1
floor 商 = -4  自洽余 = 1  验证 flq*2+flr = -7
```

- `OVER` 向零截断（`-7 OVER 2 = -3`），`MOD` 却给**非负余数**（`-7 MOD 2 = 1`）。
- 于是恒等式 `a = (a OVER b)*b + (a MOD b)` 对负数**不成立**：`(-3)*2 + 1 = -5 ≠ -7`。
- 要自洽的"商 + 余"，自己用 floor 算：**商 = `ENTIER(a/b)`，余 = `a - 商*b`**（示例给出
  完整写法并断言 `flq*2 + flr = -7`）。

## 4. 取整：ENTIER 是 floor，ROUND 四舍五入

```algol68
# 坑：ENTIER 不是「向零截断」！ENTIER(-3.7) = -4（往下），不是 -3。 #
print(("ENTIER(3.9)  = ", whole(ENTIER(3.9), 0), new line));
print(("ENTIER(-3.7) = ", whole(ENTIER(-3.7), 0), "  (向下取整，非向零)", new line));
print(("ROUND(3.5)   = ", whole(ROUND(3.5), 0), new line));
print(("ROUND(-3.5)  = ", whole(ROUND(-3.5), 0), new line));
```

| 调用 | 结果 | 语义 |
|---|---|---|
| `ENTIER(3.9)` | `3` | 向下取整（floor）：正数上看着像"向零截断" |
| `ENTIER(-3.7)` | `-4` | 负数上暴露真身：floor 是往**更小**方向，不是往零 |
| `ROUND(3.5)` | `4` | 四舍五入 |
| `ROUND(-3.5)` | `-4` | 实测 `.5` 时远离零取整 |

## 5. ELEM：标准里有，a68g 3.13.3 没声明（实测）

Algol 68 修订报告的 prelude 里有一元运算符 `ELEM`（`ELEM e` = 10 的 e 次幂，用于十进制
指数刻度）。但本机实测 a68g 3.13.3 **没有声明它**：

```text
a68g: error: 1: monadic operator "ELEM" INT has not been declared, ...
```

需要这个语义时自己一行补上（实测可用）：

```algol68
PROC elem = (INT e) REAL: 10.0 ** e;    # elem(3) → 1000.0；elem(-2) → .0100 #
```

## 6. 关系与数学函数

```algol68
print(("sqrt(16) = ", fixed(sqrt(16.0), 0, 2), new line));
print(("exp(1)   = ", fixed(exp(1.0), 0, 5), new line));
print(("ln(e)    = ", fixed(ln(exp(1.0)), 0, 5), new line));
print(("sin(0)   = ", fixed(sin(0.0), 0, 3), "  cos(0) = ", fixed(cos(0.0), 0, 3), new line));
print(("SIGN(-4) = ", whole(SIGN(-4), 0), "  ODD(3) = ", ODD(3), new line));
assert(sqrt(16.0) = 4.0, "sqrt(16)=4");
assert(ABS(sin(0.0)) < 1.0e-12, "sin(0)≈0");
```

- prelude 直接给 `sqrt`、`exp`、`ln`（自然对数）、`sin`、`cos`，参数/结果是 REAL。
- `SIGN(-4) = -1`（符号函数，产出 INT）；`ODD(3)` 产出 **BOOL**，直接 print 打成 `T`。
- 浮点比较别用 `=` 硬碰：示例断言 `ABS(sin(0.0)) < 1.0e-12`（`1.0e-12` 是 REAL 科学
  记数字面量）。

## 7. 溢出是运行时错误，不是静默回绕 ★

```algol68
# 实测：max int + 1 直接 abort —— 「INT value overflow, result too large」。 #
# 好处是不会悄悄算错；坏处是生产代码要先判界。这里只做边界断言，不真的触发。 #
# 坑：INT 宽度随 a68g 构建而变，勿硬编码——macOS(MacPorts) 3.13.3 是 32 位 #
#      (2147483647)，Windows(scoop) 3.13.3 是 64 位 (9223372036854775807)。 #
assert(max int >= 2147483647, "INT 至少 32 位（宽度随构建平台而变，勿硬编码）");
assert(max int - 1 < max int, "接近上界仍单调");
```

与 COBOL"溢出默认静默截断"相反：a68g 的 INT 溢出是**运行时错误**，进程直接中止（本机
实测退出码 1，stderr 报 `INT value overflow, result too large`）。好处是永远不会悄悄算
错；代价是生产代码在可能越界处要先判界。示例因此只做边界断言，不真的触发溢出。

## 8. 增量赋值：+:= -:= *:=

```algol68
INT acc := 0;
acc +:= 10; acc -:= 3; acc *:= 2;
print(("acc 经 +10 -3 *2 = ", whole(acc, 0), new line));   # (0+10-3)*2 = 14 #
```

`x +:= y` 即 `x := x + y`，另有 `-:=`、`*:=`。**坑：INT 没有 `/:=`**——因为 `/` 是实数
除法，INT `/` INT 的结果是 REAL，塞不回 INT，所以 prelude 干脆不为 INT 声明它。实测也
**没有 `OVER:=`**（`syntax error`）——要整数"除赋"就老实写 `x := x OVER y`。

## 9. whole / fixed：数值转字符串与精度

数值本身没有"显示格式"，格式化发生在转字符串这一步：

```algol68
whole(n, w)          # INT → 右对齐、宽 w 的十进制串；w = 0 表示最短 #
fixed(x, before, after)   # REAL → 定点串：整数部至少 before 位、小数 after 位（四舍五入） #
```

- `whole(sum, 0)` 得到紧凑的 `"3"`；不转直接 print INT 会得到宽格式 `+3`（第 02 章）。
- `fixed(q, 0, 4)` 把 `3.5` 打成 `3.5000`；`fixed(lq, 0, 12)` 打出 LONG REAL 的 12 位
  小数。
- **`after` 位就是舍入发生的地方**：`fixed(3.14159, 0, 4)` → `3.1416`（四舍五入，第 02 章）。
- **绝对值小于 1 时 `fixed` 省略前导零**：实测打出 `.333333333333`、`.000`、`.0100`，
  不是 `0.333...`——做报表对齐时要留意。

## 10. 实测输出（本机 a68g 3.13.3）

`./run-all.sh 04` 中 check 通道的真实 stdout（release 通道逐字节一致；有 C 后端的构建上）：

```text
7 / 2      = 3.5000
1.0/3.0    = .333333333333  (LONG REAL)
max int    = 2147483647
a + b = 9   a - b = 5   a * b = 14
a OVER b = 3  (整数商，向零截断)
a MOD b  = 1  (余数)
2 ** 10  = 1024  (幂)
ABS(-8)  = 8  (绝对值，一元)
-a       = -7  (取负，一元减)
ENTIER(3.9)  = 3
ENTIER(-3.7) = -4  (向下取整，非向零)
ROUND(3.5)   = 4
ROUND(-3.5)  = -4
-7 OVER 2 = -3   -7 MOD 2 = 1
floor 商 = -4  自洽余 = 1  验证 flq*2+flr = -7
sqrt(16) = 4.00
exp(1)   = 2.71828
ln(e)    = 1.00000
sin(0)   = .000  cos(0) = 1.000
SIGN(-4) = -1  ODD(3) = T
提示：INT 溢出在 a68g 里会运行时报错并退出，而非静默回绕
acc 经 +10 -3 *2 = 14
==== 04 结束 ====
自检全部通过
```

挑要紧的行解释：

| 输出 | 为什么长这样 |
|---|---|
| `7 / 2 = 3.5000` | `/` 是实数除法，INT 自动升 REAL；`fixed(q, 0, 4)` 补满 4 位小数 |
| `.333333333333` | LONG REAL 保留 12 位小数；`fixed` 对 <1 的值**省略前导零** |
| `max int = 2147483647` | macOS 构建的 INT 是 32 位（2^31 − 1）；**Windows 构建此行是 64 位的 `9223372036854775807`**——宽度随构建变 |
| `-7 OVER 2 = -3   -7 MOD 2 = 1` | OVER 向零截断、MOD 给非负余数——二者方向不一致（§3） |
| `floor 商 = -4 ... flq*2+flr = -7` | 用 `ENTIER(-7.0/2.0)` 自算 floor 商，恒等式恢复成立 |
| `ENTIER(-3.7) = -4` | ENTIER 是 floor 不是截断：往更小方向取整 |
| `ROUND(-3.5) = -4` | 实测 `.5` 时远离零取整（`ROUND(3.5) = 4` 对称） |
| `sin(0) = .000` | `fixed(sin(0.0), 0, 3)`：又是省略前导零的 `.000` |
| `ODD(3) = T` | `ODD` 产出 BOOL，直接 print 打成 `T` |
| `acc 经 +10 -3 *2 = 14` | `(0+10-3)*2`：`+:= -:= *:=` 按书写顺序就地累积 |

## 11. 坑位清单（实测）

1. **`/` 永远是实数除法**：`7 / 2 = 3.5`，没有 C 式整数截断；整数商用 `OVER`。
2. **OVER 与 MOD 语义不一致**：`-7 OVER 2 = -3`（向零）而 `-7 MOD 2 = 1`（非负余），
   `a = (a OVER b)*b + (a MOD b)` 对负数不成立；自洽商余用 `ENTIER(a/b)` 自己算。
3. **ENTIER 是 floor 不是向零截断**：`ENTIER(-3.7) = -4`；四舍五入用 `ROUND`
   （`ROUND(-3.5) = -4`）。
4. **INT 溢出直接运行时中止**：`INT value overflow, result too large`、退出码 1，不会
   静默回绕；可能越界处要先判界。
5. **ELEM 在 a68g 3.13.3 未声明**：标准 prelude 的 `ELEM`（10^e）会报
   `monadic operator "ELEM" INT has not been declared`；用 `10.0 ** e` 自建。
6. **INT 没有 `/:=`**：INT/INT 升 REAL，塞不回 INT；只有 `+:=`、`-:=`、`*:=`。
7. **`fixed` 省略 <1 数值的前导零**：`.333333333333`、`.000`——报表对齐要自己补 `0`。
8. **浮点断言别用 `=` 硬碰**：示例用 `ABS(sin(0.0)) < 1.0e-12` 的容差写法。

---
上一章：[03 模式系统](03-modes.md) ｜ 下一章：[05 条件与控制流](05-control.md) ｜ 返回：[README](../README.md)
