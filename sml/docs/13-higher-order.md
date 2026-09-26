# 13 · 高阶函数与闭包

> 对应示例：`examples/11-higher-order.sml`


## 13.1 函数就是值

SML 里函数是一等公民：可以传参、可以返回、可以放列表、可以用 `let` 绑定。

```sml
fun twice f x = f (f x)
val _ = twice (fn n => n * 3) 2        (* 18 *)
```

`twice` 的类型是 `('a -> 'a) -> 'a -> 'a`。注意那两个 `'a` 是**同一个** —— 因为 `f` 的输入输出必须同型才能嵌套调用两次。

## 13.2 柯里化 vs 元组参数

```sml
fun add1 (a, b) = a + b      (* int * int -> int   元组参数 *)
fun add2 a b = a + b         (* int -> int -> int  柯里化 *)
```

两者都能用，但**偏应用只对柯里化形式成立**：

```sml
val inc = add2 1             (* int -> int，一个现成的加 1 函数 *)
val _ = inc 41               (* 42 *)

(* add1 1 是类型错：1 不是 int * int *)
```

**选择标准**：

- 需要**偏应用**、需要**当函数传给别人** → 柯里化
- 参数之间有「主从关系」（主参数在最后） → 柯里化
- 参数是一组对等的值 → 元组

SML 标准库两种都有：`List.map f xs` 是柯里化（`List.map f` 拿到一个「映射函数」很有用），`Int.max (a, b)` 是元组（`Int.max` 本身就是你要传给 `foldl` 的那个函数）。

## 13.3 偏应用造工具函数

```sml
fun scaleBy factor x = x * factor
val double = scaleBy 2
val triple = scaleBy 3

fun padTo width s = StringCvt.padLeft #" " width s
val pad8 = padTo 8
```

`scaleBy 2` 立刻得到一个固定了 `factor` 的新函数。**「先给一部分参数」是 SML 里最常用的代码复用手段**，比写一堆 `double`/`triple` 函数干净。

## 13.4 闭包：函数记住它出生时的环境

```sml
fun makeCounter start =
    let
        val count = ref start
    in
        fn () => (count := !count + 1; !count)
    end

val c1 = makeCounter 0
val c2 = makeCounter 100

val _ = c1 ()     (* 1 *)
val _ = c1 ()     (* 2 *)
val _ = c2 ()     (* 101 —— 完全独立的另一个 count *)
```

`c1` 和 `c2` 各自捕获了**不同的** `count` 单元。这就是闭包：

- 函数体里引用了外层的 `ref`
- 外层函数返回后，那个 `ref` **不会**被回收（被闭包引用着）
- 每次调用 `makeCounter` 都分配一个新的 `ref`

**闭包 + `ref` 是 SML 里做「有状态对象」的标准手段**，第 18 章会用它写一个银行账户。

## 13.5 组合：`o`

```sml
val f = Int.toString o (fn n => n * 2)
val _ = f 3        (* "6" *)
```

`o` 是函数组合：`(f o g) x = f (g x)`。优先级是 3（低于 `=`），所以经常需要括号。

**`o` 不能当变量名**（第 5 章那个坑）。要用它做参数得写 `op o`：

```sml
fun composeAll fs = foldl (op o) (fn x => x) fs
```

## 13.6 `op`：把中缀运算符变成前缀函数

```sml
op +        (* int * int -> int（重载） *)
op ^        (* string * string -> string *)
op ::       (* 'a * 'a list -> 'a list *)
```

用法：

```sml
foldl (op +) 0 [1, 2, 3]              (* 6 *)
foldl (op ^) "" ["a", "b"]            (* "ab" *)
foldl (op ::) [] [1, 2, 3]            (* [3,2,1] —— 注意是倒的 *)
```

`op +` 是重载的，类型靠上下文定：`foldl (op +) 0 xs` 里的 `0` 把它定成整数加法。

## 13.7 函数放进列表

```sml
val ops = [fn n => n + 1, fn n => n * 2, fn n => n - 3]
val _ = map (fn f => f 10) ops        (* [11, 20, 7] *)
```

这是「用数据驱动行为」的最小形式。往上是「一张表定义状态机」、往上是「插件架构」。

## 13.8 手写一遍 map/filter

```sml
fun myMap _ [] = []
  | myMap f (x :: rest) = f x :: myMap f rest

fun myFilter _ [] = []
  | myFilter p (x :: rest) =
        if p x then x :: myFilter p rest else myFilter p rest
```

标准库里的 `map` / `filter` 就是这么两行。**理解这一点之后，「高阶函数」就不再神秘** —— 它只是「把一个函数当普通参数传进去」。

## 13.9 什么时候用高阶函数

- **能用现成的就用**：`map` / `filter` / `foldl` / `find` / `partition` 覆盖了绝大多数需求。
- **要写递归时先问一句**：「这是不是某个 fold？」是就用 fold，代码短而且不会写错边界。
- **别为了高阶而高阶**：一层嵌套的 `fn` 里再套 `fn`，可读性会掉。该起名字就起名字。

---
