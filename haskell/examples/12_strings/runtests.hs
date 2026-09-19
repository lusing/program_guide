-- 12 测试套件
{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Ch12
import Control.Monad (unless)
import qualified Data.ByteString as B
import qualified Data.Text as T
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
    s1 <- runSuite "String 与 Text"
        [ expectEq "大写" (shoutUp "abc") "ABC"
        , expectEq "反转" (reverse "abc") "cba"
        , expectEq "词数" (wordCount "the quick brown fox") 4
        , expectEq "词数空白" (wordCount "   ") 0
        , expectEq "首字母大写" (titleCase "hello world again") "Hello World Again"
        , expectEq "Text 拼接" (T.append "ab" "cd") "abcd"
        , expectEq "Text 切分" (T.splitOn "," "a,b,c") ["a", "b", "c"]
        , expectEq "Text 大写" (T.toUpper "héllo") "HÉLLO"
        ]
    s2 <- runSuite "码点与字节"
        [ expectEq "中文码点" (tlen "中文") 2
        , expectEq "中文字节" (utf8Bytes "中文") 6
        , expectEq "英文等长" (utf8Bytes "abc") 3
        , expectEq "空串" (utf8Bytes "") 0
        , expectEq "emoji 码点" (tlen "🇨🇳") 2
        , expectEq "emoji 字节" (utf8Bytes "🇨🇳") 8
        ]
    s3 <- runSuite "编解码"
        [ expectEq "往返" (decodeSafe (toBytes "你好")) (Right "你好")
        , expectEq "坏字节" (either (const "失败") (const "成功") (decodeSafe (B.pack [0xFF, 0xFE]))) "失败"
        , expectEq "fromSafe 兜底" (fromSafe (B.pack [0xFF])) ""
        , expectEq "分类空行" (classifyLine "   ") "<空行>"
        , expectEq "分类注释" (classifyLine "// note") "<注释> // note"
        , expectEq "分类代码" (classifyLine "x = 1") "<代码> x = 1"
        ]
    unless (s1 && s2 && s3) exitFailure
    putStrLn "==== 12 结束 ===="
