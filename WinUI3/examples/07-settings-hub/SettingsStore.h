// Services/SettingsStore.h -- %LOCALAPPDATA%\SettingsHub\settings.json (34 章路线)
#pragma once
#include <string>

namespace winrt::SettingsHub::implementation
{
    // 极简键值存取：教学用，够小够直白
    struct SettingsStore
    {
        static hstring Get(hstring const& key, hstring const& fallback);
        static void Put(hstring const& key, hstring const& value);
        static void Save();

    private:
        static std::wstring Path();
        static Windows::Data::Json::JsonObject Load();
        static Windows::Data::Json::JsonObject m_cache;
        static bool m_dirty;
    };
}
