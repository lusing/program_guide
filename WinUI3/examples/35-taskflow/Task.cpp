#include "pch.h"
#include "Task.h"

namespace winrt::TaskFlow::implementation
{
    Task::Task(hstring const& title) : m_title(title) {}

    hstring Task::Title() { return m_title; }
    void Task::Title(hstring const& value)
    {
        if (m_title != value) { m_title = value; RaisePropertyChanged(L"Title"); }
    }

    bool Task::Done() { return m_done; }
    void Task::Done(bool value)
    {
        if (m_done != value) { m_done = value; RaisePropertyChanged(L"Done"); }
    }

    winrt::event_token Task::PropertyChanged(
        Microsoft::UI::Xaml::Data::PropertyChangedEventHandler const& handler)
    {
        return m_propertyChanged.add(handler);
    }
    void Task::PropertyChanged(winrt::event_token const& token)
    {
        m_propertyChanged.remove(token);
    }

    void Task::RaisePropertyChanged(hstring const& name)
    {
        m_propertyChanged(*this, Microsoft::UI::Xaml::Data::PropertyChangedEventArgs(name));
    }
}
