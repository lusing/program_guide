// Entry point of a WinUI 3 C++/WinRT app: see docs/04-first-app.md 4.2.
// Deliberately does not include pch.h so the snippet in the tutorial compiles verbatim.

#include <windows.h>
#include "App.xaml.h"
#include <winrt/Microsoft.UI.Xaml.h>

int __stdcall wWinMain(HINSTANCE, HINSTANCE, PWSTR, int showCommand)
{
    winrt::init_apartment();   // 初始化 COM apartment（UI 线程是 STA）

    winrt::Microsoft::UI::Xaml::Application::Start(
        [](auto&&)
        {
            // 工厂回调：框架需要 App 对象时调用
            winrt::make<winrt::MyApp::implementation::App>();
        });

    return 0;
}
