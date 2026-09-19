-- 08 类型类：class/instance、超类、MINIMAL、约束多态、newtype 派生
-- 运行：ghc -v0 --make main.hs -o 08.exe && ./08.exe
module Main (main) where

import Ch08
import Data.Ratio ((%))
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    -- ═══ 08.1 按类型分派：同名方法，每个类型一份实现
    putStrLn "==[ 08 · 类型类 ]=="
    putStrLn (describe Red ++ " / " ++ describe Green ++ " / " ++ describe Blue)
    putStrLn (describe True ++ " / " ++ describe False)
    putStrLn ("describeTwice Red = " ++ describeTwice Red)        -- 默认实现生效

    -- ═══ 08.2 超类能力
    putStrLn ("label A = " ++ label A ++ "   A == B? " ++ show (A == B))

    -- ═══ 08.3 MINIMAL：实例只实现 volume，halfVolume 吃默认
    let b = Box 3
    putStrLn ("volume (Box 3) = " ++ show (volume b))
    putStrLn ("halfVolume     = " ++ show (halfVolume b))

    -- ═══ 08.4 newtype 派生：Count 白拿 Int 的全部算术
    let c2 = Count 2
        c3 = Count 3
    putStrLn ("Count 2 + Count 3 = " ++ show (c2 + c3))
    putStrLn ("Count 2 * 5       = " ++ show (c2 * 5))
    putStrLn ("Count 3 > Count 2 = " ++ show (c3 > c2))

    -- ═══ 08.5 约束多态：同一函数喂多种类型
    putStrLn ("scaleIt (5::Int)        = " ++ scaleIt (5 :: Int))
    putStrLn ("scaleIt (5.5::Double)   = " ++ scaleIt (5.5 :: Double))
    putStrLn ("scaleIt (Count 7)       = " ++ scaleIt (Count 7))
    putStrLn ("halfOf (5::Double)      = " ++ show (halfOf (5 :: Double)))
    putStrLn ("halfOf (1::Rational)    = " ++ show (halfOf (1 :: Rational)))

    -- ═══ 08.6 自检
    check "实例分派" (describe Blue) "蓝"
    check "Bool 实例" (describe False) "假"
    check "默认方法" (describeTwice Red) "红，红"
    check "超类 label" (label B) "B"
    check "MINIMAL 体积" (volume (Box 3)) 27.0
    check "默认半体积" (halfVolume (Box 3)) 13.5
    check "newtype Num" (c2 + c3) (Count 5)
    check "newtype Ord" (c3 > c2) True
    check "约束多态 Int" (scaleIt (5 :: Int)) "10"
    check "约束多态 Rational" (halfOf (1 :: Rational)) (1 % 2)

    putStrLn "==== 08 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
