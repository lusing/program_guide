#pragma once
#include "TablePage.g.h"

namespace winrt::CollectionsGallery::implementation
{
    struct TablePage : TablePageT<TablePage>
    {
        TablePage();

        void OnRowSelected(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::SelectionChangedEventArgs const& args);
    };
}

namespace winrt::CollectionsGallery::factory_implementation
{
    struct TablePage : TablePageT<TablePage, implementation::TablePage>
    {
    };
}
