#include "pch.h"
#include "MainWindow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::ShellGallery::implementation
{
    MainWindow::MainWindow()
    {
        InitializeComponent();
        Title(L"ShellGallery");
        if (auto appWindow = AppWindow())
        {
            appWindow.Resize({ 1280, 860 });
        }
        ContentFrame().Navigate(xaml_typename<ShellGallery::HomePage>());
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
        if (tag == L"home") ContentFrame().Navigate(xaml_typename<ShellGallery::HomePage>());
        if (tag == L"tabview") ContentFrame().Navigate(xaml_typename<ShellGallery::TabViewPage>());
        if (tag == L"navigationview") ContentFrame().Navigate(xaml_typename<ShellGallery::NavPage>());
        if (tag == L"commandbar") ContentFrame().Navigate(xaml_typename<ShellGallery::CommandBarPage>());
        if (tag == L"dialogs") ContentFrame().Navigate(xaml_typename<ShellGallery::DialogsPage>());
        if (tag == L"overlays") ContentFrame().Navigate(xaml_typename<ShellGallery::OverlaysPage>());
        if (tag == L"home") ContentFrame().Navigate(xaml_typename<ShellGallery::HomePage>());
        if (tag == L"tabview") ContentFrame().Navigate(xaml_typename<ShellGallery::TabViewPage>());
        if (tag == L"navigationview") ContentFrame().Navigate(xaml_typename<ShellGallery::NavPage>());
        if (tag == L"commandbar") ContentFrame().Navigate(xaml_typename<ShellGallery::CommandBarPage>());
        if (tag == L"dialogs") ContentFrame().Navigate(xaml_typename<ShellGallery::DialogsPage>());
        if (tag == L"overlays") ContentFrame().Navigate(xaml_typename<ShellGallery::OverlaysPage>());
        // 每章任务追加分支
    }
}
