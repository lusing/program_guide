#include "pch.h"
#include "LabeledValueControl.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::CustomGallery::implementation
{
    static Microsoft::UI::Xaml::DependencyProperty s_labelProperty{ nullptr };
    static Microsoft::UI::Xaml::DependencyProperty s_valueProperty{ nullptr };

    LabeledValueControl::LabeledValueControl()
    {
        // 27.3 的接线：默认样式键指向 Generic.xaml 里的 Style
        DefaultStyleKey(box_value(L"CustomGallery.LabeledValueControl"));
    }

    Microsoft::UI::Xaml::DependencyProperty LabeledValueControl::LabelProperty()
    {
        if (!s_labelProperty)
        {
            s_labelProperty = Microsoft::UI::Xaml::DependencyProperty::Register(
                L"Label", xaml_typename<Windows::Foundation::IInspectable>(),
                xaml_typename<CustomGallery::LabeledValueControl>(), nullptr);
        }
        return s_labelProperty;
    }

    Microsoft::UI::Xaml::DependencyProperty LabeledValueControl::ValueProperty()
    {
        if (!s_valueProperty)
        {
            s_valueProperty = Microsoft::UI::Xaml::DependencyProperty::Register(
                L"Value", xaml_typename<Windows::Foundation::IInspectable>(),
                xaml_typename<CustomGallery::LabeledValueControl>(), nullptr);
        }
        return s_valueProperty;
    }

    hstring LabeledValueControl::Label()
    {
        auto v = GetValue(LabelProperty()).try_as<Windows::Foundation::IReference<hstring>>();
        return v ? v.Value() : L"";
    }
    void LabeledValueControl::Label(hstring const& value)
    {
        SetValue(LabelProperty(), box_value(value));
    }
    hstring LabeledValueControl::Value()
    {
        auto v = GetValue(ValueProperty()).try_as<Windows::Foundation::IReference<hstring>>();
        return v ? v.Value() : L"";
    }
    void LabeledValueControl::Value(hstring const& value)
    {
        SetValue(ValueProperty(), box_value(value));
    }

    void LabeledValueControl::OnApplyTemplate()
    {
        base_type::OnApplyTemplate();
        // TemplatePart 约定：模板就位后取部件（27.3）
        if (auto part = GetTemplateChild(L"PART_ValueText").try_as<TextBlock>())
        {
            part.Text(Value().empty() ? L"-" : Value());
        }
    }
}
