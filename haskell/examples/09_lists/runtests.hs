-- 09 测试套件
module Main (main) where

import Ch09
import Control.Monad (unless)
import System.Exit (exitFailure)
import System.IO (hSetEncoding, stderr, stdout, utf8)

data Case = Case { name :: String, ok :: Bool, detail :: String }

expectEq :: (Eq a, Show a) => String -> a -> a -> Case
expectEq n got want
  | got == want = Case n True ""
  | otherwise   = Case n False (n ++ ": 得到 " ++ show got ++ " 期望 " ++ show want)

expectTrue :: String -> Bool -> Case
expectTrue n b = Case n b (if b then "" else n ++ ": 期望为真，得到假")

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
    s1 <- runSuite "折叠家族"
        [ expectEq "foldr" (mySumR [1 .. 100]) 5050
        , expectEq "foldl" (mySumL [1 .. 100]) 5050
        , expectEq "foldl'" (mySumL' [1 .. 1000]) 500500
        , expectEq "空表折叠" (mySumR []) 0
        , expectEq "andR 全真" (andR [True, True, True]) True
        , expectTrue "andR 短路 undefined" (andR [True, False] == False)
        , expectEq "foldr 建列表" (foldr (:) [] [1, 2, 3]) [1, 2, 3]
        ]
    s2 <- runSuite "scan 与展开"
        [ expectEq "前缀和" (prefixSums [1, 2, 3, 4]) [0, 1, 3, 6, 10]
        , expectEq "scanl1 保序" (scanl1 (+) [1, 2, 3]) [1, 3, 6]
        , expectEq "fibs 首 10" (take 10 fibs) [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
        , expectEq "iterate" (take 5 naturals) [0 .. 4]
        ]
    s3 <- runSuite "推导与筛"
        [ expectEq "勾股小边界" (pythagTriples 5) [(3, 4, 5)]
        , expectEq "勾股数 (6,8,10) 在列" (length (pythagTriples 13)) 3
        , expectEq "素数" (firstPrimes 6) [2, 3, 5, 7, 11, 13]
        , expectEq "素数边界" (maximum (firstPrimes 10)) 29
        ]
    s4 <- runSuite "zip 族"
        [ expectEq "点积" (dot [1, 2, 3] [4, 5, 6]) 32.0
        , expectEq "zipWith 截断" (zipWith (*) [1, 2, 3, 4] [2]) [2]
        , expectEq "zip 配对" (zip "ab" [1, 2, 3]) [('a', 1), ('b', 2)]
        ]
    unless (s1 && s2 && s3 && s4) exitFailure
    putStrLn "==== 09 结束 ===="
