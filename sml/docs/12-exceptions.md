# 12 · 异常

> 对应示例：`examples/10-exceptions.sml`


## 12.1 定义与抛出

```sml
exception BadInput
exception BadInput2 of string        (* 参数化 *)
exception ValueOutOfRange of int * int

fun parseAge (s : string) =
    case Int.fromString s of
        NONE => raise BadInput2 ("not a number: " ^ s)
      | SOME n => if n < 0 orelse n > 150 then raise ValueOutOfRange (0, 150) else n
```

异常声明可以带参数，就是一个普通的构造子。

## 12.2 捕获

```sml
fun safeParse (s : string) =
    Int.toString (parseAge s)
    handle BadInput2 msg => "bad input / " ^ msg
      | ValueOutOfRange (lo, hi) => "out of range " ^ Int.toString lo ^ "-" ^ Int.toString hi
```

三条规则：

1. **handler 的体必须和表达式同类型。** 上面的表达式是 `string`，所以每个分支都得返回 `string`。忘了会报 `expression and handler do not agree`。
2. **handler 从上往下试，第一个匹配的赢。**
3. **`handle` 的优先级很低**，只包住紧邻的那个表达式。多个语句要用括号：

```sml
(f x) handle e => (log e; raise e)     (* 括号很重要 *)
```

## 12.3 用 exnName 而不是 exnMessage

```sml
exception MyErr
val _ = print (exnName MyErr)        (* "MyErr" *)
val _ = print (exnMessage MyErr)     (* 各家不同！*)
```

实测：

| | `exnName Div` | `exnMessage Div` |
|---|---|---|
| SML/NJ | `Div` | `divide by zero` |
| Poly/ML | `Div` | `Div` |
| MLton | `Div` | — |

**`exnName` 给的是构造子名，三家一致；`exnMessage` 的文本是实现自由。** 所以：

- **做断言、做日志、做错误分派 → 用 `exnName`**
- **给用户看 → 可以 `exnMessage`，但要接受文本不一致**

本书第 23 章的测试示例就是这么做的：断言「抛出的异常叫 `Div`」，而不是「消息是什么」。

## 12.4 一个全覆盖的 exnName 包装

`exnName` 接受任意 `exn`，所以这个函数必须是**全函数**（不能假设知道所有异常）：

```sml
fun describe e =
    case e of
        Fail msg => "Fail / " ^ msg
      | Div => "Div"
      | Subscript => "Subscript"
      | Empty => "Empty"
      | _ => "other / " ^ exnName e        (* 这一分支必须有 *)
```

漏了 `_` 编译器会警告非穷尽 —— 而 `exn` 是开放类型，永远不可能穷尽。

## 12.5 重抛与日志

```sml
fun withLog f x =
    (f x) handle e => (say ("  [caught " ^ exnName e ^ "]"); raise e)
```

`handle` 里 `raise e` 就是重抛，`e` 是绑定的异常值。这是「记录一下再往上抛」的常规写法。

## 12.6 异常 vs option

两种表达失败的风格，选择标准很清楚：

| | 用 `option` | 用异常 |
|---|---|---|
| 适合 | 失败是**常见且预期**的结果（查找没找到） | 失败是**异常状况**（文件不存在、格式错） |
| 调用方 | 必须显式处理（`case`） | 可以忽略（不处理就往上冒） |
| 开销 | 无 | 有（但正常路径无开销） |
| 类型 | 写在类型里 `'a option` | **不写在类型里** |

**「调用方必须知道可能失败」就选 `option`**，因为它出现在类型里，编译器逼着你处理。异常适合「失败了就整体放弃」的场景。

两者可以互转：

```sml
fun toOption f x = SOME (f x) handle e => NONE
```

## 12.7 局部异常会遮蔽同名的全局异常

这是个非常隐蔽的坑：

```sml
exception Div                       (* 声明一个局部 Div *)

fun safeDiv (a, b) =
    (a div b) handle Div => ~1      (* 这里接的是局部 Div，不是 General.Div！*)

val _ = safeDiv (1, 0)              (* 除零异常直接冒出去了 *)
```

因为 `Int.div` 抛的是 `General.Div`，而 `handle Div` 里那个 `Div` 已经被局部声明遮蔽成了另一个异常。**解决办法：别用 Basis 已有的异常名做自定义异常。**

## 12.8 嵌套 handler

```sml
(inner () handle e => raise Fail ("inner failed: " ^ exnName e))
handle Fail msg => "outer caught: " ^ msg
```

内层把异常转成 `Fail` 再抛，外层接住。异常可以在传播路径上被逐层「降噪」。

## 12.9 本章示例为什么不打印 exnMessage

`examples/10-exceptions.sml` 的文件头专门写了一句：**这里刻意不打印 `exnMessage` 的结果**，因为它的文本三家不同，会把逐字节比对搞坏。示例里只打印 `exnName`。

这是本书的一个通用原则：**示例输出只包含三家一致的东西**；不一致的东西写进文档的差异表，而不是写进示例的输出。

---
