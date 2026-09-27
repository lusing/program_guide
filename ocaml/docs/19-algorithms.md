# 19 · 排序与经典算法

对应示例：`../examples/15_algorithms.ml`

对应示例：`examples/15_algorithms.ml`

### 19.1 函数式算法的思考方式

学习算法时，OCaml 的函数式风格能让你更专注于「做什么」而不是「怎么做」。

命令式算法的典型模式是：初始化变量 -> 循环修改 -> 得到结果。你需要跟踪每一步的状态变化。

函数式算法的典型模式是：递归分解 -> 组合子问题的解 -> 得到结果。你需要思考的是问题的结构，而不是执行的步骤。

我们通过几个经典算法来体会这种差异。

### 19.2 插入排序

插入排序的思路很简单：把列表分成「已排序」和「未排序」两部分，依次把未排序的元素插入到已排序部分的正确位置。

**函数式版本**：

```ocaml
(* 将 x 插入到已排序列表 lst 的正确位置 *)
let rec insert x = function
  | [] -> [x]
  | h :: t as lst ->
      if x <= h then x :: lst
      else h :: insert x t

(* 插入排序主函数 *)
let rec insertion_sort = function
  | [] -> []
  | h :: t -> insert h (insertion_sort t)
```

这个版本非常简洁，几乎就是算法的数学定义：
- 空列表已经排序好了
- 对于非空列表，先排好尾部，然后把头部插入进去

时间复杂度是 O(n^2)，空间复杂度是 O(n)（因为每次都创建新列表）。

**命令式版本（使用数组）**：

```ocaml
let insertion_sort_array arr =
  let n = Array.length arr in
  for i = 1 to n - 1 do
    let key = arr.(i) in
    let j = ref (i - 1) in
    while !j >= 0 && arr.(!j) > key do
      arr.(!j + 1) <- arr.(!j);
      decr j
    done;
    arr.(!j + 1) <- key
  done;
  arr
```

命令式版本更长，你需要跟踪索引 i 和 j，需要手动移动元素。但它是原地排序，不需要额外空间。

**对比**：函数式版本更清晰地表达了算法的本质，但有额外的内存分配。命令式版本更高效，但代码更繁琐、更容易出错。

### 19.3 归并排序

归并排序是分治算法的经典例子。思路：
1. 把列表分成两半
2. 分别排序两半
3. 把两个有序列表合并成一个

```ocaml
(* 合并两个有序列表 *)
let rec merge a b =
  match (a, b) with
  | ([], _) -> b
  | (_, []) -> a
  | (x :: xs, y :: ys) ->
      if x <= y then x :: merge xs b
      else y :: merge a ys

(* 归并排序 *)
let rec merge_sort = function
  | [] -> []
  | [x] -> [x]
  | lst ->
      let rec split n lst =
        if n = 0 then ([], lst)
        else match lst with
          | [] -> ([], [])
          | h :: t ->
              let (left, right) = split (n - 1) t in
              (h :: left, right)
      in
      let half = List.length lst / 2 in
      let (left, right) = split half lst in
      merge (merge_sort left) (merge_sort right)
```

时间复杂度：O(n log n)，因为每次递归列表长度减半（log n 层），每层合并需要 O(n)。

归并排序的函数式实现非常优雅——它直接对应了算法的递归描述。缺点是需要额外的空间来存储中间结果（不像快速排序可以原地进行）。

### 19.4 快速排序

快速排序也是分治算法。思路：
1. 选一个基准元素（pivot）
2. 把小于等于 pivot 的放左边，大于 pivot 的放右边
3. 分别对左右两边排序

**函数式版本**：

```ocaml
let rec quick_sort = function
  | [] -> []
  | pivot :: rest ->
      let left = List.filter (fun x -> x <= pivot) rest in
      let right = List.filter (fun x -> x > pivot) rest in
      quick_sort left @ [pivot] @ quick_sort right
```

这个版本极其简洁——几乎就是快速排序的定义本身。

但它有几个问题：
1. 效率不高：两次遍历列表（两次 filter），而且 `@` 操作是 O(n) 的
2. 空间复杂度高：每次都创建新的列表
3. 基准选择简单：总是选第一个元素，如果输入已经有序，时间复杂度退化为 O(n^2)

**命令式版本（原地快速排序）**：

```ocaml
let quick_sort_array arr =
  let swap i j =
    let tmp = arr.(i) in
    arr.(i) <- arr.(j);
    arr.(j) <- tmp
  in
  let rec partition lo hi =
    let pivot = arr.(hi) in
    let i = ref (lo - 1) in
    for j = lo to hi - 1 do
      if arr.(j) <= pivot then (
        incr i;
        swap !i j
      )
    done;
    swap (!i + 1) hi;
    !i + 1
  in
  let rec qsort lo hi =
    if lo < hi then
      let p = partition lo hi in
      qsort lo (p - 1);
      qsort (p + 1) hi
  in
  qsort 0 (Array.length arr - 1);
  arr
```

命令式版本原地排序，空间复杂度 O(log n)（栈空间），平均时间复杂度 O(n log n)。但代码明显更长，而且更容易写错（索引边界、swap 逻辑等）。

**函数式 vs 命令式的取舍**：

函数式快速排序代码简洁、易于理解，但性能不如原地版本。在实际工程中：
- 如果数据量不大，用函数式版本完全没问题
- 如果数据量大且性能关键，用 `Array.sort`（标准库的原地排序）
- 大多数时候，你不需要自己写排序算法，直接用标准库的就行

### 19.5 二分查找

二分查找是在有序数组中查找元素的经典算法，时间复杂度 O(log n)。

```ocaml
let binary_search arr target =
  let rec search lo hi =
    if lo > hi then None
    else
      let mid = lo + (hi - lo) / 2 in   (* 防止溢出 *)
      if arr.(mid) = target then Some mid
      else if arr.(mid) < target then search (mid + 1) hi
      else search lo (mid - 1)
  in
  search 0 (Array.length arr - 1)
```

这个版本用递归实现，非常清晰。每一步比较中间元素，然后决定去左半边还是右半边找。

```ocaml
let arr = [| 1; 3; 5; 7; 9; 11; 13; 15 |]
let _ =
  binary_search arr 7;    (* Some 3 —— 找到了，索引是 3 *)
  binary_search arr 4     (* None —— 没找到 *)
```

注意计算 `mid` 用的是 `lo + (hi - lo) / 2` 而不是 `(lo + hi) / 2`。后者在 `lo + hi` 很大时可能溢出（虽然 OCaml 的 int 是任意精度的不会溢出，但这是一个好的编程习惯，在其他语言中很重要）。

### 19.6 埃拉托斯特尼筛法

埃拉托斯特尼筛法（Sieve of Eratosthenes）是求素数的经典算法。思路：从 2 开始，把每个素数的倍数都标记为合数，最后剩下的就是素数。

这个算法天然适合用数组（因为需要随机访问和原地修改）。

```ocaml
let sieve n =
  if n < 2 then [||]
  else
    let is_prime = Array.make (n + 1) true in
    is_prime.(0) <- false;
    is_prime.(1) <- false;
    let i = ref 2 in
    while !i * !i <= n do
      if is_prime.(!i) then
        (* 把 i 的倍数都标记为非素数，从 i*i 开始（更小的倍数已经被标记过了） *)
        let j = ref (!i * !i) in
        while !j <= n do
          is_prime.(!j) <- false;
          j := !j + !i
        done;
      incr i
    done;
    (* 收集所有素数 *)
    let primes = ref [] in
    for k = n downto 2 do
      if is_prime.(k) then primes := k :: !primes
    done;
    Array.of_list !primes
```

```ocaml
let _ =
  let primes = sieve 30 in
  Array.iter (Printf.printf "%d ") primes;   (* 2 3 5 7 11 13 17 19 23 29 *)
  print_newline ()
```

筛法是一个典型的「用可变数组更自然」的算法。你当然可以用纯函数式的方式实现（比如用列表或函数式的惰性序列），但代码会复杂得多，效率也更低。

### 19.7 gcd 与 lcm

**最大公约数（gcd）** 用欧几里得算法：

```ocaml
let rec gcd a b =
  if b = 0 then abs a
  else gcd b (a mod b)
```

这个算法的时间复杂度是 O(log(min(a, b)))，非常高效。

**最小公倍数（lcm）** 可以用 gcd 来算：

```ocaml
let lcm a b =
  if a = 0 || b = 0 then 0
  else abs (a * b) / gcd a b
```

注意 `a * b` 可能溢出——在 OCaml 中 int 是固定精度的（63 位或 31 位），如果 a 和 b 都很大，乘积可能超出范围。对于大数应该用 `Zarith` 库的任意精度整数。

### 19.8 记忆化（Memoization）

记忆化是一种优化技术：把函数的计算结果缓存起来，下次调用同样的参数时直接返回缓存的结果，避免重复计算。

我们用斐波那契数列来演示。朴素的递归版本是 O(2^n) 的，因为有大量重复计算：

```ocaml
let rec fib n =
  if n <= 1 then n
  else fib (n - 1) + fib (n - 2)
```

用 Hashtbl 实现记忆化：

```ocaml
let memo_fib =
  let cache = Hashtbl.create 100 in
  let rec fib n =
    match Hashtbl.find_opt cache n with
    | Some result -> result
    | None ->
        let result =
          if n <= 1 then n
          else fib (n - 1) + fib (n - 2)
        in
        Hashtbl.add cache n result;
        result
  in
  fib
```

```ocaml
let _ =
  memo_fib 10;    (* 55 —— 计算并缓存 *)
  memo_fib 10;    (* 55 —— 直接从缓存取 *)
  memo_fib 20     (* 6765 —— 可以算更大的数了 *)
```

记忆化后的斐波那契时间复杂度变成 O(n)（每个 n 只算一次），空间复杂度也是 O(n)（缓存了 n 个结果）。

**更通用的记忆化函数**：

我们可以写一个通用的 memoize 函数，给任意函数加上记忆化：

```ocaml
let memoize f =
  let cache = Hashtbl.create 100 in
  fun x ->
    match Hashtbl.find_opt cache x with
    | Some result -> result
    | None ->
        let result = f x in
        Hashtbl.add cache x result;
        result
```

但要注意：这个版本只能用于单参数函数。对于多参数函数，需要先把参数打包成元组。而且对于递归函数，直接 memoize 不会工作——因为递归调用的是原始函数，不是记忆化后的版本。要让递归函数也享受记忆化，需要用「不动点组合子」或者像上面的 `memo_fib` 那样手动在递归函数内部使用缓存。

### 19.9 算法的函数式思考方式

学习了这么多算法，我们来总结一下函数式算法的思考模式：

**1. 关注问题结构，而非执行步骤**

函数式编程中，你思考的是「这个问题可以分解成什么样的子问题」，而不是「第一步做什么、第二步做什么」。递归是这种思维方式的直接体现。

**2. 不可变性简化了推理**

纯函数式算法中，数据是不可变的。你不用担心某个值在别处被修改了——你创建的列表就是那个样子，不会变。这让代码更容易推理和调试。

**3. 用高阶函数抽象模式**

`map`、`filter`、`fold` 这些高阶函数本身就是算法模式的抽象。很多算法都可以用它们来组合实现，而不需要从头写递归。

**4. 什么时候用命令式**

当你真正需要性能时，或者当算法天然就是原地修改的（比如筛法、原地排序），就用可变数据结构。但要把可变的部分封装起来，对外暴露纯函数式的接口。

### 19.10 本章小结

- 插入排序：简单直观，O(n^2)，适合小规模数据
- 归并排序：分治思想，O(n log n)，函数式实现优雅
- 快速排序：平均 O(n log n)，原地版本更高效但代码更复杂
- 二分查找：O(log n)，需要有序数组，递归实现清晰
- 埃拉托斯特尼筛法：求素数的经典算法，天然适合用数组
- gcd 用欧几里得算法，lcm = a*b/gcd(a,b)
- 记忆化用 Hashtbl 缓存计算结果，把指数复杂度降到多项式
- 函数式算法关注问题结构，命令式算法关注执行步骤
- 优先用函数式写法，性能关键时再考虑可变数据结构

---

---
上一章：[18 · 可变状态](mutable.md) ｜ 下一章：[20 · 数值计算](numeric.md) ｜ 返回：[README](../README.md)
