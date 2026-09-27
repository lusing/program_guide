# 31 · 带标签的函数参数与可选参数

对应示例：`../examples/27_labeled_args.ml`

OCaml 从 3.0 版起引入了 Jacques Garrigue 设计的标签参数（labeled
arguments）与可选参数（optional arguments）。标签带来三个便利：

1. **可读性**：调用点的参数含义一目了然，不再靠数位置猜；
2. **顺序自由**：带标签的实参可以按任意顺序给；
3. **任意部分求值**：可以抽走中间的某个参数做偏应用。

本章按《OCaml 语言编程基础教程》第 2.11 节的脉络展开（Real World
OCaml 第 2 章亦有涉及），全部行为在 OCaml 5.4.1 上实测。

### 31.1 位置参数的谜语

```ocaml
let f a b c = a + String.length b + List.length c
```

调用 `f 1 "ab" [1; 2]` 时，读代码的人必须记住参数顺序才能明白
`1` 是什么、`"ab"` 是什么。三个不同类型的参数尚可，一旦参数同型
（比如 `copy src dst` 还是 `copy dst src`？），位置就成了谜语。

### 31.2 标签参数：`~x`

在参数名前加 `~`：

```ocaml
let f ~x ~y ~z = x + String.length y + List.length z
(* val f : x:int -> y:string -> z:'a list -> int *)
```

类型里**带标签**：`x:int`。函数体内照常用 `x`（不带波浪号）。
调用时可以按位置给，也可以用标签给——顺序任意：

```ocaml
f 1 "ab" [1; 2]                      (* 按位置 *)
f ~y:"ab" ~z:[1; 2] ~x:1             (* 按标签，顺序打乱 *)
```

**punning（双关）**：标签名恰与变量名相同时，`~x:x` 可简写成 `~x`：

```ocaml
let x = 1 and y = "ab" and z = [1; 2] in
f ~z ~y ~x
```

### 31.3 按任意标签做部分求值

无标签时偏应用只能从头截断；有标签可以抽走**中间**参数：

```ocaml
let cat3 ~x ~y ~z = x ^ y ^ z
let cat_xz ~x ~z = cat3 ~x ~y:"-" ~z   (* 抽走中间的 ~y *)
```

### 31.4 可选参数

两种形式。

**带缺省值**（常用）：

```ocaml
let greet ?(punct = "!") name = "hi " ^ name ^ punct
greet "ml"                         (* "hi ml!" —— 省略则用缺省值 *)
greet ~punct:"?" "ml"              (* "hi ml?" *)
```

**不带缺省值**：`?x` 形式，函数体内 `x` 是 `option`：

```ocaml
let sub_opt ?base n =
  match base with
  | None -> n
  | Some b -> n - b
```

**大坑：可选参数不能是最后一个参数**。`let g ?(a = 1) = ...`
直接 Syntax error——后面必须跟一个非可选参数来「钉住」调用时机：
编译器看到非可选参数到齐，才把剩下的可选参数按缺省值收尾。这也
解释了标准库的参数排布惯例：`ListLabels.fold_left ~f ~init l`，
实数据参数永远垫底。

**坑（实测）**：带缺省值的可选参数在函数体内已经是套用过缺省值的
普通值——想在递归里「转发」它是不行的，`repeat ?sep ...` 会报
`The value sep has type string but an expression was expected to be
string option`。转发要在**还是 option 的那一层**做（见 31.5），
递归改用内部辅助函数。

### 31.5 `?x` 转发

外层函数不解释、原样把可选参数传给内部调用：

```ocaml
let repeat ?(sep = ",") n s =
  let rec go k =                        (* 缺省值已套用，递归用辅助函数 *)
    if k <= 0 then ""
    else s ^ (if k = 1 then "" else sep) ^ go (k - 1)
  in
  go n

let banner ?sep s = "[" ^ repeat ?sep 3 s ^ "]"   (* ?sep 转发 *)
banner "go"                 (* [go,go,go] *)
banner ~sep:"|" "go"        (* [go|go|go] *)
```

`banner` 里的 `?sep`（不带缺省值）类型是 `string option`；
`repeat ?sep ...` 表示「调用方给了我 `sep` 就传下去，没给就也不给」。

### 31.6 显式类型标注

```ocaml
let typed     ~x ~(y : int) ~z = x + y + List.length z
let typed_opt ?(x : int option) y = match x with Some v -> v + y | None -> y
let typed_def ?(x : int = 1) y = x + y
```

三种形式：`~(y : int)`、`?(x : int option)`、`?(x : int = 1)`。

### 31.7 高阶函数与标签：顺序必须一致

```ocaml
let g ~x ~y = x * 10 + y
let h1 g x y = g ~x ~y        (* 形参 g 以 ~x ~y 顺序应用 —— 通过 *)
```

两个编译不过的写法（收进注释的常驻陷阱）：

```ocaml
let h2 g x y = g ~y ~x        (* Error: 标签顺序与 g 的定义不一致 *)
h1 (+) 1 2                    (* Error: 带标签的形参不能喂无标签函数 *)
```

要点：

- 实参函数**定义时的标签顺序**必须与高阶函数**应用它的顺序**一致；
- 形参类型是带标签的函数类型时，不能传 `(+)` 这类无标签函数，
  要写 `fun ~x ~y -> x + y` 显式接标签。

### 31.8 带标签的标准库

| 原始库 | 带标签的库 |
|---|---|
| `List` | `ListLabels` |
| `String` | `StringLabels` |
| `Array` | `ArrayLabels` |
| `Hashtbl` | `MoreLabels.Hashtbl` |
| `Set` | `MoreLabels.Set` |
| `Map` | `MoreLabels.Map` |
| `Unix` | `UnixLabels` |

同一个 `fold_left` 的两种接口：

```ocaml
List.fold_left (+) 0 [1; 2; 3]                      (* ('a -> 'b -> 'a) -> 'a -> ... *)
ListLabels.fold_left ~f:(+) ~init:0 [1; 2; 3]       (* f:... -> init:... -> ... *)
```

`MoreLabels.Hashtbl` 的日常：

```ocaml
let tbl : (string, int) MoreLabels.Hashtbl.t = MoreLabels.Hashtbl.create 16
MoreLabels.Hashtbl.replace tbl ~key:"ocaml" ~data:5
MoreLabels.Hashtbl.find tbl "ocaml"
```

### 31.9 选型建议

1. 参数多、类型相同、容易调换位置——上标签；
2. 函数要长期演进、老调用点不能改——新参数做成可选；
3. **签名（模块接口）里避免可选参数**：与抽象类型、functor 组合时
   类型推导容易出问题（书上原话：避免在模块中使用可选参数）；
4. 参数少时加标签纯属噪音——`id ~x` 不比 `id x` 更清楚。

### 31.10 本章小结

标签参数把「参数的位置语义」显式化，可选参数把「参数的缺省语义」
显式化。两者都是纯编译期机制，运行时零开销；代价是高阶函数上的
类型约束更严格。示例 27 把本章全部行为跑了一遍。

---
上一章：[30 · ocamllex：词法分析器生成器](30-ocamllex.md) ｜ 下一章：[32 · 延迟求值：lazy 与延迟流](32-lazy.md) ｜ 返回：[README](../README.md)
