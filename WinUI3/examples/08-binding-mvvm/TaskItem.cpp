// Models/TaskItem.cpp -- see docs/08-binding-mvvm.md 8.2
#include "pch.h"
#include "TaskItem.h"

namespace winrt::MvvmApp::implementation
{
    TaskItem::TaskItem(winrt::hstring const& title) : m_title(title) {}

    winrt::event_token TaskItem::PropertyChanged(
        Microsoft::UI::Xaml::Data::PropertyChangedEventHandler const& handler)
    {
        return m_propertyChanged.add(handler);
    }

    void TaskItem::PropertyChanged(winrt::event_token const& token)
    {
        m_propertyChanged.remove(token);
    }

    winrt::hstring TaskItem::Title() { return m_title; }

    void TaskItem::Title(winrt::hstring const& value)
    {
        if (m_title != value)
        {
            m_title = value;
            RaisePropertyChanged(L"Title");
        }
    }

    bool TaskItem::Done() { return m_done; }

    void TaskItem::Done(bool value)
    {
        if (m_done != value)
        {
            m_done = value;
            RaisePropertyChanged(L"Done");
        }
    }

    void TaskItem::RaisePropertyChanged(winrt::hstring const& propertyName)
    {
        m_propertyChanged(*this,
            Microsoft::UI::Xaml::Data::PropertyChangedEventArgs(propertyName));
    }
}
