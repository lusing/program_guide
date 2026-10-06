-- 18 命令式函数式：State 回顾与 ST 单子（书10）
-- 运行：ghc -v0 --make main.hs -o 18.exe && ./18.exe
module Main (main) where

import Ch18
import Data.List (sort)
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    putStrLn "==[ 18 · 命令式函数式：State 与 ST ]=="

    -- ═══ 18.1 骰子两版：显式串联 vs State 单子（书10.3）
    putStrLn ("diceExplicit 42 = " ++ show (diceExplicit 42))
    putStrLn ("diceState 42    = " ++ show (diceState 42))

    -- ═══ 18.2 fib 两版：纯元组递推 vs STRef 直译（书10.4）
    putStrLn ("fibPair 30 = " ++ show (fibPair 30))
    putStrLn ("fibST   30 = " ++ show (fibST 30))

    -- ═══ 18.3 STArray 冒泡排序（书10.5）
    putStrLn ("bsortST [5,1,4,2,8] = " ++ show (bsortST [5, 1, 4, 2, 8 :: Int]))

    -- ═══ 18.4 Fisher-Yates 洗牌：确定性可复现
    putStrLn ("shuffleST [1..10] 种子 7  = " ++ show (shuffleST [1 .. 10 :: Int] 7))
    putStrLn ("shuffleST [1..10] 种子 7 再来一次（相同）= " ++ show (shuffleST [1 .. 10 :: Int] 7 == shuffleST [1 .. 10 :: Int] 7))

    -- ═══ 18.5 STRef 计数器
    putStrLn ("labelsST 3 = " ++ show (labelsST 3))

    -- ═══ 18.6 自检
    check "骰子两版一致" (diceState 42) (diceExplicit 42)
    check "骰子确定性" (diceState 99) (diceExplicit 99)
    check "fib 两版一致 30" (fibST 30) (fibPair 30)
    check "fib 两版一致 0" (fibST 0) (fibPair 0)
    check "fibST 10 = 55" (fibST 10) 55
    check "bsortST 与 sort 一致"
        (bsortST [5, 3, 8, 1, 9, 2, 7, 2 :: Int])
        (sort [5, 3, 8, 1, 9, 2, 7, 2 :: Int])
    check "bsortST 空表" (bsortST [] :: [Int]) []
    check "洗牌可复现" (shuffleST [1 .. 10 :: Int] 7) (shuffleST [1 .. 10 :: Int] 7)
    check "洗牌是排列" (sort (shuffleST [1 .. 10 :: Int] 13)) [1 .. 10]
    check "不同种子不同洗法" (shuffleST [1 .. 20 :: Int] 1 /= shuffleST [1 .. 20 :: Int] 2) True
    check "标签自增" (labelsST 4) ["L1", "L2", "L3", "L4"]

    putStrLn "==== 18 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
    | actual == expected = return ()
    | otherwise =
        error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
