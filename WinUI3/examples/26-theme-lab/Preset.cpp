#include "pch.h"
#include "Preset.h"

namespace winrt::ThemeLab::implementation
{
    std::vector<Preset> Presets::All()
    {
        return {
            { L"Morning Mist", 0x00, 0x78, 0xD4, false },   // 经典蓝，亮色
            { L"Ink Stone",    0x9A, 0xA6, 0xB2, true  },   // 铁灰，暗色
            { L"Sunset",       0xC4, 0x2B, 0x1C, true  },   // 落日红，暗色
            { L"Forest",       0x1F, 0x8A, 0x4C, false },   // 林海绿，亮色
        };
    }
}
