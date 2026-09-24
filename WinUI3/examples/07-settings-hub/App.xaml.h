#pragma once
#include "App.g.h"

namespace winrt::SettingsHub::implementation
{
    struct App : AppT<App>
    {
        App();

        void OnLaunched(Microsoft::UI::Xaml::LaunchActivatedEventArgs const&);
        void ApplyTheme(hstring const& theme);
        void ShowSavedBar();

    private:
        Microsoft::UI::Xaml::Window m_window{ nullptr };
    };
}
