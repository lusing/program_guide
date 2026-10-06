-- 10 测试套件：数独求解器（书5）——定律 + 定例 + 求解正确性
module Main (main) where

import Ch10
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
    let m3 :: Matrix Int
        m3 = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
        m9 :: Matrix Int
        m9 = [[10 * r + c | c <- [1 .. 9]] | r <- [1 .. 9]]
    s1 <- runSuite "视图函数定律（书5.2；boxs 对合只在 n²×n² 形状上成立）"
        [ expectTrue "rows 恒等" (rows m3 == m3)
        , expectTrue "cols 对合（任意形状）" (cols (cols m3) == m3)
        , expectTrue "cols 对合 9×9" (cols (cols m9) == m9)
        , expectTrue "boxs 对合 9×9" (boxs (boxs m9) == m9)
        , expectEq "group 三三分组" (group "abcdefghi") ["abc", "def", "ghi"]
        , expectEq "ungroup . group = id" (ungroup (group "abcdefghi")) "abcdefghi"
        , expectEq "boxs 首行 = 第一个宫的首行" (row1 (boxs m9)) [11, 12, 13, 21, 22, 23, 31, 32, 33]
        ]
    s2 <- runSuite "笛卡尔积与剪枝（书5.3）"
        [ expectEq "cp 书例长度" (length (cp [[1, 2, 3 :: Int], [2], [1, 3]])) 6
        , expectTrue "cp 书例成员" ([1, 2, 1 :: Int] `elem` cp [[1, 2, 3], [2], [1, 3]])
        , expectEq "pruneRow 书例一"
            (pruneRow [['6'], ['1', '2'], ['3'], ['1', '3', '4'], ['5', '6']])
            [['6'], ['1', '2'], ['3'], ['1', '4'], ['5']]
        , expectEq "pruneRow 书例二（剪出空格子 = 死路信号）"
            (pruneRow [['6'], ['3', '6'], ['3'], ['1', '3', '4'], ['4']])
            [['6'], [], ['3'], ['1'], ['4']]
        , expectEq "choices 已定格不变" (firstCell (choices ["5..", ".7.", "..9"])) "5"
        , expectEq "choices 空格得全候选" (secondCell (choices ["5..", ".7.", "..9"])) digits
        , expectTrue "prune 之后安全" (safe (prune (choices example)))
        ]
    let sols = solve example
    s3 <- runSuite "求解器（书5.4）"
        [ expectEq "唯一解" (length sols) 1
        , expectTrue "解有效" (all valid sols)
        , expectEq "解的第一行" (case sols of (s : _) -> row1 s; [] -> "") "534678912"
        , expectTrue "解尊重已填数字" (case sols of (s : _) -> givensOK example s; [] -> False)
        ]
    unless (s1 && s2 && s3) exitFailure
    putStrLn "==== 10 结束 ===="
  where
    row1 (r : _) = r
    row1 [] = []
    firstCell (r : _) = cell1 r
    firstCell [] = ""
    cell1 (c : _) = c
    cell1 [] = ""
    secondCell (r : _) = cell2 r
    secondCell [] = []
    cell2 (_ : c : _) = c
    cell2 _ = []
    givensOK g s = and (zipWith rowOK g s)
    rowOK given sol = and (zipWith ok given sol)
      where
        ok '.' _ = True
        ok d c = d == c
