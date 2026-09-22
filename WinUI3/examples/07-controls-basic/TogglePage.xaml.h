#pragma once
#include "TogglePage.g.h"

namespace winrt::BasicGallery::implementation
{
    struct TogglePage : TogglePageT<TogglePage>
    {
        TogglePage();

        void OnAutoSaveToggled(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnModeToggled(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::BasicGallery::factory_implementation
{
    struct TogglePage : TogglePageT<TogglePage, implementation::TogglePage>
    {
    };
}
