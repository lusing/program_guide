#include "pch.h"
#include "MainWindow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::MyApp::implementation
{
    MainWindow::MainWindow()
    {
        InitializeComponent();   // 执行 XAML 编译器生成的界面构建代码
    }

    void MainWindow::OnClick(IInspectable const& sender, RoutedEventArgs const&)
    {
        // x:Name 生成的访问器：StatusText() 返回 TextBlock 对象
        StatusText().Text(L"Clicked from C++/WinRT");
    }
}
