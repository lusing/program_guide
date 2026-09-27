# 15 · Functor（函子）

对应示例：`../examples/13_functors.ml`

对应示例：`examples/13_functors.ml`

### 15.1 什么是 Functor

Functor（函子）是**从模块到模块的函数**。

如果说普通函数是 "值 -> 值"，那么 functor 就是 "模块 -> 模块"。你给它一个模块作为参数，它返回一个新的模块。

为什么需要 functor？想象一下：你写了一个通用的二叉搜索树模块，它需要知道元素的类型和比较函数才能工作。如果没有 functor，你就得为 `int` 写一份、为 `string` 写一份、为 `float` 写一份……代码大量重复。

有了 functor，你可以写一个 `MakeSet` 函子，它接受一个「有序类型」模块作为参数，返回一个针对该类型的集合模块。你只需要写一次算法逻辑，就能用在任意可比较的类型上。

这就是 functor 的核心价值：**参数化模块，代码复用**。

### 15.2 Functor 的定义语法

Functor 的定义语法是：

```ocaml
module FunctorName (Param : SIGNATURE) = struct
  (* ... 使用 Param 中的内容 ... *)
end
```

我们来看一个简单的例子。先定义一个签名作为参数类型：

```ocaml
module type PRINTABLE = sig
  type t
  val to_string : t -> string
end
```

`PRINTABLE` 签名说：任何实现了这个签名的模块，都必须有一个类型 `t` 和一个把 `t` 转成字符串的函数。

现在定义一个 functor，它接受一个 `PRINTABLE` 模块，返回一个带打印功能的模块：

```ocaml
module Printer (P : PRINTABLE) = struct
  let print x = print_endline (P.to_string x)
  let print_list lst =
    print_endline ("[" ^ String.concat "; " (List.map P.to_string lst) ^ "]")
end
```

在 functor 内部，我们通过参数名 `P` 来访问参数模块的内容。

### 15.3 Functor 的应用

应用 functor 就像调用函数一样——把参数传进去：

```ocaml
module IntPrintable = struct
  type t = int
  let to_string = string_of_int
end

module IntPrinter = Printer(IntPrintable)
```

`IntPrinter` 就是 `Printer` 函子作用在 `IntPrintable` 上得到的新模块。我们可以使用它：

```ocaml
let _ =
  IntPrinter.print 42;                    (* 42 *)
  IntPrinter.print_list [1; 2; 3; 4; 5]   (* [1; 2; 3; 4; 5] *)
```

再为 `string` 类型创建一个：

```ocaml
module StringPrintable = struct
  type t = string
  let to_string s = s
end

module StringPrinter = Printer(StringPrintable)

let _ =
  StringPrinter.print "hello world";
  StringPrinter.print_list ["foo"; "bar"; "baz"]
```

注意 `IntPrinter` 和 `StringPrinter` 是两个完全不同的模块——它们是同一个 functor 用不同参数实例化出来的结果，各自操作自己的类型。

### 15.4 更完整的例子：MakeSet

让我们看一个更有实际意义的例子——实现一个类似标准库 `Set.Make` 的 functor。

首先定义参数签名：元素必须是可比较的。

```ocaml
module type ORDERED = sig
  type t
  val compare : t -> t -> int
end
```

然后定义 functor：

```ocaml
module MakeSet (Elem : ORDERED) = struct
  type elem = Elem.t
  type t = Empty | Node of t * elem * t

  let empty = Empty

  let rec mem x = function
    | Empty -> false
    | Node (left, v, right) ->
        let c = Elem.compare x v in
        if c = 0 then true
        else if c < 0 then mem x left
        else mem x right

  let rec add x = function
    | Empty -> Node (Empty, x, Empty)
    | Node (left, v, right) as node ->
        let c = Elem.compare x v in
        if c = 0 then node
        else if c < 0 then Node (add x left, v, right)
        else Node (left, v, add x right)

  let rec elements = function
    | Empty -> []
    | Node (left, v, right) ->
        elements left @ [v] @ elements right

  let rec size = function
    | Empty -> 0
    | Node (l, _, r) -> 1 + size l + size r

  let of_list lst = List.fold_left (fun s x -> add x s) empty lst
end
```

关键点：
- 参数模块 `Elem` 提供了元素类型 `Elem.t` 和比较函数 `Elem.compare`
- 返回的模块中，`type elem = Elem.t` 把元素类型暴露出去
- 所有的比较操作都通过 `Elem.compare` 完成，不直接使用 `compare`

现在我们可以为不同类型实例化集合：

```ocaml
(* int 集合 *)
module IntSet = MakeSet(struct
  type t = int
  let compare = compare
end)

(* string 集合（按长度比较） *)
module StringByLenSet = MakeSet(struct
  type t = string
  let compare s1 s2 = compare (String.length s1) (String.length s2)
end)

let _ =
  let is = IntSet.of_list [5; 2; 8; 1; 9; 3] in
  Printf.printf "IntSet size: %d\n" (IntSet.size is);
  Printf.printf "IntSet elements: [%s]\n"
    (String.concat ", " (List.map string_of_int (IntSet.elements is)))
```

这就是标准库中 `Set.Make` 和 `Map.Make` 的基本原理——它们都是 functor，接受一个可比较的元素类型模块，返回一个针对该类型的集合/映射模块。

### 15.5 带签名约束的 Functor 参数

Functor 的参数可以带有丰富的签名，不仅仅是一个类型和一个函数。比如我们可以定义一个「数字类型」签名，然后基于它构造向量运算模块：

```ocaml
module type NUMERIC = sig
  type t
  val zero : t
  val one : t
  val add : t -> t -> t
  val mul : t -> t -> t
  val to_string : t -> string
end

module VectorOps (Num : NUMERIC) = struct
  type scalar = Num.t
  type vector = scalar list

  let add v1 v2 = List.map2 Num.add v1 v2
  let dot v1 v2 =
    List.fold_left2 (fun acc a b -> Num.add acc (Num.mul a b)) Num.zero v1 v2
  let scale s v = List.map (Num.mul s) v
  let to_string v =
    "[" ^ String.concat ", " (List.map Num.to_string v) ^ "]"
end
```

然后实例化为 int 向量和 float 向量：

```ocaml
module IntVector = VectorOps(struct
  type t = int
  let zero = 0
  let one = 1
  let add = (+)
  let mul = ( * )
  let to_string = string_of_int
end)

module FloatVector = VectorOps(struct
  type t = float
  let zero = 0.0
  let one = 1.0
  let add = (+.)
  let mul = ( *. )
  let to_string = string_of_float
end)
```

同一份向量运算代码，既能用于整数，也能用于浮点数——甚至可以用于任何满足 `NUMERIC` 接口的类型（比如有理数、复数）。

### 15.6 多参数 Functor

Functor 可以接受多个模块参数，就像函数可以有多个参数一样。

```ocaml
module type KEY = sig
  type t
  val compare : t -> t -> int
end

module type VALUE = sig
  type t
  val to_string : t -> string
end

module MakePrintMap (K : KEY) (V : VALUE) = struct
  type key = K.t
  type value = V.t
  type t = (key * value) list

  let empty = []

  let rec find k = function
    | [] -> raise Not_found
    | (k', v) :: rest ->
        if K.compare k k' = 0 then v else find k rest

  let add k v m =
    let rec loop = function
      | [] -> [(k, v)]
      | (k', v') :: rest ->
          if K.compare k k' = 0 then (k, v) :: rest
          else (k', v') :: loop rest
    in loop m

  let bindings m = m
end
```

使用时传入两个参数：

```ocaml
module StringIntMap = MakePrintMap
  (struct type t = string let compare = compare end)
  (struct type t = int let to_string = string_of_int end)
```

和函数类似，多参数 functor 也可以「柯里化」——只传第一个参数，得到一个接受剩余参数的 functor：

```ocaml
module MakeIntValueMap = MakePrintMap(struct
  type t = int
  let compare = compare
end)

module IntIntMap = MakeIntValueMap(struct
  type t = int
  let to_string = string_of_int
end)
```

这里 `MakeIntValueMap` 是一个「偏应用」的 functor——它已经有了键类型（int），还需要传入值类型模块才能得到完整的映射模块。

### 15.7 Functor 的返回签名约束

Functor 的返回结果也可以加上签名约束，用来隐藏内部实现细节。我们会在下一章（不透明约束）详细讨论这个话题，这里先看一个简单例子：

```ocaml
module type SAFE_SET = sig
  type elem
  type t
  val empty : t
  val mem : elem -> t -> bool
  val add : elem -> t -> t
  val elements : t -> elem list
  val size : t -> int
end

module MakeSafeSet (Elem : ORDERED) : SAFE_SET with type elem = Elem.t = struct
  (* ... 实现 ... *)
end
```

这里 `: SAFE_SET with type elem = Elem.t` 就是 functor 的返回签名约束。它说：返回的模块满足 `SAFE_SET` 签名，并且其中的 `elem` 类型等于参数中的 `Elem.t`。

`with type elem = Elem.t` 叫做**共享约束**（sharing constraint）——它告诉类型系统两个类型是相同的。没有这个约束的话，外部就不知道 `SafeIntSet.elem` 就是 `int`，就没法把 `int` 传给 `SafeIntSet.mem` 了。

### 15.8 应用场景：Set.Make 和 Map.Make 背后的原理

OCaml 标准库的 `Set.Make` 和 `Map.Make` 是 functor 最经典的应用。

```ocaml
module StringSet = Set.Make(String)
module IntMap = Map.Make(struct type t = int let compare = compare end)
```

`Set.Make` 是一个 functor，它接受一个模块参数（必须提供 `type t` 和 `val compare`），返回一个针对该类型的集合模块。内部可能用红黑树实现，但外部只看到抽象的 `Set.S` 签名。

为什么要这么设计？为什么不像 Java 那样直接用接口/type class？

因为 OCaml 的模块系统是**生成式**的——每次 functor 应用都会产生一个全新的抽象类型。`Set.Make(String)` 和 `Set.Make(struct type t = string let compare = compare end)` 产生的是不同的类型，即使底层都是 string 的集合。这确保了「不同用途的集合不会混用」——比如你有一个按字典序比较的字符串集合和一个按长度比较的字符串集合，它们的类型是不同的，不会意外混用。

### 15.9 本章小结

- Functor 是「模块 -> 模块」的函数，用于参数化模块
- 定义语法：`module F (P : SIG) = struct ... end`
- 应用语法：`module M = F(ArgModule)`
- Functor 参数是带有签名的模块，提供类型和操作
- 多参数 functor 支持柯里化和偏应用
- 返回值可以加签名约束，控制对外暴露的内容
- `with type ... = ...` 是共享约束，用于指定类型等价关系
- 标准库的 `Set.Make`、`Map.Make` 就是 functor 的典型应用
- Functor 让算法逻辑只写一次，就能复用到不同类型上

---

---
上一章：[14 · 模块与签名](modules.md) ｜ 下一章：[16 · 不透明约束与抽象数据类型](abstraction.md) ｜ 返回：[README](../README.md)
