-- 21 测试套件：手写解析器组合子（书11）
module Main (main) where

import Ch21
import Control.Monad (unless)
import System.Exit (exitFailure)
import System.IO (hSetEncoding, stderr, stdout, utf8)

data Case = Case {name :: String, ok :: Bool, detail :: String}

expectEq :: (Eq a, Show a) => String -> a -> a -> Case
expectEq n got want
    | got == want = Case n True ""
    | otherwise = Case n False (n ++ ": 得到 " ++ show got ++ " 期望 " ++ show want)

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
    s1 <- runSuite "基本组合子（书11.2/11.3）"
        [ expectEq "string 识别前缀" (applyP (string "hell") "hello") [((), "o")]
        , expectEq "失败是空解" (applyP (string "hell") "world") []
        , expectEq "many 小写串" (applyP lowls "isUpper") [("is", "Upper")]
        , expectEq "many 零次" (applyP lowls "Upper") [("", "Upper")]
        , expectEq "wrong 被 digit 抢跑" (applyP wrong "1+2") [(1, "+2")]
        , expectEq "best 提公共前缀" (applyP best "1+2") [(3, "")]
        , expectEq "best 链式" (applyP best "1+2+3") [(6, "")]
        , expectEq "natural 跳空白" (parseFirst natural " 42xyz") (Just (42, "xyz"))
        , expectEq "integer 负号" (parseFirst integer "-34") (Just (-34, ""))
        , expectEq "integer 正号非法" (parseFirst integer "+4") Nothing
        ]
    s2 <- runSuite "表达式文法（书11.4）"
        [ expectEq "优先级" (runExpr "1+2*3") (Right 7)
        , expectEq "括号覆盖" (runExpr "(1+2)*3") (Right 9)
        , expectEq "左结合减" (runExpr "6-2-3") (Right 1)
        , expectEq "左结合除" (runExpr "8/2/2") (Right 2)
        , expectEq "嵌套" (runExpr "2*(3+4)") (Right 14)
        , expectEq "复杂嵌套" (runExpr "1+2*(30-4*6/3)") (Right 45)
        , expectEq "空白自由" (runExpr "1 + 2 * 3") (Right 7)
        , expectEq "部分解析报错" (runExpr "1+") (Left "语法错误：多余的输入 \"+\"")
        , expectEq "全失败" (runExpr "x") (Left "语法错误：无法解析")
        , expectEq "除零" (runExpr "1/0") (Left "除零")
        ]
    let trees =
            [ Con 42
            , Bin Plus (Con 1) (Con 2)
            , Bin Mul (Bin Plus (Con 1) (Con 2)) (Con 3)
            , Bin Plus (Con 1) (Bin Mul (Con 2) (Con 3))
            , Bin Minus (Bin Minus (Con 6) (Con 2)) (Con 3)
            , Bin Div (Bin Div (Con 8) (Con 2)) (Con 2)
            , Bin Div (Con 7) (Con 2)
            , Bin Mul (Con 2) (Bin Div (Con 9) (Con 3))
            ]
        readBack e = case parseFirst exprP (show e) of
            Just (e', "") -> Just e'
            _ -> Nothing
    s3 <- runSuite "show 往返（书11.5）"
        [ expectTrue "往返律 parse (show e) == e" (all (\e -> readBack e == Just e) trees)
        , expectEq "最少括号：子表达式同级加括" (show (Bin Mul (Bin Plus (Con 1) (Con 2)) (Con 3))) "(1 + 2) * 3"
        , expectEq "免括号：高优先级在右" (show (Bin Plus (Con 1) (Bin Mul (Con 2) (Con 3)))) "1 + 2 * 3"
        , expectEq "同级右子要加括（左结合语义）" (show (Bin Mul (Con 2) (Bin Div (Con 9) (Con 3)))) "2 * (9 / 3)"
        , expectEq "左结合不加括" (show (Bin Minus (Bin Minus (Con 6) (Con 2)) (Con 3))) "6 - 2 - 3"
        , expectEq "同根右子要加括" (show (Bin Minus (Con 6) (Bin Minus (Con 2) (Con 3)))) "6 - (2 - 3)"
        ]
    unless (s1 && s2 && s3) exitFailure
    putStrLn "==== 21 结束 ===="
