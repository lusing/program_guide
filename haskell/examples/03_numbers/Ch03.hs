-- Ch03 库模块：数值类型与类型类层次（Num → Fractional / Integral）
module Ch03
    ( factInt, factInteger
    , divideFamily
    , count, avg
    , safeRead
    , third, half
    , doubleIt
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
