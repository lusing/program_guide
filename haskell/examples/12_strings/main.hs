-- 12 字符串三件套：String/Text/ByteString、码点 vs 字节、解码失败、转换表
-- 运行：ghc -v0 --make main.hs -o 12.exe && ./12.exe
{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Ch12
import qualified Data.ByteString as B
import qualified Data.Text as T
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    -- ═══ 12.1 String=[Char]：列表函数白拿
    putStrLn "==[ 12 · 字符串 ]=="
    putStrLn ("shoutUp \"haskell\" = " ++ show (shoutUp "haskell"))
    putStrLn ("reverse \"abc\"     = " ++ show (reverse "abc"))        -- 列表反转白拿

    -- ═══ 12.2 Text 工程操作
    putStrLn ("wordCount \"the quick brown fox\" = " ++ show (wordCount "the quick brown fox"))
    putStrLn ("titleCase \"hello world again\"   = " ++ show (titleCase "hello world again"))

    -- ═══ 12.3 码点 vs 字节：同一个字符串的三种"长度"（🇨🇳 是两个码点、8 个字节）
    let zh = "中文" :: T.Text
        flag = "🇨🇳" :: T.Text
    putStrLn ("\"中文\": 码点 " ++ show (tlen zh) ++ " / 字节 " ++ show (utf8Bytes zh))
    putStrLn ("旗子 emoji: 码点 " ++ show (tlen flag) ++ " / 字节 " ++ show (utf8Bytes flag))

    -- ═══ 12.4 编解码往返 + 失败路径
    let bs = toBytes zh
    putStrLn ("encode→decode 往返 = " ++ show (decodeSafe bs))
    putStrLn ("坏字节解码         = " ++ show (fmap T.null (decodeSafe (B.pack [0xFF, 0xFE]))))
    putStrLn ("fromSafe 兜底空串  = " ++ show (fromSafe (B.pack [0xFF])))

    -- ═══ 12.5 splitOn / lines / isPrefixOf
    mapM_ (putStrLn . T.unpack . classifyLine) ["", "// 注释", "x = 1"]

    -- ═══ 12.6 自检
    check "String 大写" (shoutUp "ok") "OK"
    check "词数" (wordCount "a b c") 3
    check "词数空串" (wordCount "") 0
    check "首字母大写" (titleCase "hello world") "Hello World"
    check "中文码点" (tlen "中文") 2
    check "中文字节" (utf8Bytes "中文") 6
    check "英文等长" (utf8Bytes "abc") 3
    check "往返成功" (decodeSafe (toBytes "你好")) (Right "你好")
    check "坏字节失败" (either (const True) (const False) (decodeSafe (B.pack [0xFF]))) True
    check "空行分类" (classifyLine "") "<空行>"
    check "注释分类" (classifyLine "// x") "<注释> // x"

    putStrLn "==== 12 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
