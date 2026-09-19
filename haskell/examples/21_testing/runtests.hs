-- 21 测试套件：本文件的 expectEq/runSuite 框架即教程主线用的自制框架（21 章正文以它为范本）
module Main (main) where

import Ch21
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
    s1 <- runSuite "生成器"
        [ expectEq "种子复现" (sampleInts 42) (sampleInts 42)
        , expectTrue "种子敏感" (sampleInts 42 /= sampleInts 43)
        , expectEq "样本数量" (length (sampleInts 42)) 8
        , expectTrue "范围合法" (all (\v -> v >= (-100) && v <= 100) (sampleInts 99))
        , expectEq "收缩整数" (shrinkInt 100) [50, 0]
        , expectEq "收缩零" (shrinkInt 0) ([] :: [Int])
        , expectEq "收缩列表" (shrinkList [1, 2, 3, 4]) [[1, 2], [1, 2, 3]]
        , expectEq "收缩单元素" (shrinkList [9]) ([] :: [[Int]])
        ]
    s2 <- runSuite "属性（各 200 样本定种子）"
        [ expectTrue "排序幂等" (runProperty 200 42 (generate :: Gen [Int]) shrinkList propSortIdempotent == Nothing)
        , expectTrue "绝对值非负" (runProperty 200 42 (generate :: Gen Int) shrinkInt propAbsNonNeg == Nothing)
        , expectTrue "reverse 两次" (runProperty 200 42 (generate :: Gen [Int]) shrinkList propReverseTwice == Nothing)
        , expectTrue "Text 往返" (runProperty 200 42 (generate :: Gen String) shrinkList propTextRoundtrip == Nothing)
        , expectTrue "失败属性给反例" (maybe False (const True) mfail)
        , expectTrue "反例确实违反" (maybe False (\x -> not (x < 5)) mfail)
        , expectTrue "反例已最小（邻居都满足）" (maybe False (\x -> all (\y -> y < 5) (shrinkInt x)) mfail)
        ]
    unless (s1 && s2) exitFailure
    putStrLn "==== 21 结束 ===="
  where
    mfail = runProperty 50 7 (generate :: Gen Int) shrinkInt (\x -> x < 5)
