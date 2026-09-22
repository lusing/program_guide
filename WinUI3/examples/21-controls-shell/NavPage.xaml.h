#pragma once
#include "NavPage.g.h"

namespace winrt::ShellGallery::implementation
{
    struct NavPage : NavPageT<NavPage>
    {
        NavPage();

        void OnLeftClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnCompactClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnTopClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnEmbeddedSelectionChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::NavigationViewSelectionChangedEventArgs const& args);
        void OnToggleSplitClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::ShellGallery::factory_implementation
{
    struct NavPage : NavPageT<NavPage, implementation::NavPage>
    {
    };
}
