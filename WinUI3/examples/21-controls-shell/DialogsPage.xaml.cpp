#include "pch.h"
#include "DialogsPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::ShellGallery::implementation
{
    DialogsPage::DialogsPage()
    {
        InitializeComponent();
    }

    void DialogsPage::OnShowDialogClicked(IInspectable const&, RoutedEventArgs const&)
    {
        (void)ShowDialogAsync();
    }

    winrt::Windows::Foundation::IAsyncAction DialogsPage::ShowDialogAsync()
    {
        ContentDialog dialog;
        dialog.Title(box_value(L"Confirm removal"));
        dialog.Content(box_value(L"ContentDialog from a Page: XamlRoot still comes from the content tree root."));
        dialog.PrimaryButtonText(L"Remove");
        dialog.SecondaryButtonText(L"Keep");
        dialog.CloseButtonText(L"Cancel");
        dialog.DefaultButton(ContentDialogButton::Primary);

        // 24.2 核心坑：XamlRoot 从内容树根取（Window 自己没有这个成员）
        dialog.XamlRoot(rootPanel().XamlRoot());

        auto result = co_await dialog.ShowAsync();
        hstring verdict = result == ContentDialogResult::Primary ? L"primary: removed"
                       : result == ContentDialogResult::Secondary ? L"secondary: kept"
                                                                   : L"dismissed";
        if (!StatusText()) co_return;
        StatusText().Text(verdict);
    }

    void DialogsPage::OnRetryClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"flyout: retry");
    }

    void DialogsPage::OnSkipClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"flyout: skip");
    }
}
