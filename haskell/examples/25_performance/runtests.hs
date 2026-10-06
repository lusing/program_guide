-- 19 测试套件（性能章：断值不断耗时；比例关系用宽松断言）
module Main (main) where

import Ch25
import Control.Monad (unless)
import qualified Data.Text as T
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
    s1 <- runSuite "算法级"
        [ expectEq "fib 一致" (fibNaive 20) (fibAcc 20)
        , expectEq "fibAcc 90" (fibAcc 90) 2880067194370816120
        , expectEq "fibNaive 24" (fibNaive 24) 46368
        ]
    s2 <- runSuite "惰性与严格"
        [ expectEq "两版同值" (sumLazy 5000) (sumStrict 5000)
        , expectEq "严格版大数" (sumStrict 100000) 5000050000
        , expectEq "严格版零" (sumStrict 0) 0
        ]
    s3 <- runSuite "拼接"
        [ expectEq "同长" (T.length (concatSlow 100)) (T.length (concatBuilder 100))
        , expectEq "同值" (concatSlow 100) (concatBuilder 100)
        , expectEq "内容" (concatBuilder 3) (T.pack "ababab")
        ]
    s4 <- runSuite "书7 兵器（累积参数/元组/共享）"
        [ expectEq "fibPair 与 fibAcc 一致" (fibPair 90) (fibAcc 90)
        , expectEq "reverse 两版同值" (reverseSlow [1 .. 500]) (revcat [1 .. 500] [])
        , expectEq "revcat 空" (revcat ([] :: [Int]) [7]) [7]
        , expectEq "subseqs 两版同值" (subseqsSlow [1 .. 10]) (subseqsShared [1 .. 10])
        , expectEq "subseqs 数量 2^n" (length (subseqsShared [1 .. 8])) 256
        , expectEq "partition 一趟两分" (partitionT even [1 .. 8]) ([2, 4, 6, 8], [1, 3, 5, 7])
        , expectEq "partition 空表" (partitionT even ([] :: [Int])) ([], [])
        , expectEq "sumLen 元组化" (sumLen [1 .. 100 :: Double]) (5050.0, 100)
        , expectEq "sumLen 空表" (sumLen ([] :: [Double])) (0.0, 0)
        ]
    unless (s1 && s2 && s3 && s4) exitFailure
    putStrLn "==== 25 结束 ===="
