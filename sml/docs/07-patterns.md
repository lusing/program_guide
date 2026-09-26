# 07 · 模式匹配

> 对应示例：`examples/05-patterns.sml`


模式匹配是 SML 的核心机制。它出现在四个地方：`fun` 的参数、`case`、`val`、`fn`。

## 7.1 六种基本模式

```sml
(* 1) 通配：不要的值 *)
fun firstOf (x, _) = x

(* 2) 字面量：精确匹配常量 *)
fun isZero 0 = true
  | isZero _ = false

(* 3) 构造子：解出内容 *)
fun optOr (SOME v, _) = v
  | optOr (NONE, d) = d

(* 4) 列表：空表与 cons *)
fun len [] = 0
  | len (_ :: rest) = 1 + len rest

(* 5) as 模式：既解构又留住整体 *)
fun headTail (all as (x :: _)) = (x, all)

(* 6) 变量：绑定 *)
fun id x = x
```

一个模式里可以混合使用：

```sml
fun depth ({name = n, children = kids, ...} : node) = 1 + foldl (fn (k, m) => Int.max (depth k, m)) 0 kids
```

## 7.2 顺序至关重要

`case` / 多子句 `fun` 是**从上往下**试的，第一个匹配的赢。所以：

```sml
(* 错的：通配在最前面会吃掉一切 *)
fun bad _ = "any"
  | bad 0 = "zero"        (* 永远到不了，编译器还会警告 redundant *)

(* 对的：特例在前 *)
fun good 0 = "zero"
  | good _ = "any"
```

## 7.3 穷尽性：只是警告，但值得当错误

```sml
fun lastOf [] = raise Empty
  | lastOf [x] = x
  | lastOf (_ :: rest) = lastOf rest
```

如果写成：

```sml
fun lastOf [x] = x
  | lastOf (_ :: rest) = lastOf rest     (* 漏了 [] *)
```

三家都会警告 `Matches are not exhaustive`，但**只有 MLton 把它送到 stderr**，另两家送到 stdout。而且退出码不受影响。

本书的验证脚本把这条警告**当成失败**，理由很直接：非穷尽匹配迟早会在运行期变成 `Match` 异常，那是 bug，不该被「只是警告」放过。

**写 `case` 的标准做法**：如果你确信某个分支不可能，用 `raise` 或 `Fail` 显式表示，而不是省掉它：

```sml
case !pos of
    NUM v :: rest => (pos := rest; v)
  | _ => raise Fail "unreachable"
```

## 7.4 `val` 模式与 `fn` 模式

```sml
val (q, r) = (17, 5)              (* 元组解构 *)
val {name, age} = record          (* 记录解构 *)
val x :: xs = list                (* 列表解构；不匹配会抛 Bind *)

val add = fn (a, b) => a + b      (* fn 也带模式 *)
```

`fn` 可以写多子句：

```sml
val classify = fn 0 => "zero"
                 | _ => "nonzero"
```

但 `val` 模式的匹配失败是**运行时异常 `Bind`**，不是编译期检查。所以 `val x :: xs = ...` 要确保真的非空。

## 7.5 记录模式里的 `...` 与嵌套

```sml
fun area ({w, h, ...} : {w : int, h : int, label : string}) = w * h
```

嵌套模式可以直接嵌：

```sml
fun originOf ({pos = (x, y), ...} : {pos : int * int, tag : string}) = (x, y)
```

## 7.6 模式不能做的事

- **不能在模式里做运算**。`fun f (x + 1) = ...` 是错的，模式里只能有构造子、字面量、变量、通配。想判断「是不是偶数」得用 `if` 或 guard 式写法。
- **不能用同一个变量匹配两个位置再看相等**。`fun eq (x, x) = true` 是错的（`x` 会被当成两个不同的绑定）。

想要「等式约束」，只能显式写条件：

```sml
fun same (a, b) = a = b
```

---
