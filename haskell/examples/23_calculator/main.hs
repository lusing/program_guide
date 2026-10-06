-- 23 等式计算器（书12）：点自由定律的自动证明器
-- 运行：ghc -v0 --make main.hs -o 23.exe && ./23.exe
module Main (main) where

import Ch23
import System.IO (hSetEncoding, stderr, stdout, utf8)

-- 12.1 的定律集（书原样）
laws12 :: [String]
laws12 =
    [ "defn filter: filter p = concat . map (box p)"
    , "defn box: box p = if p one nil"
    , "if after dot: if p f g . h = if (p . h) (f . h) (g . h)"
    , "dot after if: h . if p f g = if p (h . f) (h . g)"
    , "nil constant: nil . f = nil"
    , "map after nil: map f . nil = nil"
    , "map after one: map f . one = one . f"
    , "map after concat: map f . concat = concat . map (map f)"
    , "map functor: map f . map g = map (f . g)"
    , "map functor: map id = id"
    ]

-- 12.1 的 iterate 定律集（演示"定义最后用"如何避免无穷回归）
lawsIter :: [String]
lawsIter =
    [ "defn iterate: iterate f = cons . fork id (iterate . f)"
    , "head after cons: head . cons = fst"
    , "fst after fork: fst . fork f g = f"
    ]

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    putStrLn "==[ 23 · 等式计算器 ]=="
    putStrLn "-- 定律从左到右单向应用；简单定律优先、定义垫底（防中间表达式膨胀）。"

    -- ═══ 23.1 12.1 的招牌计算：filter p . map f 的全自动简化
    putStrLn "\n-- 计算 1：simplify \"filter p . map f\"（12.1 定律集）"
    case simplify laws12 "filter p . map f" of
        Right calc -> putStr (show calc)
        Left err -> putStrLn ("解析失败: " ++ err)

    -- ═══ 23.2 证明：filter p . map f = map f . filter (p . f)（09 章手推定律的自动化）
    putStrLn "\n-- 计算 2：prove \"filter p . map f = map f . filter (p . f)\""
    case prove laws12 "filter p . map f = map f . filter (p . f)" of
        Right calc -> putStr (show calc)
        Left err -> putStrLn ("解析失败: " ++ err)

    -- ═══ 23.3 定律排序的功劳：head . iterate f 直达 id，不陷入无穷展开
    putStrLn "\n-- 计算 3：simplify \"head . iterate f\"（定义最后用，避免无穷回归）"
    case simplify lawsIter "head . iterate f" of
        Right calc -> putStr (show calc)
        Left err -> putStrLn ("解析失败: " ++ err)

    -- ═══ 23.4 自检
    let finalOf1 = final <$> simplify laws12 "filter p . map f"
        finalOf2a = final <$> simplify laws12 "map f . filter (p . f)"
    case (finalOf1, finalOf2a) of
        (Right a, Right b) -> check "两边殊途同归（证明成功）" a b
        _ -> check "解析" False True
    case simplify lawsIter "head . iterate f" of
        Right calc -> check "iterate 计算收敛到 id" (show (final calc)) "id"
        Left _ -> check "iterate 解析" False True
    check "表达式解析往返" (show <$> parseExpr "map f . concat . map (box p)") (Right "map f . concat . map (box p)")
    check "运算符表达式往返" (show <$> parseExpr "(f * g) . h") (Right "(f * g) . h")
    check "id 解析为空复合" (parseExpr "id") (Right (Compose []))

    putStrLn "==== 23 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
    | actual == expected = return ()
    | otherwise =
        error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
