#pragma once
#include "MainWindow.g.h"

namespace winrt::TaskFlow::implementation
{
    struct MainWindow : MainWindowT<MainWindow>
    {
        MainWindow();

        void SetBackdrop(bool mica);

        void OnNavSelectionChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::NavigationViewSelectionChangedEventArgs const& args);

    private:
        void NavigateTo(winrt::hstring const& tag);
    };
}

namespace winrt::TaskFlow::factory_implementation
{
    struct MainWindow : MainWindowT<MainWindow, implementation::MainWindow>
    {
    };
}
