#pragma once
#include "MainWindow.g.h"
#include "LibraryViewModel.h"

namespace winrt::MediaLibrary::implementation
{
    struct MainWindow : MainWindowT<MainWindow>
    {
        MainWindow();

        winrt::MediaLibrary::LibraryViewModel ViewModel() { return m_viewModel; }

        // 12.5 教训：SelectionChanged 在 XAML 解析期就可能触发，判空是铁律
        void OnSelectionChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::SelectionChangedEventArgs const& args);
        // 过滤 ComboBox 的选中回写（x:Bind TwoWay 回程无 IInspectable→hstring 转换）
        void OnCategoryChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::SelectionChangedEventArgs const& args);

    private:
        winrt::MediaLibrary::LibraryViewModel m_viewModel{ nullptr };
        winrt::Microsoft::UI::Xaml::Window::Activated_revoker m_activatedRevoker{};
    };
}

namespace winrt::MediaLibrary::factory_implementation
{
    struct MainWindow : MainWindowT<MainWindow, implementation::MainWindow>
    {
    };
}
