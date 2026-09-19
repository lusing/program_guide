-- 08 测试套件
module Main (main) where

import Ch08
import Control.Monad (unless)
import Data.Ratio ((%))
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
    s1 <- runSuite "class/instance"
        [ expectEq "Color 分派" (map describe [Red, Green, Blue]) ["红", "绿", "蓝"]
        , expectEq "Bool 分派" (describe True) "真"
        , expectEq "默认实现" (describeTwice Blue) "蓝，蓝"
        , expectEq "实例间无干扰" (describe Green /= describe True) True
        ]
    s2 <- runSuite "超类与 MINIMAL"
        [ expectEq "默认 label" (label A) "A"
        , expectEq "超类 Eq" (A == A) True
        , expectEq "volume" (volume (Box 2)) 8.0
        , expectEq "halfVolume 默认" (halfVolume (Box 2)) 4.0
        ]
    s3 <- runSuite "newtype 派生与约束多态"
        [ expectEq "newtype 加法" (Count 2 + Count 3) (Count 5)
        , expectEq "newtype 乘法" (Count 4 * Count 5) (Count 20)
        , expectEq "newtype Ord" (maximum [Count 1, Count 9, Count 4]) (Count 9)
        , expectEq "scaleIt Int" (scaleIt (21 :: Int)) "42"
        , expectEq "scaleIt Count" (scaleIt (Count 21)) "42"
        , expectEq "halfOf Double" (halfOf (5 :: Double)) 2.5
        , expectEq "halfOf Rational" (halfOf (1 :: Rational)) (1 % 2)
        ]
    unless (s1 && s2 && s3) exitFailure
    putStrLn "==== 08 结束 ===="
