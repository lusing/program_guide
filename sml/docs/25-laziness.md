# 25 · 惰性求值与流

> 对应示例：`examples/23-laziness.sml`
> 参考书：Harper《Programming in Standard ML》第 15 章（Lazy Data Structures）、第 30.1 节（Infinite Sequences）、第 31.2 节（Laziness）；Myers/Clack/Poon《Programming with Standard ML》附录 F（Delaying Evaluation）。

SML 是**严格求值**语言：函数的实参在进入函数体之前全部求值，`Cons (head, tail)` 的两个分量在构造格子时立即算。但「按需计算」并非严格语言的禁区——只要把「计算」本身做成值，想算的时候再运行它。这一章讲的就是这套模拟术：**挂起（suspension）与流（stream）**。

Harper 在第 15 章开宗明义：惰性的主要好处是支持**按需驱动的计算**（demand-driven computation）。两类典型场景：

- **无穷数据结构**：素数序列永远算不完，但「算到当前需要的第 N 个」随时可以；
- **交互式数据结构**：用户的输入在程序启动时并不存在，它是随计算推进「按需产生」的。

## 25.1 朴素 delay：就是函数，force 两次算两次

最朴素的挂起就是一个函数：

```sml
type 'a ndelay = unit -> 'a
fun ndelay (f : unit -> 'a) : 'a ndelay = f
fun nforce (d : 'a ndelay) : 'a = d ()
```

它有惰性的形，没有惰性的魂：**每次 force 都重算一遍**。示例第 1 节用计数器量了出来——force 两次，计算发生两次。

## 25.2 记忆化 suspension：算一次，之后读缓存

Harper 第 31.2 节给的标准接口：

```sml
signature SUSP = sig
    type 'a susp
    val force : 'a susp -> 'a
    val delay : (unit -> 'a) -> 'a susp
end
```

`delay` 的职责是**记忆化**：挂起的计算至多求值一次，结果存进 ref，之后的 force 全走缓存。Harper 的实现很巧——不用状态机 datatype，而是「自改写」的 thunk：

```sml
structure Susp :> SUSP = struct
    type 'a susp = unit -> 'a
    fun force t = t ()
    fun delay (t : 'a susp) =
        let
            exception Impossible
            val memo : 'a susp ref = ref (fn () => raise Impossible)
            fun t' () =
                let val r = t ()
                in memo := (fn () => r); r end
        in
            memo := t';
            fn () => (!memo)()
        end
end
```

`delay` 先放一个永远不该被强制的占位 thunk；真正的 `t'` 被强制时先算出 `r`、**把 memo 换成立即返回 r 的常函数**、再返回 r。于是第一次 force 走计算，之后所有 force 走缓存。Harper 的验证方式是 `delay (fn () => print "hello")` 强制两次只打印一次。

本目录的示例用了更容易看懂的等价实现——`datatype` 状态机：

```sml
datatype 'a status = Delayed of unit -> 'a | Value of 'a
type 'a susp = 'a status ref

fun delay (f : unit -> 'a) : 'a susp = ref (Delayed f)
fun force (s : 'a susp) : 'a =
    case !s of
        Value v => v
      | Delayed f => let val v = f () in s := Value v; v end
```

两种实现语义相同（至多算一次），示例第 2 节的计数器给出 `computations=1`。顺带注意：这里 `case !s of` 是**模式匹配**，不涉及 `=`，所以 status 里装着函数也不影响——datatype 模式匹配不要求相等类型。

## 25.3 流：由挂起串起来的无穷列表

```sml
datatype 'a stream = Nil | Cons of 'a * 'a stream susp
```

对比普通列表 `Cons of 'a * 'a list`：尾巴从「已经是的列表」换成了「将来会是流的计算」。于是：

```sml
fun sfrom (n : int) : int stream = Cons (n, delay (fn () => sfrom (n + 1)))
```

`sfrom 1` 立即返回，代价是 O(1)；往后走一格才构造下一格。`stake`/`sdrop` 在它上面取多少算多少——示例第 3 节 `sdrop 97` 之后再 take 3，输出的确从 107 开始。

**注意这里埋着本章头号实测坑**。流的 take 直觉写法是：

```sml
(* 有坑的写法 *)
fun stake (n, Cons (x, rest)) = x :: stake (n - 1, force rest)
  | stake (_, Nil) = []
```

在严格语言里，`stake (n - 1, force rest)` 的实参 `force rest` **在进入函数体、检查 n 之前就被求值**。取前 n 个元素会顺带强制第 n+1 格。如果第 n+1 格埋着 `Div`（示例第 7 节真埋了一颗），take n 也会炸。正确写法是把「检查 n」与「force」拆成两层：

```sml
fun stake (n : int, s : 'a stream) =
    if n <= 0 then []
    else case s of
             Nil => []
           | Cons (x, rest) => x :: stakeS (n - 1, rest)
and stakeS (n : int, r : 'a stream susp) =
    if n <= 0 then [] else stake (n, force r)
```

这不是学究式洁癖——**严格语言里写惰性工具函数，边界检查必须先于强制**，否则惰性的「不算用不到的」承诺就漏了。

## 25.4 流上的 map / filter

```sml
fun smap (f : 'a -> 'b, Cons (x, rest)) =
        Cons (f x, delay (fn () => smap (f, force rest)))
  | smap (_, Nil) = Nil
```

结构完全平行于列表版，只是递归点包进了 `delay`。注意 `Cons (f x, ...)` 的头是**立即**算的——只有尾巴延迟。示例第 4 节：`map (*2)` 与 `filter odd` 作用在 `sfrom 1` 上各取 6 个，输出与列表版一致。

## 25.5 素数的无穷筛

厄拉多塞筛的流版本（示例第 5 节）：

```sml
fun sieve (Cons (p, rest)) =
        Cons (p, delay (fn () => sieve (sfilter (fn x => x mod p <> 0,
                                                  force rest))))
  | sieve Nil = Nil
```

取出素数 p，把「p 的倍数」从尾巴滤掉，再对滤过的流递归。前 10 个素数、第 50 到第 55 个素数，都按需产出。这个写法的性能不是最优的（每个素数挂一层 filter，同一合数会被多个素数检查），但它是「无穷结构 + 按需计算」最经典的演示。示例第 8 节用计数器量了实际代价：筛出前 600 个素数（第 600 个是 4409），共做了 188353 次取模——平均每个被检查的整数约 43 次，因为每个合数要被所有小于它的素数各筛一遍。

## 25.6 斐波那契流：状态对前移

```sml
fun fibs () : int stream =
    let
        fun go (a, b) = Cons (a, delay (fn () => go (b, a + b)))
    in
        go (0, 1)
    end
```

注意 `fibs` 是函数不是值：`go` 递归引用自己，只能用 `fun` 打结（`val rec` 只接受 `fn`）。更彻底的「自引用流」——`fibs = 0 :: 1 :: (fibs + tail fibs)`——需要递归挂起，那是下一章（第 26 章）的主题。

## 25.7 非严格的证据：埋雷不踩不响

示例第 7 节在流的第三格埋了 `100 div 0`。**雷只能埋在挂起的尾巴里**——`Cons` 的第一个分量在构造格子时就求值，写 `Cons (100 div 0, delay ...)` 是当场爆炸；包进 `delay` 的函数体才是延迟的部分。take 2 之后检查第三格的挂起，状态仍是 `delayed`——雷没踩。

## 25.8 SML/NJ 的 `lazy` 扩展：知道就好，别在三通道代码里用

Harper 第 15 章的写法基于 SML/NJ 私有扩展：

```sml
Compiler.Control.lazysml := true;
open Lazy;

datatype lazy 'a stream = Cons of 'a * 'a stream   (* 没有基础情形！ *)
val rec lazy ones = Cons (1, ones)                  (* 循环流 *)
```

第 31.3 节揭示了它展开成什么：`datatype lazy 'a stream` 其实是

```sml
datatype 'a stream! = Cons of 'a * 'a stream
withtype 'a stream = 'a stream! Susp.susp
```

——**流的类型本身就是「流值的挂起」**。构造 `Cons e` 自动 `delay`，模式匹配自动 `force`。`val rec lazy` 则让递归值的打结由编译器完成。

问题：Poly/ML 没有这个扩展，MLton 要 `-default-ann` 开编译开关且语义有差异。本目录要求三通道逐字节一致，所以全部示例用 25.2–25.3 的可移植写法（datatype + ref + 显式 delay/force）。`val rec lazy ones` 的可移植替代（ref 占位 + 回填）在第 26 章实录。

## 25.9 本章小结

| 概念 | 可移植写法 | SML/NJ 扩展 |
|---|---|---|
| 挂起 | `datatype status + ref` 或自改写 thunk | `lazy` 表达式 |
| 流 | `Cons of 'a * 'a stream susp` | `datatype lazy stream` |
| 循环流 | `fun` 打结 / ref 占位回填 | `val rec lazy` |
| 记忆化 | force 时改写格子 | 内建于 `lazy` |

坑位速查（详见第 32 章）：

- **take/drop 的惯用写法会多 force 一格**——边界检查必须先于强制（本章实测，坑 39）；
- **雷埋不进 `Cons` 的头**——严格语言构造格子即求值第一个分量；
- **`datatype status` 的模式匹配不受 eqtype 限制**——匹配不是相等性比较。
