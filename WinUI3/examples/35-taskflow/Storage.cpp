#include "pch.h"
#include "Storage.h"

#include <shlwapi.h>

using namespace winrt;

namespace winrt::TaskFlow::implementation
{
    std::wstring Storage::TasksFilePath()
    {
        wchar_t buffer[MAX_PATH]{};
        ::GetEnvironmentVariableW(L"LOCALAPPDATA", buffer, MAX_PATH);
        std::wstring dir = std::wstring(buffer) + L"\\TaskFlow";
        ::CreateDirectoryW(dir.c_str(), nullptr);   // 已存在则失败，无害
        return dir + L"\\tasks.json";
    }

    std::vector<hstring> Storage::LoadTitles()
    {
        std::vector<hstring> titles;
        auto path = TasksFilePath();
        HANDLE file = ::CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
            OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
        if (file == INVALID_HANDLE_VALUE) { return titles; }

        std::string json;
        char chunk[4096];
        DWORD read = 0;
        while (::ReadFile(file, chunk, sizeof(chunk), &read, nullptr) && read > 0)
        {
            json.append(chunk, read);
        }
        ::CloseHandle(file);

        // Windows.Data.Json 解析（34 章 JSON 一节同款）；坏文件当空处理
        try
        {
            auto arr = Windows::Data::Json::JsonArray::Parse(to_hstring(json));
            for (auto&& v : arr)
            {
                titles.push_back(v.GetString());
            }
        }
        catch (winrt::hresult_error const&)
        {
        }
        return titles;
    }

    void Storage::SaveTitles(std::vector<hstring> const& titles)
    {
        auto path = TasksFilePath();
        auto arr = Windows::Data::Json::JsonArray();
        for (auto const& t : titles) { arr.Append(Windows::Data::Json::JsonValue::CreateStringValue(t)); }
        auto content = arr.Stringify();

        HANDLE file = ::CreateFileW(path.c_str(), GENERIC_WRITE, 0, nullptr,
            CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
        if (file == INVALID_HANDLE_VALUE) { return; }
        auto wide = std::wstring(content);
        std::string utf8;
        for (wchar_t ch : wide)
        {
            if (ch < 0x80) { utf8.push_back(static_cast<char>(ch)); }
            else { utf8.push_back('?'); }   // 教学工程：标题按 ASCII 存放
        }
        DWORD written = 0;
        ::WriteFile(file, utf8.data(), static_cast<DWORD>(utf8.size()), &written, nullptr);
        ::CloseHandle(file);
    }
}
