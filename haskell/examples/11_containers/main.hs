-- 11 容器：Data.Map/Data.Set、Foldable/Traversable、元组
-- 运行：ghc -v0 --make main.hs -o 11.exe && ./11.exe
module Main (main) where

import Ch11
import qualified Data.Map.Strict as M
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    -- ═══ 11.1 词频统计（Map 主场）
    putStrLn "==[ 11 · 容器 ]=="
    let words' = ["to", "be", "or", "not", "to", "be"]
        freq = buildCounts words'
    putStrLn ("词频 = " ++ show freq)
    putStrLn ("topCounts = " ++ show (topCounts freq))
    putStrLn ("bump to 之后 = " ++ show (bump "to" freq M.! "to"))

    -- ═══ 11.2 合并两张表
    let f1 = buildCounts ["a", "b"]
        f2 = buildCounts ["b", "c"]
    putStrLn ("unionWith (+) = " ++ show (mergeCounts f1 f2))

    -- ═══ 11.3 集合运算
    putStrLn ("dedup [3,1,2,1] = " ++ show (dedup [3, 1, 2, 1 :: Int]))
    putStrLn ("common [1,2,3] [2,3,4] = " ++ show (common [1, 2, 3] [2, 3, 4]))
    putStrLn ("diff   [1,2,3] [2,3,4] = " ++ show (diff [1, 2, 3] [2, 3, 4]))

    -- ═══ 11.4 Foldable / Traversable
    putStrLn ("sumValues = " ++ show (sumValues freq))
    putStrLn ("doubleAll = " ++ show (doubleAll (M.fromList [("x", 1), ("y", 2)])))
    putStrLn ("validateAll 全正 = " ++ show (validateAll (M.fromList [("a", 1)])))
    putStrLn ("validateAll 有负 = " ++ show (validateAll (M.fromList [("a", -1)])))

    -- ═══ 11.5 元组
    putStrLn ("firstLast [1,2,3] = " ++ show (firstLast [1, 2, 3 :: Int]))

    -- ═══ 11.6 自检
    check "词频 to=2" (getCount freq "to") 2
    check "词频 or=1" (getCount freq "or") 1
    check "缺省 0" (getCount freq "zzz") 0
    check "bump" (bump "to" freq) (M.insert "to" 3 freq)
    check "合并" (mergeCounts f1 f2) (M.fromList [("a", 1), ("b", 2), ("c", 1)])
    check "去重升序" (dedup [3, 1, 2, 1]) [1, 2, 3]
    check "交集" (common [1, 2, 3] [2, 3, 4]) [2, 3]
    check "并集" (eitherOf [1, 2] [3, 4]) [1, 2, 3, 4]
    check "差集" (diff [1, 2, 3] [2]) [1, 3]
    check "Foldable 求和" (sumValues freq) 6
    check "Traverse 全过" (validateAll (M.fromList [("a", 1), ("b", 2)])) (Just (M.fromList [("a", 1), ("b", 2)]))
    check "Traverse 有败" (validateAll (M.fromList [("a", 1), ("b", 0)])) Nothing
    check "firstLast 空" (firstLast ([] :: [Int])) (Nothing, Nothing)

    putStrLn "==== 11 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
