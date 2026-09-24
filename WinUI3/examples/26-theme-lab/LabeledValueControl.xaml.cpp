#include "pch.h"
#include "LabeledValueControl.xaml.h"
#if __has_include("LabeledValueControl.g.cpp")
#include "LabeledValueControl.g.cpp"
#endif

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::ThemeLab::implementation
{
    Microsoft::UI::Xaml::DependencyProperty LabeledValueControl::m_labelProperty{ nullptr };
    Microsoft::UI::Xaml::DependencyProperty LabeledValueControl::m_valueProperty{ nullptr };

    LabeledValueControl::LabeledValueControl()
    {
        InitializeComponent();
    }

    Microsoft::UI::Xaml::DependencyProperty LabeledValueControl::LabelProperty()
    {
        if (!m_labelProperty)
        {
            // 默认值必须给空串：x:Bind 在 InitializeComponent 里就取值，
            // null 默认会让 unbox 抛异常（stowed 0xC000027B，实测）
            m_labelProperty = Microsoft::UI::Xaml::DependencyProperty::Register(
                L"Label", xaml_typename<Windows::Foundation::IReference<hstring>>(),
                xaml_typename<ThemeLab::LabeledValueControl>(),
                Microsoft::UI::Xaml::PropertyMetadata(box_value(L"")));
        }
        return m_labelProperty;
    }

    Microsoft::UI::Xaml::DependencyProperty LabeledValueControl::ValueProperty()
    {
        if (!m_valueProperty)
        {
            m_valueProperty = Microsoft::UI::Xaml::DependencyProperty::Register(
                L"Value", xaml_typename<Windows::Foundation::IReference<hstring>>(),
                xaml_typename<ThemeLab::LabeledValueControl>(),
                Microsoft::UI::Xaml::PropertyMetadata(box_value(L"")));
        }
        return m_valueProperty;
    }

    hstring LabeledValueControl::Label() const
    {
        return unbox_value<hstring>(GetValue(LabelProperty()));   // 经惰性注册，勿直用字段
    }

    void LabeledValueControl::Label(hstring const& value)
    {
        SetValue(LabelProperty(), box_value(value));
    }

    hstring LabeledValueControl::Value() const
    {
        return unbox_value<hstring>(GetValue(ValueProperty()));
    }

    void LabeledValueControl::Value(hstring const& value)
    {
        SetValue(ValueProperty(), box_value(value));
    }

    void LabeledValueControl::OnLabelChanged(DependencyObject const&, DependencyPropertyChangedEventArgs const&) {}
    void LabeledValueControl::OnValueChanged(DependencyObject const&, DependencyPropertyChangedEventArgs const&) {}
}
