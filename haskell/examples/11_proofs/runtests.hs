-- 11 测试套件：证明与归纳（书6）——定律、融合、scanl/mss 对账、Float 反例
module Main (main) where

import Ch11
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
    s1 <- runSuite "定律族（书4/6）"
        [ expectTrue "++ 结合律" (and [propAppendAssoc xs ys zs | xs <- samples, ys <- samples, zs <- samples])
        , expectTrue "reverse 对合" (and (map propReverseTwice samples))
        , expectTrue "sum . (++)" (and [propSumAppend xs ys | xs <- samples, ys <- samples])
        , expectTrue "map 融合" (and [propMapFusion g f xs | g <- gs, f <- fs, xs <- samples])
        , expectTrue "map·reverse" (and [propMapReverseCommute f xs | f <- fs, xs <- samples])
        , expectTrue "filter·map" (and [propFilterMapLaw p f xs | p <- ps, f <- fs, xs <- samples])
        ]
    s2 <- runSuite "融合律与对账（书6.3/6.5/6.6）"
        [ expectTrue "double.sum 融合" (and (map propDoubleSumFusion samples))
        , expectTrue "length.concat 融合" (and (map propLengthConcatFusion (map pure samples)))
        , expectTrue "scanl 规格==线性" (and (map (propScanlSpecEqLinear (+) 0) samples))
        , expectTrue "scanl 规格==线性（自定函数）" (and (map (propScanlSpecEqLinear (\n x -> n * 2 + x) 0) samples))
        , expectTrue "mss 规格==线性" (and [mssSpec xs == mssLinear xs | xs <- samples])
        , expectEq "mss 书例" (mssLinear [-1, 2, -3, 5, -2, 1, 3, -2, -2, -3, 6]) 7
        , expectEq "mss 全负" (mssLinear [-1, -2, -3]) 0
        , expectEq "mss 单元素正" (mssLinear [42]) 42
        , expectEq "mss 空表" (mssLinear []) 0
        ]
    s3 <- runSuite "Float 反例（书6.1）"
        [ expectTrue "结合律在 Float 上失效" (floatAssocL /= floatAssocR)
        , expectEq "floatAssocL" floatAssocL 4.95e-11
        ]
    unless (s1 && s2 && s3) exitFailure
    putStrLn "==== 11 结束 ===="
  where
    gs = [id, (+ 1), (* 3)] :: [Int -> Int]
    fs = [id, negate, (* 2), abs] :: [Int -> Int]
    ps = [even, odd, (> 3), const True] :: [Int -> Bool]
