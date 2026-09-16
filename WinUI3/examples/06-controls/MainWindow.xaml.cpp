#include "pch.h"
#include "MainWindow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::ControlsApp::implementation
{
    MainWindow::MainWindow()
    {
        InitializeComponent();
    }

    void MainWindow::OnThemeChanged(IInspectable const&, SelectionChangedEventArgs const&)
    {
        // SelectedItem() 返回 IInspectable（装箱对象），必须 unbox_value<T> 解包（docs/06 6.4）
        auto item = ThemeBox().SelectedItem();
        auto theme = winrt::unbox_value<winrt::hstring>(item);
        StatusText().Text(L"theme = " + theme);
    }

    void MainWindow::OnNotifyToggled(IInspectable const&, RoutedEventArgs const&)
    {
        // IsChecked() 返回 IReference<bool>（三态），必须先解包（docs/06 6.3）
        StatusText().Text(NotifyBox().IsChecked().Value()
            ? L"notifications on"
            : L"notifications off");
    }

    void MainWindow::OnThemeRadioChecked(IInspectable const& sender, RoutedEventArgs const&)
    {
        auto button = sender.as<RadioButton>();
        StatusText().Text(L"radio = " + button.Content().as<winrt::hstring>());
    }

    void MainWindow::OnAutoSaveToggled(IInspectable const&, RoutedEventArgs const&)
    {
        // ToggleSwitch 就是普通 bool，无三态问题（docs/06 6.6）
        StatusText().Text(AutoSaveSwitch().IsOn() ? L"autosave on" : L"autosave off");
    }

    void MainWindow::OnVolumeChanged(IInspectable const&,
        Microsoft::UI::Xaml::Controls::Primitives::RangeBaseValueChangedEventArgs const& args)
    {
        StatusText().Text(L"volume = " + winrt::to_hstring(args.NewValue()));
    }

    void MainWindow::OnShowDialogClicked(IInspectable const&, RoutedEventArgs const&)
    {
        (void)ShowDialogAsync();
    }

    winrt::Windows::Foundation::IAsyncAction MainWindow::ShowDialogAsync()
    {
        ContentDialog dialog;
        dialog.Title(box_value(L"Confirm"));
        dialog.Content(box_value(L"ContentDialog from a Window needs an explicit XamlRoot."));
        dialog.PrimaryButtonText(L"OK");
        dialog.CloseButtonText(L"Cancel");
        dialog.DefaultButton(ContentDialogButton::Primary);

        // WinUI 3 必须设置 XamlRoot，否则 ShowAsync 运行时抛 "XamlRoot has not been set"。
        // Window 本身没有 XamlRoot 成员，只能从内容树根元素取（docs/06 6.7）。
        dialog.XamlRoot(rootPanel().XamlRoot());

        auto result = co_await dialog.ShowAsync();
        StatusText().Text(result == ContentDialogResult::Primary
            ? L"dialog: primary"
            : L"dialog: dismissed");
    }
}
