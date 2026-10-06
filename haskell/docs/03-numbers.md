# 03 · 数值与类型类

> 对应示例：`examples/03_numbers/`。
> 本章对应原书第 3 章〈数〉：3.6 节"从零构造 floor"与 3.7 节 Nat 归纳数是原书 3.3/3.4 的
> 完整提炼；类族层次按书 3.1/3.2 重画。

## 3.1 数值类型一览

| 类型 | 说明 | 坑 |
|---|---|---|
| `Int` | 定长整数（64 位） | `21!` 就溢出变负（实测） |
| `Integer` | 任意精度整数 | 慢一点但永不溢出，默认整数字面量就是它 |
| `Word` | 无符号整数 | 与 C 互操作常见（30 章） |
| `Double` / `Float` | 浮点 | `0.1 + 0.2 == 0.30000000000000004`（IEEE-754，与所有语言一致） |
| `Rational` | 任意精度有理数 | `1 % 3 + 1 % 6 == 1 % 2`，零误差 |

```haskell
maxBound :: Int          -- 9223372036854775807
factInt 20               -- 2432902008176640000（尚在界内）
factInt 21               -- -4249290049419214848（溢出！）
factInteger 21           -- 51090942171709440000（无界）
```

## 3.2 Num 类族：数值的公共合同

数值运算不绑定具体类型，而是挂在**类型类**上（08 章细讲类型类机制）。`Num` 的声明
（原书 3.1，有删节）长这样：

```haskell
class (Eq a, Show a) => Num a where
    (+), (-), (*) :: a -> a -> a
    negate         :: a -> a          -- 取反；前缀 -x 就是 negate x（唯一的前缀运算符）
    abs, signum    :: a -> a          -- 绝对值；符号（-1/0/1，按书中的直观定义）
    fromInteger    :: Integer -> a    -- 转换函数：字面量的入口
```

读法：**每个 `Num` 实例都是 `Eq` 和 `Show` 的实例**（超类族约束）——所以任意两个数能比相等、
任何数都能打印。四则里没除法：复数不能比大小、整数除法语义特殊，除法被下放到子类族。

`fromInteger` 是理解 Haskell 算术的钥匙：字面量 `42` 其实是 `fromInteger 42` 在类型参数为
`Integer` 的值上的应用，所以 `42 :: Num a => a`——它**是什么类型取决于上下文**（3.5 节）。
同理 `3.149 :: Fractional a => a`。这解释了 `42 + 3.149` 为何合法：两个类型都在 `Num` 里，
结果推断为更窄的 `Fractional a => a`。

## 3.3 类族层次：Real 与 Fractional 两支

`Num` 之下按"能做什么"分两支（原书 3.2）：

```
Num (+) (-) (*) negate abs signum fromInteger
├── Real (toRational)                    ── 能变成有理数：可比较大小
│     └── Integral (divMod, toInteger)   ── 整型：Int/Integer/Word
└── Fractional ((/), fromRational)       ── 能除：Double/Float/Rational
      ├── Floating (sqrt, sin, exp, …)   ── 数学函数
      └── (Real + Fractional →) RealFrac (floor, ceiling, round, properFraction)
```

两条转换通道把层次串起来：

```haskell
toRational pi        -- 884279719003555 % 281474976710656（π 的最近似有理数——不如 22%7 好记但精确得多）
fromIntegral :: (Integral a, Num b) => a -> b
fromIntegral = fromInteger . toInteger     -- 两步桥：先升到 Integer，再落到目标类型
```

推论：

- `1 / 2` 合法（默认 Double → 0.5）；`1 \`div\` 2` 才是整数除（得 0）。
- `length xs / 2` **编译不过**——`length` 给 `Int`，`/` 要 `Fractional`。必须
  `fromIntegral (length xs) / 2`。**跨类型比较同理**：`Integer` 与 `Float` 比大小没有
  直接的 `<=`（它要求两边同型），要先 `fromInteger`——3.6 节马上用到。

## 3.4 整除家族四兄弟

`div/mod` 向下取整（余数符号随**除数**）；`quot/rem` 向零取整（余数符号随**被除数**，C 系语言语义）：

```haskell
divMod  (-7) 2    -- (-4, 1)     向下：-7 = 2×(-4) + 1
quotRem (-7) 2    -- (-3, -1)    向零：-7 = 2×(-3) + (-1)
```

正数时两家一致——坑只在负数。教学建议：数学语义用 `div/mod`，FFI 对接 C 用 `quot/rem`。

`divMod` 一次返回商和余数，比 `div`+`mod` 各调一次省一半工作。原书用 01 章的
`digits2 n = (n \`div\` 10, n \`mod\` 10)` 演示这个改写——最简形式是部分运算：
`digits2 = divMod 10` 的 section 写法 ``(divMod 10)``……准确说 ``(`divMod` 10)``。

## 3.5 字面量多态与 defaulting

```haskell
5     :: Num a => a          -- 用在哪类上下文就是哪个类型
5.0   :: Fractional a => a
```

无约束时触发 defaulting 规则：整数默认 `Integer`、小数默认 `Double`（GHCi 里 `:set -XNoMonomorphismRestriction`
一瞥即可，正文不展开）：

```haskell
doubleIt :: Num a => a -> a
doubleIt x = x + x
doubleIt (21 :: Int)         -- 42
doubleIt (2.5 :: Double)     -- 5.0
doubleIt (10^25 :: Integer)  -- 大数照算
```

## 3.6 从零构造 floor：until 与二分查找

Prelude 有 `floor`，但原书 3.3 "自己造一个"的过程值三节课。目标类型：

```haskell
floor :: Float -> Integer    -- ⌊x⌋：满足 m ≤ x 的最大整数 m
```

**先看一个反例**（原书的 CleverDick 同学）：把数 `show` 成字符串、截到小数点前、`read`
回整数——`read . takeWhile (/= '.') . show`。它有两处致命伤（3.11 练习让你补刀）：
`floor (-3.1)` 给 -3（正确答案 -4）；`12345678.0 :: Float` 显示为 `1.2345678e7`（科学
计数法），截完只剩 1。

**正路需要一个循环**。Prelude 的 `until` 正是"纯函数式的最小循环"：

```haskell
until :: (a -> Bool) -> (a -> a) -> a -> a
until p f x = if p x then x else until p f (f x)
-- until (>100) (*7) 1  →  343：从 1 起反复 ×7，直到越过 100
```

**线性版**（负数情形：沿 -1, -2, … 找第一个 ≤x 的整数）：

```haskell
m `leq` x = fromInteger m <= x      -- Integer 与 Float 比较：必须转换（<= 两边要同型）

floorNeg x = until (`leq` x) (subtract 1) (-1)
```

三行各藏一个知识点：

1. `subtract 1`——**`(-1)` 不是"减 1 的 section"，它是负数字面量 -1**。想要"减 1 的部分
   应用"只有 `subtract 1`（Prelude 定义 `subtract x y = y - x`）。
2. `` (`leq` x) ``——反引号 section 的参数序：`` (`leq` x) m = m `leq` x``（m 是待求的
   循环变量），而 `(x `lt`) n = x `lt` n`。两个方向长得像，是易错点。
3. 转换方向要选对：把 `Integer` 转到 `Float`（`fromInteger`）而不是反过来——`Float` 的
   精度装不下大 `Integer`。

正数情形对称（找第一个 >x 的整数再减一），合并成：

```haskell
floorNaive x
  | x < 0     = until (`leq` x) (subtract 1) (-1)
  | otherwise = until (x `lt`) (+ 1) 1 - 1
  where
    m `leq` y = fromInteger m <= y
    y `lt` n  = y < fromInteger n
```

能用，但步数正比于 |x|——线性搜索。**二分版**把它压到对数：先倍增找出夹住 x 的区间
`(m, n)`（m ≤ x < n），再每次取中点收缩到单位区间：

```haskell
type Interval = (Integer, Integer)

floorBin :: Float -> Integer
floorBin x = fst (until unit (shrink x) (bound x))
  where
    unit (m, n)    = m + 1 == n                 -- 收缩到单位区间即完成
    shrink y (m, n)
      | p `leq` y  = (p, n)                     -- 中点在 x 左：丢掉左半
      | otherwise  = (m, p)                     -- 中点在 x 右：丢掉右半
      where p = (m + n) `div` 2
    bound y = (until (`leq` y) (* 2) (-1),      -- 下界：-1, -2, -4, … 倍增下降
               until (y `lt`) (* 2) 1)          -- 上界：1, 2, 4, … 倍增上升
```

以 `floorBin 17.3` 实测：下界 -1 一步到位（-1 ≤ 17.3），上界 1→2→4→8→16→32 共 5 步
得包围区间 `(-1, 32)`；中点收缩 15→(15,32)→(15,23)→(15,19)→(17,19)→(17,18) 共 5 步。
**对数步数对线性步数**——这是 25 章性能篇的第一个算法级对比实例。Prelude 真正的
`floor` 走 `RealFrac` 类族的 `properFraction`（把 x 拆成整数部分 + 小数部分），一条
指令的事——但你现在知道它内部替你免掉了什么。

## 3.7 Nat：自己造一个数系

Haskell 没有无符号自然数？那就**造一个**（原书 3.4）——这也是你第一次见到"数据声明"：

```haskell
data Nat = Zero | Succ Nat deriving (Eq, Ord, Show)
```

读法：`Zero` 是 `Nat`；`n` 是 `Nat` 时 `Succ n` 也是 `Nat`。于是
`Zero`、`Succ Zero`、`Succ (Succ Zero)`、……就是 0、1、2、……（皮亚诺公理的程序员版，
11 章归纳法证明的骨架正是它）。`deriving` 让 GHC 自动生成相等、排序、打印实例——原书
先手写了 `Eq`/`Show` 的模式匹配版本让你看清"派生"背后是什么，07/08 章会手写一次。

让 `Nat` 进 `Num` 类族，加减乘就能直接写：

```haskell
instance Num Nat where
    fromInteger n
      | n <= 0    = Zero
      | otherwise = Succ (fromInteger (n - 1))
    m + Zero      = m
    m + Succ n    = Succ (m + n)         -- 加法 = 后继的搬移
    m * Zero      = Zero
    m * Succ n    = m * n + m            -- 乘法 = 重复加法
    abs n         = n                    -- 自然数恒正
    signum Zero   = Zero
    signum (Succ _) = Succ Zero
    negate _      = Zero                 -- 自然数没有负数：截断（教学取舍）
    m - Zero        = m
    Zero - Succ _   = Zero               -- 截断减法：小减大得 0
    Succ m - Succ n = m - n
```

`natToInt (fromInteger 3 + fromInteger 4)` 得 7——但注意这是一进制表示，**又慢又占空间**，
纯教学。真正的收获是下面两个"世界观"观察：

**非完整数**。每个类型都含 ⊥（02 章），所以 `undefined :: Nat`、`Succ undefined`、
`Succ (Succ undefined)`、……**都是 `Nat` 的值**。它们能参与比较而不崩——只要比较不需要
看被 ⊥ 挡住的部分：

```haskell
Zero == Succ undefined     -- False（构造子就分出胜负，不用动 undefined）
Succ Zero == Succ undefined  -- *** Exception: Prelude.undefined（必须比内部，撞上 ⊥）
```

`Succ undefined` 可读作"至少是 1 的数"。**无穷数**也合法：

```haskell
natInf :: Nat
natInf = Succ natInf       -- 后继指向自己

Zero == natInf             -- False（1 步）；Succ Zero == natInf 也是 False（2 步）
```

每类数据类型都由**有穷元素 + 非完整元素 + 无穷元素**组成——12 章的无穷列表、13 章的
流，都是这个结构换了包装。若想关掉非完整数，可以给构造子加**严格标志**：
`data Nat = Zero | Succ !Nat`——`!` 强迫 `Succ` 的参数先求值，`Succ undefined` 在构造
时就炸（代价是失去惰性，25 章再算这笔账）。

## 3.8 read 与 readMaybe

`read :: Read a => String -> a` 是**部分函数**——解析失败直接崩：

```haskell
read "42" :: Int        -- 42
read "4x" :: Int        -- 运行时异常！
```

安全版在 `Text.Read`：

```haskell
readMaybe "42" :: Maybe Int    -- Just 42
readMaybe "4x" :: Maybe Int    -- Nothing
```

规则：**边界输入一律 readMaybe**（文件/网络/用户），内部已验证数据才允许 read。

## 3.9 Rational：精确分数

```haskell
import Data.Ratio ((%))

third = 1 % 3 :: Rational
third + 1 % 6                -- 1 % 2（精确）
0.1 + 0.2 :: Double          -- 0.30000000000000004（对照）
```

测试断言浮点别用 `==`（要么 `Rational`，要么误差带）——28 章性质测试也遵守。

## 3.10 坑位清单

1. **`factInt 21` 溢出为负**：阶乘类演示用 `Integer`；`Int` 边界意识常在（3.1）。
2. **`/` 与 `div` 分家**：整数除法写 `` `div` ``；`length` 参与 `/` 前必须 `fromIntegral`（3.3）。
3. **负数整除两家分道**：`divMod` vs `quotRem`——对接 C 用后者（3.4）。
4. **read 是部分函数**：外部输入用 `readMaybe`（3.8）。
5. **浮点相等**：`==` 对 Double 是逐位比较；测试用 Rational 或误差断言（3.9）。
6. **`(-1)` 不是 section**：减 1 的部分应用只能 `subtract 1`；`` (`leq` x) `` 与
   `(x `lt`)` 参数序相反，写错即翻车（3.6）。
7. **跨类型数值比较要显式转换**：`Integer` 与 `Float` 没有"混合 `<=`"——`fromInteger`
   过桥（3.6）。

## 3.11 练习（选自原书第 3 章习题）

**练习 3.1（subtract 与 flip）**：下列哪些表达式等于 1：`-2+3`、`3 + -2`、`3 + (-2)`、
`subtract 2 3`、`2 + subtract 3`？并用 `flip`（`flip f x y = f y x`）表示 `subtract`。
（答案：前三个里 `-2+3` 与 `3+(-2)` 得 1，`3 + -2` 不是合式；`subtract 2 3` 得 1；
`2 + subtract 3` 不合式。`subtract = flip (-)`。）

**练习 3.2（div 能用 floor 定义吗）**：`div x y = floor (x / y)` 行不行？
（答案：不行——`x/y` 是 `Fractional`、`div` 要 `Integral`，类型不通。正解：
`div x y = floor (fromIntegral x / fromIntegral y)`。）

**练习 3.3（牛顿法开方）**：若 `y` 是 √x 的近似，则 `x/y` 也是，且真值夹在两者之间。
比 `y` 与 `x/y` 都更好的下一步近似是什么？终止条件用 `|y*y - x| < eps` 还是
`|y*y - x| < eps * x`（Float 只有 ~6 位有效数字）？给出 `sqrt' :: Float -> Float`。
（答案：中点 `(y + x/y)/2`——你在重新发明牛顿法；相对误差版本更合理，
`eps = 0.000001`；骨架 `sqrt' x = until good improve x`。）

---

上一章：[02 第一个程序](02-hello.md) ｜ 下一章：[04 控制流](04-control.md) ｜ 返回：[README](../README.md)
