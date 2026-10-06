-- 13 测试套件：无穷列表（书9）
module Main (main) where

import Ch13
import Control.Monad (unless)
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
    s1 <- runSuite "循环结构（书9.2）"
        [ expectEq "myCycle" (take 5 (myCycle "ab")) "ababa"
        , expectEq "repeat2" (take 3 (repeat2 'x')) "xxx"
        , expectEq "iterate1" (take 8 (iterate1 (2 *) 1)) [1, 2, 4, 8, 16, 32, 64, 128 :: Int]
        , expectEq "iterate2" (take 8 (iterate2 (2 *) 1)) [1, 2, 4, 8, 16, 32, 64, 128 :: Int]
        , expectEq "iterate3" (take 8 (iterate3 (2 *) 1)) [1, 2, 4, 8, 16, 32, 64, 128 :: Int]
        , expectEq "approx 前 k 项可取" (take 4 (approx 6 (iterate1 (2 *) 1)) :: [Int]) [1, 2, 4, 8]
        , expectEq "fibs 前 12" (take 12 fibs) [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89]
        , expectEq "fibs 第 21 项" (fibs !! 21) 10946
        ]
    s2 <- runSuite "素数循环筛（书9.2 最终版）"
        [ expectEq "primes 前 10" (take 10 primes) [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
        , expectEq "primes 第 15 个" (take 15 primes !! 14) 47
        , expectTrue "primes 与小规模试除一致"
            (take 50 primes == [fromIntegral n | n <- [2 .. 230 :: Int], naive n])
        , expectTrue "minus 保序去重" (minus [1 .. 20] [2, 4 .. 20] == [1, 3 .. 19])
        , expectTrue "merge 归并去重" (take 6 (merge [2, 4 ..] [3, 6 ..]) == [2, 3, 4, 6, 8, 9])
        ]
    s3 <- runSuite "石头剪刀布（书9.4）"
        [ expectEq "布包石头" (score (Paper, Rock)) (1, 0)
        , expectEq "石头钝剪刀" (score (Rock, Scissors)) (1, 0)
        , expectEq "剪刀剪布" (score (Scissors, Paper)) (1, 0)
        , expectEq "平局" (score (Rock, Rock)) (0, 0)
        , expectEq "copy 对 copy 全平" (match 10 (copy, copy)) (0, 0)
        , expectEq "cheat 全胜" (match 10 (cheat, copy)) (10, 0)
        , expectEq "devious 7 装老实" (match 7 (devious 7, copy)) (0, 0)
        , expectEq "devious 7 十回合赢三" (match 10 (devious 7, copy)) (3, 0)
        , expectTrue "对局可复现（确定性 rand）" (match 20 (smart, cheat) == match 20 (smart, cheat))
        ]
    unless (s1 && s2 && s3) exitFailure
    putStrLn "==== 13 结束 ===="
  where
    -- 小规模试除法对照（n ≤ 229 时与循环筛逐个一致）
    naive n = null [d | d <- [2 .. n - 1], n `mod` d == 0]
