# 33 · 模块表达式与抽象类型

对应示例：`../examples/29_module_exprs.ml`

模块不只是「文件顶部的组织单位」。《OCaml 语言编程基础教程》第
3.9–3.12 节把这条线讲得很深：模块可以出现在**表达式位置**（首类
模块）、签名可以**动态构造**、抽象类型有**私有**与**局部**两个
精变体。本章把这些深水区工具凑齐（Real World OCaml 第 10 章是
工程视角的补充），全部行为在 OCaml 5.4.1 实测。

### 33.1 局部打开：`let open ... in` 与 `M.(...)`

只在一段表达式里借用模块的名字：

```ocaml
let r1 =
  let open List in
  length (append [1; 2] [3; 4])          (* 4 *)

let r2 = List.(length (append [1; 2] [3; 4]))   (* 同上的简写 *)
```

出了局部作用域，裸的 `length` 不再可见。模块内部 `open List`
的作用范围同样限于该模块——出了模块定义，List 自动关闭。

### 33.2 include：把别家的定义「抄进来」

```ocaml
module EL = struct
  include List
  let length l = length l + 1     (* 非 rec 的 let：函数体里的 length
                                      解析到「上一个绑定」= List.length *)
end

List.length [1; 2; 3]    (* 3 *)
EL.length  [1; 2; 3]     (* 4 —— 被覆盖 *)
EL.hd [9; 8]             (* 9 —— 原样继承 *)
```

`open` 与 `include` 的区别：`open M` 借用 M 的名字、不产生新模块；
`include M` 把 M 的名字**抄进当前模块**，新模块自己也有这些成员
（`EL.hd` 可用）。覆盖规则：同名者后定义覆盖先引入。

### 33.3 首类模块：pack 与 unpack

打包 `(module M : S)` 让模块成为值；拆包 `(val m : S)` 恢复成模块：

```ocaml
module type Ele = sig
  type ele
  val zero : ele
  val add1 : ele -> ele
  val show : ele -> string
end

module F_impl = struct
  type ele = float
  let zero = 0.0
  let add1 x = x +. 1.0
  let show x = Printf.sprintf "%.1f" x
end

let m_f = (module F_impl : Ele)              (* 打包：let 的右端！ *)
let () =
  let module M = (val m_f : Ele) in          (* 拆包 *)
  print_endline (M.show (M.add1 M.zero))     (* 1.0 *)
```

**坑（实测）**：顶层拆包必须写 `module P = (val m : S)`；写成
`let module P = ...` 而不接 `in` 直接 `;;` 会 Syntax error——
`let module` 是表达式级绑定、必须有 `in`。

**坑（实测）**：首类模块按**签名名**判等。结构一模一样的两个签名
`Ele` 与 `Ele2`，打包出的 `(module Ele)` 与 `(module Ele2)` 是
不同类型，不能进同一个 list。要复用就引用同一个签名名。

### 33.4 异构实现同表

抽象类型让内部表示不同的实现共存于一个 list——每个元素各自带着
不同的「元素类型」：

```ocaml
module I_impl = struct                    (* int 内部表示 *)
  type ele = int
  let zero = 100
  let add1 x = x + 2
  let show x = string_of_int x
end

let impls : (module Ele) list = [m_f; (module I_impl)]

List.iter
  (fun m ->
    let module M = (val m : Ele) in
    print_endline (M.show (M.add1 M.zero)))
  impls
```

这是运行期「策略选择」的地道写法。

### 33.5 带类型细化的首类模块

`(module S with type t = ...)` 把抽象类型钉死，函数签名随之明确
（Real World OCaml 的惯用法）：

```ocaml
let apply_float (m : (module Ele with type ele = float)) (x : float) =
  let module M = (val m : Ele with type ele = float) in
  M.show (M.add1 x)

apply_float (module F_impl) 1.5      (* 2.5 *)
```

`I_impl` 的 `ele` 是 int，塞不进这个参数——类型系统替你把关。

### 33.6 动态构造模块

吃一个首类模块、产一个新首类模块——运行期组装：

```ocaml
let mk_pair (m : (module Ele with type ele = float))
  : (module Ele with type ele = float * float) =
  let module M = (val m : Ele with type ele = float) in
  (module struct
     type ele = float * float
     let zero = (M.zero, M.zero)
     let add1 (a, b) = (M.add1 a, b)
     let show (a, b) = Printf.sprintf "(%s, %s)" (M.show a) (M.show b)
   end : Ele with type ele = float * float)
```

从「处理单个 float 的模块」动态造出「处理 float 对偶的模块」，
旧模块的行为被新模块复用。

### 33.7 签名是可见性手术刀

`:` 约束掐掉具体类型；`with type` 把类型方程补回去：

```ocaml
module F_hidden = (F_impl : Ele)         (* add1 : F_hidden.ele -> ...，
                                            外部造不出 ele 的值 *)
(* F_hidden.add1 2.0   编译错：float 不是 F_hidden.ele *)

module type Ele_f = sig include Ele with type ele = float end
module F_revealed = (F_impl : Ele_f)
F_revealed.add1 2.5                      (* 又能用于 float *)
```

这不是 bug，是签名在保护表示——强制走 `zero` 出发，模块作者才
能自由更换内部表示（`F_impl` 的 ele 换成 `float * float` 也不影响
使用者）。

### 33.8 私有抽象类型：`type hour = private int`

介于抽象与具体之间：**表示公开可打印、可比较，但不能构造**。

```ocaml
module type Hoursig = sig
  type hour = private int
  val zero : hour
  val inc : hour -> hour
end

module Hour : Hoursig = struct
  type hour = int
  let zero = 0
  let inc n = (n + 1) mod 24
end
```

```ocaml
let start = Hour.zero and next = Hour.inc (Hour.inc Hour.zero)
start < next                (* true —— 继承 int 的比较 *)
(start :> int) = 0          (* true —— 显式上行强制回 int *)
(* Hour.inc 2     编译错：裸 int 进不去 *)
(* start = 0      编译错：hour 不与 int 直接相等 *)
```

结构化类型也能私有：`type time = private int * int * int`。
适合「想要具体表示的效率与可读性、又不想让调用方乱造值」的场景
（时钟、句柄、ID）。

### 33.9 局部抽象类型：把「类型」传进 functor

`(type ele)` 在函数参数表里造一个仅本函数可见的抽象类型，它**能
出现在 functor 参数的类型描述里**——普通多态 `'a` 做不到：

```ocaml
let sort_uniq (type ele) (cmp : ele -> ele -> int) (l : ele list) =
  let module S = Set.Make (struct type t = ele let compare = cmp end) in
  S.elements (List.fold_right S.add l S.empty)

sort_uniq Char.compare ['a'; 'z'; 'a'; 'd'; 'd']   (* [a; d; z] *)
```

对照（编译不过）：

```ocaml
let sort_uniq_bad (cmp : 'a -> 'a -> int) (l : 'a list) =
  let module S = Set.Make (struct type t = 'a let compare = cmp end) in ...
(* Error: Unbound type parameter 'a —— 多态变量逃不出模块定义边界 *)
```

这也是 GADT 代码里 `fun (type a) ->` 写法的同族工具。

### 33.10 破坏性替换 `:=` 与 `module type of`

`with type t = τ` 保留类型方程（签名里仍有 `type t = τ`）；
`with type t := τ` **把 t 从签名里抹掉**、用 τ 顶替：

```ocaml
module type Ele_stripped = sig include Ele with type ele := float end
(* 签名里连 type 声明都没有了，只剩 zero/add1/show : float 相关 *)
```

`module type of M` 从模块反推签名，可再接 `with` 做手术：

```ocaml
module type Of_F = module type of F_impl
module type Fancy =
  sig include module type of struct include F_impl end with type ele := float end
```

### 33.11 多参数函子与部分应用

函子可以有多个模块参数，逐个应用、也能只喂一半：

```ocaml
module type B = sig val b : int end
module F = functor (X1 : B) (X2 : B) -> struct
  let c = X1.b + X2.b
end

module C1 = F (B1)          (* 剩一个参数的函子 *)
module C2 = C1 (B2)         (* c = 3 *)
```

### 33.12 本章小结

| 工具 | 一句话 |
|---|---|
| `let open M in` / `M.(...)` | 局部借用名字 |
| `include M` | 把名字抄进新模块，可覆盖 |
| `(module M : S)` / `(val m : S)` | 模块装进值、值还原成模块 |
| `(module S with type t = τ)` | 首类模块带类型细化 |
| `: S` | 掐掉表示 |
| `with type t = τ` | 补回类型方程 |
| `with type t := τ` | 抹掉类型声明 |
| `module type of M` | 从模块反推签名 |
| `type t = private τ` | 可打印不可构造 |
| `(type t)` | 函数级抽象类型，能进 functor |
| `functor (A) (B) ->` | 多参数函子，柯里化应用 |

示例 29 把以上每一条都跑了一遍。

---
上一章：[32 · 延迟求值：lazy 与延迟流](32-lazy.md) ｜ 下一章：[34 · 命令式进阶：弱多态、四向链表与命令式容器](34-imperative-deep.md) ｜ 返回：[README](../README.md)
