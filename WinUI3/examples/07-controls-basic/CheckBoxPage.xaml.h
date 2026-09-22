#pragma once
#include "CheckBoxPage.g.h"

namespace winrt::BasicGallery::implementation
{
    struct CheckBoxPage : CheckBoxPageT<CheckBoxPage>
    {
        CheckBoxPage();

        void OnNotifyChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnThemeChecked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::BasicGallery::factory_implementation
{
    struct CheckBoxPage : CheckBoxPageT<CheckBoxPage, implementation::CheckBoxPage>
    {
    };
}
