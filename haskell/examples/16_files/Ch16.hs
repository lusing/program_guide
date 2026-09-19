-- Ch16 库模块：文件与目录——惰性读坑、严格读、withFile、目录遍历、临时文件、二进制
{-# LANGUAGE OverloadedStrings #-}

module Ch16
    ( toUpperFileLazy, toUpperFileStrict, readStrict
    , writeFileUtf8, appendLine, countLines
    , walkDir, treeDump
    , tempRoundtrip, binaryRoundtrip
    , withScratch, scratchName
    ) where

import Control.Exception (IOException, SomeException, bracket_, catch)
import qualified Data.ByteString as B
import qualified Data.Text as T
import Data.Text.Encoding (decodeUtf8')
import Data.Char (toUpper)
import Data.List (sort)
import System.Directory
    (createDirectoryIfMissing, doesDirectoryExist, getTemporaryDirectory, listDirectory,
     removeDirectoryRecursive, removeFile)
import System.FilePath ((</>))
import System.IO (IOMode (..), hClose, hGetContents, hPutStr, hPutStrLn, openFile, openTempFile,
                  hSetEncoding, utf8)
import System.Mem (performGC)

scratchName :: FilePath
scratchName = "scratch16"

-- ═══ 16.1 经典坑：惰性读 + 同名写 = 文件清空
-- readFile 返回"承诺"；writeFile 先打开（截断）文件，再强制内容——
-- 强制的瞬间才去读，读的已是截断后的空文件
toUpperFileLazy :: FilePath -> IO ()
toUpperFileLazy p = readFile p >>= writeFile p . map toUpper

-- ═══ 16.2 正确姿势：先严格读入内存，再写
toUpperFileStrict :: FilePath -> IO ()
toUpperFileStrict p = do
    c <- readStrict p
    writeFile p (map toUpper c)

-- 严格读：ByteString 一次全量入内存，再按 UTF-8 解码（教学版忽略坏字节）。
-- 坑（Windows 实测）：文本模式写出的 \n 会翻成 \r\n，而 ByteString 读是二进制通道看得见 \r
-- ——统一把 \r\n 归一成 \n，跨平台才稳
readStrict :: FilePath -> IO String
readStrict p = do
    bs <- B.readFile p
    let txt = either (const T.empty) id (decodeUtf8' bs)
    pure (T.unpack (T.replace "\r\n" "\n" txt))

-- ═══ 16.3 显式 UTF-8 写入（坑：writeFile 默认走系统代码页——本机 GBK，中文写出即乱码）
writeFileUtf8 :: FilePath -> String -> IO ()
writeFileUtf8 p s = openFile p WriteMode >>= \h ->
    hSetEncoding h utf8 >> hPutStr h s >> hClose h

appendLine :: FilePath -> String -> IO ()
appendLine p line = openFile p AppendMode >>= \h ->
    hSetEncoding h utf8 >> hPutStrLn h line >> hClose h

countLines :: String -> Int
countLines = length . lines

-- ═══ 16.4 递归遍历（listDirectory 不保证顺序——必须先 sort 才可断言）
walkDir :: FilePath -> IO [FilePath]
walkDir root = go ""
  where
    go rel = do
        es <- sort <$> listDirectory (root </> rel)
        concat <$> mapM (\e -> do
            let rel' = if null rel then e else rel </> e
            isDir <- doesDirectoryExist (root </> rel')
            if isDir then go rel' else pure [rel']) es

treeDump :: FilePath -> IO [FilePath]
treeDump = walkDir

-- ═══ 16.5 临时文件：openTempFile 保证名字不冲突
tempRoundtrip :: String -> IO String
tempRoundtrip s = do
    tmpDir <- getTemporaryDirectory
    (p, h) <- openTempFile tmpDir "haskell16.tmp"
    hSetEncoding h utf8
    hPutStr h s
    hClose h
    c <- readStrict p
    removeFile p
    pure c

-- ═══ 16.6 二进制读写：ByteString 不做任何编码解释
binaryRoundtrip :: B.ByteString -> IO B.ByteString
binaryRoundtrip bs = do
    tmpDir <- getTemporaryDirectory
    (p, h) <- openTempFile tmpDir "haskell16.bin"
    B.hPutStr h bs
    hClose h
    c <- B.readFile p
    removeFile p
    pure c

-- ═══ 16.7 示例沙盒：建 scratch 目录，用完整体删除（bracket_ 保证异常也清理；
-- 惰性句柄可能仍握着文件——先 performGC 让终结器关掉它，删除再尽力而为）
withScratch :: FilePath -> IO a -> IO a
withScratch root act = bracket_ setup teardown act
  where
    dir = root </> scratchName
    setup = createDirectoryIfMissing True dir
    teardown = do
        performGC                                   -- System.Mem：回收仍被惰性 thunk 握住的句柄
        removeDirectoryRecursive dir `catch` \(_ :: SomeException) -> pure ()

-- 惰性 hGetContents 一瞥（句柄由 GHC 在内容读尽后自动关闭；教学版不依赖它）
_lazyUnused :: FilePath -> IO String
_lazyUnused p = openFile p ReadMode >>= \h -> hSetEncoding h utf8 >> hGetContents h
