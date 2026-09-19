-- Ch10 库模块：惰性求值——thunk、自引用、seq/deepseq、bang、空间泄漏修复
{-# LANGUAGE BangPatterns #-}

module Ch10
    ( nats, fibsZ, fibIndex
    , sumLazy, sumStrict, strictSum
    , squareOnce, average, average'
    , strictLen, lazyLen
    ) where

import Control.DeepSeq (NFData, force)
import Data.List (foldl')

-- ═══ 10.1 自引用定义：值在自己的定义里被引用（thunk 图的环）
nats :: [Int]
nats = 0 : map (+ 1) nats        -- take 5 nats = [0,1,2,3,4]，逐个按需展开

fibsZ :: [Integer]
fibsZ = 0 : 1 : zipWith (+) fibsZ (tail fibsZ)   -- 自引用 + zipWith：每个 thunk 复用前两个

fibIndex :: Int -> Integer
fibIndex n = fibsZ !! n          -- 索引取值：只算前 n 项

-- ═══ 10.2 空间泄漏复现：foldl 堆一百万个未求值的 (0+1)+2)+… 再一次性算
sumLazy :: Int -> Integer
sumLazy n = foldl (+) 0 [1 .. fromIntegral n]        -- 值对，代价大（正文 RTS -s 实测）

sumStrict :: Int -> Integer
sumStrict n = foldl' (+) 0 [1 .. fromIntegral n]     -- 每步强制：常量内存

-- ═══ 10.3 共享：let 绑定一个 thunk，两处引用只算一次
squareOnce :: Int -> (Int, Int)
squareOnce n =
    let sq = n * n                -- 一个共享 thunk（重计算会不会发生两次取决于共享，正文讲）
    in (sq + 0, sq + 1)

-- ═══ 10.4 经典泄漏形态：先算 length 再算 sum，两个 thunk 挂到除法才强制
average :: [Double] -> Double     -- 泄漏形态：l、s 都拖到最后一行
average xs = s / fromIntegral l
  where
    l = length xs
    s = sum xs

average' :: [Double] -> Double    -- seq 逐个强制：用完即弃
average' xs = l `seq` s `seq` s / fromIntegral l
  where
    l = length xs
    s = sum xs

-- ═══ 10.5 deepseq：整棵结构一次算完（NFData 约束）
strictLen :: (NFData a) => [a] -> Int
strictLen xs = force xs `seq` length xs

lazyLen :: [a] -> Int
lazyLen = length

-- ═══ 10.6 bang pattern：定义处直接声明"这里是严格的"
strictSum :: [Int] -> Int
strictSum = go 0
  where
    go !acc []     = acc          -- 参数前的 ! = 每次递归立即强制 acc
    go !acc (x:xs) = go (acc + x) xs
