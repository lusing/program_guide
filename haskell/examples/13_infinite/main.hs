-- 13 无穷列表：循环结构、素数筛、approx、石头剪刀布（书9）
-- 运行：ghc -v0 --make main.hs -o 13.exe && ./13.exe
module Main (main) where

import Ch13
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    putStrLn "==[ 13 · 无穷列表 ]=="

    -- ═══ 13.1 循环结构：一个结，取之不尽
    putStrLn ("myCycle \"ab\" 前 5 个 = " ++ show (take 5 (myCycle "ab")))
    putStrLn ("repeat2 'x' 前 3 个 = " ++ show (take 3 (repeat2 'x')))

    -- ═══ 13.2 iterate 三定义：结果相同、代价不同（docs 讲 O(n) vs O(n²)）
    putStrLn ("iterate1 (2*) 1 前 6 个 = " ++ show (take 6 (iterate1 (2 *) 1)))
    putStrLn ("iterate2 (2*) 1 前 6 个 = " ++ show (take 6 (iterate2 (2 *) 1)))
    putStrLn ("iterate3 (2*) 1 前 6 个 = " ++ show (take 6 (iterate3 (2 *) 1)))
    -- 注意：approx 5 xs 的尾部是 ⊥，直接 == 会撞上（坑位素材！）；机器对账用 take：
    putStrLn ("take 3 (approx 5 (iterate1 (2*) 1)) = "
                ++ show (take 3 (approx 5 (iterate1 (2 *) 1)) :: [Int]))

    -- ═══ 13.3 fibs：打结的 zipWith
    putStrLn ("fibs 前 12 个 = " ++ show (take 12 fibs))

    -- ═══ 13.4 素数循环筛：2 : ([3..] \\ composites)，composites 又用 primes
    putStrLn ("primes 前 15 个 = " ++ show (take 15 primes))

    -- ═══ 13.5 石头剪刀布：策略 = 流→流，两个循环列表互指
    putStrLn ("copy   vs copy   10 回合 = " ++ show (match 10 (copy, copy)))
    putStrLn ("smart  vs copy   10 回合 = " ++ show (match 10 (smart, copy)))
    putStrLn ("cheat  vs copy   10 回合 = " ++ show (match 10 (cheat, copy)))
    putStrLn ("devious 7 vs copy 10 回合 = " ++ show (match 10 (devious 7, copy)))

    -- ═══ 13.6 自检
    check "myCycle" (take 5 (myCycle "ab")) "ababa"
    check "repeat2" (take 3 (repeat2 'x')) "xxx"
    check "iterate 三版同值" [take 10 (iterate1 (2 *) 1), take 10 (iterate2 (2 *) 1), take 10 (iterate3 (2 *) 1)] (replicate 3 [1, 2, 4, 8, 16, 32, 64, 128, 256, 512 :: Int])
    check "approx 前 k 项可取" (take 4 (approx 6 (iterate1 (2 *) 1)) :: [Int]) [1, 2, 4, 8]
    check "fibs 第 21 项" (fibs !! 21) 10946
    check "primes 前 10" (take 10 primes) [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
    check "布包石头" (score (Paper, Rock)) (1, 0)
    check "石头钝剪刀" (score (Rock, Scissors)) (1, 0)
    check "剪刀剪布" (score (Scissors, Paper)) (1, 0)
    check "平局" (score (Rock, Rock)) (0, 0)
    check "copy 对 copy 全平" (match 10 (copy, copy)) (0, 0)
    check "cheat 全胜" (match 10 (cheat, copy)) (10, 0)
    check "devious 后 3 手才赢" (match 10 (devious 7, copy)) (3, 0)

    putStrLn "==== 13 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
    | actual == expected = return ()
    | otherwise =
        error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
