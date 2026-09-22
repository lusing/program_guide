// ViewModels/TasksViewModel.cpp -- see docs/08-binding-mvvm.md 8.3 / 8.4
#include "pch.h"
#include "TasksViewModel.h"
#include "TaskItem.h"

namespace winrt::MvvmApp::implementation
{
    TasksViewModel::TasksViewModel()
    {
        // 单线程可观察向量：Append/Remove 等操作自动触发 VectorChanged
        m_tasks = winrt::single_threaded_observable_vector<winrt::MvvmApp::TaskItem>();
    }

    winrt::event_token TasksViewModel::PropertyChanged(
        Microsoft::UI::Xaml::Data::PropertyChangedEventHandler const& handler)
    {
        return m_propertyChanged.add(handler);
    }

    void TasksViewModel::PropertyChanged(winrt::event_token const& token)
    {
        m_propertyChanged.remove(token);
    }

    winrt::hstring TasksViewModel::Status() { return m_status; }

    void TasksViewModel::Status(winrt::hstring const& value)
    {
        if (m_status != value)
        {
            m_status = value;
            RaisePropertyChanged(L"Status");
        }
    }

    winrt::hstring TasksViewModel::Query() { return m_query; }

    void TasksViewModel::Query(winrt::hstring const& value)
    {
        if (m_query != value)
        {
            m_query = value;
            RaisePropertyChanged(L"Query");
        }
    }

    winrt::Windows::Foundation::Collections::IObservableVector<winrt::MvvmApp::TaskItem>
    TasksViewModel::Tasks()
    {
        return m_tasks;
    }

    void TasksViewModel::AddFromInput()
    {
        if (m_query.empty()) { return; }
        m_tasks.Append(winrt::make<TaskItem>(m_query));
        SyncTaskCount();
        Status(L"Added: " + m_query);
        m_query.clear();
        // The TextBox is TwoWay-bound to Query; clearing the field without notifying
        // would leave the stale text on screen.
        RaisePropertyChanged(L"Query");
    }

    void TasksViewModel::DeleteSelected(winrt::MvvmApp::TaskItem const& item)
    {
        uint32_t index = 0;
        if (m_tasks.IndexOf(item, index))
        {
            m_tasks.RemoveAt(index);
            SyncTaskCount();
            Status(L"Deleted");
        }
    }

    void TasksViewModel::LoadFrom(
        winrt::Windows::Foundation::Collections::IVector<winrt::hstring> const& titles)
    {
        // 整体替换集合对象：必须再发一次属性通知，否则界面还盯着旧集合
        m_tasks = winrt::single_threaded_observable_vector<winrt::MvvmApp::TaskItem>();
        for (auto const& title : titles)
        {
            m_tasks.Append(winrt::make<TaskItem>(title));
        }
        RaisePropertyChanged(L"Tasks");
        SyncTaskCount();
        Status(L"Loaded " + winrt::to_hstring(titles.Size()) + L" tasks");
    }

    void TasksViewModel::RaisePropertyChanged(winrt::hstring const& propertyName)
    {
        m_propertyChanged(*this,
            Microsoft::UI::Xaml::Data::PropertyChangedEventArgs(propertyName));
    }

    int32_t TasksViewModel::TaskCount()
    {
        return static_cast<int32_t>(m_tasks.Size());
    }

    void TasksViewModel::SyncTaskCount()
    {
        // 集合内容变化不会自动通知"派生计数"，显式再发一次属性通知
        RaisePropertyChanged(L"TaskCount");
    }
}
