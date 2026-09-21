# 18 · TreeView 与层级数据

> 对应示例：`examples/18_treeview`（解决方案资源管理器式的文件树 + 展开收起批量操作）

> **本章你将学会**：HierarchicalDataTemplate 的嵌套绑定、树节点的建模、SelectedItem 的获取方式、树的批量操作与懒加载思路。
> **前置章节**：[15 DataTemplate](15-templates.md)、[17 列表数据](17-listview-datagrid.md)。

## 1. 树形数据怎么建模

树控件的数据天然是递归结构——节点模型长这样（示例的 FileNode）：

```csharp
public sealed class FileNode : INotifyPropertyChanged
{
    public required string Name { get; init; }
    public required bool IsFolder { get; init; }

    public ObservableCollection<FileNode> Children { get; } = new();   // ← 孩子的类型就是自己

    public bool IsExpanded { ... }   // 展开状态也是数据（下面有用）
}
```

要点：**Children 是 ObservableCollection<FileNode>**——类型递归、通知机制照第 10 章用。ViewModel 只需要根节点集合：

```csharp
public ObservableCollection<FileNode> Root { get; } = new() { 项目树… };
```

数据是内存里搭好的演示树（解决方案 → 文件夹 → 文件）；真实项目里它可能来自磁盘扫描或接口返回——**树控件不关心数据从哪来，只认"节点有名字和孩子"这个形状**。

## 2. HierarchicalDataTemplate：模板自己套自己

普通 DataTemplate 只管"一层怎么显示"；树需要"每层怎么显示 + 孩子从哪来"——**HierarchicalDataTemplate** 多一个 `ItemsSource`：

```xml
<TreeView ItemsSource="{Binding Root}"
          SelectedItemChanged="FileTree_SelectedItemChanged">
    <TreeView.ItemTemplate>
        <HierarchicalDataTemplate ItemsSource="{Binding Children}">   <!-- ★ 孩子从这来 -->
            <StackPanel Orientation="Horizontal">
                <TextBlock Text="{Binding IsFolder, Converter={StaticResource BoolToIcon}}"/>
                <TextBlock Text="{Binding Name}" Margin="6,0,0,0"/>
                <TextBlock Text="{Binding Badge}" FontSize="11" Foreground="#94A3B8"/>
            </StackPanel>
        </HierarchicalDataTemplate>
    </TreeView.ItemTemplate>
</TreeView>
```

这一个模板被**递归地**用于每一层：根节点的孩子、孩子的孩子……全是 FileNode，所以一份模板通吃。若各层级类型不同（公司→部门→员工），可为每层类型配隐式 DataTemplate（`DataType="{x:Type local:Department}"`），WPF 按类型自动挑模板——多类型树的标准解法。

小图标（📁/📄）由 BoolToIconConverter 转换器提供——第 10 章转换器在"bool → 显示字符"这种轻量场景比模板触发器省事。

## 3. SelectedItem：TreeView 的著名例外

第 09 章以后我们习惯了"一切皆绑定"，但 **TreeView.SelectedItem 是只读属性，不能 TwoWay 绑定**——只能用事件拿：

```csharp
private void FileTree_SelectedItemChanged(object sender,
    RoutedPropertyChangedEventArgs<object> e)
{
    if (e.NewValue is FileNode node)
        StatusText.Text = $"选中：{node.Name}（{(node.IsFolder ? "文件夹" : "文件")}）";
}
```

MVVM 项目的变通：代码后置把选中值转存进 VM（`_vm.SelectedNode = node`），XAML 逻辑依旧不写业务。这个例外记住即可——它和 PasswordBox.Password（第 07 章）同属"不能绑定的家伙"名单。

## 4. 批量操作：操作数据，不是操作视觉树

"展开全部/收起全部"是树的经典操作。**正解是递归遍历模型本身**（示例的做法）：

```csharp
private static void SetExpanded(IEnumerable<FileNode> nodes, bool expanded)
{
    foreach (var node in nodes)
    {
        node.IsExpanded = expanded;        // 数据属性改了，界面跟着变（INPC）
        SetExpanded(node.Children, expanded);
    }
}
```

对比错误直觉"找到所有 TreeViewItem 控件设置 IsExpanded"——要 `ItemContainerGenerator` 逐层生成容器再递归，代码多三倍还受虚拟化限制。**树形 UI 的批量操作永远落在数据上**——IsExpanded 收进模型不是设计洁癖，是让界面状态可被程序操作。

## 5. 懒加载：大树的按需展开

文件系统全量扫描太慢时，标准做法是**展开时才加载孩子**：

```csharp
private async void Node_Expanded(object sender, RoutedEventArgs e)
{
    if (e.OriginalSource is TreeViewItem { DataContext: FileNode node } && !node.Loaded)
    {
        node.Children.Clear();
        foreach (var child in await LoadChildrenAsync(node))   // 真实的 IO 在这
            node.Children.Add(child);
        node.Loaded = true;
    }
}
```

配套技巧：未加载的文件夹先塞一个占位孩子（"加载中…"），让展开箭头出现；`Loaded` 标记防止重复加载。把 `IsExpanded` 变化做成模型的属性通知（第 4 节把它收进模型的好处这里兑现）比挂 TreeViewItem 事件更 MVVM。IO 一定是异步的（第 21 章），别把扫描写在 UI 线程上。

## 6. 常见坑

**SelectedItem 不能绑**：见第 3 节，用事件或行为库（`Interaction.Behaviors` 里有现成桥接）。

**ItemTemplate 写成普通 DataTemplate**：树只有一层、点不开——少了 `ItemsSource` 的递归声明，模板不套模板。

**节点类型不统一时模板错乱**：`object` 型节点 + 单一模板 = 显示 ToString。按类型配隐式模板（`DataType`），或先把数据规整成统一的节点模型（推荐，示例就是这么做的）。

**大树不虚拟化卡顿**：TreeView 默认虚拟化没开，千级节点要显式 `VirtualizingStackPanel.IsVirtualizing="True"`（示例写了）；开了虚拟化后"遍历所有 TreeViewItem"的代码失效——又一次数 据 vs 视觉 的选择题。

**递归死循环**：节点孩子里不小心塞了祖先节点（文件系统的符号链接/循环引用）——加载时判重。

**INPC 忘在 IsExpanded 上**：SetExpanded 改了字段界面不动——树节点的每个可变属性（Name/IsExpanded/徽标）都要走通知。

## 7. 实战建议

- 先把任意树形数据**规整成统一 Node 模型**（Name/Icon/Children/IsExpanded/原始数据引用），界面层就简单了——示例 FileNode 是模板
- 徽标、图标、计数这类"派生显示"用转换器或模型派生属性，别在模板里堆逻辑
- 树 + 列表的主从界面：`SelectedItemChanged` → 更新 VM → 详情区绑定 VM，第 15 章"三件套"的树形版
- 展开状态要持久化（下次打开还原）的话，把 IsExpanded 序列化进配置——因为它是模型属性，这条路径是免费的

## 自测

1. **HierarchicalDataTemplate 比普通 DataTemplate 多了什么？** —— `ItemsSource` 指向孩子的来源，模板由此递归套用每一层。
2. **为什么 TreeView.SelectedItem 不能像 ListBox 那样绑？怎么拿选中项？** —— 它是只读属性；用 SelectedItemChanged 事件（或行为库桥接进 VM）。
3. **"展开全部"应该操作什么？为什么？** —— 递归改模型的 IsExpanded；界面状态收进模型才可编程操作，且不惧虚拟化。
4. **懒加载的关键配套是什么？** —— 占位孩子让箭头出现 + Loaded 防重 + 异步 IO。

---
上一章：[17 ListView 与 DataGrid](17-listview-datagrid.md) ｜ 下一章：[19 绘图与变换](19-drawing.md)
