-- Ch19 库模块：性能——算法级 vs 常数级、惰性泄漏、严格折叠、Builder、计时方法论
{-# LANGUAGE OverloadedStrings #-}

module Ch19
    ( fibNaive, fibAcc
    , sumLazy, sumStrict
    , concatSlow, concatBuilder
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

-- ═══ 19.4 计时方法论：deepseq 把结果算完才停表（否则测的是"造 thunk"的时间）
timed :: NFData a => IO a -> IO (Double, a)
timed act = do
    t0 <- getMonotonicTime
    x <- act
    y <- evaluate (force x)        -- force 保证计到完全求值为止
    t1 <- getMonotonicTime
    pure (t1 - t0, y)
