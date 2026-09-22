#include "pch.h"
#include "MainWindow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::CustomGallery::implementation
{
    MainWindow::MainWindow()
    {
        InitializeComponent();
        Title(L"CustomGallery");
        if (auto appWindow = AppWindow())
        {
            appWindow.Resize({ 1280, 860 });
        }
        ContentFrame().Navigate(xaml_typename<CustomGallery::HomePage>());
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
        if (tag == L"home") ContentFrame().Navigate(xaml_typename<CustomGallery::HomePage>());
        if (tag == L"styles") ContentFrame().Navigate(xaml_typename<CustomGallery::StylesPage>());
        if (tag == L"customcontrol") ContentFrame().Navigate(xaml_typename<CustomGallery::CustomControlPage>());
        if (tag == L"vsm") ContentFrame().Navigate(xaml_typename<CustomGallery::VsmPage>());
        if (tag == L"animation") ContentFrame().Navigate(xaml_typename<CustomGallery::AnimationPage>());
        if (tag == L"drawing") ContentFrame().Navigate(xaml_typename<CustomGallery::DrawingPage>());
        // 每章任务追加分支
    }
}
