# 28 · GADT：广义代数数据类型

对应示例：`../examples/24_gadts.ml`

对应示例：`examples/24_gadts.ml`

### 28.1 让构造子决定类型参数

普通变体：所有构造子造出同一个 `t`。GADT：每个构造子
**声明自己造出什么类型**：

```ocaml
type _ value_kind =
  | KInt : int value_kind
  | KBool : bool value_kind
  | KString : string value_kind
```

于是能写出“一个函数、按构造子返回不同类型”的代码——
这在普通变体上不可能：

```ocaml
let default (type a) (k : a value_kind) : a =
  match k with
  | KInt -> 0
  | KBool -> false
  | KString -> ""
(* default KInt : int，default KBool : bool *)
```

### 28.2 类型安全的动态值（存在类型）

把值连同类型标签打包，取回时只有标签对得上才拿得到——
模式匹配的**类型细化**保证了安全：

```ocaml
type cell = Cell : 'a * 'a value_kind -> cell

let cell_to_int (c : cell) : int option =
  match c with
  | Cell (n, KInt) -> Some n      (* 这里 n 自动是 int *)
  | _ -> None
```

**实测坑（OCaml 5.4.1）**：存在类型的 GADT 模式匹配必须给
函数补**显式参数/返回类型标注**（如上面的 `(c : cell) : int option`），
否则报 `This instance of int is ambiguous: it would escape the
scope of its equation`。原则：凡是有存在类型参与的 match，
把边界类型写清楚。

### 28.3 招牌应用：well-typed by construction 的表达式 AST

```ocaml
type _ expr =
  | Const : int -> int expr
  | BoolConst : bool -> bool expr
  | Add : int expr * int expr -> int expr
  | Lt : int expr * int expr -> bool expr
  | If : bool expr * 'a expr * 'a expr -> 'a expr

let rec eval : type a. a expr -> a = function
  | Const n -> n
  | BoolConst b -> b
  | Add (x, y) -> eval x + eval y
  | Lt (x, y) -> eval x < eval y
  | If (c, t, e) -> if eval c then eval t else eval e
```

`Add (BoolConst true, Const 1)` 直接编译错误；`If` 的两个分支
类型不同也直接编译错误。求值器的类型是 `'a expr -> 'a`：
“这个 AST 求出来是什么类型”在构造时就定了，求值器不需要
任何运行期类型检查。

两个语法细节：

- 递归函数要写 `type a.`（显式全量多态标注），否则递归调用
  无法在不同类型实例上泛化；
- match 臂里的 GADT 类型标注要加括号：`| (Get : a Effect.t) -> ...`
  ——不带括号的 `| Get : a Effect.t ->` 在 5.4.1 是**语法错**
  （第 29 章效应匹配同此）。

### 28.4 类型相等见证

```ocaml
type (_, _) eq = Eq : ('a, 'a) eq
let cast : type a b. (a, b) eq -> a -> b = fun Eq x -> x
```

`Eq` 只能造出 `('a, 'a) eq`——拿到 `(a, b) eq` 就等于拿到
`a = b` 的证明，`cast` 里匹配 `Eq` 时编译器把 a、b 统一，转换
自然安全。`(int, string) eq` 的值无法构造，假证明被编译器挡死。

### 28.5 多态递归需要显式标注

```ocaml
type 'a nest = NNil | NCons of 'a * ('a * 'a) nest

let rec depth : 'a. 'a nest -> int = function
  | NNil -> 0
  | NCons (_, t) -> 1 + depth t
```

每往下一层元素类型都变成 `('a * 'a)`，普通推断会失败；
`'a. 'a nest -> int`（注意带点的形式）告诉编译器“对所有类型
实例都成立”。GADT 上的 `eval` 用 `type a.` 同理。

### 28.6 什么时候用 GADT

用：构造子蕴含类型信息（typed AST/DSL）、类型索引族、
安全转换。代价：类型推断变弱（标注变多）、穷尽性检查变弱、
学习曲线陡——先穷尽普通变体的可能性。

### 28.7 本章小结

- GADT = 构造子声明返回什么类型参数；
- 存在类型参与 match 时必须显式标注边界类型，否则 escape 报错；
- `type a.` / `'a.` 显式标注是多态递归的开关；
- match 臂的 GADT 标注要括号。

---

---
上一章：[27 · 错误处理：option / result 与绑定运算符](error-handling.md) ｜ 下一章：[29 · OCaml 5 并发：Domain 与 Effect](domains-effects.md) ｜ 返回：[README](../README.md)
