# 17. ListView：集合展示主线

上一篇：[16 日期与时间族](./16-datetime.md) ｜ 下一篇：[18 GridView 与 FlipView](./18-gridview-flipview.md)

ListView 是集合控件的基准形态—— GridView、FlipView、ComboBox 的下拉、TreeView 的列表部分都建立在同一套 ItemsControl 机制上。本章把这套机制讲透：项从哪来、怎么长、怎么选、怎么点。示例代码来自功能工程 `examples/17-data-explorer/`（数据浏览器：分类树、双视图、名称过滤、详情轮播）。

## 17.1 ItemsControl 的三层结构

```text
ListView
├── Items / ItemsSource   项从哪来（本章 17.2）
├── ItemTemplate          每项长什么样（17.3）
└── ItemsPanel            项怎么排（默认 ItemsStackPanel，纵向虚拟化；18 章换面板变 GridView）
```

选择/点击语义（SelectionMode / SelectionChanged / ItemClick）在最外层——所以换面板、换模板都不影响"选"的行为。

## 17.2 喂项：Items 与 ItemsSource

```cpp
ListViewPage::ListViewPage()
{
    InitializeComponent();
    for (auto const& fruit : { L"apple", L"banana", L"cherry", L"durian", L"elderberry" })
    {
        FruitList().Items().Append(box_value(fruit));
    }
    m_items = FruitList().Items();
}
```

两条路线：

- **`Items()`（本页）**：控件自己的 `ItemCollection`，逐个 Append。静态/少量项最直接；增删直接对它操作（本页 Add/Remove 按钮）。**项必须是装箱的 WinRT 值**——`box_value(hstring)`，塞裸 `wchar_t const*` 不行。
- **`ItemsSource()`**：绑一个 WinRT 集合（`IVector<IInspectable>` / `IObservableVector<T>`）。数据在 ViewModel/Service 里的正经路线（32 章的 MVVM 工程全程用一个可观察集合）；**std::vector 不行**——绑定引擎只认 WinRT 集合接口，这是 README 错误速查表的老条目。

替换整个 ItemsSource 对象是合法操作（数据刷新），但**选中状态会清零**——回到 -1/nullptr，需要的话自己记下 SelectedIndex 再恢复。

## 17.3 每项长什么样：ItemTemplate 与 {Binding}

```xml
<ListView x:Name="FruitList" Height="260" SelectionMode="Single"
          SelectionChanged="OnFruitSelectionChanged">
    <ListView.ItemTemplate>
        <DataTemplate x:DataType="x:String">
            <TextBlock Text="{Binding}" FontSize="16" Margin="8,6"/>
        </DataTemplate>
    </ListView.ItemTemplate>
</ListView>
```

模板里的 `{Binding}`（无路径）= 项本身。这里做一次 03 章概念的落地：**DataTemplate 内部用运行期 `{Binding}`，不是 `x:Bind`**——x:Bind 编译期解析需要页面对应的成员路径，而模板的内容每项才实例化，绑的是"项"这个上下文；x:Bind 在模板里要用 `x:DataType` + 绑定项属性（32 章给 ViewModel 的场景）。简单记：**模板里绑项 → `{Binding}`；页面里绑成员 → `x:Bind`**。

模板可以是任意 UIElement 树（18 章的卡片、20 章的多列行都是）。

## 17.4 选择与点击：两套互斥语义

```cpp
void ListViewPage::OnFruitSelectionChanged(IInspectable const&,
    SelectionChangedEventArgs const&)
{
    if (!FruitList() || !StatusText()) return;
    if (auto item = FruitList().SelectedItem())
    {
        StatusText().Text(L"selected = " + unbox_value<hstring>(item));
    }
}
```

- **`SelectionMode`**：`Single`（默认）/ `Multiple`（多选，配合 `SelectedItems` 集合）/ `Extended`（Ctrl/Shift 多选）/ `None`（不可选，纯列表）。
- **`SelectionChanged`**：args 带 `AddedItems`/`RemovedItems`（IVector\<IInspectable\>），多选模式下靠它增量更新；单选直接读 `SelectedItem()`（判空）或 `SelectedIndex()`。
- **`IsItemClickEnabled="True"` + `ItemClick`**：点击即动作（打开文件、跳转详情），与选择语义**互斥**——开了 ItemClick，点按不再改选中。选"点开"还是"选中后按按钮操作"是交互设计决策，别两个都开。

**SelectedItem 仍是装箱对象**（14 章同款）：`unbox_value<hstring>` 解包。

## 17.5 虚拟化与容器回收

ListView 默认面板 `ItemsStackPanel` 开虚拟化：可视区外的项**不生成 UI**，滚动时容器循环复用。两个实践推论：

1. **大数据量直接上**——十万项的字符串列表照常滚动，因为真实 UIElement 只有可视区那十几个。
2. **容器里的状态是临时的**——你在某行的控件上设的状态（比如行内展开），滚动回来可能没了（容器被回收复用）。**业务状态放数据模型，不放容器**；32 章的可观察属性是正解。

## 17.6 增删：对 Items() 的直接操作

```cpp
void ListViewPage::OnAddClicked(IInspectable const&, RoutedEventArgs const&)
{
    if (!m_items) return;
    m_items.Append(box_value(L"fig " + to_hstring(m_items.Size())));
    StatusText().Text(L"items = " + to_hstring(m_items.Size()));
}
```

`ItemCollection` 自带变更通知，Append/RemoveAt 即时反映到界面（这也是它比裸 vector 强的原因——它实现了 INotifyCollectionChanged）。注意**删选中项**的时序：删除后 SelectionChanged 会再触发一次（选中被清），handler 判空分支要能接住。

## 17.7 实测坑位

1. **std::vector 直塞 ItemsSource**：绑定引擎不认，用 `single_threaded_vector` 或 `ItemCollection`。
2. **裸字符串 Append**：必须 `box_value`；取回 `unbox_value`（装箱机制的第三、四次出场，和 ComboBox/RadioButton 一脉相承）。
3. **替换 ItemsSource 丢选中**（17.2）。
4. **容器回收丢状态**（17.5）——状态进数据模型。
5. **SelectionChanged 解析期触发**：12.5 的通用坑；handler 第一行判空控件。
6. **ItemClick 与选择互斥**：开了 IsItemClickEnabled 点按不再选。

## 17.6 实战：一张真表格（数据浏览器）

### 17.6.1 数据模型先行：FileItem runtimeclass

x:Bind 的模板需要投影类型——集合控件的真实工程从 IDL 开始：

```idl
runtimeclass FileItem
{
    FileItem(String name, String kind, String size, String date, String category);
    String Name;
    String Kind;
    String Size;
    String Date;
    String Category;
}
```

**格式化前置到构造期**（"3.4 MB"、"2026-08-14" 存好字符串）——模板里只做展示，不做单位换算。列宽、排序、过滤这些"表格逻辑"全部发生在 UI 之外。

### 17.6.2 四列表格 = 同栅格的表头 + 行模板

```xml
<!-- 表头 -->
<Grid Padding="12,0">
    <Grid.ColumnDefinitions>
        <ColumnDefinition Width="2*"/><ColumnDefinition Width="*"/>
        <ColumnDefinition Width="*"/><ColumnDefinition Width="*"/>
    </Grid.ColumnDefinitions>
    <TextBlock Grid.Column="0" Text="Name" FontWeight="SemiBold"/>
    ...
</Grid>

<!-- 行模板：与表头同栅格 -->
<ListView x:Name="Table" SelectionMode="Single" SelectionChanged="OnRowSelected">
    <ListView.ItemTemplate>
        <DataTemplate x:DataType="local:FileItem">
            <Grid Padding="12,6">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="2*"/><ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/><ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <TextBlock Grid.Column="0" Text="{x:Bind Name}"/>
                <TextBlock Grid.Column="1" Text="{x:Bind Kind}" Opacity="0.75"/>
                ...
            </Grid>
        </DataTemplate>
    </ListView.ItemTemplate>
</ListView>
```

**"自制表格"的全部秘密就是两份相同的 ColumnDefinitions**。代价要诚实：列宽是契约，两边改一边必歪；窗口缩放时 `2*:*:*:*` 按比例同步，但没有列拖拽（那要上 GridSplitter 或 ItemsRepeater 自绘，20 章）。

### 17.6.3 过滤管线：一个向量喂三个视图

```cpp
void MainWindow::ApplyFilters()
{
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
    Cards().ItemsSource(m_view);      // GridView 同源（18 章）
    Details().ItemsSource(m_view);    // FlipView 同源（20 章）
    CountText().Text(...);            // 计数行
}
```

**单一 m_view 是架构决策**：类别（TreeView）、子串（TextBox）两个输入归一到一个过滤函数，三个视图共享结果——列表、卡片、详情永远显示同一份数据，不存在"卡片视图忘了过滤"这种分叉 bug。

### 17.6.4 选中联动（与防重入）

```cpp
void MainWindow::OnRowSelected(IInspectable const&, SelectionChangedEventArgs const& args)
{
    // 坑：Clear/过滤会触发空 AddedItems 的 SelectionChanged，GetAt(0) 前必须查 Size
    if (args.AddedItems().Size() == 0) { return; }
    if (auto item = args.AddedItems().GetAt(0).try_as<winrt::DataExplorer::FileItem>())
    {
        SelectDetail(item);   // 翻 FlipView，内部有 m_syncing 防重入闸
    }
}
```

**空 AddedItems 是启动崩溃的来源**（实测）：`m_view.Clear()` 触发一次"没有新增项"的 SelectionChanged，直接 `GetAt(0)` 抛出 stowed exception。三个视图互相同步（列表选→详情翻；详情翻→列表选）共用一个 `m_syncing` 布尔闸——选中事件里的级联更新是重入的重灾区。

`.smoke/17-data-explorer/tree/tap-1.png`：TreeView 点 Images → 表格剩三行图像文件、计数行 "3 items · Images"——列表视图对过滤的全部响应，一帧可见。

### 17.6.5 选择模式三档的现实用法

| 模式 | 用法 | 设置中心/数据浏览器外的例子 |
|---|---|---|
| Single | 选中即详情 | 文件列表→预览 |
| Multiple | 勾选收集 | 批量下载选择 |
| Extended | 单选+Ctrl 多选+Shift 范围 | 资源管理器 |

**Multiple 与 CheckBox 的组合**：SelectionMode=Multiple 时 WinUI 自动给行加复选框（SelectionCheckMode）——不用自己做 ItemTemplate 塞 CheckBox。收集选中项：`SelectedItems()`（IVector<object>）——**不是 SelectedItem 的复数语法糖**，是独立集合，双向维护。Extended 模式的 Ctrl/Shift 处理内建，别自己拦键盘。

### 17.6.6 ContainerGeneration：行容器的坑与钱

ListView 行不是 DataTemplate 本体——外面裹着 ListViewItem（选择态、悬停、键盘焦点的宿主）。**ItemContainerStyle 改的是这层**（14 章密度实战）。两个坑：容器异步生成（`ContainerContentChanging` 事件能接住每个容器就位时机——图片懒加载的标准位）；`ItemsPanel` 换 StackPanel 为 ItemsStackGrid 时虚拟化语义跟着变（非虚拟化面板=全量生成=千行卡死）。

## 17.8 小结

| 环节 | API |
|------|-----|
| 少量项 | `Items().Append(box_value(...))` |
| 数据项 | `ItemsSource(WinRT 集合)` |
| 项外观 | `ItemTemplate` + `{Binding}` |
| 选择 | `SelectionMode` + `SelectedItem`（判空+unbox）/ `SelectedIndex` |
| 点击即动作 | `IsItemClickEnabled` + `ItemClick` |
| 增删 | `ItemCollection.Append/RemoveAt` |

运行时证据：`.smoke/17-data-explorer/tree/tap-1.png`——自制四列表格（Grid 列定义 + DataTemplate x:Bind）承载 10 条文件数据，TreeView 切到 Images 后列表只剩 3 条图像、计数行 **"3 items · Images"**。

---

上一篇：[16 日期与时间族](./16-datetime.md) ｜ 下一篇：[18 GridView 与 FlipView](./18-gridview-flipview.md) ｜ 返回 [目录](../README.md)
