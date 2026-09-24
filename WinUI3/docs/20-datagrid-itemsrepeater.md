# 20. 表格数据：DataGrid 缺位与自制

上一篇：[19 TreeView](./19-treeview.md) ｜ 下一篇：[21 TabView 与 Expander](./21-tabview-expander.md)

本章与其他控件章不同：它讲一个**不存在的东西**——C++/WinRT 的 DataGrid——以及在没有它的世界里怎么把表格做出来。结论先行：**CommunityToolkit 的 DataGrid 用不了，自制 = Grid 表头 + ListView 行 + ItemsRepeater 高性能场景**。示例代码来自功能工程 `examples/17-data-explorer/`（数据浏览器：分类树、双视图、名称过滤、详情轮播）。

## 20.1 为什么没有 DataGrid（实测证据）

WPF/MFC/Lazarus 教程都有 DataGrid/ListView 报表控件章；WinUI 3 的 C++ 工程想要同样的东西时，第一反应是装 CommunityToolkit：

```xml
<PackageReference Include="CommunityToolkit.WinUI.UI.Controls.DataGrid" Version="7.1.2" />
```

结果（本机实测，WASDK 1.8.260317003 + CppWinRT 2.0.250303.1）：

```text
error NU1202: 包 CommunityToolkit.WinUI.UI.Controls.DataGrid 7.1.2 与 native
(native,Version=v0.0) 不兼容。包支持: net5.0-windows10.0.18362
```

**根因**：Toolkit 7.x 的 DataGrid 是纯托管控件（`lib/net5.0-windows10.0.18362` 下的 C# 程序集），PackageReference 在 native（C++/WinRT）工程里还原直接失败。XAML 编译器需要 WinRT 元数据，托管程序集给不出。这不是版本没选对——**7.x 全系没有 native 目标**。

所以 C++/WinRT 的表格路线是：

| 需求档位 | 方案 |
|---------|------|
| 简单只读表 | **Grid 表头 + ListView 行**（20.2，本章主线） |
| 高性能/自由布局 | **ItemsRepeater + 自定义 Layout**（20.3） |
| 排序/就地编辑/列宽拖拽的企业级表格 | 自己造（工作量大），或项目改用 C# 承载表格页，或 WebView2 嵌 HTML 表格——工程决策，如实评估 |

## 20.2 自制表格：Grid 表头 + ListView 行

```xml
<!-- 表头：一个普通 Grid，列宽定义 -->
<Grid ColumnDefinitions="2*,1*,1*" MaxWidth="560">
    <TextBlock Text="Name" FontWeight="SemiBold" Padding="8,6"/>
    <TextBlock Grid.Column="1" Text="Priority" FontWeight="SemiBold" Padding="8,6"/>
    <TextBlock Grid.Column="2" Text="Done" FontWeight="SemiBold" Padding="8,6"/>
</Grid>

<!-- 行：ListView（选择/虚拟化/滚动全白拿），行模板用同一组列宽 -->
<ListView x:Name="TaskTable" MaxWidth="560" SelectionChanged="OnRowSelected">
    <ListView.ItemTemplate>
        <DataTemplate x:DataType="x:String">
            <Grid ColumnDefinitions="2*,1*,1*" Background="{ThemeResource CardBackgroundFillColorDefaultBrush}">
                <TextBlock Text="{Binding}" Padding="8,6"/>
                <TextBlock Grid.Column="1" Text="P2" Padding="8,6"/>
                <TextBlock Grid.Column="2" Text="no" Padding="8,6"/>
            </Grid>
        </DataTemplate>
    </ListView.ItemTemplate>
</ListView>
```

设计的三个支点：

1. **列对齐**：表头 Grid 和行模板 Grid 用**相同的 ColumnDefinitions 字符串**（`2*,1*,1*`）。两边同宽同约束，列天然对齐——这是没有"共享列宽"机制时最可靠的做法（WPF 的 SharedSizeGroup 在 WinUI 3 不存在）。要像素级对齐就用固定宽列。
2. **行的能力全部白拿**：ListView 的选择高亮、虚拟化、键盘、增删通知——表格行最贵的部分免费。
3. **本页演示用静态字符串行**；真实工程的行是 runtimeclass 对象（Title/Priority/Done 三属性），模板里 `{Binding Title}` 取值，集合挂 ItemsSource——32 章的完整模式直接套。

点表头排序？表头 TextBlock 换 Button，Click 里对数据集合排序后重新喂 ItemsSource（或用可观察集合的排序重建）——排序逻辑在数据侧，控件无感。

## 20.3 ItemsRepeater：裸重复器

```xml
<ItemsRepeater x:Name="TileRepeater" MaxWidth="560">
    <ItemsRepeater.Layout>
        <UniformGridLayout MinItemWidth="90" MinItemHeight="40"
                           MinRowSpacing="8" MinColumnSpacing="8"/>
    </ItemsRepeater.Layout>
    <ItemsRepeater.ItemTemplate>
        <DataTemplate x:DataType="x:String">
            <Border Background="{ThemeResource AccentFillColorDefaultBrush}" CornerRadius="6">
                <TextBlock Text="{Binding}" Foreground="White" Padding="10"/>
            </Border>
        </DataTemplate>
    </ItemsRepeater.ItemTemplate>
</ItemsRepeater>
```

```cpp
auto tiles = single_threaded_vector<IInspectable>();
for (int i = 1; i <= 8; ++i) tiles.Append(box_value(L"T" + to_hstring(i)));
TileRepeater().ItemsSource(tiles);
```

ItemsRepeater 的定位：**ItemsControl 拆到只剩"重复 + 布局"**。没有选择、没有内建交互、没有 ItemClick——换来的是性能与自由度（布局可换：StackLayout/UniformGridLayout/FlowLayout，进阶可自写 Layout）。要用选择就自己叠（ItemClick 手动、或每项模板里放可点击元素）。

- 平铺小图（色板、标签云）：`UniformGridLayout`。
- 纵向高性能清单（自己管选择）：`StackLayout` + 模板里放 ToggleButton/RadioButton。
- 流式换行：`FlowLayout`。

## 20.4 实测坑位

1. **NU1202 就是答案**（20.1）：别再找"支持 C++ 的 DataGrid 版本"，7.x 没有。
2. **列对齐靠共享 ColumnDefinitions 字符串**（20.2）：两边改一边忘 = 列错位，改动要成对。
3. **ItemsRepeater 没有选择**：从 ListView 过来最容易踩的预期差。
4. **表头不随行虚拟化**（本来就不该），但表头在 ListView **外**——横向滚动要自己同步（本表无横向滚动，规避）。

## 20.5 实战路线回顾：自制表格的最终形态

数据浏览器把本章路线全部走通，这里把"没有 DataGrid 时怎么办"的完整决策链摊开：

### 20.5.1 需求分层

| 需求 | 数据浏览器的答案 | 章节 |
|---|---|---|
| 多列对齐 | 表头 Grid + 行模板同栅格（2\*/\*/\*\*） | 17.6.2 |
| 行选择/高亮 | ListView 的 SelectionMode + SelectionChanged | 17.6.4 |
| 行内字段绑定 | FileItem runtimeclass + x:Bind | 17.6.1 |
| 过滤（维度一） | TreeView 类别 | 19.5 |
| 过滤（维度二） | TextBox 子串 | 9 章 |
| 双视图 | GridView 卡片共用 m_view | 18.5 |
| 详情 | FlipView 选中联动 | 18.5.3 |

**没有一列需求指向 DataGrid**——这就是本章的论点：表格 = 列栅格 + 行选择 + 数据绑定，三者 ListView 全有。DataGrid 真正的增量是内联编辑、列排序点击、列拖拽——那是 Excel 级交互的领域，你的应用八成不在那里。

### 20.5.2 ItemsRepeater 的位置

数据浏览器没上 ItemsRepeater，因为它换来的性能（无选择/无内置模板开销）在百行级数据上无感。它的真实舞台：**虚拟化自定义布局**——时间线、看板、瀑布流这类"ItemsPanel 之外的形状"。`Layout` 属性接 `StackLayout`/`UniformGridLayout`（社区包还有更多），选择语义要自己搭（它是纯展示控件）。判断线：数据量过万、或布局非行非网格，才值得为此放弃 ListView 的免费午餐。

### 20.5.3 排序与列宽：自制的边界

给自制表格加排序：表头 TextBlock 换 Button，Click 里对 m_view 重排（`std::sort` + 重建向量 + 计数行刷新）——二十行的事。列宽拖拽：两份 ColumnDefinitions 变成代码里共享的 GridLength 资源 + Splitter 手势——这就开始贵了。**贵到什么程度换 ItemsRepeater 或等 DataGrid**：当"表格交互"开始吃掉"业务功能"的开发时间，重新评估依赖。教程立场：自制路线的教学价值（理解 ItemsControl 机制）先于工程价值（省一个依赖），两者都在数据浏览器里兑现了。

### 20.5.4 表格的可达性语义

自制表格的盲区：屏幕阅读器听到的是"逐个 TextBlock"，行列关系丢失（真表格该读"第 3 行，名称列，holiday.jpg"）。ListView 的行级语义（List item）有，**列级没有**——补法是 AutomationProperties.Name 挂到行容器（拼好整行文本）或在每个单元格 TextBlock 上 `AutomationProperties.LabeledBy` 指向表头。教学示例不必全做，**知道欠了什么**比假装不欠强：这是自制路线对 DataGrid 真正的还债项。

### 20.5.5 虚拟化的现实检验

ListView 默认虚拟化（行超出视口才实例化）——千行数据内存平稳。**但行高不齐时（本例文件名单行/换行不定）虚拟化会退化**：容器回收要量高，VariableHeight 模式性能打折。数据浏览器十行无所谓；上万行不齐高，先 `TextTrimming` 钉死单行高（本例已做——文件名超长截断），这是虚拟化的前置条件而非审美选择。

### 20.5.6 排序的完整接线（补 20.5.3 的缺口）

给表头加排序，从 XAML 到逻辑的完整清单：

```xml
<!-- 表头列从 TextBlock 换成可点 -->
<Button Grid.Column="2" Click="OnSortSize" Content="Size" FontWeight="SemiBold"
        Style="{ThemeResource TextButtonStyle}"/>
```

```cpp
void MainWindow::OnSortSize(IInspectable const&, RoutedEventArgs const&)
{
    std::sort(begin(m_view), end(m_view),
        [](auto const& a, auto const& b) { return a.Size() < b.Size(); });
    // observable vector 的排序通知：Clear + 重灌最笨最稳
    auto snapshot = std::vector(m_view.begin(), m_view.end());
    m_view.Clear();
    for (auto&& item : snapshot) { m_view.Append(item); }
}
```

**"3.4 MB" 排序的陷阱**：字符串序 "88 MB" > "410 MB"（'8'>'4'）——格式化前置（17.6.1）的代价在这里付：排序键要么存原始数值（FileItem 加个 double Bytes 字段），要么比较器里解析。这是"展示与数据分离"原则的又一次现身——**模板里只展示，但数据的原始形态要为排序/过滤留好字段**。三视图同源（17.6.3）在排序后自动全刷——列表、卡片、详情跟着重排，一处排序处处生效。

## 20.5 小结

| 场景 | 做法 |
|------|------|
| 只读表格 | Grid 表头 + ListView 行模板（共享列宽定义） |
| 排序 | 数据侧排序 + 重喂集合 |
| 高性能平铺 | ItemsRepeater + UniformGridLayout |
| 自定义流式 | ItemsRepeater + FlowLayout/自写 Layout |
| 企业级 DataGrid | 不存在于 C++/WinRT；改架构或自造（诚实评估） |

DataExplorer 的自制表格就是本章路线的成品：表头一行 Grid（4 列 2\*/\*/\*\*），行模板用同栅格 DataTemplate，数据来自 FileItem runtimeclass 的 x:Bind——没有 DataGrid 依赖也能对齐成表。运行时证据：`.smoke/17-data-explorer/tree/tap-1.png`。

---

上一篇：[19 TreeView](./19-treeview.md) ｜ 下一篇：[21 TabView 与 Expander](./21-tabview-expander.md) ｜ 返回 [目录](../README.md)
