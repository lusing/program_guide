#include "pch.h"
#include "FilesStore.h"

using namespace winrt;

namespace winrt::DataExplorer::implementation
{
    Windows::Foundation::Collections::IVector<winrt::DataExplorer::FileItem> FilesStore::All()
    {
        auto items = single_threaded_observable_vector<winrt::DataExplorer::FileItem>();
        auto add = [&](auto&& name, auto&& kind, auto&& size, auto&& date, auto&& category)
        {
            items.Append(winrt::make<winrt::DataExplorer::implementation::FileItem>(
                name, kind, size, date, category));
        };
        add(L"report-q3.docx", L"Document", L"248 KB", L"2026-08-14", L"Documents");
        add(L"notes.txt",     L"Document", L"3 KB",   L"2026-09-02", L"Documents");
        add(L"contract.pdf",  L"Document", L"1.2 MB", L"2026-06-30", L"Documents");
        add(L"holiday.jpg",   L"Image",    L"3.4 MB", L"2026-07-21", L"Images");
        add(L"icon.png",      L"Image",    L"18 KB",  L"2026-09-18", L"Images");
        add(L"banner.webp",   L"Image",    L"640 KB", L"2026-05-11", L"Images");
        add(L"theme.wav",     L"Audio",    L"8.1 MB", L"2026-04-27", L"Audio");
        add(L"podcast.mp3",   L"Audio",    L"26 MB",  L"2026-08-03", L"Audio");
        add(L"backup.zip",    L"Archive",  L"410 MB", L"2026-03-19", L"Archives");
        add(L"source.tar",    L"Archive",  L"88 MB",  L"2026-09-11", L"Archives");
        return items;
    }
}
