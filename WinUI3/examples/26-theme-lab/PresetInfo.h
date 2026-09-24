#pragma once
#include "PresetInfo.g.h"

namespace winrt::ThemeLab::implementation
{
    struct PresetInfo : PresetInfoT<PresetInfo>
    {
        PresetInfo(hstring const& name, Windows::UI::Color const& swatch)
            : m_name(name), m_swatch(swatch)
        {
        }

        hstring Name() const { return m_name; }
        void Name(hstring const& value) { m_name = value; }
        Windows::UI::Color Swatch() const { return m_swatch; }
        void Swatch(Windows::UI::Color const& value) { m_swatch = value; }

    private:
        hstring m_name;
        Windows::UI::Color m_swatch;
    };
}

namespace winrt::ThemeLab::factory_implementation
{
    struct PresetInfo : PresetInfoT<PresetInfo, implementation::PresetInfo>
    {
    };
}
