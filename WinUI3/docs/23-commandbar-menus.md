# 23. CommandBar 与菜单

上一篇：[22 NavigationView](./22-navigationview.md) ｜ 下一篇：[24 ContentDialog 与 Flyout](./24-dialogs-flyouts.md)

命令的三个层次：常驻工具条（CommandBar）、菜单栏/上下文菜单（MenuBar/MenuFlyout）、以及它们共用的图标体系。示例来自画廊工程 `examples/21-controls-shell/` 的 `CommandBarPage`（导航 **CommandBar** 项）。

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

## 23.6 小结

| 需求 | API |
|------|-----|
| 工具条 | CommandBar + AppBarButton/ToggleButton/Separator |
| 溢出 | SecondaryCommands |
| 菜单栏 | MenuBar + MenuFlyoutItem/Toggle/Radio |
| 右键菜单 | AttachedFlyout + RightTapped + ShowAt(FlyoutShowOptions) |
| 图标 | Icon="Symbol" / FontIcon Glyph / BitmapIcon |

画廊 `CommandBarPage` 运行时证据：`.smoke/21-controls-shell/commandbar/click-2.png`——点击 Add，状态行 **"command: add"**；CommandBar/MenuBar/右键区三组控件同帧可见。

---

上一篇：[22 NavigationView](./22-navigationview.md) ｜ 下一篇：[24 ContentDialog 与 Flyout](./24-dialogs-flyouts.md) ｜ 返回 [目录](../README.md)
