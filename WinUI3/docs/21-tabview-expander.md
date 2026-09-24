# 21. TabView 与 Expander

上一篇：[20 表格数据](./20-datagrid-itemsrepeater.md) ｜ 下一篇：[22 NavigationView 与 SplitView](./22-navigationview.md)

文档型界面（编辑器、浏览器、设置页）的骨架是 `TabView`；把一屏长表单收拢成"按需展开"用 `Expander`。示例代码来自功能工程 `examples/09-scratchpad/`（编辑器：多文档、加粗、查找、未保存确认、落盘回读）。

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

两个行为要点（都在 ScratchPad 的代码里）：

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

## 21.5 实战：多文档编辑器的两件套（ScratchPad）

### 21.5.1 TabView：每个页签一份独立世界

页签不是"标签字符串"——每个 TabViewItem 的 Content 是一个**独立的 RichEditBox**：

```cpp
void MainWindow::AddTab()
{
    hstring name = L"untitled-" + to_hstring(m_docs.size() + 1) + L".txt";

    RichEditBox editor;
    editor.AcceptsReturn(true);
    // ...编辑器配置（9.9.1）...

    TabViewItem tab;
    tab.Header(box_value(name));   // 页签标题：装箱字符串
    tab.Content(editor);           // 页签内容：整个文档编辑器
    Docs().TabItems().Append(tab);
    Docs().SelectedItem(tab);      // 新页签即选中

    TabEntry entry{ tab, name, false };   // 脏标记与名字跟页签走
    m_docs.push_back(std::move(entry));
}
```

**页面状态放哪**：`m_docs` 向量存 `{TabViewItem, name, dirty}`——TabViewItem 是引用计数对象，存副本安全。不把状态塞进 Tag 里装箱拆箱，因为脏标记要高频读写。`AddTabButtonClick`（页签栏的 + 按钮）与 Ctrl+N、File 菜单三个入口都汇到这个函数——**创建文档只有一条路**。

### 21.5.2 关闭确认：TabCloseRequested

```xml
<TabView x:Name="Docs" TabCloseRequested="OnTabCloseRequested"
         AddTabButtonClick="OnAddTabButton"/>
```

页签的 X 触发 `TabCloseRequested`，处理器是协程（要 await 对话框）：

```cpp
Windows::Foundation::IAsyncAction MainWindow::OnTabCloseRequested(
    TabView const&, TabViewTabCloseRequestedEventArgs const& args)
{
    auto tab = args.Tab();
    auto entry = FindEntry(tab);
    if (entry && entry->Dirty)
    {
        ContentDialog dlg;   // 24 章的完整形态，此处只看关闭侧
        ...
        auto choice = co_await dlg.ShowAsync();
        if (choice == ContentDialogResult::Primary) { SaveTab(tab); }
        else if (choice == ContentDialogResult::None) { co_return; }   // Cancel
    }
    CloseTab(tab);
    if (m_docs.empty()) { AddTab(); }   // 关到最后补一个空文档
}
```

最后两行是产品语义：**关掉最后一个页签不等于关窗口**——编辑器空转不如给个新文档（VS Code 的行为）；真要关窗走 File > Exit。**注意 e.Tab() 按值捕获**——协程挂起期间 UI 可能继续动，引用参数会悬空。

### 21.5.3 Expander：查找面板的收与放

```xml
<Expander x:Name="FindPane" Header="Find in document" IsExpanded="False">
    <StackPanel Orientation="Horizontal" Spacing="8">
        <TextBox x:Name="FindBox" Width="260" .../>
        <Button Content="Next" Click="OnFindNext"/>
    </StackPanel>
</Expander>
```

Ctrl+F 的处理器做两件事：翻面 + 抢焦点：

```cpp
void MainWindow::OnToggleFind(IInspectable const&, RoutedEventArgs const&)
{
    FindPane().IsExpanded(!FindPane().IsExpanded());
    if (FindPane().IsExpanded())
    {
        FindBox().Focus(FocusState::Programmatic);
    }
}
```

**展开后立刻 Focus 是键盘流的闭环**：用户按 Ctrl+F 是想输入，不是想再点一下输入框。收起面板不用做任何事——焦点自然流回。Expander 的适用线（21.2 说过"低频次级选项"）在这里兑现：查找是次级功能，但一旦展开就是高频输入，所以内容区放完整交互（输入框+按钮）而非静态说明。

**XAML 默认 `IsExpanded="False"` 是安全方向**：True 会在解析期触发展开动画与布局，虽然 Expander 的事件不像 Checked 那样危险，但"收起"本来就是查找面板的正确初态。

### 21.5.4 页签的生命周期尾巴

关闭页签后 `m_docs.erase` + `TabItems.RemoveAt`——但**异步尾巴**：21.5.2 的协程 await 期间用户可能已关掉别的页签（索引位移）。这就是为什么 FindEntry 遍历匹配 TabViewItem 而不是存索引：**句柄式查找（对象身份）对异步重排免疫**，索引式查找（下标）在两个 await 点之间就可能失效。同理由，m_view 的 IndexOf 拿到 index 后立即用、不缓存（18 章的同步代码也一样纪律）。

### 21.5.5 Expander 的展开方向与布局

`Expander.ExpandDirection`（Down 默认/Up/Left/Right）决定内容从哪边长出来——查找面板在底部时 Up 更贴（向屏内展开）。数据浏览器把它放在列表与命令栏之间用默认 Down。**布局占位是 Expander 的隐性成本**：收起时高度为零但仍在视觉树，频繁开合会让下方内容跳——本例下方是命令栏（固定行），跳的是面板自身，无感；若下方还有滚动内容，开合瞬间滚动位置会被顶，必要时 ScrollIntoView 压回。

### 21.5.6 页签的中键关闭与拖拽

TabView 内建：**鼠标中键点页签=关闭**（浏览器习惯，免费）+ 页签拖拽重排（`CanReorderTabs`，默认开，含拖出成新窗口的 `CanDragTabs`——拖出行为要配 31 章多窗口）。重排后 m_docs 向量与视觉顺序脱钩——FindEntry 按对象身份查找的架构（21.5.4）对重排免疫；若哪里缓存了索引，重排即错。**教学取舍**：ScratchPad 没关 CanReorderTabs 也没处理顺序持久化——重排后保存顺序与视觉不一致，记为已知边界（产品化要么关重排要么持久化顺序）。

### 21.5.7 Expander 的无障碍语义

Expander 的展开头**自动是按钮**（朗读"可展开/已折叠"+ 回车切换）——这是它对手搓"标题+Visibility 切换"的碾压级优势（手搓版朗读器只念文字，不知道能点）。`AutomationProperties.Name` 默认取 Header——别给 Header 塞图标（Content 装对象时 Name 落空，要显式补）。

## 21.4 小结

| 需求 | API |
|------|-----|
| 多文档页签 | TabView：TabItems/TabItemsSource + SelectionChanged |
| 关闭页签 | TabCloseRequested 里手动 RemoveAt |
| 添加页签 | AddTabButtonClick + Append + SelectedItem |
| 折叠分组 | Expander：Header/Content + Expanding/Collapsed |

运行时证据：`.smoke/09-scratchpad/close/tap-3.png`——TabView 的页签 X 触发未保存确认（ContentDialog 三钮），FindPane 是 Expander 折叠板（Ctrl+F 展开、聚焦查找框）；每个 TabViewItem 的 Content 是一个独立 RichEditBox，TextChanged 脏标记驱动页签语义。

---

上一篇：[20 表格数据](./20-datagrid-itemsrepeater.md) ｜ 下一篇：[22 NavigationView 与 SplitView](./22-navigationview.md) ｜ 返回 [目录](../README.md)
