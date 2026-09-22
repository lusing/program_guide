#pragma once
#include "TaskListPage.g.h"

namespace winrt::TaskFlow::implementation
{
    struct TaskListPage : TaskListPageT<TaskListPage>
    {
        TaskListPage();

        TaskFlow::TaskViewModel ViewModel();

        void OnAddClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnRowToggled(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnRemoveClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);

    private:
        TaskFlow::TaskViewModel m_viewModel{ nullptr };
        Windows::Foundation::IAsyncAction ShowAddDialogAsync();
    };
}

namespace winrt::TaskFlow::factory_implementation
{
    struct TaskListPage : TaskListPageT<TaskListPage, implementation::TaskListPage>
    {
    };
}
