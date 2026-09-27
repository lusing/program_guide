# 07 · 模式匹配

对应示例：`../examples/05_patterns.ml`

对应示例：`examples/05_patterns.ml`

### 7.1 模式匹配是 OCaml 的灵魂

如果说有一个特性定义了 OCaml 的编程风格，那一定是**模式匹配**（pattern matching）。模式匹配让你可以「根据数据的形状来选择代码路径」，而且编译器会帮你检查有没有漏掉情况。

你可能在其他语言里见过类似的东西（比如 switch/case），但 OCaml 的模式匹配要强大得多：

- 可以匹配任何数据类型：整数、浮点数、字符串、元组、记录、变体、列表……
- 可以嵌套匹配：模式里面可以再套模式
- 可以解构数据：匹配的同时把数据拆开，把各部分绑到变量上
- 编译器检查穷尽性：确保你覆盖了所有可能的情况
- 编译器检查冗余：提醒你哪些分支永远不会被执行

模式匹配的基本形式是 `match` 表达式：

```ocaml
match expr with
| pattern1 -> expr1
| pattern2 -> expr2
| ...
```

`match` 是一个表达式，它的值是第一个匹配的分支中 `->` 右边表达式的值。

### 7.2 通配模式与字面量模式

最简单的模式是**通配模式** `_`，它匹配任何值，但不绑定任何变量：

```ocaml
let describe n =
  match n with
  | 0 -> "zero"
  | 1 -> "one"
  | 2 -> "two"
  | _ -> "something else"
```

这里的 `0`、`1`、`2` 是**字面量模式**——它们匹配等于该字面量的值。`_` 是兜底分支，匹配所有剩下的情况。

字面量模式可以是整数、浮点数、字符、字符串等：

```ocaml
let greeting lang =
  match lang with
  | "en" -> "Hello"
  | "fr" -> "Bonjour"
  | "es" -> "Hola"
  | "zh" -> "Ni hao"
  | _ -> "Hi"
```

### 7.3 变体构造子模式

对于变体类型（第 9 章会详细讲），模式匹配可以解构构造子的参数：

```ocaml
type shape =
  | Circle of float
  | Rectangle of float * float
  | Square of float

let area s =
  match s with
  | Circle r -> 3.14159 *. r *. r
  | Rectangle (w, h) -> w *. h
  | Square side -> side *. side
```

`Circle r` 这个模式匹配所有 `Circle` 构造的值，同时把半径绑到变量 `r` 上。`Rectangle (w, h)` 匹配 `Rectangle` 构造的值，把宽和高分别绑到 `w` 和 `h` 上。

标准库的 `option` 类型就是一个常用的变体：

```ocaml
let opt_value default opt =
  match opt with
  | Some x -> x
  | None -> default
```

`Some x` 匹配 `Some` 构造的值，把里面的值绑到 `x` 上。`None` 匹配 `None`。

### 7.4 列表模式

列表也可以用模式匹配：

```ocaml
let rec sum lst =
  match lst with
  | [] -> 0
  | x :: rest -> x + sum rest
```

- `[]` 匹配空列表
- `x :: rest` 匹配非空列表，`x` 绑到第一个元素（头），`rest` 绑到剩下的列表（尾）

`::` 在模式中是构造子，就像它在表达式中一样。注意 `::` 是右结合的，所以 `x :: y :: rest` 匹配至少有两个元素的列表。

也可以用固定长度的列表模式：

```ocaml
let describe_list lst =
  match lst with
  | [] -> "empty"
  | [_] -> "one element"
  | [_; _] -> "two elements"
  | _ :: _ :: _ -> "three or more"
```

`[x; y; z]` 是 `x :: y :: z :: []` 的语法糖，在表达式和模式中都是如此。

### 7.5 元组与记录模式

我们在第 6 章已经见过元组和记录的模式匹配了，这里再强调一下：它们在 `match` 中同样适用，而且可以和其他模式组合使用。

```ocaml
let describe_pair (x, y) =
  match (x, y) with
  | (0, 0) -> "origin"
  | (0, _) -> "on y-axis"
  | (_, 0) -> "on x-axis"
  | (a, b) when a = b -> "on diagonal"
  | _ -> "somewhere else"
```

记录模式：

```ocaml
type point2d = { x : float; y : float }

let is_on_x_axis p =
  match p with
  | { y = 0.0 } -> true
  | _ -> false
```

记录模式中不需要列出所有字段——你只需要写你关心的那些。

### 7.6 as 模式

`as` 模式可以给匹配的子模式起一个名字：

```ocaml
let describe_list lst =
  match lst with
  | ([] | [_]) as short ->
      "short list, length = " ^ string_of_int (List.length short)
  | _ :: _ :: _ as long ->
      "long list, length = " ^ string_of_int (List.length long)
```

`([] | [_]) as short` 的意思是：如果匹配 `[]` 或 `[_]`，就把整个匹配的值绑到 `short` 上。

`as` 在嵌套模式中尤其有用，你既能解构内部结构，又能保留对整体的引用：

```ocaml
let first_point_x lst =
  match lst with
  | ((x, _) :: _) as points ->
      Printf.printf "First x of %d points: %f\n" (List.length points) x;
      x
  | [] -> 0.0
```

### 7.7 when 守卫

有时候光靠模式本身不足以表达分支条件。这时可以用 `when` 守卫（guard）：

```ocaml
let classify n =
  match n with
  | 0 -> "zero"
  | n when n > 0 -> "positive"
  | n when n < 0 -> "negative"
  | _ -> "unreachable"
```

`when` 后面跟一个布尔表达式。只有当模式匹配**且** `when` 条件为 `true` 时，该分支才会被选中。

`when` 守卫的作用是补充模式匹配表达不了的条件。但注意：**编译器不会检查 when 条件的穷尽性**。因为 `when` 条件可以是任意布尔表达式，编译器无法静态分析它覆盖了哪些情况。

所以上面的例子中，虽然逻辑上前三个分支已经覆盖了所有整数，但最后那个 `_` 分支还是需要的——不是因为穷尽性检查，而是因为 `when` 守卫不算入穷尽性检查。不过实际上，`n when n > 0` 中的 `n` 已经匹配了所有整数，所以从模式的角度看，第二个分支就已经是穷尽的了……这有点微妙。实际经验是：如果你用了 `when`，最好加一个兜底分支。

### 7.8 穷尽性检查

OCaml 编译器会检查模式匹配是否穷尽（exhaustive）——也就是是否覆盖了所有可能的输入。如果有遗漏，编译器会发出警告。

```ocaml
type color = Red | Green | Blue

(* 警告：非穷尽匹配，漏掉了 Blue *)
let string_of_color c =
  match c with
  | Red -> "Red"
  | Green -> "Green"
```

穷尽性检查是 OCaml 最有价值的特性之一。想象一下：你给一个变体类型加了一个新的构造子，然后编译器会告诉你所有需要更新的模式匹配——你永远不会忘记处理某个情况。

穷尽性检查是精确的，不是粗略的。它不会因为你有一个 `_` 兜底就不检查了——它会检查你显式列出的模式是否覆盖了所有情况。

还有一个相关的检查：**冗余模式检查**。如果某个分支永远不会被执行（因为前面的分支已经覆盖了所有情况），编译器也会警告你：

```ocaml
let f x =
  match x with
  | 0 -> "zero"
  | _ -> "other"
  | 1 -> "one"    (* 警告：这个匹配情况没用 *)
```

### 7.9 let 模式解构

`let` 本身就是模式匹配的一种形式。任何「一定能匹配」的模式都可以用在 `let` 中：

```ocaml
(* 元组模式 *)
let (a, b) = (10, 20)

(* 记录模式 *)
let { x; y } = { x = 3.5; y = 4.5 }

(* 变体模式（只有一个构造子时安全） *)
let Some v = Some 42
```

最后那个例子要小心：如果右边是 `None`，程序会在运行时崩溃（抛出 `Match_failure` 异常）。所以 `let` 模式只应该用在「肯定能匹配」的情况下。对于可能失败的匹配，用 `match`。

函数参数也可以用模式：

```ocaml
let add_pair (x, y) = x + y
let get_x { x } = x
let head (x :: _) = x      (* 不推荐：空列表会失败 *)
```

### 7.10 function 关键字

`function` 是一个语法糖，用来写只有一个参数且直接做模式匹配的函数：

```ocaml
(* 用 match 写 *)
let string_of_color c =
  match c with
  | Red -> "Red"
  | Green -> "Green"
  | Blue -> "Blue"

(* 用 function 写，等价 *)
let string_of_color = function
  | Red -> "Red"
  | Green -> "Green"
  | Blue -> "Blue"
```

`function` 隐式地引入了一个参数，然后立刻对它做模式匹配。当函数的主体就是一个 match 时，`function` 更简洁。

### 7.11 嵌套模式

模式可以任意嵌套。比如列表中嵌套元组，元组中嵌套变体，变体中嵌套记录……：

```ocaml
type 'a tree =
  | Leaf
  | Node of 'a * 'a tree * 'a tree

let rec leftmost tree =
  match tree with
  | Leaf -> None
  | Node (v, Leaf, _) -> Some v
  | Node (_, left, _) -> leftmost left
```

`Node (v, Leaf, _)` 是一个嵌套模式——外层是 `Node` 构造子模式，里面嵌套了 `Leaf` 模式（匹配左子树为空的情况）。

嵌套模式让你可以用一个模式表达复杂的结构条件，不需要多层嵌套的 match。

### 7.12 本章小结

- `match` 是模式匹配的基本形式，也是表达式
- 通配模式 `_` 匹配任何值但不绑定变量
- 字面量模式匹配具体的值
- 变体构造子模式可以解构带参数的变体
- 列表模式：`[]`、`x :: rest`、`[x; y; z]`
- `as` 模式给匹配的值起名字
- `when` 守卫给分支增加额外的条件
- 编译器做穷尽性检查和冗余检查
- `let` 和函数参数也可以用模式（但必须是穷尽的）
- `function` 是「单参数 + 直接 match」的语法糖
- 模式可以任意嵌套

---

---
上一章：[06 · 元组与记录](tuples-records.md) ｜ 下一章：[08 · 列表与高阶列表函数](lists.md) ｜ 返回：[README](../README.md)
