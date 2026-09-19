-- 07 代数数据类型：和×积、记录语法、newtype、递归数据、Maybe/Either
-- 运行：ghc -v0 --make main.hs -o 07.exe && ./07.exe
module Main (main) where

import Ch07
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    -- ═══ 07.1 和类型：模式匹配分派
    putStrLn "==[ 07 · 代数数据类型 ]=="
    let shapes = [Circle 1, Rect 2 3]
    mapM_ (\s -> putStrLn (show s ++ " 面积 " ++ show (area s) ++ " 周长 " ++ show (perimeter s))) shapes

    -- ═══ 07.2 Ord 派生序：构造子声明序 Circle < Rect
    putStrLn ("sort [Rect 9 9, Circle 5] = " ++ show (sortShapes [Rect 9 9, Circle 5]))
    putStrLn ("maximum [Circle 1, Circle 3, Circle 2] = " ++ show (maximum [Circle 1, Circle 3, Circle 2]))

    -- ═══ 07.3 记录语法与更新
    let alice = Person { pName = "Alice", pAge = 30 }
        older = birthday alice
    putStrLn (show alice ++ " → " ++ show older)    -- alice 不变（不可变值）

    -- ═══ 07.4 递归数据 IntList
    let il = fromList [1, 2, 3]
    putStrLn ("fromList [1,2,3] = " ++ show il)
    putStrLn ("sumIL = " ++ show (sumIL il) ++ "  lenIL = " ++ show (lenIL il))

    -- ═══ 07.5 二叉搜索树
    let t = foldl insertT Leaf [5, 3, 8, 1, 4, 9, 2, 6, 7]
    putStrLn ("中序遍历 = " ++ show (inOrder t))            -- 恰好升序
    putStrLn ("size = " ++ show (sizeT t) ++ "  height = " ++ show (heightT t))

    -- ═══ 07.6 Maybe / Either
    putStrLn ("safeDiv 10 2 = " ++ show (safeDiv 10 2))
    putStrLn ("safeDiv 10 0 = " ++ show (safeDiv 10 0))
    putStrLn ("annotate 10 0 = " ++ show (annotate 10 0))

    -- ═══ 07.7 自检
    check "面积圆" (area (Circle 1)) pi
    check "面积矩形" (area (Rect 2 3)) 6.0
    check "Ord 构造子序" (compare (Circle 1) (Rect 1 1)) LT
    check "记录更新" (pAge (birthday alice)) 31
    check "原值不变" (pAge alice) 30
    check "sumIL" (sumIL (fromList [1, 2, 3])) 6
    check "中序有序" (inOrder t) [1 .. 9]
    check "树大小" (sizeT t) 9
    check "重复插入" (sizeT (insertT t 5)) 9
    check "safeDiv 零" (safeDiv 10 0) Nothing
    check "annotate 左" (annotate 10 0) (Left "除数为零")

    putStrLn "==== 07 结束 ===="

sortShapes :: [Shape] -> [Shape]
sortShapes = foldr insertBy' []
  where
    insertBy' x [] = [x]
    insertBy' x (y:ys) | x <= y    = x : y : ys
                       | otherwise = y : insertBy' x ys

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
