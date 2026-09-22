#include "pch.h"
#include "MainWindow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;
using namespace Microsoft::UI::Xaml::Media;

namespace winrt::TaskFlow::implementation
{
    MainWindow::MainWindow()
    {
        InitializeComponent();
        Title(L"TaskFlow");
        if (auto appWindow = AppWindow())
        {
            appWindow.Resize({ 1100, 800 });
        }
        // 31 章：内容延伸进标题栏之外，Mica 贯通（此处保持系统标题栏，简化）
        SystemBackdrop(MicaBackdrop());
        ContentFrame().Navigate(xaml_typename<TaskFlow::TaskListPage>());
    }

    void MainWindow::SetBackdrop(bool mica)
    {
        // 两个 Backdrop 派生类型没有公共三元类型，分开赋值
        if (mica)
        {
            SystemBackdrop(Microsoft::UI::Xaml::Media::MicaBackdrop());
        }
        else
        {
            SystemBackdrop(Microsoft::UI::Xaml::Media::DesktopAcrylicBackdrop());
        }
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
        if (tag == L"tasks") ContentFrame().Navigate(xaml_typename<TaskFlow::TaskListPage>());
        if (tag == L"settings") ContentFrame().Navigate(xaml_typename<TaskFlow::SettingsPage>());
    }
}
