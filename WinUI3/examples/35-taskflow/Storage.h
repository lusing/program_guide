// Services/Storage.h -- JSON persistence under %LOCALAPPDATA%\TaskFlow
// (34 章：非打包进程不能依赖 ApplicationData，退回 Win32 环境变量)
#pragma once
#include <string>
#include <vector>

namespace winrt::TaskFlow::implementation
{
    struct Storage
    {
        static std::wstring TasksFilePath();
        static std::vector<winrt::hstring> LoadTitles();
        static void SaveTitles(std::vector<winrt::hstring> const& titles);
    };
}
