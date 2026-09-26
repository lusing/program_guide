# 26 · 记忆化与递归挂起

> 对应示例：`examples/24-memo.sml`
> 参考书：Harper《Programming in Standard ML》第 31 章（Memoization）全章：31.1 Cacheing Results、31.2 Laziness、31.3 Lazy Data Types in SML/NJ、31.4 Recursive Suspensions。

记忆化（memoization）的策略很简单：**算过的存表，再算先查表**。这一章用计数器把三个层次的记忆化全部量出来——包括一个几乎所有初学者都会踩的大坑：**把递归函数包一层 memoize，什么也没省下**。

## 26.1 朴素 fib：指数级的账单

```sml
fun fibNaive (n : int) = if n < 2 then n else fibNaive (n - 1) + fibNaive (n - 2)
```

`fibNaive 25 = 75025`，调用次数 242785 次——调用数 `calls(n) = calls(n-1) + calls(n-2) + 1` 本身就是个 fib 数列。这不是 SML 的问题，是分治不记忆的通病。

## 26.2 数组当表：命令式记忆化

把 `fib` 的递归改成「查表驱动」：

```sml
fun fibArray (n : int) =
    let
        val tbl = Array.array (n + 1, ~1)          (* ~1 = 未算 *)
        fun go k =
            if Array.sub (tbl, k) >= 0 then Array.sub (tbl, k)
            else
                let
                    val v = if k < 2 then k else go (k - 1) + go (k - 2)
                    val _ = Array.update (tbl, k, v)
                in
                    v
                end
    in
        go n
    end
```

`fibArray 40 = 102334155`，填表 41 次。数组的键必须稠密且非负——这是它快的原因，也是它的边界。

**别忘 33 章那张表**：MLton 默认 `int` 是 32 位，`fib 47 = 2971215073` 已经溢出 2³¹−1。示例统一算到 `fib 40`，三家都安全。

## 26.3 大坑：memoize 包不住递归

「给函数加缓存」的自然抽象：

```sml
fun memoize (f : int -> int) : int -> int =
    let
        val tbl = ref ([] : (int * int) list)
    in
        fn k =>
           case List.find (fn (k', _) => k' = k) (!tbl) of
               SOME (_, v) => v
             | NONE =>
                   let
                       val v = f k
                       val _ = tbl := (k, v) :: !tbl
                   in
                       v
                   end
    end

val fibWrapped = memoize fibNaive
```

跑一下：`fibWrapped 25` 的调用数是 **242785，纹丝不动**。原因值得抄进笔记本：

> 包装函数自己会查表，但 `fibNaive` **内部的递归调用仍然直连原函数**，一步也不走表。缓存里只存下了顶层的 `(25, 75025)` 一个条目。

这不是实现瑕疵，是结构问题：**记忆化必须接管递归路径上的每一次调用**，而外包装碰不到函数体内部。

顺带一提，这里的查表用 `List.find (fn (k', _) => k' = k)`——键是 `int`，相等是单态的，不会触发 SML/NJ 的 `polyEqual` 警告（多态 `=` 才会）。关联表的查表是 O(n)，教学够用；键稠密时换 26.2 的数组，键稀疏时换第 31 章的词典。

## 26.4 正解：开递归 + memoRec

把「怎么递归」从函数体里参数化出来——**开递归**（open recursion）：

```sml
fun fibBody (recf : int -> int) (n : int) =
    (bodyRuns := !bodyRuns + 1;
     if n < 2 then n else recf (n - 1) + recf (n - 2))
```

`fibBody` 不再自呼，它接收一个 `recf` 当作「自己的查表版」。`memoRec` 负责把两者焊起来：

```sml
fun memoRec (body : (int -> int) -> int -> int) : int -> int =
    let
        val tbl = ref ([] : (int * int) list)
        fun self k =
            case List.find (fn (k', _) => k' = k) (!tbl) of
                SOME (_, v) => v
              | NONE =>
                    let
                        val v = body self k      (* 递归走 self：查表版 *)
                        val _ = tbl := (k, v) :: !tbl
                    in
                        v
                    end
    in
        self
    end

val fibFast = memoRec fibBody
```

实测：`fibFast 25` 与 `fibFast 40` 都对，body 执行 **41 次**——线性。和 26.2 的 41 次填表完全一致：两种记忆化殊途同归。

「开递归」是面向对象「模板方法」的函数式变体：把自调用改成对注入函数的调用。第 31 章的 functor 是它的模块级版本——**functor 参数化的正是「依赖怎么递归/依赖谁」**。

## 26.5 惰性流版的 fib：表就是流自己

```sml
fun fibStream () : int stream =
    let
        fun go (a, b) = Cons (a, delay (fn () => go (b, a + b)))
    in
        go (0, 1)
    end
```

第 25 章已见过它。从记忆化的视角看：**流的第 k 格就是 fib(k) 的缓存条目**，`force` 命中 `Value` 就是查表命中。计数器证明每个元素只算一次——这是「惰性 + 记忆化」合体的标准案例（Harper 31.2 的论点：laziness 就是 memoized suspension）。

## 26.6 递归挂起：循环流不打结就是指数级

Harper 31.4 的压轴问题：定义**自引用的流**。教科书式的写法是

```
fibs = 0 :: 1 :: (fibs + tail fibs)
```

SML/NJ 里可以写 `val rec lazy`，但可移植版本只剩两个工具：`fun`（只能定义函数）和 `ref`（可以事后回填）。

**不打结的版本**（每次调用重新生成一条独立流）：

```sml
fun fibsGen () : int stream =
    (regen := !regen + 1;
     Cons (0, delay (fn () =>
       Cons (1, delay (fn () =>
         sadds (fibsGen (), stail (fibsGen ())))))))
```

其中 `sadds` 是流的逐元素加法（两边的尾巴都包在 `delay` 里）。实测 `stake 20`：**regen = 13529**——每往深走一格，`sadds` 的两个操作数各自引出一条**全新的** `fibsGen ()` 流，重算量指数增长。

**打结的版本**——ref 占位 + 回填：

```sml
val rootCell : int stream susp = delay (fn () => raise Fail "unfilled")
fun fibsKnotted () : int stream =
    (regen2 := !regen2 + 1;
     Cons (0, delay (fn () =>
       Cons (1, delay (fn () =>
         sadds (force rootCell, stail (force rootCell)))))))
val _ = rootCell := Delayed fibsKnotted    (* 回填：结打上了 *)
```

先声明一个「未填充」的挂起占位；`fibsKnotted` 引用这个占位；定义完之后把真正的生成器写回去。同一 `stake 20`：**regen = 2**（根格子算一次、回填后再确认一次），输出与不打结版完全一致。

这就是「打结」（tying the knot）的实现术：**SML 没有 `val rec` 除 `fn` 外的递归值，循环数据结构靠 `ref` 的可回填性实现**。第 18 章的 ref 在这里第一次被用来构造**循环的纯数据**，而不是累加器。

三个注意点：

- 回填用 `rootCell := Delayed fibsKnotted`——直接改写 status，不经过 force；
- 占位里放 `raise Fail "unfilled"`，谁在回填前偷跑谁炸——把时序错误变成显式异常；
- 这个流是**记忆化的**：root 只生成一次，之后所有引用共享同一条流（对比 26.6 开头的 13529 次）。

## 26.7 本章小结

| 方案 | 调用/次数（fib 25） | 适用 |
|---|---|---|
| 朴素递归 | 242785 | 只算一两次 |
| `memoize` 包装 | **242785（没用！）** | 只缓存顶层调用 |
| 数组表 | 41 | 键稠密非负 |
| `memoRec` 开递归 | 41 | 任意递归、键可比较 |
| 惰性流 | 每元素一次 | 无穷序列、按需 |

坑位速查（详见第 32 章）：

- **memoize 包装不省递归**（坑 40）——这是本章最重要的单一教训；
- **`val rec` 只收 `fn`**——循环数据用 `fun` 打函数结或 ref 回填（坑 41）；
- 键的多态 `=` 会触发 `polyEqual` 警告，SML/NJ 上会污染 stdout——查表谓词把键钉成单态。
