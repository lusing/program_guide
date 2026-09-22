#pragma once
#include "LabeledValueControl.g.h"

namespace winrt::CustomGallery::implementation
{
    struct LabeledValueControl : LabeledValueControlT<LabeledValueControl>
    {
        LabeledValueControl();

        static Microsoft::UI::Xaml::DependencyProperty LabelProperty();
        static Microsoft::UI::Xaml::DependencyProperty ValueProperty();

        hstring Label();
        void Label(hstring const& value);
        hstring Value();
        void Value(hstring const& value);

        void OnApplyTemplate();
    };
}

namespace winrt::CustomGallery::factory_implementation
{
    struct LabeledValueControl : LabeledValueControlT<LabeledValueControl, implementation::LabeledValueControl>
    {
    };
}
