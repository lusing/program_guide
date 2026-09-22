# 6. 布局：Grid / StackPanel / Border / RelativePanel

布局要回答的问题不是"有哪些容器"，而是：页面有哪些区域、区域怎么伸缩、内容放不下怎么办。本篇过一遍五个主力容器，最后给一个真实页面布局的完整例子。

选型速查：

| 容器 | 排布方式 | 典型场景 |
|------|---------|---------|
| `StackPanel` | 顺序堆叠（横/竖） | 表单、工具栏按钮组 |
| `Grid` | 行列网格 | 页面主结构、表单分区——**大多数情况的首选** |
| `Border` | 单容器 + 边框/背景/圆角 | 卡片、区域包裹（不负责多子元素排布） |
| `RelativePanel` | 元素间相对定位 | 小范围微布局 |
| `ScrollViewer` | 内容超出时滚动 | 长表单、长内容 |

## 6.1 StackPanel：顺序排列

```xml
<StackPanel Orientation="Vertical" Spacing="12">
    <TextBlock Text="Create task" FontSize="24" />
    <TextBox Header="Title" PlaceholderText="Enter task name" />
    <TextBox Header="Description" PlaceholderText="Optional notes" />
    <Button Content="Add task" HorizontalAlignment="Right" />
</StackPanel>
```

- `Orientation` 默认纵向；`Spacing` 控制子元素间距
- 子元素按内容大小排列，`StackPanel` 自身高度可以无限增长——**放在需要受高度约束的地方（如窗口底部）要小心**，它不会主动压缩子元素，内容溢出时直接被裁剪

## 6.2 Grid：主力布局

`Grid` 是二维网格：先定义行列，再把子元素放进格子。

```xml
<Grid ColumnSpacing="12" RowSpacing="12">
    <Grid.RowDefinitions>
        <RowDefinition Height="Auto" />
        <RowDefinition Height="*" />
    </Grid.RowDefinitions>

    <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*" />
        <ColumnDefinition Width="220" />
    </Grid.ColumnDefinitions>

    <TextBox Grid.Row="0" Grid.Column="0" Header="New task" />
    <Button Grid.Row="0" Grid.Column="1" Content="Add" VerticalAlignment="Bottom" />

    <ListView Grid.Row="1" Grid.Column="0" Grid.ColumnSpan="2" />
</Grid>
```

尺寸定义的三种值，含义必须分清：

| 值 | 含义 |
|----|------|
| `Auto` | 由内容决定 |
| 固定值（如 `220`） | 像素固定，不随窗口缩放 |
| `*`（星号） | 按比例分剩余空间；`2*` 是 `*` 的两倍 |

上面例子的读法：第一行 `Auto` 高度由输入框决定；第二行 `*` 吃掉所有剩余高度给列表；第二列固定 220px 给按钮，第一列 `*` 弹性伸缩。`Grid.ColumnSpan="2"` 让列表横跨两列。

**页面主结构一律用 Grid**：它对窗口缩放、内容增减的行为最可预测。

## 6.3 Border：区域包裹层

`Border` 只有一个子元素，职责是"给一块区域加上外观"：

```xml
<Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}"
        CornerRadius="8"
        Padding="12"
        BorderThickness="1"
        BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}">
    <StackPanel Spacing="8">
        <TextBlock Text="Quick actions" FontWeight="SemiBold" />
        <Button Content="Open" />
        <Button Content="Save" />
    </StackPanel>
</Border>
```

注意颜色来自 `ThemeResource`（卡片背景/描边）而不是硬编码——这样深浅色主题自动适配（主题机制见 [33 篇](./33-theming-packaging.md)）。

## 6.4 RelativePanel：相对定位

适合"这个在那个右边、贴住底边"这类关系布局：

```xml
<RelativePanel Width="400" Height="120">
    <TextBlock x:Name="TitleText" Text="Settings" FontSize="32" />
    <Button Content="Save"
            RelativePanel.RightOf="TitleText"
            RelativePanel.AlignBottomWith="TitleText" />
</RelativePanel>
```

引用其他元素要用 `x:Name`。小范围好用，但关系一多就是面条——复杂结构仍回 Grid。

## 6.5 ScrollViewer：内容溢出时滚动

```xml
<ScrollViewer>
    <StackPanel Spacing="12">
        <TextBox Header="Name" />
        <TextBox Header="Email" />
        <TextBox Header="Address" />
        <Button Content="Submit" />
    </StackPanel>
</ScrollViewer>
```

它解决的是"内容比视口大"，不是布局本身。注意 `ScrollViewer` 只能有一个直接子元素——里面通常包一个 StackPanel 或 Grid。

## 6.6 真实页面：任务管理主界面

把容器组合起来，看一个典型的主界面结构：

```xml
<Grid>
    <Grid.ColumnDefinitions>
        <ColumnDefinition Width="220" />
        <ColumnDefinition Width="*" />
    </Grid.ColumnDefinitions>

    <!-- 左侧：菜单区，Border 包出卡片感 -->
    <Border Grid.Column="0"
            Background="{ThemeResource LayerFillColorDefaultBrush}"
            Padding="12">
        <StackPanel Spacing="8">
            <TextBlock Text="Menu" FontSize="20" />
            <Button Content="Tasks" HorizontalContentAlignment="Left" />
            <Button Content="Calendar" HorizontalContentAlignment="Left" />
            <Button Content="Settings" HorizontalContentAlignment="Left" />
        </StackPanel>
    </Border>

    <!-- 右侧：主内容区，纵向 Grid 再分区 -->
    <Grid Grid.Column="1" Padding="12" RowSpacing="12">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
        </Grid.RowDefinitions>

        <!-- 输入区：一行内输入框 + 按钮，用横向 Grid 对齐 -->
        <Grid ColumnSpacing="8">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="Auto" />
            </Grid.ColumnDefinitions>
            <TextBox Grid.Column="0" Header="Add task"
                     PlaceholderText="What do you want to do?" />
            <Button Grid.Column="1" Content="Add" VerticalAlignment="Bottom" />
        </Grid>

        <!-- 列表区吃掉剩余空间 -->
        <ListView Grid.Row="1" />
    </Grid>
</Grid>
```

这段结构的读法（也是布局设计的通用套路）：

1. **先切大区**：外层 Grid 按列切出"侧栏 + 主区"
2. **大区内部再切**：主区按行切出"输入区 + 列表区"
3. **小范围对齐**用局部 Grid/StackPanel 解决
4. **外观**交给 Border，**弹性**交给 `*`，**固定**留给侧栏/工具栏

## 6.7 布局思想总结

背容器定义没有意义，要建立的是选型判断：

- 垂直/水平堆一串 → `StackPanel`
- 页面结构、区域划分 → `Grid`（先大区，再层层细分）
- 一块区域的外观 → `Border`
- 元素间的相对关系 → `RelativePanel`
- 内容放不下 → `ScrollViewer`

以及一条纪律：**布局容器只管布局**。数据、状态、事件不放进布局讨论——它们属于 ViewModel 和事件链（[05](./05-project-structure.md)、[32](./32-binding-mvvm.md) 篇）。

---

下一篇：[07 控件篇](./07-button.md)
