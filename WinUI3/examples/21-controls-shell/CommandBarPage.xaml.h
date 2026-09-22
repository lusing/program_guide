#pragma once
#include "CommandBarPage.g.h"

namespace winrt::ShellGallery::implementation
{
    struct CommandBarPage : CommandBarPageT<CommandBarPage>
    {
        CommandBarPage();

        void OnAddClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnSaveClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnPinClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnSettingsClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnMenuNew(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnMenuExit(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnMenuGrid(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnCtxZoneRightTapped(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Input::RightTappedRoutedEventArgs const& args);
        void OnMenuRefresh(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnMenuDelete(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::ShellGallery::factory_implementation
{
    struct CommandBarPage : CommandBarPageT<CommandBarPage, implementation::CommandBarPage>
    {
    };
}
