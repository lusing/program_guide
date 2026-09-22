#include "pch.h"
#include "CommandBarPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;
using namespace Microsoft::UI::Xaml::Controls::Primitives;

namespace winrt::ShellGallery::implementation
{
    CommandBarPage::CommandBarPage()
    {
        InitializeComponent();
    }

    void CommandBarPage::OnAddClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"command: add");
    }

    void CommandBarPage::OnSaveClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"command: save");
    }

    void CommandBarPage::OnPinClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"command: pin");
    }

    void CommandBarPage::OnSettingsClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"command: settings");
    }

    void CommandBarPage::OnMenuNew(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"menu: new");
    }

    void CommandBarPage::OnMenuExit(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"menu: exit");
    }

    void CommandBarPage::OnMenuGrid(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"menu: toggle grid");
    }

    void CommandBarPage::OnCtxZoneRightTapped(IInspectable const& sender,
        Input::RightTappedRoutedEventArgs const& args)
    {
        // 上下文菜单标准模式：AttachedFlyout + RightTapped + ShowAt(位置)
        auto element = sender.as<FrameworkElement>();
        // 元数据实测：ShowAt 没有 (element, Point) 重载；位置要包进 FlyoutShowOptions
        Primitives::FlyoutShowOptions options;
        options.Position(args.GetPosition(element));
        FlyoutBase::GetAttachedFlyout(element).ShowAt(element, options);
        args.Handled(true);
        if (!StatusText()) return;
        StatusText().Text(L"context flyout shown");
    }

    void CommandBarPage::OnMenuRefresh(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"context: refresh");
    }

    void CommandBarPage::OnMenuDelete(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"context: delete");
    }
}
