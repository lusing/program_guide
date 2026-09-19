// 24_dll_plugin — 插件宿主：扫描 exe 旁的 DLL，显式加载并调用
//
// 对应教程：docs/20-DLL进阶与插件系统.md
#include "plugin_api.h"
#include <windows.h>
#include <stdio.h>
#include <locale.h>

int wmain() {
    _wsetlocale(LC_ALL, L"");

    // exe 所在目录 = build\（插件 DLL 也输出到那里，靠"应用程序目录优先"找到）
    wchar_t dir[MAX_PATH];
    GetModuleFileNameW(nullptr, dir, MAX_PATH);
    wchar_t* slash = wcsrchr(dir, L'\\');
    if (slash) *slash = 0;

    wchar_t pattern[MAX_PATH];
    swprintf_s(pattern, MAX_PATH, L"%s\\*.dll", dir);

    WIN32_FIND_DATAW fd;
    HANDLE find = FindFirstFileW(pattern, &fd);
    if (find == INVALID_HANDLE_VALUE) {
        wprintf(L"没有找到任何 DLL\n");
        return 1;
    }
    int loaded = 0;
    do {
        HMODULE hMod = LoadLibraryW(fd.cFileName);   // 裸名：搜索顺序生效
        if (!hMod) {
            wprintf(L"[跳过] %s 加载失败 %lu\n", fd.cFileName, GetLastError());
            continue;
        }
        PFN_query_plugin query =
            (PFN_query_plugin)GetProcAddress(hMod, "query_plugin");
        if (!query) {
            // 不是本宿主的插件（如 build\ 里别的示例 DLL）——正常，静默跳过
            FreeLibrary(hMod);
            continue;
        }
        const PluginInfo* info = query();
        if (info->apiVersion != PLUGIN_API_VERSION) {
            wprintf(L"[拒绝] %s 版本不匹配（插件 %d，宿主 %d）\n",
                    info->name, info->apiVersion, PLUGIN_API_VERSION);
            FreeLibrary(hMod);
            continue;
        }
        wprintf(L"[插件] %-14s area(2.5) = %.4f\n", info->name, info->area(2.5));
        ++loaded;
        FreeLibrary(hMod);
    } while (FindNextFileW(find, &fd));
    FindClose(find);

    wprintf(L"共加载 %d 个插件\n", loaded);
    return 0;
}
