-- 19 性能：算法级差距、惰性泄漏、严格折叠、Builder、计时方法论
-- 运行：ghc -v0 --make main.hs -o 19.exe && ./19.exe（RTS 内存对照见正文：+RTS -s）
module Main (main) where

import Ch19
import qualified Data.Text as T
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    putStrLn "==[ 19 · 性能 ]=="

    -- ═══ 19.1 算法级：指数 vs 线性
    (tNaive, vNaive) <- timed (pure (fibNaive 24))
    (tAcc, vAcc)     <- timed (pure (fibAcc 90))
    putStrLn ("fibNaive 24 = " ++ show vNaive ++ "，耗时 " ++ show tNaive ++ "s")
    putStrLn ("fibAcc 90   = " ++ show vAcc ++ "，耗时 " ++ show tAcc ++ "s")

    -- ═══ 19.2 惰性泄漏：两版同值（内存差距看正文 RTS -s 实测）
    (tL, vL) <- timed (pure (sumLazy 100000))
    (tS, vS) <- timed (pure (sumStrict 1000000))
    putStrLn ("sumLazy 10万    = " ++ show vL ++ "，耗时 " ++ show tL ++ "s")
    putStrLn ("sumStrict 100万 = " ++ show vS ++ "，耗时 " ++ show tS ++ "s")

    -- ═══ 19.3 拼接策略
    (tSlow, vSlow)       <- timed (pure (concatSlow 4000))
    (tBuilder, vBuilder) <- timed (pure (concatBuilder 4000))
    putStrLn ("concatSlow    长度 " ++ show (T.length vSlow) ++ "，耗时 " ++ show tSlow ++ "s")
    putStrLn ("concatBuilder 长度 " ++ show (T.length vBuilder) ++ "，耗时 " ++ show tBuilder ++ "s")

    -- ═══ 19.4 自检（只断值与关系，不断耗时——计时数字因机器而异）
    check "fib 两版一致" (fibNaive 24) (fibAcc 24)
    check "fibAcc 90" vAcc 2880067194370816120
    check "泄漏版值正确" vL (sumStrict 100000)
    check "线性版大数" vS 500000500000
    check "拼接同长" (T.length vSlow) (T.length vBuilder)
    check "拼接同值" vSlow vBuilder
    check "指数远慢于线性" (tNaive > tAcc) True     -- 24 项朴素版仍应慢于 90 项线性版

    putStrLn "==== 19 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
