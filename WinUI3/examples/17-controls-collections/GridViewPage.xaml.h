#pragma once
#include "GridViewPage.g.h"

namespace winrt::CollectionsGallery::implementation
{
    struct GridViewPage : GridViewPageT<GridViewPage>
    {
        GridViewPage();

        void OnCardSelectionChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::SelectionChangedEventArgs const& args);
        void OnFlipChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::SelectionChangedEventArgs const& args);
        void OnNextClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::CollectionsGallery::factory_implementation
{
    struct GridViewPage : GridViewPageT<GridViewPage, implementation::GridViewPage>
    {
    };
}
