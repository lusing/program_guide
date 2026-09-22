// ViewModels/TaskViewModel.h -- see docs/32-binding-mvvm.md 32.3 / 32.4 / 32.7
#pragma once
#include "TaskViewModel.g.h"
#include "Storage.h"

namespace winrt::TaskFlow::implementation
{
    struct TaskViewModel : TaskViewModelT<TaskViewModel>
    {
        TaskViewModel();

        hstring Status();
        void Status(hstring const& value);
        int32_t Count();

        Windows::Foundation::Collections::IObservableVector<TaskFlow::Task> Tasks();

        void Add(hstring const& title, boolean important);
        void Toggle(TaskFlow::Task const& item);
        void Remove(TaskFlow::Task const& item);
        void Load();
        Windows::Foundation::IAsyncAction SaveAsync();

        winrt::event_token PropertyChanged(
            Microsoft::UI::Xaml::Data::PropertyChangedEventHandler const& handler);
        void PropertyChanged(winrt::event_token const& token);

    private:
        winrt::event<Microsoft::UI::Xaml::Data::PropertyChangedEventHandler> m_propertyChanged;
        Windows::Foundation::Collections::IObservableVector<TaskFlow::Task> m_tasks{ nullptr };
        hstring m_status;

        void RaisePropertyChanged(hstring const& name);
    };
}

namespace winrt::TaskFlow::factory_implementation
{
    struct TaskViewModel : TaskViewModelT<TaskViewModel, implementation::TaskViewModel>
    {
    };
}
