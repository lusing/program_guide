-- 05 测试套件
module Main (main) where

import Ch05
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
    s1 <- runSuite "柯里化与组合"
        [ expectEq "部分应用" (map inc [0, 1, 2]) [1, 2, 3]
        , expectEq "组合顺序" (pipeline 4) (-25)
        , expectEq "组合 vs 手写" (pipeline x0) (negate (sq (x0 + 1)))
        , expectEq "组合单位元" (composeAll [] 42) 42
        , expectEq "composeAll 多级" (composeAll [inc, mul2, inc] 3) 9
        ]
    s2 <- runSuite "sections 与高阶"
        [ expectEq "doubleAll" (doubleAll [1, 2, 3]) [2, 4, 6]
        , expectEq "positives" (positives [-1, 2, -3, 0]) [2]
        , expectEq "subtract 1" (decrementAll [10, 20]) [9, 19]
        , expectEq "applyTwice" (applyTwice mul2 1) 4
        , expectEq "applyTwice 泛型" (applyTwice (++ "!") "hi") "hi!!"
        , expectEq "点自由" (totalNegatives [-1, -2, 3]) 2
        ]
    s3 <- runSuite "自定义运算符"
        [ expectEq "逐元素加" ([1, 2] <+> [3, 4]) [4, 6]
        , expectEq "截断到短的" ([1, 2, 3] <+> [10]) [11]
        , expectEq "左结合同级" ([1, 2] <+> [3, 4] <+> [5, 6]) [9, 12]
        ]
    unless (s1 && s2 && s3) exitFailure
    putStrLn "==== 05 结束 ===="
  where
    x0 :: Int
    x0 = 4
