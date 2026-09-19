-- Ch12 库模块：字符串三件套——String/Text/ByteString、转换表、码点与字节、OverloadedStrings
{-# LANGUAGE OverloadedStrings #-}

module Ch12
    ( shoutUp, wordCount, titleCase
    , tlen, utf8Bytes, toBytes
    , decodeSafe, fromSafe
    , classifyLine
    ) where

import Data.Char (toUpper)
import qualified Data.ByteString as B
import qualified Data.Text as T
import Data.Text.Encoding (decodeUtf8', encodeUtf8)
import Data.Text.Encoding.Error (UnicodeException)   -- text 2.x：异常类型搬到了 .Error 子模块
import Data.Word (Word8)

-- ═══ 12.1 String 就是 [Char]：所有列表函数直接可用（但慢）
shoutUp :: String -> String
shoutUp = map toUpper

-- ═══ 12.2 Text：紧凑 UTF-16→（text 2.x 起）UTF-8 内部表示，工程首选
wordCount :: T.Text -> Int
wordCount = length . T.words          -- T.words 按空白切；length 此处 O(n)（String 的是 O(n) 同样）

titleCase :: T.Text -> T.Text
titleCase = T.unwords . map capitalize . T.words
  where
    capitalize w = case T.uncons w of
        Nothing      -> T.empty
        Just (c, cs) -> T.cons (toUpper c) cs

-- ═══ 12.3 码点 vs 字节：T.length 数码点，ByteString 数字节
tlen :: T.Text -> Int
tlen = T.length

utf8Bytes :: T.Text -> Int
utf8Bytes = B.length . encodeUtf8

toBytes :: T.Text -> B.ByteString
toBytes = encodeUtf8

-- ═══ 12.4 解码是可能失败的：decodeUtf8' 给 Either（decodeUtf8 直接抛异常）
decodeSafe :: B.ByteString -> Either UnicodeException T.Text
decodeSafe = decodeUtf8'

fromSafe :: B.ByteString -> T.Text
fromSafe b = either (const T.empty) id (decodeUtf8' b)   -- 失败给空串（演示用）

-- ═══ 12.5 按行分类：Text 的 splitOn/lines 实战
classifyLine :: T.Text -> T.Text
classifyLine line
  | T.null (T.strip line)        = "<空行>"
  | "//" `T.isPrefixOf` line     = "<注释> " <> line
  | otherwise                    = "<代码> " <> line
