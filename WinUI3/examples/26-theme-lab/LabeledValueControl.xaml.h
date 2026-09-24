#pragma once
#include "LabeledValueControl.g.h"

namespace winrt::ThemeLab::implementation
{
    struct LabeledValueControl : LabeledValueControlT<LabeledValueControl>
    {
        LabeledValueControl();

        static Microsoft::UI::Xaml::DependencyProperty LabelProperty();
        static Microsoft::UI::Xaml::DependencyProperty ValueProperty();

        hstring Label() const;
        void Label(hstring const& value);
        hstring Value() const;
        void Value(hstring const& value);

        static void OnLabelChanged(Microsoft::UI::Xaml::DependencyObject const& d,
            Microsoft::UI::Xaml::DependencyPropertyChangedEventArgs const&);
        static void OnValueChanged(Microsoft::UI::Xaml::DependencyObject const& d,
            Microsoft::UI::Xaml::DependencyPropertyChangedEventArgs const&);

    private:
        static Microsoft::UI::Xaml::DependencyProperty m_labelProperty;
        static Microsoft::UI::Xaml::DependencyProperty m_valueProperty;
    };
}

namespace winrt::ThemeLab::factory_implementation
{
    struct LabeledValueControl : LabeledValueControlT<LabeledValueControl, implementation::LabeledValueControl>
    {
    };
}
