# 11 · 证明与归纳 ⭐

> 对应示例：`examples/11_proofs/`（Ch11.hs + main.hs + runtests.hs）。
> 本章对应原书第 6 章〈证明〉——等式推理、自然数/列表归纳、foldr 融合律、foldl、
> scanl 的程序计算、最大连续段和的三次方到线性推导，全部提炼。
> 示例把本章"计算出的等价定义"放到确定性样本上机器对账；手算推导的过程在本页。

## 11.1 等式逻辑：函数式的"为什么"

前面各章攒下的**定律**（`map (f . g) = map f . map g`、`++` 结合律……）名字有点僭越——
好像它们是从天上掉下来的。实际上每条定律都是**等式推理**能证明的定理。"定律"这个
词的真正含义是：**证一次，处处用**。等式逻辑在函数式程序设计里既简单又有力，因为它
能**引导你找到新的、更快的定义**——效率是 25 章的主题，本章先把推理工具配齐：
归纳证明，以及把"重复证明"打包成一条定理的高阶函数。

## 11.2 自然数归纳：证明的格式

证明 `P(n)` 对所有自然数成立，只需两步：

1. **基本情况**：`P(0)` 成立；
2. **归纳情况**：假设 `P(n)`（**归纳假设**），证 `P(n+1)`。

看原书的例子。幂函数：

```haskell
exp x Zero     = 1                    -- exp.1
exp x (Succ n) = x * exp x n          -- exp.2
```

（老书上的 `exp x 0` / `exp x (n+1)` 写法用了 *n*+1 模式——Haskell 2010 已禁止，我们用
03 章的 `Nat` 语言或直接对 `Int` 用 guard。证明格式不受影响。）

**定理**：对所有 `x m n`，`exp x (m+n) = exp x m * exp x n`。对 **m** 归纳
（对 n 也能证，但更绕——**选对归纳变量是证明的一半功力**，11.10 练习 1 再练）。
格式是两列各自化简、直到相同（理由标注在 `{}` 里）：

```
m = 0：                                            m = n+1：
exp x (0+n)     = exp x n        {0+n=n}          exp x ((m+1)+n)          = exp x (m+1) * exp x n    {算术}
                = 1 * exp x n    {exp.1}          exp x ((m+n)+1)          = (x*exp x m) * exp x n    {exp.2}
                = exp x n        {1*x=x}          exp x ((m+n)+1)          = x * (exp x m * exp x n)  {*结合}
                                                                    x * exp x (m+n)           = x * (exp x m * exp x n)  {归纳假设}
                                                                    两边再次合流。∎
```

两条脚注比证明本身更重要：

- 证明**用了**三条算术律（`(m+1)+n=(m+n)+1`、`1*x=x`、乘法结合律）。从零重建算术的话
  它们也得证；这里作为给定。**每个证明都站在别的证明肩膀上**——公理到定理的层级感。
- 最后一条律在 `Float` 上**实际是假的**：

```
ghci> (9.9e10 * 0.5e-10) * 0.1e-10 :: Float    -- 4.95e-11
ghci> 9.9e10 * (0.5e-10 * 0.1e-10) :: Float    -- 4.4999998e-11   ← 不相等！
```

**证明在数学上正确，不等于在 Haskell 上正确**——`(x*y)*z = x*(y*z)` 最终托付给了
`Num Float` 实例的实现。类型类的每个实例都是一份"合同履约"，定理成立与否要看实例
守不守约（这也是 08 章" lawful instance"一词的含义）。示例 main 打印这组反例实测值。

## 11.3 列表归纳：`++` 与 reverse

每个**有穷**列表是 `[]` 或 `x:xs`（xs 有穷）。所以证 `P(xs)`：证 `P([])`，再假设
`P(xs)` 证 `P(x:xs)`。

**定理**（`++` 结合律，对 xs 归纳；ys、zs 只需是任意列表）：

```
xs = []：                                         xs = x:xs：
([]++ys)++zs   = ys++zs      {++.1}               ((x:xs)++ys)++zs          = (x:xs)++(ys++zs)      {++.2}
               = ys++zs      {++.1}               (x:(xs++ys))++zs          = x:(xs++(ys++zs))      {++.2}
                                                                    x:((xs++ys)++zs)          = x:(xs++(ys++zs))  {归纳假设}
                                                                    两列合流。∎
```

**定理**（reverse 是对合）：`reverse (reverse xs) = xs`。基本情况显然。归纳情况第一步
就卡住：

```
reverse (reverse (x:xs))
  = reverse (reverse xs ++ [x])     {reverse.2}
  = ???                             -- 卡住：reverse 对 (++ [x]) 没有定律可用
```

**卡住是证明的常态**——这时发明一条**辅助命题**（引理）：

```
引理：reverse (ys ++ [x]) = x : reverse ys     （对 ys 归纳，两行即证——自己验）
```

回去续推：`reverse (reverse xs ++ [x]) = x : reverse (reverse xs) = x : xs`（引理 + 归纳
假设）。**先卡住、再发明引理、然后通关**——这个小循环就是数学研究的日常缩影。

## 11.4 三种列表，三种归纳

09 章说过列表分有穷/非完整/无穷三种。归纳法也随之分三种：

- **有穷列表**：`P([])` + `P(xs) ⇒ P(x:xs)`；
- **非完整列表**：`P(undefined)` + `P(xs) ⇒ P(x:xs)`。例：`xs ++ ys = xs` 对所有非完整
  xs 成立（`undefined ++ ys = undefined` 是 `++` 左参数模式匹配的语义）；
- **无穷列表**：把无穷列表看成非完整列表序列的**极限**（`[0..]` 是
  `undefined, 0:undefined, 0:1:undefined, …` 的极限）。若 P 是**链完全**的
  （chain complete：在各近似上都真 ⇒ 在极限上真），且对所有非完整列表成立，则对无穷
  列表成立。一切"纯等式"性质都链完全；**不等式和存在量词性质不一定**（
  `∃n. drop n xs = undefined` 对非完整列表真、对无穷列表假）。

一个警世故事：`reverse (reverse xs) = xs` 证过了 `P(undefined)` 这关，能推广到一切列表
吗？**不能**。对任何非完整列表 `xs`，`reverse (reverse xs) = undefined`——证明里用的
引理 `reverse (ys ++ [x]) = x : reverse ys` 恰好对非完整 ys 失效。结论：**函数等式
默认指"对所有列表（三种）成立"；只对有穷列表成立必须写明**。每条定律都有适用范围，
范围是定律的一部分。

## 11.5 foldr：把归纳打包复用

看四个函数定义和四条定律——它们**长得一模一样**：

```haskell
sum []       = 0            sum (x:xs)     = x + sum xs          sum (xs++ys)     = sum xs + sum ys
concat []    = []           concat (x:xs)  = x ++ concat xs      concat (xss++yss) = concat xss ++ concat yss
map f []     = []           map f (x:xs)   = f x : map f xs      map f (xs++ys)    = map f xs ++ map f ys
filter p []  = []           filter p (x:xs) = …                   filter p (xs++ys) = …
```

把共同模式提成**一个**高阶函数、**一条**定理，从此免于重复归纳——这就是 `foldr`：

```haskell
foldr :: (a -> b -> b) -> b -> [a] -> b
foldr f e []       = e                    -- foldr.1
foldr f e (x:xs)   = f x (foldr f e xs)   -- foldr.2
```

直觉记法：**`foldr (@) e xs` 就是把 `xs` 里的 `[]` 换成 `e`、每个 `(:)` 换成 `@`**：

```
foldr (@) e [x,y,z]  =  x @ (y @ (z @ e))       （右结合，函数名由此得）
foldr (:) [] xs      =  xs                      （什么都没换：恒等）
sum                  =  foldr (+) 0
concat               =  foldr (++) []
map f                =  foldr ((:) . f) []
```

**融合律**（fusion law）——foldr 最重要的性质：

```haskell
f . foldr g a = foldr h b
-- 成立三条件（对归纳证明的每一步"要什么"照单全收）：
--   ① f 严格（f undefined = undefined）
--   ② f a = b
--   ③ f (g x y) = h x (f y)        对所有 x y
```

原书称融合律为**"列表归纳的预制包"**：以后凡是"外层函数吃 foldr 结果"的形状，套
融合律即可，不必重写归纳。两个直接推论：

```haskell
foldr f a . map g = foldr (f . g) a          -- 融合 + map 的 foldr 表示
double . sum      = sum . map double = foldr ((+) . double) 0    -- 两趟并一趟
length . concat   = sum . map length = foldr addLen 0            -- addLen ys n = length ys + n
```

示例 Ch11 把这两条推论连同定律族放到确定性样本上全量对账（机器抽查、证明保全部）。

## 11.6 foldl：另一只手

`foldr (@) e [w,x,y,z] = w@(x@(y@(z@e)))`；有时顺手的是反方向：

```
foldl (@) e [w,x,y,z] = (((e @ w) @ x) @ y) @ z
```

```haskell
foldl :: (b -> a -> b) -> b -> [a] -> b
foldl f e []       = e
foldl f e (x:xs)   = foldl f (f e x) xs     -- 累加器在场：f 吃"左边"的积攒
```

一个对偶的小程序（原书 6.4 的数字解析）同时用到两只手：

```haskell
-- "1234.567" → (1234, 0.567)
ipart = foldl shiftL 0 . map toDigit     -- 整数部分：((((0×10+1)×10+2)×10+3)×10+4)——左折叠
  where shiftL n d = n * 10 + d
fpart = foldr shiftR 0 . map toDigit     -- 小数部分：(5+(6+(7+0)/10)/10)/10——右折叠
  where shiftR d x = (d + x) / 10
```

**reverse 的两个定义**在此会师：

```haskell
reverse = foldr snoc []            -- snoc x xs = xs ++ [x]：每个元素追加到尾——O(n²)
reverse = foldl (flip (:)) []      -- 每个元素压到头——线性！
```

第二个为什么线性：`foldl (flip (:)) [] [1,2,3]` 一步步是 `foldl (flip (:)) [1] [2,3]` →
`foldl (flip (:)) [2,1] [3]` → `[3,2,1]`——**每步 O(1)**。代价分析归 25 章，定律先记两条：

- `foldl f e xs = foldr (flip f) e (reverse xs)`（两者经 reverse 互表；**只对有穷列表**——
  xs 为 ⊥ 时两边虽都是 ⊥，但证明用到的辅助性质只对有穷表成立）；
- 若 `(@)` 与单位元 `e` **可结合**，则 `foldr (@) e xs = foldl (@) e xs`（有穷列表）。

**无穷列表上两者分道扬镳**（原书实测，`concat` 的例子）：

```
ghci> foldl (++) [[i] | i <- [1..]]     -- 长久沉默：左折叠要先看完全表
ghci> take 4 (foldr (++) [[i] | i <- [1..]])   -- [1,2,3,4]：右折叠出流
```

## 11.7 程序计算第一课：scanl 的线性化

`scanl f e` 把 `foldl f e` 施加到**每个前缀**：`scanl (+) 0 [1..10]` 得流动和
`[0,1,3,6,10,…,55]`。最直白的规格：

```haskell
scanl f e = map (foldl f e) . inits      -- inits "abc" = ["","a","ab","abc"]
-- 规格正确，但 f 被算 0+1+2+…+n = n(n+1)/2 次：二次方
```

**不知道要证什么的时候，先归纳着算，让目标自己浮现**（原书 6.5 的示范）：

```
[] 的情况：  map (foldl f e) (inits []) = map (foldl f e) [[]] = [foldl f e []] = [e]
x:xs 的情况： map (foldl f e) (inits (x:xs))
            = foldl f e [] : map (foldl f e . (x:)) (inits xs)
            = e : map (foldl f (f e x)) (inits xs)      ← 要求并证明了 foldl f e . (x:) = foldl f (f e x)
            = e : scanl f (f e x) xs
```

计算结果就是**线性定义**：

```haskell
scanl f e []       = [e]
scanl f e (x:xs)   = e : scanl f (f e x) xs     -- f 每元素只算一次
```

这就是**程序计算**（program calculation）：从一个说得清的规格出发，靠归纳与定律推出
等价的高效定义——**不需要另请一门逻辑语言**，用的就是 Haskell 自己的等式。
（Prelude 实际的 `scanl` 与我们的版本在 ⊥ 上有差：库版 `scanl f e undefined = e:undefined`，
我们的版给 `undefined`——库版让输出先吐 `e` 再管输入，惰性的又一寸收益。示例 Ch11 的
`propScanlSpecEqLinear` 在全部样本上断言两版等值。）

## 11.8 战例：最大连续段和，从 n³ 到 n

最大段和（maximum segment sum，Bentley《编程珠玑》的名题）：给整数序列，求所有
**连续段**之和的最大值。例：`[-1,2,-3,5,-2,1,3,-2,-2,-3,6]` 答案 7（段 `[5,-2,1,3]`）；
全负序列答案 0（空段）。规格一眼看懂：

```haskell
mss = maximum . map sum . segments
segments = concat . map inits . tails     -- 每个尾段的首段：所有连续段
```

直接算：n² 个段 × 每段求和 n 步 = **n³**。现在**只用定律改写**（原书 6.6 完整链）：

```
mss = maximum . map sum . concat . map inits . tails
    = {map/concat 自然律：map f . concat = concat . map (map f)}
      maximum . concat . map (map sum) . map inits . tails
    = {map 函子律}            maximum . concat . map (map sum . inits) . tails
    = {maximum . concat = maximum . map maximum（内层列表非空时）}
      maximum . map (maximum . map sum . inits) . tails          ← n³ 变 n²
    = {11.7 的 scanl 定律镜像：map sum . inits = scanl (+) 0}
      maximum . map (maximum . scanl (+) 0) . tails
    = {对内层用融合律：maximum = foldr1 max，需要 (+) 对 max 可分配
       —— x + (y `max` z) = (x+y) `max` (x+z)，成立}
      maximum . map (foldr step 0) . tails
        where step x y = 0 `max` (x + y)
    = {foldr 版 scanl 定律：map (foldr f e) . tails = scanr f e}
      maximum . scanr step 0                                        ← 线性！
```

最终解一行（示例 Ch11 的 `mssLinear`）：

```haskell
mss = maximum . scanr step 0  where step x y = 0 `max` (x + y)
```

`step` 的读法很有味道：从右往左扫，"以当前位置开头的最大段和"要么是 0（空段），
要么是当前元素接上后面那段。**三次方到线性，没有改一行"实现"——只是把同一个规格
用定律重写**。示例把 `mssSpec`（n³ 规格）与 `mssLinear`（线性解）在全部样本上对账
（书例 = 7、全负 = 0、空表 = 0 全部断言在 runtests）。

## 11.9 证明与测试的分工

机器抽查（示例做的事）与数学证明（本章做的事）不是竞争关系：

| | 测试/对账 | 证明 |
|---|---|---|
| 覆盖 | 样本点 | **全部**输入（含没造出来的） |
| 信心来源 | 没找到反例 | 反例不存在 |
| 成本 | 一行断言 | 一页推导 |
| 适用 | 实现细节、性能、Float 之类"实例级"行为 | 定律、融合、等价改写 |

28 章的性质测试把"抽查"自动化到随机输入；本章的推理链保证抽查永远找不到反例
（类型类实例守约的前提下——11.2 的 Float 反例就是"实例违约"的存证）。

## 11.10 坑位清单

1. **证明选对归纳变量**：`exp` 定理对 m 归纳两行、对 n 归纳绕远——动笔前先试方向（11.2）。
2. **`(n+1)` 模式已禁**：Haskell 2010 起 `f (n+1) = …` 不再合法——用 guard 或 `Succ`（11.2）。
3. **算术律止于实例**：`(x*y)*z = x*(y*z)` 在 `Float` 上实测失效——证明引用的每条定律
   都要落到 lawful 实例（11.2）。
4. **等式有适用范围**：`reverse . reverse = id` 只对有穷列表；推广前必须补非完整/无穷
   情况的检查（11.4）。
5. **foldl 与无穷列表势不两立**：左折叠要先看完全表——`foldl (++)` 无穷列表永挂，
   `foldr (++)` 却能出流（11.6）。
6. **融合律三条件缺一不可**：忘了 `f 严格`（条件①）会在 ⊥ 上翻车（11.5）。

## 11.11 练习（选自原书第 6 章习题）

**练习 11.1（归纳变量）**：`mult Zero y = Zero`；`mult (Succ x) y = mult x y + y`。
证 `mult (x+y) z = mult x z + mult y z`——只能用 `x+0=x` 与加法结合律。对 x、y、z 哪个
归纳最好？（答案：对 **y**——两个基本方程都作用在第一个参数上，选它才两行收工。）

**练习 11.2（reverse 与 ++）**：证 `reverse (xs ++ ys) = reverse ys ++ reverse xs`
（可假设 `++` 结合律）。注意两边方向都翻了——这是"翻转保持结构、倒置顺序"的代数体现。

**练习 11.3（foldl/foldr 互表）**：证 `foldl f e xs = foldr (flip f) e (reverse xs)`
（对 xs 归纳）。再证：若 `(@)` 满足 `(x<>y)@z = x<>(y@z)` 且 `e@x = x<>e`，则
`foldl (@) e xs = foldr (<>) e xs`。

**练习 11.4（一个数学彩蛋）**：`sum (scanl (/) 1 [1..])` 的值是什么？
（答案：e（自然对数的底）——它是 e 的连分数展开 `1 + 1/(1 + 1/(2 + 1/(3 + …)))`。
取 20 项在 GHCi 里对着 `exp 1` 验。惰性求值让"无穷和的有限近似"随取随算。）

---

上一章：[10 数独解题器](10-sudoku.md) ｜ 下一章：[12 惰性求值](12-laziness.md) ｜ 返回：[README](../README.md)
