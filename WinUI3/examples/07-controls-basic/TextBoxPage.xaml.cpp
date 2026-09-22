#include "pch.h"
#include "TextBoxPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::BasicGallery::implementation
{
    TextBoxPage::TextBoxPage()
    {
        InitializeComponent();
        // RichEditBox 的内容不是 Text 属性，进 Document()（ITextDocument）
        RichBox().Document().SetText(Microsoft::UI::Text::TextSetOptions::None,
            L"Hello from RichEditBox. Select a word, then click Bold selection.");
    }

    void TextBoxPage::OnNameChanged(IInspectable const&, TextChangedEventArgs const&)
    {
        // TextChanged 不带旧值/新值：文本已经改完，要旧值自己记
        auto text = NameBox().Text();
        StatusText().Text(L"title len = " + winrt::to_hstring(text.size()));
    }

    void TextBoxPage::OnPasswordChanged(IInspectable const&, RoutedEventArgs const&)
    {
        StatusText().Text(L"password len = "
            + winrt::to_hstring(SecretBox().Password().size()));
    }

    void TextBoxPage::OnBoldClicked(IInspectable const&, RoutedEventArgs const&)
    {
        // 选区字符格式：Bold 是 FormatEffect 枚举（Off/On/Toggle/Undefined，元数据核对）
        using Microsoft::UI::Text::FormatEffect;
        RichBox().Document().Selection().CharacterFormat().Bold(FormatEffect::Toggle);
        StatusText().Text(L"selection bold toggled");
    }

    void TextBoxPage::OnReadRichClicked(IInspectable const&, RoutedEventArgs const&)
    {
        // 元数据形状：Void GetText(TextGetOptions, String&) —— C++/WinRT 原样保留双参数（out 不收成返回值）
        hstring raw;
        RichBox().Document().GetText(Microsoft::UI::Text::TextGetOptions::None, raw);
        // 结尾会带回车换行，去掉再展示
        std::wstring_view v(raw.c_str(), raw.size());
        while (!v.empty() && (v.back() == L'\r' || v.back() == L'\n')) v.remove_suffix(1);
        StatusText().Text(L"rich text = \"" + hstring(v) + L"\"");
    }
}
