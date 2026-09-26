# 27 · 持久与易失数据结构：队列、共享与摊还

> 对应示例：`examples/25-queues.sml`
> 参考书：Harper《Programming in Standard ML》第 28 章（Persistent and Ephemeral Data Structures）：28.1 Persistent Queues、28.2 Amortized Analysis。

函数式数据结构有一个命令式结构没有的性质：**持久性（persistence）**——操作不销毁旧版本，`(q, q', q'')` 可以同时活着，各答各的。代价是它不能就地改；好处是时间旅行免费。Harper 第 28 章用队列把这两面讲透了，本章照做，并且把摊还分析从数学变成**可数的 cons 格子**。

## 27.1 反例：单列表队列

```sml
fun badSnoc (q : int list, x) = q @ [x]      (* @ 要把整个 q 抄一遍 *)
```

入队 5 次：抄 0+1+2+3+4 = **10 个格子**。m 个操作总功 O(m²)。示例第 1 节的计数器当场数了出来。

## 27.2 双列表批式队列

标准解法（Okasaki 式 batched queue）：

```sml
datatype 'a queue = Q of 'a list * 'a list    (* front, rear *)

fun norm (Q (f, r)) =
    if null f then Q (rev r, []) else Q (f, r)

fun snoc (Q (f, r), x) = norm (Q (f, x :: r))
fun qhead (Q (x :: _, _)) = x
  | qhead (Q ([], _)) = raise QEmpty
fun qtail (Q (x :: f, r)) = norm (Q (f, r))
  | qtail _ = raise QEmpty
```

不变式：**front 为空时，rear 必须整个翻过来接班**（`norm` 是唯一的翻转点）。入队 `x :: r` 是 O(1)；出队只在 front 枯竭时触发一次 `rev`。

示例第 3 节的实测：200 次入队 + 100 次出队，共分配 **129 个格子**，摊到每个操作 **0.43 个**——对比单列表版的 **9900 个格子**，差 76 倍。

## 27.3 摊还分析：为什么总功是 O(m)

直觉：`rev` 只在 front 篱笆倒下时发生，而 **rear 里的每个元素自进入队列起至多被翻转一次**。于是 m 个操作的总功 ≤ O(1) × m（入队各一格）+ O(1) × m（每个元素至多被 rev 搬一次）= O(m)。

这就是**摊还分析**（amortized analysis）：单次操作可能贵（worst case O(n) 的 rev），但贵操作的出现频率被此前的便宜操作「预付」了。示例用计数器把「预付」变成可见的数字——0.43 格/操作 < 2 格/操作的理论上界。

**重要限定**（Harper 28.2 结尾的警告）：这个摊还界**只对单线（ephemeral）使用成立**。如果持久地反复回溯到「front 即将枯竭」的历史版本，每次出队都触发全额 rev，摊还上界被击穿。要持久 + 摊还同时成立，需要惰性 + 记忆化的队列（Okasaki 的真正贡献）——那是第 25/26 章工具的组合题，这里点破为止。

## 27.4 持久性：旧版本照常可用

```sml
val qa = qFromList [1, 2, 3, 4]
val qb = qtail qa                 (* 出队一次 *)
val qc = snoc (qb, 99)            (* 再入队一个 *)
```

三个版本同时活着：`qhead qa = 1`（1 还在），`qToList qb = [2,3,4]`，`qToList qc = [2,3,4,99]`。操作**返回新队列**而不是修改旧队列——这是所有示例里 `val _ =` 链的底层原因。

## 27.5 结构共享的可移植证明

「qb 与 qa 共享了尾部」这件事，标准 SML 没有物理相等运算符（SML/NJ 的 `==` 是扩展，Poly/ML 与 MLton 没有或语义不同）。可移植的证明术是**变异探针**：元素放 ref，改一处，观察哪些版本看得见。

```sml
val marker = ref 10
val sq1 = snoc (snoc (empty : int ref queue, marker), ref 20)
val sq2 = snoc (sq1, ref 30)
val _ = marker := 99
(* qhead sq1 与 qhead sq2 现在都读到 99 *)
```

两个「不同版本」的队列看见同一个 99——它们**共享同一个元素格子**。这就是持久性便宜的来源：`snoc` 不抄旧结构，只是沿 rear 加一格、其余全部复用。

## 27.6 易失队列：快，但旧版本没了

```sml
type 'a equeue = {front : 'a list ref, rear : 'a list ref}

fun elenq ({front, rear} : 'a equeue, x) = rear := x :: !rear
fun etail (eq as {front, ...} : 'a equeue) =
    (enorm eq;
     case !front of
         _ :: f => front := f
       | [] => raise QEmpty)
```

同样的双列表技巧，但格子是 `ref`，更新就地发生。示例第 4 节的对照：

```
ehead eq1 = 10
after etail via eq2, ehead eq1 = 20   (* 10 没了，别名可见 *)
persistent: head pq = 10
after qtail, head pq = 10             (* 10 还在 *)
```

`eq2 = eq1` 之后，通过 `eq2` 出队，`eq1` 立刻看见——**别名共享同一个可变记录**。持久版同样的剧本里 `pq` 处变不惊。

选择的标准（Harper 的总结）：

| | 持久 | 易失 |
|---|---|---|
| 旧版本 | 永远可用 | 被销毁 |
| 别名 | 无害（怎么共享都不改） | 危险（一处改动处处可见） |
| 常数因子 | 略大 | 更小 |
| 回溯/撤销/并发快照 | 天然支持 | 要自己造 |

## 27.7 本章小结

- 队列的摊还 O(1) 来自「**每个元素至多被 rev 一次**」，计数器可以当场验证；
- 持久性 = 操作返回新结构 + 物理共享，变异探针（元素放 ref）是证明共享的可移植手段；
- 易失结构把别名变成协议：谁持有引用，谁就看得见所有修改；
- 摊还界在**反复回溯历史版本**时会失效——要持久摊还，得把第 25 章的惰性用上。

坑位速查（详见第 32 章）：

- **无参值绑定必须 `val` 不能 `fun`**（`fun empty = ...` 三家都报错，坑 42）；
- **`handle` 的体必须与被包表达式同类型**——想拿到异常本身打 `exnName`，用 `exn option ref` 中转（示例第 2 节实录，坑 43）；
- 出队空队列的 `QEmpty` 是自己的异常，别和 `List.Empty` 撞名。
