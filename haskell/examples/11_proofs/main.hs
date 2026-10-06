-- 11 证明与归纳：定律族抽查 + 程序计算成果对账 + Float 反例（书6）
-- 运行：ghc -v0 --make main.hs -o 11.exe && ./11.exe
module Main (main) where

import Ch11
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    putStrLn "==[ 11 · 证明与归纳 ]=="
    putStrLn "-- 手算推导见 docs/11-proofs.md；本程序把每条定律与推导成果放到确定性样本上互证。"

    -- ═══ 11.1 基本定律族：全部样本成立
    let laws :: [(String, Bool)]
        laws =
            [ ("(++ ) 结合律", and [propAppendAssoc xs ys zs | xs <- samples, ys <- samples, zs <- samples])
            , ("reverse 对合（有穷表）", and (map propReverseTwice samples))
            , ("sum . (++) 分配", and [propSumAppend xs ys | xs <- samples, ys <- samples])
            , ("map 融合律", and [propMapFusion g f xs | g <- gs, f <- fs, xs <- samples])
            , ("map 与 reverse 可交换", and [propMapReverseCommute f xs | f <- fs, xs <- samples])
            , ("filter/map 定律", and [propFilterMapLaw p f xs | p <- ps, f <- fs, xs <- samples])
            ]
        gs = [id, (+ 1), (* 3)] :: [Int -> Int]
        fs = [id, negate, (* 2), abs] :: [Int -> Int]
        ps = [even, odd, (> 3), const True] :: [Int -> Bool]
    mapM_ (\(n, b) -> putStrLn ("  " ++ (if b then "PASS " else "FAIL ") ++ n)) laws

    -- ═══ 11.2 foldr 融合律的两个推论
    putStrLn ("  " ++ "PASS " ++ "double . sum = foldr ((+).double) 0   : "
                ++ show (and (map propDoubleSumFusion samples)))
    putStrLn ("  " ++ "PASS " ++ "length . concat = foldr addLen 0     : "
                ++ show (and (map propLengthConcatFusion (map pure samples))))

    -- ═══ 11.3 scanl：二次方规格与线性实现等值（书 6.5 的计算成果）
    putStrLn ("  scanl 规格 == 线性版（加法/长度双例）: "
                ++ show (and (map (propScanlSpecEqLinear (+) 0) samples)
                        && and (map (propScanlSpecEqLinear (\n x -> n * 2 + x) 0) samples)))

    -- ═══ 11.4 最大连续段和：三次方规格 == 线性解（书 6.6 的计算成果）
    putStrLn ("  mssSpec == mssLinear（全部样本）: "
                ++ show (and [mssSpec xs == mssLinear xs | xs <- samples]))
    putStrLn ("  书中例子 mss [-1,2,-3,5,-2,1,3,-2,-2,-3,6] = "
                ++ show (mssLinear [-1, 2, -3, 5, -2, 1, 3, -2, -2, -3, 6]))
    putStrLn ("  全负序列 mss [-1,-2,-3] = " ++ show (mssLinear [-1, -2, -3]) ++ "（空段和为 0）")

    -- ═══ 11.5 Float 反例：证明正确 ≠ 实例正确（书 6.1）
    putStrLn ("  (9.9e10 * 0.5e-10) * 0.1e-10 = " ++ show floatAssocL)
    putStrLn ("  9.9e10 * (0.5e-10 * 0.1e-10) = " ++ show floatAssocR)
    putStrLn ("  结合律在 Float 上失效: " ++ show (floatAssocL /= floatAssocR))

    -- ═══ 11.6 自检
    check "定律族全绿" (and (map snd laws)) True
    check "融合推论一" (and (map propDoubleSumFusion samples)) True
    check "融合推论二" (and (map propLengthConcatFusion (map pure samples))) True
    check "scanl 双例等值" (and (map (propScanlSpecEqLinear (+) 0) samples)
                            && and (map (propScanlSpecEqLinear (\n x -> n * 2 + x) 0) samples)) True
    check "mss 双版等值" (and [mssSpec xs == mssLinear xs | xs <- samples]) True
    check "mss 书例 = 7" (mssLinear [-1, 2, -3, 5, -2, 1, 3, -2, -2, -3, 6]) 7
    check "mss 全负 = 0" (mssLinear [-1, -2, -3]) 0
    check "Float 反例成立" (floatAssocL /= floatAssocR) True

    putStrLn "==== 11 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
    | actual == expected = return ()
    | otherwise =
        error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
