# 13 · 无穷列表 ⭐

> 对应示例：`examples/13_infinite/`（Ch13.hs + main.hs + runtests.hs）。
> 本章对应原书第 9 章〈无穷列表〉——循环结构、素数筛、逼近序与不动点语义、石头剪刀布、
> 流式交互全部提炼；12 章的 thunk 机制是本章的机械基础，11 章的链完全归纳是本章的
> 证明基础。

## 13.1 无穷列表的值，你其实已经见过

```haskell
ghci> zip [1..] "hello"            -- [(1,'h'),(2,'a'),(3,'l'),(4,'l'),(5,'o')]
ghci> [x | x <- [1..], x*x < 10]   -- 打出 1,2,3 后沉默——值是 1:2:3:undefined
```

第一个例子是无穷列表最典型的用法：给有穷数据配一个无穷下标流，`zip` 自动截停。
第二个例子是**值**的教训：无穷列表的求值不一定终止，它的值可能是**非完整列表**
（09 章 9.1 的三分法在这里见血）——`[1..]` 本身是 `enumFrom 1 = 1 : enumFrom 2` 的
递归定义，`(:)` 对第二参数非严格，所以构造不停止也能进行。

## 13.2 循环列表：在定义里打一个结

数据结构和函数一样可以递归定义：

```haskell
ones :: [Int]
ones = 1 : ones            -- ones 的尾部指向 ones 自己：循环（cyclic）列表
```

与 `ones = repeat 1` 对照着看（原书 9.2）：

```haskell
repeat1 x = x : repeat1 x             -- 不打结：每次展开都新建结构
repeat2 x = xs where xs = x : xs      -- 打结：xs 在自己的定义里被共享
```

两个函数值相等，但**代价不等**——原书实测 `last (take 10000000 …)`：repeat1 用
2.95s / 8×10⁸ 字节，repeat2 用 **0.11s / 2.8×10⁸ 字节**。结（sharing）是真实的指针：
第二版里所有"下一个 x"都是同一个已构造的单元。

`iterate` 的三个定义把这件事讲得更透：

```haskell
iterate1 f x = x : iterate1 f (f x)      -- 库版：线性，但不共享
iterate2 f x = xs where xs = x : map f xs   -- 打结 + map 共享：线性（每步 O(1)）
iterate3 f x = x : map f (iterate3 f x)     -- 不打结：二次方！
```

为什么 iterate3 是二次方？展开两层就看穿：

```
iterate3 (2*) 1 = 1 : map (2*) (iterate3 (2*) 1)
                 = 1 : 2 : map (2*) (map (2*) (iterate3 (2*) 1))
                 = 1 : 2 : 4 : map (2*) (map (2*) (map (2*) …))
```

第 n 个元素外面套了 n 层 `map (2*)`——**重复计算没人共享**。iterate2 里 `map f xs`
的结果被 `xs` 这个名字共享，每来一个需求只算一次 `f`。示例 Ch13 三个定义齐活，
`take` 出的前若干项完全相同（机器对账），代价分析归 25 章。

最后是打结的招牌菜——斐波那契：

```haskell
fibs = 0 : 1 : zipWith (+) fibs (drop 1 fibs)
```

`fibs` 的第 n 项由它自己的第 n−1、n−2 项加出来——**定义引用自己**，靠共享免于重算。
`take 12 fibs` 得 `[0,1,1,2,3,5,8,13,21,34,55,89]`（示例实测）。

## 13.3 素数的循环筛：三版进化

目标：所有素数的无穷列表。第一版（09 章筛法的亲戚）：

```haskell
primes   = [2..] `minus` composites
composites = mergeAll [map (n*) [n..] | n <- [2..]]
  where  minus/merge 归并两个严格递增列表（去重/求差）
```

能跑，但混进了太多重复劳动（4 的倍数早被 2 的倍数覆盖）。改进思想：**只筛素数的倍数**
——这要求"素数表"参与定义自己：

```haskell
primes     = 2 : ([3..] `minus` composites)
composites = mergeAll [map (p*) [p..] | p <- primes]
```

这一版的诞生史是原书 9.2 最精彩的三步教学，每一步都是真坑：

1. **不打领带就打结**：直接写 `primes = [2..] \`minus\` composites`——求第一个素数
   要看 composites 的第一个元素，后者又要看 primes 的第一个元素。**死循环**。
   解法：把第一个素数 **2 显式写出来**，让计算有起点。
2. **`foldr1` 的 ⊥ 坑**：`mergeAll = foldr1 xmerge` 看起来对，但
   `foldr1 f (x:undefined) = undefined`（foldr1 先匹配完 `x:xs` 的形状才动工）——
   于是 `mergeAll [map (p*) [p..] | p <- 2:undefined] = undefined`，第 4 个合数都出不来。
   解法：手写 `mergeAll (xs:xss) = xmerge xs (mergeAll xss)`，其中
   `xmerge (x:xs) ys = x : merge xs ys` **先吐左边首元素、再看右边**——对无穷列表
   友好的归并。
3. 就地验证不动点逼近（原书）：`primes` 的逐轮逼近是 `2:⊥` → `2:3:⊥` →
   `2:3:5:7:⊥` → `2:3:5:7:11:…:47:⊥`——第 n 轮给出**小于 p²ₙ 的全部素数**，
   每轮平方级地增长。循环定义不是玄学，它是这条逼近链的极限。

示例 Ch13 实现最终版（`minus`/`merge`/`xmerge`/`mergeAll`/`primes`），runtests 用
小规模试除法对账前 50 个素数完全一致。

## 13.4 作为极限的无穷列表：approx 与不动点

为什么循环定义是**合法的**？原书 9.3 给出语义基础（浓缩版）：

- 每个类型上有一个**逼近序** `⊑`：`undefined ⊑ x`（⊥ 是"什么都不知道"），列表上
  `undefined ⊑ xs`、`(x:xs) ⊑ []`、`(x:xs) ⊑ (y:ys) ⇔ x ⊑ y ∧ xs ⊑ ys`。
  例：`1:2:undefined ⊑ [1,2,3]`——前者是后者的一个"近似"。
- 无穷列表 = 非完整列表**逼近链的极限**：`[1..]` 是 `⊥, 1:⊥, 1:2:⊥, …` 的极限，
  正如 π 是 `3, 3.1, 3.14, …` 的极限。
- Haskell 的每个类型是**完备偏序**（CPO）：每条链都有最小上界。可计算函数都
  **单调**（信息越多结果信息越多）且**连续**（f(极限) = 极限 f(近似)）——于是每个
  递归定义被解释为其函数的**最小不动点**：`ones = 1:ones` 的意思就是
  `lim ⊑ 1:⊥ ⊑ 1:1:⊥ ⊑ …`。

工具函数 `approx` 把"第 n 个近似"拿到手上：

```haskell
approx n _        | n <= 0 = undefined       -- 0 号近似：什么都不知道
approx n (x:xs)   = x : approx (n-1) xs      -- n 号近似：前 n 个元素 + ⊥
```

它的杀手级用法是**证明无穷列表相等**：`approx n xs = approx n ys` 对一切 n 成立
⟹ `xs = ys`（对 n 归纳）——11 章的"链完全"原理落到实处的样子。例：证
`iterate f x = x : map f (iterate f x)`，只需对每边取 `approx n` 后对 n 归纳。

**机器对账的坑**（本例实测翻过车）：`approx 5 xs == approx 5 ys` **不能直接跑**——
`==` 走到第 6 步撞上两边的 ⊥，异常。安全的机器写法是 `take k (approx n xs)`
（k ≤ n，取出的部分是完整列表）——证明用 `⊑`，测试用 `take`，分工见 11.9。

## 13.5 石头剪刀布：策略即流

规则：布包石头、石头钝剪刀、剪刀剪布。每轮双方同时出手，计分。类型先行：

```haskell
data Move = Paper | Rock | Scissors deriving (Eq, Show)
beats :: Move -> Move -> Bool     -- Paper `beats` Rock = True；……
type Round = (Move, Move)
score :: Round -> (Int, Int)
```

关键设计决策：**策略是什么类型**？原书对比两种答案：

```haskell
type Strategy1 = [Move] -> Move        -- 吃对手已出的（有穷）历史，回一手
type Strategy2 = [Move] -> [Move]      -- 吃对手的（潜在无穷）出手流，回一个流
```

两种策略的"复读机"（首手 Rock，此后复读对手上一手）：

```haskell
copy1 ms = if null ms then Rock else firstOf ms   -- Strategy1
copy2 ms = Rock : ms                              -- Strategy2：一行
```

Strategy1 的 `rounds1` 每轮把新回合**加到历史前面**，n 轮后算 O(n²)；
Strategy2 的 `rounds2` 是两个循环列表**互相定义**：

```haskell
rounds (p1, p2) = zip xs ys
  where xs = p1 ys      -- 我方流由对方流算出
        ys = p2 xs      -- 对方流由我方流算出
```

只要策略"诚实"，两个流互为函数、又都能先吐首元素——打结成功，**每个新回合 O(1)**，
n 回合 O(n)。"诚实"指：算第 k 手时不偷看对方第 k 手。不诚实的例子一眼见赃：

```haskell
cheat ms = map trump ms             -- 每一手都出克制对方"当前这一手"的牌
devious n ms = take n (copy ms) ++ cheat (drop n ms)   -- 前 n 手装老实
```

`cheat` 对 `copy` 十回合 **10:0**（示例实测输出）；`devious 7` 十回合 3:0——赢的正好是
开始作弊后的 3 手。原书用 `wdf`（前 n 个元素良好定义）给诚实性下了形式化定义，并给出
`police` 强制"先出后看"的组合子——**无穷流的模型里，作弊是类型系统管不住、但语义
分析能定义清楚的东西**，这是"形式化必要性"的绝佳一课。

书里的 `smart` 策略（统计对手三种手势频次、按比例选克制牌）用了 `System.Random`——
那不是 boot 库，示例换成**确定性整数哈希**：对局可复现，runtests 才敢断言比分
（smart 对 copy 十回合 3:0 实测）。

## 13.6 流式交互：interact

同样的"函数吃流、产流"模型可以建模与外界的交互（原书 9.5）：

```haskell
interact :: (String -> String) -> IO ()
-- 参数函数吃"标准输入的潜在无穷字符流"，产"标准输出的潜在无穷字符流"
ghci> interact (map toUpper)          -- 每敲一行，回一声全大写——直到中断
ghci> interact (map toUpper . takeWhile (/= '.'))   -- 遇句点终止的版本
```

一个能编译的完整例子——把文学脚本（.lhs）转普通脚本：吃全文、滤掉非代码行、
剥掉代码行的 `>` 标记、拼回文本。Haskell 早期（无 IO 单子的年代）**流模型就是**
**与外界交互的主要方式**；它的局限也很清楚：事件的次序藏在**数据**的次序里，
程序文本上看不出先干什么后干什么——这正是 IO 单子要解决的（16/19 章），
也是 22 章并发流水的伏笔。

## 13.7 双向链表：结的另一种打法

读书翻页：`next` 到下一页、`prev` 回上一页，最后一页的下一页是第一页——**循环
双链表**。核心类型（原书 9.6）：

```haskell
data DList a = Cons a (DList a) (DList a)   -- 元素 + 前驱 + 后继
elem' (Cons a _ _) = a
prev (Cons _ p _)  = p
next (Cons _ _ n)  = n
```

构造一本 n 页的书要打 n 个互相咬合的结——每个 `Cons` 的前驱和后继指针指向**还没
构造完的邻居**，惰性让"先引用、后填上"成为合法施工顺序。命令式语言里这是指针操作
的地盘，Haskell 用一个递归 `mkDList` 一层循环搞定（13.9 练习动手写）。

## 13.8 坑位清单

1. **`approx n xs` 的尾部是 ⊥**：直接 `==` 比较两个近似会撞异常——机器对账用
   `take k (approx n xs)`（k ≤ n）（13.4，本例实测）。
2. **`foldr1 f (x:⊥) = ⊥`**：`mergeAll = foldr1 xmerge` 在无穷列表的列表上死——
   手写"先吐左边"的 `xmerge` 版本（13.3）。
3. **循环定义要有起点**：`primes` 必须显式写 `2 : …`，否则"求第一个元素要靠第一个
   元素"死循环（13.3）。
4. **`iterate3` 式不打结的 map 是二次方**：`x : map f (recurse x)` 每层重包一层 map——
   要共享就把递归结果 `where` 绑名再 `map`（13.2）。
5. **无穷列表别直接打印/求长度**：`length [1..]`、`sum [1..]`、`maximum [1..]`
   都是"合理类型的死循环"——需求全部元素的操作要求列表**有底**（09 章）。
6. **`System.Random` 不是 boot 库**：书里的 `rand` 在本教程主线里换成确定性哈希
   ——顺带收获可复现的对局断言（13.5）。

## 13.9 练习（选自原书第 9 章习题）

**练习 13.1（approx 与 take）**：证 `take n xs = take n (approx n xs)`，再证
`lim approx n xs = xs`（对 xs 归纳——三种列表各证一遍，体会"极限"如何在有穷列表上
退化成自身）。

**练习 13.2（iterate 相等）**：用 approx 方法证
`iterate f x = x : map f (iterate f x)`——对 n 归纳比较两边的 `approx n`。

**练习 13.3（mkDList）**：给 `mkDList :: [a] -> DList a` 一个定义：把页面列表变成
循环双链表。提示：让每个结点的后继是"从下一页开始构造的结果"，前驱是"从上一页
开始构造的结果"——两个方向都递归，起点补在尾部闭合。

**练习 13.4（诚实性检查）**：按"wdf(n, ms) ⟹ wdf(n+1, f ms)"的定义逐一验证
`copy`、`cheat`、`devious 7`、`const (repeat undefined)`（书里的 dozy：不作弊但
也不诚实）。哪几个过得了关？

---

上一章：[12 惰性求值](12-laziness.md) ｜ 下一章：[14 容器](14-containers.md) ｜ 返回：[README](../README.md)
