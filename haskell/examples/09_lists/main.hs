-- 09 列表与折叠：fold 三兄弟、scan、unfoldr、推导式、建造塔筛素数
-- 运行：ghc -v0 --make main.hs -o 09.exe && ./09.exe
module Main (main) where

import Ch09
import qualified Data.List
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    -- ═══ 09.1 三种折叠同一结果，代价不同（12 章给内存实测）
    putStrLn "==[ 09 · 列表与折叠 ]=="
    let xs = [1 .. 100] :: [Int]
    putStrLn ("sum/map/filter: " ++ show (sum xs, map (* 2) [1, 2, 3], filter odd [1 .. 6]))
    putStrLn ("三折叠一致: " ++ show (mySumR xs == mySumL xs && mySumL xs == mySumL' xs))
    putStrLn ("andR 短路: " ++ show (andR [True, False, undefined]))   -- False，undefined 没被碰

    -- ═══ 09.2 scanl 前缀和
    putStrLn ("prefixSums [1,2,3] = " ++ show (prefixSums [1, 2, 3 :: Int]))

    -- ═══ 09.3 unfoldr / iterate：无穷结构 + take
    putStrLn ("fibs 前 10 项 = " ++ show (take 10 fibs))
    putStrLn ("naturals 前 5 项 = " ++ show (take 5 naturals))

    -- ═══ 09.4 列表推导
    putStrLn ("勾股数 (<=20) = " ++ show (pythagTriples 20))

    -- ═══ 09.5 建造塔筛素数
    putStrLn ("前 10 个素数 = " ++ show (firstPrimes 10))

    -- ═══ 09.6 zipWith 点积
    putStrLn ("dot [1,2,3] [4,5,6] = " ++ show (dot [1, 2, 3] [4, 5, 6]))

    -- ═══ 09.7 书4：span/countRuns + 归并排序 + nondec/position + triads + 高频词
    putStrLn ("countRuns (sort (words)) = " ++ show (countRuns ["be", "be", "not", "or", "to", "to"]))
    putStrLn ("msort [5,3,8,1,9,2] = " ++ show (msort [5, 3, 8, 1, 9, 2 :: Int]))
    putStrLn ("nondec [1,2,2,5] = " ++ show (nondec [1, 2, 2, 5 :: Int]) ++ "   nondec [3,1] = " ++ show (nondec [3, 1 :: Int]))
    putStrLn ("position 'b' abc = " ++ show (position 'b' "abc") ++ "   position 'z' = " ++ show (position 'z' "abc"))
    putStrLn ("triads 20 = " ++ show (triads 20))
    putStrLn "-- commonWords 3 (书版全手写管线):"
    putStr (commonWords 3 "to be or not to be")

    -- ═══ 09.8 自检
    check "fold 三兄弟" (mySumR xs) 5050
    check "foldl' 同值" (mySumL' [1 .. 1000]) 500500
    check "andR 真全真" (andR [True, True]) True
    check "前缀和" (prefixSums [1, 2, 3]) [0, 1, 3, 6]
    check "fibs 第 10" (fibs !! 10) 55
    check "fibs !! 90" (fibs !! 90) 2880067194370816120
    check "勾股 (3,4,5)" ((3, 4, 5) `elem` pythagTriples 20) True
    check "素数递增" (maximum (firstPrimes 10)) 29    -- 升序序列，maximum = 第 10 个
    check "点积" (dot [1, 2, 3] [4, 5, 6]) 32.0
    check "zipWith 截断" (zipWith (+) [1, 2, 3] [10]) [11]
    check "span 切分" (mySpan (< 3) [1, 2, 4, 1]) ([1, 2], [4, 1])
    check "countRuns 连续段" (countRuns ["a", "a", "b"]) [(2, "a"), (1, "b")]
    check "msort 与库 sort 一致" (msort vs) (Data.List.sort vs)
    check "merge 基本情况" (merge [] [1 :: Int]) [1]
    check "nondec 真" (nondec [1, 2, 2, 5 :: Int]) True
    check "nondec 假" (nondec [3, 1 :: Int]) False
    check "position 命中" (position 'b' "abc") 1
    check "position 未命中" (position 'z' "abc") (-1)
    check "triads 数量" (length (triads 20)) 3
    check "triads 含本原三元组" ((3, 4, 5) `elem` triads 20) True
    check "commonWords 书版" (commonWords 3 "to be or not to be") (unlines ["to: 2", "be: 2", "or: 1"])

    putStrLn "==== 09 结束 ===="

vs :: [Int]
vs = [5, 3, 8, 1, 9, 2, 7, 2]   -- msort 对账样本

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
