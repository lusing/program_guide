# 08 · 运算符与优先级

> 示例：[`examples/08_operators/08_operators.a68`](../examples/08_operators/08_operators.a68)
> 运行：`./run-all.sh 08`

Algol 68 的运算符体系是它最独特的设计之一：**运算符本质上就是"带符号名的过程"**。
内置的 `+` `*` `<` 是预定义好的运算符，而你可以用 `PRIO` + `OP` 声明全新的运算符，
也可以为自己定义的新模（MODE）"重载"已有的 `+` `*`。本章按示例逐节展开。

## 1. 双目与单目：两类内置运算符

- **双目（dyadic）**：吃两个操作数，写在中间，如 `a * b`、`x < y`。
- **单目（monadic）**：吃一个操作数，写在前面，如 `-x`、`ABS x`、`NOT b`。

示例里两类都自定义了一遍（§5、§6）。单目运算符**绑得比所有双目运算符都紧**，
实测 `-3 ** 2` 得 `9`（即 `(-3) ** 2`，单目 `-` 先于 `**` 结合）。

## 2. 算术与整数运算

```algol68
print((whole(17 OVER 5, 0), " ", whole(17 MOD 5, 0), new line))   # 实测：3 2
```

| 运算符 | 含义 | 实测例 |
|---|---|---|
| `+` `-` `*` `/` | 四则（`/` 对 INT 得 REAL） | `2 + 3 * 4` = `14` |
| `OVER` | 整除（商） | `17 OVER 5` = `3` |
| `MOD` | 取余 | `17 MOD 5` = `2` |
| `**` | 幂 | `2 ** 3` = `8` |
| `-` `+`（单目） | 取负 / 恒等 | `- 5 + 3` = `-2` |
| `ABS` `SIGN` | 绝对值 / 符号 | `ABS (-5)` = `5` |
| `ENTIER` `ROUND` | REAL 向下取整 / 四舍五入成 INT | `ENTIER 3.7` = `3`，`ROUND 3.5` = `4` |

示例里大量使用 `whole(x, 0)`：把 INT 转成**最紧凑**的字符串（宽度 0），避免默认打印
的宽格式（见第 10 章）。

## 3. 关系运算与 BOOL 逻辑

关系运算符 `=` `/=` `<` `<=` `>` `>=` 对数值和 STRING 都有效（实测 `"abc" < "abd"` 为
`TRUE`，按字典序）。BOOL 上用 `AND` `OR` `NOT`：

```algol68
print((NOT TRUE AND TRUE, new line))          # 实测 F：NOT 先于 AND 结合
print((FALSE AND TRUE OR TRUE, new line))     # 实测 T：AND 先于 OR 结合
```

> **实测注意**：修订报告里 BOOL/BITS 是"集合"，有 `I`（交）与 `E`（属于）运算；但
> a68g 3.13.3 上 `TRUE I TRUE` 报 `dyadic operator BOOL "I" BOOL has not been declared`，
> `TRUE E TRUE` 报 `tag "E" has not been declared properly`——**这两个运算符默认未声明**。
> 位运算请对 BITS 用 `AND` `OR` `XOR` `NOT`，集合差与补用 `-` 和 `~`（实测可用）。

## 4. 赋值类运算符：`:=` 与它的家族

```algol68
INT x := 10;        # 声明并初始化（示例第 3 行就是这么写的）
x +:= 5;            # x = x + 5
x -:= 3;            # x = x - 3
x *:= 2;            # x = x * 2
REAL y := 7.0; y /:= 2;         # y = y / 2，实测 3.5
STRING s := "ab"; s +:= "cd";   # 对 STRING，+:= 是拼接，实测 "abcd"
```

示例第 5 行的断言过程里就有 `fails +:= 1`——失败计数原地累加。

> **实测边界**：a68g 3.13.3 声明的赋值类运算符只有 `:=` `+:=` `-:=` `*:=` `/:=`。
> `OVER:=`、`MOD:=`、`%:=`、`**:=`、`AND:=`、`OR:=` 一律语法错误
> （如 `x OVER:= 5` 报 `incorrect sentence`）。想要就写全 `x := x OVER 5`。

## 5. 优先级（priorities）：`PRIO` 只能是 1..9

双目运算符的优先级是一个 1..9 的整数，数字越大绑得越紧。示例注释点明了内置值：
`*` 是 7，`+` 是 6。实测链条（从紧到松）：

```text
单目（最紧） >  **  >  * / OVER MOD  >  + -  >  关系 = /= < ...  >  AND  >  OR  >  := +:=（最松）
```

证据都是实测：`2 + 3 * 4` = 14（`*` 紧于 `+`）；`1 + 2 < 4` = TRUE（`+` 紧于关系）；
`NOT TRUE AND TRUE` = FALSE（单目紧于 AND）；`-3 ** 2` = 9（单目紧于 `**`）。

自定义运算符**必须先 `PRIO` 再 `OP`**——只写 `OP` 实测报：

```text
a68g: syntax error: 1: "PLUSTWICE" has no priority declaration.
```

而 `PRIO TENOP = 10` 实测报 `invalid priority declaration`：**优先级只能是 1..9**。

## 6. 自定义双目运算符：`PRIO DOT = 7; OP DOT = ...`

示例 8.1 定义了一个"点乘加一"运算符：

```algol68
PRIO DOT = 7;
OP DOT = (INT a, b) INT: a * b + 1;
print(("3 DOT 4 = ", whole(3 DOT 4, 0), "  (定义为 a*b+1)", new line));
assert(3 DOT 4 = 13, "DOT 自定义运算");
```

运算符名的规则（示例注释 + 本机实测）：

- 可用**大写字母串**（upper-stropping 下如 `DOT`、`PLUSTWICE`），也可用符号
  `% & ! ? ^ ~` 及多字符符号如 `<>` `==` `**`——实测 `PRIO <> = 7; OP <> = ...` 可用。
- **`$` 和 `|` 不行**：它们是 transput/格式专用符号。实测 `OP $ = ...` 报
  `encountered format-a-frame in this line ...`，`PRIO | = 5` 报 `"END" expected`。
- 运算符名**不能含空格**：实测 `OP PLUS AB = ...` 报 `tag "PLUS" has not been declared
  properly`（过程名反而可以含空格，见第 09 章）。

优先级如何影响解析，示例 8.3 给了个"比 `+` 还松"的算符：

```algol68
PRIO PLUSTWICE = 5;                # 比 + (6) 还低
OP PLUSTWICE = (INT a, b) INT: a + b + b;
print(("2 PLUSTWICE 3 = ", whole(2 PLUSTWICE 3, 0), "  (a+b+b)", new line));
assert(2 PLUSTWICE 3 = 8, "低优先级自定义算符");
```

`PRIO` 定"什么时候轮到我算"，`OP` 定"算出什么"——两条声明各司其职。

## 7. 自定义单目运算符：优先级要给高

示例 8.2 定义平方算符 `SQ`：

```algol68
PRIO SQ = 9;                       # 一元运算符优先级要高（绑得紧）
OP SQ = (INT a) INT: a * a;
print(("SQ 5 = ", whole(SQ 5, 0), new line));
assert(SQ 5 = 25, "一元平方");
```

`OP SQ = (INT a) INT: ...` 的参数表只有**一个**形参——这就是"单目"的全部秘密：
双目写两个形参，单目写一个，`a SQ` 还是 `a SQ b` 由形参个数决定。

## 8. 为新模"重载"已有运算符

Algol 68 没有专门的"运算符重载"语法——`OP +` 本来就允许针对新模再声明一遍。
示例 8.4 给二维向量加上 `+` 和标量 `*`：

```algol68
MODE VEC = STRUCT(INT x, y);
OP + = (VEC a, b) VEC: (x OF a + x OF b, y OF a + y OF b);
OP * = (INT k, VEC v) VEC: (k * x OF v, k * y OF v);
VEC v1 := (1, 2), v2 := (3, 4);
VEC sum := v1 + v2;
VEC scaled := 3 * v1;
```

注意重载 `+` 时**不需要也不能写 `PRIO`**——它沿用内置 `+` 已有的优先级。
实测输出 `v1 + v2 = (4,6)`、`3 * v1 = (3,6)`，与手算一致。

## 9. 运算符就是过程：`OP` 体里委托给 `PROC`

示例 8.5 把同一个实现既做成过程又做成运算符：

```algol68
PROC dot_impl = (INT a, b) INT: a * b + 1;
PRIO DOTP = 7;
OP DOTP = (INT a, b) INT: dot_impl(a, b);   # 运算符体里调用普通过程
assert(3 DOTP 4 = dot_impl(3, 4), "运算符与过程同源");
```

实测 `3 DOTP 4 = 13   dot_impl(3,4) = 13`——两条路径同一个值。这印证了本章开头：
运算符只是"名字长成符号/大写词"的过程（第 09 章细讲过程本身）。

## 10. 坑（实测）：重定义已有运算符时，体里别再用同名运算符

示例 8.6 的注释记录了一个真实崩溃：

```algol68
# 例如 OP ** = (INT a,b) REAL: a ** b; —— 体里的 a**b 又调用自己，
# 实测直接 stack overflow（无限递归）。要复用旧语义请先存进过程或换名。
```

重载后的 `**` 在**自己的体里**也指向新实现，于是 `a ** b` 无限自我调用直到
stack overflow。想包一层旧语义，先把旧实现存进一个 `PROC`（如 §9 的 `dot_impl`
模式），或者干脆给新行为换个名字（如 `DOTP`）。

## 11. 实测输出（本机 a68g 3.13.3）

`./run-all.sh 08` 双通道运行：check 通道 `a68g --warnings --notices`（解释器，
全运行时检查），release 通道 `a68g -O2`（编译到 C 后端），两通道 stdout 要求
**逐字节一致**，且退出码 0、stderr 为空、输出含结束标记。check 通道真实 stdout：

```text
3 DOT 4 = 13  (定义为 a*b+1)
SQ 5 = 25
2 PLUSTWICE 3 = 8  (a+b+b)
v1 + v2 = (4,6)
3 * v1  = (3,6)
3 DOTP 4 = 13   dot_impl(3,4) = 13
提示：重载 ** 却在体里写 a ** b 会无限递归 → stack overflow
==== 08 结束 ====
自检全部通过
```

| 输出行 | 为什么长这样 |
|---|---|
| `3 DOT 4 = 13` | `DOT` 定义为 `a*b+1`：`3*4+1 = 13` |
| `SQ 5 = 25` | 单目 `SQ` 即 `a*a` |
| `2 PLUSTWICE 3 = 8` | `a+b+b` = `2+3+3 = 8` |
| `v1 + v2 = (4,6)` | 重载的 `+` 按字段相加：`(1+3, 2+4)` |
| `3 * v1  = (3,6)` | 重载的 `*` 是标量乘：`(3*1, 3*2)` |
| `3 DOTP 4 = 13   dot_impl(3,4) = 13` | 运算符委托给过程，两值必然相等 |
| `自检全部通过` | `fails = 0`：全部 `assert` 通过；有失败会打到 stderr 且非 0 退出 |

## 12. 坑位清单（实测）

1. **先 `PRIO` 后 `OP`**：只写 `OP` 报 `"XXX" has no priority declaration`。
2. **优先级只能 1..9**：`PRIO X = 10` 报 `invalid priority declaration`；单目运算符
   要绑得紧，给高值（示例 `SQ` 用 9）。
3. **`$` 和 `|` 不能当运算符**：transput/格式专用，实测直接语法错误。
4. **运算符名不能含空格**：`OP PLUS AB` 报 `tag "PLUS" has not been declared properly`。
5. **重载体的无限递归**：`OP ** = ... a ** b` 会 stack overflow——旧语义先存进 PROC
   或改用新名字（§10）。
6. **`I` / `E` / `U` 未声明**：a68g 3.13.3 对 BOOL/BITS 直接用会报错；位运算用
   `AND` `OR` `XOR` `NOT`，差与补用 `-` `~`（§3）。
7. **赋值类运算符只有 5 个**：`:=` `+:=` `-:=` `*:=` `/:=`；`OVER:=` `MOD:=` `**:=`
   等实测都是语法错误（§4）。
8. **重载 `+`/`*` 给新模时别再写 `PRIO`**：沿用内置优先级即可（§8）。

---
上一章：[07 字符串处理](07-strings.md) ｜ 下一章：[09 过程](09-procedures.md) ｜ 返回：[README](../README.md)
