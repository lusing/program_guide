#include "pch.h"
#include "ComboBoxPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::BasicGallery::implementation
{
    ComboBoxPage::ComboBoxPage()
    {
        InitializeComponent();
    }

    void ComboBoxPage::OnThemeChanged(IInspectable const&, SelectionChangedEventArgs const&)
    {
        // 防护（12.5 教训）+ SelectedItem 是装箱对象，必须 unbox_value 解包
        if (!ThemeBox() || !StatusText()) return;
        if (auto item = ThemeBox().SelectedItem())
        {
            StatusText().Text(L"theme = " + winrt::unbox_value<hstring>(item));
        }
    }

    void ComboBoxPage::OnSelectDarkClicked(IInspectable const&, RoutedEventArgs const&)
    {
        // 程序化选择走 SelectedIndex，同样触发 SelectionChanged
        ThemeBox().SelectedIndex(1);
    }
}
