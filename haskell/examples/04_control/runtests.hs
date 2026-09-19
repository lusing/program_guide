-- 04 测试套件
{-# LANGUAGE BangPatterns #-}

module Main (main) where

import Ch04
import Control.Monad (unless)
import System.Exit (exitFailure)
import System.IO (hSetEncoding, stderr, stdout, utf8)

data Case = Case { name :: String, ok :: Bool, detail :: String }

expectEq :: (Eq a, Show a) => String -> a -> a -> Case
expectEq n got want
  | got == want = Case n True ""
  | otherwise   = Case n False (n ++ ": 得到 " ++ show got ++ " 期望 " ++ show want)

runSuite :: String -> [Case] -> IO Bool
runSuite group cs = do
    let bad = [c | c <- cs, not (ok c)]
    putStrLn (group ++ ": " ++ show (length cs - length bad) ++ "/" ++ show (length cs) ++ " 通过")
    mapM_ (putStrLn . ("  ✗ " ++) . detail) bad
    pure (null bad)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8
    s1 <- runSuite "if 与 guard"
        [ expectEq "clamp 三档" ([clamp 0 10 x | x <- [-3, 5, 99]], [clamp 0 10 x | x <- [0, 10, 7]])
                     ([0, 5, 10], [0, 10, 7])
        , expectEq "classify" (map classify [-5, 0, 7, 42]) ["负数", "零", "小正数", "大正数"]
        , expectEq "grade 五档" (map grade [95, 85, 75, 65, 50]) "ABCDF"
        ]
    s2 <- runSuite "let/where 与 case"
        [ expectEq "normalize 分量" (normalize [1, 2, 3]) [1 / 6, 2 / 6, 3 / 6]
        , expectEq "normalize 和为 1" (sum (normalize [1, 2, 3])) 1.0
        , expectEq "stats" (stats [1, 2, 3]) (6.0, 2.0)
        , expectEq "case 空表" (describeList []) "空列表"
        , expectEq "case 单元素" (describeList [7]) "单元素: 7"
        , expectEq "case 多元素" (describeList [1, 2, 3]) "开头两个: 1 和 2"
        ]
    s3 <- runSuite "递归与累加器"
        [ expectEq "sumTo 10" (sumTo 10) 55
        , expectEq "两版一致" (sumTo 1000) (sumToAcc 1000)
        , expectEq "fibNaive 10" (fibNaive 10) 55
        , expectEq "fib 两版一致" (fibNaive 25) (fibAcc 25)
        , expectEq "fibAcc 90" (fibAcc 90) 2880067194370816120
        ]
    unless (s1 && s2 && s3) exitFailure
    putStrLn "==== 04 结束 ===="
