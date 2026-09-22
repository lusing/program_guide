#include "pch.h"
#include "TreeViewPage.xaml.h"

#include <array>

using namespace winrt;
using namespace Microsoft::UI::Xaml;
namespace wux = winrt::Microsoft::UI::Xaml::Controls;

namespace winrt::CollectionsGallery::implementation
{
    TreeViewPage::TreeViewPage()
    {
        InitializeComponent();
        // 三根两子的小树
        auto make_child = [](hstring const& name)
        {
            wux::TreeViewNode c;
            c.Content(box_value(name));
            return c;
        };
        for (auto const& root : std::array<hstring, 3>{ L"src", L"docs", L"examples" })
        {
            wux::TreeViewNode node;
            node.Content(box_value(root));
            node.Children().Append(make_child(root + L"/a"));
            node.Children().Append(make_child(root + L"/b"));
            DirTree().RootNodes().Append(node);
        }
    }

    void TreeViewPage::OnNodeInvoked(IInspectable const&,
        wux::TreeViewItemInvokedEventArgs const& args)
    {
        if (!StatusText()) return;
        // ItemInvoked 的项在 InvokedItem()，是 TreeViewNode
        auto node = args.InvokedItem().as<wux::TreeViewNode>();
        if (auto content = node.Content())
        {
            StatusText().Text(L"node = " + unbox_value<hstring>(content));
        }
    }

    void TreeViewPage::OnExpandAllClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!DirTree()) return;
        int count = 0;
        for (auto const& node : DirTree().RootNodes())
        {
            ExpandRecursively(node, count);
        }
        StatusText().Text(L"expanded " + to_hstring(count) + L" nodes");
    }

    void TreeViewPage::ExpandRecursively(wux::TreeViewNode const& node, int& count)
    {
        node.IsExpanded(true);
        ++count;
        for (auto const& child : node.Children())
        {
            ExpandRecursively(child, count);
        }
    }
}
