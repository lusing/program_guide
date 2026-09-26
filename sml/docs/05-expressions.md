# 05 · 表达式与运算符

> 对应示例：`examples/03-expressions.sml`


## 5.1 优先级表（从高到低）

| 优先级 | 运算符 |
|---|---|
| 最高 | `~`（一元取负）、函数应用 |
| 9 | `*` `/` `div` `mod` `quot` `rem` |
| 8 | `+` `-` `^` |
| 7 | `::` `@` |
| 6 | `=` `<>` `<` `>` `<=` `>=` |
| 4 | `:=`（赋值） |
| 3 | `o`（组合） |
| 2 | `andalso` |
| 1 | `orelse` |
| 最低 | `handle`、`raise`、`if`/`case`/`fn` |

两条要记住：

- **`o` 的优先级比 `=` 低**，所以 `f o g x = y` 会被解析成 `f o (g x = y)` —— 类型错。要写 `f (g x) = y` 或者 `(f o g) x = y`。
- **`o` 是 infix 的关键字级运算符，不能当变量名。** `val o = TextIO.openOut path` 会报：

```
Error: expression or pattern begins with infix identifier "o"
```

本书第 22 章写 `writeOne` 时又踩了一次，改成 `out` 才好。**变量名不要用 `o`。**

## 5.2 两种整数除法

```sml
val _ = 7 div 3        (* 2  向负无穷取整 *)
val _ = 7 mod 3        (* 1  *)
val _ = Int.quot (7, 3)   (* 2  向零取整 *)
val _ = Int.rem (7, 3)    (* 1  *)
```

**`div` / `mod` 是关键字，`quot` / `rem` 不是** —— 后者必须带结构名前缀。负数上两者不同：

```sml
~7 div 3          (* ~3：向负无穷 *)
Int.quot (~7, 3)  (* ~2：向零 *)
```

`div` 和 `mod` 满足 `(a div b) * b + (a mod b) = a`，符号跟着 `b` 走。

## 5.3 实数除法与浮点比较

`/` 永远返回 `real`，即使两边都是整数：

```sml
val _ = print (Real.fmt (StringCvt.FIX (SOME 6)) (7.0 / 2.0))   (* 3.500000 *)
```

因为 `real` 不是相等类型，浮点比较只能靠 `<` `<=` `>` `>=` 和 `Real.==` / `Real.compare`。

**要判断两个浮点数「几乎相等」**，自己写：

```sml
fun almostEq (a : real, b : real, eps : real) = abs (a - b) < eps
```

本书第 20 章打印浮点差值时用了另一个办法：**别打印 17 位有效数字**，因为 `FIX (SOME 17)` 三家不一致。改成打印到小数点后 6 位，或者用 `SCI (SOME 3)` 打印量级：

```sml
val _ = print (Real.fmt (StringCvt.SCI (SOME 3)) 1.95e~14)   (* 1.95E~14 *)
```

注意 SML 的指数记法用 `E~14`（`~` 而不是 `-`），三家一致。

## 5.4 andalso / orelse：真的短路

```sml
fun isPositive (a, b) = b <> 0 andalso a div b > 0
```

和 C 的 `&&` / `||` 一样是短路的，但它们是**语法**不是函数 —— 这正是短路能成立的原因（函数参数会先被求值）。交换律不成立：

```sml
b <> 0 andalso a div b > 0     (* 安全 *)
a div b > 0 andalso b <> 0     (* 抛 Div *)
```

## 5.5 if 是表达式，不是语句

```sml
val sign = if n < 0 then ~1 else if n = 0 then 0 else 1
```

`then` 和 `else` 两个分支**必须同类型**，而且 `else` 不能省。没有「只做副作用的 if」，要那个就用 `if ... then ... else ()`。

`if` 也是表达式，所以可以嵌在任何位置。

## 5.6 `;` 序列

```sml
val _ = (print "a"; print "b"; print "c")
```

`e1; e2; e3` 要求 `e1`、`e2` 的类型是 `unit`（除了最后一个）。整个表达式的值就是 `e3` 的值。

## 5.7 case 与 order

`case` 是表达式，可以嵌在任意位置：

```sml
fun orderName ord =
    case ord of
        LESS => "LESS"
      | EQUAL => "EQUAL"
      | GREATER => "GREATER"
```

**注意参数名别用 `o`**（又是那个坑）。上面的 `ord` 是安全的。

`order` 是 Basis 里的普通 `datatype`（`LESS | EQUAL | GREATER`），`Int.compare`、`String.compare` 都返回它。所以 SML 里排序/查找的比较函数通常写成：

```sml
val cmp : int * int -> order = Int.compare
```

## 5.8 本章示例的其余内容

- `abs`、`min`、`max` 是重载的，会在 `int` 和 `real` 之间按上下文选。
- `^` 只能拼字符串，不能拼字符 —— 单个字符先 `String.str` 或 `Char.toString`。
- `<>` 是不等号，不是 `!=`。

---
