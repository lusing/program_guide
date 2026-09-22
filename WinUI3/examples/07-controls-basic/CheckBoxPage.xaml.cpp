#include "pch.h"
#include "CheckBoxPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::BasicGallery::implementation
{
    CheckBoxPage::CheckBoxPage()
    {
        InitializeComponent();
    }

    void CheckBoxPage::OnNotifyChanged(IInspectable const&, RoutedEventArgs const&)
    {
        // IsChecked() 返回 IReference<bool>（三态），必须先解引用再判
        auto const& checked = NotifyBox().IsChecked();
        if (!checked)            { StatusText().Text(L"notifications = (null)"); }
        else if (checked.Value()) { StatusText().Text(L"notifications = on"); }
        else                     { StatusText().Text(L"notifications = off"); }
    }

    void CheckBoxPage::OnThemeChecked(IInspectable const& sender, RoutedEventArgs const&)
    {
        // sender 是被选中的 RadioButton：读 Content 标识哪一项
        auto button = sender.as<RadioButton>();
        StatusText().Text(L"theme = " + button.Content().as<hstring>());
    }
}
