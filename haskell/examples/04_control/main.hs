-- 04 控制流：表达式化的 if/guard/case、let vs where、递归与累加器
-- 运行：ghc -v0 --make main.hs -o 04.exe && ./04.exe
{-# LANGUAGE BangPatterns #-}

module Main (main) where

import Ch04
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    -- ═══ 04.1 if 是表达式：能塞进任何值的位置
    putStrLn "==[ 04 · 控制流 ]=="
    putStrLn ("clamp 0 10 (-3) = " ++ show (clamp 0 10 (-3)))
    putStrLn ("clamp 0 10 5    = " ++ show (clamp 0 10 5))
    putStrLn ("clamp 0 10 99   = " ++ show (clamp 0 10 99))

    -- ═══ 04.2 guard 链：自上而下首个成立者胜
    mapM_ (putStrLn . (\n -> show n ++ " → " ++ classify n)) [-5, 0, 7, 42]
    putStrLn ("grades: " ++ map grade [95, 85, 75, 65, 50])

    -- ═══ 04.3 where 与 let 的分工
    putStrLn ("normalize [1,2,3] = " ++ show (normalize [1, 2, 3]))
    putStrLn ("stats [1,2,3]     = " ++ show (stats [1, 2, 3]))

    -- ═══ 04.4 case 按结构分派
    mapM_ (putStrLn . describeList) [[], [7], [1, 2, 3]]

    -- ═══ 04.5 递归与累加器：结果相同，形态不同（正文给耗时对照）
    putStrLn ("sumTo 100000     = " ++ show (sumTo 100000))
    putStrLn ("sumToAcc 100000  = " ++ show (sumToAcc 100000))
    putStrLn ("fibNaive 28      = " ++ show (fibNaive 28))
    putStrLn ("fibAcc 90        = " ++ show (fibAcc 90))    -- 朴素版在这个量级要跑数分钟

    -- ═══ 04.6 自检
    check "clamp 下界" (clamp 0 10 (-3)) 0
    check "clamp 上界" (clamp 0 10 99) 10
    check "classify 负" (classify (-5)) "负数"
    check "grade 95" (grade 95) 'A'
    check "grade 50" (grade 50) 'F'
    check "normalize 总和归一" (sum (normalize [1, 2, 3])) 1.0
    check "describeList 空" (describeList []) "空列表"
    check "sumTo == sumToAcc" (sumTo 1000) (sumToAcc 1000)
    check "fib 30 两版一致" (fibNaive 30) (fibAcc 30)

    putStrLn "==== 04 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
