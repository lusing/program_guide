# 23 · FFI：调 C

> 对应示例：`examples/23_ffi/`（Windows + macOS/Linux 双分支，CPP 切换）

## 23.1 最小 FFI

```haskell
{-# LANGUAGE CPP #-}
{-# LANGUAGE ForeignFunctionInterface #-}     -- GHC 2021 起其实可不写，显式更清楚

#if defined(mingw32_HOST_OS)
foreign import ccall "msvcrt strlen" c_strlen :: CString -> IO CSize
foreign import ccall "msvcrt abs"    c_abs    :: CInt -> CInt     -- 纯导入：不带 IO
#else                                          -- macOS/Linux：libc 符号全局，省略库名段
foreign import ccall "strlen" c_strlen :: CString -> IO CSize
foreign import ccall "abs"    c_abs    :: CInt -> CInt
#endif

hsStrlen s = withCString s (fmap fromIntegral . c_strlen)
```

格式：`foreign import ccall "库 符号" haskell名 :: 签名`。**Windows 实测**：msvcrt 与
kernel32 都能直链；**macOS/Linux 实测**：libc 符号（strlen/abs/qsort）全局可见，导入名
只写符号、不带库名段（`mingw32_HOST_OS` 是 GHC 在 Windows 上定义的 CPP 宏）。纯 C 函数
（abs）声明成非 IO 的直接当 Haskell 函数用。

## 23.2 类型映射表

| Haskell | C |
|---|---|
| CInt / CUInt | int / unsigned int |
| CSize | size_t |
| CDouble | double |
| CString | char* |
| Ptr a / FunPtr a | 指针 / 函数指针 |
| Word64 | （要精确对 64 位，别拿 Word 凑——见坑） |

**marshal 三招**：`withCString`（借出期间保持存活）、`alloca`（栈上分配用完即弃）、
`peek/poke`（读写）。转换靠 `fromIntegral`（数值）与 `peekCString`（字符串回来）。

## 23.3 wrapper：Haskell 闭包 → C 函数指针

回调方向：把 Haskell 比较器交给 qsort（Windows `msvcrt qsort` / macOS·Linux `qsort`）：

```haskell
foreign import ccall "wrapper"
    mkComparator :: (Ptr CInt -> Ptr CInt -> IO CInt) -> IO (FunPtr (Ptr CInt -> Ptr CInt -> IO CInt))

#if defined(mingw32_HOST_OS)
foreign import ccall "msvcrt qsort"
#else
foreign import ccall "qsort"
#endif
    c_qsort :: Ptr CInt -> CSize -> CSize -> FunPtr (Ptr CInt -> Ptr CInt -> IO CInt) -> IO ()

compareCInt p q = do
    a <- peek p; b <- peek q
    pure $ case compare a b of LT -> -1; EQ -> 0; GT -> 1

hsSortInts xs = allocaArray n $ \arr -> do
    pokeArray arr (map fromIntegral xs)
    cmp <- mkComparator compareCInt
    c_qsort arr (fromIntegral n) (fromIntegral (sizeOf (undefined :: CInt))) cmp
    map fromIntegral <$> peekArray n arr
```

`compare a b` 是 `Ordering`——**不能 fromIntegral**，case 到 -1/0/1（实测编译错误教你做人）。

## 23.4 毫秒级阻塞：平台分叉

Windows 有 `kernel32 Sleep(DWORD 毫秒)`；POSIX 没有毫秒级 sleep，用 `nanosleep(timespec*)`：

```haskell
#if defined(mingw32_HOST_OS)
foreign import ccall "kernel32 Sleep" c_sleep :: CUInt -> IO ()
sleepFor s = c_sleep (fromIntegral (round (s * 1000)))     -- 秒 → DWORD 毫秒
#else
-- struct timespec { time_t tv_sec; long tv_nsec; }——64 位 POSIX 上两者皆 long（8 字节）
foreign import ccall "nanosleep" c_nanosleep :: Ptr CLong -> Ptr CLong -> IO CInt
sleepFor s = allocaBytes (2 * field) $ \p -> do
    poke p (fromIntegral sec :: CLong)                          -- tv_sec
    poke (castPtr (p `plusPtr` field)) (fromIntegral nsec :: CLong)  -- tv_nsec
    c_nanosleep (castPtr p) nullPtr >> pure ()
  where
    field = sizeOf (undefined :: CLong)
    (sec, nsec) = round (s * 1e9) `divMod` 1000000000
#endif
```

x64 上调用约定统一为 ccall（32 时代的 stdcall 注记已不需要）。用 `getMonotonicTime` 前后
掐表：sleep 0.1s 实测 ≈ 0.1002s（Windows）/ ≈ 0.1034s（macOS）；断言给带宽 0.09–2.0s。
POSIX 无现成 timespec 的 Storable 实例，按 `sizeOf CLong` 手工算字段大小与偏移编组。

## 23.5 ByteString 零拷贝借出

```haskell
byteLen bs = BC.useAsCString bs (fmap fromIntegral . c_strlen)
```

`useAsCString` 保证 NUL 结尾的临时视图存在期间调用 C——比 pack/unpack 快得多。

## 23.6 坑位清单

1. **DWORD 是 CUInt 不是 Word**：FFI 类型要精确按 C 的宽度写——Word（64 位）凑 32 位参数
   是未定义行为级错误（23.2/23.4）。
2. **Ordering 不能 fromIntegral**：回调返回值 case 成 -1/0/1（23.3）。
3. **纯导入（无 IO）要求函数真纯**：abs/sqrt 可以；fopen 这类有状态的不行（23.1）。
4. **FunPtr 要释放**（freeHaskellFunPtr）：长生命周期回调注意泄漏；教学示例短命可忽略（23.3）。
5. **导入名两段式 "库 符号" 仅 Windows**：Windows 直链 msvcrt/kernel32 ✓；macOS/Linux 的 libc
   符号全局可见，只写符号名（`strlen`/`abs`/`qsort`），带库名段反而可能链不上（23.1/23.3）。
6. **POSIX 无毫秒 sleep**：`kernel32 Sleep` 是 Win32 专有；macOS/Linux 用 `nanosleep` + 手工
   编组 `struct timespec`（无 boot 库 Storable 实例，按 `sizeOf CLong` 算偏移），CPP 分平台（23.4）。
