-- 19 测试套件（性能章：断值不断耗时；比例关系用宽松断言）
module Main (main) where

import Ch19
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
    unless (s1 && s2 && s3) exitFailure
    putStrLn "==== 19 结束 ===="
