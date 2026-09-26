# 19 · 排序与经典算法

> 对应示例：`examples/17-algorithms.sml`


这一章的算法本身都是老面孔，重点不在「怎么排序」，而在**SML 写这些算法时形状有什么不同**。同一个插入排序，在 C 里是双层循环加下标，在 SML 里是两行模式匹配：

```sml
fun insert (x, []) = [x]
  | insert (x, y :: ys) = if x <= y then x :: y :: ys else y :: insert (x, ys)

fun isort [] = []
  | isort (x :: xs) = insert (x, isort xs)
```

`insert` 的两个子句把「插到空表」和「插到非空表」分开写，**递归的终止条件由模式匹配兜住**，不需要 `if (i >= n) break` 这类守卫。这就是 SML 的核心手感：**把控制流编码进数据的形状**。

另一个反复出现的手法：**用累积器 + 尾递归替代循环**。示例里 `collect`、`loop`、`go` 这些内层函数都是这个形状：

```sml
fun loop (k, acc) = if k > n then acc else loop (k + 1, acc + term k)
```

`acc` 是显式的，`k` 是显式的，没有隐式状态。看起来比 `for` 啰嗦，但换来的是：**每轮迭代的输入输出都写在签名里**，读的人不用在脑子里维护变量。

## 19.1 三条排序路线，互为校验

示例里写了三条完全不同的排序，然后对同一份数据跑，要求结果逐字节相同：

```sml
val data = [37, 12, 91, 5, 44, 12, 78, 3, 60, 25]
val a1 = isort data
val a2 = msort data
val a3 = qsort data

val _ = say ("   all agree = " ^ Bool.toString (a1 = a2 andalso a2 = a3))
```

输出：

```
4) input = [37,12,91,5,44,12,78,3,60,25]
   isort = [3,5,12,12,25,37,44,60,78,91]
   msort = [3,5,12,12,25,37,44,60,78,91]
   qsort = [3,5,12,12,25,37,44,60,78,91]
   all agree = true
```

这件事值得单独做一节，因为它示范了**在没有测试框架的语言里怎么获得信心**：不是比较「我认为结果是对的」，而是让三条互不相关的实现互相掐。`isort` 是插入式、`msort` 是分治式、`qsort` 是划分式，它们同时错的概率极低。

**这个思路贯穿全书**：第 8 章的 `tokens`/`fields` 对照、第 20 章的二分/牛顿互证、第 21 章的正则与手写解析对照，全是同一个套路。

## 19.2 `split`：不数长度就对半劈

归并排序的 `split` 有个漂亮写法，一次模式匹配吃掉两个元素：

```sml
fun split [] = ([], [])
  | split [x] = ([x], [])
  | split (x :: y :: rest) =
        let
            val (a, b) = split rest
        in
            (x :: a, y :: b)
        end
```

三个子句分别对应「偶数剩 0」「奇数剩 1」「至少剩 2」。第三个子句一次递归**同时**给两半各加一个元素，所以天然是均分。对比一下常见写法：先 `length` 数一遍、再 `List.take`/`List.drop` 切一次（这两个都在 Basis 里，实测三家都有）—— 那是**两趟遍历**，而模式匹配这个写法**一趟**就够了。

输出：

```
2) split [1,2,3,4,5] = ([1,3,5], [2,4])
   merge ([1,3,5],[2,4]) = [1,2,3,4,5]
```

`merge` 的两个终止子句值得注意顺序：

```sml
fun merge ([], ys) = ys
  | merge (xs, []) = xs
  | merge (x :: xs, y :: ys) = ...
```

第一条吃掉「左边空了」，第二条吃掉「右边空了」。**顺序不能反**吗？其实这里可以，因为 `([],[])` 两个都匹配第一条。但如果第二条写在前面，写错成 `merge (xs, []) = xs` 在前，那么 `merge ([], [])` 会先命中它、返回 `[]` —— 结果一样。真正的风险在于：**模式匹配是自上而下取第一个匹配的子句**，写多子句时要按「越具体越靠前」排。

## 19.3 `qsort`：`List.partition` 把它压到六行

```sml
fun qsort [] = []
  | qsort (pivot :: rest) =
        let
            val (lo, hi) = List.partition (fn x => x < pivot) rest
        in
            qsort lo @ [pivot] @ qsort hi
        end
```

`List.partition` 一次遍历把表分成「满足谓词」和「不满足」两半，返回一个二元组。有了它，快排的分区步骤一行就完事。

输出：

```
3) qsort [3,1,4,1,5,9,2,6] = [1,1,2,3,4,5,6,9]
```

**注意这里的 `@`**：`qsort lo @ [pivot] @ qsort hi` 的拼接复制度是 O(n)，所以这个写法的复杂度比原地快排差。示例里数据量小，无所谓；真要用就得像下面那样用 `@` 只在必要处用：

```sml
fun qsort [] = []
  | qsort (pivot :: rest) =
        let
            val (lo, hi) = List.partition (fn x => x < pivot) rest
        in
            qsort lo @ (pivot :: qsort hi)      (* 右边不需要单独的一元表 *)
        end
```

`pivot :: qsort hi` 是**常数时间**的，只有左边那个 `@` 免不掉。这种「把 `@ [x] @` 改成 `x ::`」的小修，是把 SML 列表代码写快的第一课。

## 19.4 用「步数」把算法差距量出来

讲复杂度的时候，「二分查找比线性查找快」是句空话。示例里直接让两个函数各自返回比较次数：

```sml
fun bsearch (arr : int array, goal : int) =
    let
        fun go (lo, hi, steps) =
            if lo > hi then NONE
            else
                let
                    val mid = (lo + hi) div 2
                    val v = Array.sub (arr, mid)
                in
                    if v = goal then SOME (mid, steps)
                    else if v < goal then go (mid + 1, hi, steps + 1)
                    else go (lo, mid - 1, steps + 1)
                end
    in
        go (0, Array.length arr - 1, 1)
    end
```

数组是 `0,2,4,...,198` 共 100 个元素，找 192（在下标 96）：

```
5) binary search 192 -> index 96 in 5 steps
   linear search 192 -> index 96 in 97 steps
   binary search 3 (absent) -> not found
```

**5 步 vs 97 步**。这个数字比任何渐近记号都有说服力。`steps` 作为 `go` 的一个参数一路传下去，是「累积器」思路的又一例。

注意 `bsearch` 的返回类型推出来是 `int option`，然后：

```sml
fun describe result =
    case result of
        NONE => "not found"
      | SOME (idx, steps) => "index " ^ Int.toString idx ^ " in " ^ Int.toString steps ^ " steps"
```

**`SOME` 里套了个二元组** —— `option` 和元组可以随意组合，`case` 一次把它拆到底。这是 SML 里表达「可能失败的计算 + 附带信息」的标准姿势。

## 19.5 埃拉托斯特尼筛：`Array` 第一次派上正经用场

```sml
fun sieve n =
    let
        val mark = Array.array (n + 1, true)
        val _ = if n >= 0 then Array.update (mark, 0, false) else ()
        val _ = if n >= 1 then Array.update (mark, 1, false) else ()

        fun strike p =
            let
                fun go k = if k > n then () else (Array.update (mark, k, false); go (k + p))
            in
                go (p * p)
            end

        fun loop p =
            if p * p > n then ()
            else (if Array.sub (mark, p) then strike p else (); loop (p + 1))

        val _ = loop 2
        ...
    end
```

几个真正的知识点：

1. **`val _ = if ... else ()` 这种写法**：`Array.update` 返回 `unit`，但 `if` 的两个分支都必须是 `unit`。当条件不满足时不能「什么都不做」——SML 没有空语句，要显式写 `()`。这是从命令式语言过来的人第一个不适应的地方。

2. **`(Array.update (...); go (...))`**：分号串联两个 `unit` 表达式，**必须用括号包起来**。不包的话分号会被当成声明层的分隔符，报语法错。这个坑后面第 21 章还会再遇到一次。

3. **`val _ = loop 2` 的位置**：`loop` 是 `let` 里的局部函数，必须在 `collect` 用它之前**先执行**。`let` 里的 `val` 是按顺序求值的，这一点和 SML 的纯函数外表形成了对比 —— `let` 内部其实是一个**顺序执行的语句块**，只是所有副作用被限制在这个块里。

4. **`strike` 从 `p * p` 开始**：更小的倍数已经被更小的质数划掉了。这是筛法唯一的优化点，值得写进注释。

输出：

```
6) primes <= 30 = [2,3,5,7,11,13,17,19,23,29]
   number of primes <= 100 = 25
```

## 19.6 `gcd` 与 `lcm`：先除后乘

```sml
fun gcd (a, b) = if b = 0 then a else gcd (b, a mod b)
fun lcm (a, b) = a div gcd (a, b) * b
```

`gcd` 是尾递归的教科书例子：`if b = 0 then a else gcd (b, a mod b)`，状态全在参数里，所以能被编译成循环。MLton 会把这种函数彻底优化掉。

`lcm` 的写法有个真实陷阱：

```sml
fun lcm (a, b) = a * b div gcd (a, b)      (* 危险！a*b 可能溢出 *)
fun lcm (a, b) = a div gcd (a, b) * b      (* 正确 *)
```

虽然 `div` 和 `*` 同优先级、左结合，`a * b div g` 看着也对，但 **`a * b` 先算**。在 MLton 上 `int` 是 32 位，`lcm (100000, 100001)` 会直接溢出。先除后乘就没事（因为 `gcd` 一定整除 `a`）。

**这个差别在三通道上还会分叉**：SML/NJ 和 Poly/ML 的 `int` 是 63 位，`a * b` 没那么容易溢出，于是在那两个实现上「错版」跑得好好的，在 MLton 上翻车。这正是多通道验证的价值 —— 见第 33 章。

```
7) gcd (48, 18)     = 6
   gcd (1071, 462)  = 21
   lcm (4, 6)       = 12
```

## 19.7 汉诺塔：一个函数打印步骤，另一个只数次数

```sml
fun hanoiMoves (0, _, _, _) = []
  | hanoiMoves (n, a, b, c) =
        hanoiMoves (n - 1, a, c, b) @ [(a, c)] @ hanoiMoves (n - 1, b, a, c)

fun hanoiCount (0, _, _, _) = 0
  | hanoiCount (n, a, b, c) =
        hanoiCount (n - 1, a, c, b) + 1 + hanoiCount (n - 1, b, a, c)
```

两个函数结构完全同构，只是一个返回 `list`、一个返回 `int`。这是 SML 里很典型的现象：**改动量的地方往往只是类型不同，骨架一模一样**。写第二个的时候基本上是复制第一个再改两处。

第一个用 `_` 忽略塔名（不需要），第二个保留塔名（因为要传给递归）。**`_` 不是省略，是一个真实的模式**：它匹配任何东西且不绑定名字，编译器也不会因为它而少做穷尽性检查。

```
8) hanoi 3 -> 7 moves (2^3 - 1 = 7)
   A>C A>B C>B A>C B>A B>C A>C
   hanoi 10 -> 1023 moves
   hanoi 20 -> 1048575 moves
```

**为什么 n=20 只数不打印？** 因为那是 1048575 行输出，而验证脚本要把 stdout 逐字节比对三遍。示例的注释里写得很直白：「别对 n=20 打印每步」。写示例代码时要**时刻记住输出规模**，尤其是输出要进回归比对的时候。

顺带说：`hanoiMoves` 用 `@` 拼接是 O(n²) 的（每层都复制一次）。n=3 无所谓。真写生产代码要把返回类型改成「累积器 + `rev`」，或者直接返回 `unit` 边算边打印。

## 19.8 记忆化：`Array` + `~1` 当「未算」标记

```sml
fun fibMemo n =
    let
        val memo = Array.array (n + 1, ~1)      (* ~1 表示「还没算」 *)

        fun go k =
            if k <= 1 then k
            else
                let
                    val cached = Array.sub (memo, k)
                in
                    if cached >= 0 then cached
                    else
                        let
                            val r = go (k - 1) + go (k - 2)
                        in
                            (Array.update (memo, k, r); r)
                        end
                end
    in
        go n
    end
```

这是全章最实用的一节。朴素递归 `fib 40` 要几十亿次调用，记忆化只要 40 次左右：

```
9) fib 10 (memoized) = 55
   fib 40 (memoized) = 102334155
```

三个要点：

1. **`~1` 是负一的写法**。SML 里 `-` 是二元减法运算符，取负用 `~`。`~1` 才能当字面量用在模式里（`-1` 会被解析成「减法，缺左操作数」）。
2. **`memo` 建在 `let` 里，不是全局**。每次调用 `fibMemo` 都得到一张新表，互不干扰。如果把 `memo` 提到顶层，函数就不再可重入了 —— 这在多线程/回调用场景下是隐性 bug。
3. **`(Array.update (memo, k, r); r)`** 又是那种「分号串联 + 括号」的写法：先写入缓存，再把 `r` 作为整个表达式的值。**顺序不能反**，因为 `;` 的值是右边那个，但求值顺序是从左到右。

## 19.9 有序表的 `dedup` 与 `inter`：和 `merge` 同构

```sml
fun dedup [] = []
  | dedup [x] = [x]
  | dedup (x :: y :: rest) =
        if x = y then dedup (y :: rest) else x :: dedup (y :: rest)

fun inter ([], _) = []
  | inter (_, []) = []
  | inter (x :: xs, y :: ys) =
        if x = y then x :: inter (xs, ys)
        else if x < y then inter (xs, y :: ys)
        else inter (x :: xs, ys)
```

`inter` 的结构和 19.2 的 `merge` 一模一样：两个表同步前进，谁小谁先走。**这实际上就是归并排序里 merge 的那一步**，只是把「合并」换成了「取交集」。

`dedup` 需要三个子句：空表、单元素、至少两个元素。第二个子句 `| dedup [x] = [x]` 不能省 —— 少了它，`[x]` 走到第三个子句会因为 `y :: rest` 匹配不上而报「非穷尽匹配」警告。

```
10) dedup [1,1,2,3,3,3,4] = [1,2,3,4]
    inter [1,3,5,7] [3,4,5,6] = [3,5]
```

## 19.10 `foldl` 一趟算完 min / max / sum

```sml
val smallest = foldl Int.min (hd nums) nums
val largest  = foldl Int.max (hd nums) nums
val total    = foldl (op +) 0 nums
```

```
11) min = 3, max = 91, sum = 367, count = 10
```

三个收获：

- **`Int.min` / `Int.max` 本身就是 `int * int -> int` 的函数**，可以直接当 `foldl` 的合并函数，不需要 `fn (a, b) => if a < b then a else b`。
- **`op +` 把中缀运算符变成前缀函数**。`foldl + 0 nums` 是语法错，因为 `+` 是中缀标识符，必须 `op +` 才能当普通函数传。这个 `op` 关键字在第 13 章出现过（`map (op +) [[1,2],[3]]` 之类的场景），在这里第二次出现。
- **初始值 `hd nums` 有风险**：空表会让 `hd` 抛 `Empty`。示例里数据是写死的非空表，所以安全；通用写法要把 `min` 的返回类型改成 `int option`：

```sml
fun minOf xs =
    case xs of
        [] => NONE
      | x :: rest => SOME (foldl Int.min x rest)
```

**这就是 SML 社区常说的「用类型表达失败」**：返回值从 `int` 变成 `int option`，调用方被迫处理空表。编译器帮你记住这件事。

---
