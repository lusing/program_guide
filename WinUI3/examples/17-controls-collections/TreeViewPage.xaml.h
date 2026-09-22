#pragma once
#include "TreeViewPage.g.h"

namespace winrt::CollectionsGallery::implementation
{
    struct TreeViewPage : TreeViewPageT<TreeViewPage>
    {
        TreeViewPage();

        void OnNodeInvoked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::TreeViewItemInvokedEventArgs const& args);
        void OnExpandAllClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);

    private:
        void ExpandRecursively(winrt::Microsoft::UI::Xaml::Controls::TreeViewNode const& node, int& count);
    };
}

namespace winrt::CollectionsGallery::factory_implementation
{
    struct TreeViewPage : TreeViewPageT<TreeViewPage, implementation::TreeViewPage>
    {
    };
}
