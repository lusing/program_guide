#pragma once

#include "pch.h"

namespace winrt::ThemeLab::implementation
{
    // One skin preset: a name, an accent colour, and whether the shell goes
    // dark. Presets are the "make theming visible" hook of chapter 26.
    struct Preset
    {
        hstring Name;
        uint8_t R{ 0 }, G{ 0 }, B{ 0 };
        bool Dark{ false };
    };

    struct Presets
    {
        static std::vector<Preset> All();
    };
}
