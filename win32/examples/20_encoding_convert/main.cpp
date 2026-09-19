// 20_encoding_convert — 代码页 / UTF-8 互转 / 非法序列检测 / StrSafe
//
// 对应教程：docs/12-字符编码与字符串.md
#include <windows.h>
#include <strsafe.h>
#include <stdio.h>
#include <locale.h>

static void DumpHex(const wchar_t* label, const char* bytes, int len) {
    wprintf(L"    %s（%d 字节）:", label, len);
    for (int i = 0; i < len; ++i) wprintf(L" %02X", (unsigned char)bytes[i]);
    wprintf(L"\n");
}

int wmain() {
    _wsetlocale(LC_ALL, L"");

    const wchar_t* text = L"Win32 编码";

    // 1) 宽字符 → UTF-8：两段式（先问长度再转换——几乎所有转换 API 的套路）
    int need = WideCharToMultiByte(CP_UTF8, 0, text, -1, nullptr, 0, nullptr, nullptr);
    char utf8[64];
    WideCharToMultiByte(CP_UTF8, 0, text, -1, utf8, need, nullptr, nullptr);
    DumpHex(L"UTF-8     ", utf8, need - 1);

    // 2) UTF-8 → 宽字符（回来），往返校验
    int need2 = MultiByteToWideChar(CP_UTF8, 0, utf8, -1, nullptr, 0);
    wchar_t back[64];
    MultiByteToWideChar(CP_UTF8, 0, utf8, -1, back, need2);
    wprintf(L"    往返一致：%s\n", wcscmp(back, text) == 0 ? L"是" : L"否");

    // 3) 同一段文字在 GBK(936) 下的形态：字节完全不同
    int need3 = WideCharToMultiByte(936, 0, text, -1, nullptr, 0, nullptr, nullptr);
    char gbk[64];
    WideCharToMultiByte(936, 0, text, -1, gbk, need3, nullptr, nullptr);
    DumpHex(L"GBK (936) ", gbk, need3 - 1);
    wprintf(L"    →「乱码」的本质：按 A 编码写、按 B 编码读\n");

    // 4) 非法序列：MB_ERR_INVALID_CHARS 让坏输入报错而不是静默替换
    char bad[] = { (char)0xFF, (char)0xFE, 'A', 0 };
    int r = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, bad, -1, nullptr, 0);
    if (r == 0) {
        wprintf(L"    非法 UTF-8 被拒绝，GetLastError()=%lu\n", GetLastError());
    }

    // 5) StrSafe：长度感知的字符串函数，杜绝缓冲区溢出
    wchar_t dst[8];
    HRESULT hr = StringCchCopyW(dst, 8, L"1234567890");   // 10 字符塞 8 容量
    if (FAILED(hr)) {
        wprintf(L"    StringCchCopyW 拒绝溢出：0x%08lX\n", (unsigned long)hr);
        wprintf(L"    dst 安全截断为：%s\n", dst);
    }
    size_t len = 0;
    StringCchLengthW(dst, 8, &len);
    wprintf(L"    StringCchLengthW：dst 有效长度 %zu\n", len);
    return 0;
}
