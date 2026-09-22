#include "pch.h"
#include "App.xaml.h"
#include "MainWindow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Media;

namespace winrt::TaskFlow::implementation
{
    App::App()
    {
        InitializeComponent();
    }

    void App::OnLaunched(LaunchActivatedEventArgs const&)
    {
        window = make<MainWindow>();
        window.Activate();
    }

    void App::SetMica(bool on)
    {
        if (auto main = window.as<winrt::TaskFlow::MainWindow>())
        {
            main.SetBackdrop(on);
        }
    }
}
