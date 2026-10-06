-- 21 手写解析器组合子（书11）：newtype Parser、组合子、表达式文法、show 往返
-- 运行：ghc -v0 --make main.hs -o 21.exe && ./21.exe
module Main (main) where

import Ch21
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    putStrLn "==[ 21 · 手写解析器组合子 ]=="

    -- ═══ 21.1 基本组合子实录
    putStrLn ("applyP (string \"hell\") \"hello\" = " ++ show (applyP (string "hell") "hello"))
    putStrLn ("applyP lowls \"isUpper\"  = " ++ show (applyP lowls "isUpper"))
    putStrLn ("applyP lowls \"Upper\"    = " ++ show (applyP lowls "Upper"))

    -- ═══ 21.2 选择陷阱（书11.3）：wrong 被 digit 抢跑，best 提公共前缀
    putStrLn ("applyP wrong \"1+2\" = " ++ show (applyP wrong "1+2"))
    putStrLn ("applyP best \"1+2\"  = " ++ show (applyP best "1+2"))
    putStrLn ("applyP best \"1+2+3\" = " ++ show (applyP best "1+2+3"))

    -- ═══ 21.3 自然数/整数：负号返回函数的技巧
    putStrLn ("parseFirst natural \" 42xyz\" = " ++ show (parseFirst natural " 42xyz"))
    putStrLn ("parseFirst integer \"-34\"    = " ++ show (parseFirst integer "-34"))

    -- ═══ 21.4 四则表达式：优先级 + 左结合
    mapM_ (\s -> putStrLn ("runExpr " ++ show s ++ " = " ++ show (runExpr s)))
        ["1+2*3", "(1+2)*3", "6-2-3", "8/2/2", "10-4-3", "2*(3+4)", "1+2*(30-4*6/3)"]

    -- ═══ 21.5 show 是解析之逆：往返律 parse (show e) == e
    let trees =
            [ Con 42
            , Bin Plus (Con 1) (Con 2)
            , Bin Mul (Bin Plus (Con 1) (Con 2)) (Con 3)      -- (1 + 2) * 3
            , Bin Plus (Con 1) (Bin Mul (Con 2) (Con 3))      -- 1 + 2 * 3
            , Bin Minus (Bin Minus (Con 6) (Con 2)) (Con 3)    -- 6 - 2 - 3
            , Bin Div (Bin Div (Con 8) (Con 2)) (Con 2)        -- 8 / 2 / 2
            ]
    mapM_ (\e -> putStrLn ("show " ++ show (show e) ++ " → 回读 " ++ show (readBack e))) trees

    -- ═══ 21.6 自检
    check "识别字符串" (applyP (string "hell") "hello") [((), "o")]
    check "小写串" (applyP lowls "isUpper") [("is", "Upper")]
    check "空小写串" (applyP lowls "Upper") [("", "Upper")]
    check "wrong 抢跑" (applyP wrong "1+2") [(1, "+2")]
    check "best 全吃" (applyP best "1+2+3") [(6, "")]
    check "natural 跳空白" (parseFirst natural " 42xyz") (Just (42, "xyz"))
    check "integer 负号" (parseFirst integer "-34") (Just (-34, ""))
    check "优先级" (runExpr "1+2*3") (Right 7)
    check "括号覆盖" (runExpr "(1+2)*3") (Right 9)
    check "左结合减" (runExpr "6-2-3") (Right 1)
    check "左结合除" (runExpr "8/2/2") (Right 2)
    check "嵌套" (runExpr "2*(3+4)") (Right 14)
    check "语法错（部分解析）" (runExpr "1+") (Left "语法错误：多余的输入 \"+\"")
    check "语法错（全失败）" (runExpr "x") (Left "语法错误：无法解析")
    check "除零" (runExpr "1/0") (Left "除零")
    check "多余输入" (runExpr "1)2") (Left "语法错误：多余的输入 \")2\"")
    check "show 最少括号" (show (Bin Mul (Bin Plus (Con 1) (Con 2)) (Con 3))) "(1 + 2) * 3"
    check "show 免括号" (show (Bin Plus (Con 1) (Bin Mul (Con 2) (Con 3)))) "1 + 2 * 3"
    check "往返律" (all roundTrip trees) True

    putStrLn "==== 21 结束 ===="
  where
    readBack e = case parseFirst exprP (show e) of
        Just (e', "") -> e'
        _ -> Con 0 -- 不会发生（往返律成立），给个底防止 partial
    roundTrip e = readBack e == e

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
    | actual == expected = return ()
    | otherwise =
        error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
