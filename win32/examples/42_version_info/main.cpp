// 42_version_info —— 第 34 章：VERSIONINFO 三件套读取（version.lib）
// 无参数 = 先读自己（教学点：没有 .rc 的程序"没有版本资源"），
//           再读 kernel32.dll（完整链路，产品版本即操作系统版本号）；
// 带参数 = 读指定文件的版本资源。
#include <windows.h>
#include <stdio.h>
#include <string>
#include <vector>
#pragma comment(lib, "version.lib")

// 宽串 → UTF-8 再走窄 printf（%ls 遇中文在 C locale 会中断整条输出，39 例教训）
static std::string U8(const wchar_t* s) {
    int n = WideCharToMultiByte(CP_UTF8, 0, s, -1, nullptr, 0, nullptr, nullptr);
    if (n <= 0) return {};
    std::string r((size_t)n - 1, '\0');
    WideCharToMultiByte(CP_UTF8, 0, s, -1, r.data(), n, nullptr, nullptr);
    return r;
}

static void DumpVersion(const wchar_t* label, const wchar_t* path) {
    printf("---- %s ----\n", U8(label).c_str());
    printf("文件: %s\n", U8(path).c_str());

    // ① 问尺寸（两段式模式又一例；返回 0 = 这个文件没有版本资源）
    //    Ex 版旗标只有 LOCALISED/NEUTRAL/PREFETCHED（注意英式拼写），默认 0 即本机行为
    DWORD handle = 0;
    DWORD size = GetFileVersionInfoSizeExW(0, path, &handle);
    if (size == 0) {
        printf("结果: 没有版本资源（GetFileVersionInfoSizeExW = 0，LastError = %lu）\n",
               GetLastError());
        printf("      —— 没有 .rc 里 VERSIONINFO 的程序就是这个样子（34.3）\n\n");
        return;
    }

    // ② 取数据块
    std::vector<BYTE> data(size);
    if (!GetFileVersionInfoW(path, 0, size, data.data())) {
        printf("GetFileVersionInfoW 失败 %lu\n\n", GetLastError());
        return;
    }

    // ③a 二进制段：文件版本 / 产品版本（各 32 位打包两段 16 位）
    VS_FIXEDFILEINFO* ffi = nullptr; UINT ffiLen = 0;
    if (VerQueryValueW(data.data(), L"\\", (void**)&ffi, &ffiLen) && ffi) {
        printf("FileVersion    : %u.%u.%u.%u\n",
               HIWORD(ffi->dwFileVersionMS),    LOWORD(ffi->dwFileVersionMS),
               HIWORD(ffi->dwFileVersionLS),    LOWORD(ffi->dwFileVersionLS));
        printf("ProductVersion : %u.%u.%u.%u\n",
               HIWORD(ffi->dwProductVersionMS), LOWORD(ffi->dwProductVersionMS),
               HIWORD(ffi->dwProductVersionLS), LOWORD(ffi->dwProductVersionLS));
    }

    // ③b 字符串段：先问 Translation（语言+代码页），再拼子块路径查询
    struct { WORD lang, codepage; }* langs = nullptr; UINT langLen = 0;
    if (VerQueryValueW(data.data(), L"\\VarFileInfo\\Translation", (void**)&langs, &langLen)
        && langs && langLen >= sizeof(*langs)) {
        wchar_t sub[80];
        static const wchar_t* keys[] = {
            L"FileDescription", L"CompanyName", L"ProductName",
            L"FileVersion", L"ProductVersion", L"LegalCopyright",
        };
        for (const wchar_t* key : keys) {
            swprintf_s(sub, L"\\StringFileInfo\\%04x%04x\\%s",
                       langs[0].lang, langs[0].codepage, key);
            wchar_t* val = nullptr; UINT valLen = 0;
            if (VerQueryValueW(data.data(), sub, (void**)&val, &valLen) && val && val[0])
                printf("%-14s : %s\n", U8(key).c_str(), U8(val).c_str());
        }
    }
    printf("\n");
}

int wmain(int argc, wchar_t** argv) {
    if (argc > 1) {
        DumpVersion(L"指定文件", argv[1]);
        return 0;
    }
    wchar_t self[MAX_PATH];
    GetModuleFileNameW(nullptr, self, MAX_PATH);

    printf("=== 版本资源读取器：GetFileVersionInfo 三件套 ===\n\n");
    DumpVersion(L"本程序（自己 build、无 .rc）", self);
    DumpVersion(L"kernel32.dll（系统组件，产品版本 = 操作系统版本）",
                L"C:\\Windows\\System32\\kernel32.dll");
    printf("提示：带参数可读任意 exe/dll，例如 42_version_info.exe C:\\Windows\\explorer.exe\n");
    return 0;
}
