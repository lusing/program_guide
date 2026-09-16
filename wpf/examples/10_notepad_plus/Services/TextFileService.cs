using System.IO;
using System.Text;

namespace NotepadPlus.Services;

/// <summary>异步读写文本文件，读出时识别编码，写入时保留原编码。</summary>
public static class TextFileService
{
    public static async Task<(string Content, Encoding Encoding)> ReadAsync(string path)
    {
        var bytes = await File.ReadAllBytesAsync(path).ConfigureAwait(false);
        var (encoding, hasBom) = EncodingDetector.Detect(bytes);
        var content = encoding.GetString(StripBom(bytes, encoding, hasBom));
        return (content, encoding);
    }

    public static Task WriteAsync(string path, string content, Encoding encoding)
        => File.WriteAllTextAsync(path, content, encoding);   // WriteAllText 自动写 preamble(BOM)

    private static ReadOnlySpan<byte> StripBom(ReadOnlySpan<byte> bytes, Encoding encoding, bool hasBom)
    {
        if (!hasBom) return bytes;
        return bytes[encoding.GetPreamble().Length..];        // UTF-8→3 字节, UTF-16→2 字节
    }
}
