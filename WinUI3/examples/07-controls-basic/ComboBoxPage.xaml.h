#pragma once
#include "ComboBoxPage.g.h"

namespace winrt::BasicGallery::implementation
{
    struct ComboBoxPage : ComboBoxPageT<ComboBoxPage>
    {
        ComboBoxPage();

        void OnThemeChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::SelectionChangedEventArgs const& args);
        void OnSelectDarkClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::BasicGallery::factory_implementation
{
    struct ComboBoxPage : ComboBoxPageT<ComboBoxPage, implementation::ComboBoxPage>
    {
    };
}
