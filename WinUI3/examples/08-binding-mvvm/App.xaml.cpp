#include "pch.h"
#include "App.xaml.h"
#include "MainWindow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::MvvmApp::implementation
{
    App::App()
    {
        InitializeComponent();   // 处理 App.xaml 里的资源字典
    }

    void App::OnLaunched(LaunchActivatedEventArgs const&)
    {
        window = make<MainWindow>();
        window.Activate();       // 显示窗口，开始接收消息
    }
}
