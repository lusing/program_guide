#pragma once
#include "MainWindow.g.h"

namespace winrt::OsIntApp::implementation
{
    struct MainWindow : MainWindowT<MainWindow>
    {
        MainWindow();

        void OnShowPathClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnPickClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnRunToolClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);

    private:
        Microsoft::UI::Dispatching::DispatcherQueue m_dispatcherQueue{ nullptr };
        // jthread 析构时自动请求停止并 join，不会像 detach() 那样线程失控（docs/10 10.1）
        std::jthread m_worker;

        winrt::Windows::Foundation::IAsyncAction PickFileAsync();
        void ReportToolResult(bool ok, DWORD exitCode);
    };
}

namespace winrt::OsIntApp::factory_implementation
{
    struct MainWindow : MainWindowT<MainWindow, implementation::MainWindow>
    {
    };
}
