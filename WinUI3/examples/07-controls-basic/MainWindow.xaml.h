#pragma once
#include "MainWindow.g.h"

namespace winrt::BasicGallery::implementation
{
    struct MainWindow : MainWindowT<MainWindow>
    {
        MainWindow();

        void OnNavSelectionChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::NavigationViewSelectionChangedEventArgs const& args);

    private:
        // tag -> Page 的分发表：每章任务在此追加一个分支
        void NavigateTo(winrt::hstring const& tag);
    };
}

namespace winrt::BasicGallery::factory_implementation
{
    struct MainWindow : MainWindowT<MainWindow, implementation::MainWindow>
    {
    };
}
