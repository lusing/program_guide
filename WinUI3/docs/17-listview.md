# 17. ListView：集合展示主线

上一篇：[16 日期与时间族](./16-datetime.md) ｜ 下一篇：[18 GridView 与 FlipView](./18-gridview-flipview.md)

ListView 是集合控件的基准形态—— GridView、FlipView、ComboBox 的下拉、TreeView 的列表部分都建立在同一套 ItemsControl 机制上。本章把这套机制讲透：项从哪来、怎么长、怎么选、怎么点。示例来自画廊工程 `examples/17-controls-collections/` 的 `ListViewPage`（导航 **ListView** 项）。

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

## 17.8 小结

| 环节 | API |
|------|-----|
| 少量项 | `Items().Append(box_value(...))` |
| 数据项 | `ItemsSource(WinRT 集合)` |
| 项外观 | `ItemTemplate` + `{Binding}` |
| 选择 | `SelectionMode` + `SelectedItem`（判空+unbox）/ `SelectedIndex` |
| 点击即动作 | `IsItemClickEnabled` + `ItemClick` |
| 增删 | `ItemCollection.Append/RemoveAt` |

画廊 `ListViewPage` 运行时证据：`.smoke/17-controls-collections/listview/click-2.png`——点击 banana 项，状态行 **"selected = banana"**，项高亮。

---

上一篇：[16 日期与时间族](./16-datetime.md) ｜ 下一篇：[18 GridView 与 FlipView](./18-gridview-flipview.md) ｜ 返回 [目录](../README.md)
