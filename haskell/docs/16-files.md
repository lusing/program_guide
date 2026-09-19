# 16 · 文件与目录

> 对应示例：`examples/16_files/`

## 16.1 读写基础（全部显式 UTF-8）

```haskell
writeFileUtf8 p s = openFile p WriteMode >>= \h ->
    hSetEncoding h utf8 >> hPutStr h s >> hClose h
```

**实测坑（Windows 重灾区）**：`writeFile`/`appendFile`/`readFile` 默认走**系统代码页**（本机 GBK）。
中文写出去是 GBK 字节；与显式 UTF-8 的句柄混用，一个文件两种编码。**写文件一律显式
hSetEncoding utf8**（教程的 writeFileUtf8）。

## 16.2 惰性读 + 同名写：两平台两种死法

```haskell
toUpperFileLazy p = readFile p >>= writeFile p . map toUpper    -- 反面教材
```

- **Windows（实测）**：写端打开时被未关的惰性读句柄**锁住**，直接抛 IOException；原文件未损。
  且该句柄**一直锁到 GC**——后续对同名文件的写也失败（`withFile: resource busy`）。
- **Linux**：更阴险——不报错，文件被**静默清空**（截断发生在读取之前）。

正解都是**先严格读入内存再写**：

```haskell
readStrict p = do                        -- ByteString 全量入内存 + UTF-8 解码
    bs <- B.readFile p
    pure (T.unpack (either (const T.empty) id (decodeUtf8' bs)))

toUpperFileStrict p = do c <- readStrict p; writeFile p (map toUpper c)
```

## 16.3 CRLF 归一化

Windows 文本模式把 `\n` 写成 `\r\n`；ByteString 读是二进制通道看得见 `\r`。跨平台读取统一归一：

```haskell
T.unpack (T.replace "\r\n" "\n" txt)
```

## 16.4 目录操作（directory 库）

```haskell
createDirectoryIfMissing True (dir </> "sub" </> "deep")
es <- listDirectory dir                   -- 顺序不定！断言前必须 sort
doesFileExist / doesDirectoryExist / copyFile / removeFile
```

`</>` 来自 System.FilePath（路径拼接跨平台）。递归遍历：

```haskell
walkDir root = go ""
  where
    go rel = do
        es <- sort <$> listDirectory (root </> rel)
        concat <$> mapM (\e -> do
            let rel' = if null rel then e else rel </> e
            isDir <- doesDirectoryExist (root </> rel')
            if isDir then go rel' else pure [rel']) es
```

## 16.5 临时文件与二进制

```haskell
(p, h) <- openTempFile tmpDir "haskell16.tmp"   -- base 的 System.IO 就有，名字保证不冲突
B.hPutStr h bs; hClose h; B.readFile p          -- 二进制：ByteString 不做编码解释
```

## 16.6 沙盒与清理

示例的 `withScratch`：bracket_ 三段式 + **performGC 先回收悬锁句柄** + 尽力而为删除：

```haskell
withScratch root act = bracket_ setup teardown act
  where
    setup    = createDirectoryIfMissing True dir
    teardown = do performGC                                   -- 让惰性句柄终结器先跑
                  removeDirectoryRecursive dir `catch` \_ -> pure ()
```

## 16.7 坑位清单

1. **writeFile 默认 GBK**（Windows）：中文乱码源头——显式 UTF-8 句柄（16.1）。
2. **惰性读句柄锁文件到 GC**：同名写直接 IOException、删目录 permission denied（16.2、16.6
   ——本教程开发中两度中招，故有 performGC 兜底）。
3. **Linux 静默清空**：跨平台代码干脆别写"读-改-写同名"——严格读（16.2）。
4. **CRLF**：文本模式写出 `\r\n`、二进制读看得见——归一化 `\r\n → \n`（16.3）。
5. **listDirectory 顺序不定**：断言/展示前 sort（16.4）。
