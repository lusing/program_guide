#include "pch.h"
#include "ButtonPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::BasicGallery::implementation
{
    ButtonPage::ButtonPage()
    {
        InitializeComponent();
    }

    void ButtonPage::OnMainClick(IInspectable const&, RoutedEventArgs const&)
    {
        ++m_mainCount;
        StatusText().Text(L"clicked " + winrt::to_hstring(m_mainCount));
    }

    void ButtonPage::OnRepeatClick(IInspectable const&, RoutedEventArgs const&)
    {
        ++m_repeatCount;
        StatusText().Text(L"repeat " + winrt::to_hstring(m_repeatCount)
            + L" (hold to keep firing)");
    }

    void ButtonPage::OnExportKind(IInspectable const& sender, RoutedEventArgs const&)
    {
        // 事件 sender 是菜单项本体：MenuFlyoutItem.Text() 读回点的是哪一项
        auto item = sender.as<MenuFlyoutItem>();
        StatusText().Text(L"export = " + item.Text());
    }
}
