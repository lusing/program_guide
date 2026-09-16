#pragma once
#include "MainWindow.g.h"
#include "TasksViewModel.h"

namespace winrt::MvvmApp::implementation
{
    struct MainWindow : MainWindowT<MainWindow>
    {
        MainWindow();

        winrt::MvvmApp::TasksViewModel ViewModel() { return m_viewModel; }

        void OnDeleteClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnRefreshClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);

    private:
        winrt::MvvmApp::TasksViewModel m_viewModel{ nullptr };
        // The queue the WinUI 3 UI thread actually pumps. winrt::resume_foreground has no
        // awaiter for this type (only Windows.System.DispatcherQueue / CoreDispatcher, and
        // the Windows.System one is not pumped on a WinUI 3 desktop UI thread), so the
        // switch-back below goes through TryEnqueue.
        Microsoft::UI::Dispatching::DispatcherQueue m_dispatcherQueue{ nullptr };

        winrt::Windows::Foundation::IAsyncAction ConfirmDeleteAsync(
            winrt::MvvmApp::TaskItem const& item);
        winrt::Windows::Foundation::IAsyncAction RefreshAsync();
    };
}

namespace winrt::MvvmApp::factory_implementation
{
    struct MainWindow : MainWindowT<MainWindow, implementation::MainWindow>
    {
    };
}
