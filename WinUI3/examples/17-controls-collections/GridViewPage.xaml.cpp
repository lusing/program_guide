#include "pch.h"
#include "GridViewPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
namespace wux = winrt::Microsoft::UI::Xaml::Controls;

namespace winrt::CollectionsGallery::implementation
{
    GridViewPage::GridViewPage()
    {
        InitializeComponent();
        for (auto const& tag : { L"alpha", L"beta", L"gamma", L"delta", L"epsilon" })
        {
            CardGrid().Items().Append(box_value(tag));
        }
    }

    void GridViewPage::OnCardSelectionChanged(IInspectable const&,
        wux::SelectionChangedEventArgs const&)
    {
        if (!CardGrid() || !StatusText()) return;
        if (auto item = CardGrid().SelectedItem())
        {
            StatusText().Text(L"card = " + unbox_value<hstring>(item));
        }
    }

    void GridViewPage::OnFlipChanged(IInspectable const&,
        wux::SelectionChangedEventArgs const&)
    {
        if (!Pager() || !StatusText()) return;
        StatusText().Text(L"flip page = " + to_hstring(Pager().SelectedIndex() + 1));
    }

    void GridViewPage::OnNextClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!Pager()) return;
        int next = Pager().SelectedIndex() + 1;
        if (next >= static_cast<int>(Pager().Items().Size())) next = 0;
        Pager().SelectedIndex(next);
    }
}
