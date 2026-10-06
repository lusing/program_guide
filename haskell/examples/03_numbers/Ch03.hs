-- Ch03 库模块：数值类型与类型类层次（Num → Fractional / Integral）
--                + until/两版 floor（书 3.3）+ Nat 归纳数（书 3.4）
module Ch03
    ( factInt, factInteger
    , divideFamily
    , count, avg
    , safeRead
    , third, half
    , doubleIt
    , leq, lt
    , floorNaive, floorBin
    , Nat (Zero, Succ), natToInt, natInf
    ) where

import Data.Ratio ((%))
import Text.Read (readMaybe)

-- ═══ 03.1 Int 有界、Integer 无界：21! 恰好越过 Int64 上界（约 9.2e18）
factInt :: Int -> Int
factInt n = product [1 .. n]

factInteger :: Integer -> Integer
factInteger n = product [1 .. n]

-- ═══ 03.2 整除家族：div/mod 向下取整（余数符号随除数），quot/rem 向零取整（余数符号随被除数）
-- 负数时两家分道扬镳——C 系语言是 quot/rem，数学惯例是 div/mod
divideFamily :: Integer -> Integer -> ((Integer, Integer), (Integer, Integer))
divideFamily a b = (divMod a b, quotRem a b)

-- ═══ 03.3 fromIntegral 桥接：length 返回 Int，要进 Double 必须显式转换
count :: [a] -> Double
count xs = fromIntegral (length xs)

avg :: [Double] -> Double
avg xs = sum xs / count xs          -- 不转就类型错误：Int 不能参与 /（Fractional）

-- ═══ 03.4 read 是部分函数：读不了就崩；readMaybe 给你 Maybe
safeRead :: String -> Maybe Int
safeRead s = readMaybe s

-- ═══ 03.5 Rational 精确分数：1/3 + 1/6 = 1/2，无浮点误差
third :: Rational
third = 1 % 3

half :: Rational
half = third + 1 % 6

-- ═══ 03.6 字面量多态：5 :: Num a => a，用在哪类上下文就是哪个类型
doubleIt :: Num a => a -> a
doubleIt x = x + x

-- ═══ 03.7 跨类型比较的桥（书 3.3）：Integer 与 Float 没有"混合 <="，必须转换
leq :: Integer -> Float -> Bool
leq m x = fromInteger m <= x

lt :: Float -> Integer -> Bool
lt x n = x < fromInteger n

-- ═══ 03.8 两版 floor（书 3.3）：线性搜索版——步数正比于 |x|
floorNaive :: Float -> Integer
floorNaive x
    | x < 0 = until (`leq` x) (subtract 1) (-1)     -- subtract 1：(-1) 是负数字面量不是 section
    | otherwise = until (x `lt`) (+ 1) 1 - 1

-- ═══ 03.9 二分版 floor：倍增定界 + 中点收缩，对数步数
type Interval = (Integer, Integer)

floorBin :: Float -> Integer
floorBin x = fst (until unit (shrink x) (bound x))
  where
    unit (m, n) = m + 1 == n
    shrink y (m, n)
        | p `leq` y = (p, n)
        | otherwise = (m, p)
      where
        p = (m + n) `div` 2
    bound y = (until (`leq` y) (* 2) (-1), until (y `lt`) (* 2) 1)

-- ═══ 03.10 Nat 归纳数（书 3.4）：皮亚诺公理的程序员版
data Nat = Zero | Succ Nat deriving (Eq, Ord, Show)

instance Num Nat where
    fromInteger n
        | n <= 0 = Zero
        | otherwise = Succ (fromInteger (n - 1))
    m + Zero = m
    m + Succ n = Succ (m + n) -- 加法 = 后继的搬移
    m * Zero = Zero
    m * Succ n = m * n + m -- 乘法 = 重复加法
    abs n = n
    signum Zero = Zero
    signum (Succ _) = Succ Zero
    negate _ = Zero -- 自然数没有负数：截断（教学取舍）
    m - Zero = m
    Zero - Succ _ = Zero -- 截断减法：小减大得 0
    Succ m - Succ n = m - n

natToInt :: Nat -> Integer
natToInt Zero = 0
natToInt (Succ n) = 1 + natToInt n

-- 无穷数（书 3.4）：Succ 指向自己。Zero == natInf 是 False——比较只走一层就分出胜负
natInf :: Nat
natInf = Succ natInf
