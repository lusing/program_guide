#pragma once
#include "AppearancePage.g.h"

namespace winrt::SettingsHub::implementation
{
    struct AppearancePage : AppearancePageT<AppearancePage>
    {
        AppearancePage();

        void OnThemeChecked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnDensityChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::SelectionChangedEventArgs const& args);
        void OnOpacityChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::Primitives::RangeBaseValueChangedEventArgs const& args);
        void OnSaveClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnResetClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);

        // 进入页面即聚焦首个控件：键盘用户少按一次 TAB，也让冒烟脚本的
        // 方向键/空格有确定性的落点（无障碍与可测性一举两得）。
        // 必须是 public：生成基类通过接口调用虚函数
        void OnNavigatedTo(Microsoft::UI::Xaml::Navigation::NavigationEventArgs const& e);
    };
}

namespace winrt::SettingsHub::factory_implementation
{
    struct AppearancePage : AppearancePageT<AppearancePage, implementation::AppearancePage>
    {
    };
}
