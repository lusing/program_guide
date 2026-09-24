# 23. CommandBar 与菜单

上一篇：[22 NavigationView](./22-navigationview.md) ｜ 下一篇：[24 ContentDialog 与 Flyout](./24-dialogs-flyouts.md)

命令的三个层次：常驻工具条（CommandBar）、菜单栏/上下文菜单（MenuBar/MenuFlyout）、以及它们共用的图标体系。示例代码来自功能工程 `examples/09-scratchpad/`（编辑器：多文档、加粗、查找、未保存确认、落盘回读）。

## 23.1 CommandBar：主命令与溢出

```xml
<CommandBar DefaultLabelPosition="Right" IsOpen="False">
    <AppBarButton Icon="Add" Label="Add" Click="OnAddClicked"/>
    <AppBarButton Icon="Save" Label="Save" Click="OnSaveClicked"/>
    <AppBarSeparator/>
    <AppBarToggleButton Icon="Favorite" Label="Pin" Click="OnPinClicked"/>
    <CommandBar.SecondaryCommands>
        <AppBarButton Icon="Setting" Label="Settings" Click="OnSettingsClicked"/>
    </CommandBar.SecondaryCommands>
</CommandBar>
```

- **`PrimaryCommands`**（直接子元素）：常驻可见。**`SecondaryCommands`**：收进 "..." 溢出菜单——放低频命令，别把主命令挤没了。
- `AppBarButton` / `AppBarToggleButton`（两态，11 章 ToggleButton 的命令栏形态）/ `AppBarSeparator`。
- `Icon` 是 `IconElement` 家族：`Symbol`（枚举速记，如 Add/Save/Setting）/ `FontIcon`（Glyph 码）/ `BitmapIcon`（图片）。图标码是 Segoe Fluent Icons 字体。
- `DefaultLabelPosition`（Right/Bottom/Collapsed）控制标签位置；窄窗口会自动只显图标。
- `Command=` 绑定（7 章预告、32 章展开）是 MVVM 路线，Click 是 code-behind 路线，语义同 Button。

`IsOpen` 手动开合溢出（做"更多操作"教程提示时用）。

## 23.2 MenuBar：经典菜单栏

```xml
<MenuBar>
    <MenuBarItem Title="File">
        <MenuFlyoutItem Text="New" Click="OnMenuNew"/>
        <MenuFlyoutSeparator/>
        <MenuFlyoutItem Text="Exit" Click="OnMenuExit"/>
    </MenuBarItem>
    <MenuBarItem Title="View">
        <ToggleMenuFlyoutItem Text="Show grid" IsChecked="True" Click="OnMenuGrid"/>
    </MenuBarItem>
</MenuBar>
```

菜单项四件套：`MenuFlyoutItem`（动作）/ `ToggleMenuFlyoutItem`（勾选态）/ `RadioMenuFlyoutItem`（组内单选，同 GroupName 机制）/ `MenuFlyoutSeparator`。桌面应用要 Alt+F 这类键盘流就配 `KeyboardAccelerators`。

## 23.3 上下文菜单：AttachedFlyout 模式（含一个大坑）

```xml
<Border x:Name="CtxZone" RightTapped="OnCtxZoneRightTapped" ...>
    <FlyoutBase.AttachedFlyout>
        <MenuFlyout>
            <MenuFlyoutItem Text="Refresh" Click="OnMenuRefresh"/>
            <MenuFlyoutItem Text="Delete" Click="OnMenuDelete"/>
        </MenuFlyout>
    </FlyoutBase.AttachedFlyout>
</Border>
```

```cpp
void CommandBarPage::OnCtxZoneRightTapped(IInspectable const& sender,
    Input::RightTappedRoutedEventArgs const& args)
{
    auto element = sender.as<FrameworkElement>();
    // 元数据实测：ShowAt 没有 (element, Point) 重载；位置要包进 FlyoutShowOptions
    Primitives::FlyoutShowOptions options;
    options.Position(args.GetPosition(element));
    FlyoutBase::GetAttachedFlyout(element).ShowAt(element, options);
    args.Handled(true);
    StatusText().Text(L"context flyout shown");
}
```

标准三步：**AttachedFlyout 挂菜单 → RightTapped 里 `GetAttachedFlyout(...).ShowAt(...)` → Handled(true)**。

> **实测坑（编译级 + 元数据）**：网上 UWP 资料写 `flyout.ShowAt(element, point)`——1.8 元数据里 `IFlyoutBase.ShowAt` 只有 `(FrameworkElement)` 和 `(DependencyObject, FlyoutShowOptions)` 两个重载，**没有 Point 版**。位置包进 `FlyoutShowOptions.Position`（它接受 `Windows.Foundation.Point`，正是 `GetPosition` 的返回类型）。直接抄旧 API 是 C2665。

## 23.4 三种命令容器的分工

| 容器 | 场景 |
|------|------|
| CommandBar | 页面级动作，常驻或溢出 |
| MenuBar | 文档型应用的传统菜单（File/Edit/View） |
| MenuFlyout（AttachedFlyout） | 右键/长按的上下文动作 |

选型依据是用户预期而非能力——三个容器装的都是"命令"，放哪儿决定用户找不找得到。

## 23.5 实测坑位

1. **ShowAt 无 Point 重载**（23.3，FlyoutShowOptions 包装）。
2. **SecondaryCommands 挤占主命令**：溢出是"低频"不是"备用"，全塞进去等于藏起来。
3. **Symbol 枚举覆盖有限**：没有的图标走 `FontIcon` Glyph（Segoe Fluent Icons 码表），别硬凑近义 Symbol。
4. **右键事件两个**：`RightTapped`（鼠标右键/长按）与 `ContextRequested`（新 API，更细）；AttachedFlyout 模式用前者最稳。

## 23.5 实战：三层命令入口同窗（ScratchPad）

```xml
<!-- 层一：MenuBar——完整命令集 -->
<MenuBar Grid.Row="0">
    <MenuBarItem Title="File">
        <MenuFlyoutItem Text="New tab" Click="OnNewTab">
            <MenuFlyoutItem.KeyboardAccelerators>
                <KeyboardAccelerator Modifiers="Control" Key="N"/>
            </MenuFlyoutItem.KeyboardAccelerators>
        </MenuFlyoutItem>
        <MenuFlyoutSeparator/>
        <MenuFlyoutItem Text="Save" Click="OnSave">...</MenuFlyoutItem>
        <MenuFlyoutSeparator/>
        <MenuFlyoutItem Text="Exit" Click="OnExit"/>
    </MenuBarItem>
    <MenuBarItem Title="Edit">
        <MenuFlyoutItem Text="Select all" Click="OnSelectAll"/>
        <MenuFlyoutItem Text="Find" Click="OnToggleFind"/>
        <MenuFlyoutItem Text="Bold" Click="OnBoldMenu"/>
    </MenuBarItem>
</MenuBar>

<!-- 层二：CommandBar——高频动作 -->
<CommandBar Grid.Row="3" DefaultLabelPosition="Right">
    <AppBarButton Icon="Add" Label="New tab" Click="OnNewTab"/>
    <AppBarButton Icon="Save" Label="Save" Click="OnSave"/>
    <AppBarToggleButton x:Name="BoldToggle" Icon="Bold" Label="Bold" Click="OnBold"/>
    <CommandBar.SecondaryCommands>
        <AppBarButton Icon="Find" Label="Find" Click="OnToggleFind"/>
    </CommandBar.SecondaryCommands>
</CommandBar>

<!-- 层三：加速器——键盘用户（根 Grid 上） -->
<Grid.KeyboardAccelerators>
    <KeyboardAccelerator Modifiers="Control" Key="S" Invoked="OnSaveKey"/>
    ...
</Grid.KeyboardAccelerators>
```

### 23.5.1 同一命令一份实现

三层入口在处理器层汇流：`OnNewTab`/`OnSave` 是公共终点；菜单的 `Click` 与按钮的 `Click` 签名相同（RoutedEventArgs 家族）直接共用；加速器的 `OnSaveKey` 里一行 `args.Handled(true)` + 转发：

```cpp
void MainWindow::OnSaveKey(Input::KeyboardAccelerator const&,
    Input::KeyboardAcceleratorInvokedEventArgs const& args)
{
    args.Handled(true);
    OnSave(nullptr, nullptr);
}
```

**菜单项内嵌 KeyboardAccelerators 的作用是显示**（Ctrl+N 印在菜单项右侧，教快捷键的存在）而非执行——真正拦键的是根 Grid 上的全局加速器（菜单没打开时它也在）。两处声明不冗余：一个管教学，一个管干活。

### 23.5.2 SecondaryCommands 与溢出

`CommandBar.SecondaryCommands` 放"该有但不常用"的命令（Find）——它们收进 `...` 溢出菜单，不占常驻位。**判断标准是频率而非重要性**：保存重要且高频（常驻 + 图标 + 文字），Find 重要但低频（溢出）。窗口窄时 CommandBar 还会自动把常驻项的 Label 折叠成纯图标——`DefaultLabelPosition="Right"` 先定常态，自动折叠是它的降级路径。

### 23.5.3 Exit 的实现选择

```cpp
void MainWindow::OnExit(IInspectable const&, RoutedEventArgs const&)
{
    Close();
}
```

Window::Close() 一行——不弹"确认退出"（没有未保存文档时那是冒犯；有时 21 章的页签关闭确认已经拦过了）。**确认对话框属于数据单元（页签/文档），不属于窗口**——窗口关闭要不要拦，WinUI 3 给的是 AppWindow.Closing 事件（31 章窗口篇细讲），菜单 Exit 主动 Close 不经过它，这是教学上值得点破的一条暗线。

### 23.5.4 图标的经济学

AppBarButton 的 `Icon` 有三档供给：**字体字形**（`Icon="Add"`——Segoe Fluent 内建枚举，零资产）、**FontIcon 自定义码**（`Glyph="&#xE790;"`——全量字形表里挑，22.6 导航项用的就是它）、**BitmapIcon/PathIcon**（自有图）。决策链：枚举有的用枚举（自动主题化+免资产）→ 字形表有的用码（记得查 Segoe Fluent Icons 字体页）→ 都没有才上图。**图标颜色的主题适配**（亮暗反转）只在前两档自动——BitmapIcon 要自己备两份或依赖白色+透明度。

### 23.5.5 菜单的键盘流

MenuBar 内建 Alt 助记键体系：按 Alt 高亮菜单标题首字母、再按字母展开（Windows 传统）。自定义加速键（如 F5=刷新）挂 KeyboardAccelerator 不带 Modifiers 即可。**别抢系统级**：Ctrl+Alt+Del 类组合拿不到，Alt+Space 是窗口菜单——23 章的加速器注册在应用窗口焦点内，全局热键（应用不在前台也响应）是 RegisterHotKey 的 Win32 领地（31 章）。

### 23.5.6 MenuFlyout 与右键菜单

上下文菜单（右键）的挂法：

```xml
<ListView ...>
    <ListView.ContextFlyout>
        <MenuFlyout>
            <MenuFlyoutItem Text="Open" Click="OnOpen"/>
            <MenuFlyoutSeparator/>
            <MenuFlyoutItem Text="Delete" Icon="Delete"/>
        </MenuFlyout>
    </ListView.ContextFlyout>
</ListView>
```

`ContextFlyout` 属性一切 UIElement 都有——**右键（桌面）与长按（触屏）自动触发**。位置自适应（控件的上下左右哪有空间去哪）。菜单项的 Icon 同 AppBarButton 的供给体系（23.5.4）。与 MenuBar 的分工：MenuBar 是全局命令的常驻入口，ContextFlyout 是**对象级**命令（"对这个文件做什么"）——同一个动作两边都出现（File>Open 与右键 Open）是正常冗余，处理器共用一个（23.5.1 的汇流原则）。

### 23.5.7 命令的 CanExecute 化（32 章前传）

三层入口共用处理器解决了"行为一致"，没解决"可用性一致"——没有选中项时 Bold 该灰。事件路线的土法：每个影响状态的交互后手动刷一批 `IsEnabled`（遗漏点是常态）；命令路线（`XamlUICommand` + `CanExecute` 事件）把可用性逻辑集中，三入口绑同一命令自动同步。设置中心/ScratchPad 体量小走事件；第 32 章把命令路线走全——**复杂度超过一屏命令时，事件路线的维护成本曲线陡升**，那是切换点。

## 23.6 小结

| 需求 | API |
|------|-----|
| 工具条 | CommandBar + AppBarButton/ToggleButton/Separator |
| 溢出 | SecondaryCommands |
| 菜单栏 | MenuBar + MenuFlyoutItem/Toggle/Radio |
| 右键菜单 | AttachedFlyout + RightTapped + ShowAt(FlyoutShowOptions) |
| 图标 | Icon="Symbol" / FontIcon Glyph / BitmapIcon |

ScratchPad 三层命令入口同窗：MenuBar（File/Edit 全命令集）、CommandBar（New tab/Save/Bold 高频动作）、KeyboardAccelerator（Ctrl+S/N/F/B）——三入口共用同一批处理器，菜单与加速器状态同步（OnBoldKey 同步 BoldToggle.IsChecked）。运行时证据：`.smoke/09-scratchpad/save/tap-2.png`。

---

上一篇：[22 NavigationView](./22-navigationview.md) ｜ 下一篇：[24 ContentDialog 与 Flyout](./24-dialogs-flyouts.md) ｜ 返回 [目录](../README.md)
