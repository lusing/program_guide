-- 18 测试套件
{-# LANGUAGE TemplateHaskell #-}

module Main (main) where

import Ch18
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
    s1 <- runSuite "TH 与 Generics"
        [ expectEq "表达式拼接" answer 42
        , expectEq "typed 拼接" typedAnswer 42
        , expectEq "reify Maybe" maybeCons 2
        , expectEq "lift 平方表" compileTimeTable [1, 4, 9, 16, 25, 36, 49, 64]
        , expectEq "名字基名" (nameBaseOf 'recTypeName) "recTypeName"
        , expectEq "Generics 类型名" (recTypeName (Rec 0 "")) "Rec"
        , expectEq "Generics 与 Show 共存" (show (Rec 1 "x")) "Rec {ra = 1, rb = \"x\"}"
        ]
    unless s1 exitFailure
    putStrLn "==== 18 结束 ===="
