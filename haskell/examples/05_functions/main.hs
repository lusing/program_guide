-- 05 函数：柯里化/部分应用、组合与 $、sections、高阶函数、自定义运算符
-- 运行：ghc -v0 --make main.hs -o 05.exe && ./05.exe
module Main (main) where

import Ch05
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    -- ═══ 05.1 柯里化与部分应用
    putStrLn "==[ 05 · 函数 ]=="
    putStrLn ("add 3 4   = " ++ show (add 3 4))
    putStrLn ("inc 41    = " ++ show (inc 41))          -- add 1 41 == 42
    putStrLn ("map inc [1,2,3] = " ++ show (map inc [1, 2, 3]))
    putStrLn ("mul2 21   = " ++ show (mul2 21))

    -- ═══ 05.2 组合链：negate . sq . (+1) 4 = -(5^2) = -25
    putStrLn ("pipeline 4 = " ++ show (pipeline 4))

    -- ═══ 05.3 $ 省括号：show (sq (sq 3)) == show $ sq $ sq 3
    putStrLn ("show $ sq $ sq 3 = " ++ (show $ sq $ sq 3))

    -- ═══ 05.4 sections
    putStrLn ("doubleAll [1,2,3]   = " ++ show (doubleAll [1, 2, 3]))
    putStrLn ("positives [-1,2,-3] = " ++ show (positives [-1, 2, -3]))
    putStrLn ("decrementAll [1,2]  = " ++ show (decrementAll [1, 2]))

    -- ═══ 05.5 高阶函数
    putStrLn ("applyTwice mul2 1 = " ++ show (applyTwice mul2 1))
    putStrLn ("composeAll [inc, mul2, inc] 3 = " ++ show (composeAll [inc, mul2, inc] 3))
    putStrLn ("totalNegatives [1,-2,3,-4] = " ++ show (totalNegatives [1, -2, 3, -4]))

    -- ═══ 05.6 自定义中缀：<+> 逐元素加
    putStrLn ("[1,2,3] <+> [10,20,30] = " ++ show ([1, 2, 3] <+> [10, 20, 30]))

    -- ═══ 05.7 lambda（匿名函数就地写）
    let bigSquares = filter (\x -> sq x > 10) [1 .. 5]
    putStrLn ("filter (\\x -> sq x > 10) [1..5] = " ++ show bigSquares)

    -- ═══ 05.8 自检
    check "inc" (inc 41) 42
    check "pipeline" (pipeline 4) (-25)
    check "组合可读序" (composeAll [inc, mul2] 5) (inc (mul2 5))
    check "doubleAll" (doubleAll [1, 2, 3]) [2, 4, 6]
    check "subtract 区别" (decrementAll [1, 2]) [0, 1]
    check "applyTwice" (applyTwice (+ 3) 1) 7
    check "点自由" (totalNegatives [1, -2, 3, -4]) 2
    check "自定义中缀" ([1, 2] <+> [3, 4]) [4, 6]
    check "短列表 zipWith 截断" ([1, 2, 3, 4] <+> [10]) [11]

    putStrLn "==== 05 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
