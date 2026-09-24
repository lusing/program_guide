#include "pch.h"
#include "SettingsStore.h"

using namespace winrt;

namespace winrt::SettingsHub::implementation
{
    Windows::Data::Json::JsonObject SettingsStore::m_cache{ nullptr };
    bool SettingsStore::m_dirty{ false };

    std::wstring SettingsStore::Path()
    {
        wchar_t buffer[MAX_PATH]{};
        ::GetEnvironmentVariableW(L"LOCALAPPDATA", buffer, MAX_PATH);
        std::wstring dir = std::wstring(buffer) + L"\\SettingsHub";
        ::CreateDirectoryW(dir.c_str(), nullptr);
        return dir + L"\\settings.json";
    }

    Windows::Data::Json::JsonObject SettingsStore::Load()
    {
        if (m_cache) { return m_cache; }
        m_cache = Windows::Data::Json::JsonObject();
        HANDLE file = ::CreateFileW(Path().c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
            OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
        if (file == INVALID_HANDLE_VALUE) { return m_cache; }
        std::string json;
        char chunk[4096];
        DWORD read = 0;
        while (::ReadFile(file, chunk, sizeof(chunk), &read, nullptr) && read > 0)
        {
            json.append(chunk, read);
        }
        ::CloseHandle(file);
        try
        {
            m_cache = Windows::Data::Json::JsonObject::Parse(to_hstring(json));
        }
        catch (hresult_error const&)
        {
            m_cache = Windows::Data::Json::JsonObject();   // 坏文件当空 (35 章 Storage 同款纪律)
        }
        return m_cache;
    }

    hstring SettingsStore::Get(hstring const& key, hstring const& fallback)
    {
        auto doc = Load();
        if (doc.HasKey(key))
        {
            return doc.GetNamedString(key);
        }
        return fallback;
    }

    void SettingsStore::Put(hstring const& key, hstring const& value)
    {
        Load();
        m_cache.Insert(key, Windows::Data::Json::JsonValue::CreateStringValue(value));
        m_dirty = true;
    }

    void SettingsStore::Save()
    {
        if (!m_dirty || !m_cache) { return; }
        auto text = m_cache.Stringify();
        HANDLE file = ::CreateFileW(Path().c_str(), GENERIC_WRITE, 0, nullptr,
            CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
        if (file == INVALID_HANDLE_VALUE) { return; }
        std::string utf8;
        for (wchar_t ch : std::wstring_view(text))
        {
            if (ch < 0x80) { utf8.push_back(static_cast<char>(ch)); }
            else { utf8.push_back('?'); }
        }
        DWORD written = 0;
        ::WriteFile(file, utf8.data(), static_cast<DWORD>(utf8.size()), &written, nullptr);
        ::CloseHandle(file);
        m_dirty = false;
    }
}
