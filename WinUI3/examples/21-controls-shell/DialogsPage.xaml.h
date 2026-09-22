#pragma once
#include "DialogsPage.g.h"

namespace winrt::ShellGallery::implementation
{
    struct DialogsPage : DialogsPageT<DialogsPage>
    {
        DialogsPage();

        void OnShowDialogClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnRetryClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnSkipClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);

    private:
        winrt::Windows::Foundation::IAsyncAction ShowDialogAsync();
    };
}

namespace winrt::ShellGallery::factory_implementation
{
    struct DialogsPage : DialogsPageT<DialogsPage, implementation::DialogsPage>
    {
    };
}
