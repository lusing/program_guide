// Service layer for child-process work: see docs/10-os-integration.md 10.4.
// Plain C++/Win32, no WinRT, no UI -- the page only reports the result.
#pragma once

#include <string>

// exitCode 只在返回 true 时才有意义。阻塞等待：调用方必须在后台线程（docs/10 10.1）。
bool RunTool(std::wstring cmdLine, DWORD& exitCode);
