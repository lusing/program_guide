using System.Text;

namespace NotepadPlus.Services;

/// <summary>BOM 检测 + 严格 UTF-8 试解码 + GB18030 回退的编码识别。</summary>
public static class EncodingDetector
{
    public static (Encoding Encoding, bool HasBom) Detect(ReadOnlySpan<byte> bytes)
    {
        // ① BOM 是最可靠的信号，三种文本 BOM 逐一比对
        if (bytes.Length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF)
            return (new UTF8Encoding(encoderShouldEmitUTF8Identifier: true), true);
        if (bytes.Length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE)
            return (Encoding.Unicode, true);              // UTF-16 LE
        if (bytes.Length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF)
            return (Encoding.BigEndianUnicode, true);     // UTF-16 BE

        // ② 无 BOM：先按严格 UTF-8 试解码，遇到非法序列再回退 GB18030
        try
        {
            _ = new UTF8Encoding(false, throwOnInvalidBytes: true).GetCharCount(bytes);
            return (new UTF8Encoding(false), false);
        }
        catch (DecoderFallbackException)
        {
            return (Encoding.GetEncoding("GB18030"), false);
        }
    }
}
