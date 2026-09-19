-- 06 测试套件
{-# LANGUAGE ViewPatterns #-}

module Main (main) where

import Ch06
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
    s1 <- runSuite "构造子与字面量模式"
        [ expectEq "describe 四档" (map describe [[], [7], [3, 4], [1, 2, 3]])
                     ["空", "单元素 7", "两个 3,4", "至少三个，首尾 1,3"]
        , expectEq "safeHead 空表" (safeHead ([] :: [Int])) Nothing
        , expectEq "safeHead 字符" (safeHead "abc") (Just 'a')
        , expectEq "safeTail" (safeTail [5, 6, 7]) (Just [6, 7])
        , expectEq "safeTail 单元素" (safeTail [5]) (Just [])
        , expectEq "safeTail 空表" (safeTail ([] :: [Int])) Nothing
        , expectEq "元音表" (filter isVowel "functional") ['u', 'i', 'o', 'a']
        ]
    s2 <- runSuite "元组/@/guard/视图"
        [ expectEq "sumPairs" (sumPairs [(1, 2), (3, 4), (0, 0)]) [3, 7, 0]
        , expectEq "swapPair" (swapPair (1, 'x')) ('x', 1)
        , expectEq "@ 绑定" (firstAndRest [10, 20, 30]) (10, [10, 20, 30], 3)
        , expectEq "@ 绑定空表" (firstAndRest []) (0, [], 0)
        , expectEq "guard 正" (categorize [3]) "首元素为正"
        , expectEq "guard 负" (categorize [-3]) "首元素为负"
        , expectEq "guard 零" (categorize [0]) "首元素为零"
        , expectEq "视图 读尽" (readInt "42") (Just 42)
        , expectEq "视图 读不尽" (readInt "4x") Nothing
        , expectEq "视图 带空格" (readInt " 42") (Just 42)
        ]
    s3 <- runSuite "惰性模式"
        [ expectEq "lazyHead 正常" (lazyHead [9, 8 :: Int]) 9
        , expectEq "lazyHead 单元素" (lazyHead "x") 'x'
        ]
    unless (s1 && s2 && s3) exitFailure
    putStrLn "==== 06 结束 ===="
