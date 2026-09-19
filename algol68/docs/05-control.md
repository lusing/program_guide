# 05 · 条件与控制流

> 示例：[`examples/05_control/05_control.a68`](../examples/05_control/05_control.a68)
> 运行：`./run-all.sh 05`

Algol 68 的分支只有两个核心构造：`IF` 和 `CASE`。但它和 C/Java/Python 有一个根本差别——
**分支本身是「单元（unit）」，是有值的表达式**，可以直接赋给变量、当作过程的返回值。本章把
`IF/ELIF/ELSE/FI`、`CASE/IN/OUT/ESAC`、关系与逻辑运算符、以及它们的优先级一次讲透。

## 1. 封闭子句：关键字成对回文（本章的"骨架"知识）

Algol 68 用**成对的关键字**把一块结构括起来，而且首尾关键字互为回文，读代码时一眼能配对：

| 开始 | 结束 | 用途 |
|---|---|---|
| `BEGIN` | `END` | 封闭子句（一段带局部声明的代码块） |
| `IF` | `FI` | 条件分支（`FI` 是 `IF` 倒过来写） |
| `CASE` | `ESAC` | 多路分支（`ESAC` 是 `CASE` 倒过来写） |
| `DO` | `OD` | 循环体（第 06 章；`OD` 是 `DO` 倒过来写） |
| `(` | `)` | 括号也是封闭子句 |

> 没有 C 那样的花括号 `{}`，也没有 Python 那样的缩进强制。结构完全靠这对关键字界定，
> 分号 `;` 用来分隔同一层里的多个单元。

我们的示例整体就是一个 `BEGIN ... END` 封闭子句：

```algol68
BEGIN
  INT fails := 0;
  PROC assert = (BOOL cond, STRING msg) VOID:
    IF NOT cond THEN put(stand error, ("FAIL: ", msg, new line)); fails +:= 1 FI;
  # ... 正文 ... #
END
```

## 2. IF / THEN / ELIF / ELSE / FI

多路"否则如果"用 **`ELIF`**（不是 `ELSEIF`，也不是 `ELSIF`），一个 `IF` 里可以写任意多个：

```algol68
PROC classify = (INT x) STRING:
  IF   x > 10 THEN "big"
  ELIF x > 3  THEN "mid"
  ELIF x > 0  THEN "small"
  ELSE             "non-positive"
  FI;
```

- 从上往下判断，命中**第一个**为真的 `THEN` 分支就取那个分支的值，其余不再看（不贯穿）。
- `ELSE` 可选，是兜底分支；`FI` 必须写，标志整个 `IF` 结束。
- 每个分支这里都是一个 `STRING` 字面量——因为 `IF` 有值，分支产出什么类型，`IF` 就是什么类型。

调用与实测：

```algol68
print(("classify(15) = ", classify(15), new line));   # big #
print(("classify(-2) = ", classify(-2), new line));   # non-positive #
```

## 3. IF 是「单元」：它有值，能直接赋值、能当返回值

这是 Algol 68 新手最反直觉、也最强大的一点：**`IF ... FI` 整体是一个有值的表达式**。

```algol68
INT n := 7;
STRING parity := IF ODD n THEN "odd" ELSE "even" FI;
print(("parity of 7 = ", parity, new line));          # odd #
```

- `ODD n` 是单目运算符，判断 `n` 是否奇数（产出 `BOOL`）。
- 整个 `IF ... FI` 产出 `"odd"` 或 `"even"`，直接赋给 `parity`——不需要临时变量。

同理，上面 §2 的 `PROC classify` **没有 `RETURN` 语句**：封闭子句里**最后一个单元的值**就是
过程的返回值，而那个最后的单元正是 `IF ... FI`。这就是 Algol 68 表达"函数返回分支结果"的惯用法。

> 布尔值直接 `print` 出来是 `T` / `F`（不是 `true` / `false`），见 §8 实测输出。

## 4. CASE ... IN ... OUT ... ESAC：按「第几个」匹配，不是按字面量！

`CASE` 是多路分支，但它**和 C 的 `switch` 完全不同**，这是本章最大的坑：

```algol68
PROC name_of = (INT k) STRING:
  CASE k IN
    "one",                    # k = 1 #
    "two",                    # k = 2 #
    "three"                   # k = 3 #
  OUT "many"                  # 其余 #
  ESAC;
```

- `CASE k IN A, B, C OUT D ESAC` 的含义是：**按 `k` 的整数值选「第几个」分支**——
  `k=1` 选 `A`，`k=2` 选 `B`，`k=3` 选 `C`；`k` 落在 `1..分支数` 之外时选 `OUT` 的兜底分支 `D`。
- 它**不是**"找到值等于 `k` 的那个标签"。`IN` 后面用**逗号**分隔各分支，`OUT` 是兜底。
- 因此 `CASE` 只接受 `INT` 选择子，且分支是**位置敏感**的：调换顺序就调换了匹配的值。

实测：`name_of(2)` → `two`（第 2 个分支），`name_of(9)` → `many`（9 超出 1..3，落 `OUT`）。

## 5. 关系运算符：= /= < <= > >=

六个关系运算符产出 `BOOL`：

```algol68
print(("5 = 5 : ", (5 = 5), new line));    # T #
print(("5 /= 4: ", (5 /= 4), new line));   # T，/= 是「不等于」 #
print(("3 <= 3: ", (3 <= 3), new line));   # T #
```

| 运算符 | 含义 | 备注 |
|---|---|---|
| `=` | 等于 | 单等号就是比较，赋值是 `:=` |
| `/=` | 不等于 | **不是 `!=`**，也不是 `<>` |
| `<` `<=` | 小于 / 小于等于 | |
| `>` `>=` | 大于 / 大于等于 | |

> 赋值用 `:=`，比较用 `=`，两者泾渭分明——不会像 C 那样把 `=` 误当比较。

## 6. 逻辑运算 AND / OR / NOT 与优先级

三个逻辑运算符都作用于 `BOOL`：

```algol68
BOOL t := TRUE, f := FALSE;
print(("t AND f = ", (t AND f), new line));   # F #
print(("t OR  f = ", (t OR f), new line));    # T #
print(("NOT f   = ", (NOT f), new line));     # T #
```

优先级（结合越紧越先算，均由本机 a68g 3.13.3 实测确认）：

```text
NOT（单目）  >  关系运算 = /= < <= > >=  >  AND  >  OR
```

- **`AND` 比 `OR` 结合更紧**：实测 `TRUE OR FALSE AND FALSE` 得 `T`，即先算 `FALSE AND FALSE`
  再 `OR`。要别的顺序就加括号。
- **`NOT` 比关系运算结合更紧（大坑）**：`NOT 5 = 4` 会**编译报错**——
  `monadic operator "NOT" INT has not been declared`，因为 `NOT` 先作用到整数 `5` 上。
  正确写法必须加括号：`NOT (5 = 4)`（实测得 `T`）。示例里的断言正是这么写的。
- 关系比 `AND` 结合更紧：第 06 章的 `cand > 20 AND cand MOD 7 = 0` 能正常编译并给出正确答案，
  即它被解析成 `(cand > 20) AND ((cand MOD 7) = 0)`。

> **短路求值不保证**：源码注释明确指出——`AND`/`OR` 是普通运算符，Algol 68 标准**不保证**
> "左边为假就不算右边"。别依赖短路来防错（如防除零/防越界），要防错请用嵌套 `IF`（见 §7）。

## 7. 用「守卫」替代短路，安全避免除零

既然不能靠 `AND` 短路挡除零，就把守卫写成 `IF` 的条件：

```algol68
INT denom := 0;
INT result := IF denom /= 0 THEN 100 OVER denom ELSE -1 FI;
print(("guarded 100/0 = ", whole(result, 0), "  (-1 表示被守卫拦下)", new line));
```

`denom` 为 0，条件 `denom /= 0` 为假，直接走 `ELSE` 取 `-1`，**根本不会去算 `100 OVER denom`**——
除零被 `IF` 的结构挡住，而不是靠运算符短路。这是 Algol 68 里防御式判断的标准写法。

## 8. 实测输出（本机 a68g 3.13.3）

`./run-all.sh 05` 中 check 通道的真实 stdout（release 通道 `-O2` 逐字节一致，即验证保证）：

```text
classify(15) = big
classify(5)  = mid
classify(1)  = small
classify(-2) = non-positive
parity of 7 = odd
name_of(2) = two
name_of(9) = many
5 = 5 : T
5 /= 4: T
3 <= 3: T
t AND f = F
t OR  f = T
NOT f   = T
guarded 100/0 = -1  (-1 表示被守卫拦下)
==== 05 结束 ====
自检全部通过
```

逐行要点：

| 输出 | 为什么长这样 |
|---|---|
| `classify(-2) = non-positive` | `-2` 不满足任何 `ELIF`，落 `ELSE` 兜底分支 |
| `parity of 7 = odd` | `IF ODD n THEN ... FI` 作为表达式直接赋值给 `parity` |
| `name_of(2) = two` | `CASE` 按**第 2 个分支**匹配，不是"找值等于 2 的标签" |
| `name_of(9) = many` | `9` 超出分支序号 1..3，走 `OUT` 兜底 |
| `5 = 5 : T` | `BOOL` 直接 `print` 出来是单字母 `T`/`F` |
| `guarded 100/0 = -1` | 守卫 `IF denom /= 0` 为假，走 `ELSE` 取 `-1`，未触发除零 |
| `自检全部通过` | 所有 `assert` 未累加 `fails`，退出码 0 |

## 9. 坑位清单（实测）

1. **`ELSEIF` 要写成 `ELIF`**：Algol 68 的多路"否则如果"关键字是 `ELIF`。
2. **`IF ... FI` 必须闭合**：漏 `FI` 会导致封闭子句不匹配，报语法错误。
3. **`CASE` 按位置匹配，不是按值**：`CASE k IN A,B,C OUT D ESAC` 是"k=1→A, k=2→B, k=3→C"，
   调换分支顺序就调换了匹配的整数值；`k` 超出 `1..分支数` 才走 `OUT`。
4. **不等于用 `/=`**，不是 `!=` 也不是 `<>`；赋值用 `:=`，比较用 `=`。
5. **`NOT` 比关系运算结合更紧**：`NOT 5 = 4` **编译报错**（`NOT` 作用到 INT 5）；
   必须写 `NOT (5 = 4)`。
6. **`AND` 比 `OR` 结合更紧**：`TRUE OR FALSE AND FALSE` 得 `T`；要别的顺序加括号。
7. **不要依赖短路**：标准不保证 `AND`/`OR` 短路；防除零/越界请用嵌套 `IF` 守卫（§7）。
8. **过程无 `RETURN`**：封闭子句最后一个单元的值即返回值，`IF ... FI` 常充当这个"最后单元"。

---
上一章：[04 数值与运算](04-numeric.md) ｜ 下一章：[06 循环](06-loops.md) ｜ 返回：[README](../README.md)
