#include "pch.h"
#include "TablePage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
namespace wux = winrt::Microsoft::UI::Xaml::Controls;

namespace winrt::CollectionsGallery::implementation
{
    TablePage::TablePage()
    {
        InitializeComponent();
        for (auto const& name : { L"write guide", L"run smoke", L"fix bug", L"ship it" })
        {
            TaskTable().Items().Append(box_value(name));
        }
        auto tiles = single_threaded_vector<IInspectable>();
        for (int i = 1; i <= 8; ++i) tiles.Append(box_value(L"T" + to_hstring(i)));
        TileRepeater().ItemsSource(tiles);
    }

    void TablePage::OnRowSelected(IInspectable const&,
        wux::SelectionChangedEventArgs const&)
    {
        if (!TaskTable() || !StatusText()) return;
        if (auto item = TaskTable().SelectedItem())
        {
            StatusText().Text(L"row = " + unbox_value<hstring>(item));
        }
    }
}
