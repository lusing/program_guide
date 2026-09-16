#pragma once
#include "MainWindow.g.h"

namespace winrt::MyApp::implementation
{
    struct MainWindow : MainWindowT<MainWindow>
    {
        MainWindow();

        void OnClick(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::MyApp::factory_implementation
{
    struct MainWindow : MainWindowT<MainWindow, implementation::MainWindow>
    {
    };
}
