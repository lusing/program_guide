#pragma once
#include "MainWindow.g.h"

namespace winrt::ControlsApp::implementation
{
    struct MainWindow : MainWindowT<MainWindow>
    {
        MainWindow();

        void OnThemeChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::SelectionChangedEventArgs const& args);
        void OnNotifyToggled(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnThemeRadioChecked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnAutoSaveToggled(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnVolumeChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::Primitives::RangeBaseValueChangedEventArgs const& args);
        void OnShowDialogClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);

    private:
        winrt::Windows::Foundation::IAsyncAction ShowDialogAsync();
    };
}

namespace winrt::ControlsApp::factory_implementation
{
    struct MainWindow : MainWindowT<MainWindow, implementation::MainWindow>
    {
    };
}
