# 04 · 类型系统

> 对应示例：`examples/02-types.sml`


## 4.1 基础类型

| 类型 | 字面量示例 | 说明 |
|---|---|---|
| `int` | `42`、`~7`（负号是 `~`） | 位宽**实现相关**，见 4.4 |
| `real` | `3.14`、`1.0E16` | IEEE 754 双精度 |
| `bool` | `true` / `false` | |
| `char` | `#"a"`、`#"\n"` | 单个字符 |
| `string` | `"hello"` | 不可变字节序列 |
| `unit` | `()` | 只有一个值，用于「有副作用没结果」 |
| `word` | `0w255` | 无符号整数，位运算用 |

负号是 **`~`** 不是 `-`：`~7` 是一个负数字面量，而 `-` 是二元减法。这不是怪癖 —— `-` 既能当减法又能当负号会造成解析歧义（`x-1` 是 `x - 1` 还是 `x (-1)`？），SML 干脆只让 `~` 当负号。所有实现都自带把 `~` 打出来的习惯：`Int.toString ~7` 得到 `"~7"`。

字符字面量写作 **`#"a"`**，是「一个字符的字符串」的讽刺性记法（SML 早期沿用了这个语法）。

## 4.2 三种类型标注写法

```sml
val a : int = 42                    (* 标在名字上 *)
val b = 42 : int                    (* 标在表达式上 *)
fun f (x : int) : int = x + 1       (* 标在参数和返回值上 *)
```

都合法，用途不同：标在表达式上可以只给子表达式加约束：

```sml
val c = (1 + 2 : int) * 3
```

## 4.3 相等类型

SML 的 `=` 是**多态的**，但只能作用于**相等类型（equality type）**，写作 `''a`。哪些是相等类型？

- `int`、`char`、`string`、`bool`、`unit`、`word` —— 是
- **`real` —— 不是！**
- 元组、记录、`list`、`option` —— 当且仅当成员都是
- `ref`、`array` —— 是，但语义是**物理地址比较**（第 18 章）
- 抽象类型 —— **默认不是**，除非签名里写 `eqtype`（第 16 章）

所以这段不编译：

```sml
val _ = 0.1 + 0.2 = 0.3      (* Error: operator and operand do not agree *)
```

```
Error: operator and operand do not agree [equality type required]
```

这是 SML 的一个正确决定：浮点相等几乎总是 bug。要比较浮点，用：

```sml
Real.== (0.1 + 0.2, 0.3)          (* false *)
Real.compare (0.1 + 0.2, 0.3)     (* LESS *)
```

## 4.4 int 有多宽？—— 别假设

```sml
val _ = print (Int.toString (valOf Int.maxInt))
```

实测：

| 实现 | `Int.maxInt` | 有效位数 |
|---|---|---|
| SML/NJ 110.99.9 | `4611686018427387903` | 63 位 |
| Poly/ML 5.9.2 | `4611686018427387903` | 63 位 |
| MLton 20241230 | **`2147483647`** | **32 位** |

MLton 默认是 32 位 `int`，要 64 位得显式用 `Int64` 结构。

**实践后果**：写算法时不要挑大的测试数据。`fact 12` 是安全的（479001600），`fact 13` 在 MLton 上就溢出了。本书第 19 章的斐波那契刻意用了 `fib 40 = 102334155`（小于 2³¹）而不是 `fib 50`。

另外两个 `int option`：

```sml
val _ = print (Int.toString (valOf Int.maxInt))       (* 必须 valOf *)
val _ = print (Int.toString (valOf Int.precision))    (* 一般也是 63 / 31 *)
```

## 4.5 type 别名

```sml
type point = int * int

fun dist2 ((x1, y1) : point, (x2, y2) : point) = (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)
```

`type` 只是给类型起别名，**不产生新类型**。所以 `point` 和 `int * int` 完全等价，可以互换。

想要「和 `int` 不同的一个新类型」，SML 的做法是 `datatype`（第 9 章）或者不透明签名（第 16 章）。

**注意 `type` 别名不是约束**。这点很微妙，第 23 章会撞上一个真实例子：

```sml
type checker = { checkInt : int -> unit, ... }

fun makeChecker () = { checkInt = ..., ... }
(* 这里 typeof (makeChecker ()) 并不等于 checker！
   它有一套自己的推断类型，可能带着自由类型变量 *)
```

要让它真的等于 `checker`，必须写返回值标注：`fun makeChecker () : checker = ...`。

## 4.6 重载字面量

整数和浮点字面量是**重载**的：`1` 可以是任何「整型」类型，`1.0` 可以是任何「浮点型」类型。所以：

```sml
val a : Int32.int = 1        (* 可以 *)
val b : Real.real = 1.0      (* 可以 *)
val c = 1                    (* 默认 int *)
```

这也是为什么 `fun add (a, b) = a + b` 里的 `+` 需要上下文才能定下来 —— 没上下文就默认 `int`。第 15 章会看到这个默认规则在抽象类型 + 签名约束下会分叉。

## 4.7 变量的作用域与遮蔽

同名的 `val` 会**遮蔽**前一个，两个都还在内存里（前一个被闭包捕获的话）：

```sml
val x = 1
val x = x + 1     (* 右边的 x 是上一个，左边的 x 是新的 *)
(* 现在 x = 2 *)
```

`let ... in ... end` 里的绑定只在内层可见：

```sml
val y =
    let
        val tmp = 10
    in
        tmp * 3
    end
(* tmp 在这里已经不可见了 *)
```

---
