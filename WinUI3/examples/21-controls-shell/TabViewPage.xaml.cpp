#include "pch.h"
#include "TabViewPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::ShellGallery::implementation
{
    TabViewPage::TabViewPage()
    {
        InitializeComponent();
    }

    void TabViewPage::OnTabSelectionChanged(IInspectable const&,
        SelectionChangedEventArgs const&)
    {
        if (!Docs() || !StatusText()) return;
        auto item = Docs().SelectedItem().as<TabViewItem>();
        StatusText().Text(L"tab = " + item.Header().as<hstring>());
    }

    void TabViewPage::OnTabCloseRequested(IInspectable const&,
        TabViewTabCloseRequestedEventArgs const& args)
    {
        // 关闭不自动发生：必须在这里真正移除 TabItems 里的那一项
        uint32_t index{};
        if (Docs().TabItems().IndexOf(args.Tab(), index))
        {
            Docs().TabItems().RemoveAt(index);
            StatusText().Text(L"closed a tab, left = " + to_hstring(Docs().TabItems().Size()));
        }
    }

    void TabViewPage::OnAddTabClicked(IInspectable const&, IInspectable const&)
    {
        TabViewItem item;
        item.Header(box_value(L"new " + to_hstring(Docs().TabItems().Size())));
        Docs().TabItems().Append(item);
        Docs().SelectedItem(item);
    }

    void TabViewPage::OnExpanderExpanding(IInspectable const&, Controls::ExpanderExpandingEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"expander expanding");
    }

    void TabViewPage::OnExpanderCollapsed(IInspectable const&, Controls::ExpanderCollapsedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"expander collapsed");
    }
}
