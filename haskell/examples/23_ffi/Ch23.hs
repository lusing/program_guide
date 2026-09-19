-- Ch23 库模块：FFI——foreign import ccall、C 类型映射、Ptr 编组、wrapper 回调
{-# LANGUAGE ForeignFunctionInterface #-}

module Ch23
    ( hsStrlen, c_abs
    , hsSortInts
    , sleepFor
    , byteLen
    ) where

import Foreign.C.String (CString, withCString)
import Foreign.C.Types (CUInt (..), CInt (..), CSize (..))
import Foreign.Marshal.Array (allocaArray, peekArray, pokeArray)
import Foreign.Ptr (FunPtr, Ptr)
import Foreign.Storable (Storable (peek, sizeOf))
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as BC

-- ═══ 23.1 最小 FFI：msvcrt 的 strlen（Windows 实测可直链）
foreign import ccall "msvcrt strlen" c_strlen :: CString -> IO CSize

hsStrlen :: String -> IO Int
hsStrlen s = withCString s (fmap fromIntegral . c_strlen)

-- 纯函数导入：c_abs 不做 IO，直接当 Haskell 函数用
foreign import ccall "msvcrt abs" c_abs :: CInt -> CInt

-- ═══ 23.2 wrapper 回调：把 Haskell 闭包包装成 C 函数指针，交给 msvcrt qsort
foreign import ccall "wrapper"
    mkComparator :: (Ptr CInt -> Ptr CInt -> IO CInt) -> IO (FunPtr (Ptr CInt -> Ptr CInt -> IO CInt))

foreign import ccall "msvcrt qsort"
    c_qsort :: Ptr CInt -> CSize -> CSize -> FunPtr (Ptr CInt -> Ptr CInt -> IO CInt) -> IO ()

compareCInt :: Ptr CInt -> Ptr CInt -> IO CInt
compareCInt p q = do
    a <- peek p
    b <- peek q
    pure $ case compare a b of           -- C 惯例：-1 / 0 / 1（升序比较器）
        LT -> -1
        EQ -> 0
        GT -> 1

hsSortInts :: [Int] -> IO [Int]
hsSortInts xs = allocaArray n $ \arr -> do
    pokeArray arr (map fromIntegral xs :: [CInt])
    cmp <- mkComparator compareCInt
    c_qsort arr (fromIntegral n) (fromIntegral (sizeOf (undefined :: CInt))) cmp
    map fromIntegral <$> peekArray n arr
  where
    n = length xs

-- ═══ 23.3 kernel32：Sleep 毫秒级阻塞（x64 上调用约定统一为 ccall，不必标 stdcall）
-- 坑：DWORD 是 32 位无符号——FFI 类型必须精确用 CUInt，不能拿 Word（64 位）凑
foreign import ccall "kernel32 Sleep" c_sleep :: CUInt -> IO ()

sleepFor :: Double -> IO ()               -- 秒（内部换算毫秒）
sleepFor s = c_sleep (fromIntegral (round (s * 1000)))

-- ═══ 23.4 ByteString 透传：useAsCString 零拷贝借出底层字节
byteLen :: B.ByteString -> IO Int
byteLen bs = BC.useAsCString bs (fmap fromIntegral . c_strlen)
