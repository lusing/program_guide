# 08 · 列表与高阶列表函数

对应示例：`../examples/06_lists.ml`

对应示例：`examples/06_lists.ml`

### 8.1 列表是函数式编程的面包和黄油

列表是函数式语言中最基本的数据结构。在 OCaml 中，列表是**单链表**，所有元素类型相同（同质）。

列表有两种构造方式：

- `[]`：空列表
- `x :: rest`：在列表 `rest` 的前面加上元素 `x`（`::` 读作 cons）

`[1; 2; 3]` 是 `1 :: 2 :: 3 :: []` 的语法糖。

```ocaml
let empty = []
let single = 42 :: []
let nums = 1 :: 2 :: 3 :: []
let nums2 = [1; 2; 3; 4; 5]
```

列表的类型是 `'a list`，其中 `'a` 是元素的类型。比如 `int list` 是整数列表，`string list` 是字符串列表。

**重要**：`::` 是 O(1) 操作——它只是创建一个新的链表节点，指向原来的列表。而列表拼接 `@` 是 O(n)，其中 n 是第一个列表的长度。

### 8.2 列表拼接 @

`@` 运算符把两个列表拼在一起：

```ocaml
let a = [1; 2; 3]
let b = [4; 5; 6]
let c = a @ b    (* [1; 2; 3; 4; 5; 6] *)
```

为什么 `@` 是 O(n)？因为列表是单链表，要拼接两个列表，必须把第一个列表完整复制一遍，让它的最后一个节点指向第二个列表。第二个列表不需要复制（共享）。

所以如果你要往列表前面加元素，用 `::`（O(1)）；往后面加，用 `@`（O(n)）。这也是为什么函数式代码通常先反向构建列表（不断往前面加），最后再 `List.rev` 翻转过来——这样总的时间复杂度还是线性的。

### 8.3 List.map：转换每个元素

`List.map` 可能是最常用的高阶列表函数。它的类型是：

```ocaml
val map : ('a -> 'b) -> 'a list -> 'b list
```

意思是：给我一个 `'a -> 'b` 的函数和一个 `'a list`，我给你一个 `'b list`——把函数应用到每个元素上，收集结果。

```ocaml
let nums = [1; 2; 3; 4; 5]
let squares = List.map (fun x -> x * x) nums
(* [1; 4; 9; 16; 25] *)

let strs = List.map string_of_int nums
(* ["1"; "2"; "3"; "4"; "5"] *)
```

`List.map` 是函数式编程的核心抽象之一。它把「对列表中每个元素做某事」这个模式封装起来，你只需要关心「做什么」，不需要关心「怎么遍历」。

自己实现 `map` 也很简单：

```ocaml
let rec my_map f lst =
  match lst with
  | [] -> []
  | x :: rest -> f x :: my_map f rest
```

这个实现是直接的，但它不是尾递归的（见第 11 章）。标准库的 `List.map` 在旧版本中也不是尾递归的，较新版本做了优化。

### 8.4 List.filter：选择元素

`List.filter` 保留满足谓词的元素，丢掉不满足的：

```ocaml
val filter : ('a -> bool) -> 'a list -> 'a list
```

```ocaml
let evens = List.filter (fun x -> x mod 2 = 0) nums
(* [2; 4] *)

let bigs = List.filter (fun x -> x > 3) nums
(* [4; 5] *)
```

谓词函数（返回 bool 的函数）也叫「判断」（predicate）。

### 8.5 fold：从列表中累积一个值

`fold`（折叠）是最通用的列表操作——`map` 和 `filter` 都可以用 `fold` 来实现。

OCaml 标准库有两个 fold 函数：`List.fold_left` 和 `List.fold_right`。

**List.fold_left**：

```ocaml
val fold_left : ('a -> 'b -> 'a) -> 'a -> 'b list -> 'a
```

从左到右遍历列表，用一个累积器（accumulator）累积结果。第一个参数是「累积函数」（接受累积器和当前元素，返回新的累积器），第二个参数是初始值，第三个是列表。

```ocaml
let sum = List.fold_left (fun acc x -> acc + x) 0 [1; 2; 3; 4; 5]
(* 15 *)

let product = List.fold_left ( * ) 1 [1; 2; 3; 4; 5]
(* 120 *)

let length lst = List.fold_left (fun acc _ -> acc + 1) 0 lst
```

`fold_left` 是尾递归的（见第 11 章），所以即使列表很长也不会栈溢出。

**List.fold_right**：

```ocaml
val fold_right : ('a -> 'b -> 'b) -> 'a list -> 'b -> 'b
```

从右到左遍历列表。注意参数顺序和 `fold_left` 不一样——列表在初始值前面。

```ocaml
let sum = List.fold_right (fun x acc -> x + acc) [1; 2; 3; 4; 5] 0
```

`fold_right` 不是尾递归的，所以长列表可能会栈溢出。但 `fold_right` 有时比 `fold_left` 更直观，特别是当你需要保持元素顺序的时候。

一个直观的对比：

```ocaml
let left_result = List.fold_left (fun acc x -> "(" ^ acc ^ "+" ^ string_of_int x ^ ")") "0" [1;2;3]
(* "((0+1)+2)+3" *)

let right_result = List.fold_right (fun x acc -> "(" ^ string_of_int x ^ "+" ^ acc ^ ")") [1;2;3] "0"
(* "(1+(2+(3+0)))" *)
```

**用 fold 实现 map 和 filter**：

```ocaml
let map_via_fold f lst =
  List.fold_right (fun x acc -> f x :: acc) lst []

let filter_via_fold p lst =
  List.fold_right (fun x acc -> if p x then x :: acc else acc) lst []
```

因为 `fold_right` 的顺序和 `::` 的构造顺序一致，所以用 `fold_right` 实现 map 和 filter 不需要翻转。

### 8.6 其他常用 List 函数

**List.init**：生成一个列表，第 i 个元素是 `f i`。

```ocaml
val init : int -> (int -> 'a) -> 'a list

let squares = List.init 10 (fun i -> i * i)
(* [0; 1; 4; 9; 16; 25; 36; 49; 64; 81] *)
```

**List.length**：列表长度。O(n) 时间，因为列表是链表，必须遍历才能知道长度。

```ocaml
val length : 'a list -> int
```

**List.rev**：反转列表。O(n) 时间。

```ocaml
val rev : 'a list -> 'a list
```

**List.nth**：取第 n 个元素（从 0 开始）。O(n) 时间。越界抛出 `Failure`。

```ocaml
val nth : 'a list -> int -> 'a
```

**List.find**：找到第一个满足谓词的元素。找不到抛出 `Not_found`。

```ocaml
val find : ('a -> bool) -> 'a list -> 'a

let first_even = List.find (fun x -> x mod 2 = 0) [1; 2; 3; 4]
(* 2 *)
```

**List.exists**：是否存在满足谓词的元素。

```ocaml
val exists : ('a -> bool) -> 'a list -> bool

let has_big = List.exists (fun x -> x > 10) [1; 2; 3]
(* false *)
```

**List.for_all**：是否所有元素都满足谓词。

```ocaml
val for_all : ('a -> bool) -> 'a list -> bool

let all_pos = List.for_all (fun x -> x > 0) [1; 2; 3]
(* true *)
```

**List.partition**：把列表分成两部分——满足谓词的和不满足的。

```ocaml
val partition : ('a -> bool) -> 'a list -> 'a list * 'a list

let (evens, odds) = List.partition (fun x -> x mod 2 = 0) [1; 2; 3; 4; 5]
(* evens = [2; 4], odds = [1; 3; 5] *)
```

**List.iter**：对每个元素执行一个副作用函数，返回 `unit`。

```ocaml
val iter : ('a -> unit) -> 'a list -> unit

List.iter print_int [1; 2; 3]
```

**List.sort**：排序。第一个参数是比较函数。

```ocaml
val sort : ('a -> 'a -> int) -> 'a list -> 'a list

let sorted = List.sort compare [3; 1; 4; 1; 5; 9; 2; 6]
(* [1; 1; 2; 3; 4; 5; 6; 9] *)
```

`compare` 是标准库的多态比较函数，返回 -1、0 或 1。

### 8.7 列表的不可变性与共享

OCaml 的列表是不可变的。`::` 和 `@` 都不会修改原列表——它们创建新的列表。

但「不可变」不意味着「每次都完全复制」。`::` 操作中，新列表的尾部和原列表是**共享**的：

```ocaml
let a = [2; 3]
let b = 1 :: a
```

这里 `b` 的第二个元素及之后和 `a` 是同一块内存。因为列表是不可变的，所以共享是安全的——没人能修改 `a`，所以 `b` 也不会意外改变。

这是函数式数据结构的核心优势：**不可变数据可以安全共享，不需要拷贝，也不需要加锁。**

### 8.8 什么时候不该用列表

列表是函数式编程的主力数据结构，但它不是万能的。以下场景考虑用其他数据结构：

- **需要随机访问**：列表的 `List.nth` 是 O(n)，用 `Array`（O(1) 访问）
- **需要键值对查找**：用 `Hashtbl` 或 `Map`
- **需要在两端高效操作**：用 `Queue` 或自定义的双向链表
- **元素数量很大且需要随机访问**：用 `Array`

列表最适合的场景是：顺序遍历、从前端添加/删除、函数式转换（map/filter/fold）。

### 8.9 本章小结

- 列表是单链表，用 `[]` 和 `::` 构造
- `::` 是 O(1)，`@` 是 O(n)
- `List.map` 转换每个元素
- `List.filter` 选择满足条件的元素
- `List.fold_left` / `List.fold_right` 累积一个值，是最通用的列表操作
- `List.fold_left` 是尾递归的，`List.fold_right` 不是
- `List.find` / `List.exists` / `List.for_all` / `List.partition` 用于查询
- `List.iter` 用于副作用遍历
- `List.sort` 用于排序
- 列表是不可变的，可以安全共享
- 列表不适合随机访问，那是数组的活

---

---
上一章：[07 · 模式匹配](patterns.md) ｜ 下一章：[09 · 变体类型（代数数据类型）](variants.md) ｜ 返回：[README](../README.md)
