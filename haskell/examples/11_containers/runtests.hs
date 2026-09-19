-- 11 测试套件
module Main (main) where

import Ch11
import Control.Monad (unless)
import qualified Data.Map.Strict as M
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
    let freq = buildCounts ["to", "be", "or", "not", "to", "be"]
    s1 <- runSuite "Map"
        [ expectEq "词频 to" (getCount freq "to") 2
        , expectEq "词频 be" (getCount freq "be") 2
        , expectEq "词频单次" (getCount freq "not") 1
        , expectEq "缺省零" (getCount freq "nothing") 0
        , expectEq "bump" (bump "be" freq M.! "be") 3
        , expectEq "键有序" (M.keys freq) ["be", "not", "or", "to"]
        , expectEq "topCounts 首" (head (topCounts freq)) ("be", 2)
        , expectEq "合并" (mergeCounts (buildCounts ["a"]) (buildCounts ["a", "b"]))
                     (M.fromList [("a", 2), ("b", 1)])
        ]
    s2 <- runSuite "Set"
        [ expectEq "去重升序" (dedup [3, 1, 2, 1]) [1, 2, 3]
        , expectEq "空表" (dedup ([] :: [Int])) []
        , expectEq "交集" (common [1, 2, 3] [2, 3, 4]) [2, 3]
        , expectEq "交集空" (common [1] [2]) ([] :: [Int])
        , expectEq "并集" (eitherOf [1, 2] [2, 3]) [1, 2, 3]
        , expectEq "差集" (diff [1, 2, 3] [2]) [1, 3]
        ]
    s3 <- runSuite "Foldable/Traversable"
        [ expectEq "求和" (sumValues freq) 6
        , expectEq "M.map" (doubleAll (M.fromList [("x", 1)])) (M.fromList [("x", 2)])
        , expectEq "全过" (validateAll (M.fromList [("a", 1), ("b", 2)]))
                      (Just (M.fromList [("a", 1), ("b", 2)]))
        , expectEq "有零败" (validateAll (M.fromList [("a", 1), ("b", 0)])) Nothing
        , expectEq "firstLast" (firstLast [1, 2, 3 :: Int]) (Just 1, Just 3)
        , expectEq "firstLast 空" (firstLast ([] :: [Int])) (Nothing, Nothing)
        ]
    unless (s1 && s2 && s3) exitFailure
    putStrLn "==== 11 结束 ===="
