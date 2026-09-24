#include "pch.h"
#include "App.xaml.h"
#include "MainWindow.xaml.h"

#include <string>

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::SettingsHub::implementation
{
    App::App()
    {
        InitializeComponent();
    }

    void App::OnLaunched(LaunchActivatedEventArgs const&)
    {
        m_window = make<MainWindow>();
        m_window.Activate();
    }

    void App::ApplyTheme(hstring const& theme)
    {
        // RequestedTheme on the content root re-skins the whole tree (10 章 RadioButton 的真 payoff)
        if (auto root = m_window.Content().try_as<FrameworkElement>())
        {
            ElementTheme value = theme == L"dark"  ? ElementTheme::Dark
                               : theme == L"light" ? ElementTheme::Light
                                                    : ElementTheme::Default;
            // WindowsAppSDK 实测坑：同一值连续赋值不会触发 ThemeResource 重估，
            // 先归 Default 再设目标值，两轮变更通知才能让整树换肤
            root.RequestedTheme(ElementTheme::Default);
            root.RequestedTheme(value);
        }
    }

    void App::ShowSavedBar()
    {
        if (auto main = m_window.as<SettingsHub::MainWindow>())
        {
            main.ShowSaved();
        }
    }
}
