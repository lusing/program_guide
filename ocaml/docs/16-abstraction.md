# 16 · 不透明约束与抽象数据类型

### 16.1 透明约束 vs 不透明约束

上一章我们提到了签名约束 `:`，它叫做**透明约束**（transparent constraint）。还有一种约束叫**不透明约束**（opaque constraint），用 `:>`。

它们的区别在于类型信息的可见性：

- **透明约束 `:`**：签名中给出定义的类型，其类型等式是可见的；签名中是抽象的（只写 `type t`），则是抽象的
- **不透明约束 `:>`**：所有在签名中声明的类型，**全部变成抽象的**，即使签名里写了 `type t = int`，外部也不知道

用一个例子来看：

```ocaml
module type COUNTER = sig
  type t
  val create : unit -> t
  val increment : t -> unit
  val get : t -> int
end
```

**透明约束版本**：

```ocaml
module TransparentCounter : COUNTER with type t = int ref = struct
  type t = int ref
  let create () = ref 0
  let increment r = r := !r + 1
  let get r = !r
end
```

透明约束下，`t = int ref` 是可见的。外部可以直接操作内部表示：

```ocaml
let tc = TransparentCounter.create ()
let _ =
  TransparentCounter.increment tc;
  tc := 999;   (* 直接绕过接口修改内部状态！ *)
  Printf.printf "%d\n" (TransparentCounter.get tc)   (* 999 *)
```

**不透明约束版本**：

```ocaml
module OpaqueCounter : COUNTER = struct
  type t = int ref
  let create () = ref 0
  let increment r = r := !r + 1
  let get r = !r
end
```

不透明约束下，`OpaqueCounter.t` 是完全抽象的——外部根本不知道它是 `int ref`。你只能通过 `create`、`increment`、`get` 这些接口来操作它。

```ocaml
let oc = OpaqueCounter.create ()
let _ =
  OpaqueCounter.increment oc;
  (* oc := 999   编译错误！外部不知道 t 是 int ref *)
  Printf.printf "%d\n" (OpaqueCounter.get oc)   (* 1 *)
```

这才是真正的封装。不透明约束保证了外部无法绕过你的接口直接操作内部数据。

### 16.2 什么是抽象数据类型（ADT）

**抽象数据类型**（Abstract Data Type，简称 ADT）是指：由它的操作（可以做什么）来定义，而不是由它的内部表示（怎么实现的）来定义的数据类型。

比如「栈」就是一个抽象数据类型——它由 push、pop、empty、is_empty 这些操作来定义。至于内部是用列表实现还是用数组实现，用户不关心，也不应该知道。

在 OCaml 中，抽象数据类型就是通过**不透明约束 + 签名**来实现的：

```ocaml
module type STACK = sig
  type 'a t          (* 抽象类型：栈的表示 *)
  val empty : 'a t
  val push : 'a -> 'a t -> 'a t
  val pop : 'a t -> 'a * 'a t
  val is_empty : 'a t -> bool
  val size : 'a t -> int
end

(* 用不透明约束封装 *)
module ListStack : STACK = struct
  type 'a t = 'a list
  (* ... 实现 ... *)
end
```

外部只知道 `'a ListStack.t` 是一个栈类型，可以 push/pop，但不知道它内部是列表。你随时可以把内部实现改成数组或者链表，而不需要修改任何使用它的代码。

### 16.3 不变量保护

不透明约束最重要的用途是**保护数据结构的内部不变量**（invariant）。

什么是不变量？就是数据结构必须始终满足的性质。比如：
- 二叉搜索树的不变量：左子树所有节点 < 根 < 右子树所有节点
- 有序列表的不变量：元素按顺序排列
- 日期类型的不变量：月份在 1-12 之间，日期在有效范围内

如果内部表示是公开的，用户就可能手动构造一个破坏不变量的值，导致后续操作出错。

来看一个日期的例子：

```ocaml
module type DATE = sig
  type t
  val create : int -> int -> int -> t   (* 年, 月, 日 *)
  val year : t -> int
  val month : t -> int
  val day : t -> int
  val to_string : t -> string
end

module Date : DATE = struct
  type t = { year : int; month : int; day : int }

  let is_valid y m d =
    m >= 1 && m <= 12 && d >= 1 && d <= 31  (* 简化版校验 *)

  let create y m d =
    if is_valid y m d then { year = y; month = m; day = d }
    else failwith "invalid date"

  let year d = d.year
  let month d = d.month
  let day d = d.day
  let to_string d = Printf.sprintf "%04d-%02d-%02d" d.year d.month d.day
end
```

因为用了不透明约束（`Date : DATE`），外部无法直接构造 `Date.t` 的值，只能通过 `Date.create` 来创建。而 `Date.create` 会做合法性检查——这就保证了**所有 `Date.t` 类型的值都是合法的日期**。

你不需要在每次使用日期时都检查它是否合法——只要你拿到了一个 `Date.t`，它就一定是合法的。这是一种非常强大的保证，叫做**「使非法状态不可表示」**（make illegal states unrepresentable）。

**这就是类型系统的力量**：让类型检查器帮你保证不变量，而不是靠文档和约定。

### 16.4 隐藏内部辅助函数

不透明约束还可以用来隐藏内部的辅助函数。你在模块内部定义了很多辅助函数，但只想对外暴露少数几个公共接口。

```ocaml
module type MATH_UTILS = sig
  val gcd : int -> int -> int
  val lcm : int -> int -> int
end

module MathUtils : MATH_UTILS = struct
  let rec gcd a b =
    if b = 0 then a else gcd b (a mod b)

  (* 内部辅助函数，不对外暴露 *)
  let abs x = if x < 0 then -x else x

  let lcm a b =
    if a = 0 || b = 0 then 0
    else abs (a * b) / gcd a b
end
```

外部只能使用 `gcd` 和 `lcm`，看不到 `abs` 辅助函数。这有几个好处：
- 减少命名空间污染
- 让接口更清晰，用户只看到他们需要的东西
- 内部实现可以自由重构，不用担心破坏外部代码

### 16.5 相等性与抽象类型

抽象类型有一个微妙的问题：相等性。

在 OCaml 中，结构相等（`=`）是多态的——它可以比较任意两个同类型的值。但对于抽象类型，外部不知道内部结构，`=` 还能用吗？

答案是可以的。`=` 操作符在运行时仍然会比较内部表示，不管类型是不是抽象的。类型抽象只影响编译期的类型检查，不影响运行时的行为。

但这里有一个设计问题：你应该允许用户用 `=` 比较你的抽象类型吗？

有时候不应该。比如对于你的集合类型，如果内部用列表实现，`=` 比较的是列表的结构相等——但两个列表顺序不同可能表示同一个集合（因为集合是无序的）。这时候 `=` 给出的结果在语义上就是错误的。

所以对于抽象类型，一个好的实践是：**在签名中提供自己的相等性函数**，并提醒用户不要直接用 `=`。

```ocaml
module type SET = sig
  type 'a t
  val equal : 'a t -> 'a t -> bool
  (* ... 其他操作 ... *)
end
```

当然，这只能靠约定——用户仍然可以用 `=`，你无法在类型层面阻止。但至少你提供了正确的比较方式。

### 16.6 多态抽象类型

抽象类型可以是多态的。比如栈、集合这些数据结构，它们可以装任意类型的元素。

```ocaml
module type STACK = sig
  type 'a t         (* 多态抽象类型 *)
  val empty : 'a t
  val push : 'a -> 'a t -> 'a t
  (* ... *)
end
```

`type 'a t` 表示 `t` 是一个带一个类型参数的抽象类型。外部看到的是 `'a Stack.t`，知道它是「装 'a 类型元素的栈」，但不知道内部表示。

### 16.7 Functor + 不透明约束的强大组合

Functor 和不透明约束结合起来，威力巨大。你可以用 functor 参数化地构造模块，同时用不透明约束封装内部实现。

标准库的 `Set.Make` 就是这样的：

```ocaml
(* Set.Make 的简化版本 *)
module Make (Ord : OrderedType) : S with type elt = Ord.t = struct
  type elt = Ord.t
  type t = Empty | Node of t * elt * t
  (* ... 实现 ... *)
end
```

返回的模块满足 `Set.S` 签名（不透明约束），但 `elt` 类型和参数模块的 `Ord.t` 共享（`with type elt = Ord.t`）。这意味着：
- 内部的树结构是隐藏的，外部无法直接构造或修改
- 但元素类型是已知的，用户可以用 `Ord.t` 类型的值去调用 `mem`、`add` 等函数

这种「大部分隐藏，选择性暴露」的模式非常常见。你通过不透明约束隐藏所有实现细节，然后通过 `with type ... = ...` 共享约束来暴露必要的类型等式。

### 16.8 本章小结

- 透明约束 `:`：签名中有定义的类型可见，抽象的类型不可见
- 不透明约束 `:>`：签名中所有类型都变成抽象的，完全隐藏
- 抽象数据类型（ADT）：由操作定义，不由内部表示定义
- 不透明约束可以保护数据结构的内部不变量
- 「使非法状态不可表示」是类型驱动设计的核心思想
- 不透明约束还可以隐藏内部辅助函数，保持接口简洁
- 抽象类型可以是多态的（`'a t`）
- Functor + 不透明约束 = 参数化 + 封装，是 OCaml 模块系统最强大的组合
- `with type ... = ...` 共享约束用于在不透明约束下选择性地暴露类型等式

---

---
上一章：[15 · Functor（函子）](functors.md) ｜ 下一章：[17 · 模块系统进阶](modules-advanced.md) ｜ 返回：[README](../README.md)
