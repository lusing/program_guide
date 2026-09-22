# 22. NavigationView 与 SplitView

上一篇：[21 TabView 与 Expander](./21-tabview-expander.md) ｜ 下一篇：[23 CommandBar 与菜单](./23-commandbar-menus.md)

NavigationView 是现代 Windows 应用的标准外壳——左侧（或顶部）导航栏 + 内容区。**教程三个画廊工程的外壳就是它**，本章既是控件课也是"这些画廊怎么搭的"的揭秘。示例来自画廊工程 `examples/21-controls-shell/` 的 `NavPage`（导航 **NavigationView** 项）。

## 22.1 结构解剖：画廊外壳的直接引用

```xml
<NavigationView x:Name="Nav" IsBackButtonVisible="Auto"
                PaneDisplayMode="Left" IsPaneOpen="True" OpenPaneLength="200"
                SelectionChanged="OnNavSelectionChanged">
    <NavigationView.MenuItems>
        <NavigationViewItem Content="Home" Tag="home"/>
        <!-- 画廊的每个演示页一项 -->
    </NavigationView.MenuItems>
    <Frame x:Name="ContentFrame"/>
</NavigationView>
```

```cpp
void MainWindow::OnNavSelectionChanged(IInspectable const&,
    NavigationViewSelectionChangedEventArgs const& args)
{
    if (auto item = args.SelectedItem().try_as<NavigationViewItem>())
    {
        NavigateTo(winrt::unbox_value<winrt::hstring>(item.Tag()));   // Tag 装箱字符串
    }
}

void MainWindow::NavigateTo(winrt::hstring const& tag)
{
    if (tag == L"home") ContentFrame().Navigate(xaml_typename<BasicGallery::HomePage>());
    // 每章一个分支
}
```

三件套：**MenuItems（导航项）+ Frame（内容宿主）+ SelectionChanged（分发）**。导航项用 `Tag` 携带路由键（装箱 hstring，unbox 回来），`NavigateTo` 查表跳页——这是"控件-页面"解耦的最短实现；页多了可换成 tag→`xaml_typename` 的数组表。

## 22.2 PaneDisplayMode 与自适应陷阱（本教程实测第一坑）

`PaneDisplayMode` 决定面板形态：`Auto`（默认，**随窗口宽度变形**）/ `Left` / `LeftCompact` / `LeftMinimal` / `Top` / `Bottom`。

**画廊骨架开发实录**：外壳没钉模式时，150% DPI 下 900 物理px 的窗口 = 600 逻辑px，低于 Auto 模式的展开阈值——**面板自折叠成汉堡条**，导航项全部消失。修法即上面 XAML 里的 `PaneDisplayMode="Left"` 钉死。教训：**要稳定左栏就显式 Left，别赌 Auto 的断点**；真要做响应式（窄窗口收起），用 28 章的 AdaptiveTrigger 自己控制切换时机。

`IsPaneOpen`/`OpenPaneLength` 是面板的开关与宽度；汉堡按钮自动提供切换。`NavPage` 演示页把这三个模式做成了按钮现场切换（Left/LeftCompact/Top），状态行回报当前模式。

## 22.3 其余成员速览

| 成员 | 用途 |
|------|------|
| `MenuItems` / `MenuItemsSource` | 静态 / 集合驱动 |
| `FooterMenuItems` | 底部区（设置、关于） |
| `SettingsItem` | 自动生成的"设置"项（`IsSettingsVisible`） |
| `IsBackButtonVisible` + `BackRequested` | 返回按钮（自己管 Frame.GoBack 与历史） |
| `Header` / `AutoSuggestBox` | 标题区 / 内嵌搜索框（15 章） |
| `SelectionChanged` vs `ItemInvoked` | 选中态变化 / 纯点击（允许点已选项时用后者） |

`Frame.Navigate` 的页面缓存：默认每次导航重建页面（`NavigationCacheMode.Disabled`）；表单类页面要保状态就 `NavigationCacheMode="Required"` 或 Enabled——但缓存页的 OnNavigatedTo 不会每次走，刷新逻辑放对地方。

## 22.4 SplitView：NavigationView 的底座

```xml
<SplitView x:Name="Split" DisplayMode="Inline" OpenPaneLength="160">
    <SplitView.Pane>
        <TextBlock Text="pane" Margin="12"/>
    </SplitView.Pane>
    <TextBlock Text="content" HorizontalAlignment="Center" VerticalAlignment="Center"/>
</SplitView>
```

NavigationView 内部就是一个 SplitView 加上完整的导航交互（汉堡、返回、选中态、自适应）。直接用 SplitView 的场景：**自制非标准外壳**——工具面板、侧边详情栏。参数对照：`DisplayMode`（Overlay 浮在内容上 / Inline 推挤内容 / CompactInline 带窄条）对应 NavigationView 的 PaneDisplayMode 子集；`IsPaneOpen`/`OpenPaneLength` 同名同义。`NavPage` 下方有完整的开合演示。

## 22.5 实测坑位

1. **Auto 模式自折叠**（22.2，DPI 换算后低于阈值——本教程三个画廊全部钉死 `Left`）。
2. **Tag 装箱路由键**：`unbox_value<hstring>(item.Tag())`；混合类型 Tag 时先 try_as 判型。
3. **SelectionChanged 解析期触发**（12.5 通用坑，画廊外壳 handler 里 Frame 已就绪，页面内嵌的第二个 NavigationView 同样要防）。
4. **Frame 每次重建页面**：状态丢失先查 `NavigationCacheMode`。
5. **菜单行距随条目数变**（自动化视角）：NavigationView 菜单行距**不是常数**——本教程实测 6 项 ≈72px、7+ 项收紧到 ≈56px、11 项 ≈50px。UI 自动化点击导航项不能线性外推坐标，要按当前条目数实测（ui-smoke 的场景表因此存实测坐标）。

## 22.6 小结

| 需求 | API |
|------|-----|
| 应用外壳 | NavigationView：MenuItems + Frame + SelectionChanged |
| 稳定左栏 | `PaneDisplayMode="Left"`（别赌 Auto） |
| 底部设置区 | FooterMenuItems / SettingsItem |
| 返回 | IsBackButtonVisible + BackRequested + Frame.GoBack |
| 自制侧栏 | SplitView：DisplayMode + IsPaneOpen |

画廊 `NavPage` 运行时证据：`.smoke/21-controls-shell/navigationview/click-2.png`——点击 Compact，内嵌 NavigationView 收成窄条，状态行 **"pane mode = LeftCompact"**；下方 SplitView 演示同帧可见。

---

上一篇：[21 TabView 与 Expander](./21-tabview-expander.md) ｜ 下一篇：[23 CommandBar 与菜单](./23-commandbar-menus.md) ｜ 返回 [目录](../README.md)
