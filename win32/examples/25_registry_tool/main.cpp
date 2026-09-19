// 25_registry_tool — HKCU 下的注册表增删改查与枚举全流程
//
// 对应教程：docs/21-注册表.md
// 控制台程序；全部操作在 HKEY_CURRENT_USER，标准用户即可
#include <windows.h>
#include <stdio.h>
#include <locale.h>

static const wchar_t* kRoot = L"Software\\GuideWin32";
static const wchar_t* kSubKey = L"Software\\GuideWin32\\Demo";

static const wchar_t* TypeName(DWORD type) {
    switch (type) {
    case REG_SZ:         return L"REG_SZ";
    case REG_EXPAND_SZ:  return L"REG_EXPAND_SZ";
    case REG_DWORD:      return L"REG_DWORD";
    case REG_QWORD:      return L"REG_QWORD";
    case REG_BINARY:     return L"REG_BINARY";
    default:             return L"其他";
    }
}

int wmain() {
    _wsetlocale(LC_ALL, L"");

    // ── 1. 创建键（已存在则打开）────────────────────────────────
    HKEY key;
    LSTATUS st = RegCreateKeyExW(HKEY_CURRENT_USER, kSubKey, 0, nullptr,
                                 REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS,
                                 nullptr, &key, nullptr);
    if (st != ERROR_SUCCESS) {
        wprintf(L"RegCreateKeyExW 失败 %ld\n", (long)st);
        return 1;
    }
    wprintf(L"[1] 已创建/打开 HKCU\\%s\n", kSubKey);

    // ── 2. 写三种类型的值 ──────────────────────────────────────
    DWORD count = 42;
    BYTE blob[] = { 0xDE, 0xAD, 0xBE, 0xEF };
    const wchar_t* hello = L"你好，注册表";
    RegSetValueExW(key, L"计数", 0, REG_DWORD,
                   (const BYTE*)&count, sizeof(count));
    RegSetValueExW(key, L"问候", 0, REG_SZ,
                   (const BYTE*)hello,
                   (DWORD)((wcslen(hello) + 1) * sizeof(wchar_t)));   // 含结尾 NUL
    RegSetValueExW(key, L"指纹", 0, REG_BINARY, blob, sizeof(blob));
    wprintf(L"[2] 写入 REG_DWORD / REG_SZ / REG_BINARY\n");

    // ── 3. 读回：按类型分支 ────────────────────────────────────
    wchar_t text[64]; DWORD type = 0, size = sizeof(text);
    st = RegQueryValueExW(key, L"问候", nullptr, &type, (BYTE*)text, &size);
    if (st == ERROR_SUCCESS && type == REG_SZ) {
        wprintf(L"[3] 问候 = %s\n", text);
    }
    DWORD num = 0; size = sizeof(num);
    RegQueryValueExW(key, L"计数", nullptr, &type, (BYTE*)&num, &size);
    wprintf(L"    计数 = %lu\n", (unsigned long)num);

    // ── 4. 建子键，然后枚举值与子键 ─────────────────────────────
    HKEY sub;
    RegCreateKeyExW(key, L"子键甲", 0, nullptr, REG_OPTION_NON_VOLATILE,
                    KEY_ALL_ACCESS, nullptr, &sub, nullptr);
    RegCloseKey(sub);
    RegCreateKeyExW(key, L"子键乙", 0, nullptr, REG_OPTION_NON_VOLATILE,
                    KEY_ALL_ACCESS, nullptr, &sub, nullptr);
    RegCloseKey(sub);

    wprintf(L"[4] 枚举值：\n");
    for (DWORD i = 0; ; ++i) {
        wchar_t name[64]; DWORD nameLen = 64;
        st = RegEnumValueW(key, i, name, &nameLen, nullptr,
                           &type, nullptr, nullptr);
        if (st == ERROR_NO_MORE_ITEMS) break;
        if (st != ERROR_SUCCESS) break;
        wprintf(L"    值 %s（%s）\n", name, TypeName(type));
    }
    wprintf(L"    枚举子键：\n");
    for (DWORD i = 0; ; ++i) {
        wchar_t name[64]; DWORD nameLen = 64;
        st = RegEnumKeyExW(key, i, name, &nameLen,
                           nullptr, nullptr, nullptr, nullptr);
        if (st == ERROR_NO_MORE_ITEMS) break;
        if (st != ERROR_SUCCESS) break;
        wprintf(L"    键 %s\n", name);
    }

    // ── 5. 清场：整棵删除（环境还原）────────────────────────────
    RegCloseKey(key);
    st = RegDeleteTreeW(HKEY_CURRENT_USER, kRoot);
    wprintf(L"[5] RegDeleteTreeW 清场：%s\n",
            st == ERROR_SUCCESS ? L"已删除" : L"失败");
    return 0;
}
