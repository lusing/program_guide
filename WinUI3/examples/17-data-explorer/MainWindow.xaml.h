#pragma once
#include "MainWindow.g.h"

namespace winrt::DataExplorer::implementation
{
    struct MainWindow : MainWindowT<MainWindow>
    {
        MainWindow();

        void OnCategoryInvoked(Microsoft::UI::Xaml::Controls::TreeView const& sender,
            Microsoft::UI::Xaml::Controls::TreeViewItemInvokedEventArgs const& args);
        void OnFilterChanged(Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::TextChangedEventArgs const& args);
        void OnCardsToggled(Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnRowSelected(Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::SelectionChangedEventArgs const& args);
        void OnCardSelected(Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::SelectionChangedEventArgs const& args);
        void OnDetailChanged(Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::SelectionChangedEventArgs const& args);

    private:
        void ApplyFilters();
        void SelectDetail(winrt::DataExplorer::FileItem const& item);
        winrt::hstring m_category{ L"All" };
        winrt::hstring m_query;
        bool m_cards{ false };
        bool m_syncing{ false };   // 列表/卡片/详情三方同步的防重入闸

        Windows::Foundation::Collections::IVector<winrt::DataExplorer::FileItem> m_all{ nullptr };
        Windows::Foundation::Collections::IVector<winrt::DataExplorer::FileItem> m_view{ nullptr };
    };
}

namespace winrt::DataExplorer::factory_implementation
{
    struct MainWindow : MainWindowT<MainWindow, implementation::MainWindow>
    {
    };
}
