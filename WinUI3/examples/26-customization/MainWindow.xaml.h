#pragma once
#include "MainWindow.g.h"

namespace winrt::CustomGallery::implementation
{
    struct MainWindow : MainWindowT<MainWindow>
    {
        MainWindow();

        void OnNavSelectionChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::NavigationViewSelectionChangedEventArgs const& args);

    private:
        void NavigateTo(winrt::hstring const& tag);
    };
}

namespace winrt::CustomGallery::factory_implementation
{
    struct MainWindow : MainWindowT<MainWindow, implementation::MainWindow>
    {
    };
}
