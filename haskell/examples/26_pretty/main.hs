-- 26 优美打印（书8）：Doc 代数、浅/深嵌入、线性 pretty
-- 运行：ghc -v0 --make main.hs -o 26.exe && ./26.exe
module Main (main) where

import Ch26
import System.CPUTime (getCPUTime)
import System.IO (hSetEncoding, stderr, stdout, utf8)

smallPara :: String
smallPara = "This is a fairly short paragraph with just a few words."

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    putStrLn "==[ 26 · 优美打印 ]=="

    -- ═══ 26.1 条件表达式：13 种格式？两种嵌入数出同一批
    putStrLn ("bookIf 的格式数（参考版/线性版）: "
                ++ show (length (layouts (cexpr bookIf)), length (layoutsLinear (cexpr bookIf))))

    -- ═══ 26.2 pretty 实录：窄/宽两档
    putStrLn "-- pretty 30 (cexpr bookIf)："
    putStrLn (pretty 30 (cexpr bookIf))
    putStrLn "-- pretty 66 (cexpr bookIf)："
    putStrLn (pretty 66 (cexpr bookIf))

    -- ═══ 26.3 树：窄/宽两档
    putStrLn "-- pretty 26 (gtree bookTree)："
    putStrLn (pretty 26 (gtree bookTree))
    putStrLn "-- pretty 70 (gtree bookTree)："
    putStrLn (pretty 70 (gtree bookTree))

    -- ═══ 26.4 段落：书里 31.32s → 0.00s 的主角
    t0 <- getCPUTime
    let p22 = pretty 30 (para bookPara)
    t1 <- getCPUTime
    putStrLn "-- pretty 30 (para bookPara)："
    putStr p22
    putStrLn ""
    putStrLn ("22 词段落线性版耗时: " ++ show (fromIntegral (t1 - t0) / 1e9 :: Double) ++ " 毫秒（书里指数版 31.32s）")

    -- ═══ 26.5 自检
    check "两种 layouts 同集" (layouts (cexpr bookIf)) (layoutsLinear (cexpr bookIf))
    check "两版 pretty 同文（条件）" (prettyNaive 30 (cexpr bookIf)) (pretty 30 (cexpr bookIf))
    check "两版 pretty 同文（小段落）" (prettyNaive 22 (para smallPara)) (pretty 22 (para smallPara))
    check "段落每行不超宽" (all (<= 30) (map length (lines' (pretty 30 (para bookPara))))) True
    check "线性版快于毫秒级" (t1 - t0 < 50000000000) True   -- 50ms 上限，远低于指数版

    putStrLn "==== 26 结束 ===="
  where
    lines' s = case break (== '\n') s of
        (l, "") -> [l]
        (l, _ : rest) -> l : lines' rest

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
    | actual == expected = return ()
    | otherwise =
        error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
