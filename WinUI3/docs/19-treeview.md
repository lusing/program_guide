# 19. TreeView：层级数据

上一篇：[18 GridView 与 FlipView](./18-gridview-flipview.md) ｜ 下一篇：[20 表格数据：DataGrid 缺位与自制](./20-datagrid-itemsrepeater.md)

文件树、组织架构、章节目录——层级数据的展示归 `TreeView`。它没有走 Selector 路线，而是有自己的 `TreeViewNode` 对象模型和 `ItemInvoked` 事件。示例来自画廊工程的 `TreeViewPage`（导航 **TreeView** 项）。

## 19.1 建树：TreeViewNode 模型

```cpp
TreeViewPage::TreeViewPage()
{
    InitializeComponent();
    auto make_child = [](hstring const& name)
    {
        TreeViewNode c;
        c.Content(box_value(name));
        return c;
    };
    for (auto const& root : std::array<hstring, 3>{ L"src", L"docs", L"examples" })
    {
        TreeViewNode node;
        node.Content(box_value(root));
        node.Children().Append(make_child(root + L"/a"));
        node.Children().Append(make_child(root + L"/b"));
        DirTree().RootNodes().Append(node);
    }
}
```

模型要点：

- `TreeViewNode`：`Content`（装箱的任意值，显示用）+ `Children`（`IVector<TreeViewNode>`，可观察——增删即时反映）+ `IsExpanded` + `HasChildren` + `Depth`。
- 树根挂在 `TreeView().RootNodes()`；子挂父的 `Children()`。**递归是天然写法**（本页 Expand 按钮同样递归）。
- 元数据核对（1.8）：`Microsoft.UI.Xaml.Controls.TreeViewNode`、`TreeView`、`TreeViewItemInvokedEventArgs` 均在 `Microsoft.UI` 命名空间下——UWP 资料里的 `Windows.UI` 前缀全部要换。

## 19.2 交互：ItemInvoked 与展开

```cpp
void TreeViewPage::OnNodeInvoked(IInspectable const&,
    TreeViewItemInvokedEventArgs const& args)
{
    if (!StatusText()) return;
    auto node = args.InvokedItem().as<TreeViewNode>();
    if (auto content = node.Content())
    {
        StatusText().Text(L"node = " + unbox_value<hstring>(content));
    }
}
```

- **`ItemInvoked`**：点击节点本体触发（点箭头展开不算）。项在 `args.InvokedItem()`，是 `TreeViewNode`。
- **程序化展开**：`node.IsExpanded(true)`。全展开 = 递归（`ExpandRecursively`，本页按钮演示，状态行报 **"expanded 9 nodes"**）。
- `SelectionMode`（Single/Multiple/None）决定能否"选中高亮"；默认 None 时 ItemInvoked 是唯一反馈。

## 19.3 懒加载模式

子节点未知/昂贵的树（网络目录、数据库大纲）：

```cpp
node.HasChildren(true);   // 先显示展开箭头
// Collapsed/Expanding 事件里此刻才 Append 真子节点
```

`HasChildren(true)` 骗 UI 画箭头；用户展开时 `Expanding` 事件给你填充时机。配合 `IsExpanded` 可以做"首次展开后不再重复加载"。

## 19.4 ItemsSource 路线的现实

WinUI 的 TreeView 有 `ItemsSource` 与 `HierarchicalDataTemplate`（XAML 侧声明"每层的模板与子集合属性"），C# 工程里常用。**C++/WinRT 里它的投影路径存在但样本稀少**（元数据确认类型在），本章的教学主线走 TreeViewNode 直构——对 C++ 工程最直观可控。需要数据驱动大树时，把"模型→TreeViewNode 树"的同步写成一对递归函数（模型侧加孩子 → 找到对应 node Append），比挣扎于模板绑定更可调试。这是工程判断而非能力缺失，如实记。

## 19.5 实测坑位

1. **字面量相加**（本页开发实录）：`for (auto const& root : { L"src", ... })` 里 `root + L"/a"` 是 `wchar_t const* + wchar_t const*` = C2110。循环集合用 `std::array<hstring, N>{...}`。
2. **ItemInvoked 的项要 as<TreeViewNode>**：`InvokedItem()` 返回 IInspectable。
3. **展开不触发 ItemInvoked**：两套交互，别混。
4. **深树的递归深度**：万级深度才需要考虑，常规目录树无虞。

## 19.6 小结

| 环节 | API |
|------|-----|
| 建树 | `RootNodes()` + `node.Children().Append()`，Content 装箱 |
| 点击节点 | `ItemInvoked` → `args.InvokedItem().as<TreeViewNode>()` |
| 展开 | `node.IsExpanded(bool)`；全展开递归 |
| 懒加载 | `HasChildren(true)` + Expanding 事件填充 |
| 数据驱动 | C++ 推荐"模型↔TreeViewNode"手动同步递归 |

画廊 `TreeViewPage` 运行时证据：`.smoke/17-controls-collections/treeview/click-2.png`——点击 Expand all，三根六子全部展开，状态行 **"expanded 9 nodes"**。

---

上一篇：[18 GridView 与 FlipView](./18-gridview-flipview.md) ｜ 下一篇：[20 表格数据](./20-datagrid-itemsrepeater.md) ｜ 返回 [目录](../README.md)
