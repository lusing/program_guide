-- MiniLang 测试：解析层（字符串→AST）/ 求值层（程序→值）/ 错误层 / 性质层
module Main (main) where

import Ast
import Control.Monad (unless)
import Data.Bits (shiftL, shiftR, xor)
import Data.Word (Word64)
import Eval (runProgram)
import Parser (parseMini)
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

-- 求值辅助：跑 MiniLang 源码 → Either String Value
evalOf :: String -> IO (Either String Value)
evalOf src = case parseMini "test" src of
    Left err -> pure (Left ("解析错误: " ++ show err))
    Right e  -> runProgram e

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    -- ── 解析层 ──
    s1 <- runSuite "解析层" $
        [ expectEq "优先级" (parseExpr "1 + 2 * 3")
            (Right (EBin Add (EInt 1) (EBin Mul (EInt 2) (EInt 3))))
        , expectEq "左结合减" (parseExpr "10 - 2 - 3")
            (Right (EBin Sub (EBin Sub (EInt 10) (EInt 2)) (EInt 3)))
        , expectEq "布尔短路键" (parseExpr "a && b || c")
            (Right (EBin Or (EBin And (EVar "a") (EVar "b")) (EVar "c")))
        , expectEq "lambda" (parseExpr "\\x -> x + 1")
            (Right (ELam "x" (EBin Add (EVar "x") (EInt 1))))
        , expectEq "let 结构" (parseExpr "let x = 5 in x")
            (Right (ELet "x" (EInt 5) (EVar "x")))
        , expectEq "if 结构" (parseExpr "if 1 < 2 then 3 else 4")
            (Right (EIf (EBin Lt (EInt 1) (EInt 2)) (EInt 3) (EInt 4)))
        , expectEq "应用左结合" (parseExpr "f a b")
            (Right (EApp (EApp (EVar "f") (EVar "a")) (EVar "b")))
        , expectEq "序列" (parseExpr "1; 2")
            (Right (ESeq (EInt 1) (EInt 2)))
        , expectTrue "烂输入 Left" (either (const True) (const False) (parseExpr "let 1 ="))
        , expectTrue "关键字不当变量" (either (const True) (const False) (parseExpr "in"))
        , expectEq "lets 是合法标识符" (parseExpr "let s = lets in s")
            (Right (ELet "s" (EVar "lets") (EVar "s")))
        ]
    -- ── 求值层 ──
    r1 <- evalOf "1 + 2 * 3"
    r2 <- evalOf "(1 + 2) * 3"
    r3 <- evalOf "let x = 5 in x * x"
    r4 <- evalOf "let x = 1 in let x = 2 in x"        -- 遮蔽
    r5 <- evalOf "let add = \\x -> \\y -> x + y in add 3 4"
    r6 <- evalOf "let fact = \\n -> if n <= 1 then 1 else n * fact (n - 1) in fact 10"
    r7 <- evalOf "let fib = \\n -> if n < 2 then n else fib (n-1) + fib (n-2) in fib 15"
    r8 <- evalOf "\"abc\" + \"def\""
    r9 <- evalOf "strlen \"MiniLang\""
    r10 <- evalOf "abs (0 - 9)"
    r11 <- evalOf "if 2 < 1 then 100 else 200"
    r12 <- evalOf "1; 2; 3"
    r13 <- evalOf "let x = 10 in let f = \\y -> x + y in let x = 0 in f 5"   -- 词法作用域！
    r14 <- evalOf "max 3 9"
    r15 <- evalOf "min 3 9"
    s2 <- runSuite "求值层"
        [ expectEq "优先级" r1 (Right (VInt 7))
        , expectEq "括号" r2 (Right (VInt 9))
        , expectEq "let" r3 (Right (VInt 25))
        , expectEq "遮蔽取内层" r4 (Right (VInt 2))
        , expectEq "柯里化" r5 (Right (VInt 7))
        , expectEq "递归 fact" r6 (Right (VInt 3628800))
        , expectEq "递归 fib" r7 (Right (VInt 610))
        , expectEq "字符串拼接" r8 (Right (VStr "abcdef"))
        , expectEq "strlen" r9 (Right (VInt 8))
        , expectEq "abs" r10 (Right (VInt 9))
        , expectEq "if 分支" r11 (Right (VInt 200))
        , expectEq "序列取末值" r12 (Right (VInt 3))
        , expectEq "闭包是词法作用域" r13 (Right (VInt 15))
        , expectEq "max" r14 (Right (VInt 9))
        , expectEq "min" r15 (Right (VInt 3))
        ]
    -- ── 错误层 ──
    e1 <- evalOf "nope"
    e2 <- evalOf "1 + \"a\""
    e3 <- evalOf "1 / 0"
    e4 <- evalOf "\"a\" < 1"
    e5 <- evalOf "(\\x -> x + 1) true"
    s3 <- runSuite "错误层"
        [ expectTrue "未绑定" (isLeftWith "未绑定" e1)
        , expectTrue "类型错" (isLeftWith "类型不配" e2)
        , expectTrue "除零" (isLeftWith "除数为零" e3)
        , expectTrue "比较类型错" (isLeftWith "类型不配" e4)
        , expectTrue "参数类型错" (isLeftWith "类型不配" e5)
        ]
    -- ── 性质层：随机表达式，求值要么 Right、要么 Left 带信息（永不崩溃）且可复现 ──
    props <- mapM propRun [1 .. 30 :: Int]
    s4 <- runSuite "性质层"
        [ expectTrue "30 个随机表达式全部确定" (and props)
        ]
    unless (s1 && s2 && s3 && s4) exitFailure
    putStrLn "==== 24 结束 ===="
  where
    parseExpr = parseMini "test"
    isLeftWith kw (Left msg) = take (length kw) msg == kw
    isLeftWith _  (Right _)  = False

    -- 随机算术表达式：xorshift 种子 = 行号 → 生成 → 两次求值结果一致
    propRun :: Int -> IO Bool
    propRun i = do
        let src = genExpr 3 (fromIntegral i)
        a <- evalOf src
        b <- evalOf src
        pure (show a == show b)      -- Value 含函数字段没有 Eq——用 show 比确定性

    genExpr :: Int -> Word64 -> String
    genExpr depth seed
      | depth <= 0 = show (1 + fromIntegral (step seed `shiftR` 8) `mod` 20 :: Integer)
      | otherwise =
          let op = [" + ", " - ", " * "] !! (fromIntegral (step seed `shiftR` 4) `mod` 3 :: Int)
              l = genExpr (depth - 1) (step seed)
              r = genExpr (depth - 1) (step (step seed))
          in "(" ++ l ++ op ++ r ++ ")"

    step :: Word64 -> Word64
    step x0 = x3 * 2685821657736338717
      where
        x1 = x0 `xor` (x0 `shiftR` 12)
        x2 = x1 `xor` (x1 `shiftL` 25)
        x3 = x2 `xor` (x2 `shiftR` 27)
