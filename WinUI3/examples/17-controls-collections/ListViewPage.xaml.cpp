#include "pch.h"
#include "ListViewPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
namespace wux = winrt::Microsoft::UI::Xaml::Controls;

namespace winrt::CollectionsGallery::implementation
{
    ListViewPage::ListViewPage()
    {
        InitializeComponent();
        for (auto const& fruit : { L"apple", L"banana", L"cherry", L"durian", L"elderberry" })
        {
            FruitList().Items().Append(box_value(fruit));
        }
        m_items = FruitList().Items();
    }

    void ListViewPage::OnFruitSelectionChanged(IInspectable const&,
        wux::SelectionChangedEventArgs const&)
    {
        if (!FruitList() || !StatusText()) return;
        if (auto item = FruitList().SelectedItem())
        {
            StatusText().Text(L"selected = " + unbox_value<hstring>(item));
        }
    }

    void ListViewPage::OnAddClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!m_items) return;
        m_items.Append(box_value(L"fig " + to_hstring(m_items.Size())));
        StatusText().Text(L"items = " + to_hstring(m_items.Size()));
    }

    void ListViewPage::OnRemoveClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!m_items || !FruitList()) return;
        auto idx = FruitList().SelectedIndex();
        if (idx >= 0)
        {
            m_items.RemoveAt(static_cast<uint32_t>(idx));
            StatusText().Text(L"removed, items = " + to_hstring(m_items.Size()));
        }
    }
}
