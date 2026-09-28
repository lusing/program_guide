// Model -- a single SQLite row surfaced to XAML (docs/37-sqlite-storage.md 37.2).
#pragma once
#include "MediaItem.g.h"

namespace winrt::MediaLibrary::implementation
{
    struct MediaItem : MediaItemT<MediaItem>
    {
        // wstring_view 参数一举两得：工厂转发 hstring 与调用方传 std::wstring
        // 都一步隐式转换到位（hstring 直收 std::wstring 会撞"两跳用户定义转换"）
        MediaItem(int64_t id, std::wstring_view name, std::wstring_view category,
                  std::wstring_view location)
            : m_id{ id }, m_name{ name }, m_category{ category }, m_location{ location }
        {
        }

        int64_t Id() const { return m_id; }
        hstring Name() const { return m_name; }
        hstring Category() const { return m_category; }
        hstring Location() const { return m_location; }

    private:
        int64_t m_id{};
        hstring m_name;
        hstring m_category;
        hstring m_location;
    };
}

namespace winrt::MediaLibrary::factory_implementation
{
    struct MediaItem : MediaItemT<MediaItem, implementation::MediaItem>
    {
    };
}
