#include "pch.h"
#include "TaskViewModel.h"
#include "Task.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml::Media;

namespace winrt::TaskFlow::implementation
{
    TaskViewModel::TaskViewModel()
    {
        m_tasks = single_threaded_observable_vector<TaskFlow::Task>();
        Status(L"Ready");
    }

    hstring TaskViewModel::Status() { return m_status; }
    void TaskViewModel::Status(hstring const& value)
    {
        if (m_status != value) { m_status = value; RaisePropertyChanged(L"Status"); }
    }

    int32_t TaskViewModel::Count() { return static_cast<int32_t>(m_tasks.Size()); }

    Windows::Foundation::Collections::IObservableVector<TaskFlow::Task> TaskViewModel::Tasks()
    {
        return m_tasks;
    }

    void TaskViewModel::Add(hstring const& title, boolean important)
    {
        if (title.empty()) { return; }
        hstring finalTitle = important ? title + L" !" : title;
        m_tasks.Append(make<Task>(finalTitle));
        RaisePropertyChanged(L"Count");
        Status(L"Added: " + finalTitle);
        (void)SaveAsync();
    }

    void TaskViewModel::Toggle(TaskFlow::Task const& item)
    {
        item.Done(!item.Done());
        Status(item.Done() ? L"finished a task" : L"reopened a task");
        (void)SaveAsync();
    }

    void TaskViewModel::Remove(TaskFlow::Task const& item)
    {
        uint32_t index = 0;
        if (m_tasks.IndexOf(item, index))
        {
            m_tasks.RemoveAt(index);
            RaisePropertyChanged(L"Count");
            Status(L"removed a task");
            (void)SaveAsync();
        }
    }

    void TaskViewModel::Load()
    {
        // 启动路径的同步读盘（文件极小）；异步后台模式已在 32 章工程完整演示，
        // 这里刻意走简单路径，35 章只关注"持久化闭环"本身
        for (auto const& title : Storage::LoadTitles())
        {
            m_tasks.Append(make<Task>(title));
        }
        RaisePropertyChanged(L"Count");
        Status(L"Loaded " + to_hstring(m_tasks.Size()) + L" tasks");
    }

    Windows::Foundation::IAsyncAction TaskViewModel::SaveAsync()
    {
        auto strong = get_strong();
        // 在 UI 线程拷贝标题快照（IObservableVector 不能跨线程碰）
        std::vector<hstring> titles;
        titles.reserve(m_tasks.Size());
        for (auto const& t : m_tasks) { titles.push_back(t.Title()); }

        co_await winrt::resume_background();
        Storage::SaveTitles(titles);
        co_return;
    }

    winrt::event_token TaskViewModel::PropertyChanged(
        Microsoft::UI::Xaml::Data::PropertyChangedEventHandler const& handler)
    {
        return m_propertyChanged.add(handler);
    }
    void TaskViewModel::PropertyChanged(winrt::event_token const& token)
    {
        m_propertyChanged.remove(token);
    }

    void TaskViewModel::RaisePropertyChanged(hstring const& name)
    {
        m_propertyChanged(*this, Microsoft::UI::Xaml::Data::PropertyChangedEventArgs(name));
    }
}
