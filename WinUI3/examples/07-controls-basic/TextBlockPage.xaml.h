#pragma once
#include "TextBlockPage.g.h"

namespace winrt::BasicGallery::implementation
{
    struct TextBlockPage : TextBlockPageT<TextBlockPage>
    {
        TextBlockPage();

        void OnCycleTrimClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);

    private:
        int m_trimIndex{ 0 };
    };
}

namespace winrt::BasicGallery::factory_implementation
{
    struct TextBlockPage : TextBlockPageT<TextBlockPage, implementation::TextBlockPage>
    {
    };
}
