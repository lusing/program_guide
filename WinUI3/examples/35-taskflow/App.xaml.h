#pragma once
#include "App.g.h"

namespace winrt::TaskFlow::implementation
{
    struct App : AppT<App>
    {
        App();

        void OnLaunched(Microsoft::UI::Xaml::LaunchActivatedEventArgs const&);

        // 35 章：SettingsPage 经此开关主窗口背景材质（窗口归 App 持有，04 章模式）
        void SetMica(bool on);

    private:
        Microsoft::UI::Xaml::Window window{ nullptr };
    };
}
