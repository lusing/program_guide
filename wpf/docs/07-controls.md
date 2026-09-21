# 07 · 核心控件一览

> 对应示例：`examples/07_controls_gallery`（控件画廊，事件汇到底部状态栏）

> **本章你将学会**：按内容模型理解控件家族、常用控件的属性与事件速查、控件选型直觉。
> **前置章节**：[03 XAML 基础](03-xaml-basics.md)、[05 布局](05-layout.md)。

## 1. 控件家族：按"能装什么"分类

WPF 控件不是按外观分类，而是按**内容模型**分类——这才是它们的本质差异：

| 家族 | 基类 | 装什么 | 代表 |
|---|---|---|---|
| 内容控件 | `ContentControl` | **一个**任意对象 | Window、Button、Label、CheckBox、RadioButton |
| 条目控件 | `ItemsControl` | **一组**对象（Items） | ListBox、ComboBox、Menu、TabControl、StatusBar |
| 带头内容控件 | `HeaderedContentControl` | Content + Header | GroupBox、Expander、TabItem |
| 文本控件 | `TextBoxBase` | 字符串（专用） | TextBox、RichTextBox |
| 纯展示 | — | — | TextBlock、Image、ProgressBar、Slider |

"内容是任意对象"（第 03 章伏笔）是 WPF 与 WinForms 的分水岭：

```xml
<Button>
    <StackPanel Orientation="Horizontal">
        <Ellipse Width="12" Height="12" Fill="Green"/>
        <TextBlock Text=" 在线" Margin="4,0,0,0"/>
    </StackPanel>
</Button>
```

按钮里装一棵 UI 子树完全合法；更妙的是内容可以是**非 UI 对象**——`ListBox` 装一堆 `Person`，条目按 DataTemplate 渲染（第 15 章兑现）。选控件时先问"我要装一个还是一组"，家族就定了。

**TextBlock 与 Label 的区别**（高频问题）：TextBlock 轻量、只管显示文字，不可聚焦、不支持访问键；Label 是 ContentControl，支持 `_文件` 式访问键（`Target` 属性指向输入控件，Alt+F 聚焦）。静态文字一律 TextBlock，表单标签用 Label + 访问键。

## 2. 输入与选择控件速查

`07_controls_gallery` 把常用控件摆成一个画廊，每个控件的事件都汇到底部状态栏——建议边运行边对照本表：

| 控件 | 关键属性 | 关键事件 | 备注 |
|---|---|---|---|
| `TextBox` | Text、AcceptsReturn、TextWrapping、MaxLength | TextChanged | 多行 = AcceptsReturn + TextWrapping + 滚动 |
| `PasswordBox` | Password | PasswordChanged | 出于安全不给绑定属性，只能事件读（第 10 章坑） |
| `CheckBox` | IsChecked（**bool?** 三态）、IsThreeState | Checked/Unchecked | 三态对应"全选框的不确定态" |
| `RadioButton` | GroupName、IsChecked | Checked | 同组互斥：同容器或同 GroupName |
| `ComboBox` | ItemsSource、SelectedItem、IsEditable | SelectionChanged | IsEditable=True 变可输入下拉 |
| `ListBox` | ItemsSource、SelectedItem、SelectionMode | SelectionChanged | 多选用 SelectionMode=Extended |
| `Slider` | Minimum、Maximum、Value、TickFrequency | ValueChanged | IsSnapToTickEnabled 吸附刻度 |
| `ProgressBar` | Minimum、Maximum、Value、IsIndeterminate | — | IsIndeterminate=true 转圈式"忙" |

`IsChecked` 是 `bool?` 不是 bool——绑定和判断时留意（`== true` 判断、null 是第三态）。示例里 CheckBox 触发的事件名显示在状态栏，勾/取消/置灰三态各触发一次事件，可以直接感受。

## 3. 展示与容器型控件

| 控件 | 用途 | 关键点 |
|---|---|---|
| `GroupBox` | 带标题的分组框 | Header + Content；表单分区 |
| `Expander` | 可折叠面板 | IsExpanded 控制开合；放次要选项 |
| `TabControl` | 页签容器 | 每页一个 TabItem；设置界面标配 |
| `ToolTip` | 悬停提示 | 任意控件 `ToolTip="..."` 即挂；内容也可以是复杂树 |
| `ContextMenu` | 右键菜单 | 挂在任意控件上；与 Menu 同一套 MenuItem |
| `Image` | 图片 | Source 指 BitmapImage；路径要 pack URI 或绝对路径 |
| `Menu`/`StatusBar` | 菜单栏/状态栏 | 里面是 MenuItem/StatusBarItem |

ToolTip 值得一提：它不是属性里的字符串，而是一个弹出的 ContentControl——`<Button.ToolTip><StackPanel>…复杂内容…</StackPanel></Button.ToolTip>` 完全合法，第 16 章就用它显示验证错误列表。

## 4. ItemsControl：一切列表的骨架

所有列表控件的基类 `ItemsControl` 只做一件事：**把 Items 里每个对象生成一个条目容器**。`ListBox` 在其上加"选中"，`ComboBox` 加"收起"，`DataGrid` 加"列"，`TreeView` 加"层级"（第 18 章）。数据驱动的标准用法：

```xml
<ListBox ItemsSource="{Binding Cities}"/>
<!-- Cities 是 ObservableCollection<string> 时，增删自动刷新界面（第 10 章） -->
```

条目怎么显示由 `ItemTemplate`（第 15 章）决定；默认对 string 直接显示，对自定义对象显示 ToString()。**两条铁律**：

1. 数据驱动就纯数据驱动——别 `Items.Add()` 手工条目和 `ItemsSource` 混用（后者一赋值前者全清空）
2. 条目级交互（双击、右键）挂容器级路由事件（第 08 章），模板保持无代码

## 5. 控件选型决策

几个高频纠结，给结论：

- **CheckBox 还是ToggleButton**：语义是"设置项"用 CheckBox，语义是"当前模式开关"（如编辑/预览）用 ToggleButton
- **ComboBox 还是 ListBox**：选项 ≤5 且都要可见用 RadioButton/ListBox；选项多或省空间用 ComboBox
- **Slider 还是 TextBox**：范围连续且精确值不重要用 Slider；要精确输入用 TextBox（必要时配验证，第 16 章）
- **MessageBox 还是状态栏**：需要用户必须看到的用 MessageBox 打断；提示类信息放状态栏/通知区，不打断（第 22 章）

控件外观不合心意时，先想**样式/触发器**（第 13、14 章）能不能解决，再想**模板重写**（第 15 章），最后才是自定义控件——九成需求到不了第三步。

## 6. 常见坑

**IsChecked 判断 null**：`if (cb.IsChecked)` 编译不过（bool? 不能隐式转 bool）——用 `== true`。绑定时目标也必须是 bool? 或配转换器。

**RadioButton 跨容器不互斥**：同一个 GroupName 才是一组；不同 StackPanel 里的同名组依旧互斥，反之同容器无名也互斥（按视觉树就近分组）。

**PasswordBox 无绑定**：Password 是普通属性且不实现 INPC，`{Binding Password}` 无效且不安全。用 PasswordChanged 事件取值（示例画廊的做法）。

**ComboBox 直接显示对象类型名**：ItemsSource 装自定义对象时条目显示 `MyApp.Person`——ToString 没重写或没配 DisplayMemberPath/ItemTemplate。

**Menu/StatusBar 挤成一团**：它们是 ItemsControl，直接子元素应是 MenuItem/StatusBarItem；塞 TextBlock 进 StatusBar 没有分隔样式。

## 7. 实战建议

- 控件画廊示例可以直接当**选型参考手册**用：做界面前跑一遍，找到最接近的再回来查属性表
- 关键属性记"语义"而不是背全：IsChecked（状态）、SelectedItem（当前选谁）、ItemsSource（数据从哪来）——属性名在 WPF 里高度一致
- 输入类控件的"内容对齐"交给布局章的工具（SharedSizeGroup），不要用空格凑
- 每类控件先用默认行为，确认不够再上样式——默认模板对键盘/无障碍的处理是你手写容易漏的

## 自测

1. **ContentControl 与 ItemsControl 的本质区别？** —— 装一个任意对象 vs 装一组对象再批量生成条目。
2. **CheckBox.IsChecked 是什么类型？为什么？** —— bool?（三态）：true/false/null，配 IsThreeState 表达"部分选中"。
3. **RadioButton 怎样才算一组？** —— 同一直接父容器，或显式同 GroupName（跨容器也能互斥）。
4. **TextBlock 和 Label 各适合什么场景？** —— 静态文字用轻量 TextBlock；表单标签要访问键用 Label + Target。

---
上一章：[06 布局实战](06-layout-lab.md) ｜ 下一章：[08 路由事件](08-routed-events.md)
