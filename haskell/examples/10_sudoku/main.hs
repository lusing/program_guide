-- 10 数独求解器：三视图定律、剪枝、最少选择格搜索（书5）
-- 运行：ghc -v0 --make main.hs -o 10.exe && ./10.exe
module Main (main) where

import Ch10
import System.CPUTime (getCPUTime)
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    putStrLn "==[ 10 · 数独求解器 ]=="

    -- ═══ 10.1 三个视图函数的定律（对合）：转置两次、取宫两次都回到原样
    putStrLn ("cols (cols m) == m   : " ++ show (cols (cols example) == example))
    putStrLn ("boxs (boxs m) == m   : " ++ show (boxs (boxs example) == example))

    -- ═══ 10.2 笛卡尔积：书上的小例子——6 种填法
    putStrLn ("cp [[1,2,3],[2],[1,3]] = " ++ show (cp [[1, 2, 3 :: Int], [2], [1, 3]]))

    -- ═══ 10.3 剪枝一行的书上实例：已定 6/3 从候选中剔除
    putStrLn ("pruneRow [[6],[1,2],[3],[1,3,4],[5,6]] = "
                ++ show (pruneRow [['6'], ['1', '2'], ['3'], ['1', '3', '4'], ['5', '6']]))

    -- ═══ 10.4 第一版为什么不可行：61 个空格 → 9^61 个棋盘
    putStrLn ("9^61 = " ++ show (9 ^ (61 :: Int)) ++ "  ← solve1 要过滤的棋盘数")

    -- ═══ 10.5 最终求解器：解谜题 + 计时
    putStrLn "-- 例题："
    mapM_ putStrLn example
    t0 <- getCPUTime
    let sols = solve example
    t1 <- getCPUTime
    putStrLn ("解的个数: " ++ show (length sols))
    case sols of
        (s : _) -> do
            putStrLn "-- 解："
            mapM_ putStrLn s
        [] -> putStrLn "（无解）"
    putStrLn ("solve 用时: " ++ show (fromIntegral (t1 - t0) / 1e9 :: Double) ++ " 毫秒（CPU）")

    -- ═══ 10.6 自检
    case sols of
        (s : _) -> do
            check "解有效" (valid s) True
            check "解尊重已填数字" (and (zipWith agree example s)) True
            check "解的第一行" (firstRow s) "534678912"
        [] -> check "有解" False True
    check "cols 对合" (cols (cols example) == example) True
    check "boxs 对合" (boxs (boxs example) == example) True
    check "cp 六种填法" (length (cp [[1, 2, 3 :: Int], [2], [1, 3]])) 6
    check "pruneRow 书例" (pruneRow [['6'], ['1', '2'], ['3'], ['1', '3', '4'], ['5', '6']]) [['6'], ['1', '2'], ['3'], ['1', '4'], ['5']]

    putStrLn "==== 10 结束 ===="
  where
    agree given sol = and (zipWith ok given sol)
      where
        ok '.' _ = True
        ok d c = d == c
    firstRow m = case m of
        (r : _) -> r
        [] -> ""

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
    | actual == expected = return ()
    | otherwise =
        error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
