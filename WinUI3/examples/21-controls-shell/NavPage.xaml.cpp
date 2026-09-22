#include "pch.h"
#include "NavPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::ShellGallery::implementation
{
    NavPage::NavPage()
    {
        InitializeComponent();
    }

    void NavPage::OnLeftClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!Embedded()) return;
        Embedded().PaneDisplayMode(NavigationViewPaneDisplayMode::Left);
        StatusText().Text(L"pane mode = Left");
    }

    void NavPage::OnCompactClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!Embedded()) return;
        Embedded().PaneDisplayMode(NavigationViewPaneDisplayMode::LeftCompact);
        StatusText().Text(L"pane mode = LeftCompact");
    }

    void NavPage::OnTopClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!Embedded()) return;
        Embedded().PaneDisplayMode(NavigationViewPaneDisplayMode::Top);
        StatusText().Text(L"pane mode = Top");
    }

    void NavPage::OnEmbeddedSelectionChanged(IInspectable const&,
        NavigationViewSelectionChangedEventArgs const& args)
    {
        if (!EmbeddedContent()) return;
        auto item = args.SelectedItem().as<NavigationViewItem>();
        EmbeddedContent().Text(L"section = " + unbox_value<hstring>(item.Tag()));
    }

    void NavPage::OnToggleSplitClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!Split() || !StatusText()) return;
        Split().IsPaneOpen(!Split().IsPaneOpen());
        StatusText().Text(Split().IsPaneOpen() ? L"split pane open" : L"split pane closed");
    }
}
