-- 10 惰性求值：thunk、自引用、无穷结构、空间泄漏与三板斧修复
-- 运行：ghc -v0 --make main.hs -o 10.exe && ./10.exe（正文演示 +RTS -s 看内存对照）
{-# LANGUAGE BangPatterns #-}

module Main (main) where

import Ch10
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    -- ═══ 10.1 自引用结构的按需展开
    putStrLn "==[ 10 · 惰性求值 ]=="
    putStrLn ("take 5 nats  = " ++ show (take 5 nats))
    putStrLn ("fibsZ 前 8 项 = " ++ show (take 8 fibsZ))
    putStrLn ("fibIndex 90  = " ++ show (fibIndex 90))

    -- ═══ 10.2 take 前先 drop：无穷结构随便切
    putStrLn ("drop 5 (take 10 fibsZ) = " ++ show (drop 5 (take 10 fibsZ)))

    -- ═══ 10.3 空间泄漏：两版值相同、内存天差地别（-O0 下 sumLazy 百万级堆 thunk）
    putStrLn ("sumLazy 100000    = " ++ show (sumLazy 100000))
    putStrLn ("sumStrict 1000000 = " ++ show (sumStrict 1000000))

    -- ═══ 10.4 平均值两版：值一致，严格性不同
    putStrLn ("average [1..100]  = " ++ show (average [1 .. 100]))
    putStrLn ("average' [1..100] = " ++ show (average' [1 .. 100]))

    -- ═══ 10.5 共享
    putStrLn ("squareOnce 7      = " ++ show (squareOnce 7))

    -- ═══ 10.6 bang 累加器
    putStrLn ("strictSum [1..100] = " ++ show (strictSum [1 .. 100]))

    -- ═══ 10.7 自检（惰性结构断言只断"取到的那部分"）
    check "自引用 nats" (take 5 nats) [0 .. 4]
    check "自引用 fibs" (take 8 fibsZ) [0, 1, 1, 2, 3, 5, 8, 13]
    check "fib 索引" (fibIndex 30) 832040
    check "泄漏版值正确" (sumLazy 1000) (sumStrict 1000)
    check "平均值两版一致" (average [1 .. 100]) (average' [1 .. 100])
    check "平均值" (average [1 .. 100]) 50.5
    check "共享元组" (squareOnce 7) (49, 50)
    check "bang 累加" (strictSum [1 .. 100]) 5050
    check "deepseq 长度" (strictLen [1, 2, 3 :: Int]) 3

    putStrLn "==== 10 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
