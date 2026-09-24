#pragma once
#include "MainWindow.g.h"

namespace winrt::ScratchPad::implementation
{
    // 每个 TabViewItem 对应一份文档状态（TabViewItem 持引用计数，安全存副本）
    struct TabEntry
    {
        Microsoft::UI::Xaml::Controls::TabViewItem Tab{ nullptr };
        winrt::hstring Name;
        bool Dirty{ false };
    };

    struct MainWindow : MainWindowT<MainWindow>
    {
        MainWindow();

        void OnNewTab(Windows::Foundation::IInspectable const& sender, Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnSave(Windows::Foundation::IInspectable const& sender, Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnExit(Windows::Foundation::IInspectable const& sender, Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnSelectAll(Windows::Foundation::IInspectable const& sender, Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnToggleFind(Windows::Foundation::IInspectable const& sender, Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnBold(Windows::Foundation::IInspectable const& sender, Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnBoldMenu(Windows::Foundation::IInspectable const& sender, Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnFindChanged(Windows::Foundation::IInspectable const& sender, Microsoft::UI::Xaml::Controls::TextChangedEventArgs const& args);
        void OnFindNext(Windows::Foundation::IInspectable const& sender, Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnAddTabButton(Windows::Foundation::IInspectable const& sender, Windows::Foundation::IInspectable const& args);

        Windows::Foundation::IAsyncAction OnTabCloseRequested(
            Microsoft::UI::Xaml::Controls::TabView const& sender,
            Microsoft::UI::Xaml::Controls::TabViewTabCloseRequestedEventArgs const& args);

        void OnSaveKey(Microsoft::UI::Xaml::Input::KeyboardAccelerator const& sender,
            Microsoft::UI::Xaml::Input::KeyboardAcceleratorInvokedEventArgs const& args);
        void OnNewTabKey(Microsoft::UI::Xaml::Input::KeyboardAccelerator const& sender,
            Microsoft::UI::Xaml::Input::KeyboardAcceleratorInvokedEventArgs const& args);
        void OnFindKey(Microsoft::UI::Xaml::Input::KeyboardAccelerator const& sender,
            Microsoft::UI::Xaml::Input::KeyboardAcceleratorInvokedEventArgs const& args);
        void OnBoldKey(Microsoft::UI::Xaml::Input::KeyboardAccelerator const& sender,
            Microsoft::UI::Xaml::Input::KeyboardAcceleratorInvokedEventArgs const& args);

    private:
        void AddTab();
        Microsoft::UI::Xaml::Controls::RichEditBox ActiveEditor();
        TabEntry* FindEntry(Microsoft::UI::Xaml::Controls::TabViewItem const& tab);
        void SaveTab(Microsoft::UI::Xaml::Controls::TabViewItem const& tab);
        void CloseTab(Microsoft::UI::Xaml::Controls::TabViewItem const& tab);
        void ToggleBold(bool on);
        void UpdateMatches();
        void UpdateStatus(winrt::hstring const& extra);

        std::vector<TabEntry> m_docs;
        winrt::hstring m_saveProbe;
        std::vector<uint32_t> m_matches;   // 查找命中起始位置（活动文档）
        size_t m_matchIndex{ 0 };
    };
}

namespace winrt::ScratchPad::factory_implementation
{
    struct MainWindow : MainWindowT<MainWindow, implementation::MainWindow>
    {
    };
}
