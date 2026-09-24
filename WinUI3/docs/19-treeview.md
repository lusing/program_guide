# 19. TreeView：层级数据

上一篇：[18 GridView 与 FlipView](./18-gridview-flipview.md) ｜ 下一篇：[20 表格数据：DataGrid 缺位与自制](./20-datagrid-itemsrepeater.md)

文件树、组织架构、章节目录——层级数据的展示归 `TreeView`。它没有走 Selector 路线，而是有自己的 `TreeViewNode` 对象模型和 `ItemInvoked` 事件。示例代码来自功能工程 `examples/17-data-explorer/`（数据浏览器：分类树、双视图、名称过滤、详情轮播）。

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

## 19.5 实战：分类树真过滤（数据浏览器）

```xml
<TreeView x:Name="Categories" SelectionMode="Single"
          ItemInvoked="OnCategoryInvoked">
    <TreeView.RootNodes>
        <TreeViewNode Content="All" IsExpanded="True">
            <TreeViewNode.Children>
                <TreeViewNode Content="Documents"/>
                <TreeViewNode Content="Images"/>
                <TreeViewNode Content="Audio"/>
                <TreeViewNode Content="Archives"/>
            </TreeViewNode.Children>
        </TreeViewNode>
    </TreeView.RootNodes>
</TreeView>
```

静态树直接在 XAML 里声明节点（`TreeViewNode` 带 `Content` 与 `Children`），**不预选任何节点**——TreeView 的选中/展开在解析期触发事件，与 12.5 家族同源。

### 19.5.1 ItemInvoked 与双形态载荷

```cpp
void MainWindow::OnCategoryInvoked(TreeView const&,
    TreeViewItemInvokedEventArgs const& args)
{
    // 19 章：ItemInvoked 的载荷是 TreeViewItem 或节点本身，两种都接
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
```

**为什么选 ItemInvoked 而不是 SelectionChanged**：真实分类树允许"点已选中的类别重新触发过滤"（清掉文本过滤回到纯类别态）。SelectionChanged 只在选中态变化时触发——点同一个节点没事件；ItemInvoked 是纯点击语义，每次都到。两者的取舍与 22 章 NavigationView 相同。

**载荷双形态**（TreeViewItem vs TreeViewNode）不是设计美感，是历史包袱的实况：节点由 ItemsSource 供给时载荷是数据对象，XAML 静态声明时是 TreeViewItem——`try_as` 两连判是最稳的接法。

### 19.5.2 树在 SplitView 侧栏里

TreeView 住在 `SplitView.Pane`（22.4 的底座在此上岗）：侧栏分类树 + 主区表格，是"导航不配做、列表懒得筛"的中间态——**层级过滤**。NavigationView 适合"互斥的目的地"，TreeView 适合"可组合的维度"（类别 × 文本过滤两个维度同时生效，ApplyFilters 是它们的交点）。窗口窄时 `DisplayMode="Inline"` 的面板推挤内容——窄屏形态把它切 Overlay 就是文件资源管理器的行为。

`.smoke/17-data-explorer/tree/tap-1.png`：点 Images 节点 → 树高亮、表格剩 3 行、计数行 "3 items · Images"。树的可视反馈（高亮）与列表的内容反馈（行数变化）在同一个交互里各说各的话——这才是"过滤控件"的完整形态，而不是状态行里一句 "selected = images"。

### 19.5.3 展开态与 HasUnrealizedChildren

静态树的展开就是 `IsExpanded="True"` 一行。数据驱动的大树要用 `HasUnrealizedChildren="True"` 开惰性填充（展开时才 `Children().Append(...)`）——文件系统目录树没有别的写法（C 盘全量展开是天文数字）。数据浏览器的五节点树用不着，但记住这条升级路径的存在：**TreeView 的对象模型按十万节点设计，别拿它当五个RadioButton用**——那不如 ComboBox。

### 19.5.4 ItemTemplate：节点的自定义长相

静态节点的 Content 是字符串；数据驱动（TreeViewNode 承对象）时要 ItemTemplate：

```xml
<TreeView ItemTemplate="..."/>
```

模板里 `x:Bind` 到节点数据类（如 Category{Name, Icon}）——与 17 章 DataTemplate 完全同机制。**不要用 Content 塞 UIElement**（能跑但节点展开/选中态的视觉不跟随）；也别忘了 TreeViewItem 的缩进由控件层管，模板只管"一行里的内容"。

### 19.5.5 选中态的维护成本

TreeView 的 SelectionMode=Single 有内建高亮——但**过滤后选中项可能不在视图里**（类别切走、选中还挂在旧项上）。数据浏览器点新类别时旧选中自然被替换（ItemInvoked + SelectionMode 双轨）；更复杂的"选中与数据不同步"bug 出在 ItemsSource 重建后 SelectedItem 悬空引用——重建向量后要么清选中要么重设到等价新对象（IndexOf 找不到就清，别硬设旧引用）。

### 19.5.6 树的键盘与无障碍

TreeView 键盘内建：方向键在**可见节点间**移动、左右键展开/收起/进出层级、Home/End 到首尾。**展开过的节点才进键盘序**（惰性填充的子节点未展开时不可达）——大树的键盘体验取决于填充策略。AutomationProperties 默认按 Content 朗读（"Images, tree item, level 2"）——层级自动带上，这是 TreeView 相对手搓 Expander 列表的最大无障碍红利。

### 19.5.7 树的持久化：展开态

TreeView 的展开状态是**纯 UI 状态**（用户展开过什么）——产品上常要记忆（重启回到上次展开的样子）。挂 `TreeExpanding` 事件记录节点路径、启动时回放 `IsExpanded(true)`。路径用节点 Content 拼（"All/Images"）而不是索引（树结构变了索引即错）。数据浏览器的五节点树不需要；文件树类应用必须有——**展开态记忆是"树形 UI 尊重用户"的最低标准**。

### 19.5.8 TreeView vs 手搓 Expander 链

层级展示的另一条土路：Expander 嵌 Expander。差在没有**统一的选择模型**（每层各管各的）、没有键盘层级导航（19.5.6）、没有懒加载钩子（19.5.3）——只省了一个 ItemInvoked 处理器。三层以下且不需要选择的静态结构（FAQ 页）可以用；但凡有交互，TreeView 全维度碾压。

### 19.5.9 拖放：树的进阶交互

TreeView 支持节点拖拽重排/跨层级移动（`AllowDrop`+`CanDragItems`+ `DragItemsStarting/Completed` 一族事件）——文件管理器的"拖进文件夹"就是它。**数据模型的代价**：拖放落点要改的是你的层级数据（不是 TreeView 的）——DragOver 里校验合法性（图片文件夹不能拖进音频节点）、Drop 里改 m_all 重建过滤。数据浏览器没做拖放（分类是静态的）；**有拖放的树=数据可变的应用**，持久化结构先想清楚再开这个口。

## 19.6 练习与思考

1. 19.5.7 的展开态持久化：挂 TreeExpanding 记路径、启动回放。路径用什么标识节点？索引为什么不行？
2. 把分类树换成 ItemsSource 驱动（Categories 向量）——ItemInvoked 的载荷形态变了吗？（19.5.1 的双形态预言兑现）
3. TreeView 加"All"节点外的多选（复选框模式）——与单选过滤的交互模型冲突在哪？你的裁决？

### 19.5.10 树的视觉密度

TreeViewNode 的缩进（每层约 16 逻辑 px）与行高是内建的——**深树（5+ 层）横向吃屏幕**：250px 面板只够四层。缓解：`ItemTemplate` 里压缩内容（图标+短名）、或换"面包屑+列表"形态（资源管理器的地址栏模式——只显示当前层，父级在面包屑里）。**TreeView 适合"同时看多层"，面包屑适合"聚焦一层深钻"**——数据浏览器两级树用 TreeView；文件管理器的深层钻取用面包屑+列表更现代。

## 19.7 上生产前的审查清单

- [ ] 选中/展开不预置于 XAML（解析期事件家族）
- [ ] ItemInvoked 载荷双形态都接住（TreeViewItem/TreeViewNode）
- [ ] 大树有懒加载方案（HasUnrealizedChildren）
- [ ] 展开态是否需要持久化已决策（19.5.7）
- [ ] 层级深度 vs 面板宽度的最坏情况算过

## 19.6 小结

| 环节 | API |
|------|-----|
| 建树 | `RootNodes()` + `node.Children().Append()`，Content 装箱 |
| 点击节点 | `ItemInvoked` → `args.InvokedItem().as<TreeViewNode>()` |
| 展开 | `node.IsExpanded(bool)`；全展开递归 |
| 懒加载 | `HasChildren(true)` + Expanding 事件填充 |
| 数据驱动 | C++ 推荐"模型↔TreeViewNode"手动同步递归 |

运行时证据：`.smoke/17-data-explorer/tree/tap-1.png`——侧栏 TreeView（All/Documents/Images/Audio/Archives）点击 Images 节点，ItemInvoked 过滤主列表与计数行，状态 **"3 items · Images"**；XAML 里不预选节点，避免解析期触发事件（全书反复出现的坑）。

---

上一篇：[18 GridView 与 FlipView](./18-gridview-flipview.md) ｜ 下一篇：[20 表格数据](./20-datagrid-itemsrepeater.md) ｜ 返回 [目录](../README.md)
