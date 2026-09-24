#pragma once
#include "FileItem.g.h"

namespace winrt::DataExplorer::implementation
{
    struct FileItem : FileItemT<FileItem>
    {
        FileItem(hstring const& name, hstring const& kind, hstring const& size,
                 hstring const& date, hstring const& category)
            : m_name(name), m_kind(kind), m_size(size), m_date(date), m_category(category)
        {
        }

        hstring Name() const { return m_name; }
        void Name(hstring const& value) { m_name = value; }
        hstring Kind() const { return m_kind; }
        void Kind(hstring const& value) { m_kind = value; }
        hstring Size() const { return m_size; }
        void Size(hstring const& value) { m_size = value; }
        hstring Date() const { return m_date; }
        void Date(hstring const& value) { m_date = value; }
        hstring Category() const { return m_category; }
        void Category(hstring const& value) { m_category = value; }

    private:
        hstring m_name;
        hstring m_kind;
        hstring m_size;
        hstring m_date;
        hstring m_category;
    };
}

namespace winrt::DataExplorer::factory_implementation
{
    struct FileItem : FileItemT<FileItem, implementation::FileItem>
    {
    };
}
