#pragma once

#include "pch.h"

namespace winrt::ScratchPad::implementation
{
    // 文档落盘：%LOCALAPPDATA%\ScratchPad\<name>，UTF-8 无 BOM。
    struct DocStore
    {
        static std::wstring Dir();
        static hstring DirH();
        static void Save(hstring const& name, hstring const& text);
        static bool Load(hstring const& name, hstring& text);
    };
}
