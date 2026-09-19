-- 15 解析器组合子：词法包装、try 回溯、运算符优先级表、错误消息
-- 运行：ghc -v0 --make main.hs -o 15.exe && ./15.exe
module Main (main) where

import Ch15
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    -- ═══ 15.1 表达式求值一条龙
    putStrLn "==[ 15 · 解析器组合子 ]=="
    putStrLn ("calc \"1 + 2 * 3\"        = " ++ show (calc "1 + 2 * 3"))        -- 优先级：7
    putStrLn ("calc \"(1 + 2) * 3\"      = " ++ show (calc "(1 + 2) * 3"))      -- 括号：9
    putStrLn ("calc \"10 / 0\"           = " ++ show (calc "10 / 0"))           -- 求值层报错
    putStrLn ("calc \"1 +\"              = " ++ either (const "解析失败") show (calc "1 +"))

    -- ═══ 15.2 AST：解析与求值分离
    putStrLn ("parseExpr \"1+2*3\"       = " ++ show (parseExpr "1+2*3"))

    -- ═══ 15.3 结构化解析
    putStrLn ("parsePair \"count = 42\"  = " ++ show (parsePair "count = 42"))
    putStrLn ("parseKeyValues           = " ++ show (parseKeyValues "a = 1\nb = 2\n"))

    -- ═══ 15.4 解析错误的位置信息
    putStrLn ("错误消息示例 = " ++ either show (const "ok") (parseExpr "1 + * 2"))

    -- ═══ 15.5 自检
    check "优先级" (calc "1 + 2 * 3") (Right 7)
    check "左结合" (calc "10 - 2 - 3") (Right 5)
    check "括号覆盖" (calc "(1 + 2) * 3") (Right 9)
    check "嵌套" (calc "2 * (3 + (4 - 1))") (Right 12)
    check "除零" (calc "10 / 0") (Left "除数为零")
    check "正常除" (calc "7 / 2") (Right 3)
    check "解析失败是 Left" (either (const True) (const False) (calc "1 + * 2")) True
    check "键值对" (parsePair "x = 5") (Right ("x", 5))
    check "键值表" (parseKeyValues "a = 1 b = 2") (Right [("a", 1), ("b", 2)])
    check "键值表失败" (either (const True) (const False) (parseKeyValues "1a = 1")) True

    putStrLn "==== 15 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
