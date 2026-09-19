-- 10 测试套件
{-# LANGUAGE BangPatterns #-}

module Main (main) where

import Ch10
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
    s1 <- runSuite "自引用与无穷"
        [ expectEq "nats" (take 6 nats) [0 .. 5]
        , expectEq "nats 深处" (nats !! 20) 20
        , expectEq "fibsZ" (take 10 fibsZ) [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
        , expectEq "fibIndex 25" (fibIndex 25) 75025
        , expectEq "drop+take" (drop 5 (take 10 fibsZ)) [5, 8, 13, 21, 34]
        ]
    s2 <- runSuite "严格性"
        [ expectEq "两版同值" (sumLazy 1000) (sumStrict 1000)
        , expectEq "大列表 foldl'" (sumStrict 100000) 5000050000
        , expectEq "平均值" (average [1 .. 100]) 50.5
        , expectEq "平均两版一致" (average [2, 4, 6]) (average' [2, 4, 6])
        , expectEq "bang 累加" (strictSum [1 .. 1000]) 500500
        , expectEq "空表 bang" (strictSum []) 0
        ]
    s3 <- runSuite "共享"
        [ expectEq "squareOnce" (squareOnce 9) (81, 82)
        , expectEq "squareOnce 零" (squareOnce 0) (0, 1)
        ]
    unless (s1 && s2 && s3) exitFailure
    putStrLn "==== 10 结束 ===="
