# 18. GridView 与 FlipView

上一篇：[17 ListView](./17-listview.md) ｜ 下一篇：[19 TreeView](./19-treeview.md)

17 章说 GridView 和 ListView 共享 ItemsControl 机制——本章兑现这句话：换一个属性（ItemsPanel），列表变平铺。FlipView 则是同一机制的"一次只看一项"特化。示例来自画廊工程的 `GridViewPage`（导航 **GridView** 项）。

## 18.1 GridView = ListView 换默认面板

对照两页代码你会发现：喂项的循环、SelectionChanged 的解包，与 ListViewPage **逐字相同**。差异只有两处：

```xml
<GridView x:Name="CardGrid" Height="180" SelectionChanged="OnCardSelectionChanged">
    <GridView.ItemTemplate>
        <DataTemplate x:DataType="x:String">
            <Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}"
                    BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"
                    BorderThickness="1" CornerRadius="8" Padding="16" Width="120">
                <TextBlock Text="{Binding}" FontWeight="SemiBold"/>
            </Border>
        </DataTemplate>
    </GridView.ItemTemplate>
</GridView>
```

1. **默认 ItemsPanel**：ListView 默认 `ItemsStackPanel`（纵向堆叠），GridView 默认 `ItemsWrapGrid`（横向流式换行）。**这就是两个控件的全部本质差异**——Selector 家族的共有语义（选择/点击/模板/虚拟化）一个不差。
2. **模板更"卡片"**：平铺场景项有固有宽度（Width=120），卡片背景/圆角用主题资源（33 章）而不是硬编码颜色。

想反向证明？给 ListView 显式设 `ItemsPanel=ItemsWrapGrid`，它就"变成"了 GridView——控件名只是默认面板的糖。什么时候用哪个：**纵向清单用 ListView，图墙/卡片流用 GridView**，用户对两种形态有滚动方向的肌肉记忆。

```cpp
// 与 ListViewPage 完全同构的选择处理
void GridViewPage::OnCardSelectionChanged(IInspectable const&,
    SelectionChangedEventArgs const&)
{
    if (!CardGrid() || !StatusText()) return;
    if (auto item = CardGrid().SelectedItem())
    {
        StatusText().Text(L"card = " + unbox_value<hstring>(item));
    }
}
```

## 18.2 FlipView：一次一项的翻页器

```xml
<FlipView x:Name="Pager" Width="260" Height="100" SelectionChanged="OnFlipChanged">
    <Border Background="#C42B1C"><TextBlock Text="page one" .../></Border>
    <Border Background="#1C6FC4"><TextBlock Text="page two" .../></Border>
    <Border Background="#2B8A3E"><TextBlock Text="page three" .../></Border>
</FlipView>
```

FlipView 也是 Selector：项集合、模板、`SelectedIndex`/`SelectionChanged` 全套都有——只是它**只显示当前选中项**，翻页 = 改选中。用户交互：两侧的小箭头、触摸滑动、键盘左右。

```cpp
void GridViewPage::OnNextClicked(IInspectable const&, RoutedEventArgs const&)
{
    if (!Pager()) return;
    int next = Pager().SelectedIndex() + 1;
    if (next >= static_cast<int>(Pager().Items().Size())) next = 0;   // 循环
    Pager().SelectedIndex(next);   // 程序化翻页，事件照常触发
}
```

典型场景：引导页（onboarding）、图片查看器、分步向导。**向导每步要阻止后退/强校验**时 FlipView 的自由翻页反而碍事——那时用 ContentDialog + 步进按钮（24 章）自己控制流程更稳。

## 18.3 命名空间注意

ListView/GridView/FlipView 都在 `Microsoft.UI.Xaml.Controls`（WinUI 3 的投影命名空间），**不是** UWP 的 `Windows.UI.Xaml.Controls`。写 `using namespace` 时敲错前缀，报出来的是一片 C2039/C2065 而不指向真因——这是从 UWP 资料抄代码时的第一坑（本页开发时实测：TreeViewNode 等 1.8 全部位于 `Microsoft.UI`，网上大量示例还停在 `Windows.UI`）。

## 18.4 实测坑位

1. **GridView 卡片不设固有宽**：平铺面板不知道项多宽，会拉伸到面板宽。模板根元素给 Width（或 MinWidth）。
2. **FlipView 项直接放 UIElement**：少量静态页可以（本页）；数据多页用 ItemsSource + 模板。
3. **UWP 命名空间残留**（18.3）。
4. **GridView 里放可交互项**（卡片里有按钮）：点击被项选择吞掉的场景，用 `IsItemClickEnabled` 或在卡片按钮上处理冒泡。

## 18.5 小结

| 控件 | 一句话 | 关键差异 |
|------|--------|---------|
| ListView | 纵向清单 | 默认 ItemsStackPanel |
| GridView | 卡片平铺 | 默认 ItemsWrapGrid + 项固有宽 |
| FlipView | 翻页器 | 只显示当前项，翻页=改 SelectedIndex |

画廊 `GridViewPage` 运行时证据：`.smoke/17-controls-collections/gridview/click-2.png`——点击 Next，状态行 **"flip page = 2"**，FlipView 切到蓝色 page two。

---

上一篇：[17 ListView](./17-listview.md) ｜ 下一篇：[19 TreeView](./19-treeview.md) ｜ 返回 [目录](../README.md)
