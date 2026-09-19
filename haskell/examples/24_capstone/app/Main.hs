-- MiniLang 入口：minilang demo（内置演示）/ minilang 文件.ml / 无参进 REPL
module Main (main) where

import Eval (runProgram)
import Parser (parseMini)
import Repl (runRepl)
import System.Environment (getArgs)
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8
    args <- getArgs
    case args of
        []             -> runRepl
        ["demo"]       -> runDemo
        [path]         -> runFile path
        _              -> putStrLn "用法: minilang [demo | 文件.ml]"

-- 内置演示：递归 + 高阶 + 柯里化 + 字符串拼接 + 序列——全部特性一网打尽
demoSource :: String
demoSource = unlines
    [ "let fact = \\n -> if n <= 1 then 1 else n * fact (n - 1) in"
    , "let twice = \\f -> \\x -> f (f x) in"
    , "let apply = \\f -> \\x -> f x in"
    , "print (twice (\\x -> x + 3) 10);"
    , "print (\"fact 10 = \" + str (fact 10));"
    , "print (\"strlen = \" + str (strlen \"MiniLang\"));"
    , "(if 3 < 5 && 2 == 2 then print \"比较成立\" else print \"不可能\");"
    , "apply max 3 9"
    ]

runDemo :: IO ()
runDemo = do
    putStrLn "==[ 24 · MiniLang 演示 ]=="
    runSource "demo" demoSource
    putStrLn "==== 24 结束 ===="

runFile :: FilePath -> IO ()
runFile path = do
    src <- readFile' path
    runSource path src
  where
    readFile' p = do
        c <- readFile p      -- 教学版：演示程序小，惰性读即够用（16 章的坑这里是安全的）
        length c `seq` pure c

runSource :: String -> String -> IO ()
runSource name src = case parseMini name src of
    Left err  -> putStrLn ("解析错误:\n" ++ show err)
    Right ast -> do
        r <- runProgram ast
        case r of
            Left msg  -> putStrLn ("求值错误: " ++ msg)
            Right val -> putStrLn ("⇒ " ++ show val)
