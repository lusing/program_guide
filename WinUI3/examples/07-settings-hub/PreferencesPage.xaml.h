#pragma once
#include "PreferencesPage.g.h"

namespace winrt::SettingsHub::implementation
{
    struct PreferencesPage : PreferencesPageT<PreferencesPage>
    {
        PreferencesPage();

        void OnCountChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::NumberBoxValueChangedEventArgs const& args);
        void OnWeekStartChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::DatePickerValueChangedEventArgs const& args);
        void OnSaveClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnSaveAccelerator(
            Microsoft::UI::Xaml::Input::KeyboardAccelerator const& sender,
            Microsoft::UI::Xaml::Input::KeyboardAcceleratorInvokedEventArgs const& args);

        // 进入页面即聚焦保存按钮（与 AppearancePage 同一模式：键盘可达 + 冒烟可测）。
        // 必须是 public：生成基类通过接口调用虚函数
        void OnNavigatedTo(Microsoft::UI::Xaml::Navigation::NavigationEventArgs const& e);

    private:
        Windows::Foundation::IAsyncAction AnimateSaveAsync();
    };
}

namespace winrt::SettingsHub::factory_implementation
{
    struct PreferencesPage : PreferencesPageT<PreferencesPage, implementation::PreferencesPage>
    {
    };
}
