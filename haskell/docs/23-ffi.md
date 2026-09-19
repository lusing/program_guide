# 23 · FFI：调 C

> 对应示例：`examples/23_ffi/`

## 23.1 最小 FFI

```haskell
{-# LANGUAGE ForeignFunctionInterface #-}     -- GHC 2021 起其实可不写，显式更清楚

foreign import ccall "msvcrt strlen" c_strlen :: CString -> IO CSize
foreign import ccall "msvcrt abs"    c_abs    :: CInt -> CInt     -- 纯导入：不带 IO

hsStrlen s = withCString s (fmap fromIntegral . c_strlen)
```

格式：`foreign import ccall "库 符号" haskell名 :: 签名`。**Windows 实测**：msvcrt 与
kernel32 都能直链。纯 C 函数（abs）声明成非 IO 的直接当 Haskell 函数用。

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

回调方向：把 Haskell 比较器交给 msvcrt 的 qsort：

```haskell
foreign import ccall "wrapper"
    mkComparator :: (Ptr CInt -> Ptr CInt -> IO CInt) -> IO (FunPtr (Ptr CInt -> Ptr CInt -> IO CInt))

foreign import ccall "msvcrt qsort"
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

## 23.4 kernel32：Sleep 计时验证

```haskell
foreign import ccall "kernel32 Sleep" c_sleep :: CUInt -> IO ()
sleepFor s = c_sleep (fromIntegral (round (s * 1000)))     -- 秒 → DWORD 毫秒
```

x64 上调用约定统一为 ccall（32 时代的 stdcall 注记已不需要）。用 `getMonotonicTime` 前后
掐表：Sleep 0.1s 实测 ≈ 0.1002s（断言给带宽 0.09–2.0s）。

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
5. **导入名两段式 "库 符号"**：Windows 直链 msvcrt/kernel32 ✓；Linux 无库名段（符号全局）。
