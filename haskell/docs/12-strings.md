# 12 · 字符串三件套 ⭐

> 对应示例：`examples/12_strings/`

## 12.1 String 就是 [Char]

```haskell
type String = [Char]
```

列表函数全部白拿（`map toUpper`、`reverse`、`filter`），但每个字符是一个装箱的堆对象——
**性能上是最慢的字符串**。短串、教学、GHCi 里用；正文处理换 Text。

## 12.2 Text：工程默认

```haskell
import qualified Data.Text as T

T.pack "hello"          -- String → Text（显式转换，或 OverloadedStrings）
T.words / T.lines       -- 切分
T.splitOn ","           -- 按串切
T.toUpper               -- Unicode 感知（"héllo" → "HÉLLO"）
T.intercalate / T.append / T.cons
```

**OverloadedStrings** 扩展让字面量多态（`"abc" :: Text` 无需 pack）——Text 重度代码标配：

```haskell
{-# LANGUAGE OverloadedStrings #-}
```

## 12.3 ByteString：字节流

```haskell
import qualified Data.ByteString as B
```

元素是 `Word8`（原始字节）——文件/网络/协议层的正确类型，不做任何编码解释。

## 12.4 转换表（背下来）

```
String ── T.pack ──→ Text ── encodeUtf8 ──→ ByteString
String ←─ T.unpack ─ Text ←─ decodeUtf8' ── ByteString
```

`decodeUtf8'` 返回 `Either UnicodeException Text`——**解码可能失败**；`decodeUtf8` 直接抛。

## 12.5 码点 vs 字节（实测）

```haskell
tlen "中文"          -- 2（Data.Text 数码点）
utf8Bytes "中文"     -- 6（UTF-8 每汉字 3 字节）
utf8Bytes "🇨🇳"      -- 8（两个码点 × 4 字节）
tlen "🇨🇳"           -- 2
```

`T.length` 数**码点**；`B.length` 数**字节**；两者都对，问的问题不同。字素簇（用户眼中的
"一个字"）需要 `text-icu` 等包——生态介绍层。

## 12.6 编解码实战

```haskell
decodeSafe = decodeUtf8'                  -- Either 版本（安全）
fromSafe b = either (const T.empty) id (decodeUtf8' b)   -- 兜底空串
classifyLine line
  | T.null (T.strip line)    = "<空行>"
  | "//" `T.isPrefixOf` line = "<注释> " <> line
  | otherwise                = "<代码> " <> line
```

## 12.7 坑位清单

1. **UnicodeException 的家搬了**：text 2.x 里在 `Data.Text.Encoding.Error`——从
   `Data.Text.Encoding` 导入会报 does not export（实测踩过）（12.4）。
2. **decodeUtf8 抛异常版别碰**：外部数据一律 `decodeUtf8'` + 处理 Left（12.6）。
3. **码点 ≠ 字节 ≠ 字素簇**：三个"长度"三个数——报告口径先问清楚（12.5）。
4. **String 拼接 O(n²)**：循环里 `acc ++ s` 换 `Text` + Builder（19 章实测对照）（12.1）。
5. **OverloadedStrings 是扩展**：不开的话 `"abc" :: ByteString` 编译不过（12.2）。
