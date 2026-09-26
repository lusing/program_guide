# 06 · 元组与记录

> 对应示例：`examples/04-tuples.sml`


## 6.1 元组就是字段名为 1、2、3… 的记录

SML 里元组和记录是**同一种东西**的两种写法：

```sml
val t = (1, "two", 3.0)              (* int * string * real *)
val r = {1 = 1, 2 = "two", 3 = 3.0}  (* 完全等价 *)
```

`t = r` 是 `true`。类型写作 `int * string * real`，那个 `*` 是类型构造子，和乘法没关系。

## 6.2 两种选择子

```sml
val t = (1, "two", 3.0)

val _ = #1 t     (* 1 *)
val _ = #2 t     (* "two" *)

val p = {name = "alice", age = 30}
val _ = #name p  (* "alice" *)
val _ = #age p   (* 30 *)
```

`#1` 是**位置**选择子，`#name` 是**字段名**选择子。注意它们是**函数**，不是语法结构：`#1` 的类型是 `'a * 'b -> 'a`。

## 6.3 用模式解构比用选择子好

```sml
(* 位置解构 *)
fun swap (x, y) = (y, x)

(* 记录解构：写出字段名 *)
fun greet {name, age} = name ^ " is " ^ Int.toString age
```

记录解构是最推荐的写法：字段名直接在参数位置列出来，函数签名自己就是文档。

## 6.4 记录模式默认是「精确匹配」

**少写字段就不匹配**：

```sml
val p = {name = "alice", age = 30, city = "beijing"}

fun bad {name, age} = name        (* 类型错！{name, age} 不是 {name, age, city} *)
```

想允许多余字段，必须显式写 `...`：

```sml
fun ok {name, age, ...} = name ^ " / " ^ Int.toString age
```

那条 `...` 不是装饰，是**必需的**。而且它反过来还有个大坑 —— 见下节。

## 6.5 flex record：不写全字段又不用 `...`

```sml
fun describe person = #name person ^ "(" ^ Int.toString (#age person) ^ ")"
```

这段代码的推断类型里，`person` 的类型是「一个至少含 `name` 和 `age` 的记录，其余字段待定」。这叫**不收敛的 flex record**。三家实测：

| 实现 | 结果 |
|---|---|
| SML/NJ | **编译错误** `unresolved flex record` |
| Poly/ML | 通过 |
| MLton | 通过 |

SML/NJ 对 flex record 更严格（这也符合标准的保守解读）。**解决办法是显式写清记录类型**：

```sml
type person_t = {name : string, age : int, city : string}

fun describe (p : person_t) = #name p ^ "(" ^ Int.toString (#age p) ^ ")"
```

类型一旦写死，三家行为完全一致。**结论：跨实现时不要依赖 flex record，把记录类型写清楚。**

## 6.6 记录相等是结构相等

记录是相等类型（当且仅当成员都是）：

```sml
val a = {x = 1, y = 2}
val b = {x = 1, y = 2}
val _ = a = b        (* true，逐字段比 *)
```

但字段的**书写顺序**不影响相等 —— 记录是集合不是序列。

## 6.7 嵌套

```sml
val nested = {pos = (1, 2), label = {text = "origin", bold = false}}

fun show ({pos = (x, y), label = {text, ...}, ...} : {...}) = ...
```

嵌套记录的解构可以一次到位，模式写起来像 JSON 的结构。

## 6.8 元组不适合当「多返回值」以外的东西

元组的定位就是「一次返回几个值」：

```sml
fun divMod (a, b) = (a div b, a mod b)
val (q, r) = divMod (17, 5)
```

**要表达「一堆命名字段」就用记录**，别用三元组然后猜 `#2` 是什么。

## 6.9 元组 vs 列表

| | 元组 | 列表 |
|---|---|---|
| 元素类型 | **可以不同** | **必须相同** |
| 长度 | 声明时固定 | 运行时可变 |
| 类型 | `int * string` | `int list` |
| 访问 | 模式解构 / `#n` | 模式解构 / `List.nth` |

```sml
val pair = (1, "one")        (* 合法 *)
val bad = [1, "one"]         (* 类型错 *)
```

**「将来可能变长」就用列表，「类型不一样」就用元组或记录。**

---
