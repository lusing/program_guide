#include "pch.h"
#include "SettingsPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::TaskFlow::implementation
{
    SettingsPage::SettingsPage()
    {
        InitializeComponent();
    }

    void SettingsPage::OnBackdropToggled(IInspectable const&, RoutedEventArgs const&)
    {
        // 经投影的 App 接口把选择落到主窗口（SetMica 在 App.idl 里声明过）
        auto app = Microsoft::UI::Xaml::Application::Current().as<TaskFlow::App>();
        app.SetMica(true);
    }
}
