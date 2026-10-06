# 10 · 数独解题器 ⭐

> 对应示例：`examples/10_sudoku/`（Ch10.hs + main.hs + runtests.hs）。
> 本章对应原书第 5 章〈一个简单的数独求解器〉——全书第一个完整的"计算出程序"案例：
> 从一个慢得离谱但**正确**的定义出发，靠定律一步步算出快 60 个数量级的版本。

## 10.1 先写规格，再谈速度

数独规则一句话：9×9 棋盘，每行、每列、每个 3×3 宫内数字 1–9 各出现一次。给定格子的
数字不能动，问如何填满空格。

原书的方法论宣言在本章开宗明义：**函数式程序设计总是可以从一个清晰、简单、尽管可能
效率极低的定义开始，然后用定律修改计算，满足时空要求**。慢而对的程序是快而对的前身；
反过来（快而说不清对不对）不是。所以第一版定义就是题面直译：

```haskell
solve :: Grid -> [Grid]
solve1 = filter valid . completions        -- 生成所有"填满的棋盘"，留下合法的
  where completions = expand . choices     -- 每个空格放满候选 → 展开成棋盘列表
```

## 10.2 建模：矩阵是行的列表

```haskell
type Digit  = Char                    -- '1'..'9'；Char 是 Enum，['1'..'9'] 直接可用
type Row a  = [a]
type Matrix a = [Row a]               -- 矩阵 = 行的列表 = 列表的列表
type Grid   = Matrix Digit            -- 棋盘；'.' 表示空格
```

不设下标、不开二维数组——**矩阵本身就是值**，操作矩阵的函数吃整个矩阵、吐整个矩阵。
原书给这种风格起了名字：**全麦面粉程序设计**（wholemeal programming）——吃整粒谷物，
避免"过度下标"这种营养不良疾病。判断合法只需三个"视图"函数：

```haskell
rows :: Matrix a -> Matrix a
rows = id                             -- 矩阵本来就按行存：恒等

cols :: Matrix a -> Matrix a          -- 转置（书版手写）
cols [xs]       = [[x] | x <- xs]
cols (xs : xss) = zipWith (:) xs (cols xss)

group   :: [a] -> [[a]]               -- 3 个一组
group []        = []
group xs        = take 3 xs : group (drop 3 xs)

ungroup :: [[a]] -> [a]
ungroup = concat

boxs :: Matrix a -> Matrix a          -- 9 个 3×3 宫按行摊开
boxs = map ungroup . ungroup . map cols . group . map group
```

`boxs` 一行复合值得逐层读：`map group` 把每行切成 3 段；`group` 把 9 行切成 3 组
（每组 3 行，正是一个横条带的宫）；`map cols` 转置每个横条带——**转置后每行恰好是一
个宫的内容**；`ungroup` 摊平组，`map ungroup` 摊平行内分组。合法棋盘的定义于是对称得
像一句诗：

```haskell
valid g = all nodups (rows g) && all nodups (cols g) && all nodups (boxs g)

nodups []       = True
nodups (x : xs) = not (elem x xs) && nodups xs
```

## 10.3 定律先行：三个对合

视图函数不是"能跑就行"的代码，它们携带**定律**（原书 5.2）：

```haskell
rows . rows = id
cols . cols = id        -- 直观显然，按定义证明反而最绕（书里明说）
boxs . boxs = id        -- 等式推理可干净证出（用 group . ungroup = id 与 map 函子律）
```

`f . f = id` 称为**对合**（involution）。另外三条"`expand` 与视图可交换"的定律
（`map rows . expand = expand . rows` 等，对 cols/boxs 同款）和两条 `cp`（笛卡尔积）
的定律，本章推导剪枝合法性时全用上。**定律比测试值钱**：测试抽查一百万个矩阵，
定律覆盖全部矩阵——11 章教怎么证，这里先收下这些"合法手续"。

注意 `boxs` 的对合律**只在 n²×n² 形状上成立**（9×9 配 group 3、4×4 配 group 2）——
本例 runtests 第一版拿 3×3 矩阵断言 `boxs . boxs = id`，实测翻车：3×3 不属于这个
家族，`boxs` 把它摊成一行后再也回不去。形状前提是定律的一部分。

## 10.4 第一版：全展开与它的天文数字

`choices` 给每个格子放候选（空格 9 个、已定格 1 个）：

```haskell
choices = map (map choice)            -- 矩阵是两层列表：map 两次
  where choice d = if d == '.' then ['1'..'9'] else [d]

expand = cp . map cp                  -- 行内笛卡尔积，行间再笛卡尔积
  where
    cp []       = [[]]                -- cp [[1,2,3],[2],[1,3]] → 6 个长度 3 的列表
    cp (xs:xss) = [x : ys | x <- xs, ys <- cp xss]

solve1 = filter valid . expand . choices
```

`cp`（cartesian product）就是"每列选一个元素的所有选法"——展开候选矩阵 = 枚举所有
可填棋盘。定义正确，然后立刻**判它死刑**：本例题 81 格中 61 格为空，`solve1` 要过滤

```
9^61 = 16173092699229880893718618465586445357583280647840659957609
```

个棋盘。宇宙热寂都算不完。**规格正确 + 度量荒谬 = 改进的靶子已明确**。

## 10.5 剪枝：从"事后过滤"到"事前剔除"

洞察：`filter valid` 在**展开后**丢掉非法棋盘，太晚了——非法性在候选矩阵上就能看出来。
某行已定格 6，同行其他格的候选里就不该有 6。定义一行级别的剪枝：

```haskell
pruneRow :: Row [Digit] -> Row [Digit]
pruneRow row = map (remove fixed) row
  where fixed  = [d | [d] <- row]     -- 模式 [d] 只认单元素列表：本行已定格的数字
        remove ds xs@[_] = xs         -- 已定格：不动
        remove ds xs     = filter (`notElem` ds) xs
```

书上的实测例子（runtests 里有同款断言）：

```
pruneRow [['6'], ['1','2'], ['3'], ['1','3','4'], ['5','6']]
       = [['6'], ['1','2'], ['3'], ['1','4'], ['5']]     -- 6/3 被剔，末格 5 落定
```

行列宫三个方向用**同一条定律**装配起来（这是本章计算的高潮，浓缩版）：

```haskell
pruneBy f = map pruneRow . f . map pruneRow . f
prune     = pruneBy boxs . pruneBy cols . pruneBy rows
```

合法性靠核心定理（原书 5.3 用一整页等式推理证出，用的正是 10.3 的定律族）：

```haskell
filter valid . expand = filter valid . expand . prune
```

读法：**先剪再展开，好棋盘一个不丢**（丢的全是本来就要被过滤的）。于是第二版：

```haskell
solve2 = filter valid . expand . many prune . choices
  where many f x = if x == y then x else many f y where y = f x   -- 剪到不动点
```

最简单的谜题（只需传播约束、无需试探）这一版就解了。

## 10.6 单格扩展：搜索登场

`many prune` 之后候选矩阵只剩三类：**完全**（全定格，抽取即解）、**含空格**（候选被剪空，
死路）、**其余**（还有 ≥2 候选的格子，必须试探）。第三类不该全展开——只展开**一个**格子：

```haskell
complete = all (all single)          -- single [_] = True；single _ = False
safe m   = all ok (rows m) && all ok (cols m) && all ok (boxs m)
  where ok row = nodups [x | [x] <- row]    -- 已定格的数字无冲突

extract = map (map firstOf)          -- complete 前提下每格单元素；firstOf 是全函数版 head
  where firstOf [x] = x
        firstOf _    = '.'

expand1 rowsm = [rows1 ++ [row1 ++ [c] : row2] ++ rows2 | c <- cs]
  where
    (rows1, row : rows2) = break (any smallest) rowsm    -- 定位含最少候选格的行
    (row1, cs : row2)    = break smallest row            -- 定位该格
    smallest cs          = length cs == n
    n                    = minimum (counts rowsm)
    counts               = filter (/= 1) . map length . concat
```

两个设计决策值得咀嚼：

1. **选"候选最少"的格，不是"第一个"格**。候选最少的格分叉最少；且若有格子候选已被剪空
   （n = 0），第一时间发现死路——而"第一个非单格"可能藏在矩阵深处，让你白跑很远。
2. `minimum (counts …)` 里 `counts` 过滤掉 1（定格格）：若矩阵已完全，`counts` 为空，
   `minimum [] = ⊥`——所以 `expand1` **只在非完全矩阵上调用**，这个前提写进了
   `search` 的结构里而不是类型里（部分函数的契约管理，20 章给系统方案）。

最终求解器三行定式（书 5.4）：

```haskell
solve  = search . prune . choices

search cm
  | not (safe pm) = []                     -- 剪后不安全：死路，立即返回
  | complete pm   = [extract pm]           -- 全定格：这就是解
  | otherwise     = concat (map search (expand1 pm))   -- 展开一格，逐支递归
  where pm = prune cm
```

## 10.7 实测：61 个数量级

示例（`examples/10_sudoku/`）跑经典例题：

```
53..7....        534678912
6..195...        672195348
.98....6.        198342567
8...6...3   →    859761423
4..8.3..1        426853791
7...2...6        713924856
.6....28.        961537284
...419..5        287419635
....8..79        345286179
```

解的个数 1（唯一解），本机 CPU 计时 **0.0 毫秒级**——对照第一版的 9^61 ≈ 1.6×10^58
个棋盘：**定律改写带来的 60 个数量级加速**，一行硬件都没换。runtests 断言：三视图
对合律（9×9）、cp 书例、pruneRow 两个书例、解有效、唯一、尊重已填数字、首行精确匹配。

回看全程的节奏：**规格 → 天文数字的荒谬 → 一条定理（剪枝不丢解）→ 一条策略（最少候选格）
→ 毫秒级**。没有一行命令式代码，没有可变状态——每个版本都是纯函数，每次加速都有
等式推理背书。这就是"用定律计算程序"的完整一课。

## 10.8 坑位清单

1. **`boxs . boxs = id` 有形状前提**：只在 n²×n² 矩阵上成立；3×3 矩阵实测不回归
   （runtests 首版踩过，已改 9×9 断言）（10.3）。
2. **`Digit = Char` 的字面量要引号**：`[[6], [1,2]]` 直接 `No instance for Num Digit`
   ——写 `[['6'], ['1','2']]`（本例实测）（10.4）。
3. **`minimum []` 是 ⊥**：`expand1` 的 `n` 依赖"非完全矩阵"前提——结构保证调用时机，
   或用 `NonEmpty`/Maybe 把契约写进类型（10.6）。
4. **`extract` 别写 `map (map head)`**：GHC 9.12+ 默认 `-Wx-partial` 警告 `head`；
   模式匹配版 `firstOf [x] = x` 同义且全函数（10.6）。
5. **`expand` 的类型比看起来宽**：`cp . map cp` 对任意 `[[[a]]]` 都能跑——空候选行让
   结果为空列表，这正是"死路"的表示，不是 bug（10.4）。

## 10.9 练习（选自原书第 5 章习题）

**练习 10.1（矩阵运算的提升）**：`zipWith (+)` 把两行相加——什么函数把两个矩阵相加？
（提示：`zipWith (zipWith (+))`。给整数矩阵每个元素 +1、求全部元素之和也一并写掉：
`map (map (+1))` 与 `sum . map sum`。）

**练习 10.2（空矩阵的维数）**：`cols [[]]`（1 行 0 列）的转置是什么？`cols []` 呢？
（提示：`[[]]` 转置得 `[]`——0 行；`[]` 转置按书版定义没有匹配方程，`Data.List.transpose`
给 `[]`。维数 0×n 与 n×0 的不对称正是空值的老麻烦。）

**练习 10.3（定律判定）**：`any p = not . all (not . p)` 与 `any null = null . cp`
哪些成立？（答案：第一条成立——德摩根律的列表版；第二条**不成立**，反例是 `cp [[]]`：
左 边 `any null []` 得 `False`，右边 `null []` 得 `True`。左边问"积里有没有空列表"，
右边问"积本身是否为空"——完全不同的两个问题。）

---

上一章：[09 列表与折叠](09-lists.md) ｜ 下一章：[11 证明与归纳](11-proofs.md) ｜ 返回：[README](../README.md)
