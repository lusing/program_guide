-- 09 列表与折叠：fold 三兄弟、scan、unfoldr、推导式、建造塔筛素数
-- 运行：ghc -v0 --make main.hs -o 09.exe && ./09.exe
module Main (main) where

import Ch09
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    -- ═══ 09.1 三种折叠同一结果，代价不同（10 章给内存实测）
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

    -- ═══ 09.7 自检
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

    putStrLn "==== 09 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
