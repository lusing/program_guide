#pragma once
#include "NotificationsPage.g.h"

namespace winrt::SettingsHub::implementation
{
    struct NotificationsPage : NotificationsPageT<NotificationsPage>
    {
        NotificationsPage();

        void OnMasterToggled(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnChannelChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnTipClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnTipClosed(
            Windows::Foundation::IInspectable const& sender,
            Windows::Foundation::IInspectable const& args);
        void OnSaveClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::SettingsHub::factory_implementation
{
    struct NotificationsPage : NotificationsPageT<NotificationsPage, implementation::NotificationsPage>
    {
    };
}
