# 08 · 列表与高阶列表函数

> 对应示例：`examples/06-lists.sml`


## 8.1 构造

```sml
val xs = [1, 2, 3]              (* 字面量 *)
val ys = 1 :: 2 :: 3 :: []      (* 完全等价的 cons 写法 *)
val zs = xs @ ys                (* 拼接 *)
val nil = []                    (* 空表 *)
```

**`::` 是 O(1) 的头部插入，`@` 是 O(n) 的拼接。**

```sml
1 :: xs         (* 快 *)
xs @ [1]        (* 慢：要把整个 xs 走一遍 *)
```

这直接决定了递归该怎么写。看两个求区间的函数：

```sml
(* 朴素版：每次 @ 都要复制，整体 O(n^2) *)
fun rangeNaive (i, j) = if i > j then [] else i :: [] @ rangeNaive (i + 1, j)

(* 累积器版：先倒着攒，最后 rev 一次，整体 O(n) *)
fun rangeFast (i, j) =
    let
        fun go (k, acc) = if k > j then rev acc else go (k + 1, k :: acc)
    in
        go (i, [])
    end
```

**「永远往前面 `::`，需要正序就最后 `rev` 一次」** 是 SML 里最基本的性能模式。

## 8.2 三个主力：map / filter / fold

```sml
map (fn x => x * 2) [1, 2, 3]                 (* [2,4,6] *)
filter (fn x => x mod 2 = 0) [1, 2, 3, 4]     (* [2,4] *)
foldl (fn (x, acc) => x + acc) 0 [1, 2, 3]    (* 6 *)
foldr (fn (x, acc) => x :: acc) [] [1, 2, 3]  (* [1,2,3] *)
```

## 8.3 foldl 与 foldr 的区别

```sml
foldl f init [x1, x2, x3]  =  f (x3, f (x2, f (x1, init)))
foldr f init [x1, x2, x3]  =  f (x1, f (x2, f (x3, init)))
```

`foldl` 从左往右累积（累积器在第二个参数），`foldr` 从右往左。

- **求和、计数、求最值 → `foldl`**（而且是尾递归，大列表安全）
- **构造列表、保持顺序 → `foldr`**
- **`foldr` 不是尾递归**，长列表上会吃栈帧。

同一个结果用哪个都能写，但代价不同：

```sml
foldr (fn (x, acc) => x :: acc) [] xs    (* 保持顺序，但非尾递归 *)
rev (foldl (fn (x, acc) => x :: acc) [] xs)  (* 尾递归，最后 rev *)
```

## 8.4 工具函数一览

```sml
length [1,2,3]           (* 3，O(n) *)
rev [1,2,3]              (* [3,2,1] *)
List.nth ([1,2,3], 1)    (* 2，O(n)！*)
List.take ([1,2,3], 2)   (* [1,2] *)
List.drop ([1,2,3], 2)   (* [3] *)
List.concat [[1],[2,3]]  (* [1,2,3] *)
```

**`List.nth` 是 O(n)** —— SML 的列表是单链表，没有随机访问。要按下标频繁访问就换 `Array` 或 `Vector`（第 18 章）。

`take` / `drop` 越界会抛 `Subscript`：

```sml
List.take ([1,2,3], 5)   (* 抛 Subscript *)
```

## 8.5 谓词与查找

```sml
List.exists (fn x => x > 2) [1,2,3]              (* true *)
List.all (fn x => x > 0) [1,2,3]                 (* true *)
List.find (fn x => x > 1) [1,2,3]                (* SOME 2 *)
List.partition (fn x => x > 1) [1,2,3]           (* ([2,3], [1]) *)
List.mapPartial (fn x => if x > 1 then SOME x else NONE) [1,2,3]  (* [2,3] *)
```

**`List.partition` 是写快速排序的关键**：

```sml
fun qsort [] = []
  | qsort (pivot :: rest) =
        let
            val (lo, hi) = List.partition (fn x => x < pivot) rest
        in
            qsort lo @ [pivot] @ qsort hi
        end
```

## 8.6 ListPair：同时处理两个列表

```sml
ListPair.zip ([1,2], ["a","b"])         (* [(1,"a"), (2,"b")] *)
ListPair.map (fn (x, y) => x + y) ([1,2], [10,20])   (* [11,22] *)
ListPair.all (fn (x, y) => x < y) ([1,2], [3,4])     (* true *)
```

**长度不等时行为要注意**：`zip` 会**报 `UnequalLengths`**，而 `map` / `all` 的语义按实现略有差别 —— 想安全就先用 `length` 对齐，或者用 `ListPair.zipEq` / `zip` 配异常处理。

## 8.7 手写一遍 map

```sml
fun myMap _ [] = []
  | myMap f (x :: rest) = f x :: myMap f rest
```

类型推断给出 `('a -> 'b) -> 'a list -> 'b list` —— 和 `map` 一模一样。这就是 SML 里「写库函数」的感觉：写出来自然就是多态的。

## 8.8 本章示例的其余内容

- `List.tabulate (n, f)` 造 `[f 0, f 1, ..., f (n-1)]`，比手写 `range` + `map` 干脆。
- `String.concatWith` 不只用于字符串，`String.concatWith "," (map Int.toString xs)` 是打印整数列表的常用手段（本书所有示例都用它）。
- `null xs` 判空比 `length xs = 0` 快（O(1) vs O(n)）。

---
