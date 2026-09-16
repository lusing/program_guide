# 05 · 核心控件与路由事件

> 对应示例：`examples/02_binding`（复用）、`examples/09_navigation`

## 1. 控件家族：按"能装什么"分类

WPF 控件不是按外观分类，而是按**内容模型**分类——这才是它们的本质差异：

| 家族 | 基类 | Content 是什么 | 代表 |
|---|---|---|---|
| 内容控件 | `ContentControl` | **一个**任意对象 | Window、Button、Label、CheckBox |
| 条目控件 | `ItemsControl` | **一组**对象（Items） | ListBox、Menu、ComboBox、StatusBar |
| 带头内容控件 | `HeaderedContentControl` | Content + Header | GroupBox、Expander |
| 文本控件 | `TextBox`/`TextBlock` | 字符串（专用） | — |

"内容是任意对象"是 WPF 与 WinForms 的分水岭：

```xml
<Button>
    <StackPanel Orientation="Horizontal">
        <Ellipse Width="12" Height="12" Fill="Green"/>
        <TextBlock Text=" 在线" Margin="4,0,0,0"/>
    </StackPanel>
</Button>
```

按钮里装一棵 UI 子树完全合法。更妙的是内容可以是**非 UI 对象**：`ListBox.Items` 装一堆 `Person`，条目会通过模板决定怎么显示（默认 ToString，配 DataTemplate 才是正途——第 08 章）。

`TextBlock` 和 `Label` 的区别常被问起：TextBlock 是轻量文本显示（不支持访问键、不可聚焦），Label 是 ContentControl（支持 `_` 访问键指向目标控件）。显示静态文字用 TextBlock。

## 2. 输入控件速览

`02_binding` 示例里已经出现两个：

```xml
<TextBox x:Name="NameEntry" Text="Alice" Margin="0,0,0,12" />
<Slider x:Name="ValueSlider" Minimum="0" Maximum="100" Value="60" Margin="0,0,0,12" />
```

常用输入控件的"关键属性"清单：

| 控件 | 关键属性 | 关键事件 |
|---|---|---|
| `TextBox` | Text、AcceptsReturn、TextWrapping | TextChanged |
| `CheckBox`/`RadioButton` | IsChecked(bool?)、GroupName | Checked/Unchecked |
| `Slider` | Minimum/Maximum/Value | ValueChanged |
| `ComboBox` | ItemsSource、SelectedValue | SelectionChanged |
| `ListBox` | ItemsSource、SelectedItem | SelectionChanged |

`IsChecked` 是 `bool?`（三态）不是 bool——绑定和判断时留意。

## 3. 路由事件：事件沿树传播

`Click` 不是普通事件，是**路由事件**：它沿可视化树传播，途经的每个元素都有机会处理。三个方向：

| 路由 | 命名 | 传播方向 | 例子 |
|---|---|---|---|
| 冒泡 | 普通 | 子 → 根 | `Click`、`MouseDown` |
| 隧道 | `Preview` 前缀 | 根 → 子 | `PreviewMouseDown` |
| 直接 | 普通 | 只到目标 | `TextBox.TextChanged` |

实用推论：**在容器上处理所有子元素的事件**。一个 ListView 想响应双击，不必给每个条目挂钩子：

```xml
<ListBox MouseDoubleClick="List_DoubleClick">...</ListBox>
```

双击发生在条目上，事件冒泡到 ListBox，处理函数照常触发，`sender` 是 ListBox、`e.OriginalSource` 才是真正被点的元素——**sender 是挂载点，OriginalSource 是事件源头**，两个都看才能写对逻辑。

`e.Handled = true` 会把路由截停。隧道事件（Preview\*）永远先于配对的冒泡事件触发，且隧道里标记 Handled 会连带压制冒泡——拦截输入（比如屏蔽粘贴）用 Preview 系列。

## 4. 事件与命令的边界

前一章说过事件把界面和逻辑焊死，但不是所有事件都该被消灭。分工：

- **"用户下了指令"**（点击、菜单）→ 命令（第 07 章），因为命令带 CanExecute 自动置灰、可被多入口共享
- **"用户在做操作过程"**（拖动、选择变化、双击某行）→ 事件，保持薄处理函数，转发给 ViewModel 或服务

判断口诀：能想出对应"动词"的用命令，描述"状态变化"的用事件。

## 5. ItemsControl：列表的骨架

所有列表控件的基类 `ItemsControl` 只做一件事：**把 Items 里每个对象变成一个条目容器**。`ListBox` 加了选中与滚动，`DataGrid` 加了列。最小用法：

```xml
<ListBox ItemsSource="{Binding Files}"/>
```

`ItemsSource` 指向 `ObservableCollection<string>` 时，集合增删自动刷新界面（要求集合是 ObservableCollection，普通 List 不会通知——第 06 章细讲）。第 12 章实战的"最近文件"菜单就是这个机制的变体。

## 6. 常见坑

**在事件里写业务逻辑**：`Click` 里算账、存库——三个月后这个函数 300 行没法测试。事件函数只做"翻译"：取参数 → 调用逻辑。

**搞混 sender 和 OriginalSource**：在容器上挂路由事件后，`sender as FrameworkElement` 拿到的是容器；要拿被点的子元素用 `e.OriginalSource`，而且它可能是模板内部的元素（如 Border），需要向上 `ItemsControl.ContainerFromElement` 找条目。

**RadioButton 不互斥**：同一个逻辑组必须同 `GroupName` 或同一个直接父容器，跨容器分组只认 GroupName。

**TextBox.TextChanged 不是路由事件**：它是普通 .NET 事件（直接路由），不能在容器上统一处理；批量监听输入用绑定 + `UpdateSourceTrigger=PropertyChanged`（第 06 章）。

**订阅了没退订**：长生命周期对象（如 Application 级服务）订阅短生命周期控件的事件会造成内存泄漏。反向（窗口订阅服务）时记得在 `Closed` 里退订。

## 7. 实战建议

- 条目控件优先 `ItemsSource` 数据驱动，**别手工 `Items.Add` 混合数据绑定**——两条路同时走会互相打架
- 列表行级交互（双击、右键）挂容器级路由事件，条目模板保持无代码
- 自定义"看起来复杂"的控件前先问：Content 模型 + DataTemplate（第 08 章）能不能解决？九成场景不用写自定义控件类
- `ToolTip`、`ContextMenu` 是 Content 模型的免费赠品，优先使用

---
上一章：[04 布局系统](04-layout.md) ｜ 下一章：[06 数据绑定](06-binding.md)
