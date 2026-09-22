#pragma once
#include "StylesPage.g.h"

namespace winrt::CustomGallery::implementation
{
    struct StylesPage : StylesPageT<StylesPage>
    {
        StylesPage();

        void OnStyledClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnTemplatedClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::CustomGallery::factory_implementation
{
    struct StylesPage : StylesPageT<StylesPage, implementation::StylesPage>
    {
    };
}
