#!/usr/bin/env python3
"""Generates the four chapter pages (17-20) of the collections gallery."""
import io
import os

BASE = os.path.join(os.path.dirname(__file__), '..', 'examples', '17-controls-collections')
NS = 'CollectionsGallery'


def w(name, content):
    with io.open(os.path.join(BASE, name), 'w', encoding='utf-8', newline='\n') as f:
        f.write(content)


def idl(cls):
    return f'''namespace {NS}
{{
    [default_interface]
    runtimeclass {cls} : Microsoft.UI.Xaml.Controls.Page
    {{
        {cls}();
    }}
}}
'''


# ---------- ListViewPage ----------
w('ListViewPage.idl', idl('ListViewPage'))
w('ListViewPage.xaml', '''<Page
    x:Class="CollectionsGallery.ListViewPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <Grid Margin="24">
        <StackPanel Spacing="12" MaxWidth="480">
            <TextBlock x:Name="StatusText" Text="Ready" FontSize="18"/>

            <!-- 17.2 ItemsSource + DataTemplate({Binding} 运行期绑定) -->
            <ListView x:Name="FruitList" Height="260"
                      SelectionMode="Single"
                      SelectionChanged="OnFruitSelectionChanged">
                <ListView.ItemTemplate>
                    <DataTemplate x:DataType="x:String">
                        <TextBlock Text="{Binding}" FontSize="16" Margin="8,6"/>
                    </DataTemplate>
                </ListView.ItemTemplate>
            </ListView>

            <StackPanel Orientation="Horizontal" Spacing="12">
                <Button Content="Add item" Click="OnAddClicked"/>
                <Button Content="Remove selected" Click="OnRemoveClicked"/>
            </StackPanel>
        </StackPanel>
    </Grid>
</Page>
''')
w('ListViewPage.xaml.h', '''#pragma once
#include "ListViewPage.g.h"

namespace winrt::CollectionsGallery::implementation
{
    struct ListViewPage : ListViewPageT<ListViewPage>
    {
        ListViewPage();

        void OnFruitSelectionChanged(
            Windows::Foundation::IInspectable const& sender,
            Windows::UI::Xaml::Controls::SelectionChangedEventArgs const& args);
        void OnAddClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnRemoveClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);

    private:
        Windows::UI::Xaml::Controls::ItemCollection m_items{ nullptr };
    };
}

namespace winrt::CollectionsGallery::factory_implementation
{
    struct ListViewPage : ListViewPageT<ListViewPage, implementation::ListViewPage>
    {
    };
}
''')
w('ListViewPage.xaml.cpp', '''#include "pch.h"
#include "ListViewPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
namespace wux = winrt::Windows::UI::Xaml::Controls;

namespace winrt::CollectionsGallery::implementation
{
    ListViewPage::ListViewPage()
    {
        InitializeComponent();
        for (auto const& fruit : { L"apple", L"banana", L"cherry", L"durian", L"elderberry" })
        {
            FruitList().Items().Append(box_value(fruit));
        }
        m_items = FruitList().Items();
    }

    void ListViewPage::OnFruitSelectionChanged(IInspectable const&,
        wux::SelectionChangedEventArgs const&)
    {
        if (!FruitList() || !StatusText()) return;
        if (auto item = FruitList().SelectedItem())
        {
            StatusText().Text(L"selected = " + unbox_value<hstring>(item));
        }
    }

    void ListViewPage::OnAddClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!m_items) return;
        m_items.Append(box_value(L"fig " + to_hstring(m_items.Size())));
        StatusText().Text(L"items = " + to_hstring(m_items.Size()));
    }

    void ListViewPage::OnRemoveClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!m_items || !FruitList()) return;
        auto idx = FruitList().SelectedIndex();
        if (idx >= 0)
        {
            m_items.RemoveAt(static_cast<uint32_t>(idx));
            StatusText().Text(L"removed, items = " + to_hstring(m_items.Size()));
        }
    }
}
''')

# ---------- GridViewPage ----------
w('GridViewPage.idl', idl('GridViewPage'))
w('GridViewPage.xaml', '''<Page
    x:Class="CollectionsGallery.GridViewPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <Grid Margin="24">
        <StackPanel Spacing="12">
            <TextBlock x:Name="StatusText" Text="Ready" FontSize="18"/>

            <!-- 18.2 GridView：平铺卡片（同一份字符串数据） -->
            <GridView x:Name="CardGrid" Height="180"
                      SelectionChanged="OnCardSelectionChanged">
                <GridView.ItemTemplate>
                    <DataTemplate x:DataType="x:String">
                        <Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}"
                                BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"
                                BorderThickness="1" CornerRadius="8"
                                Padding="16" Width="120">
                            <TextBlock Text="{Binding}" FontWeight="SemiBold"/>
                        </Border>
                    </DataTemplate>
                </GridView.ItemTemplate>
            </GridView>

            <!-- 18.3 FlipView：单项翻页 -->
            <TextBlock Text="FlipView:" FontWeight="SemiBold"/>
            <StackPanel Orientation="Horizontal" Spacing="12">
                <FlipView x:Name="Pager" Width="260" Height="100"
                          SelectionChanged="OnFlipChanged">
                    <Border Background="#C42B1C"><TextBlock Text="page one" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
                    <Border Background="#1C6FC4"><TextBlock Text="page two" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
                    <Border Background="#2B8A3E"><TextBlock Text="page three" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
                </FlipView>
                <Button Content="Next" Click="OnNextClicked" VerticalAlignment="Center"/>
            </StackPanel>
        </StackPanel>
    </Grid>
</Page>
''')
w('GridViewPage.xaml.h', '''#pragma once
#include "GridViewPage.g.h"

namespace winrt::CollectionsGallery::implementation
{
    struct GridViewPage : GridViewPageT<GridViewPage>
    {
        GridViewPage();

        void OnCardSelectionChanged(
            Windows::Foundation::IInspectable const& sender,
            Windows::UI::Xaml::Controls::SelectionChangedEventArgs const& args);
        void OnFlipChanged(
            Windows::Foundation::IInspectable const& sender,
            Windows::UI::Xaml::Controls::SelectionChangedEventArgs const& args);
        void OnNextClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::CollectionsGallery::factory_implementation
{
    struct GridViewPage : GridViewPageT<GridViewPage, implementation::GridViewPage>
    {
    };
}
''')
w('GridViewPage.xaml.cpp', '''#include "pch.h"
#include "GridViewPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
namespace wux = winrt::Windows::UI::Xaml::Controls;

namespace winrt::CollectionsGallery::implementation
{
    GridViewPage::GridViewPage()
    {
        InitializeComponent();
        for (auto const& tag : { L"alpha", L"beta", L"gamma", L"delta", L"epsilon" })
        {
            CardGrid().Items().Append(box_value(tag));
        }
    }

    void GridViewPage::OnCardSelectionChanged(IInspectable const&,
        wux::SelectionChangedEventArgs const&)
    {
        if (!CardGrid() || !StatusText()) return;
        if (auto item = CardGrid().SelectedItem())
        {
            StatusText().Text(L"card = " + unbox_value<hstring>(item));
        }
    }

    void GridViewPage::OnFlipChanged(IInspectable const&,
        wux::SelectionChangedEventArgs const&)
    {
        if (!Pager() || !StatusText()) return;
        StatusText().Text(L"flip page = " + to_hstring(Pager().SelectedIndex() + 1));
    }

    void GridViewPage::OnNextClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!Pager()) return;
        int next = Pager().SelectedIndex() + 1;
        if (next >= static_cast<int>(Pager().Items().Size())) next = 0;
        Pager().SelectedIndex(next);
    }
}
''')

# ---------- TreeViewPage ----------
w('TreeViewPage.idl', idl('TreeViewPage'))
w('TreeViewPage.xaml', '''<Page
    x:Class="CollectionsGallery.TreeViewPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <Grid Margin="24">
        <StackPanel Spacing="12" MaxWidth="480">
            <TextBlock x:Name="StatusText" Text="Ready" FontSize="18"/>

            <!-- 19.2 TreeViewNode 模型：程序化建树 -->
            <TreeView x:Name="DirTree" Height="300"
                      ItemInvoked="OnNodeInvoked"/>

            <Button Content="Expand all" Click="OnExpandAllClicked"/>
        </StackPanel>
    </Grid>
</Page>
''')
w('TreeViewPage.xaml.h', '''#pragma once
#include "TreeViewPage.g.h"

namespace winrt::CollectionsGallery::implementation
{
    struct TreeViewPage : TreeViewPageT<TreeViewPage>
    {
        TreeViewPage();

        void OnNodeInvoked(
            Windows::Foundation::IInspectable const& sender,
            Windows::UI::Xaml::Controls::TreeViewItemInvokedEventArgs const& args);
        void OnExpandAllClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);

    private:
        void ExpandRecursively(winrt::Windows::UI::Xaml::Controls::TreeViewNode const& node, int& count);
    };
}

namespace winrt::CollectionsGallery::factory_implementation
{
    struct TreeViewPage : TreeViewPageT<TreeViewPage, implementation::TreeViewPage>
    {
    };
}
''')
w('TreeViewPage.xaml.cpp', '''#include "pch.h"
#include "TreeViewPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
namespace wux = winrt::Windows::UI::Xaml::Controls;

namespace winrt::CollectionsGallery::implementation
{
    TreeViewPage::TreeViewPage()
    {
        InitializeComponent();
        // 三根两子的小树
        auto make_child = [](hstring const& name)
        {
            wux::TreeViewNode c;
            c.Content(box_value(name));
            return c;
        };
        for (auto const& root : { L"src", L"docs", L"examples" })
        {
            wux::TreeViewNode node;
            node.Content(box_value(root));
            node.Children().Append(make_child(root + L"/a"));
            node.Children().Append(make_child(root + L"/b"));
            DirTree().RootNodes().Append(node);
        }
    }

    void TreeViewPage::OnNodeInvoked(IInspectable const&,
        wux::TreeViewItemInvokedEventArgs const& args)
    {
        if (!StatusText()) return;
        // ItemInvoked 的项在 InvokedItem()，是 TreeViewNode
        auto node = args.InvokedItem().as<wux::TreeViewNode>();
        if (auto content = node.Content())
        {
            StatusText().Text(L"node = " + unbox_value<hstring>(content));
        }
    }

    void TreeViewPage::OnExpandAllClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!DirTree()) return;
        int count = 0;
        for (auto const& node : DirTree().RootNodes())
        {
            ExpandRecursively(node, count);
        }
        StatusText().Text(L"expanded " + to_hstring(count) + L" nodes");
    }

    void TreeViewPage::ExpandRecursively(wux::TreeViewNode const& node, int& count)
    {
        node.IsExpanded(true);
        ++count;
        for (auto const& child : node.Children())
        {
            ExpandRecursively(child, count);
        }
    }
}
''')

# ---------- TablePage (ch20) ----------
w('TablePage.idl', idl('TablePage'))
w('TablePage.xaml', '''<Page
    x:Class="CollectionsGallery.TablePage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <Grid Margin="24">
        <StackPanel Spacing="12">
            <TextBlock x:Name="StatusText" Text="Ready" FontSize="18"/>

            <!-- 20.3 自制表格：Grid 表头 + ListView 行（C++/WinRT 没有 Toolkit DataGrid） -->
            <Grid ColumnDefinitions="2*,1*,1*" MaxWidth="560">
                <TextBlock Text="Name" FontWeight="SemiBold" Padding="8,6"/>
                <TextBlock Grid.Column="1" Text="Priority" FontWeight="SemiBold" Padding="8,6"/>
                <TextBlock Grid.Column="2" Text="Done" FontWeight="SemiBold" Padding="8,6"/>
            </Grid>
            <ListView x:Name="TaskTable" MaxWidth="560" SelectionChanged="OnRowSelected">
                <ListView.ItemTemplate>
                    <DataTemplate x:DataType="x:String">
                        <Grid ColumnDefinitions="2*,1*,1*" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}">
                            <TextBlock Text="{Binding}" Padding="8,6"/>
                            <TextBlock Grid.Column="1" Text="P2" Padding="8,6"/>
                            <TextBlock Grid.Column="2" Text="no" Padding="8,6"/>
                        </Grid>
                    </DataTemplate>
                </ListView.ItemTemplate>
            </ListView>

            <!-- 20.4 ItemsRepeater + UniformGridLayout：高性能平铺 -->
            <TextBlock Text="ItemsRepeater (UniformGridLayout):" FontWeight="SemiBold"/>
            <ItemsRepeater x:Name="TileRepeater" MaxWidth="560">
                <ItemsRepeater.Layout>
                    <UniformGridLayout MinItemWidth="90" MinItemHeight="40" MinRowSpacing="8" MinColumnSpacing="8"/>
                </ItemsRepeater.Layout>
                <ItemsRepeater.ItemTemplate>
                    <DataTemplate x:DataType="x:String">
                        <Border Background="{ThemeResource AccentFillColorDefaultBrush}" CornerRadius="6">
                            <TextBlock Text="{Binding}" Foreground="White" Padding="10" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </DataTemplate>
                </ItemsRepeater.ItemTemplate>
            </ItemsRepeater>
        </StackPanel>
    </Grid>
</Page>
''')
w('TablePage.xaml.h', '''#pragma once
#include "TablePage.g.h"

namespace winrt::CollectionsGallery::implementation
{
    struct TablePage : TablePageT<TablePage>
    {
        TablePage();

        void OnRowSelected(
            Windows::Foundation::IInspectable const& sender,
            Windows::UI::Xaml::Controls::SelectionChangedEventArgs const& args);
    };
}

namespace winrt::CollectionsGallery::factory_implementation
{
    struct TablePage : TablePageT<TablePage, implementation::TablePage>
    {
    };
}
''')
w('TablePage.xaml.cpp', '''#include "pch.h"
#include "TablePage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
namespace wux = winrt::Windows::UI::Xaml::Controls;

namespace winrt::CollectionsGallery::implementation
{
    TablePage::TablePage()
    {
        InitializeComponent();
        for (auto const& name : { L"write guide", L"run smoke", L"fix bug", L"ship it" })
        {
            TaskTable().Items().Append(box_value(name));
        }
        auto tiles = single_threaded_vector<IInspectable>();
        for (int i = 1; i <= 8; ++i) tiles.Append(box_value(L"T" + to_hstring(i)));
        TileRepeater().ItemsSource(tiles);
    }

    void TablePage::OnRowSelected(IInspectable const&,
        wux::SelectionChangedEventArgs const&)
    {
        if (!TaskTable() || !StatusText()) return;
        if (auto item = TaskTable().SelectedItem())
        {
            StatusText().Text(L"row = " + unbox_value<hstring>(item));
        }
    }
}
''')

print('4 pages written')
