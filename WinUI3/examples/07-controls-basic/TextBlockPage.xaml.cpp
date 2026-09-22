#include "pch.h"
#include "TextBlockPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::BasicGallery::implementation
{
    TextBlockPage::TextBlockPage()
    {
        InitializeComponent();
    }

    void TextBlockPage::OnCycleTrimClicked(IInspectable const&, RoutedEventArgs const&)
    {
        // TextTrimming 四值：None / CharacterEllipsis / WordEllipsis / Clip（Clip 是 WinUI 3 新增）
        static TextTrimming const modes[]{
            TextTrimming::None,
            TextTrimming::CharacterEllipsis,
            TextTrimming::WordEllipsis,
        };
        static hstring const names[]{
            L"None", L"CharacterEllipsis", L"WordEllipsis",
        };

        m_trimIndex = (m_trimIndex + 1) % 3;
        TrimDemo().TextTrimming(modes[m_trimIndex]);
        StatusText().Text(L"trim = " + names[m_trimIndex]);
    }
}
