#pragma once
#include "SliderPage.g.h"

namespace winrt::BasicGallery::implementation
{
    struct SliderPage : SliderPageT<SliderPage>
    {
        SliderPage();

        void OnVolumeChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::Primitives::RangeBaseValueChangedEventArgs const& args);
        void OnToggleBusyClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnRatingChanged(
            Windows::Foundation::IInspectable const& sender,
            Windows::Foundation::IInspectable const& args);
    };
}

namespace winrt::BasicGallery::factory_implementation
{
    struct SliderPage : SliderPageT<SliderPage, implementation::SliderPage>
    {
    };
}
