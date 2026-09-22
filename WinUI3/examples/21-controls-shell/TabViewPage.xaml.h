#pragma once
#include "TabViewPage.g.h"

namespace winrt::ShellGallery::implementation
{
    struct TabViewPage : TabViewPageT<TabViewPage>
    {
        TabViewPage();

        void OnTabSelectionChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::SelectionChangedEventArgs const& args);
        void OnTabCloseRequested(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::TabViewTabCloseRequestedEventArgs const& args);
        void OnAddTabClicked(
            Windows::Foundation::IInspectable const& sender,
            Windows::Foundation::IInspectable const& args);
        void OnExpanderExpanding(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::ExpanderExpandingEventArgs const& args);
        void OnExpanderCollapsed(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::ExpanderCollapsedEventArgs const& args);
    };
}

namespace winrt::ShellGallery::factory_implementation
{
    struct TabViewPage : TabViewPageT<TabViewPage, implementation::TabViewPage>
    {
    };
}
