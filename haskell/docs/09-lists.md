# 09 · 列表与折叠 ⭐

> 对应示例：`examples/09_lists/`。
> 本章对应原书第 4 章〈列表〉——记法与三种列表（书 4.1）、列表概括（4.3）、`++` 的代价（4.5）、
> concat/map/filter 定律族（4.6）、zip/zipWith（4.7）、高频词完整解与归并排序（4.8）全部提炼；
> 折叠一节衔接原书第 6 章（11 章给证明）。原书名言照抄：**"列表是函数式程序设计的引擎。"**

## 9.1 列表是递归结构：一个构造子看世界

```haskell
data [a] = [] | a : [a]        -- 列表的定义（概念版；书里写成 Nil | Cons a (List a)）
```

`:` 是构造子（cons）：`[1,2,3]` 只是 `1 : 2 : 3 : []` 的简写（`:` 右结合，无需括号）。
构造子**没有计算规则**——`1 : 2 : []` 不再化简，它就是值本身。于是"对列表编程"只有
一种姿势：模式匹配拆开 `x : xs`，对首元素做点什么，对尾部递归。

由此，`[a]` 类型的每个列表只有三种形态（原书 4.1 的三分法，比"列表就是序列"的直觉精确）：

1. **有穷列表**：用 `(:)` 和 `[]` 构造，如 `1:2:3:[]`；
2. **非完整列表**（partial）：用 `(:)` 和 `undefined` "收尾"，如 `filter (<4) [1..]`——
   它等于 `1:2:3:undefined`。我们（数学上）知道 3 之后没有小于 4 的整数了，但 Haskell
   是计算器不是定理证明器，它会一直往后找；
3. **无穷列表**：只用 `(:)` 构造，如 `[1..]`。

这一分法立即产出有趣的观察：`undefined ++ [1,2]` 是 `undefined`（对左参数一无所知），
而 `[1,2] ++ undefined` 是 `1:2:undefined`——**知道开头，不知道结尾**。再看一个
"三种列表都正常工作"的例子（原书）：

```haskell
head (filter perfect [1..])
  where perfect n = (n == sum (divisors n))    -- 第一个完全数：6
```

没人知道 `filter perfect [1..]` 是有穷、非完整还是无穷列表——但 `head` 只要第一个元素，
惰性求值让这个问题无关紧要。顺带一个漂亮的化简：3 章用过的 `until` 原来是三个
更简单函数的复合——`until p f = head . filter p . iterate f`。**简单函数像质子，复合
出的一切是夸克级景观**（原书比喻）。

## 9.2 枚举与列表概括

**枚举记法**（`Enum` 类族，`Char` 也参加）：

```haskell
[m..n]      -- [m, m+1, …, n]        收尾含 n
[m..]       -- 无穷
[m,n..p]    -- 步长 n-m：[0,2..11] 得 [0,2,4,6,8,10]
['a'..'e']  -- "abcde"
```

**列表概括**（list comprehension）——用别的列表造列表的记法：

```haskell
[x*x | x <- [1..5]]                          -- [1,4,9,16,25]
[x*x | x <- [1..5], isPrime x]               -- [4,9,25]       守卫过滤
[(i,j) | i <- [1..5], even i, j <- [i..5]]   -- 后面的生成器可用前面的变量
```

一个完整的小案例（原书 4.3 的 `triads`，勾股三元组）能展示"定义→发现冗余→改进"的循环：

```haskell
triads n = [ (x,y,z) | x <- [1..n], y <- [1..n], z <- [1..n], x*x + y*y == z*z ]
-- triads 15 = [(3,4,5),(4,3,5),(5,12,13),…]：(4,3,5) 与 (3,4,5) 本质相同，还混进了倍数
```

改进：限制 `x < y` 且两者互素（`2x²` 不可能是平方数，所以 `x≠y` 时总有 `x<y` 的代表）：

```haskell
divisors x = [d | d <- [2 .. x-1], x `mod` d == 0]
coprime x y = disjoint (divisors x) (divisors y)     -- disjoint 见 9.10 练习

triads n = [ (x,y,z)
           | x <- [1 .. m], y <- [x+1 .. n], coprime x y
           , z <- [y+1 .. n], x*x + y*y == z*z ]
  where m = floor (fromIntegral n / sqrt 2)   -- x 必然 < n/√2：n 是 Int，除法前要 fromIntegral
```

`where` 里那一行是 3 章的类型转换课复盘：`n :: Int` 不能直接 `/`，且这里要
`fromIntegral`（不是 `fromInteger`）。**列表概括不是语法糖的另一套理论**——它被翻译成
`map`/`concat` 的组合（如 `[e | p <- xs, Q] = concat (map ok xs)`），守卫成了 `if`，
生成器成了 `concat . map`。知道翻译规则，概括与管线可以互相改写。

## 9.3 基本运算：手写 head/tail/last/null

用模式匹配定义四个"最小"列表函数（原书 4.4——`-Wall` 下它们各有讲究）：

```haskell
null :: [a] -> Bool
null []      = True
null (_:_)   = False              -- GHC 9.12+ 默认 -Wx-partial，别写 head/tail 版

head' (x:_)  = x                  -- 部分函数：[] 无定义（Prelude.head 同罪，警告在案）
tail' (_:xs) = xs

last' [x]     = x                 -- 单元素列表
last' (_:xs)  = last' xs          -- 至少两元素：丢首递归
```

三个教学点：`[]` 与 `(_:_)` 两个模式互斥且覆盖全部，**方程顺序无关**；`last'` 的两个
模式（单元素/多元素）**顺序有关**——`[x]` 与 `(x:y:ys)` 都匹配 `[1,2]`？不——`[x]`
只匹配单元素，但 Prelude 版 `last [x]` / `last (_:xs)` 中 `[x]` 也匹配多元素的前缀吗？
不匹配，可两个方程仍有重叠场景（单元素列表两个方程都匹配），所以**必须先写 `[x]`**。
以及一个原书反问：为什么不定义 `null = (== [])`？——那会把类型收紧成
`Eq a => [a] -> Bool`：判空根本不需要比较元素（9.10 练习 1 回来收这个尾）。

## 9.4 串联 `++`：定义、代价与结合律

```haskell
(++) :: [a] -> [a] -> [a]
[]       ++ ys = ys
(x:xs)   ++ ys = x : (xs ++ ys)
```

**定义在第一个参数上**。跟踪一次求值就懂了代价结构（原书 4.5 的推导，值得抄在手边）：

```
[1,2] ++ [3,4,5]
= (1 : (2 : [])) ++ (3 : (4 : (5 : [])))      -- 记法展开
= 1 : ((2 : []) ++ (3 : (4 : (5 : []))))      -- 第二方程剥一个 cons
= 1 : (2 : ([] ++ (3 : (4 : (5 : [])))))      -- 再剥一个
= 1 : (2 : (3 : (4 : (5 : []))))              -- 第一方程收尾
= [1,2,3,4,5]
```

左边几个 cons，就走几步——**`xs ++ ys` 的代价正比于 `xs` 的长度，与 `ys` 无关**。
推论：`((xs ++ ys) ++ zs) ++ ws …` 左嵌套是平方级灾难；`++` 满足结合律
（11 章证明），所以**多个拼接从右往左结合**最省。`concat` 把它包装成列表的列表的一次
性串联。

## 9.5 concat/map/filter：三原语与它们的定律

三原语的递归定义一行一个（原书 4.6）：

```haskell
concat []       = []
concat (xs:xss) = xs ++ concat xss

map f []        = []
map f (x:xs)    = f x : map f xs

filter p []     = []
filter p (x:xs) = if p x then x : filter p xs else filter p xs
-- 另一种定义：filter p = concat . map (test p)；test p x = if p x then [x] else []
```

`filter` 的第二种定义（"通过/拒绝"变成单元素/空列表再串联）不只是趣味——它是**等式推理
的杠杆**。先记两条 **map 的函子律**：

```haskell
map id             = id                -- 恒等
map (f . g)        = map f . map g     -- 复合——右到左读：两趟并作一趟
```

以及一族**自然律**（对 `head/tail/concat/reverse` 这类"只搬动结构、不看内容"的多态函数，
先 `map` 后结构操作 = 先结构操作后 `map`）：

```haskell
map f . tail    = tail . map f
map f . concat  = concat . map (map f)
map f . reverse = reverse . map f
concat . map concat = concat . concat
```

现在**推导一条新定律**（原书 4.6 的完整推导链——11 章证明方法论的预演）：

```
filter p . map f
  = {filter 的第二定义}        concat . map (test p) . map f
  = {map 函子律（反向）}        concat . map (test p . f)
  = {test p . f = map f . test (p . f)}
                                concat . map (map f . test (p . f))
  = {map 函子律}               concat . map (map f) . map (test (p . f))
  = {concat 自然律}            map f . concat . map (test (p . f))
  = {filter 的第二定义}        map f . filter (p . f)
```

结论：`filter p . map f = map f . filter (p . f)`。**定律不只是学术收藏——它们是改写
程序、发现更快定义的合法手续**（原书：这就是为什么函数式程序设计是最好的程序设计方法）。

## 9.6 zip 与 zipWith：两表并行

```haskell
zip :: [a] -> [b] -> [(a,b)]
zip (x:xs) (y:ys) = (x,y) : zip xs ys
zip _ _           = []               -- 任一到底即停（截到短的）

zipWith :: (a -> b -> c) -> [a] -> [b] -> [c]
zipWith f (x:xs) (y:ys) = f x y : zipWith f xs ys
zipWith _ _ _           = []
-- zip = zipWith (,)：二元组构造子 (,) 也是一个函数
```

两个教科书级用法（原书 4.7）：

```haskell
-- ① 非递减判定：相邻对全为 True
nondec xs = and (zipWith (<=) xs (drop 1 xs))     -- 不用 tail（-Wx-partial）

-- ② 首次出现位置：算出"所有位置"再取第一个——惰性让这没有代价
position x xs = firstOf [j | (j, y) <- zip [0..] xs, y == x] ++ [-1]]
  where firstOf = foldr (\h _ -> h) (-1)          -- 全函数 head
```

`position` 是"整表表达单点查询"的范式：表面算全部位置，实际只需求值第一个——
`zip [0..] xs` 的无穷下标流被有穷的 `xs` 截停。

## 9.7 高频词完整解：span、countRuns 与归并排序

01 章的 `commonWords` 管线当时借了库函数；现在（原书 4.8）逐环补上定义。管线回顾：

```haskell
commonWords n = concat . map showRun . take n
              . sortRuns . countRuns . sortWords . words . map toLower
```

**span**：把"最长满足 p 的前缀"与余下部分一分为二——`countRuns` 的钥匙：

```haskell
span :: (a -> Bool) -> [a] -> ([a], [a])
span p []       = ([], [])
span p (x:xs)
  | p x         = let (ys, zs) = span p xs in (x:ys, zs)
  | otherwise   = ([], x:xs)

countRuns :: [String] -> [(Int, String)]
countRuns []       = []
countRuns (w:ws)   = (1 + length us, w) : countRuns vs
  where (us, vs) = span (== w) ws        -- 连续重复段一次数完
```

**sortRuns 的小聪明**：`sort` 按 `(Int, Word)` 的字典序**递增**排，要按词频递减？
`sortRuns = reverse . sort`——这就是 01 章把次数放在**二元组第一分量**的原因。
（我们的 01 章版本用了 `sortOn (negate . fst)`，两条路等价。）

**归并排序**（分治）： halve 切半、递归排序、merge 合并：

```haskell
msort :: Ord a => [a] -> [a]
msort []  = []
msort [x] = [x]                       -- 这个方程不能省！
msort xs  = merge (msort ys) (msort zs)
  where n         = length xs `div` 2
        (ys, zs)  = (take n xs, drop n xs)

merge []     ys            = ys        -- 四个基本情况覆盖一空/两空
merge xs     []            = xs
merge (x:xs) (y:ys)
  | x <= y    = x : merge xs (y:ys)
  | otherwise = y : merge (x:xs) ys
```

两个必查项（原书的忠告）：**终止性**——`msort` 递归时两半长度严格变短；`merge` 每步
必有一个参数变短。**基本情况完整性**——省掉 `msort [x] = [x]` 会怎样？`1 div 2 = 0`
导致 `msort [x] = merge (msort []) (msort [x])`，右边又要求 `msort [x]`——**死循环**。
定义递归函数时，检查"所有必需的基本情况都在场"是和写递归体同等重要的工序。

顺带认识 **as 模式**（书里保守使用，我们同款态度）：`merge xs'@(x:xs) ys'@(y:ys)` 里的
`xs'` 绑定整个 `(x:xs)`，免得匹配拆开后再重构一遍——省一点分配，代价是等式读起来
隔了一层。

## 9.8 折叠：三原语之上的"万能迭代"

折叠把"对 `x:xs` 做点什么 + 对尾部递归"的模板固化成一个高阶函数：

```haskell
foldr  (+) 0 [1,2,3]   -- 1 + (2 + (3 + 0))   从右往左、惰性友好
foldl  (+) 0 [1,2,3]   -- ((0 + 1) + 2) + 3   从左往右、堆 thunk（12 章实测坑）
foldl' (+) 0 [1,2,3]   -- 严格折叠，每步强制——大列表唯一正确姿势（Data.List）
```

9.3–9.7 的几乎所有函数都能用 `foldr` 写（`map f = foldr (\x acc -> f x : acc) []`、
`filter p = foldr (\x acc -> if p x then x:acc else acc) []`……11 章的融合律全部围绕它）。

**foldr 的独门能力：短路**——它能把"决策函数"变成惰性的：

```haskell
andR = foldr (&&) True
andR [True, False, undefined]     -- False：undefined 根本没被碰！
```

`&&` 第二参不需求值时，右侧整段列表的折叠就停了。foldl 做不到（必须先走完全表才有结果）。

## 9.9 scanl 与无穷展开

```haskell
prefixSums = scanl (+) 0          -- [0, x1, x1+x2, …] 长度 +1
prefixSums [1,2,3]                -- [0,1,3,6]
scanl1 (+) [1,2,3]                -- [1,3,6]

naturals = iterate (+ 1) 0        -- 无穷：0,1,2,… 取多少算多少
fibs = unfoldr (\(a, b) -> Just (a, (b, a + b))) (0, 1)   -- fold 的对偶：种子反向展开
take 10 fibs                      -- [0,1,1,2,3,5,8,13,21,34]
```

`iterate f x = x : iterate f (f x)`；`unfoldr` 把"状态 → (输出, 新状态)"的函数展开成流。
配合 `take/drop/zip/zipWith`，"生成器"不需要特殊语法。13 章整章放大这个主题。

## 9.10 坑位清单

1. **foldl 大列表空间泄漏**：值对、内存炸——一律 `foldl'`（Data.List）（9.8，12 章实测内存对照）。
2. **`!!` 是部分函数**（越界崩）：O(n) 且不安全——随机访问用 Vector（生态）或 Map（14 章）。
3. **`++` 左嵌套 O(n²)**：循环里 `acc ++ [x]` 建大列表是经典性能坑——多个拼接右结合、
   或用 foldr 建表/DList（9.4，25 章算总账）。
4. **无穷列表要"有底"**：`foldr` 配短路函数才能收尾；`foldl` 在无穷表上永挂（9.8）。
5. **defaulting 与空表**：`sum []` 是 `0`（Num 的零元）——类型定了才有"零"是什么（8 章回响）。
6. **递归缺基本情况 = 死循环**：`msort` 少了 `[x]` 方程就在单元素上自旋——写完递归
   先查基例（9.7）。
7. **列表概括的守卫尽量前置**：`[e | x <- xs, p x, y <- ys]` 比 `[e | x <- xs, y <- ys, p x]`
   少生成元素——两者仅当 `ys` 有穷时结果相同（9.2，9.11 练习 3）。

## 9.11 练习（选自原书第 4 章习题）

**练习 9.1（等式判定）**：下列哪些对一切 `xs` 成立：`[] ++ xs == [xs]`？`xs : [] == [xs]`？
`[xs] ++ [] == [xs]`？`[] ++ [xs] == [[xs]]`？另外，为什么不能用 `null = (== [])` 定义判空？
（答案：后三个成立；`null = (== [])` 会把类型收紧为 `Eq a => [a] -> Bool`——判空不需要
比较元素。）

**练习 9.2（allPairs）**：`allPairs = [(x,y) | x <- [0..], y <- [0..]]` 能否列出所有自然
数对？（答案：不能——它产生 `[(0,0),(0,1),(0,2),…]`，永远困在 x=0。按"和递增"枚举：
`allPairs = [(x, d-x) | d <- [0..], x <- [0..d]]`。）

**练习 9.3（守卫位置与代价）**：`[e | x <- xs, p x, y <- ys]` 与
`[e | x <- xs, y <- ys, p x]` 何时结果相同、哪个更省？
（答案：`ys` 有穷时相同；前者对不满足 `p` 的 `x` 根本不展开 `ys`，更高效。）

**练习 9.4（disjoint）**：给 `disjoint :: Ord a => [a] -> [a] -> Bool`（两个**递增**列表
是否有公共元素）一个利用有序性的定义——双指针式前进，不搜索。
（骨架：两者当前头相等即 False 交；谁小谁前进；任一空即 True。`coprime` 就靠它。）

**练习 9.5（take/drop 定律族）**：给 `take/drop` 的递归定义，并判断：
`take n xs ++ drop n xs == xs`？`take m . take n == take (m `min` n)`？
`drop m . drop n == drop (m+n)`？再写一个只走一遍的 `splitAt`。
（答案：三条全成立；`splitAt` 骨架：`splitAt 0 xs = ([], xs)`；`splitAt n [] = ([], [])`；
`splitAt n (x:xs) = let (ys, zs) = splitAt (n-1) xs in (x:ys, zs)`。）

---

上一章：[08 类型类](08-typeclasses.md) ｜ 下一章：[10 数独解题器](10-sudoku.md) ｜ 返回：[README](../README.md)
