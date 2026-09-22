# 21. TabView 与 Expander

上一篇：[20 表格数据](./20-datagrid-itemsrepeater.md) ｜ 下一篇：[22 NavigationView 与 SplitView](./22-navigationview.md)

文档型界面（编辑器、浏览器、设置页）的骨架是 `TabView`；把一屏长表单收拢成"按需展开"用 `Expander`。示例来自画廊工程 `examples/21-controls-shell/` 的 `TabViewPage`（导航 **TabView** 项）。

## 21.1 TabView：页签容器

```xml
<TabView x:Name="Docs" Height="180"
         SelectionChanged="OnTabSelectionChanged"
         TabCloseRequested="OnTabCloseRequested"
         AddTabButtonClick="OnAddTabClicked">
    <TabView.TabItems>
        <TabViewItem Header="guide.md" IsClosable="False"/>
        <TabViewItem Header="notes.md"/>
        <TabViewItem Header="todo.md"/>
    </TabView.TabItems>
</TabView>
```

| 成员 | 语义 |
|------|------|
| `TabItems` / `TabItemsSource` | 静态页签 / 集合驱动（动态文档列表） |
| `TabViewItem` | `Header`（任意对象）、`IconSource`、`IsClosable` |
| `SelectionChanged` | 切页签（Selector 家族语义，17 章） |
| `TabCloseRequested` | 用户点了关闭叉——**关闭不会自动发生** |
| `AddTabButtonClick` + `IsAddTabButtonVisible` | 右侧 "+" 按钮 |

两个行为要点（都在演示页代码里）：

```cpp
void TabViewPage::OnTabCloseRequested(IInspectable const&,
    TabViewTabCloseRequestedEventArgs const& args)
{
    // 关闭不自动发生：必须在这里真正移除 TabItems 里的那一项
    uint32_t index{};
    if (Docs().TabItems().IndexOf(args.Tab(), index))
    {
        Docs().TabItems().RemoveAt(index);
        StatusText().Text(L"closed a tab, left = " + to_hstring(Docs().TabItems().Size()));
    }
}

void TabViewPage::OnAddTabClicked(IInspectable const&, IInspectable const&)
{
    TabViewItem item;
    item.Header(box_value(L"new " + to_hstring(Docs().TabItems().Size())));
    Docs().TabItems().Append(item);
    Docs().SelectedItem(item);   // 新页签立即激活
}
```

- **`TabCloseRequested` 只报告意图**：`args.Tab()` 给你被点的页签，移除是你的事（典型还要先问"保存吗"——24 章 ContentDialog 串起来）。忘写移除代码 = 叉形同虚设。
- **`AddTabButtonClick` 的 args 是裸 `IInspectable`**（元数据核对的委托形状，23/25 章还有同款）。

**TabView 与 Frame 导航的分工**：TabView 管"同屏多文档"，NavigationView（22 章）管"全局区域切换"。混用前先问交互定位——多数应用只需要后者。

## 21.2 Expander：折叠区

```xml
<Expander Header="Advanced options" Expanding="OnExpanderExpanding" Collapsed="OnExpanderCollapsed">
    <TextBlock Text="Options live here." Margin="8"/>
</Expander>
```

- `Header` 是收起时可见的行；`Content` 是展开后的区。
- **事件是 `Expanding`/`Collapsed`**，args 类型分别是 **`ExpanderExpandingEventArgs` / `ExpanderCollapsedEventArgs`**——不是 RoutedEventArgs。本页开发实测（编译级，XAML 生成代码 C2664 直接打脸）：这族事件的委托形状以生成代码为准，别按"XX 事件 = RoutedEventArgs"的惯例猜。
- `ExpandDirection`（Down/Up）与 `IsExpanded`（程序化开合）。

适用边界：**设置页分组、高级选项**——用户偶尔才碰的区域。内容是主要流程就别折叠（多一次点击是纯损耗）。

## 21.3 实测坑位

1. **TabCloseRequested 不自动关**（21.1）——移除代码必须写。
2. **Expander 事件 args 类型**（21.2，ExpanderExpandingEventArgs/ExpanderCollapsedEventArgs）。
3. **AddTabButtonClick args 是 IInspectable**（21.1）。
4. **页签内容直接塞 TabViewItem 里**：静态可以；动态文档用 TabItemsSource + Header 模板。
5. TabView 默认可拖拽重排页签（`CanReorderTabs`）——数据驱动时确认你的顺序假设。

## 21.4 小结

| 需求 | API |
|------|-----|
| 多文档页签 | TabView：TabItems/TabItemsSource + SelectionChanged |
| 关闭页签 | TabCloseRequested 里手动 RemoveAt |
| 添加页签 | AddTabButtonClick + Append + SelectedItem |
| 折叠分组 | Expander：Header/Content + Expanding/Collapsed |

画廊 `TabViewPage` 运行时证据：`.smoke/21-controls-shell/tabview/click-2.png`——点击第二个页签，状态行 **"tab = notes.md"**，页签高亮切换。

---

上一篇：[20 表格数据](./20-datagrid-itemsrepeater.md) ｜ 下一篇：[22 NavigationView 与 SplitView](./22-navigationview.md) ｜ 返回 [目录](../README.md)
