# 09 · 变体类型（代数数据类型）

对应示例：`../examples/07_variants.ml`

对应示例：`examples/07_variants.ml`

### 9.1 什么是变体类型

变体类型（variant type），也叫代数数据类型（algebraic data type）、和类型（sum type），是 OCaml 类型系统中最强大的特性之一。

简单来说，变体类型是「或」类型——一个值可以是几种可能的形式之一。比如一个「形状」可以是圆形、矩形或正方形；一个「表达式」可以是数字、加法或乘法。

变体类型用 `type` 和 `|` 定义：

```ocaml
type color = Red | Green | Blue
```

这里 `color` 是类型名，`Red`、`Green`、`Blue` 是**构造子**（constructor）。构造子的首字母必须大写。

最简单的变体（所有构造子都不带参数）类似于 C 语言的 enum，但功能强大得多。

### 9.2 带参数的变体

构造子可以携带参数，这样每个变体值可以包含不同的数据：

```ocaml
type shape =
  | Circle of float           (* 半径 *)
  | Rectangle of float * float  (* 宽 * 高 *)
  | Square of float           (* 边长 *)
```

`Circle of float` 的意思是：`Circle` 是一个构造子，它接受一个 `float` 参数，产生一个 `shape` 类型的值。

创建变体值：

```ocaml
let c = Circle 5.0
let r = Rectangle (3.0, 4.0)
let s = Square 6.0
```

用模式匹配处理：

```ocaml
let area s =
  match s with
  | Circle r -> 3.14159 *. r *. r
  | Rectangle (w, h) -> w *. h
  | Square side -> side *. side
```

这就是代数数据类型的精髓：**数据是「或」的（shape 是 circle 或 rectangle 或 square），处理数据的代码也对应地用模式匹配分情况处理。**

### 9.3 表达式树：递归变体

变体类型可以递归引用自身。这让你可以定义树形结构，比如表达式树：

```ocaml
type expr =
  | Num of int
  | Add of expr * expr
  | Mul of expr * expr
```

一个 `expr` 要么是一个数字（`Num`），要么是两个表达式相加（`Add`），要么是两个表达式相乘（`Mul`）。

表示 `(2 + 3) * 4`：

```ocaml
let e = Mul (Add (Num 2, Num 3), Num 4)
```

求值：

```ocaml
let rec eval e =
  match e with
  | Num n -> n
  | Add (e1, e2) -> eval e1 + eval e2
  | Mul (e1, e2) -> eval e1 * eval e2
```

递归变体 + 模式匹配，是处理树形结构最自然的方式。每一种节点对应一个构造子，处理代码就是一个 match，每个分支对应一种节点的处理逻辑。

### 9.4 参数化变体（泛型变体）

变体类型可以有类型参数，也就是泛型：

```ocaml
type 'a my_option =
  | MyNone
  | MySome of 'a
```

`'a my_option` 是一个参数化的变体类型。`'a` 是类型参数，可以实例化为任何类型。

标准库的 `option` 就是这样定义的：

```ocaml
type 'a option =
  | None
  | Some of 'a
```

`option` 用来表示「可能有值也可能没有值」的情况。它比空指针安全得多——类型系统会强迫你处理 `None` 的情况。

列表也是参数化变体。简化版的列表定义：

```ocaml
type 'a my_list =
  | MyNil
  | MyCons of 'a * 'a my_list
```

`MyCons (x, rest)` 表示一个元素 `x` 后面跟着另一个列表 `rest`。这和 `x :: rest` 是一样的结构，只是 `::` 是中缀构造子。

### 9.5 递归类型的经典例子：二叉搜索树

让我们用递归的参数化变体来实现一个二叉搜索树（BST）：

```ocaml
type 'a bst =
  | Leaf
  | Node of 'a * 'a bst * 'a bst   (* 值 * 左子树 * 右子树 *)
```

`Leaf` 表示空树，`Node (v, left, right)` 表示一个节点，包含值 `v`、左子树 `left` 和右子树 `right`。

插入元素：

```ocaml
let rec insert x tree =
  match tree with
  | Leaf -> Node (x, Leaf, Leaf)
  | Node (v, left, right) ->
      if x < v then Node (v, insert x left, right)
      else if x > v then Node (v, left, insert x right)
      else tree   (* 重复值不插入 *)
```

注意：这是函数式的插入——它不修改原树，而是返回一棵新树。原树保持不变。

查找元素：

```ocaml
let rec mem x tree =
  match tree with
  | Leaf -> false
  | Node (v, left, right) ->
      if x = v then true
      else if x < v then mem x left
      else mem x right
```

中序遍历（得到有序列表）：

```ocaml
let rec inorder tree =
  match tree with
  | Leaf -> []
  | Node (v, left, right) -> inorder left @ [v] @ inorder right
```

这就是函数式编程的典型风格：用递归数据结构 + 模式匹配 + 递归函数，代码简洁且结构清晰。

### 9.6 构造子也是函数

带参数的构造子本身就是函数。你可以把它当函数用——传给高阶函数、部分应用等等。

```ocaml
(* Some 是 'a -> 'a option 函数 *)
let opts = List.map (fun x -> Some x) [1; 2; 3]
(* [Some 1; Some 2; Some 3] *)
```

注意：在 OCaml 中，构造子不能直接作为函数值传递（和 SML 不同）。你需要用 `fun x -> Some x` 这样的 lambda 来包装。

不过，对于只有一个参数的构造子，你也可以这样写：

```ocaml
let wrapped_list = List.map (fun x -> Wrapped x) [1; 2; 3]
```

### 9.7 多态变体（polymorphic variants）

OCaml 还有一种特殊的变体，叫**多态变体**（polymorphic variant）。它用反引号 `` ` `` 前缀标记构造子：

```ocaml
let describe n =
  match n with
  | 0 -> `Zero
  | 1 -> `One
  | _ -> `Many
```

多态变体和普通变体最大的区别是：**多态变体不需要预先声明类型**。你可以直接用 `` `Zero ``、`` `One `` 这些构造子，编译器会自动推断类型。

多态变体的类型写成 `` [> `Zero | `One | `Many ] `` 这样的形式。`>` 表示「至少包含这些构造子」（开放的）。

多态变体的优势是灵活——你不需要先声明类型就能用。它的劣势是：
- 类型更复杂，报错信息更难读
- 没有穷尽性检查（因为类型是开放的）
- 可能会意外地「兼容」本不该兼容的类型

什么时候用多态变体？一般来说：
- **大部分时候用普通变体**——它们更安全、更清晰
- **小范围的临时联合类型**可以用多态变体，比如函数返回两种不同的结果
- **当你需要「子类型」关系时**用多态变体（多态变体支持行类型的子类型）

### 9.8 变体与模式匹配的配合

变体类型和模式匹配是天作之合。变体定义了数据的形状，模式匹配按照数据的形状分派代码。

这种编程风格有几个好处：

**1. 编译器保证穷尽性**

你不会忘记处理某个情况。加了一个新的构造子？编译器会告诉你所有需要更新的 match。

**2. 解构和匹配一步完成**

你不需要先判断类型再强转——模式匹配同时做了这两件事。而且类型系统确保你不会搞错。

**3. 代码结构和数据结构对应**

数据有几种形式，代码就有几个分支。数据怎么嵌套，模式就怎么嵌套。读代码的时候，你看到模式就知道数据长什么样。

### 9.9 本章小结

- 变体类型是「或」类型，一个值可以是多种形式之一
- 构造子首字母大写，用 `|` 分隔
- 构造子可以带参数，携带不同的数据
- 变体可以递归，用来定义树形等递归数据结构
- 参数化变体（泛型变体）用 `'a` 等类型参数
- 标准库的 `option` 和 `list` 都是参数化变体
- 构造子本质上是函数（但需要包装后才能传递）
- 多态变体（`` `Tag ``）不需要预先声明，更灵活但安全性稍低
- 变体 + 模式匹配是函数式编程的核心组合拳

---

---
上一章：[08 · 列表与高阶列表函数](lists.md) ｜ 下一章：[10 · 字符串与字符](strings.md) ｜ 返回：[README](../README.md)
