// ViewModels/TasksViewModel.h -- see docs/08-binding-mvvm.md 8.3 / 8.4
#pragma once
#include "TasksViewModel.g.h"

namespace winrt::MvvmApp::implementation
{
    struct TasksViewModel : TasksViewModelT<TasksViewModel>
    {
        TasksViewModel();

        // INotifyPropertyChanged
        winrt::event_token PropertyChanged(
            Microsoft::UI::Xaml::Data::PropertyChangedEventHandler const& handler);
        void PropertyChanged(winrt::event_token const& token);

        winrt::hstring Status();
        void Status(winrt::hstring const& value);
        winrt::hstring Query();
        void Query(winrt::hstring const& value);

        winrt::Windows::Foundation::Collections::IObservableVector<
            winrt::MvvmApp::TaskItem> Tasks();

        void AddFromInput();
        void DeleteSelected(winrt::MvvmApp::TaskItem const& item);
        void LoadFrom(
            winrt::Windows::Foundation::Collections::IVector<winrt::hstring> const& titles);

    private:
        winrt::event<Microsoft::UI::Xaml::Data::PropertyChangedEventHandler>
            m_propertyChanged;
        winrt::Windows::Foundation::Collections::IObservableVector<
            winrt::MvvmApp::TaskItem> m_tasks{ nullptr };
        winrt::hstring m_status;
        winrt::hstring m_query;

        void RaisePropertyChanged(winrt::hstring const& propertyName);
    };
}

namespace winrt::MvvmApp::factory_implementation
{
    struct TasksViewModel : TasksViewModelT<TasksViewModel, implementation::TasksViewModel>
    {
    };
}
