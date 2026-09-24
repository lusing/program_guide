# 18. GridView 与 FlipView

上一篇：[17 ListView](./17-listview.md) ｜ 下一篇：[19 TreeView](./19-treeview.md)

17 章说 GridView 和 ListView 共享 ItemsControl 机制——本章兑现这句话：换一个属性（ItemsPanel），列表变平铺。FlipView 则是同一机制的"一次只看一项"特化。示例代码来自功能工程 `examples/17-data-explorer/`（数据浏览器：分类树、双视图、名称过滤、详情轮播）。

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

## 18.5 实战：一份数据两张脸（数据浏览器）

### 18.5.1 双视图共用一个 ItemsSource

```cpp
m_view = single_threaded_observable_vector<winrt::DataExplorer::FileItem>();
...
Table().ItemsSource(m_view);   // ListView：表格
Cards().ItemsSource(m_view);   // GridView：卡片
```

切换是**可见性互换**，不是数据搬运：

```cpp
void MainWindow::OnCardsToggled(IInspectable const&, RoutedEventArgs const&)
{
    m_cards = CardsToggle().IsChecked().Value();
    Table().Visibility(m_cards ? Visibility::Collapsed : Visibility::Visible);
    Cards().Visibility(m_cards ? Visibility::Visible : Visibility::Collapsed);
}
```

为什么不销毁重建？两个理由：**选中状态在控件里**——重建即丢失，用户切到卡片视图又得重新找刚才那一行；**ItemsSource 共享**意味着数据层对"现在是哪个视图"零感知，加第三种视图（如平铺缩略图）只是再加一个控件、再接同一份 m_view。

### 18.5.2 GridView 的卡片模板

```xml
<GridView x:Name="Cards" Visibility="Collapsed" SelectionMode="Single"
          SelectionChanged="OnCardSelected">
    <GridView.ItemTemplate>
        <DataTemplate x:DataType="local:FileItem">
            <StackPanel Width="180" Padding="12" Spacing="4"
                        Background="{ThemeResource CardBackgroundFillColorDefaultBrush}"
                        BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"
                        BorderThickness="1" CornerRadius="8">
                <TextBlock Text="{x:Bind Name}" FontWeight="SemiBold"
                           TextTrimming="CharacterEllipsis"/>
                <TextBlock Text="{x:Bind Kind}" Opacity="0.7"/>
                <TextBlock Text="{x:Bind Size}" Opacity="0.7"/>
            </StackPanel>
        </DataTemplate>
    </GridView.ItemTemplate>
</GridView>
```

**卡片视觉靠 ThemeResource 拼**（CardBackground/CardStroke 是 WinUI 的卡片体系色），不写死颜色——亮暗主题自动适配。`TextTrimming="CharacterEllipsis"` 是文件名这类变长字段的标配：溢出截断优于撑破卡片或换行破坏三行式。`Width="180"` 定宽让 GridView 的自适应换行（默认 ItemsPanel 是 ItemsWrapGrid）排得整齐——卡片流与表格流的信息密度差，正是双视图存在的理由。

### 18.5.3 FlipView：同一数据的"一次一项"

详情条是 FlipView 承载的第三张脸：

```cpp
void MainWindow::SelectDetail(winrt::DataExplorer::FileItem const& item)
{
    if (m_syncing || !item) { return; }
    m_syncing = true;
    uint32_t index = 0;
    if (m_view.IndexOf(item, index))
    {
        Details().SelectedIndex(static_cast<int32_t>(index));
    }
    m_syncing = false;
}
```

**FlipView 的 SelectedIndex 与 ListView 的选中是同一 index 空间**（同源 m_view）——这是"列表点一行、详情翻一页"的全部实现。反向同步（翻详情条时让列表跟选）在 `OnDetailChanged` 里对偶实现，`Table().ScrollIntoView(item)` 顺手把滚走的行拉回视野。**`ScrollIntoView` 是 Selector 系的公开方法，FlipView 没有**（实测 C2039）——轮播视图不需要滚动到某项，它就是那一项。

**何时用 FlipView**：数据有"逐项细看"的节奏（图片轮播、章节阅读、本例的文件详情）。它与 ListView 不是竞争是分工——同一集合，浏览用列表、细读用 FlipView，中缝靠 SelectionChanged 双向缝合。

### 18.5.4 GridView 的选择边框与拖拽

GridView 项默认带选中勾选框格（SelectionCheckMarkMode）与拖拽重排（CanReorderItems）——后者是 GridView 比 ListView 多的内置交互，做看板/收藏夹时白拿。数据浏览器关了重排（默认关）——**可重排=可持久化顺序**，开了就要接 DragItemsCompleted 写回存储，半吊子的拖拽比没有更坑。

### 18.5.5 空态：过滤器把一切滤光时

子串过滤可能让 m_view 清空——ListView 显示空白（没有内建空态模板）。产品化补法：叠一个 `TextBlock x:Name="EmptyHint" Visibility="Collapsed"`，ApplyFilters 里 `m_view.Size()==0` 时 Visible（"No files match 'xyz' in Images"）。设置中心同款问题（搜索无建议时下拉自动收起，天然安全）。**空态是过滤类 UI 的义务**——白屏让用户怀疑是 bug 还是没结果，一句文案就能说清。

### 18.5.6 卡片的选中态与点击区

GridView 的选中视觉（描边+勾）由 ItemContainer（GridViewItem）承担——卡片模板里的 Border 描边是**内容自己的边**，与选中描边是两层。别在模板里模仿选中态（重复且不同步）；**点击区=整张卡片**（容器级命中），StackPanel 留白也是可点区——手指友好。要"只点图片才选中"的精确语义，得在模板里放 Button 吃点击再代码选中（罕见需求，别自找）。

### 18.5.7 FlipView 的翻页按钮与手势

FlipView 内建左右箭头 + 触屏滑动 + （键盘）PgUp/PgDn——三套翻页免费。箭头按钮的 AutomationProperties 自动带（"下一页/上一页"）。**数据不足两条时**箭头自动隐藏（一条数据时 FlipView 仍显示，只是没得翻）。循环翻页（末页→首页）不内建：监听 SelectionChanged，index 到头尾时 SelectedIndex 跳回——慎用，用户常把循环当 bug（"怎么又回来了"）。

### 18.5.8 SemanticZoom：列表的 ABC 跳转

集合控件的第三件少有人知的能力：`SemanticZoom` 包两个视图（ZoomedInView 正常列表 + ZoomedOutView 缩略/分组索引），捏合手势（或 `-` 按键）切换——通讯录按字母跳转的标准形态。ListView/GridView 都能当内层。数据浏览器十项数据用不着；文件过千的"按类型分组+跳转"就是它的主场。**C++/WinRT 的实现注意**：两个视图各自 ItemsSource 同源，分组用 `CollectionViewSource`（IsSourceGrouped）——32 章集合视图的预告。

## 18.6 练习与思考

1. 双视图切换时保持滚动位置：ListView 的 ScrollIntoView vs 手动记录 ScrollViewer 偏移——GridView 的对应物是什么？
2. 给卡片加右键 ContextFlyout（23.5.6）：Open/ Delete 两项。处理器怎么知道右键的是哪个 FileItem？（提示：FlyoutItem 的 DataContext）
3. FlipView 循环翻页（18.5.7 的慎用项）：实现它，然后找一个"用户会把它当 bug"的具体场景写成注释。

### 18.5.9 卡片的自适应尺寸

固定 Width=180 的卡片在超窄窗口挤成三列变一列浪费横向——进阶用 `ItemsWrapGrid` 的 ItemWidth + 窗口宽算列数，或上 20 章的 UniformGridLayout（MinItemWidth 自动适配列数）。**GridView 默认面板（ItemsWrapGrid）的 GridCellSize 布局**：所有卡同一格——高度不齐的卡（文本行数不同）要么统一 MinHeight（整整齐齐）要么上 VariableSizedWrapGrid（复杂）。卡片流的"整齐"几乎总是对的——用户扫的是网格不是内容。

## 18.7 上生产前的审查清单

- [ ] 卡片定宽与列数策略在窄窗下验证过
- [ ] 变长字段有截断（TextTrimming）不撑破卡片
- [ ] 选中态用容器内建，不在模板里手搓
- [ ] 空态有提示（18.5.5）
- [ ] FlipView 与列表的选中同步有防重入闸

## 18.5 小结

| 控件 | 一句话 | 关键差异 |
|------|--------|---------|
| ListView | 纵向清单 | 默认 ItemsStackPanel |
| GridView | 卡片平铺 | 默认 ItemsWrapGrid + 项固有宽 |
| FlipView | 翻页器 | 只显示当前项，翻页=改 SelectedIndex |

DataExplorer 的 Table（ListView）与 Cards（GridView）共用同一份 `m_view` 数据源，ToggleButton 一键互换 Visibility；Details 是 FlipView 详情条，列表选中与翻页双向同步（防重入闸 m_syncing）。运行时证据：`.smoke/17-data-explorer/cards/tap-1.png`（切换瞬间同帧可见）。

---

上一篇：[17 ListView](./17-listview.md) ｜ 下一篇：[19 TreeView](./19-treeview.md) ｜ 返回 [目录](../README.md)
