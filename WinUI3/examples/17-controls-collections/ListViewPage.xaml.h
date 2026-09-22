#pragma once
#include "ListViewPage.g.h"

namespace winrt::CollectionsGallery::implementation
{
    struct ListViewPage : ListViewPageT<ListViewPage>
    {
        ListViewPage();

        void OnFruitSelectionChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::SelectionChangedEventArgs const& args);
        void OnAddClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnRemoveClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);

    private:
        Microsoft::UI::Xaml::Controls::ItemCollection m_items{ nullptr };
    };
}

namespace winrt::CollectionsGallery::factory_implementation
{
    struct ListViewPage : ListViewPageT<ListViewPage, implementation::ListViewPage>
    {
    };
}
