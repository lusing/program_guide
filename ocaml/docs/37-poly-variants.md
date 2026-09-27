# 37 · 多态变体深水区

对应示例：`../examples/33_poly_variants.ml`

按官方手册「Polymorphic variants」章（Jacques Garrigue 执笔）梳理。
第 9 章只展示了「反引号构造子」的皮；本章讲清它的类型系统——
row type、上下界、交类型、收窄与弱点。

核心前提：**变体标签不属于任何类型**。普通 variant 的构造子在
定义时绑定到唯一类型；多态变体的 `` `Tag `` 由类型系统按每个使用
现场分别推断，无需先定义类型。

### 37.1 row type：`[> ...]` 与 `[< ...]`

```ocaml
let f = function `On -> 1 | `Off -> 0 | `Number n -> n
```

- `[`On; `Off]` 推断为 `[>`Off | `On] list`——**开口**：至少含
  这两个标签，还可能有更多（隐式类型变量）；
- `f` 的参数推断为 `[<`On |`Off |`Number of int]`——**闭口**：
  至多这些标签，匹配时可收窄。

### 37.2 开放匹配与 `as 'a` 类型共享

```ocaml
let f = function `A -> `C | `B -> `D | x -> x
(* 推断：([> `A | `B] as 'a) -> 'a *)
```

最后一臂接住任意标签（匹配开放 → 输入 `[> ]`），且 `x` 原样返回
（输入输出共享同一类型变量 `as 'a`）。`f `E = `E` 由此成立。

### 37.3 交类型：`int & string`

```ocaml
let f1 = function `A x -> x = 1 | `B -> true | `C -> false
let f2 = function `A x -> x = "a" | `B -> true
let f x = f1 x && f2 x        (* f 只能用 `B *)
```

`f` 的参数类型里 `` `A `` 的参数要**同时是** int 和 string——写成
`int & string`。不存在这种值，所以 `` `A `` 实际不可用，只剩
`` `B ``。两个都对同一标签有要求的函数组合时，交类型会让标签
「消失」。

### 37.4 固定 row 类型与放宽强制

类型缩写是**固定** row（没有 `<` `>`），可正常递归：

```ocaml
type 'a vlist = [`Nil | `Cons of 'a * 'a vlist]
type 'a wlist = [`Nil | `Cons of 'a * 'a wlist | `Snoc of 'a wlist * 'a]

let l : int vlist = `Cons (1, `Nil)
let w : int wlist = (l : int vlist :> int wlist)     (* 放宽 *)
let open_l : [> int vlist ] = (l :> [> int vlist ])  (* 全开放 *)
```

反方向（wlist → vlist）编译不过：`` `Snoc `` 没有去处。

### 37.5 or-模式别名收窄与 `#type` 模式缩写

```ocaml
type myvariant = [`Tag1 of int | `Tag2 of bool]

let g = function
  | #myvariant as x -> g1 x       (* x 的类型收窄为 myvariant *)
  | `Tag3 -> "Tag3"
```

- `#myvariant` 等价于把类型定义展开成 or-模式
  `` (`Tag1 (_ : int) | `Tag2 (_ : bool)) ``；
- 配合 `as` 别名，别名的类型被收窄到枚举的构造子集，可以安全
  转交给只认这几个标签的函数——「增量定义函数」的惯用法：

```ocaml
let eval1 (`Num x) = x
let eval2 eval = function
  | `Plus (x, y) -> eval x + eval y
  | `Num _ as x -> eval1 x       (* 别名收窄，正好能喂 eval1 *)
```

### 37.6 弱点：为什么没有取代普通 variant

1. **表示略重**：缺静态类型信息（构造子名按结构哈希成整数标签），
   只有在巨型数据结构上可测量；
2. **类型纪律弱**：普通 variant 检查「只用声明的构造子」「参数
   类型受约束」；多态变体全靠标注自觉；
3. **打字陷阱**：`` `As `` 不是 `` `A ``，无标注时编译器看不出错：

```ocaml
let sloppy = function
  | `As -> "A"          (* 拼错了！照常编译 *)
  | #abc -> "other"
```

给函数标注 `abc -> string` 后错误立刻现形。**库接口写精确 row、
小程序用普通 variant** 是手册给的选型结论。

**坑（实测）**：`let` 位置的多态变体模式会把 row 闭口成 `[< ...]`，
直接匹配 `int vlist` 报 "does not allow tag `Nil"；模式补类型标注
能过类型关，但穷尽性检查又要求 `Nil` 分支——访问器用完整 `match`
写最省心。

### 37.7 本章小结

| 概念 | 一句话 |
|---|---|
| `` `Tag `` | 不属于任何类型的构造子 |
| `[> ...]` / `[< ...]` | 开口（允许更多）/ 闭口（允许更少） |
| `as 'a` | 输入输出类型共享 |
| `int & string` | 交类型：两个约束的合取，常使标签不可用 |
| `:> ` 放宽 | 固定 row 可以放大到超集 |
| `#type` 模式 | 类型缩写展开成 or-模式 |
| `as` 别名收窄 | or-模式的别名只带枚举过的构造子 |

示例 37 把以上每条都跑了一遍（含 `` `As `` 陷阱的「能编译」现场）。

---
上一章：[36 · 美化打印：%a 自定义打印机与 Format 盒子](36-pp-printers.md) ｜ 下一章：[38 · 显式多态与类型注记](38-explicit-poly.md) ｜ 返回：[README](../README.md)
