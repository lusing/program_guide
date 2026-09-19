# 05 · 函数：柯里化与组合

> 对应示例：`examples/05_functions/`

## 5.1 一切函数都是柯里化的

`add :: Int -> Int -> Int` 的真实读法是 `Int -> (Int -> Int)`：**取一个 Int，返回一个函数**。
`->` 右结合，多参函数是嵌套的单参函数：

```haskell
add :: Int -> Int -> Int
add x y = x + y

inc :: Int -> Int
inc = add 1              -- 部分应用：喂第一个参数，得到"加一器"
```

**部分应用是日常**：`map inc [1,2,3]`、`filter (> 0) xs`——高阶函数与柯里化天然配对。

## 5.2 组合 `(.)` 与求值 `($)`

```haskell
(.) :: (b -> c) -> (a -> b) -> a -> c
f . g = \x -> f (g x)

($) :: (a -> b) -> a -> b      -- 最低优先级、右结合——省右括号
```

```haskell
pipeline :: Int -> Int
pipeline = negate . sq . (+ 1)     -- 从右往左读：+1 → 平方 → 取负

show (sq (sq 3))                   == show $ sq $ sq 3
```

**优先级坑（本章实测两次）**：`f . g x` 解析为 `f . (g x)`（函数应用最紧）。
组合链作用到值上要么整体加括号 `(f . g) x`，要么用 `$`。

## 5.3 sections：运算符的部分应用

```haskell
doubleAll   = map (* 2)          -- (* 2) == \x -> x * 2
positives   = filter (> 0)
decrementAll = map (subtract 1)  -- (- 1) 不是减法 section！
```

`(- 1)` 是**负一**（字面量）——减法 section 必须写 `subtract 1`。
另外方向有讲究：`(/ 2)` 是 `x / 2`，`(2 /)` 是 `2 / x`。

## 5.4 高阶函数三件套

```haskell
applyTwice :: (a -> a) -> a -> a
applyTwice f x = f (f x)          -- applyTwice (+3) 1 == 7

composeAll :: [a -> a] -> a -> a
composeAll fs = foldr (.) id fs   -- id 是组合的单位元；composeAll [] == id

totalNegatives :: [Int] -> Int
totalNegatives = length . filter (< 0)   -- 点自由风格
```

**点自由（point-free）**：参数不写，管道即语义。适度使用提升可读性，过度使用变谜语。

## 5.5 lambda 与 eta 缩约

```haskell
filter (\x -> sq x > 10) [1..5]   -- lambda：就地写匿名函数

-- eta 缩约：最后一个参数两边同现即可消去
sumSq xs = sum (map sq xs)
sumSq'   = sum . map sq           -- 同一回事
```

## 5.6 自定义中缀运算符

```haskell
infixl 6 <+>                          -- 左结合、优先级 6（与 + 同级）

(<+>) :: [Int] -> [Int] -> [Int]
xs <+> ys = zipWith (+) xs ys

[1,2] <+> [3,4]        -- [4,6]
[1,2,3] <+> [10]       -- [11]（zipWith 截到短的）
```

运算符名由符号组成；`infixl/infixr/infix` 声明结合性与优先级（0–9）。

## 5.7 坑位清单

1. **`(- 1)` 是负数字面量**：减一用 `subtract 1`；一元负数参与中缀要加括号 `x - (-1)`（5.3）。
2. **`.` 的优先级低于函数应用**：`f . g x ≠ (f . g) x`——组合链加括号或用 `$`（5.2，
   本教程开发中在同一处摔了两次：13 章定律测试、16 章 walkDir）。
3. **section 的方向**：`(/ 2)` 与 `(2 /)` 相反；比较运算 `(a <)` 是 `\x -> a < x`（5.3）。
4. **点自由过度**：三层以上的组合链建议写回参数式，配签名（5.4）。
