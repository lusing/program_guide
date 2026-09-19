// 21_security_descriptors — 令牌 / 完整性级别 / 给文件写 DACL 并读回
//
// 对应教程：docs/17-内核对象与安全.md
// 控制台程序；标准用户即可运行（只碰自己创建的临时文件）
#include <windows.h>
#include <aclapi.h>
#include <accctrl.h>
#include <stdio.h>
#include <locale.h>

static const wchar_t* IntegrityName(DWORD rid) {
    if (rid < 0x1000) return L"Low";
    if (rid < 0x3000) return L"Medium";      // 普通用户进程默认档
    if (rid < 0x4000) return L"High";        // 管理员提升后档位
    return L"System";
}

int wmain() {
    _wsetlocale(LC_ALL, L"");

    // ── 1. 令牌：进程的"身份证" ──────────────────────────────────
    HANDLE token;
    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &token)) {
        wprintf(L"OpenProcessToken 失败 %lu\n", GetLastError());
        return 1;
    }
    DWORD len = 0;

    GetTokenInformation(token, TokenElevation, nullptr, 0, &len);
    TOKEN_ELEVATION elev = {};
    GetTokenInformation(token, TokenElevation, &elev, len, &len);
    wprintf(L"[1] UAC 提升：%s\n",
            elev.TokenIsElevated ? L"是（管理员）" : L"否（标准用户）");

    GetTokenInformation(token, TokenIntegrityLevel, nullptr, 0, &len);
    PTOKEN_MANDATORY_LABEL ml = (PTOKEN_MANDATORY_LABEL)LocalAlloc(LMEM_FIXED, len);
    GetTokenInformation(token, TokenIntegrityLevel, ml, len, &len);
    DWORD count = *GetSidSubAuthorityCount(ml->Label.Sid);
    DWORD rid = *GetSidSubAuthority(ml->Label.Sid, count - 1);
    wprintf(L"[2] 完整性级别：RID 0x%04lX（%s）\n",
            (unsigned long)rid, IntegrityName(rid));
    LocalFree(ml);
    CloseHandle(token);

    // ── 2. 给临时文件写 DACL：自己全权 / Everyone 只读 ─────────────
    wchar_t path[MAX_PATH];
    GetTempPathW(MAX_PATH, path);
    wcscat_s(path, L"win32_sec_demo.txt");
    HANDLE h = CreateFileW(path, GENERIC_WRITE, 0, nullptr,
                           CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (h != INVALID_HANDLE_VALUE) CloseHandle(h);

    // Everyone 的 SID（S-1-1-0）：用权威常量拼，别背字节序列
    PSID everyone = nullptr;
    SID_IDENTIFIER_AUTHORITY worldAuth = SECURITY_WORLD_SID_AUTHORITY;
    AllocateAndInitializeSid(&worldAuth, 1, SECURITY_WORLD_RID,
                             0, 0, 0, 0, 0, 0, 0, &everyone);

    wchar_t userName[64];
    DWORD nameLen = 64;
    GetUserNameW(userName, &nameLen);

    EXPLICIT_ACCESSW ea[2] = {};
    ea[0].grfAccessPermissions = GENERIC_ALL;             // 自己：全权
    ea[0].grfAccessMode = GRANT_ACCESS;
    ea[0].grfInheritance = NO_INHERITANCE;
    ea[0].Trustee.TrusteeForm = TRUSTEE_IS_NAME;
    ea[0].Trustee.ptstrName = userName;
    ea[1].grfAccessPermissions = GENERIC_READ;            // Everyone：只读
    ea[1].grfAccessMode = GRANT_ACCESS;
    ea[1].grfInheritance = NO_INHERITANCE;
    ea[1].Trustee.TrusteeForm = TRUSTEE_IS_SID;           // SID 免受本地化名影响
    ea[1].Trustee.ptstrName = (LPWSTR)everyone;

    PSECURITY_DESCRIPTOR sd = nullptr;
    ULONG sdLen = 0;
    BuildSecurityDescriptorW(nullptr, nullptr, 2, ea, 0, nullptr,
                             nullptr, &sdLen, &sd);
    BOOL present = FALSE, defaulted = FALSE;
    PACL dacl = nullptr;
    GetSecurityDescriptorDacl(sd, &present, &dacl, &defaulted);
    SetNamedSecurityInfoW(path, SE_FILE_OBJECT, DACL_SECURITY_INFORMATION,
                          nullptr, nullptr, dacl, nullptr);
    wprintf(L"[3] 已写入 DACL：%s\n", path);

    // ── 3. 读回验证：数 ACE、把 SID 翻译回账户名 ───────────────────
    PSID owner = nullptr; PACL readAcl = nullptr;
    PSECURITY_DESCRIPTOR rsd = nullptr;
    GetNamedSecurityInfoW(path, SE_FILE_OBJECT,
                          OWNER_SECURITY_INFORMATION | DACL_SECURITY_INFORMATION,
                          &owner, nullptr, &readAcl, nullptr, &rsd);
    ACL_SIZE_INFORMATION ai = {};
    GetAclInformation(readAcl, &ai, sizeof(ai), AclSizeInformation);
    wprintf(L"[4] 读回 DACL：%lu 条 ACE\n", (unsigned long)ai.AceCount);
    for (DWORD i = 0; i < ai.AceCount; ++i) {
        ACCESS_ALLOWED_ACE* ace = nullptr;
        if (GetAce(readAcl, i, (void**)&ace)) {
            wchar_t name[64], domain[64];
            DWORD nLen = 64, dLen = 64;
            SID_NAME_USE use;
            LookupAccountSidW(nullptr, &ace->SidStart, name, &nLen,
                              domain, &dLen, &use);
            wprintf(L"    ACE%lu：%s\\%s 权限掩码 0x%08lX\n",
                    (unsigned long)i, domain, name, (unsigned long)ace->Mask);
        }
    }

    LocalFree(rsd);
    LocalFree(sd);
    FreeSid(everyone);
    DeleteFileW(path);
    wprintf(L"演示结束（临时文件已删除）\n");
    return 0;
}
