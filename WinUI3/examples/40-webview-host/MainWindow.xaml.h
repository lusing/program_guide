#pragma once
#include "MainWindow.g.h"

namespace winrt::WebViewHost::implementation
{
    struct MainWindow : MainWindowT<MainWindow>
    {
        MainWindow();

        void OnGoClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnLocalClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnScriptClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnPostClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnAddressKeyDown(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Input::KeyRoutedEventArgs const& args);
        void OnCoreInitialized(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::CoreWebView2InitializedEventArgs const& args);
        void OnNavCompleted(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::Web::WebView2::Core::CoreWebView2NavigationCompletedEventArgs const& args);
        void OnWebMessage(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::Web::WebView2::Core::CoreWebView2WebMessageReceivedEventArgs const& args);

    private:
        winrt::Windows::Foundation::IAsyncAction RunTitleScriptAsync();
        winrt::hstring LocalPageHtml() const;
    };
}

namespace winrt::WebViewHost::factory_implementation
{
    struct MainWindow : MainWindowT<MainWindow, implementation::MainWindow>
    {
    };
}
