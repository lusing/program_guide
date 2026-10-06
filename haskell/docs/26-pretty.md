# 26 · 优美打印 ⭐

> 对应示例：`examples/26_pretty/`（Ch26.hs + main.hs + runtests.hs）。
> 本章对应原书第 8 章〈精美打印〉——一个**小函数库的完整诞生史**：设计运算、写定律、
> 浅嵌入试水、深嵌入重写、指数版淘汰、线性版收官。21 章的 `showsPrec` 是它的序曲；
> 11 章的等式推理在定律清单里全面回场。

## 26.1 问题：换行该放在哪

把 `if p then e1 else e2` 显示成多行，哪些格式可接受？

```
if p then e1 else e2          ✓ 一行
if p then e1                  ✓ 两行        if p then        ✗ 拆断 then
else e2                                     e1 else e2
if p                          ✓ 三行
then e1
else e2
```

两个问题：**如何描述可接受的格式**（拒绝不可接受的）？**如何在其中挑选**？
第二个问题的答案先定：给定行宽 w，选"最好"的格式。第一个问题的答案是本章的主角——
一套**布局描述语言**：用户不写全部格式（那是指数级的手工活），而是用几个组合子
**生成**格式集合。库的核心类型叫**文档**（Doc），一个格式（Layout）就是一个串。

## 26.2 八个运算与二十四条定律（书8.2）

```haskell
pretty   :: Int -> Doc -> Layout   -- 行宽 + 文档 → 最佳格式（本章的终极目标）
layouts  :: Doc -> [Layout]        -- 全部格式：用户调试格式的诊断工具
(<>)     :: Doc -> Doc -> Doc      -- 串联（结合律）
nil      :: Doc                    -- 空文档（<> 的单位元）
text     :: String -> Doc          -- 无换行的串 → 文档
line     :: Doc                    -- 一个换行
nest     :: Int -> Doc -> Doc      -- 每个换行后缩进 i 格
group    :: Doc -> Doc             -- 追加"全压平"的额外格式（一行版）
flatten  :: Doc -> Doc             -- 内部工具：换行及缩进 → 一个空格
```

书 8.2 的做法值得整个抄下来：**先写定律，再写实现**。二十四条定律摘选（全部可在
runtests 抽样验证）：

```haskell
(x <> y) <> z  = x <> (y <> z)            -- 结合
text (s ++ t)  = text s <> text t          -- text 是 (++) 到 (<>) 的同态
nest i (x<>y)  = nest i x <> nest i y      -- nest 分配
nest i (nest j x) = nest (i+j) x           -- nest 是加法到复合的同态
nest i (text s)    = text s                -- 缩进只作用于换行之后
layouts (group x)  = layouts (flatten x) ++ layouts x    -- 扁平版排最前
```

定律不只是"成立的性质"——它们**指导实现**（实现错了定律就红）、**保证合理性**
（工具箱自然、没漏关键件）、**决定含义**（`nest` 为什么不在文档开头缩进？定律
`nest i (text s) = text s` 说了算）。

## 26.3 浅嵌入：文档 = 格式列表（书8.3）

第一种实现大胆而直接——**文档就是它的全部格式**：

```haskell
type Doc = [Layout]            -- 浅嵌入（shallow embedding）

nil    = [""];  line = ["\n"];  text s = [s]
x <> y = [xs ++ ys | xs <- x, ys <- y]           -- 提升的串联
nest i = map (nestl i)         -- nestl：每个 '\n' 后补 i 格
group x = flatten x ++ x       -- 扁平格式排最前
```

八运算十行搞定，**24 条定律几乎全部成立**——除了 `flatten (x<>y) = flatten x <> flatten y`
（`x = line, y = text "hello"` 反例：非嵌串换行后的空格删不干净）。书的选择是坦率：
接受这个不完美，继续前进（工程判断，不是数学洁癖）。

**pretty 的指数版**（书 8.5）：枚举全部格式，按"第一行贪心"挑选——

```haskell
prettyNaive w = fst (foldr1 choose (map augment (layouts d)))
  -- better：第一行装得下越长越好；都不装得下越短越好；相等比下一行
```

正确，但**每处 group 都翻倍**：22 词的段落 2²¹ ≈ 200 万格式——书里 GHCi 实测
**31.32 秒、17.6GB 分配**，再长直接"内存耗尽"。不可接受。

## 26.4 深嵌入：文档 = 抽象语法树（书8.6）

第二种实现保留结构：**每个运算一个构造子**。

```haskell
data Doc = Nil | Line | Text String
         | Nest Int Doc | Group Doc
         | Doc :<>: Doc          -- 中缀构造子必须冒号开头
```

这引出一段重要的类型论（书 8.6）：data 声明给出的是**具体类型**（值 = 项，可模式
匹配）；而库想给用户的是**抽象数据类型**（只给运算名，构造子藏进模块）。问题：
`Nest i (Nest j x)` 与 `Nest (i+j) x` 是**不同的项**——定律在项层面不成立！解法：
**定律"观察上"成立**——`layouts` 是唯一观察口，两个项只要格式集合相同就是"同一个
文档"。（这正是 20 章"封装"与 16 章"抽象"的接力。）

`layouts` 的树版定义**就是** 26.2 的定律逐条翻译成构造子方程——定律即规范、规范即
实现，三位一体。

## 26.5 两个二次方的坑与线性化（书8.6 的精华）

树版 `layouts` 结构清晰但有两个低效源，书里各给一个最小罪犯：

```haskell
egotist n = if n == 0 then nil else egotist (n-1) <> text "me"  -- 左结合串联：Θ(n²)
egoist  n = if n == 0 then nil else nest 1 (text "me" <> egoist (n-1))  -- 嵌套穿全文：Θ(n²)
```

对症下药——**延迟串联**（成分列表待拼接）+ **延迟嵌套**（缩进量记账不穿透）。
文档表示改为 `(缩进, 子文档)` 的任务列表，`lay` 沿列表走一遍（示例 Ch26 的
`layoutsLinear`）：

```haskell
lay ((i, x :<>: y) : ids) = lay ((i, x) : (i, y) : ids)   -- 串联拆账，不急着拼
lay ((i, Nest j x) : ids) = lay ((i + j, x) : ids)        -- 嵌套只加账，不穿树
lay ((i, Line) : ids)     = ['\n' : replicate i ' ' ++ l | l <- lay ids]
```

runtests 断言：参考版与线性版在条件/树/段落三种文档上**格式集合逐一相同**——
又是"两版对账"的验证范式。

## 26.6 线性 pretty：best 与 fits（书8.6 收官）

`pretty` 用**同一个模板**，把"枚举后挑选"变成"边走边挑"：

```haskell
pretty w x = best w [(0, x)]
  where
    best r ((i, Text s) : ids) = s ++ best (r - length s) ids   -- r：本行剩余宽度
    best r ((i, Line) : ids)   = '\n' : replicate i ' ' ++ best (w - i) ids
    best r ((i, Group x) : ids) = better r (best r ((i, flatten x) : ids))   -- 扁平版
                                          (best r ((i, x) : ids))            -- 展开版
    better r lx ly = if fits r lx then lx else ly
    fits r _ | r < 0 = False        -- 只看第一行、够判断就停（惰性在这里是正确性的一部分！）
    fits _ [] = True
    fits r (c:cs) | c == '\n' = True | otherwise = fits (r-1) cs
```

关键洞察：**贪心安全**。因为格式形状按字典序递减（group 把扁平版排最前），
第一行的取舍**局部最优 = 全局最优**——每个 group 独立决策、永不反悔，不必回溯。
`fits` 的惰性不是优化而是**节俭义务**：多看一个字符都可能把线性打回指数。

实测（示例 main，书里的原数据）：

```
This is a fairly short
paragraph with just twenty-two
words. The problem is that
pretty-printing it takes time,
in fact 31.32 seconds.
```

同一文档：指数版 31.32s，线性版 **0.0 毫秒**——十二个数量级，全部来自表示的改变。
runtests 断言：两版 pretty 在条件/树/段落 × 窄/宽各档**输出逐字节相同**（贪心 = 全局
最优的实证），段落每行不超宽。

## 26.7 三个示例文档（书8.4）

```haskell
cexpr (Cond p x y) = text ("if " ++ p)
    <=> group (line <=> text "then " <=> nest 5 (cexpr x))
    <=> group (line <=> text "else " <=> nest 5 (cexpr y))

gtree (GNode x ts) = text ("Node " ++ show x) <=> group (nest 2 (line <=> bracket ts))

para = cvt . map text . words                       -- 词间每处 group (line <> 词)
  where cvt (x:xs) = x <=> foldr (<=>) nil [group (line <=> t) | t <- xs]
```

三族文档各有教益：**cexpr** 展示嵌套缩进（内层 if 比外层再进 5 格）；**gtree**
展示"有子树才 group、无子树单行收口"的分支（bracket 本教程版按书的显示输出重构）；
**para** 是 2ⁿ 格式的重灾区——只有线性版活得下来。示例 main 用 30/66、26/70 两组
行宽对比打印，肉眼看 group 的取舍。

## 26.8 坑位清单

1. **`better` 必须用"当前剩余宽度 r"判 fits**：写成全局宽度 w（或拿候选第一行长度
   反推宽度）会让深层 group 误判"装得下"——本例实测翻车：39 字符的行突破 30 宽上限
   （26.6，调试现场）。
2. **`fits` 的惰性是义务**：提前多求值一个字符，最坏情形整体退化（26.6）。
3. **`then`/`else` 后面要留空格**：`group (line <> text "then" <> …)` 扁平化后
   "thenif" 粘连——词间空格属于 text，不属于 line（26.7，实测）。
4. **`flatten` 会在行尾留尾随空格**：`flatten line = Text " "`——浅嵌入定律
   `flatten (x<>y) = flatten x <> flatten y` 失效的根源（26.3）。
5. **中缀构造子必须冒号开头**（`:<>:`）——这是 Haskell 的记号法，不是风格建议（26.4）。
6. **左结合串联与层层 nest 都是二次方**：库实现要延迟（lay 的记账法），用户写文档
   也别 `foldl (<>)`（26.5）。

## 26.9 练习（选自原书第 8 章习题）

**练习 26.1（挑剔的用户）**：只要三种格式 `ABC / AB⏎C / A⏎BC`（B 后或 A 后换行，
不许多行）——用库的八个运算能表达吗？（提示：group 只会追加"全扁平"一种；
`group (a <> group (line <> c))` 给出什么集合？）

**练习 26.2（格式互异）**：证明 layouts 列表中的格式两两不同。（提示：形状字典序
严格递减。）

**练习 26.3（浅嵌入的失效定律）**：构造更多让 `flatten (x<>y) ≠ flatten x <> flatten y`
成立的 x、y；说明为什么深嵌入版这条定律"观察上"成立。

**练习 26.4（pretty 的运行时间）**：书 8.6 断言 pretty 对文档大小线性、但可能依赖
行宽 w——从 `fits` 最多看 w 个字符出发论证。（习题 L 的复刻。）

---

上一章：[25 性能](25-performance.md) ｜ 下一章：[27 Stack 工程](27-stack.md) ｜ 返回：[README](../README.md)
