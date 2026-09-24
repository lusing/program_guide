#include "pch.h"
#include "MainWindow.xaml.h"

#include <algorithm>

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::DataExplorer::implementation
{
    MainWindow::MainWindow()
    {
        InitializeComponent();
        Title(L"Data Explorer");
        // 自定位：构造期挪到 (30,30) 并压到完整在屏内（级联出屏会吃注入点击）
        if (auto appWindow = AppWindow())
        {
            // AppWindow 的 MoveAndResize 实测按逻辑单位解释（30→53、1080→1890）：
            // 传 1000x620 逻辑 = 1750x1085 物理，构造期自定位 + 完整在屏
            appWindow.MoveAndResize(Windows::Graphics::RectInt32{ 30, 30, 1000, 620 });
        }
        m_all = FilesStore::All();
        m_view = single_threaded_observable_vector<winrt::DataExplorer::FileItem>();
        ApplyFilters();
    }

    void MainWindow::ApplyFilters()
    {
        if (!m_all) { return; }
        // 类别 + 名称子串双过滤，结果同时喂给列表/卡片/详情三视图
        std::wstring_view query{ m_query };
        for (auto const& item : m_all)
        {
            bool categoryOk = m_category == L"All" || item.Category() == m_category;
            if (!categoryOk) { continue; }
            if (!query.empty())
            {
                std::wstring_view name{ item.Name() };
                if (name.find(query) == std::wstring_view::npos) { continue; }
            }
            m_view.Append(item);
        }
        Table().ItemsSource(m_view);
        Cards().ItemsSource(m_view);
        Details().ItemsSource(m_view);
        CountText().Text(to_hstring(m_view.Size()) + L" items · " + m_category
            + (query.empty() ? L"" : L" · '" + m_query + L"'"));
    }

    void MainWindow::OnCategoryInvoked(TreeView const&, TreeViewItemInvokedEventArgs const& args)
    {
        // 19 章：TreeView 的 ItemInvoked 载荷是 TreeViewItem 或节点本身
        if (auto item = args.InvokedItem().try_as<TreeViewItem>())
        {
            m_category = unbox_value<hstring>(item.Content());
        }
        else if (auto node = args.InvokedItem().try_as<TreeViewNode>())
        {
            m_category = unbox_value<hstring>(node.Content());
        }
        m_view.Clear();
        ApplyFilters();
    }

    void MainWindow::OnFilterChanged(IInspectable const&, TextChangedEventArgs const&)
    {
        if (!m_all) { return; }
        m_query = FilterBox().Text();
        m_view.Clear();
        ApplyFilters();
    }

    void MainWindow::OnCardsToggled(IInspectable const&, RoutedEventArgs const&)
    {
        // 17↔18 章切换：两套控件共用数据源，折叠/展开即可
        m_cards = CardsToggle().IsChecked().Value();
        Table().Visibility(m_cards ? Visibility::Collapsed : Visibility::Visible);
        Cards().Visibility(m_cards ? Visibility::Visible : Visibility::Collapsed);
    }

    void MainWindow::SelectDetail(winrt::DataExplorer::FileItem const& item)
    {
        // 选中行 → 详情条翻到同一条（防重入：FlipView 反向通知会再进这里）
        if (m_syncing || !item) { return; }
        m_syncing = true;
        uint32_t index = 0;
        if (m_view.IndexOf(item, index))
        {
            Details().SelectedIndex(static_cast<int32_t>(index));
        }
        m_syncing = false;
    }

    void MainWindow::OnRowSelected(IInspectable const&, SelectionChangedEventArgs const& args)
    {
        // Clear/过滤会触发空 AddedItems 的 SelectionChanged：先查尺寸再取
        if (args.AddedItems().Size() == 0) { return; }
        if (auto item = args.AddedItems().GetAt(0).try_as<winrt::DataExplorer::FileItem>())
        {
            SelectDetail(item);
        }
    }

    void MainWindow::OnCardSelected(IInspectable const&, SelectionChangedEventArgs const& args)
    {
        if (args.AddedItems().Size() == 0) { return; }
        if (auto item = args.AddedItems().GetAt(0).try_as<winrt::DataExplorer::FileItem>())
        {
            SelectDetail(item);
        }
    }

    void MainWindow::OnDetailChanged(IInspectable const&, SelectionChangedEventArgs const& args)
    {
        // 20 章：FlipView 翻页也把表格选中同步过来（双向）
        if (m_syncing) { return; }
        if (args.AddedItems().Size() == 0) { return; }
        if (auto item = args.AddedItems().GetAt(0).try_as<winrt::DataExplorer::FileItem>())
        {
            m_syncing = true;
            uint32_t index = 0;
            if (m_view.IndexOf(item, index))
            {
                Table().SelectedIndex(static_cast<int32_t>(index));
                Cards().SelectedIndex(static_cast<int32_t>(index));
                Table().ScrollIntoView(item);
            }
            m_syncing = false;
        }
    }
}
