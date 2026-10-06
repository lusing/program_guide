# 25 · 性能 ⭐

> 对应示例：`examples/25_performance/`。
> 本章对应原书第 7 章〈效率〉——惰性求值的代价、空间与时间的控制、时间复杂度演算、
> 累积参数与元组两大优化策略、排序案例，全部提炼；工程工具段（RTS/profiling/Builder）
> 是本教程的现代补充。原书开篇引用 Alan Perlis 改王尔德：**"函数式程序员知道一切东西
> 的价值，却不知道它们的价格。"** 本章教你看价格。

## 25.1 优化次序：算法 > 数据结构 > 严格性 > 常数

```haskell
fibNaive 24       -- 指数级：~10ms 级
fibAcc 90         -- 线性：瞬时（2880067194370816120）
```

同一优化级别下数量级的差距——先动算法，别的都白搭（04 章累加器的回响；11 章 mss
从 n³ 算到 n 是最完整的示范）。本章处理算法之下的层次：**你知道一个定义的代价吗？**

## 25.2 惰性求值的代价（书7.1）

**惰性求值的第一承诺**：参数只在需要时求值、只求一次。`sqr (sqr (3+4))` 的化简是
`let y = 3+4 in let x = y*y in x*x`——`3+4` 只算一次，因为 `let` 名字在实现里是
**指针**，算出值后大家共享。更精确的表述（书里的措辞）：**需要时求值，一次，且只算到
首范式**（head normal form——函数或构造子应用到参数的形状；`(e1, e2)` 已经是首范式，
尽管 e1、e2 还没算）。

**但共享不是免费的**。看 `subseqs`（所有子序列）两版：

```haskell
subseqsSlow   (x:xs) = subseqsSlow xs ++ map (x:) (subseqsSlow xs)   -- 递归出现两次：算两次
subseqsShared (x:xs) = xss ++ map (x:) xss  where xss = subseqsShared xs  -- 绑名共享：算一次
```

慢版 Θ(n·2ⁿ)、共享版 Θ(2ⁿ)（25.5 演算）——但共享版**把整张子序列表攥在内存里**
（第二处还要用）。书的原则：**省时间就得用空间存，一分为二永不相欠**。Haskell 不做
公共子表达式消去正是这个道理——自动共享可能造成空间泄漏，控制权留给程序员。

**局部与顶层（CAF）的差别**——同一个函数的三种写法，第二次求值天差地别（书里 GHCi
`:set +s` 实测 4.52s vs 0.02s）：

```haskell
foo1 n = sum (take n primes)  where primes = …   -- primes 绑在"每次应用"上：每调用重算
foo2 n = sum (take n primes)                    -- 顶层 CAF：算一次，永久共享（也永久占内存）
foo3   = \n -> sum (take n primes) where primes = …  -- lambda 版：等价于绑在函数上
```

**绑在哪一层，共享到哪一层**——这是惰性语言独有的性能维度。

## 25.3 空间的控制：seq 与 foldl'（书7.2）

`sum = foldl (+) 0` 求和 `[1..1000]` 的化简先堆出一座 **thunk 山**：

```
foldl (+) 0 [1..1000]
= foldl (+) (0+1) [2..1000]
= foldl (+) ((0+1)+2) [3..1000]
= …（1000 层未求值的算式）…
```

解药是**惰性与勤奋的混搭**：列表本身懒着走，累加和每步算掉。原始武器 `seq`：

```haskell
x `seq` y     -- 先把 x 求到首范式，再返回 y
foldl' f e []       = e
foldl' f e (x:xs)   = y `seq` foldl' f y xs  where y = f e x   -- Data.List 现成
```

**mean 的三连修**（书 7.2 的招牌案例，一步一个坑）：

```haskell
mean xs = sum xs / length xs           -- ① 类型错：Int 不能除 Float
mean xs = sum xs / fromIntegral (length xs)   -- ② 静默漏掉空表
mean [] = 0                                   -- ③ 空间泄漏：sum 走完后列表还被 length 攥着
```

元组化（25.7）把两次遍历并成一次：`sumLen = foldl' step (0,0)`，但**只 seq 到首范式
还不够**——`(s+x, n+1)` 本来就是首范式，两个分量仍是 thunk！要**深入分量**：

```haskell
step (s, n) x = s `seq` n `seq` (s + x, n + 1)    -- 分量也强制：真正的常数空间
```

顺手认识两个应用运算：`f $ x` 只是**优先级最低的右结合应用**（省括号）；
`f $! x` 是**严格应用**——先用值再调函数（18 章 fibST 里的 `writeSTRef b $! x+y`
就是它）。

## 25.4 运行时间的控制（书7.3）

GHC 文档的三条忠告（照抄书）：用 profiling 工具度量（不可替代）；**改算法**收益最大；
**用库函数**（人家调过、编译过——GHCi 里库的编译版比解释版快一个数量级）。两个窍门：

- **严格函数是你的朋友**：知道值会被用到，就按下勤奋键（`foldl'`/`$!`/bang）。
- **类型具体化**：`Int` 算术快于 `Integer`；给 `foo1 :: Int -> Integer` 这类具体签名，
  GHC 不用随身携带类型类的方法字典。

**优雅定义里的隐藏账单**——`cp`（笛卡尔积）的两版（书里实测 12.11s vs 4.54s）：

```haskell
cp (xs:xss) = [x:ys | x <- xs, ys <- cp xss]     -- cp xss 在生成器里：每个 x 都重算一次！
cp' (xs:xss) = [x:ys | x <- xs, ys <- yss] where yss = cp xss   -- 共享：只算一次
```

列表概括太顺手，**"写了一次"不等于"算了一次"**——内层生成器里出现的递归调用按外层
元素次数重复求值。`where` 绑名是最便宜的修复。

## 25.5 时间分析：T(f)(n) 演算（书7.4）

给每个定义算一笔账 `T(f)(n)`（n 规模下化简步数的渐进估计，按勤奋求值模型——
**惰性步数 ≤ 勤奋步数**，上界照用）。Θ 记号：f = Θ(g) 即 f 被 g 的正常数倍上下夹住。
演算是解递推方程，三个书例：

| 定义 | 递推 | 解 |
|---|---|---|
| `concat = foldr (++)`（m 段各长 n） | T(m+1) = T(m) + Θ(n) | **Θ(mn)** |
| `concat = foldl (++)` | T(m+1) = T(m) + Θ(平均累积长) | Θ(mn)，常数更差 |
| `subseqs` 慢/快版 | 2T(n)+Θ(2ⁿ) / T(n)+Θ(2ⁿ) | Θ(n·2ⁿ) / **Θ(2ⁿ)** |
| `cp` 无共享/foldr 版 | nT(m)+Θ(nᵐ) / T(m)+Θ(nᵐ) | Θ(m·nᵐ) / **Θ(nᵐ)** |

**写完递推，"哪个快一个对数因子"自己跳出来**——比掐秒表更能服人。

## 25.6 累积参数（书7.5）

给函数**加一个额外输入参数**携带中间结果。教科书案例 `reverse`（Θ(n²)）：

```haskell
reverse (x:xs) = reverse xs ++ [x]      -- T(n) = T(n-1) + Θ(n) = Θ(n²)
```

**计算**出快速版（11 章方法论的又一胜仗）：定义 `revcat xs ys = reverse xs ++ ys`
（故 `reverse = \xs -> revcat xs []`），对它做归纳情况的等式推导：

```
revcat (x:xs) ys
  = {revcat 定义}        reverse (x:xs) ++ ys
  = {reverse 定义}       (reverse xs ++ [x]) ++ ys
  = {++ 结合律}          reverse xs ++ ([x] ++ ys)
  = {(:) 定义}           reverse xs ++ (x:ys)
  = {revcat 定义}        revcat xs (x:ys)
```

一行结论：`revcat [] ys = ys; revcat (x:xs) ys = revcat xs (x:ys)`——Θ(n)，每个元素
O(1) 地"压头"进累积参数。示例实测两版同值、快版显著更快（20000 元素计时对照）。

同款套路：`length` 由 `lenplus xs n = length xs + n` 算出 `foldl (\n _ -> n+1) 0` 版
（配 `foldl'` 常数空间——这正是 Prelude `length` 的定义）；树的 `labels` 由
`labcat`（累积 + 列表参数）从 Θ(s log s) 降到 Θ(s)。**规律：结合律是把"追加"变
"压头"的合法性证书**。

## 25.7 元组（书7.6）

累积参数的**对偶**：给输出加一个额外结果。招牌是 fib：

```haskell
fib n = fib (n-1) + fib (n-2)             -- T(n) = T(n-1)+T(n-2)+Θ(1) = Θ(φⁿ)：指数！
fibPair n = fst (go n)                     -- 一次递推同时带出 (fib n, fib (n+1))
  where go 0 = (0,1); go k = (b, a+b) where (a,b) = go (k-1)   -- Θ(n)
```

一般定律（**foldr 元组定律**，归纳可证）：

```haskell
(foldr f a xs, foldr g b xs) = foldr h (a,b) xs   where h x (y,z) = (f x y, g x z)
```

两趟并一趟，时间空间双收。25.3 的 `sumLen`、25.8 的 `partition` 都是它的特例。
树版例子：`build`（列表建平衡树）由 `build2 n xs = (build (take n xs), drop n xs)`
元组化，从 Θ(n log n)（halve 反复切）降到 Θ(n)——**算出定义**的推导与 revcat 同款。

## 25.8 排序：两个算法的性价比（书7.7）

**归并排序**（09 章 9.7 的 msort）：`halve` 的三种改法——`splitAt` 一趟切、`sort2`
元组版免求长、"分两堆"`halve (x:y:xs) = (x:ys, y:zs)`——书里实测结论诚实：
**都是几个百分点的改进，没有实质变化**（Θ(n log n) 不动）。别为了常数复杂化代码。

**快速排序**的 Haskell 两行是"表现力广告"，代价也要看清：

```haskell
qsort [] = []
qsort (x:xs) = qsort [y | y <- xs, y < x] ++ [x] ++ qsort [y | y <- xs, x <= y]
```

最坏 Θ(n²)（已排序输入，k=0 或 k=n 的划分）——这是算法本性，与语言无关。而快排
盛名的两大理由（**原地划分**省空间、平均常数小）在纯列表版里**都不成立**：划分产生
新列表；惰性下还有书里点名的**空间泄漏**——`partition p xs` 的二元组被两个递归分支
分别攥着，严格递减输入排序要 Θ(n²) 空间。修法是元组 + 深入分量的严格求值：

```haskell
partitionT p = foldr op ([], [])             -- 25.7 元组定律：一趟两分
  where op x (ys,zs) | p x = (x:ys, zs) | otherwise = (ys, x:zs)
```

（书里进一步用双累积参数 `sortp` 彻底断开二元组的滞留——思路同 revcat，篇幅见原书；
工程实践中 Data.List.sort 的归并已是正确默认。）

## 25.9 工具箱：计时与观测（现代补充）

**计时时必须 force 结果**——否则你测的是"造 thunk"的时间：

```haskell
timed :: NFData a => IO a -> IO (Double, a)
timed act = do
    t0 <- getMonotonicTime               -- GHC.Clock（boot）
    x <- act
    y <- evaluate (force x)              -- 完全求值完才停表
    t1 <- getMonotonicTime
    pure (t1 - t0, y)
```

```bash
./25.exe +RTS -s         # 运行时统计：内存/分配/GC——foldl vs foldl' 的账单在这看
./25.exe +RTS -N4        # 多核（29 章 -threaded）
ghc -O2 …                # 发布用 -O2（注意：foldl 的泄漏在 -O2 下可能被严格性分析救掉，教学复现用 -O0）
ghc -ddump-strictness …  # 看严格性分析判定（教学演示用）
```

字符串拼接的平方律（09 章 `++` 左嵌套的工程版）：`foldl (++) ""` 是 O(n²) 拷贝，
`Data.Text.Lazy.Builder` 分段累积一次成型——4000 段实测秒级 vs 毫秒级（示例断言同值
同长，时间数字进正文不进断言）。生态（不入主线）：criterion（基准）、`-prof`（剖析）、
eventlog（并发观测）。

## 25.10 坑位清单

1. **计时不 force = 测了个寂寞**：thunk 构造远比求值便宜——`timed` 的 `evaluate (force …)`
   是教科书姿势（25.9）。
2. **`seq` 只到首范式**：`(s+x, n+1)` 已是首范式——元组的分量要 `s `seq` n `seq``
   逐个强制，mean 的最终修（25.3，书里点破的隐蔽坑）。
3. **断言别断耗时数字**：机器/负载相关——值与不等式关系（tSlow > tFast 级别）才稳定
   （本教程实测约定）。
4. **共享换空间**：`where` 绑名省时间，但被两处引用的大结构滞留内存——subseqs/foo2
   的取舍（25.2）。
5. **列表概括里的递归调用按外层次数重算**：`[x:ys | x <- xs, ys <- cp xss]` 要提出
   `where yss = cp xss`（25.4）。
6. **CAF 永久共享也永久占内存**：顶层 `primes` 第二次免费、第一次的内存不还（25.2）。
7. **`foldl` 的泄漏在 -O2 下可能被优化掉**：`-O0` 复现最稳；生产反正写 `foldl'`（25.9）。

## 25.11 练习（选自原书第 7 章习题）

**练习 25.1（foldl vs foldl'）**：构造 f、e、xs 使 `foldl f e xs ≠ foldl' f e xs`；
再证：若 f 严格（f ⊥ = ⊥），两者恒相等。
（提示：f 取"懒"的二元组构造，e=⊥ 时 foldl 能先出首范式。）

**练习 25.2（元组定律的条件）**：书 7.2 用了
`foldr f e xs = foldl g e xs`（条件 `f x (g y z) = g (f x y) z` 与 `f x e = g e x`）。
对 `sumLen` 的 f/g 验证这两条；再用 25.7 的 foldr 元组定律直接证 `(sum xs, length xs)`
的单趟版。

**练习 25.3（halve 分两堆）**：`halve (x:y:xs) = (x:ys, y:zs)` 版的 msort 与 take/drop
版**结果不必相同**（元素分布不同）——但排序结果相同。证明：两个 halve 都是输入的
划分（每个元素恰落一侧）。

**练习 25.4（自己演算）**：给 25.5 的表格补上 `subseqs` 两版的递推求解过程
（对 n 归纳证 T(n) = Θ(n·2ⁿ) 与 Θ(2ⁿ)）。

---

上一章：[24 Template Haskell](24-th.md) ｜ 下一章：[26 优美打印](26-pretty.md) ｜ 返回：[README](../README.md)
