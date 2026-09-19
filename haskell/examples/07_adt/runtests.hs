-- 07 测试套件
module Main (main) where

import Ch07
import Control.Monad (unless)
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
    let t = foldl insertT Leaf [5, 3, 8, 1, 4, 9, 2, 6, 7]
    s1 <- runSuite "和×积与派生"
        [ expectEq "面积" (area (Circle 2)) (pi * 4)
        , expectEq "周长" (perimeter (Rect 2 3)) 10.0
        , expectEq "Eq 派生" (Circle 1 == Circle 1) True
        , expectEq "Ord 构造子序" (compare (Circle 9) (Rect 0 0)) LT
        , expectEq "同构造子按字段" (Circle 2 > Circle 1) True
        ]
    s2 <- runSuite "记录与 newtype"
        [ expectEq "字段访问" (pName (Person "Bob" 3)) "Bob"
        , expectEq "记录更新改字段" (pAge (birthday (Person "Bob" 3))) 4
        , expectEq "记录更新不动名" (pName (birthday (Person "Bob" 3))) "Bob"
        , expectEq "newtype 相等性" (unpack (Age 5)) 5
        ]
    s3 <- runSuite "递归数据"
        [ expectEq "fromList" (fromList [1, 2]) (ICons 1 (ICons 2 INil))
        , expectEq "sumIL" (sumIL (fromList [1, 2, 3, 4])) 10
        , expectEq "lenIL" (lenIL (fromList [])) 0
        , expectEq "中序有序" (inOrder t) [1 .. 9]
        , expectEq "sizeT" (sizeT t) 9
        , expectEq "heightT 平衡" (heightT t) 4
        , expectEq "重复插入幂等" (sizeT (insertT t 5)) 9
        ]
    s4 <- runSuite "Maybe/Either"
        [ expectEq "safeDiv 正常" (safeDiv 10 2) (Just 5)
        , expectEq "safeDiv 零" (safeDiv 10 0) Nothing
        , expectEq "annotate 右" (annotate 10 3) (Right 3)
        , expectEq "annotate 左" (annotate 10 0) (Left "除数为零")
        ]
    unless (s1 && s2 && s3 && s4) exitFailure
    putStrLn "==== 07 结束 ===="
