#pragma once
#include "NumberBoxPage.g.h"

namespace winrt::BasicGallery::implementation
{
    struct NumberBoxPage : NumberBoxPageT<NumberBoxPage>
    {
        NumberBoxPage();

        void OnQuantityChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::NumberBoxValueChangedEventArgs const& args);
        void OnDoubleClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnClearClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::BasicGallery::factory_implementation
{
    struct NumberBoxPage : NumberBoxPageT<NumberBoxPage, implementation::NumberBoxPage>
    {
    };
}
