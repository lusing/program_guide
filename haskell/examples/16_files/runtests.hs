-- 16 测试套件（全部 IO 在 scratch 沙盒内，bracket_ + performGC 保证清理）
module Main (main) where

import Ch16
import Control.Exception (IOException, try)
import Control.Monad (unless)
import qualified Data.ByteString as B
import qualified Data.Text as T
import Data.Text.Encoding (encodeUtf8)
import System.Directory (createDirectoryIfMissing)
import System.FilePath ((</>))
import System.Exit (exitFailure)
import System.IO (hSetEncoding, stderr, stdout, utf8)

data Case = Case { name :: String, ok :: Bool, detail :: String }

expectEq :: (Eq a, Show a) => String -> a -> a -> Case
expectEq n got want
  | got == want = Case n True ""
  | otherwise   = Case n False (n ++ ": 得到 " ++ show got ++ " 期望 " ++ show want)

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
    withScratch "." $ do
        let sandbox = "." </> scratchName
            demo = sandbox </> "t.txt"
        -- 16.1 读写追加
        writeFileUtf8 demo "aa\nbb\n中文行\n"
        appendLine demo "cc"
        c1 <- readStrict demo
        s1 <- runSuite "读写追加" $
            [ expectEq "行数" (countLines c1) 4
            , expectEq "末行" (last (lines c1)) "cc"
            , expectEq "中文完好" (lines c1 !! 2) "中文行"
            , expectEq "countLines 空" (countLines "") 0
            ]
        -- 16.2 严格版
        writeFileUtf8 demo "mixed Case Text"
        toUpperFileStrict demo
        c3 <- readStrict demo
        s2 <- runSuite "严格读改写" $
            [ expectEq "严格版保内容" c3 "MIXED CASE TEXT"
            ]
        -- 16.3 遍历
        createDirectoryIfMissing True (sandbox </> "b" </> "c")
        writeFileUtf8 (sandbox </> "b" </> "c" </> "z.txt") "z"
        writeFileUtf8 (sandbox </> "b" </> "a.txt") "a"
        files <- treeDump sandbox
        s3 <- runSuite "遍历" $
            [ expectEq "数量" (length files) 3
            , expectEq "有序" files ["b" </> "a.txt", "b" </> "c" </> "z.txt", "t.txt"]
            , expectEq "含深层" ("b" </> "c" </> "z.txt" `elem` files) True
            ]
        -- 16.4 临时与二进制
        tr <- tempRoundtrip "abc中文"
        br <- binaryRoundtrip (encodeUtf8 (T.pack "OK") <> B.pack [0, 255])
        s4 <- runSuite "临时与二进制" $
            [ expectEq "临时往返" tr "abc中文"
            , expectEq "二进制往返" br (encodeUtf8 (T.pack "OK") <> B.pack [0, 255])
            , expectEq "字节保真" (B.length br) 4
            ]
        -- 16.5 惰性坑（放最后：句柄锁到 GC）
        writeFileUtf8 demo "lazy test content"
        lazyResult <- try (toUpperFileLazy demo) :: IO (Either IOException ())
        c2 <- readStrict demo
        s5 <- runSuite "惰性坑" $
            [ expectEq "坑版抛锁异常" (either (const True) (const False) lazyResult) True
            , expectEq "坑版内容未损" c2 "lazy test content"
            ]
        unless (s1 && s2 && s3 && s4 && s5) exitFailure
    putStrLn "==== 16 结束 ===="
