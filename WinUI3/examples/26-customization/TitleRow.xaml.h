#pragma once
#include "TitleRow.g.h"

namespace winrt::CustomGallery::implementation
{
    struct TitleRow : TitleRowT<TitleRow>
    {
        TitleRow();

        hstring Title();
        void Title(hstring const& value);
        hstring Value();
        void Value(hstring const& value);

    private:
        hstring m_title;
        hstring m_value;
    };
}

namespace winrt::CustomGallery::factory_implementation
{
    struct TitleRow : TitleRowT<TitleRow, implementation::TitleRow>
    {
    };
}
