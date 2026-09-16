// Models/TaskItem.h -- see docs/08-binding-mvvm.md 8.2
#pragma once
#include "TaskItem.g.h"

namespace winrt::MvvmApp::implementation
{
    struct TaskItem : TaskItemT<TaskItem>
    {
        TaskItem(winrt::hstring const& title);

        // INotifyPropertyChanged: subscribe/unsubscribe forward to winrt::event
        winrt::event_token PropertyChanged(
            Microsoft::UI::Xaml::Data::PropertyChangedEventHandler const& handler);
        void PropertyChanged(winrt::event_token const& token);

        winrt::hstring Title();
        void Title(winrt::hstring const& value);
        bool Done();
        void Done(bool value);

    private:
        winrt::event<Microsoft::UI::Xaml::Data::PropertyChangedEventHandler>
            m_propertyChanged;
        winrt::hstring m_title;
        bool m_done = false;

        void RaisePropertyChanged(winrt::hstring const& propertyName);
    };
}

namespace winrt::MvvmApp::factory_implementation
{
    struct TaskItem : TaskItemT<TaskItem, implementation::TaskItem>
    {
    };
}
