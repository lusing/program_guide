#include "pch.h"
#include "MainWindow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::CollectionsGallery::implementation
{
    MainWindow::MainWindow()
    {
        InitializeComponent();
        Title(L"CollectionsGallery");
        if (auto appWindow = AppWindow())
        {
            appWindow.Resize({ 1280, 860 });
        }
        ContentFrame().Navigate(xaml_typename<CollectionsGallery::HomePage>());
    }

    void MainWindow::OnNavSelectionChanged(IInspectable const&,
        NavigationViewSelectionChangedEventArgs const& args)
    {
        if (auto item = args.SelectedItem().try_as<NavigationViewItem>())
        {
            NavigateTo(winrt::unbox_value<winrt::hstring>(item.Tag()));
        }
    }

    void MainWindow::NavigateTo(winrt::hstring const& tag)
    {
        if (tag == L"home") ContentFrame().Navigate(xaml_typename<CollectionsGallery::HomePage>());
        if (tag == L"listview") ContentFrame().Navigate(xaml_typename<CollectionsGallery::ListViewPage>());
        if (tag == L"gridview") ContentFrame().Navigate(xaml_typename<CollectionsGallery::GridViewPage>());
        if (tag == L"treeview") ContentFrame().Navigate(xaml_typename<CollectionsGallery::TreeViewPage>());
        if (tag == L"table") ContentFrame().Navigate(xaml_typename<CollectionsGallery::TablePage>());
        // 每章任务追加分支
    }
}
