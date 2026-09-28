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

        // 36 章：命令回调（XamlUICommand / StandardUICommand 的两个事件）
        void OnCompleteAllExecute(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Input::ExecuteRequestedEventArgs const& args);
        void OnCanCompleteAll(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Input::CanExecuteRequestedEventArgs const& args);
        void OnDeleteExecute(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Input::ExecuteRequestedEventArgs const& args);

    private:
        winrt::MvvmApp::TasksViewModel m_viewModel{ nullptr };
        // The queue the WinUI 3 UI thread actually pumps. winrt::resume_foreground has no
        // awaiter for this type (only Windows.System.DispatcherQueue / CoreDispatcher, and
        // the Windows.System one is not pumped on a WinUI 3 desktop UI thread), so the
        // switch-back below goes through TryEnqueue.
        Microsoft::UI::Dispatching::DispatcherQueue m_dispatcherQueue{ nullptr };

        // 36 章命令对象：挂在按钮的 Command 属性上
        Microsoft::UI::Xaml::Input::XamlUICommand m_completeAllCommand{ nullptr };
        Microsoft::UI::Xaml::Input::StandardUICommand m_deleteCommand{ nullptr };
        winrt::event_token m_vmPropertyChangedToken{};

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
