-- 16 文件与目录：惰性读坑、严格读、目录遍历、临时文件、二进制
-- 运行：ghc -v0 --make main.hs -o 16.exe && ./16.exe
module Main (main) where

import Ch16
import Control.Exception (IOException, try)
import qualified Data.ByteString as B
import qualified Data.Text as T
import Data.Text.Encoding (encodeUtf8)
import System.Directory (createDirectoryIfMissing)
import System.FilePath ((</>))
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    putStrLn "==[ 16 · 文件 ]=="
    withScratch "." $ do
        let sandbox = "." </> scratchName
            demo = sandbox </> "demo.txt"

        -- ═══ 16.1 写、读、追加（写一律用显式 UTF-8——writeFile 默认走 GBK 代码页！）
        writeFileUtf8 demo "第一行\n第二行\n"
        appendLine demo "第三行"
        c1 <- readStrict demo
        putStrLn ("追加后内容行数 = " ++ show (countLines c1))

        -- ═══ 16.2 严格版"读-改-写"：内容完好
        writeFileUtf8 demo "hello strict world"
        toUpperFileStrict demo
        c3 <- readStrict demo
        putStrLn ("严格版 toUpper = " ++ show c3)

        -- ═══ 16.3 目录树与递归遍历（先 sort 才可断言——listDirectory 顺序不定）
        createDirectoryIfMissing True (sandbox </> "sub" </> "deep")
        writeFileUtf8 (sandbox </> "sub" </> "deep" </> "x.txt") "x"
        writeFileUtf8 (sandbox </> "top.txt") "t"
        files <- treeDump sandbox
        mapM_ putStrLn ("  遍历: " : map ("    " ++) files)

        -- ═══ 16.4 临时文件往返
        tr <- tempRoundtrip "临时文件中文往返"
        putStrLn ("tempRoundtrip = " ++ show tr)

        -- ═══ 16.5 二进制往返（UTF-8 字节原样）
        let bytes = encodeUtf8 (T.pack "二进制字节")
        back <- binaryRoundtrip bytes
        putStrLn ("binaryRoundtrip 字节数 = " ++ show (B.length back))

        -- ═══ 16.6 惰性读 + 同名写（坑演示放最后：未消费的惰性句柄会锁文件到 GC）
        -- Windows 实测：写端被未关的读句柄锁住，直接抛 IOException；
        -- Linux 上更阴险——不报错、文件静默清空。两平台的正解都是先严格读
        let lazyFile = sandbox </> "lazy.txt"
        writeFileUtf8 lazyFile "hello lazy world"
        outcome <- try (toUpperFileLazy lazyFile) :: IO (Either IOException ())
        c2 <- readStrict lazyFile
        putStrLn ("坑版 toUpper 结果 = "
                  ++ either (const "IO 锁冲突（已捕获）") (const "意外成功") outcome
                  ++ "，内容仍是 " ++ show c2)

        -- ═══ 16.7 自检
        check "追加三行" (countLines c1) 3
        check "追加末行" (foldl (\_ x -> x) "" (lines c1)) "第三行"   -- 全函数版 last
        check "严格版大写" c3 "HELLO STRICT WORLD"
        check "遍历三个文件" (length files) 3
        check "遍历有序（DFS+字典序）"
              files ["demo.txt", "sub" </> "deep" </> "x.txt", "top.txt"]
        check "临时往返" tr "临时文件中文往返"
        check "二进制往返" back bytes
        check "坑版抛锁异常" (either (const True) (const False) outcome) True
        check "坑版内容未损" c2 "hello lazy world"

    putStrLn "==== 16 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
