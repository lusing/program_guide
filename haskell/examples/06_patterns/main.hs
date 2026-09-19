-- 06 模式匹配：结构分派、@绑定、guard 共存、视图模式、惰性模式
-- 运行：ghc -v0 --make main.hs -o 06.exe && ./06.exe
{-# LANGUAGE ViewPatterns #-}

module Main (main) where

import Ch06
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    -- ═══ 06.1 按结构描述列表
    putStrLn "==[ 06 · 模式匹配 ]=="
    mapM_ (putStrLn . describe) [[], [7], [3, 4], [1, 2, 3, 4]]

    -- ═══ 06.2 安全版 head/tail
    putStrLn ("safeHead []       = " ++ show (safeHead ([] :: [Int])))
    putStrLn ("safeHead [5,6]    = " ++ show (safeHead [5, 6]))
    putStrLn ("safeTail [5,6,7]  = " ++ show (safeTail [5, 6, 7]))

    -- ═══ 06.3 元组解构
    putStrLn ("sumPairs [(1,2),(3,4)] = " ++ show (sumPairs [(1, 2), (3, 4)]))
    putStrLn ("swapPair (1,'x')       = " ++ show (swapPair (1, 'x')))

    -- ═══ 06.4 字面量分派
    putStrLn ("元音判定: " ++ show (map isVowel "haskell"))    -- h→F a→T s→F ...

    -- ═══ 06.5 @ 绑定
    let (x, whole, n) = firstAndRest [10, 20, 30]
    putStrLn ("首=" ++ show x ++ " 整表=" ++ show whole ++ " 长度=" ++ show n)

    -- ═══ 06.6 模式 + guard
    mapM_ (putStrLn . categorize) [[3], [-3], [0], []]

    -- ═══ 06.7 视图模式
    putStrLn ("readInt \"42\"   = " ++ show (readInt "42"))
    putStrLn ("readInt \"4x\"   = " ++ show (readInt "4x"))
    putStrLn ("readInt \" 42\"  = " ++ show (readInt " 42"))    -- 前导空格也能读

    -- ═══ 06.8 惰性模式：匹配必成功
    putStrLn ("lazyHead [9,8] = " ++ show (lazyHead [9, 8 :: Int]))

    -- ═══ 06.9 自检
    check "describe 空" (describe []) "空"
    check "safeHead 空" (safeHead ([] :: [Int])) Nothing
    check "safeHead 有" (safeHead "abc") (Just 'a')
    check "sumPairs" (sumPairs [(1, 2), (3, 4)]) [3, 7]
    check "isVowel" (map isVowel "aeou") [True, True, True, True]
    check "@ 绑定长度" n 3
    check "categorize 正" (categorize [3]) "首元素为正"
    check "categorize 空" (categorize []) "没有首元素"
    check "readInt 好" (readInt "42") (Just 42)
    check "readInt 坏" (readInt "4x") Nothing
    check "惰性匹配不提前崩" (lazyHead [9]) 9

    putStrLn "==== 06 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
