# 04 · 控制流：表达式与递归

> 对应示例：`examples/04_control/`

## 4.1 一切皆表达式

Haskell 没有"语句"——`if`、`case`、`let` 都是**表达式**（有值的代码片段）。`if` 必须有 `else`
（两支都要有值，缺了就没法定类型）：

```haskell
clamp :: Int -> Int -> Int -> Int
clamp lo hi x = if x < lo then lo else if x > hi then hi else x
```

## 4.2 guard：多分支的正确形态

`| 条件 = 值` 一行一支，自上而下首个成立者胜；**`otherwise` 必须兜底**（缺了是编译错误）：

```haskell
classify :: Int -> String
classify n
  | n < 0     = "负数"
  | n == 0    = "零"
  | n < 10    = "小正数"
  | otherwise = "大正数"

grade :: Int -> Char              -- 成绩分档，guard 链最自然
grade s
  | s >= 90 = 'A'
  | s >= 80 = 'B'
  | s >= 70 = 'C'
  | s >= 60 = 'D'
  | otherwise = 'F'
```

## 4.3 let … in 与 where

两种局部绑定，作用域不同：

```haskell
-- where：函数级，函数体与 guard 共用（最常用）
normalize :: [Double] -> [Double]
normalize xs = map (/ total) xs
  where
    total = sum xs

-- let … in：表达式级，作用域只到 in 这一段
stats :: [Double] -> (Double, Double)
stats xs =
    let s = sum xs
        n = fromIntegral (length xs)
    in (s, s / n)
```

## 4.4 case 与穷尽性

```haskell
describeList :: [Int] -> String
describeList xs = case xs of
    []      -> "空列表"
    [x]     -> "单元素: " ++ show x
    (x:y:_) -> "开头两个: " ++ show x ++ " 和 " ++ show y
```

case 按结构分派（06 章展开模式家族）。**模式不穷尽时 GHC 默认警告**（加了 `-Wall` 才警），
运行时撞上漏网输入直接异常——宁可 `otherwise`/`_` 兜底也别留缺口。

## 4.5 递归替代循环

没有 for/while。"对每个元素做一件事"写成对首尾的递归：

```haskell
sumTo :: Int -> Integer            -- 直译版：n + 递归（非尾递归）
sumTo 0 = 0
sumTo n = fromIntegral n + sumTo (n - 1)

sumToAcc :: Int -> Integer         -- 累加器版：尾递归形态，GHC 编译成循环
sumToAcc n = go 0 n
  where
    go !acc 0 = acc                -- BangPatterns：!acc 每层立即求值
    go !acc k = go (acc + fromIntegral k) (k - 1)
```

`{-# LANGUAGE BangPatterns #-}` 是本章引入的第一个语言扩展（10 章详讲严格性）。

## 4.6 累加器：朴素 fib vs 线性 fib

```haskell
fibNaive 0 = 0
fibNaive 1 = 1
fibNaive n = fibNaive (n-1) + fibNaive (n-2)     -- 指数级（重复子问题）

fibAcc n = go 0 1 n                               -- 线性
  where go !a !b 0 = a
        go !a !b k = go b (a + b) (k - 1)
```

实测（本机 -O0）：`fibNaive 28` 毫秒级，`fibNaive 35` 就要秒级；`fibAcc 90` 瞬时
（`2880067194370816120`——朴素版在这个量级要等到天荒地老）。**算法级差距优先于一切微优化**（19 章回响）。

## 4.7 坑位清单

1. **if 缺 else 是语法错误**，不是逻辑警告（4.1）。
2. **guard 缺 otherwise**：非穷尽 guard 编译直接报——别删兜底（4.2）。
3. **let 作用域只到 in**；跨 guard 共享的计算放 where（4.3）。
4. **朴素递归的复杂度陷阱**：fib 这种"定义直译"可能指数级——累加器/记忆化（4.6）。
5. **栈深度**：非尾递归百万层会吃栈（GHC 栈上限大但不是无限）；大迭代写累加器形态（4.5）。
