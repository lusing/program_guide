#include "pch.h"
#include "DocStore.h"

using namespace winrt;

namespace winrt::ScratchPad::implementation
{
    std::wstring DocStore::Dir()
    {
        wchar_t buffer[MAX_PATH]{};
        ::GetEnvironmentVariableW(L"LOCALAPPDATA", buffer, MAX_PATH);
        std::wstring dir = std::wstring(buffer) + L"\\ScratchPad";
        ::CreateDirectoryW(dir.c_str(), nullptr);
        return dir;
    }

    hstring DocStore::DirH()
    {
        return hstring(Dir());
    }

    void DocStore::Save(hstring const& name, hstring const& text)
    {
        std::wstring path = Dir() + L"\\" + std::wstring(name);
        // UTF-8 落盘（WideCharToMultiByte 默认替换非法序列，不会丢内容）
        std::wstring_view wide(text);
        int bytes = ::WideCharToMultiByte(CP_UTF8, 0, wide.data(),
            static_cast<int>(wide.size()), nullptr, 0, nullptr, nullptr);
        std::string utf8(bytes, '\0');
        ::WideCharToMultiByte(CP_UTF8, 0, wide.data(), static_cast<int>(wide.size()),
            utf8.data(), bytes, nullptr, nullptr);

        HANDLE file = ::CreateFileW(path.c_str(), GENERIC_WRITE, 0, nullptr,
            CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
        if (file == INVALID_HANDLE_VALUE) { return; }
        DWORD written = 0;
        ::WriteFile(file, utf8.data(), static_cast<DWORD>(utf8.size()), &written, nullptr);
        ::CloseHandle(file);
    }

    bool DocStore::Load(hstring const& name, hstring& text)
    {
        std::wstring path = Dir() + L"\\" + std::wstring(name);
        HANDLE file = ::CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
            OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
        if (file == INVALID_HANDLE_VALUE) { return false; }
        std::string utf8;
        char chunk[4096];
        DWORD read = 0;
        while (::ReadFile(file, chunk, sizeof(chunk), &read, nullptr) && read > 0)
        {
            utf8.append(chunk, read);
        }
        ::CloseHandle(file);

        int wide = ::MultiByteToWideChar(CP_UTF8, 0, utf8.data(),
            static_cast<int>(utf8.size()), nullptr, 0);
        std::wstring result(wide, L'\0');
        ::MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()),
            result.data(), wide);
        text = hstring(result);
        return true;
    }
}
