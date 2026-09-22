// Service layer for child-process work: see docs/10-os-integration.md 10.4.
// Plain C++/Win32, no WinRT, no UI -- the page only reports the result.
#include "pch.h"
#include "ToolService.h"

bool RunTool(std::wstring cmdLine, DWORD& exitCode)
{
    STARTUPINFOW si{};
    si.cb = sizeof(si);
    PROCESS_INFORMATION pi{};

    // CreateProcessW 会就地改写命令行缓冲，所以必须传可写的缓冲区，
    // 传字符串字面量或 c_str() 是未定义行为
    if (!CreateProcessW(nullptr, cmdLine.data(), nullptr, nullptr,
                        FALSE, 0, nullptr, nullptr, &si, &pi))
    {
        exitCode = static_cast<DWORD>(GetLastError());
        return false;
    }

    WaitForSingleObject(pi.hProcess, INFINITE);   // 阻塞等待：必须在后台线程，见 10.1

    DWORD code{};
    BOOL gotCode = GetExitCodeProcess(pi.hProcess, &code);

    // 句柄即资源：等完、取完码再关
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);

    if (!gotCode) { return false; }
    exitCode = code;
    return exitCode == 0;
}
