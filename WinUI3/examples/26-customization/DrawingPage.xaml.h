#pragma once
#include "DrawingPage.g.h"

namespace winrt::CustomGallery::implementation
{
    struct DrawingPage : DrawingPageT<DrawingPage>
    {
        DrawingPage();

        void OnColorChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::ColorChangedEventArgs const& args);
    };
}

namespace winrt::CustomGallery::factory_implementation
{
    struct DrawingPage : DrawingPageT<DrawingPage, implementation::DrawingPage>
    {
    };
}
