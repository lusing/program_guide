-- Ch23 库模块：FFI——foreign import ccall、C 类型映射、Ptr 编组、wrapper 回调
-- 跨平台：Windows 直链 msvcrt/kernel32；macOS/Linux 用 libc 全局符号（无库名段）
{-# LANGUAGE CPP #-}
{-# LANGUAGE ForeignFunctionInterface #-}

module Ch23
    ( hsStrlen, c_abs
    , hsSortInts
    , sleepFor
    , byteLen
    ) where

import Foreign.C.String (CString, withCString)
import Foreign.C.Types (CUInt (..), CInt (..), CSize (..), CLong (..))
import Foreign.Marshal.Alloc (allocaBytes)
import Foreign.Marshal.Array (allocaArray, peekArray, pokeArray)
import Foreign.Ptr (FunPtr, Ptr, castPtr, nullPtr, plusPtr)
import Foreign.Storable (Storable (peek, poke, sizeOf))
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as BC

-- ═══ 23.1 最小 FFI：strlen（Windows 显式 msvcrt；macOS/Linux 符号全局，省略库名段）
#if defined(mingw32_HOST_OS)
foreign import ccall "msvcrt strlen" c_strlen :: CString -> IO CSize
#else
foreign import ccall "strlen" c_strlen :: CString -> IO CSize
#endif

hsStrlen :: String -> IO Int
hsStrlen s = withCString s (fmap fromIntegral . c_strlen)

-- 纯函数导入：c_abs 不做 IO，直接当 Haskell 函数用
#if defined(mingw32_HOST_OS)
foreign import ccall "msvcrt abs" c_abs :: CInt -> CInt
#else
foreign import ccall "abs" c_abs :: CInt -> CInt
#endif

-- ═══ 23.2 wrapper 回调：把 Haskell 闭包包装成 C 函数指针，交给 qsort
foreign import ccall "wrapper"
    mkComparator :: (Ptr CInt -> Ptr CInt -> IO CInt) -> IO (FunPtr (Ptr CInt -> Ptr CInt -> IO CInt))

#if defined(mingw32_HOST_OS)
foreign import ccall "msvcrt qsort"
    c_qsort :: Ptr CInt -> CSize -> CSize -> FunPtr (Ptr CInt -> Ptr CInt -> IO CInt) -> IO ()
#else
foreign import ccall "qsort"
    c_qsort :: Ptr CInt -> CSize -> CSize -> FunPtr (Ptr CInt -> Ptr CInt -> IO CInt) -> IO ()
#endif

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

-- ═══ 23.3 毫秒级阻塞：平台分叉（x64 上调用约定统一为 ccall，不必标 stdcall）
#if defined(mingw32_HOST_OS)
-- Windows：kernel32 Sleep(DWORD 毫秒)
-- 坑：DWORD 是 32 位无符号——FFI 类型必须精确用 CUInt，不能拿 Word（64 位）凑
foreign import ccall "kernel32 Sleep" c_sleep :: CUInt -> IO ()

sleepFor :: Double -> IO ()               -- 秒（内部换算毫秒）
sleepFor s = c_sleep (fromIntegral (round (s * 1000)))
#else
-- macOS/Linux：nanosleep(const struct timespec *req, struct timespec *rem)
-- struct timespec { time_t tv_sec; long tv_nsec; }——64 位 POSIX 上两者皆 long（8 字节），
-- 故按 sizeOf CLong 算字段大小与偏移，手工编组（无 boot 库现成 Storable 实例）
foreign import ccall "nanosleep" c_nanosleep :: Ptr CLong -> Ptr CLong -> IO CInt

sleepFor :: Double -> IO ()               -- 秒（内部换算纳秒）
sleepFor s = allocaBytes (2 * field) $ \p -> do
    poke p (fromIntegral sec :: CLong)                       -- tv_sec
    poke (castPtr (p `plusPtr` field)) (fromIntegral nsec :: CLong)  -- tv_nsec
    _ <- c_nanosleep (castPtr p) nullPtr
    pure ()
  where
    field = sizeOf (undefined :: CLong)
    totalNs = round (s * 1e9) :: Integer
    (sec, nsec) = totalNs `divMod` 1000000000
#endif

-- ═══ 23.4 ByteString 透传：useAsCString 零拷贝借出底层字节
byteLen :: B.ByteString -> IO Int
byteLen bs = BC.useAsCString bs (fmap fromIntegral . c_strlen)
