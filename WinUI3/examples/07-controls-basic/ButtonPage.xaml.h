#pragma once
#include "ButtonPage.g.h"

namespace winrt::BasicGallery::implementation
{
    struct ButtonPage : ButtonPageT<ButtonPage>
    {
        ButtonPage();

        void OnMainClick(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnRepeatClick(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnExportKind(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);

    private:
        int m_mainCount{ 0 };
        int m_repeatCount{ 0 };
    };
}

namespace winrt::BasicGallery::factory_implementation
{
    struct ButtonPage : ButtonPageT<ButtonPage, implementation::ButtonPage>
    {
    };
}
