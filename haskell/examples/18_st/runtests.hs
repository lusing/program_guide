-- 18 测试套件：State 与 ST（书10）
module Main (main) where

import Ch18
import Control.Monad (unless)
import Data.List (sort)
import System.Exit (exitFailure)
import System.IO (hSetEncoding, stderr, stdout, utf8)

data Case = Case {name :: String, ok :: Bool, detail :: String}

expectEq :: (Eq a, Show a) => String -> a -> a -> Case
expectEq n got want
    | got == want = Case n True ""
    | otherwise = Case n False (n ++ ": 得到 " ++ show got ++ " 期望 " ++ show want)

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
    s1 <- runSuite "State（书10.3）"
        [ expectTrue "骰子两版一致 42" (diceState 42 == diceExplicit 42)
        , expectTrue "骰子两版一致 99" (diceState 99 == diceExplicit 99)
        , expectTrue "骰子在 1..6" (let (a, b) = diceState 7 in a `elem` [1 .. 6] && b `elem` [1 .. 6])
        , expectTrue "骰子确定性" (diceState 5 == diceState 5)
        ]
    s2 <- runSuite "STRef（书10.4）"
        [ expectEq "fibST 0" (fibST 0) 0
        , expectEq "fibST 1" (fibST 1) 1
        , expectEq "fibST 10" (fibST 10) 55
        , expectEq "fibST 30 与纯版一致" (fibST 30) (fibPair 30)
        , expectEq "fibST 90 与纯版一致" (fibST 90) (fibPair 90)
        , expectEq "labelsST" (labelsST 3) ["L1", "L2", "L3"]
        ]
    s3 <- runSuite "STArray（书10.5）"
        [ expectEq "bsort 乱序" (bsortST [5, 1, 4, 2, 8 :: Int]) [1, 2, 4, 5, 8]
        , expectEq "bsort 空表" (bsortST [] :: [Int]) []
        , expectEq "bsort 单元素" (bsortST [9 :: Int]) [9]
        , expectTrue "bsort 与 sort 一致"
            (bsortST [5, 3, 8, 1, 9, 2, 7, 2 :: Int] == sort [5, 3, 8, 1, 9, 2, 7, 2])
        , expectTrue "bsort 重复元素" (bsortST [3, 3, 1, 1, 2 :: Int] == [1, 1, 2, 3, 3])
        , expectTrue "洗牌可复现" (shuffleST [1 .. 10 :: Int] 7 == shuffleST [1 .. 10 :: Int] 7)
        , expectTrue "洗牌是排列" (sort (shuffleST [1 .. 10 :: Int] 13) == [1 .. 10])
        , expectTrue "不同种子不同洗法" (shuffleST [1 .. 20 :: Int] 1 /= shuffleST [1 .. 20 :: Int] 2)
        ]
    unless (s1 && s2 && s3) exitFailure
    putStrLn "==== 18 结束 ===="
