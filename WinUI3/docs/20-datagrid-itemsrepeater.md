# 20. 表格数据：DataGrid 缺位与自制

上一篇：[19 TreeView](./19-treeview.md) ｜ 下一篇：[21 TabView 与 Expander](./21-tabview-expander.md)

本章与其他控件章不同：它讲一个**不存在的东西**——C++/WinRT 的 DataGrid——以及在没有它的世界里怎么把表格做出来。结论先行：**CommunityToolkit 的 DataGrid 用不了，自制 = Grid 表头 + ListView 行 + ItemsRepeater 高性能场景**。示例来自画廊工程的 `TablePage`（导航 **Table** 项）。

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

## 20.5 小结

| 场景 | 做法 |
|------|------|
| 只读表格 | Grid 表头 + ListView 行模板（共享列宽定义） |
| 排序 | 数据侧排序 + 重喂集合 |
| 高性能平铺 | ItemsRepeater + UniformGridLayout |
| 自定义流式 | ItemsRepeater + FlowLayout/自写 Layout |
| 企业级 DataGrid | 不存在于 C++/WinRT；改架构或自造（诚实评估） |

画廊 `TablePage` 运行时证据：`.smoke/17-controls-collections/table/click-2.png`——点击首行，状态行 **"row = write guide"**，表头与数据列对齐，T1–T8 瓷砖正常平铺。

---

上一篇：[19 TreeView](./19-treeview.md) ｜ 下一篇：[21 TabView 与 Expander](./21-tabview-expander.md) ｜ 返回 [目录](../README.md)
