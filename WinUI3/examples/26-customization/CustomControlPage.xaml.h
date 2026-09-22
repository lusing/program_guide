#pragma once
#include "CustomControlPage.g.h"

namespace winrt::CustomGallery::implementation
{
    struct CustomControlPage : CustomControlPageT<CustomControlPage>
    {
        CustomControlPage();

        void OnBumpClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnReadRowClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);

    private:
        int m_value{ 0 };
    };
}

namespace winrt::CustomGallery::factory_implementation
{
    struct CustomControlPage : CustomControlPageT<CustomControlPage, implementation::CustomControlPage>
    {
    };
}
