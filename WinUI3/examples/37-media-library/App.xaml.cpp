#include "pch.h"
#include "App.xaml.h"
#include "MainWindow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::MediaLibrary::implementation
{
    App::App()
    {
        InitializeComponent();   // 处理 App.xaml 里的资源字典

        // 41 章手段实装：stowed exception 先经这里再进 WER——把内容落盘，
        // 无调试器的命令行流程也能拿到第一现场（诊断完成后可移除）。
        UnhandledException([](auto const&, Microsoft::UI::Xaml::UnhandledExceptionEventArgs const& e)
        {
            wchar_t line[1024];
            _snwprintf_s(line, _TRUNCATE, L"stowed 0x%08lX: %s\r\n",
                static_cast<unsigned long>(e.Exception().value), e.Message().c_str());
            wchar_t path[MAX_PATH]{};
            if (GetEnvironmentVariableW(L"TEMP", path, MAX_PATH))
            {
                HANDLE h = CreateFileW((std::wstring{ path } + L"\\MediaLibrary-crash.log").c_str(),
                    FILE_APPEND_DATA, FILE_SHARE_READ, nullptr, OPEN_ALWAYS,
                    FILE_ATTRIBUTE_NORMAL, nullptr);
                if (h != INVALID_HANDLE_VALUE)
                {
                    DWORD written{};
                    WriteFile(h, line, static_cast<DWORD>(wcslen(line) * sizeof(wchar_t)), &written, nullptr);
                    CloseHandle(h);
                }
            }
        });
    }

    void App::OnLaunched(LaunchActivatedEventArgs const&)
    {
        window = make<MainWindow>();
        window.Activate();       // 显示窗口，开始接收消息
    }
}
