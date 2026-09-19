-- 21 测试：自制断言框架（runtests 即范本）、迷你属性测试（生成/收缩/定种子）
-- 运行：ghc -v0 --make main.hs -o 21.exe && ./21.exe
module Main (main) where

import Ch21
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    putStrLn "==[ 21 · 测试 ]=="

    -- ═══ 21.1 生成器：种子固定 → 样本可复现
    putStrLn ("sampleInts 42 = " ++ show (sampleInts 42))
    putStrLn ("sampleInts 42 再来 = " ++ show (sampleInts 42))     -- 一致！
    putStrLn ("sampleInts 43       = " ++ show (sampleInts 43))    -- 换种子即变

    -- ═══ 21.2 属性测试：200 个随机样本过不变式
    let props :: [(String, String)]
        props =
            [ ("排序幂等", render (runProperty 200 42 (generate :: Gen [Int]) shrinkList propSortIdempotent))
            , ("绝对值非负", render (runProperty 200 42 (generate :: Gen Int) shrinkInt propAbsNonNeg))
            , ("reverse 两次还原", render (runProperty 200 42 (generate :: Gen [Int]) shrinkList propReverseTwice))
            , ("Text 往返", render (runProperty 200 42 (generate :: Gen String) shrinkList propTextRoundtrip))
            ]
        render Nothing  = "200/200 通过"
        render (Just x) = "反例: " ++ show x
    mapM_ (\(n, r) -> putStrLn ("  " ++ n ++ ": " ++ r)) props

    -- ═══ 21.3 故意失败的属性：反例会被收缩到最小
    let broken = runProperty 50 7 (generate :: Gen Int) shrinkInt (\x -> x < 5)
    putStrLn ("故意失败的属性 → 反例: " ++ show broken)

    -- ═══ 21.4 自检
    check "种子可复现" (sampleInts 42 == sampleInts 42) True
    check "种子敏感" (sampleInts 42 /= sampleInts 43) True
    check "属性全过" (all (\(_, r) -> r == "200/200 通过") props) True
    check "失败属性给反例" (maybe False (const True) broken) True
    check "反例确实违反属性" (maybe False (\x -> not (x < 5)) broken) True
    check "反例已最小（邻居都满足）" (maybe False (\x -> all (\y -> y < 5) (shrinkInt x)) broken) True
    check "排序幂等（定点）" (propSortIdempotent [3, 1, 2]) True
    check "Text 往返（定点）" (propTextRoundtrip "中文测试") True
    check "收缩整数" (shrinkInt 100) [50, 0]
    check "收缩列表" (shrinkList [1, 2, 3, 4]) [[1, 2], [1, 2, 3]]
    check "收缩单元素" (shrinkList [9]) []

    putStrLn "==== 21 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
