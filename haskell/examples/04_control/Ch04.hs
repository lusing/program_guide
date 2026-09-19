-- Ch04 库模块：if/guard/case/let/where、递归替代循环、累加器
{-# LANGUAGE BangPatterns #-}

module Ch04
    ( clamp, classify, grade
    , normalize, stats
    , describeList
    , sumTo, sumToAcc
    , fibNaive, fibAcc
    ) where

-- ═══ 04.1 if-then-else 是表达式不是语句：必须有 else（两支都要有值）
clamp :: Int -> Int -> Int -> Int
clamp lo hi x = if x < lo then lo else if x > hi then hi else x

-- ═══ 04.2 guard（| 条件 = 值）：多分支比嵌套 if 清晰；otherwise 必须兜底
classify :: Int -> String
classify n
  | n < 0     = "负数"
  | n == 0    = "零"
  | n < 10    = "小正数"
  | otherwise = "大正数"          -- 缺了它：非穷尽 guard 是编译错误/运行崩溃

grade :: Int -> Char
grade s
  | s >= 90   = 'A'
  | s >= 80   = 'B'
  | s >= 70   = 'C'
  | s >= 60   = 'D'
  | otherwise = 'F'

-- ═══ 04.3 where（函数级绑定，函数体与 guard 共用）vs let…in（表达式级绑定）
normalize :: [Double] -> [Double]
normalize xs = map (/ total) xs
  where
    total = sum xs                 -- where 里的名字对上面整个函数体可见

stats :: [Double] -> (Double, Double)   -- (和, 均值)
stats xs =
    let s = sum xs
        n = fromIntegral (length xs)
    in (s, s / n)                  -- let 的作用域只到 in 这一个表达式

-- ═══ 04.4 case 与模式匹配：按结构分派
describeList :: [Int] -> String
describeList xs = case xs of
    []       -> "空列表"
    [x]      -> "单元素: " ++ show x
    (x:y:_)  -> "开头两个: " ++ show x ++ " 和 " ++ show y

-- ═══ 04.5 递归替代循环：直译版（n + 递归，非尾递归）
sumTo :: Int -> Integer
sumTo 0 = 0
sumTo n = fromIntegral n + sumTo (n - 1)

-- ═══ 04.6 累加器版：尾递归形态，GHC 编译成循环（正文实测对照）
sumToAcc :: Int -> Integer
sumToAcc n = go 0 n
  where
    go !acc 0 = acc
    go !acc k = go (acc + fromIntegral k) (k - 1)

-- ═══ 04.7 朴素 fib（指数级）vs 累加器 fib（线性）——04 章经典对照
fibNaive :: Int -> Integer
fibNaive 0 = 0
fibNaive 1 = 1
fibNaive n = fibNaive (n - 1) + fibNaive (n - 2)

fibAcc :: Int -> Integer
fibAcc n = go 0 1 n
  where
    go !a !b 0 = a
    go !a !b k = go b (a + b) (k - 1)
