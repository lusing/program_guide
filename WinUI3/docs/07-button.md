# 7. Button 与按钮族：动作入口

上一篇：[06 布局](./06-layout.md) ｜ 下一篇：[08 TextBlock](./08-textblock.md)

按钮是界面上"用户主动发起动作"的标准入口。本章讲 WinUI 3 里整个按钮族——Button、RepeatButton、HyperlinkButton、DropDownButton（以及 11 章的 ToggleButton）——它们的共同基类、事件模型，和四个成员各自的存在理由。示例代码来自功能工程 `examples/09-scratchpad/`（编辑器：多文档、加粗、查找、未保存确认、落盘回读）。

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

- **小工具/单窗应用**：Click 直接写，简单透明，ScratchPad 与设置中心全用这条路。
- **正经应用**：Command 让"能不能点"（`CanExecute`）和"点什么"（`Execute`）都活在 ViewModel 里，按钮退化为纯视图。Command 路线的 `IsEnabled` 会**自动跟随 CanExecute**，这是事件路线做不到的。

判断线：**逻辑要不要离开页面**。要，就走 Command。

## 7.8 实测坑位

1. **事件处理器签名写错**：XAML 编译器生成的 `Connect` 里按委托类型严格匹配，报错信息会指向生成文件而不你的代码。核对三点：参数两个、类型 `IInspectable`+`RoutedEventArgs`、返回 void。
2. **在 Click 里读 `Content()` 当按钮文字用**：能跑，但 Content 是 `IInspectable`，放的是 StackPanel 时 `as<hstring>` 直接抛。要标识"哪个按钮"，用 `sender.as<Button>().Name()`（x:Name）或 Tag。
3. **RepeatButton 处理器里做重活**：Interval=100ms 意味着处理器一秒被调 10 次，里面放任何非平凡工作都会把 UI 线程打满。重活挂异步（32.7）。
4. **HyperlinkButton 期望应用内导航**：NavigateUri 不会碰你的 Frame，别在 Click 里又写导航又设 NavigateUri。
5. **禁用按钮的可达性**：IsEnabled=False 之后屏幕阅读器跳过它。如果"为什么不能点"需要解释，更友好的做法是保持可点、点了弹 TeachingTip/ContentDialog 说明原因（25/24 章）。

## 7.9 实战：按钮的三个真实身份（ScratchPad / 设置中心）

按钮在演示页里只有一个身份（"点了报状态"）；在功能应用里它同时是**命令入口、状态镜像、可达性锚点**。ScratchPad 的保存按钮把三个身份都占全了。

### 7.9.1 一个命令，三个入口

同一个"保存"动作有三条进入路径，终点是同一个函数：

```xml
<!-- 路径一：菜单 -->
<MenuFlyoutItem Text="Save" Click="OnSave">
    <MenuFlyoutItem.KeyboardAccelerators>
        <KeyboardAccelerator Modifiers="Control" Key="S"/>
    </MenuFlyoutItem.KeyboardAccelerators>
</MenuFlyoutItem>

<!-- 路径二：命令栏 -->
<AppBarButton Icon="Save" Label="Save" Click="OnSave"/>

<!-- 路径三：根 Grid 上的全局加速器 -->
<Grid.KeyboardAccelerators>
    <KeyboardAccelerator Modifiers="Control" Key="S" Invoked="OnSaveKey"/>
</Grid.KeyboardAccelerators>
```

```cpp
void MainWindow::OnSaveKey(Input::KeyboardAccelerator const&,
    Input::KeyboardAcceleratorInvokedEventArgs const& args)
{
    args.Handled(true);        // 不再冒泡给别的处理器
    OnSave(nullptr, nullptr);  // 与按钮同一条路径
}
```

**为什么值得这么写**：菜单教用户"完整命令集在哪"，命令栏给高频动作一次点击的捷径，加速器服务键盘用户——三者共存不是冗余，是同一命令的三种可达性。而它们共用一个处理器，意味着"保存"的行为永远只有一份实现。**实测坑**：MenuFlyoutItem 的加速器槽是集合属性 `KeyboardAccelerators`（复数）——写成单数 `KeyboardAccelerator` 会在 XAML 编译期报 WMC0011。

### 7.9.2 按钮作为状态镜像

工具栏的加粗按钮（AppBarToggleButton）多一个义务：**它的选中态必须与文档的真实状态一致**。ScratchPad 的做法是任何程序化改变都回写开关：

```cpp
void MainWindow::OnBoldMenu(IInspectable const&, RoutedEventArgs const&)
{
    BoldToggle().IsChecked(true);   // 菜单入口开了加粗 → 工具栏同步点亮
    ToggleBold(true);
}
```

漏掉这一行，用户从菜单开加粗后看到工具栏仍是暗的——控件之间互相说谎，是"API demo 感"的最典型来源。

### 7.9.3 AccentButtonStyle 与视觉层级

设置中心与 ScratchPad 的主保存按钮都用 `Style="{ThemeResource AccentButtonStyle}"`（强调填充），次级动作（Reset、Next）用默认样式。**一屏最多一个强调按钮**——两个实心蓝钮并排，用户不知道回车会触发哪个。DefaultButton（ContentDialog 的 `DefaultButton(ContentDialogButton::Primary)`，24 章）是同一逻辑的键盘版：视觉强调与回车行为指向同一处。

### 7.10.1 迁移对照：从 WPF/UWP 带来的肌肉记忆

| 直觉（别处学的） | WinUI 3 现实 | 章 |
|---|---|---|
| `IsDefault`/`IsCancel`（回车/Esc 触发） | **不存在**——ContentDialog 的 DefaultButton 管回车，普通窗口自己挂 KeyDown | 24 |
| `Command` + `CanExecute` 自动禁用 | 存在但 C++/WinRT 要自己实现 `ICommand`（XamlUICommand 可带图标） | 32 |
| 按钮模板里找 `PART_*` | 默认模板没约定部件名；重模板拿 `TemplateBinding` 属性即可 | 26 |
| WPF `Style.Triggers`（IsMouseOver 换色） | 不存在——视觉态（VisualState）在模板里，改外观 = 改模板或资源 | 26 |
| UWP `Button.Click` 路由到代码后置 | 一样，但处理器**必须**在 x:Class 类里（不能挂到别的类） | 03 |

**最快上手姿势**：把 WPF 的"触发器思维"整块换成"资源/模板思维"——想改 hover 色不是加 Trigger，是覆盖 `AccentButtonStyle` 引的画刷资源或整个换 ControlTemplate。

### 7.10.2 无障碍：按钮的自动化面孔

屏幕阅读器读按钮的顺序：**AutomationProperties.Name（显式）> Content（字符串时）> x:Name（最后兜底，且常常不友好）**。图标按钮（AppBarButton Icon 无 Label）是重灾区——设置中心 BoldToggle 有 Label 兜住；纯图标按钮必配 `AutomationProperties.Name`。快速自检：跑 `inspect.exe`（Windows SDK 自带）指到按钮上看 Name 字段——它就是朗读器会念的东西。

### 7.10.3 按钮的视觉状态家族

ButtonBase 模板内部维护六个 VisualState（Normal/PointerOver/Pressed/Disabled + Focus）：你不动它们时一切自动；**换模板时六个都得给**（缺 PointerOver 会在悬停时"死色"）。ThemeResource 的意义正在此——默认模板的悬停色是 `{ThemeResource ButtonBackgroundPointerOver}`，**覆盖资源键就能换悬停色而不用碰模板**，这是 26 章"改资源优于改模板"的直接理由。

## 7.11 练习与思考

1. 把 ScratchPad 的 Bold 入口从三处（菜单/命令栏/Ctrl+B）删掉一处，观察哪个用户群体受伤害最大——然后用一段话把这个判断写成设计决策记录。
2. 给设置中心的 Save appearance 按钮实现"保存中"状态：点击后禁用 360ms（协程），期间文本换 "Saving..."。哪些入口要同步禁用？（提示：不止按钮）
3. RepeatButton 的 Interval=100ms 意味着处理器每秒 10 次——设计一个"按住加速滚动"的用法，并说出你会怎么防止它把 UI 线程打满。

## 7.10 小结

| 成员 | 一句话定位 | 关键属性/事件 |
|------|-----------|--------------|
| Button | 通用动作入口 | Click、Content、IsEnabled、Command |
| RepeatButton | 按住持续触发 | Delay、Interval |
| HyperlinkButton | 离开应用 | NavigateUri（系统打开） |
| DropDownButton | 附带菜单暗示 | Flyout（自动开合） |
| ToggleButton（11 章） | 状态切换入口 | IsChecked |

运行时证据：`.smoke/09-scratchpad/save/tap-2.png`——编辑器里输入 hello scratchpad 后按 Ctrl+S（页面级 KeyboardAccelerator，与 "Save" 按钮同一条代码路径），状态行变 **"saved untitled-1.txt | verified on disk (15 chars)"**；`examples/09-scratchpad/MainWindow.xaml.cpp` 的 `OnSave`/`OnSaveKey` 两个入口共用一个实现。

---

上一篇：[06 布局](./06-layout.md) ｜ 下一篇：[08 TextBlock](./08-textblock.md) ｜ 返回 [目录](../README.md)
