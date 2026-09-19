-- 15 测试套件
module Main (main) where

import Ch15
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
    s1 <- runSuite "表达式"
        [ expectEq "四则" (calc "1 + 2 * 3") (Right 7)
        , expectEq "左结合减" (calc "10 - 2 - 3") (Right 5)
        , expectEq "左结合除" (calc "100 / 5 / 2") (Right 10)
        , expectEq "括号" (calc "(1 + 2) * 3") (Right 9)
        , expectEq "嵌套" (calc "2 * (3 + (4 - 1))") (Right 12)
        , expectEq "空白无关" (calc "  1+2 ") (Right 3)
        , expectEq "除零 Left" (calc "10 / 0") (Left "除数为零")
        , expectEq "嵌套除零" (calc "5 / (3 - 3)") (Left "除数为零")
        , expectEq "整除" (calc "7 / 2") (Right 3)
        , expectTrue "语法错 Left" (either (const True) (const False) (calc "1 + * 2"))
        , expectTrue "尾随垃圾 Left" (either (const True) (const False) (calc "1 2"))
        ]
    s2 <- runSuite "AST 与结构化"
        [ expectEq "AST 结构" (parseExpr "1+2*3") (Right (Add (Lit 1) (Mul (Lit 2) (Lit 3))))
        , expectEq "AST 减" (parseExpr "9-3") (Right (Sub (Lit 9) (Lit 3)))
        , expectEq "键值对" (parsePair "n = 42") (Right ("n", 42))
        , expectEq "键值表" (parseKeyValues "a = 1\nb = 2\n") (Right [("a", 1), ("b", 2)])
        , expectEq "键值表多条同行" (parseKeyValues "a=1 b=2") (Right [("a", 1), ("b", 2)])
        , expectTrue "键值表坏首字符" (either (const True) (const False) (parseKeyValues "1 = 2"))
        ]
    unless (s1 && s2) exitFailure
    putStrLn "==== 15 结束 ===="
