#include "pch.h"
#include "LibraryViewModel.h"
#include "MediaItem.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::MediaLibrary::implementation
{
    namespace
    {
        // 34 章结论复用：非打包进程没有 ApplicationData（没有包身份），
        // 数据库落在 %LOCALAPPDATA%\MediaLibrary。
        std::wstring DataDirectory()
        {
            wchar_t buffer[MAX_PATH]{};
            DWORD len = GetEnvironmentVariableW(L"LOCALAPPDATA", buffer, MAX_PATH);
            if (len == 0 || len >= MAX_PATH)
            {
                return L".";
            }
            return std::wstring{ buffer, len } + L"\\MediaLibrary";
        }
    }

    LibraryViewModel::LibraryViewModel()
    {
        m_items = single_threaded_observable_vector<winrt::MediaLibrary::MediaItem>();


        m_dispatcherQueue = Microsoft::UI::Dispatching::DispatcherQueue::GetForCurrentThread();
    }

    winrt::event_token LibraryViewModel::PropertyChanged(
        Data::PropertyChangedEventHandler const& handler)
    {
        return m_propertyChanged.add(handler);
    }

    void LibraryViewModel::PropertyChanged(winrt::event_token const& token)
    {
        m_propertyChanged.remove(token);
    }

    winrt::hstring LibraryViewModel::Status()
    {
        return m_status;
    }

    void LibraryViewModel::Status(winrt::hstring const& value)
    {
        if (m_status != value)
        {
            m_status = value;
            RaisePropertyChanged(L"Status");
        }
    }

    winrt::Windows::Foundation::Collections::IObservableVector<
        winrt::MediaLibrary::MediaItem> LibraryViewModel::Items()
    {
        return m_items;
    }


    winrt::hstring LibraryViewModel::SelectedCategory()
    {
        return m_selectedCategory;
    }

    void LibraryViewModel::SelectedCategory(winrt::hstring const& value)
    {
        if (m_selectedCategory != value)
        {
            m_selectedCategory = value;
            RaisePropertyChanged(L"SelectedCategory");
            // 书 3 章 SelectedMedium 的 setter 级联：过滤条件变了就重查数据库
            (void)ReloadAsync(std::wstring{ value }, L"");
        }
    }


    void LibraryViewModel::HasSelection(bool value)
    {
        if (m_hasSelection != value)
        {
            m_hasSelection = value;
            RaisePropertyChanged(L"HasSelection");
        }
    }

    void LibraryViewModel::RaisePropertyChanged(winrt::hstring const& propertyName)
    {
        m_propertyChanged(*this,
            Microsoft::UI::Xaml::Data::PropertyChangedEventArgs(propertyName));
    }

    void LibraryViewModel::SelectItem(winrt::MediaLibrary::MediaItem const& item)
    {
        m_selectedItem = item;
        HasSelection(item != nullptr);
    }

    void LibraryViewModel::ClearSelection()
    {
        m_selectedItem = nullptr;
        HasSelection(false);
    }

    winrt::Windows::Foundation::IAsyncAction LibraryViewModel::InitializeAsync()
    {
        auto lifetime = get_strong();

        try
        {
            // 打开数据库（建目录/建表/种子）放后台线程：文件 IO 不占 UI 线程
            co_await winrt::resume_background();

            std::wstring dir = DataDirectory();
            std::wstring status = m_store.Open(dir);
            std::wstring path = m_store.Path();

            // 回 UI 线程刷列表与状态行（32.7 纪律：TryEnqueue 而非 resume_foreground；
            // lambda 捕获 strong 与 ReloadAsync 同款——执行时对象必须还活着）
            m_dispatcherQueue.TryEnqueue([this, lifetime, status, path]
            {
                m_dbPath = path;
                (void)ReloadAsync(status, L"");
            });
        }
        catch (std::exception const& ex)
        {
            std::string what = ex.what();
            m_dispatcherQueue.TryEnqueue([this, lifetime, what]
            {
                Status(hstring{ std::wstring{ what.begin(), what.end() } + L" (db init failed)" });
            });
        }
    }

    winrt::Windows::Foundation::IAsyncAction LibraryViewModel::ReloadAsync(
        std::wstring statusPrefix, std::wstring statusSuffix)
    {
        auto lifetime = get_strong();
        std::wstring filter{ m_selectedCategory };

        // 读表在后台线程完成，回 UI 线程一次性重建集合（不逐条 Add，
        // 触发一次集合重置比 N 次增删通知便宜）
        co_await winrt::resume_background();
        std::vector<MediaStore::MediaRow> rows = m_store.List(filter);

        m_dispatcherQueue.TryEnqueue([this, lifetime, rows = std::move(rows),
            statusPrefix = std::move(statusPrefix), statusSuffix = std::move(statusSuffix)]() mutable
        {
            m_items.Clear();
            for (auto const& row : rows)
            {
                m_items.Append(make<MediaLibrary::implementation::MediaItem>(
                    row.id, row.name, row.category, row.location));
            }
            Status(winrt::hstring{ statusPrefix + L" | " +
                std::to_wstring(m_items.Size()) + L" items" + statusSuffix });
        });
    }

    void LibraryViewModel::AddItem()
    {
        m_addedCount++;
        // 轮转类别，演示一遍所有过滤分支
        static wchar_t const* cats[] = { L"Book", L"Music", L"Video" };
        std::wstring category = cats[(m_addedCount - 1) % 3];
        std::wstring name = L"New Item " + std::to_wstring(m_addedCount);

        (void)AddItemAsync(std::move(name), std::move(category));
    }

    void LibraryViewModel::DeleteSelected()
    {
        if (!m_selectedItem)
        {
            Status(L"nothing selected");
            return;
        }
        int64_t id = m_selectedItem.Id();

        // 协程体在首个 co_await 前同步执行，此刻已把 m_selectedItem 复制进
        // doomed；随后立刻清选中态，删除期间按钮回到禁用。
        (void)DeleteItemAsync(id);
        ClearSelection();
    }

    winrt::Windows::Foundation::IAsyncAction LibraryViewModel::AddItemAsync(
        std::wstring name, std::wstring category)
    {
        auto lifetime = get_strong();

        co_await winrt::resume_background();
        int64_t id = m_store.Insert(name, category);

        m_dispatcherQueue.TryEnqueue([this, lifetime, id, name, category]
        {
            // 当前过滤下能看到的行才追加（书的 ComboBox 过滤逻辑）
            if (m_selectedCategory == L"All" ||
                m_selectedCategory == category)
            {
                m_items.Append(make<MediaLibrary::implementation::MediaItem>(
                    id, name, category, L"Digital"));
            }
            Status(winrt::hstring{ L"inserted row " + std::to_wstring(id) + L" | " +
                std::to_wstring(m_items.Size()) + L" items (persisted)" });
        });
    }

    winrt::Windows::Foundation::IAsyncAction LibraryViewModel::DeleteItemAsync(int64_t id)
    {
        auto lifetime = get_strong();
        winrt::MediaLibrary::MediaItem doomed = m_selectedItem;

        co_await winrt::resume_background();
        m_store.Remove(id);

        m_dispatcherQueue.TryEnqueue([this, lifetime, id, doomed]
        {
            uint32_t index = 0;
            if (m_items.IndexOf(doomed, index))
            {
                m_items.RemoveAt(index);
            }
            ClearSelection();
            Status(winrt::hstring{ L"deleted row " + std::to_wstring(id) + L" | " +
                std::to_wstring(m_items.Size()) + L" items (persisted)" });
        });
    }
}
