# 09 · 代数数据类型

> 对应示例：`examples/07-datatypes.sml`


## 9.1 为什么需要 datatype

`type` 别名只是起个名字，不产生新类型。要表达「这个值只可能是这几种之一」，得用 `datatype`：

```sml
datatype color = Red | Green | Blue
```

`Red`、`Green`、`Blue` 是**值构造子**。它们不是整数，也没有隐含顺序 —— 想要顺序就自己写函数：

```sml
fun colorName Red = "Red"
  | colorName Green = "Green"
  | colorName Blue = "Blue"
```

## 9.2 参数化构造子

构造子可以带参数：

```sml
datatype shape =
    Circle of real
  | Rect of real * real
  | Triangle of real * real * real

fun area (Circle r) = 3.14159265358979 * r * r
  | area (Rect (w, h)) = w * h
  | area (Triangle (a, b, c)) = ...    (* 海伦公式 *)
```

**这就是 SML 的「变体」**：每种情况带自己的数据，模式匹配时编译器保证你处理了所有情况。

## 9.3 递归类型

`datatype` 可以引用自己：

```sml
datatype tree = Leaf | Node of tree * int * tree

fun insert (Leaf, v) = Node (Leaf, v, Leaf)
  | insert (Node (l, x, r), v) =
        if v < x then Node (insert (l, v), x, r)
        else if v > x then Node (l, x, insert (r, v))
        else Node (l, x, r)             (* 重复值不插入 *)

fun inorder Leaf = []
  | inorder (Node (l, x, r)) = inorder l @ [x] @ inorder r
```

顺手就是一个有序二叉搜索树。

## 9.4 表达式树与解释器

这是 `datatype` 最能体现威力的场景：

```sml
datatype expr =
    Num of int
  | Add of expr * expr
  | Mul of expr * expr
  | Neg of expr

fun eval (Num n) = n
  | eval (Add (a, b)) = eval a + eval b
  | eval (Mul (a, b)) = eval a * eval b
  | eval (Neg a) = ~ (eval a)

fun show (Num n) = Int.toString n
  | show (Add (a, b)) = "(" ^ show a ^ "+" ^ show b ^ ")"
  | show (Mul (a, b)) = "(" ^ show a ^ "*" ^ show b ^ ")"
  | show (Neg a) = "~" ^ show a
```

**加了新的构造子（比如 `Div`）之后，编译器会把所有没处理的 `case` 一处一处指出来。** 这是 `datatype` 相对「用字符串/整数标记类型」最大的优势，也是所谓「用类型表达意图」最实在的地方。

## 9.5 withtype：一起声明互相引用的类型

```sml
datatype node = Node of {name : string, children : node list}
```

这已经能跑 —— `node list` 里的 `node` 就是正在定义的类型。但如果要多个类型互相引用：

```sml
datatype expr = Num of int | Call of func
withtype func = {name : string, args : expr list}
```

`withtype` 让这几个类型同时可见，避免「先声明谁」的问题。

## 9.6 互递归的 datatype 用 and

```sml
datatype json =
    JNum of real
  | JStr of string
  | JArr of json list
  | JObj of member list
and member = Member of string * json
```

`and` 让两个 `datatype` 互相引用。

## 9.7 option 和 order 就是普通 datatype

```sml
datatype 'a option = NONE | SOME of 'a
datatype order = LESS | EQUAL | GREATER
```

标准库里没有魔法 —— 你完全可以自己写一个一模一样的。理解这一点之后，`case opt of NONE => ... | SOME v => ...` 就不再是「特殊语法」而是普通的模式匹配。

## 9.8 构造子就是函数

```sml
val f = SOME                    (* 'a -> 'a option *)
val g = map SOME [1, 2, 3]      (* [SOME 1, SOME 2, SOME 3] *)
```

带一个参数的构造子就是**普通函数**，可以直接传。这让「给列表每个元素套一个构造子」这种操作变得极简。

带多个参数的构造子不是函数（`Node` 接受一个元组），要包一层：

```sml
map (fn (l, x, r) => Node (l, x, r)) triples
```

## 9.9 本章示例的其余内容

- 枚举型 `datatype` 和 `case` 配合，等价于别的语言的 `enum` + `switch`，但不是整数、不能瞎转。
- 用 `datatype` 实现对「表达式求值 + 打印」两套递归函数，是理解「类型驱动开发」的最短路径。

---
