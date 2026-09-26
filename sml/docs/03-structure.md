# 03 · 程序结构与求值

> 对应示例：`examples/01-basics.sml`


## 3.1 一个 SML 程序长什么样

SML 没有 `main`。一个「程序」就是一串**声明**，从上到下依次求值。「输出」靠副作用（`print`）产生。

```sml
(* 一个最小的 SML 程序 *)
val _ = print "hello, sml\n"
```

`val _ = e` 的意思是「求值 `e`，把结果丢掉」。`_` 是通配模式。凡是要产生副作用又不需要留名字的地方，都这么写。

`print` 的类型是 `string -> unit`。它**不是**多态的，也不是 `println` 的近亲 —— SML 里没有「自动 toString」。

## 3.2 val 与 fun：唯一的两种「定义」

```sml
val x = 3 + 4                  (* 值绑定 *)
val name = "sml"               (* 类型由字面量推出 *)
val pi : real = 3.14159265358979   (* 显式标注 *)

fun square n = n * n           (* 函数绑定，等价于 val square = fn n => n * n *)
val cube = fn n => n * n * n   (* 匿名函数绑到名字上，和 fun 等价 *)
```

`fun` 只是 `val` + `fn` 的语法糖，但它多支持一件事：**多子句模式匹配**。

```sml
fun fact 0 = 1
  | fact n = n * fact (n - 1)   (* 两个子句用 | 分隔 *)
```

这比手写 `case` 好读得多，也是 SML 代码的主力写法。

## 3.3 类型推断：能省就省，该写就写

```sml
val a = 1 + 2            (* int *)
val b = 1.0 + 2.0        (* real *)
val c = "a" ^ "b"        (* string *)
val d = [1, 2, 3]        (* int list *)
val e = (1, "two")       (* int * string *)
```

REPL 里的 `val x = ... : int` 那行类型，就是推断的结果。类型推断是全局的：如果 `f` 在别处被当成 `int -> int` 用，那么 `fun f x = x + 1` 这里的 `+` 就会被定格成整数加法。

**推断不出来时必须标注**。最典型的是重载字面量：

```sml
(* 这一行会报错：operator and operand do not agree *)
val big = 1.0E16 + 1.0 - 1.0E16    (* 合法，因为有 .0 定住了 real *)
val zero = fn () => 0.0            (* 合法 *)
```

以及涉及抽象类型的时候 —— 第 15 章会看到，`fun add (a : real, b : real) = a + b` 里那两个标注是**必须的**。

## 3.4 求值顺序

同一个 `let` 里的绑定按书写顺序求值；函数参数**从左到右**求值；`;` 序列按顺序求值。SML 保证这些，所以有副作用的代码行为可预期。

```sml
val _ = (print "a"; print "b"; print "c")   (* 一定输出 abc *)
```

但注意：**不要依赖「列表元素的求值顺序」**之类没被规范保证的东西。要确定顺序就显式写 `;`。

## 3.5 注释可以嵌套

```sml
(*
   外层注释
   (* 里层注释：C / Java 都不支持这样写 *)
   里层结束
   外层继续
*)
```

这是 SML 的一个亮点：想临时注释掉一大段代码，里面已经有 `(* *)` 也不会坏事。

**代价是必须配平。** 漏一个 `*)` 会让后面整段源码被吞进注释，编译器报错的位置离真正的问题十万八千里。本书的 `check-literals.py` 会顺手检查配平：

```
$ python3 check-literals.py examples/01-basics.sml
字面量检查通过：1 个文件里没有非 ASCII 字符串
```

不配平时：

```
examples/xx.sml: 注释没有配平（读到文件末尾时嵌套深度是 1）
```

## 3.6 声明在「顶格的新行」处结束

这是 SML 语法里最容易咬人的一条。看这段：

```sml
fun safeDiv (a, b) =
    if b = 0 then raise Div
    else a div b
handle Div => 0          (* 错！handle 顶格了 *)
```

SML 的解析器在看到**顶格的新行**时会认为「上一个声明结束了」，于是 `handle Div => 0` 被当成新的声明开头，报出：

```
syntax error: inserting LET
```

正确写法是把 `handle` 缩进，或者用括号把它和表达式绑在一起：

```sml
fun safeDiv (a, b) =
    (if b = 0 then raise Div else a div b)
    handle Div => 0
```

同理适用于 `andalso` / `orelse` / `|` 这些续行。**规则很简单：续行不要顶格。**

## 3.7 打印实数：别用 Real.toString

```sml
val _ = print (Real.toString 1.0)
```

三家输出：

| 实现 | 输出 |
|---|---|
| SML/NJ | `1` |
| Poly/ML | `1.0` |
| MLton | `1` |

整值实数带不带 `.0` 是**实现自由**的。要跨实现一致，用 `Real.fmt` 配 `StringCvt.FIX`：

```sml
val _ = print (Real.fmt (StringCvt.FIX (SOME 2)) 3.14159265358979)
(* 3.14 —— 三家完全一致 *)
```

位数在 **1..16** 之间时三家一致；`FIX (SOME 0)` 在恰好 `.5` 的时候会分叉（第 33 章有表）。

## 3.8 本章示例的骨架

`examples/01-basics.sml` 把这些东西串了一遍，每个示例文件的骨架都是这样：

```sml
(* 文件头：准确的编译/运行命令 + 本节讲什么 *)

fun say s = print (s ^ "\n")    (* 每个示例自带这个，保证可以单独运行 *)

(* ---- 1) 子标题 ---- *)
... 代码 ...
val _ = say ("1) 结果 = " ^ Int.toString 结果)

(* ---- 2) ... ---- *)

val _ = say "==== 01 \231\187\147\230\157\159 ===="
```

三个约定值得说明：

- **`fun say s = print (s ^ "\n")`**：`print` 不带换行，每次手写 `^ "\n"` 太啰嗦。
- **每个子标题都用 `say` 打印一行**：这样输出本身就是可读的，而不是一堆裸数字。
- **最后一行打印结束标记**：这是验证脚本判定的核心依据。

---
