# 38 · 显式多态与类型注记

对应示例：`../examples/34_explicit_poly.ml`

手册「Polymorphism」章后半 + 类型定义参考章的深水区：
`'a. τ` 显式全称量词、rank-2 打包、variance 注记、`type nonrec`、
inline records、extensible variants。这些都是普通教程最容易漏、
真实代码里又会撞上的类型系统工具。

### 38.1 非正则递归类型与多态递归

```ocaml
type 'a nest = List of 'a list | Nested of 'a nest
```

递归处参数变了（`'a` → `'a list`）——**非正则**。普通的：

```ocaml
let rec depth = function        (* 编译不过 *)
  | List _ -> 1
  | Nested n -> 1 + depth n
```

失败原因：类型检查器只在**定义点**引入一次类型变量，而递归调用
需要对**每次应用**引入新变量——`'a list nest = 'a nest` 不可满足。
显式全称量词解决：

```ocaml
let rec depth : 'a. 'a nest -> int = function
  | List _ -> 1
  | Nested n -> 1 + depth n
```

`'a. 'a nest -> int` 读作「对所有 'a」。可以只标注量化部分：
`let rec depth2 : 'a. 'a nest -> _ = ...`。

### 38.2 量词标注是承诺，不是待定变量

```ocaml
let loose : 'a -> 'b -> 'c = fun x y -> ignore x; ignore y; 1   (* 合法 *)
let strict : 'a 'b 'c. 'a -> 'b -> 'c = fun x y -> x + y        (* 编译不过 *)
```

普通标注里的 `'a` 只是「待定类型变量」，实现收窄成 int 也合法；
带 `.` 的量词标注承诺**全类型**，单态实现直接被拒。

### 38.3 rank-2：把多态函数当参数

想写 `average f x y = (f x + f y) / 2` 且 x、y 类型可以不同——
`f` 本身必须是多态函数（rank-2）。HM 推断不做 rank-2，但可以
**打包**：

```ocaml
(* 打包 1：量词记录字段 *)
type 'a nest_red = { f : 'elt. 'elt nest -> 'a }
let boxed_len = { f = len }
let average_box nsm x y = (nsm.f x + nsm.f y) / 2

(* 打包 2：量词对象方法 *)
let obj_len = object method f : 'a. 'a nest -> int = len end
let average_obj (obj : < f : 'a. 'a nest -> int >) x y = (obj#f x + obj#f y) / 2
```

不打包的普通版本会把 x、y 统一成同一类型。

### 38.4 variance 注记：`+'a` / `-'a`

```ocaml
type +'a wrap = { v : 'a }
let y : [> `On ] wrap = (x : [`On ] wrap :> [> `On ] wrap)
```

- `+` 协变（产出 `'a`：list、option）、`-` 逆变（消费 `'a`：
  函数参数）、不变（既产又消：ref）；
- 声明会被编译器**核实**：`type -'a bad = 'a list` 直接拒绝
  （list 是协变的，谎报逆变不行）；
- 红利：协变容器随元素放宽子类型（上例的强制合法）。

### 38.5 `type nonrec`

类型定义默认把「正在定义的名字」当递归引用。想遮蔽重定义时：

```ocaml
type t = int
module Shadow = struct
  type nonrec t = bool * t    (* 右边的 t = 外层旧 t（int） *)
end
let v : Shadow.t = (true, 3)
```

**坑（实测）**：同一个编译单元里同名类型不许出现两次——interp
逐句执行能过、byte/native 直接 "Multiple definition"。nonrec 的
舞台是嵌套作用域（4.02.2+）。

### 38.6 inline records

单构造子带多字段，免一次性占位类型：

```ocaml
type color =
  | Named of string
  | RGB of { r : int; g : int; b : int }

let css = function
  | Named s -> s
  | RGB { r; g; b } -> Printf.sprintf "rgb(%d,%d,%d)" r g b
```

字段还能 `mutable`（普通 variant 构造子参数做不到原地改）。

### 38.7 extensible variants：`type .. +=`

`exn` 的推广——开放变体，任何模块事后追加构造子：

```ocaml
type event = ..
type event += Tick of int | Tock of string | Reset

let describe (e : event) = match e with
  | Tick n -> "tick " ^ string_of_int n
  | Tock s -> "tock " ^ s
  | Reset -> "reset"
  | _ -> "unknown event"        (* 通配臂不可省 *)
```

**坑（实测）**：匹配 extensible variant 必须带通配臂，否则
Warning 8 提示 `*extension*`。

### 38.8 本章小结

| 工具 | 一句话 |
|---|---|
| `'a. τ` | 显式全称量词：多态递归必需，且是承诺 |
| `{ f : 'elt. τ }` / `method m : 'a. τ` | rank-2 的两种打包 |
| `+'a` / `-'a` | variance 声明，编译器核实 |
| `type nonrec` | 打断同名递归可见性（嵌套作用域用） |
| `A of { ... }` | 构造子内联记录，字段可 mutable |
| `type .. +=` | 可扩展变体，通配臂保穷尽 |

---
上一章：[37 · 多态变体深水区](37-poly-variants.md) ｜ 下一章：[39 · 语言扩展拾遗](39-lang-ext.md) ｜ 返回：[README](../README.md)
