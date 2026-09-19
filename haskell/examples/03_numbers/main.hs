-- 03 数值：类型类层次、Int/Integer、整除家族、fromIntegral、read 陷阱、Rational
-- 运行：ghc -v0 --make main.hs -o 03.exe && ./03.exe
module Main (main) where

import Ch03
import Data.Ratio ((%))
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    -- ═══ 03.1 Int 溢出 wrap-around vs Integer 无界
    putStrLn $ "==[ 03 · 数值 ]=="
    putStrLn ("maxBound :: Int  = " ++ show (maxBound :: Int))
    putStrLn ("20! as Int      = " ++ show (factInt 20))       -- 2.4e18，尚在界内
    putStrLn ("21! as Int      = " ++ show (factInt 21))       -- 溢出变负！
    putStrLn ("21! as Integer  = " ++ show (factInteger 21))   -- 无界，正确

    -- ═══ 03.2 整除家族四兄弟（-7 与 2）
    let (dm, qr) = divideFamily (-7) 2
    putStrLn ("divMod (-7) 2 = " ++ show dm ++ "   quotRem (-7) 2 = " ++ show qr)

    -- ═══ 03.3 浮点：0.1 + 0.2 经典误差；Rational 精确
    putStrLn ("0.1 + 0.2 = " ++ show (0.1 + 0.2 :: Double))    -- 0.30000000000000004
    putStrLn ("1/3 + 1/6 (Rational) = " ++ show (third + 1 % 6 :: Rational))
    putStrLn ("avg [1,2,3] = " ++ show (avg [1, 2, 3]))

    -- ═══ 03.4 read 陷阱与 readMaybe
    putStrLn ("readMaybe \"42\"  = " ++ show (safeRead "42"))
    putStrLn ("readMaybe \"4x\"  = " ++ show (safeRead "4x"))   -- Nothing 而不是崩溃

    -- ═══ 03.5 字面量多态与 defaulting：整数默认 Integer、小数默认 Double
    print 5                          -- defaulting → Integer
    print 5.0                        -- defaulting → Double
    print (doubleIt 21 :: Int)       -- 同一函数，三种类型
    print (doubleIt 2.5 :: Double)
    print (doubleIt (10 ^ 25 :: Integer))

    -- ═══ 03.6 自检
    check "factInt 20 为正" (factInt 20 > 0) True
    check "factInt 21 溢出为负" (factInt 21 < 0) True
    check "divMod (-7) 2" (divMod (-7) 2) (-4, 1)
    check "quotRem (-7) 2" (quotRem (-7) 2) (-3, -1)
    check "avg" (avg [1, 2, 3]) 2.0
    check "safeRead 好输入" (safeRead "42") (Just 42)
    check "safeRead 坏输入" (safeRead "4x") Nothing
    check "Rational 精确和" half (1 % 2)

    putStrLn "==== 03 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
