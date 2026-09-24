#include <windows.h>
#include "App.xaml.h"
#include <winrt/Microsoft.UI.Xaml.h>

int __stdcall wWinMain(HINSTANCE, HINSTANCE, PWSTR, int showCommand)
{
    winrt::init_apartment();
    winrt::Microsoft::UI::Xaml::Application::Start(
        [](auto&&) { winrt::make<winrt::SettingsHub::implementation::App>(); });
    return 0;
}
