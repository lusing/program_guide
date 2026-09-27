# 39 · 语言扩展拾遗

对应示例：`../examples/35_lang_ext.ml`

手册「Language extensions」部分收录的小而锐利的语言特性——
不显眼、但真实代码里高频出没。本章一口气收齐八件。

### 39.1 generative functor：`F ()`

```ocaml
module Counter () = struct
  type t = int
  let mutable_state = ref 0
  let bump () = incr mutable_state; !mutable_state
end

module CA = Counter ()
module CB = Counter ()      (* CA.t 与 CB.t 是不同类型！ *)
```

- generative（4.02+）：每次应用产出**新鲜类型**与新鲜状态；
- applicative（默认）：同参多次应用类型相同——`F (X0)` 两次得到
  的 `C1.t` 与 `C2.t` 可以互换（示例 39 有对照）；
- **坑（实测）**：`module A = G () and B = G ()` 语法非法，分两行写；
- 副作用红利：generative 函子体内允许 unpack 首类模块。

选型：要「每实例一个身份」（状态隔离、tag 唯一）选 generative；
要「同参即同型」（Set/Map 的模块相等语义）选 applicative。

### 39.2 `open!` 与 generalized open

```ocaml
open! List                (* 我知道会遮蔽，别报警（4.01+） *)
```

4.08 起 `open` 的对象从模块名扩展为**模块表达式**：

```ocaml
(* 3a. 带签名约束的视图：hidden 被藏起来 *)
open (M : sig val x : int end)

(* 3b. 直接开 functor 应用结果 *)
let sort_uniq l =
  let open Set.Make (Int) in
  elements (of_list l)

(* 3c. open struct：结构里就地引入局部成员 *)
module W = struct
  open struct let helper y = y * 2 end
  let w = helper 21
end
```

**坑（实测）**：`open struct` 引入的局部类型不能出现在外围结构的
签名里（类型逃逸），除非定义成与非局部类型相等。

### 39.3 `let exception`：局部异常

```ocaml
let find_first_negative l =
  let exception Negative in
  try
    List.iter (fun x -> if x < 0 then raise Negative) l;
    None
  with Negative -> Some (List.find (fun x -> x < 0) l)
```

异常只在 `let` 作用域内可见可捕——不污染顶层命名空间，类型
也比裸 `exn` 精确。

### 39.4 `{< ... >}` 函数式对象更新与 `Oo.copy`

```ocaml
class functional_point (x0 : int) = object
  val x = x0
  method get_x = x
  method move d = {< x = x + d >}    (* 不改自己，返回副本 *)
end

let p = new functional_point 5
let q = p#move 7          (* p 仍是 5，q 是 12 *)
```

- `{< 字段 = 值 >}` 只能写在**方法体内**；
- `Oo.copy` 是任何对象的浅克隆（字段独立、字段内容共享——字段
  是 ref 时深改会影响两个对象）。

### 39.5 refutation case：`| _ -> .`

```ocaml
type _ term = Int : int -> int term | Bool : bool -> bool term

let get_int : int term -> int = function
  | Int n -> n
  | _ -> .      (* 逼穷尽检查把 _ 展开到构造子级再试 *)
```

普通穷尽检查只试「省略的模式可否类型化」；`-> .` 逼它把通配
拆成构造子逐一证伪。**坑（实测）**：证伪臂必须用通配模式——
写 `| Bool _ -> .` 的话模式自己先挂（`bool term` 对不上
`int term`）。

### 39.6 字面量全集

```ocaml
let hex = 0xFF and oct = 0o17 and bin = 0b1010 and grouped = 1_000_000
let w32 = 7l and w64 = 7L and wnat = 7n          (* int32/int64/nativeint *)
let supersign = "\u{207A}"                        (* Unicode -> UTF-8 字节 *)
let json = {|{"a": "b\nc", "t": true}|}           (* 免转义 *)
let nested = {html|<a data-x="|">|</a>|html}      (* 带 id 变体可嵌套 *)
let longstr = "abc \
   def"                                            (* 行续接：\ + 换行 + 缩进忽略 *)
```

速记：`l` = int32、`L` = int64、`n` = nativeint（大小写敏感）；
quoted string 的 id 只能是小写字母与下划线。

### 39.7 `module rec`：递归模块

```ocaml
module rec Even : sig val even : int -> bool end = struct
  let even n = if n = 0 then true else Odd.odd (n - 1)
end
and Odd : sig val odd : int -> bool end = struct
  let odd n = if n = 0 then false else Even.even (n - 1)
end
```

值部分必须「可推迟」（函数 / lazy），直接的值循环会报
illegal recursive module。

### 39.8 本章小结

| 特性 | 一句话 |
|---|---|
| `F ()` generative | 每次应用新鲜类型与状态 |
| `open!` / `open <模块表达式>` | 压遮蔽告警 / 开视图、functor 结果、struct |
| `let exception` | 作用域内异常 |
| `{< >}` / `Oo.copy` | 方法体内的函数式更新 / 任意对象的浅克隆 |
| `| _ -> .` | 逼穷尽检查干活（GADT 好搭档） |
| 字面量全家 | 0x/0o/0b、l/L/n、`\u{}`、`{||}`、行续接 |
| `module rec` | 互递归模块（值须可推迟） |

---
上一章：[38 · 显式多态与类型注记](38-explicit-poly.md) ｜ 下一章：[40 · OCaml 5 内存模型](40-memory-model.md) ｜ 返回：[README](../README.md)
