#pragma once
#include "TextBoxPage.g.h"

namespace winrt::BasicGallery::implementation
{
    struct TextBoxPage : TextBoxPageT<TextBoxPage>
    {
        TextBoxPage();

        void OnNameChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::TextChangedEventArgs const& args);
        void OnPasswordChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnBoldClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnReadRichClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::BasicGallery::factory_implementation
{
    struct TextBoxPage : TextBoxPageT<TextBoxPage, implementation::TextBoxPage>
    {
    };
}
