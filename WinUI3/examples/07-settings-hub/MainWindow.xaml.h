#pragma once
#include "MainWindow.g.h"

namespace winrt::SettingsHub::implementation
{
    struct MainWindow : MainWindowT<MainWindow>
    {
        MainWindow();

        void ShowSaved();

        void OnNavSelectionChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::NavigationViewSelectionChangedEventArgs const& args);
        void OnSearchChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::AutoSuggestBoxTextChangedEventArgs const& args);
        void OnSearchChosen(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::AutoSuggestBoxSuggestionChosenEventArgs const& args);
        void OnRootPointer(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Input::PointerRoutedEventArgs const& e);
        void OnRootFocus(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& e);

    private:
        void NavigateTo(winrt::hstring const& tag);
        Windows::Foundation::Collections::IVector<Windows::Foundation::IInspectable> m_searchItems{ nullptr };
    };
}

namespace winrt::SettingsHub::factory_implementation
{
    struct MainWindow : MainWindowT<MainWindow, implementation::MainWindow>
    {
    };
}
