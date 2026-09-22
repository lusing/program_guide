# 7. Button 与按钮族：动作入口

上一篇：[06 布局](./06-layout.md) ｜ 下一篇：[08 TextBlock](./08-textblock.md)

按钮是界面上"用户主动发起动作"的标准入口。本章讲 WinUI 3 里整个按钮族——Button、RepeatButton、HyperlinkButton、DropDownButton（以及 11 章的 ToggleButton）——它们的共同基类、事件模型，和四个成员各自的存在理由。示例代码全部来自画廊工程 `examples/07-controls-basic/` 的 `ButtonPage`（左侧导航 **Button** 项）。

## 7.1 按钮族的家谱：ButtonBase

WinUI 3 的按钮类共享一个基类 `ButtonBase`（在 `Microsoft.UI.Xaml.Controls.Primitives` 命名空间）：

```text
ButtonBase
├── Button              普通按钮：点一下，触发一次 Click
├── RepeatButton        按住不放，连续触发 Click
├── HyperlinkButton     链接外观的按钮：NavigateUri 打开外部目标
├── DropDownButton      自带下拉 Flyout 的按钮
└── ToggleButton        两态/三态按钮（11 章专讲）
        └── CheckBox    复选框（10 章专讲，继承 ToggleButton）
```

基类给了它们统一的骨架：

- **`Click` 事件**：核心交互，签名固定为 `(IInspectable const& sender, RoutedEventArgs const& args)`
- **`Content`**：按钮上显示的内容，类型是 `IInspectable`——通常是字符串，但可以是任意 UIElement（图标+文字的 StackPanel 都行）
- **`Command`**：MVVM 里替代 Click 的命令入口（32.6 节）
- **`IsEnabled`**（来自更上层的 `Control`）：禁用态，灰显且不再响应点击

理解这个家谱的实用价值：**你在一个成员上学到的事件模型、Content 用法、禁用语义，对全族通用**。差异只在每个成员"多出来的一件事"。

## 7.2 Button：最普通的动作入口

XAML（ButtonPage.xaml）：

```xml
<Button Content="Click me" Click="OnMainClick"/>
<Button Content="Disabled on purpose" IsEnabled="False"/>
```

代码（ButtonPage.xaml.cpp）：

```cpp
void ButtonPage::OnMainClick(IInspectable const&, RoutedEventArgs const&)
{
    ++m_mainCount;
    StatusText().Text(L"clicked " + winrt::to_hstring(m_mainCount));
}
```

三个要点：

1. **按名字挂接的事件处理器不需要进 IDL**。`Click="OnMainClick"` 在 XAML 编译时被解析成对实现类成员函数的调用（`Connect` 查表，见 [03 篇 3.3](./03-xaml.md)）；只有 `x:Bind` 路径上的成员才必须声明在 IDL 里。这是 04 篇实测结论的反复适用。
2. **事件签名是固定的**：`void OnX(IInspectable const& sender, RoutedEventArgs const& args)`。`sender` 是控件本体，需要时 `sender.as<Button>()` 取回。参数不想要可以不命名（如上），但类型必须写对——写错的话 XAML 编译器会在生成的 `Connect` 里报出委托不匹配。
3. **`Content` 装箱的是 hstring**。读回时 `button.Content().as<winrt::hstring>()`；如果你放的是别的类型，`as<T>` 会抛异常，装什么取什么。

### Content 不只能是文字

```xml
<Button Click="OnAddClicked">
    <StackPanel Orientation="Horizontal" Spacing="8">
        <FontIcon Glyph="&#xE710;"/>
        <TextBlock Text="Add task"/>
    </StackPanel>
</Button>
```

图标（`FontIcon`，23 章展开）加文字是工具栏按钮的标准做法。这也是"按钮族共享 Content"的直接红利：RepeatButton、DropDownButton 同样吃这套写法。

## 7.3 Click 的机制：路由事件的终点

`Click` 是路由事件（03 篇 3.4 讲过路由链）。对按钮来说实践上只需要知道两件事：

- **默认只有直接挂处理器的那个按钮会响应**——`Click` 的路由策略是 Bubbling，但按钮场景下子元素点击会被控件模板统一收编成一次 Click，不会误伤。
- **键盘触发也算 Click**：焦点在按钮上按空格/回车会触发同一个事件。所以处理器里不该假设"一定来自鼠标"——这通常是免费的正确性，除非你在 args 里找鼠标坐标（`RoutedEventArgs` 里没有，别找）。

## 7.4 RepeatButton：按住不放

```xml
<RepeatButton Content="Hold me" Delay="300" Interval="100" Click="OnRepeatClick"/>
```

```cpp
void ButtonPage::OnRepeatClick(IInspectable const&, RoutedEventArgs const&)
{
    ++m_repeatCount;
    StatusText().Text(L"repeat " + winrt::to_hstring(m_repeatCount)
        + L" (hold to keep firing)");
}
```

`RepeatButton` 多出来的两个属性（均为 `Int32` 依赖属性，成员形状对照本机 1.8 元数据核对过）：

| 属性 | 含义 | 默认值 |
|------|------|--------|
| `Delay` | 按下后第一次重复触发前的等待（毫秒） | 500（文档值） |
| `Interval` | 后续重复的间隔（毫秒） | 250（文档值） |

> **诚实边界**：`Delay`/`Interval` 的**默认值**不在 `.winmd` 元数据里（元数据只记属性存在与类型 Int32），500/250 是文档站数值，本章未做运行时测量。属性存在性与 Int32 类型是元数据级证据。

典型用途：数值微调的 +/-、滚动条两端——一切"按住持续生效"的场景。注意它仍然是 Click 事件，处理器无法区分"第一次"还是"重复"（要区分就自己数，或用普通 Button + 定时器）。

## 7.5 HyperlinkButton：走出应用

```xml
<HyperlinkButton Content="Open WinUI docs"
                 NavigateUri="https://learn.microsoft.com/windows/apps/winui/"/>
```

`NavigateUri` 的语义是**交给系统打开**（默认浏览器），不是应用内导航。这是新手常见误解的根源：

| 想要的效果 | 用什么 |
|-----------|--------|
| 打开外部网页 / mailto: | `HyperlinkButton.NavigateUri` |
| 应用内切页面 | 事件处理器里 `Frame().Navigate(xaml_typename<XxxPage>())`（22 章） |
| 界面里嵌富文本内联链接 | `TextBlock` + `Hyperlink` 元素（08 章） |

> **运行时验证边界**：点击它会真的弹出浏览器——ui-smoke 的合成点击驱动不了系统级窗口，因此本页的冒烟验证覆盖 Click/Repeat/DropDown 路径，HyperlinkButton 只验证了渲染与签名（`NavigateUri` 接受 `Windows.Foundation.Uri`）。

`HyperlinkButton` 也有 `Click` 事件；两个都设时 **Click 优先**（Click 挂了处理器就不再自动导航）。

## 7.6 DropDownButton：按钮 + Flyout

```xml
<DropDownButton Content="Export as">
    <DropDownButton.Flyout>
        <MenuFlyout>
            <MenuFlyoutItem Text="PDF" Click="OnExportKind"/>
            <MenuFlyoutItem Text="Markdown" Click="OnExportKind"/>
            <MenuFlyoutItem Text="Plain text" Click="OnExportKind"/>
        </MenuFlyout>
    </DropDownButton.Flyout>
</DropDownButton>
```

```cpp
void ButtonPage::OnExportKind(IInspectable const& sender, RoutedEventArgs const&)
{
    // 事件 sender 是菜单项本体：MenuFlyoutItem.Text() 读回点的是哪一项
    auto item = sender.as<MenuFlyoutItem>();
    StatusText().Text(L"export = " + item.Text());
}
```

DropDownButton（1.8 元数据确认存在：`Microsoft.UI.Xaml.Controls.DropDownButton`，实现空的标记接口 `IDropDownButton`，成员全部继承自 ButtonBase）做的事情只有一件：**点击时自动打开你挂在 `Flyout` 属性上的浮层**。它和"Button + 手动挂 Flyout"的区别：

| 写法 | 行为 |
|------|------|
| `<Button><Button.Flyout><MenuFlyout/></Button.Flyout></Button>` | 点击打开 Flyout（普通 Button 也支持！） |
| `<DropDownButton>` | 同上，但**视觉上多一个下拉箭头**，向用户暗示"这里有菜单" |

所以选择标准是**语义表达**而不是能力：要让用户预期到下拉，用 DropDownButton；Flyout 只是辅助说明（比如"详情"弹卡片），普通 Button 加 Flyout 就够。菜单本身的构造（MenuFlyoutItem/ToggleMenuFlyoutItem/RadioMenuFlyoutItem）在 23 章展开。

## 7.7 Click 还是 Command？

按钮触发动作有两条路（32.6 节是完整版）：

```xml
<!-- 路线一：事件处理器（code-behind） -->
<Button Content="Save" Click="OnSaveClicked"/>

<!-- 路线二：命令绑定（MVVM） -->
<Button Content="Save" Command="{x:Bind ViewModel.SaveCommand}"/>
```

- **小工具/演示页**：Click 直接写，简单透明，本画廊全用这条路。
- **正经应用**：Command 让"能不能点"（`CanExecute`）和"点什么"（`Execute`）都活在 ViewModel 里，按钮退化为纯视图。Command 路线的 `IsEnabled` 会**自动跟随 CanExecute**，这是事件路线做不到的。

判断线：**逻辑要不要离开页面**。要，就走 Command。

## 7.8 实测坑位

1. **事件处理器签名写错**：XAML 编译器生成的 `Connect` 里按委托类型严格匹配，报错信息会指向生成文件而不你的代码。核对三点：参数两个、类型 `IInspectable`+`RoutedEventArgs`、返回 void。
2. **在 Click 里读 `Content()` 当按钮文字用**：能跑，但 Content 是 `IInspectable`，放的是 StackPanel 时 `as<hstring>` 直接抛。要标识"哪个按钮"，用 `sender.as<Button>().Name()`（x:Name）或 Tag。
3. **RepeatButton 处理器里做重活**：Interval=100ms 意味着处理器一秒被调 10 次，里面放任何非平凡工作都会把 UI 线程打满。重活挂异步（32.7）。
4. **HyperlinkButton 期望应用内导航**：NavigateUri 不会碰你的 Frame，别在 Click 里又写导航又设 NavigateUri。
5. **禁用按钮的可达性**：IsEnabled=False 之后屏幕阅读器跳过它。如果"为什么不能点"需要解释，更友好的做法是保持可点、点了弹 TeachingTip/ContentDialog 说明原因（25/24 章）。

## 7.9 小结

| 成员 | 一句话定位 | 关键属性/事件 |
|------|-----------|--------------|
| Button | 通用动作入口 | Click、Content、IsEnabled、Command |
| RepeatButton | 按住持续触发 | Delay、Interval |
| HyperlinkButton | 离开应用 | NavigateUri（系统打开） |
| DropDownButton | 附带菜单暗示 | Flyout（自动开合） |
| ToggleButton（11 章） | 状态切换入口 | IsChecked |

画廊 `ButtonPage` 的运行时证据：`.smoke/07-controls-basic/button/click-2.png`——导航切到 Button 页后点击 "Click me"，状态行由 "Ready" 变为 **"clicked 1"**。

---

上一篇：[06 布局](./06-layout.md) ｜ 下一篇：[08 TextBlock](./08-textblock.md) ｜ 返回 [目录](../README.md)
