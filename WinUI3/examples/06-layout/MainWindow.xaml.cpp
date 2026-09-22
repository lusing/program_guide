#include "pch.h"
#include "MainWindow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::LayoutApp::implementation
{
    MainWindow::MainWindow()
    {
        InitializeComponent();
    }

    void MainWindow::OnReportSize(IInspectable const&, RoutedEventArgs const&)
    {
        // ActualWidth/ActualHeight 是布局完成后的实测尺寸（docs/07）
        auto w = rootPanel().ActualWidth();
        auto h = ContentStack().ActualHeight();
        StatusText().Text(L"panel " + winrt::to_hstring((int)w) +
                          L" x stack " + winrt::to_hstring((int)h));
    }
}
