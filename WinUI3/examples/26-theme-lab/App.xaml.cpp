#include "pch.h"
#include "App.xaml.h"
#include "MainWindow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::ThemeLab::implementation
{
    App::App()
    {
        InitializeComponent();
        // TEMP: stowed-exception diagnostics (the classic bisect tool)
        UnhandledException([this](IInspectable const&, Microsoft::UI::Xaml::UnhandledExceptionEventArgs const& e)
        {
            wchar_t buffer[512]{};
            swprintf(buffer, 512, L"%s", e.Message().c_str());
            HANDLE file = ::CreateFileW(L"C:\\Users\\lusin\\AppData\\Local\\themelab-crash.txt",
                GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
            if (file != INVALID_HANDLE_VALUE)
            {
                DWORD written = 0;
                ::WriteFile(file, buffer, static_cast<DWORD>(wcslen(buffer) * 2), &written, nullptr);
                ::CloseHandle(file);
            }
        });
    }

    void App::OnLaunched(LaunchActivatedEventArgs const&)
    {
        m_window = make<MainWindow>();
        m_window.Activate();
    }
}
