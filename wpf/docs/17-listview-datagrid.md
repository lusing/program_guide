# 17 · ListView 与 DataGrid

> 对应示例：`examples/17_datagrid`（ListView+GridView 表头排序 与 DataGrid 行内编辑，同一份数据两份视图）

> **本章你将学会**：ListView+GridView 的列定制与表头排序、DataGrid 的列类型与行内编辑、CollectionView 的排序原理。
> **前置章节**：[10 集合绑定](10-binding-advanced.md)、[15 DataTemplate](15-templates.md)。

## 1. 两个列表控件，两种定位

| | ListView + GridView | DataGrid |
|---|---|---|
| 定位 | 表格**展示** | 表格**编辑** |
| 列定义 | GridViewColumn（展示型） | 内置列类型（可编辑） |
| 行内编辑 | 无 | 双击单元格即改 |
| 排序 | 手动实现（本章实战） | 点表头内置排序 |
| 选择 | 内置 | 内置 + 多选模式 |

**选型口诀：只看不改用 ListView，要增删改用 DataGrid**。示例把同一份 `ObservableCollection<Employee>` 喂给两个控件——在 DataGrid 里改工资，ListView 那份**实时跟着变**（元素 INPC 的功劳，第 10 章伏笔），这份"同一数据多视图"的直观体验值得跑一遍。

## 2. ListView + GridView：列结构自己搭

ListView 默认是竖排列表；套上 `GridView`（ListView 专属的 View）变表格：

```xml
<ListView ItemsSource="{Binding Employees}"
          GridViewColumnHeader.Click="ListView_HeaderClick">
    <ListView.View>
        <GridView>
            <GridViewColumn Header="姓名" DisplayMemberBinding="{Binding Name}" Width="90"/>
            <GridViewColumn Header="部门" DisplayMemberBinding="{Binding Department}" Width="90"/>
            <GridViewColumn Header="薪水" CellTemplate="{StaticResource SalaryCell}" Width="110"/>
            <GridViewColumn Header="在职" Width="60">
                <GridViewColumn.CellTemplate>
                    <DataTemplate>
                        <CheckBox IsChecked="{Binding IsActive}" HorizontalAlignment="Center"/>
                    </DataTemplate>
                </GridViewColumn.CellTemplate>
            </GridViewColumn>
        </GridView>
    </ListView.View>
</ListView>
```

两种列内容的写法：

- **DisplayMemberBinding**：一行搞定"绑定属性直接显示"
- **CellTemplate**：要自定义外观（格式化、模板触发器、交互控件）时用——本质就是 DataTemplate（第 15 章），示例 SalaryCell 用模板触发器把 `IsHighSalary` 的行标蓝

注意薪水列的派生属性手法：DataTrigger 只做等值比较，"达到 18000 标蓝"在 Employee 上预加工成 `IsHighSalary`（bool），Salary 的 setter 里联动通知——第 15 章 AgeGroup 的同一套路。

## 3. 表头点击排序：CollectionView 登场

WPF 绑定到集合时，引擎自动在集合外套一层**视图（CollectionView）**——排序、筛选、分组都作用在**视图**上，数据集合本身不动（同一数据可以有多个不同排序的视图）。表头排序的标准实现：

```csharp
private void ListView_HeaderClick(object sender, RoutedEventArgs e)
{
    if (e.OriginalSource is not GridViewColumnHeader header) return;   // 表头是路由事件源头（第 08 章）

    var property = header.Column.Header switch           // 表头文本 → 属性名
    {
        "姓名" => nameof(Employee.Name),
        "薪水" => nameof(Employee.Salary),
        _ => "",
    };

    if (_lastSortProperty == property)                    // 再点同一列：切换升降序
        _lastDirection = _lastDirection == ListSortDirection.Ascending
            ? ListSortDirection.Descending : ListSortDirection.Ascending;
    else { _lastSortProperty = property; _lastDirection = ListSortDirection.Ascending; }

    var view = CollectionViewSource.GetDefaultView(_vm.Employees);
    view.SortDescriptions.Clear();
    view.SortDescriptions.Add(new SortDescription(property, _lastDirection));
}
```

三步：拿默认视图 → 清旧排序 → 加 SortDescription（属性名 + 方向）。筛选同理一行：`view.Filter = o => ((Employee)o).IsActive;`。**列表项的增删仍然走 ObservableCollection**——视图只是数据之上的"取景器"。

（`GridViewColumnHeader.Click` 是挂 ListView 上的附加路由事件——第 08 章"容器统一接"的实战应用。）

## 4. DataGrid：内置编辑能力的表格

同样的数据，DataGrid 几行声明就有了编辑/排序/选择全家桶：

```xml
<DataGrid ItemsSource="{Binding Employees}" AutoGenerateColumns="False"
          CanUserAddRows="False" SelectionMode="Single">
    <DataGrid.Columns>
        <DataGridTextColumn Header="姓名" Binding="{Binding Name, UpdateSourceTrigger=PropertyChanged}"/>
        <DataGridTextColumn Header="薪水" Binding="{Binding Salary, StringFormat={}{0:N0}}"/>
        <DataGridCheckBoxColumn Header="在职" Binding="{Binding IsActive}"/>
        <DataGridTemplateColumn Header="薪资水位">
            <DataGridTemplateColumn.CellTemplate>
                <DataTemplate>
                    <ProgressBar Minimum="0" Maximum="21000" Value="{Binding Salary}" Height="12"/>
                </DataTemplate>
            </DataGridTemplateColumn.CellTemplate>
        </DataGridTemplateColumn>
    </DataGrid.Columns>
</DataGrid>
```

内置列类型速查：

| 列类型 | 用途 | 备注 |
|---|---|---|
| `DataGridTextColumn` | 文本 | 最常用 |
| `DataGridCheckBoxColumn` | bool | 直接勾 |
| `DataGridComboBoxColumn` | 枚举选择 | ItemsSource 要另外配 |
| `DataGridHyperlinkColumn` | 链接 | — |
| `DataGridTemplateColumn` | 任意模板 | CellTemplate 展示 + **CellEditingTemplate** 编辑两态 |

几个高频开关：`AutoGenerateColumns="False"`（不用它自动猜列）、`CanUserAddRows="False"`（关掉末尾空行）、`IsReadOnly`（列级/表级只读）、`SelectionMode="Extended"`（多选）。

**编辑的生命周期**：双击进入编辑 → 控件换成编辑态（模板列的 CellEditingTemplate）→ 回车/点别处提交 → 绑定回写 → INPC 通知 → 同一数据的其他视图刷新。编辑中的验证直接用第 16 章方案（列的 Binding 上加验证开关）。

## 5. 大数据量的三个性能开关

表格行数上千时的标配：

```xml
<DataGrid EnableRowVirtualization="True" EnableColumnVirtualization="True"
          VirtualizingPanel.VirtualizationMode="Recycling"/>
```

虚拟化 = 只为**可视区**的行生成控件（滚到哪建到哪），万行数据也只同时存在二三十个控件。`Recycling` 复用行容器，滚动更顺。代价：不能假设"所有行的控件都存在"——遍历视觉树找行级控件的写法会踩空（用数据层操作替代）。第 18 章 TreeView 虚拟化同理。

## 6. 常见坑

**DisplayMemberBinding 与 CellTemplate 同列混用**：后者被无视——一个列只能一种内容策略。

**DataGrid 改了数据别的控件不动**：数据元素没实现 INPC（第 10 章两层通知的元素层缺失）——ObservableCollection 只管增删行，不管行内属性变化。

**表头排序点不动**：GridViewColumnHeader.Click 是**附加事件**，要挂在 ListView 元素上；写 `Click=` 挂到列上不行。处理器里用 `e.OriginalSource` 还原被点的表头（第 08 章坑的实战复现）。

**CanUserAddRows 默认 true 的空行崩溃**：末尾"新行"在提交前是空对象，绑定其属性的地方要判空；不需要手输新增就关掉。

**模板列里的交互控件点击即编辑**：CheckBox 在展示态就能点（默认可用），但 ProgressBar 之类纯展示模板别放可交互控件——误触进入编辑态。

**CollectionView 排序后往 ObservableCollection 插入**：插入位置按数据集合算，显示位置按视图排序——"插到第 0 行却显示在中间"不是 bug。要精确控制显示序就用视图的排序规则表达。

## 7. 实战建议

- 列宽：`Width="Auto"` 自适应内容 + `ColumnWidth="*"` 分配剩余，混用前想清楚谁是主体
- 表格界面的"全选框"：表头放 CheckBox，IsChecked 绑"是否全选"逻辑（三态），列表头排序时注意排除该列
- 导出/打印类需求直接读 ItemsSource 数据集合，**别遍历 DataGrid 行控件**——数据才是真相，控件是投影
- DataGrid 的深入主题（分页、主从表、行详情 RowDetails）都在"列 + 绑定 + 模板"三个机制上生长，需要时按这个拆解去查

## 自测

1. **只读表格与可编辑表格分别选哪个控件？** —— ListView+GridView 展示；DataGrid 编辑。
2. **CollectionView 与 ObservableCollection 的分工？** —— 集合管数据增删（通知行数变化），视图管排序/筛选/分组（数据不动、取景器变）。
3. **DisplayMemberBinding 与 CellTemplate 各适用什么列？** —— 纯文本直显 vs 需要模板/触发器/交互的列。
4. **虚拟化牺牲了什么？** —— 不可假设所有行控件存在；遍历视觉树的写法失效，改走数据层。

---
上一章：[16 数据验证](16-validation.md) ｜ 下一章：[18 TreeView 与层级数据](18-treeview.md)
