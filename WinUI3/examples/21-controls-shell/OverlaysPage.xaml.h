#pragma once
#include "OverlaysPage.g.h"

namespace winrt::ShellGallery::implementation
{
    struct OverlaysPage : OverlaysPageT<OverlaysPage>
    {
        OverlaysPage();

        void OnTipClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnTipAction(
            Windows::Foundation::IInspectable const& sender,
            Windows::Foundation::IInspectable const& args);
        void OnInfoBarClosed(
            Windows::Foundation::IInspectable const& sender,
            Windows::Foundation::IInspectable const& args);
        void OnCycleSeverityClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);

    private:
        int m_severity{ 1 };
    };
}

namespace winrt::ShellGallery::factory_implementation
{
    struct OverlaysPage : OverlaysPageT<OverlaysPage, implementation::OverlaysPage>
    {
    };
}
