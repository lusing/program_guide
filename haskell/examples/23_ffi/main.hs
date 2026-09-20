-- 23 FFI：foreign import ccall、Ptr 编组、wrapper 回调、C sleep 计时
-- 运行：ghc -v0 --make main.hs -o 23.exe && ./23.exe
module Main (main) where

import Ch23
import qualified Data.ByteString.Char8 as BC
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import GHC.Clock (getMonotonicTime)
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    putStrLn "==[ 23 · FFI ]=="

    -- ═══ 23.1 strlen 与 abs
    n1 <- hsStrlen "haskell"
    n2 <- hsStrlen ""                    -- 空串也是合法 C 字符串
    putStrLn ("strlen \"haskell\" = " ++ show n1)
    putStrLn ("strlen \"\"        = " ++ show n2)
    putStrLn ("c_abs (-42)      = " ++ show (c_abs (-42)))
    putStrLn ("c_abs 42         = " ++ show (c_abs 42))

    -- ═══ 23.2 qsort + Haskell 比较器回调
    sorted <- hsSortInts [5, 3, 9, 1, 7, 3]
    putStrLn ("qsort [5,3,9,1,7,3] = " ++ show sorted)

    -- ═══ 23.3 C sleep：毫秒计时验证（Windows=kernel32 Sleep / macOS·Linux=nanosleep）
    t0 <- getMonotonicTime
    sleepFor 0.1
    t1 <- getMonotonicTime
    putStrLn ("C sleep 0.1s 实测 ≈ " ++ show (t1 - t0) ++ "s")

    -- ═══ 23.4 ByteString 零拷贝借出
    let bs = TE.encodeUtf8 (T.pack "hello ffi")
    bl <- byteLen bs
    putStrLn ("ByteString strlen = " ++ show bl ++ "（字节数 " ++ show (BC.length bs) ++ "）")

    -- ═══ 23.5 自检
    check "strlen 正常" n1 7
    check "strlen 空串" n2 0
    check "abs 负数" (c_abs (-42)) 42
    check "abs 正数" (c_abs 42) 42
    check "abs 零" (c_abs 0) 0
    check "qsort 升序" sorted [1, 3, 3, 5, 7, 9]
    check "Sleep 不早退" (t1 - t0 >= 0.09) True
    check "Sleep 不超时" (t1 - t0 <= 2.0) True
    check "字节长度" bl 9    -- "hello ffi" = 9 字节（纯 ASCII：字符数=字节数）

    putStrLn "==== 23 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
