#include "pch.h"
#include "MainWindow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Media;

namespace winrt::WindowShellApp::implementation
{
    MainWindow::MainWindow()
    {
        InitializeComponent();
        Title(L"WindowShell");
        if (auto appWindow = AppWindow())
        {
            appWindow.Resize({ 900, 640 });
        }
        // 31.2 内容延伸进标题栏，自绘条成为拖拽区
        ExtendsContentIntoTitleBar(true);
        SetTitleBar(AppTitleBar());
        // 31.3 加载即 Mica
        SystemBackdrop(MicaBackdrop());
    }

    void MainWindow::OnBackdropNone(IInspectable const&, RoutedEventArgs const&)
    {
        SystemBackdrop(nullptr);
        StatusText().Text(L"backdrop = none");
    }

    void MainWindow::OnBackdropMica(IInspectable const&, RoutedEventArgs const&)
    {
        SystemBackdrop(MicaBackdrop());
        StatusText().Text(L"backdrop = mica");
    }

    void MainWindow::OnBackdropAcrylic(IInspectable const&, RoutedEventArgs const&)
    {
        SystemBackdrop(DesktopAcrylicBackdrop());
        StatusText().Text(L"backdrop = acrylic");
    }

    void MainWindow::OnNewWindowClicked(IInspectable const&, RoutedEventArgs const&)
    {
        // 31.4 多窗口：同线程再开一个 Window（本页 UI 是同一个 DispatcherQueue）
        auto second = make<MainWindow>();
        second.Activate();
        StatusText().Text(L"second window opened");
    }
}
