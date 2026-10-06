-- Ch25 库模块：性能——算法级 vs 常数级、惰性泄漏、严格折叠、Builder、计时方法论
{-# LANGUAGE OverloadedStrings #-}

module Ch25
    ( fibNaive, fibAcc, fibPair
    , sumLazy, sumStrict, sumLen
    , concatSlow, concatBuilder
    , reverseSlow, revcat
    , subseqsSlow, subseqsShared
    , partitionT
    , timed
    ) where

import Control.DeepSeq (NFData, force)
import Control.Exception (evaluate)
import Data.List (foldl')
import qualified Data.Text as T
import qualified Data.Text.Lazy as TL
import qualified Data.Text.Lazy.Builder as B
import GHC.Clock (getMonotonicTime)

-- ═══ 19.1 算法级差距：指数 fib vs 线性 fib（同一优化级别下的数量级差异）
fibNaive :: Int -> Integer
fibNaive 0 = 0
fibNaive 1 = 1
fibNaive n = fibNaive (n - 1) + fibNaive (n - 2)

fibAcc :: Int -> Integer
fibAcc n = go 0 1 n
  where
    go a _ 0 = a
    go a b k = go b (a + b) (k - 1)

-- ═══ 19.2 惰性泄漏：foldl 堆 thunk vs foldl' 常量空间（值相同、代价不同）
sumLazy :: Int -> Integer
sumLazy n = foldl (+) 0 [1 .. fromIntegral n]

sumStrict :: Int -> Integer
sumStrict n = foldl' (+) 0 [1 .. fromIntegral n]

-- ═══ 19.3 字符串拼接：左嵌套 ++ 是 O(n²)（每层拷贝前面全部）
concatSlow :: Int -> T.Text
concatSlow n = T.pack (foldl (++) "" (replicate n "ab"))        -- 反面教材

-- Builder：右结合分段，一次成串
concatBuilder :: Int -> T.Text
concatBuilder n = TL.toStrict (B.toLazyText (mconcat (replicate n (B.fromText "ab"))))

-- ═══ 19.5 书7.6 元组：fib2 一次递推带出相邻两项（指数 → 线性）
fibPair :: Int -> Integer
fibPair n = fst (go n)
  where
    go 0 = (0, 1)
    go k = (b, a + b)
      where
        (a, b) = go (k - 1)

-- ═══ 19.6 书7.5 累积参数：reverse 的 O(n²) 版 vs revcat 线性版
reverseSlow :: [a] -> [a] -- 每步把元素追加到尾部：T(n) = T(n-1) + Θ(n)
reverseSlow [] = []
reverseSlow (x : xs) = reverseSlow xs ++ [x]

revcat :: [a] -> [a] -> [a] -- 书 7.5 计算出的定义：revcat xs ys = reverse xs ++ ys
revcat [] ys = ys
revcat (x : xs) ys = revcat xs (x : ys) -- 累积参数把"追加"变"压头"

-- ═══ 19.7 书7.1 共享：subseqs 两版同值，一版重复计算、一版共享（但滞留空间）
subseqsSlow :: [a] -> [[a]]
subseqsSlow [] = [[]]
subseqsSlow (x : xs) = subseqsSlow xs ++ map (x :) (subseqsSlow xs) -- 递归出现两次：算两次

subseqsShared :: [a] -> [[a]]
subseqsShared [] = [[]]
subseqsShared (x : xs) = xss ++ map (x :) xss -- where 绑名共享：算一次
  where
    xss = subseqsShared xs

-- ═══ 19.8 书7.6/7.7 元组定律：partition 一趟两分（foldr 元组定律的特例）
partitionT :: (a -> Bool) -> [a] -> ([a], [a])
partitionT p = foldr op ([], [])
  where
    op x (ys, zs)
        | p x = (x : ys, zs)
        | otherwise = (ys, x : zs)

-- ═══ 19.9 书7.2 mean 的最终形态：sumlen 元组化 + seq 深入到分量
sumLen :: [Double] -> (Double, Int)
sumLen = foldl' step (0, 0)
  where
    step (s, n) x = s `seq` n `seq` (s + x, n + 1) -- 只 seq 到首范式不够：(s+x,n+1) 本来就是首范式

-- ═══ 19.10 计时方法论：deepseq 把结果算完才停表（否则测的是"造 thunk"的时间）
timed :: NFData a => IO a -> IO (Double, a)
timed act = do
    t0 <- getMonotonicTime
    x <- act
    y <- evaluate (force x)        -- force 保证计到完全求值为止
    t1 <- getMonotonicTime
    pure (t1 - t0, y)
