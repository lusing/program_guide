#pragma once
#include "VsmPage.g.h"

namespace winrt::CustomGallery::implementation
{
    struct VsmPage : VsmPageT<VsmPage>
    {
        VsmPage();

        void OnForceNarrow(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnForceWide(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::CustomGallery::factory_implementation
{
    struct VsmPage : VsmPageT<VsmPage, implementation::VsmPage>
    {
    };
}
