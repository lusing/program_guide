# 14 · 模块与签名

对应示例：`../examples/12_modules.ml`

对应示例：`examples/12_modules.ml`

### 14.1 为什么需要模块

当程序很小的时候，所有代码放在一个文件里、所有名字都在全局作用域里，这没什么问题。但当程序变大时，你就会遇到几个问题：

**命名冲突**：你想叫 `map` 的函数，别人也想叫 `map`。如果都在全局作用域，就冲突了。

**抽象不够**：你想对外暴露一些函数，但隐藏内部的辅助函数和数据表示。没有模块的话，所有东西都是公开的。

**组织混乱**：几十上百个函数和类型混在一起，找不到东西。

模块（module）就是用来解决这些问题的。模块提供了：
- **命名空间**：每个模块有自己的作用域，`List.map` 和 `String.map` 不冲突
- **抽象与封装**：通过签名控制哪些东西对外可见，哪些隐藏
- **代码组织**：相关的类型和函数放在一起，结构清晰

OCaml 的模块系统不仅仅是「命名空间」那么简单——它是一套完整的、有类型的模块语言。模块有自己的类型（签名），可以作为参数传给函子（functor），甚至可以作为值来传递（一等模块）。

### 14.2 module 定义结构

用 `module` 关键字定义模块结构（structure）：

```ocaml
module Stack = struct
  type 'a t = 'a list
  let empty = []
  let push x s = x :: s
  let pop = function
    | [] -> failwith "Stack.pop: empty stack"
    | x :: xs -> (x, xs)
  let is_empty s = s = []
  let size = List.length
end
```

模块名必须以大写字母开头。模块内部可以包含类型定义、值、函数、异常、子模块等。

访问模块中的内容用点号：

```ocaml
let s = Stack.empty
  |> Stack.push 1
  |> Stack.push 2
  |> Stack.push 3

let _ =
  Printf.printf "Stack size: %d\n" (Stack.size s)
```

每个 `.ml` 文件本身也是一个模块。比如 `foo.ml` 文件就对应一个名为 `Foo` 的模块，文件里的所有内容都是这个模块的成员。这是 OCaml 中最常见的模块定义方式——一个文件就是一个模块。

### 14.3 module type 定义签名

签名（signature）是模块的类型。就像 `int -> int` 描述了一个函数的接口一样，签名描述了一个模块的接口——它有哪些类型、哪些值、哪些函数，但不描述实现。

用 `module type` 定义签名：

```ocaml
module type STACK = sig
  type 'a t
  val empty : 'a t
  val push : 'a -> 'a t -> 'a t
  val pop : 'a t -> 'a * 'a t
  val is_empty : 'a t -> bool
  val size : 'a t -> int
end
```

签名中：
- `type 'a t` 声明了一个类型（可以是抽象的，也可以有具体定义）
- `val empty : 'a t` 声明了一个值
- `val push : 'a -> 'a t -> 'a t` 声明了一个函数（函数也是值）

`.mli` 文件就是对应 `.ml` 文件的签名。`foo.mli` 定义了 `Foo` 模块的对外接口。

### 14.4 签名约束（透明约束）

你可以用 `:` 给模块加上签名约束，就像给值加类型标注一样：

```ocaml
module AbstractStack : STACK = struct
  type 'a t = 'a list
  let empty = []
  let push x s = x :: s
  let pop = function
    | [] -> failwith "AbstractStack.pop: empty stack"
    | x :: xs -> (x, xs)
  let is_empty s = s = []
  let size = List.length
end
```

这里的 `:` 叫做**透明约束**（transparent constraint）。它的意思是「这个模块至少要实现签名中声明的东西」。

注意签名中的 `type 'a t` 没有给出具体定义——它是抽象的。当模块被加上这个签名约束后，外部就不知道 `'a t` 到底是什么了。你只能通过 `empty`、`push`、`pop` 等函数来操作它，不能直接把它当列表用。

```ocaml
let abs_s = AbstractStack.empty
  |> AbstractStack.push "hello"
  |> AbstractStack.push "world"

(* 可以通过接口操作 *)
let _ = Printf.printf "size: %d\n" (AbstractStack.size abs_s)

(* 但不能直接操作内部表示 —— 编译错误 *)
(* let _ : string list = abs_s   (* 错误：类型不匹配 *) *)
```

这就是抽象的力量——你可以改变内部实现（比如把列表改成数组、改成树）而不影响外部使用者，因为外部只依赖签名，不依赖实现。

**透明约束的「透明」体现在哪？** 如果签名中写了 `type t = int`（有具体定义），那么这个类型等式是可见的，外部知道 `t` 就是 `int`。只有当签名中类型是抽象的（只写 `type t`）时，类型才会被隐藏。

还有一种「不透明约束」用 `:>`，它会强制隐藏所有类型信息，我们会在第 16 章详细讲。

### 14.5 open 与局部 open

每次都写 `Stack.push`、`Stack.pop` 有点繁琐。你可以用 `open` 把模块的内容引入当前作用域：

```ocaml
open Stack

let s = empty |> push 1 |> push 2
```

但 `open` 要谨慎使用——它会污染命名空间，可能导致名字冲突。在实际项目中，推荐尽量少用全局 `open`，多用**局部 open**。

局部 open 有两种写法：

**写法一：`let open M in ...`**

```ocaml
let demo_local_open lst =
  let open List in
  map (fun x -> x * 2) lst
  |> filter (fun x -> x > 5)
  |> length
```

`List` 只在 `let open List in` 后面的表达式中可见。

**写法二：`M.( ... )`**

```ocaml
let demo lst =
  List.(map (fun x -> x + 1) lst |> rev)
```

这种写法更简洁，只在括号内打开模块。

局部 open 的好处是作用域明确——你知道哪些名字来自哪个模块，而且不会污染更大的作用域。

### 14.6 include 的使用

`include` 用于把另一个模块的所有内容包含到当前模块中。

```ocaml
module IntSet = struct
  type t = int list
  let empty = []
  let mem x s = List.mem x s
  let add x s = if mem x s then s else x :: s
  let elements s = List.sort compare s
end

module IntSetExtended = struct
  include IntSet                    (* 包含 IntSet 的所有内容 *)
  let of_list lst = List.fold_left (fun s x -> add x s) empty lst
  let union s1 s2 = List.fold_left (fun s x -> add x s) s1 s2
  let inter s1 s2 = List.filter (fun x -> mem x s2) s1
  let cardinal s = List.length (elements s)
end
```

`include` 和 `open` 的区别：
- `open` 只是把名字引入作用域，方便你少写前缀，模块之间还是独立的
- `include` 是把另一个模块的内容**复制**到当前模块中，被包含的内容成为当前模块的一部分

`include` 在签名中也可以使用，用来扩展签名：

```ocaml
module type SET_EXTENDED = sig
  include SET          (* 包含 SET 签名的所有声明 *)
  val of_list : 'a list -> 'a t
  val union : 'a t -> 'a t -> 'a t
end
```

### 14.7 子模块（嵌套模块）

模块内部可以定义子模块，形成层级结构。

```ocaml
module Math = struct
  module Basic = struct
    let add x y = x + y
    let sub x y = x - y
    let mul x y = x * y
    let div x y = x / y
  end

  module Advanced = struct
    let rec factorial n =
      if n <= 1 then 1 else n * factorial (n - 1)
    let rec fibonacci n =
      if n <= 1 then n else fibonacci (n - 1) + fibonacci (n - 2)
  end

  module Stats = struct
    let mean lst =
      let sum = List.fold_left (+) 0 lst in
      float_of_int sum /. float_of_int (List.length lst)
  end
end
```

访问子模块的内容用多层点号：

```ocaml
let _ =
  Math.Basic.add 3 4;           (* 7 *)
  Math.Advanced.factorial 5;    (* 120 *)
  Math.Stats.mean [1;2;3;4;5]   (* 3.0 *)
```

子模块是组织大型模块的常用方式。你可以把相关的功能分组到不同的子模块中，让层次更清晰。

### 14.8 一个签名两套实现

模块化编程的核心思想是「接口与实现分离」。同一个签名可以有多个不同的实现，调用者只依赖签名，不依赖具体实现。

我们来定义一个集合的签名，然后用两种不同的方式实现它。

```ocaml
module type SET = sig
  type 'a t
  val empty : 'a t
  val mem : 'a -> 'a t -> bool
  val add : 'a -> 'a t -> 'a t
  val remove : 'a -> 'a t -> 'a t
  val elements : 'a t -> 'a list
  val size : 'a t -> int
end
```

**实现一：基于列表的集合**

```ocaml
module ListSet : SET = struct
  type 'a t = 'a list
  let empty = []
  let mem = List.mem
  let add x s = if mem x s then s else x :: s
  let remove x s = List.filter (fun y -> y <> x) s
  let elements s = List.sort compare s
  let size = List.length
end
```

**实现二：基于二叉搜索树的集合**

```ocaml
module TreeSet : SET = struct
  type 'a t = Empty | Node of 'a t * 'a * 'a t

  let empty = Empty

  let rec mem x = function
    | Empty -> false
    | Node (left, v, right) ->
        let c = compare x v in
        if c = 0 then true
        else if c < 0 then mem x left
        else mem x right

  let rec add x = function
    | Empty -> Node (Empty, x, Empty)
    | Node (left, v, right) as node ->
        let c = compare x v in
        if c = 0 then node
        else if c < 0 then Node (add x left, v, right)
        else Node (left, v, add x right)

  let rec min_node = function
    | Empty -> raise Not_found
    | Node (Empty, v, _) -> v
    | Node (left, _, _) -> min_node left

  let rec remove x = function
    | Empty -> Empty
    | Node (left, v, right) ->
        let c = compare x v in
        if c < 0 then Node (remove x left, v, right)
        else if c > 0 then Node (left, v, remove x right)
        else
          match (left, right) with
          | (Empty, _) -> right
          | (_, Empty) -> left
          | _ ->
              let m = min_node right in
              Node (left, m, remove m right)

  let elements t =
    let rec loop acc = function
      | Empty -> acc
      | Node (left, v, right) ->
          loop (v :: loop acc right) left
    in loop [] t

  let rec size = function
    | Empty -> 0
    | Node (left, _, right) -> 1 + size left + size right
end
```

这两个模块有完全相同的签名 `SET`，但内部实现完全不同——一个用列表（简单但 O(n)），一个用二叉搜索树（高效但复杂）。

因为它们有相同的签名，你可以写一个通用的测试函数，不关心具体是哪个实现：

```ocaml
let test_set (type a) (module S : SET with type 'a t = 'a S.t) name =
  let open S in
  let s = empty
    |> add 3 |> add 1 |> add 4 |> add 1 |> add 5 |> add 9 |> add 2 |> add 6
  in
  Printf.printf "%s size: %d\n" name (size s);
  Printf.printf "%s elements: [%s]\n" name
    (String.concat ", " (List.map string_of_int (elements s)));
  Printf.printf "%s mem 5: %b\n" name (mem 5 s);
  let s' = remove 4 s in
  Printf.printf "%s after remove 4, size: %d\n" name (size s')

let _ =
  test_set (module ListSet) "ListSet";
  test_set (module TreeSet) "TreeSet"
```

（这里用到了一等模块 `(module S : SET)` 的语法，我们会在第 17 章介绍。）

**接口与实现分离的好处**：
1. 你可以先写好接口，然后多人并行实现
2. 你可以写一个简单版本（比如列表实现）快速验证，之后再换成高效版本
3. 调用者代码不需要改，只需要换模块就行
4. 便于单元测试——你可以用 mock 实现替换真实实现

### 14.9 本章小结

- 模块提供命名空间、抽象封装、代码组织三大功能
- `module M = struct ... end` 定义模块结构
- `module type S = sig ... end` 定义模块签名（接口）
- 签名约束 `:` 是透明约束——签名中抽象的类型会被隐藏，有定义的类型仍然可见
- `open` 把模块内容引入作用域，推荐用局部 open（`let open M in` 或 `M.(...)`）
- `include` 把另一个模块的内容包含进来，成为当前模块的一部分
- 模块可以嵌套，形成子模块层级
- 一个签名可以有多个实现，实现接口与实现分离
- 每个 `.ml` 文件对应一个模块，每个 `.mli` 文件对应该模块的签名

---

---
上一章：[13 · 高阶函数与闭包](higher-order.md) ｜ 下一章：[15 · Functor（函子）](functors.md) ｜ 返回：[README](../README.md)
