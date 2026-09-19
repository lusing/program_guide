-- 17 测试套件
module Main (main) where

import Ch17
import Control.Exception (IOException, evaluate, throwIO, try)
import Control.Monad (unless)
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
    s1 <- runSuite "Either 纯错误"
        [ expectEq "合法" (parseAge "42") (Right 42)
        , expectEq "零岁" (parseAge "0") (Right 0)
        , expectEq "上界" (parseAge "150") (Right 150)
        , expectEq "超界" (parseAge "151") (Left (OutOfRange 151))
        , expectEq "负数" (parseAge "-1") (Left (OutOfRange (-1)))
        , expectEq "非整数" (parseAge "4x") (Left (NotAnInt "4x"))
        , expectEq "空串" (parseAge "") (Left (NotAnInt ""))
        , expectEq "兜底" (ageOrDefault "zz") 0
        , expectEq "兜底直通" (ageOrDefault "7") 7
        ]
    r1 <- try (readFile "不存在的文件_测试用.txt") :: IO (Either IOException String)
    r2 <- try (evaluate (divideOrThrow 10 0)) :: IO (Either Boom Int)
    r3 <- try (throwIO (Boom "测")) :: IO (Either Boom Int)
    (phase, cleaned) <- runBracketDemo
    s2 <- runSuite "IO 异常与 bracket"
        [ expectTrue "IO 异常捕获" (either (const True) (const False) r1)
        , expectTrue "throw 惰性后引爆" (either (const True) (const False) r2)
        , expectEq "正常除法不炸" (divideOrThrow 9 3) 3
        , expectTrue "throwIO 立即" (either (const True) (const False) r3)
        , expectEq "bracket 阶段" phase "中途失败已捕获"
        , expectEq "bracket 清理" cleaned True
        ]
    unless (s1 && s2) exitFailure
    putStrLn "==== 17 结束 ===="
