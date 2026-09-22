// Models/Task.h -- INPC model, see docs/32-binding-mvvm.md 32.2
#pragma once
#include "Task.g.h"

namespace winrt::TaskFlow::implementation
{
    struct Task : TaskT<Task>
    {
        Task() = default;
        Task(hstring const& title);

        hstring Title();
        void Title(hstring const& value);
        bool Done();
        void Done(bool value);

        winrt::event_token PropertyChanged(
            Microsoft::UI::Xaml::Data::PropertyChangedEventHandler const& handler);
        void PropertyChanged(winrt::event_token const& token);

    private:
        hstring m_title;
        bool m_done{ false };
        winrt::event<Microsoft::UI::Xaml::Data::PropertyChangedEventHandler> m_propertyChanged;

        void RaisePropertyChanged(hstring const& name);
    };
}

namespace winrt::TaskFlow::factory_implementation
{
    struct Task : TaskT<Task, implementation::Task>
    {
    };
}
