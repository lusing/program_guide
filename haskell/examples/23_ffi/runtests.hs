-- 23 测试套件
module Main (main) where

import Ch23
import Control.Monad (unless)
import qualified Data.ByteString.Char8 as BC
import GHC.Clock (getMonotonicTime)
import System.Exit (exitFailure)
import System.IO (hSetEncoding, stderr, stdout, utf8)

data Case = Case { name :: String, ok :: Bool, detail :: String }

expectEq :: (Eq a, Show a) => String -> a -> a -> Case
expectEq n got want
  | got == want = Case n True ""
  | otherwise   = Case n False (n ++ ": 得到 " ++ show got ++ " 期望 " ++ show want)

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
    s1 <- runSuite "纯导入"
        [ expectEq "abs 负" (c_abs (-7)) 7
        , expectEq "abs 正" (c_abs 7) 7
        , expectEq "abs 极值" (c_abs (negate 12345)) 12345
        ]
    n1 <- hsStrlen "abcdef"
    n2 <- hsStrlen ""
    s2 <- runSuite "strlen"
        [ expectEq "六字符" n1 6
        , expectEq "空串" n2 0
        ]
    sorted1 <- hsSortInts [3, 1, 2]
    sorted2 <- hsSortInts []
    sorted3 <- hsSortInts [9, 9, 9, 1]
    s3 <- runSuite "qsort 回调"
        [ expectEq "小表" sorted1 [1, 2, 3]
        , expectEq "空表" sorted2 []
        , expectEq "重复值" sorted3 [1, 9, 9, 9]
        ]
    t0 <- getMonotonicTime
    sleepFor 0.05
    t1 <- getMonotonicTime
    bl <- byteLen (BC.pack "haskell")
    s4 <- runSuite "sleep 与 ByteString"
        [ expectTrue "Sleep 达时" (t1 - t0 >= 0.045)
        , expectTrue "Sleep 不挂" (t1 - t0 <= 2.0)
        , expectEq "字节长度" bl 7
        ]
    unless (s1 && s2 && s3 && s4) exitFailure
    putStrLn "==== 23 结束 ===="
