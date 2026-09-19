-- 03 测试套件
module Main (main) where

import Ch03
import Control.Monad (unless)
import Data.Ratio ((%))
import System.Exit (exitFailure)
import System.IO (hSetEncoding, stderr, stdout, utf8)

data Case = Case { name :: String, ok :: Bool, detail :: String }

expectEq :: (Eq a, Show a) => String -> a -> a -> Case
expectEq n got want
  | got == want = Case n True ""
  | otherwise   = Case n False (n ++ ": 得到 " ++ show got ++ " 期望 " ++ show want)

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
    s1 <- runSuite "整型边界"
        [ expectEq "20! 不溢出" (factInt 20) 2432902008176640000
        , expectTrue "21! 溢出为负" (factInt 21 < 0)
        , expectEq "Integer 无界" (factInteger 21) 51090942171709440000
        , expectEq "Integer 更大" (factInteger 25) 15511210043330985984000000
        ]
    s2 <- runSuite "整除家族"
        [ expectEq "divMod 正数" (divMod 7 2) (3, 1)
        , expectEq "quotRem 正数" (quotRem 7 2) (3, 1)
        , expectEq "divMod 负被除数" (divMod (-7) 2) (-4, 1)
        , expectEq "quotRem 负被除数" (quotRem (-7) 2) (-3, -1)
        , expectEq "divMod 负除数" (divMod 7 (-2)) (-4, -1)
        , expectEq "quotRem 负除数" (quotRem 7 (-2)) (-3, 1)
        ]
    s3 <- runSuite "转换与精度"
        [ expectEq "count 走 fromIntegral" (count "haskell") 7.0
        , expectEq "avg" (avg [1, 2, 3]) 2.0
        , expectEq "readMaybe 好输入" (safeRead "42") (Just 42)
        , expectEq "readMaybe 坏输入" (safeRead "4x") Nothing
        , expectEq "readMaybe 空串" (safeRead "") Nothing
        , expectEq "Rational 精确" half (1 % 2)
        , expectEq "字面量多态 Int" (doubleIt 21 :: Int) 42
        , expectEq "字面量多态 Double" (doubleIt 2.5 :: Double) 5.0
        ]
    unless (s1 && s2 && s3) exitFailure
    putStrLn "==== 03 结束 ===="
