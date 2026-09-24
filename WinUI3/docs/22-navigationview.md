# 22. NavigationView 与 SplitView

上一篇：[21 TabView 与 Expander](./21-tabview-expander.md) ｜ 下一篇：[23 CommandBar 与菜单](./23-commandbar-menus.md)

NavigationView 是现代 Windows 应用的标准外壳——左侧（或顶部）导航栏 + 内容区。**设置中心的外壳就是它**，本章既是控件课也是"这个应用怎么搭的"的揭秘。示例代码来自功能工程 `examples/07-settings-hub/`（设置中心：主题/密度/透明度即点即生效并持久化）。

## 22.1 结构解剖：设置中心外壳的直接引用

```xml
<NavigationView x:Name="Nav" IsBackButtonVisible="Auto"
                PaneDisplayMode="Left" IsPaneOpen="True" OpenPaneLength="200"
                SelectionChanged="OnNavSelectionChanged">
    <NavigationView.MenuItems>
        <NavigationViewItem Content="Home" Tag="home"/>
        <!-- 每个分区一项 -->
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
    if (tag == L"appearance") ContentFrame().Navigate(xaml_typename<SettingsHub::AppearancePage>());
    // 每章一个分支
}
```

三件套：**MenuItems（导航项）+ Frame（内容宿主）+ SelectionChanged（分发）**。导航项用 `Tag` 携带路由键（装箱 hstring，unbox 回来），`NavigateTo` 查表跳页——这是"控件-页面"解耦的最短实现；页多了可换成 tag→`xaml_typename` 的数组表。

## 22.2 PaneDisplayMode 与自适应陷阱（本教程实测第一坑）

`PaneDisplayMode` 决定面板形态：`Auto`（默认，**随窗口宽度变形**）/ `Left` / `LeftCompact` / `LeftMinimal` / `Top` / `Bottom`。

**设置中心骨架开发实录**：外壳没钉模式时，150% DPI 下 900 物理px 的窗口 = 600 逻辑px，低于 Auto 模式的展开阈值——**面板自折叠成汉堡条**，导航项全部消失。修法即上面 XAML 里的 `PaneDisplayMode="Left"` 钉死。教训：**要稳定左栏就显式 Left，别赌 Auto 的断点**；真要做响应式（窄窗口收起），用 28 章的 AdaptiveTrigger 自己控制切换时机。

`IsPaneOpen`/`OpenPaneLength` 是面板的开关与宽度；汉堡按钮自动提供切换。三个模式（Left/LeftCompact/Top）可以在属性面板现场切换对比，状态行回报当前模式。

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

NavigationView 内部就是一个 SplitView 加上完整的导航交互（汉堡、返回、选中态、自适应）。直接用 SplitView 的场景：**自制非标准外壳**——工具面板、侧边详情栏。参数对照：`DisplayMode`（Overlay 浮在内容上 / Inline 推挤内容 / CompactInline 带窄条）对应 NavigationView 的 PaneDisplayMode 子集；`IsPaneOpen`/`OpenPaneLength` 同名同义。DataExplorer 的侧栏就是一个活的 SplitView（Category 树在 Pane、主列表在内容区）。

## 22.5 实测坑位

1. **Auto 模式自折叠**（22.2，DPI 换算后低于阈值——设置中心与数据浏览器全部钉死 `Left`）。
2. **Tag 装箱路由键**：`unbox_value<hstring>(item.Tag())`；混合类型 Tag 时先 try_as 判型。
3. **SelectionChanged 解析期触发**（12.5 通用坑，外壳 handler 里 Frame 已就绪；页面内嵌的第二个 NavigationView 同样要防）。
4. **Frame 每次重建页面**：状态丢失先查 `NavigationCacheMode`。
5. **菜单行距随条目数变**（自动化视角）：NavigationView 菜单行距**不是常数**——本教程实测 6 项 ≈72px、7+ 项收紧到 ≈56px、11 项 ≈50px。UI 自动化点击导航项不能线性外推坐标，要按当前条目数实测（ui-smoke 的场景表因此存实测坐标）。

## 22.6 实战：设置中心的完整外壳

```xml
<NavigationView x:Name="Nav" IsBackButtonVisible="Collapsed"
                PaneDisplayMode="Left" IsPaneOpen="True" OpenPaneLength="210"
                SelectionChanged="OnNavSelectionChanged">
    <NavigationView.AutoSuggestBox>
        <AutoSuggestBox x:Name="SearchBox" QueryIcon="Find" .../>   <!-- 15 章 -->
    </NavigationView.AutoSuggestBox>
    <NavigationView.MenuItems>
        <NavigationViewItem Content="Appearance" Tag="appearance">
            <NavigationViewItem.Icon><FontIcon Glyph="&#xE790;"/></NavigationViewItem.Icon>
        </NavigationViewItem>
        <!-- Notifications / Preferences 同构 -->
    </NavigationView.MenuItems>
    <Grid>
        <Frame x:Name="ContentFrame"/>
        <InfoBar x:Name="SavedBar" VerticalAlignment="Bottom" .../>   <!-- 25 章：浮层 -->
    </Grid>
</NavigationView>
```

四个实战细节：

- **`IsBackButtonVisible="Collapsed"`**：三页设置没有层级深度，返回按钮只会误点。Auto（默认）在无历史时也占位——Collapsed 连占位都不留。
- **图标用 FontIcon + Segoe 字形码**（`&#xE790;` 画笔、`&#xEA8F;` 铃铛、`&#xE713;` 齿轮）——Segoe MDL2/Fluent 字体系统自带，无资产文件、自动跟随主题色。
- **InfoBar 做内容浮层**（在 Frame 之上、VerticalAlignment=Bottom）：保存反馈贴着内容区底部弹，不占布局行——多窗格应用里"全局状态条"与"分区内反馈"的分界。
- **构造期直航首页**：

```cpp
MainWindow::MainWindow()
{
    InitializeComponent();
    ...
    ContentFrame().Navigate(xaml_typename<SettingsHub::AppearancePage>());
}
```

不设 Nav 初始选中、不依赖"首次 SelectionChanged"——**导航到首页这件事不经过事件**（解析期事件的家族风险，22.5 坑 3 的正面用法）。用户点导航项后才走 OnNavSelectionChanged → NavigateTo(tag) 的正路。

### 22.6.1 导航项的增删成本

设置中心三页是静态 MenuItems——加第四个分区 = XAML 加一项 + NavigateTo 加一个分支（`if (tag == L"notifications") ...`）。页数过十时换查表：`static std::pair<hstring, xaml_typename_class> 表[]` 循环匹配。**别急着抽象**：三分支的 if 链比任何注册机制都好读，"每章任务在此追加分支"的注释就是它的扩展说明书。

### 22.6.2 页面状态与导航缓存

设置中心三页每次导航重建（默认 NavigationCacheMode.Disabled）——**这是刻意的**：页面构造函数即状态恢复器（读 SettingsStore 预置控件），重建=回到最新存储值，用户改了没保存的项导航回来会"丢"——正是"先试后存"语义的组成部分。反例是需要保留草稿的表单页：`NavigationCacheMode="Required"` 让页面实例常驻，OnNavigatedTo 只在真正重入时刷新——**两种模式对应两种产品语义**（设置=每次进来看存储值 vs 表单=离开再回草稿还在），别按性能直觉选。

### 22.6.3 导航返回栈

`Frame.Navigate` 压栈、`GoBack` 弹栈——设置中心把返回按钮 Collapsed 了，但**栈还在涨**（每次点导航项压一层）。三页应用无所谓；页多后内存与"按返回回到哪"的不可预测性都来。清法：导航时 `Frame.BackStack().Clear()`（一次性应用的标准姿势）或 NavigationView 的 `ShoulderNavigationEnabled`（触摸边缘导航配套）。32 章的 MVVM 导航会把"谁管栈"再抽象一层。

### 22.6.4 顶栏形态与 PaneTitle

`PaneDisplayMode="Top"` 把导航项横排到标题栏下（Office 系形态）——适合**平级且少**（≤5）的目的地；左侧形态容纳更多项与分组。设置中心用 Left + 图标（三项目标感更强）。`PaneTitle` 给面板顶部加标题（"Settings Hub"）——**左栏窄（210）时标题要短**，折叠成图标栏后 PaneTitle 自动隐藏。另一个易漏属性：`IsPaneToggleButtonVisible`（自定义汉堡按钮时关掉内建的）——31 章自定义标题栏应用会用到。

### 22.6.5 FooterMenuItems：底部的第二菜单区

```xml
<NavigationView.FooterMenuItems>
    <NavigationViewItem Content="About" Icon="Help"/>
</NavigationView.FooterMenuItems>
```

面板底部独立一块（设置/关于的传统位置）——与主菜单用**空间隔离**表达"这是应用级而非内容级导航"。设置中心没放（教学三页够了）；产品应用几乎必有。`IsSettingsVisible="True"`（默认）会自动生成齿轮项走 `SettingsInvoked` 事件——设置中心自己就是设置页，再放一个齿轮是套娃，所以没开。

### 22.6.6 顶部形态的完整参数

切 `PaneDisplayMode="Top"` 时的配套：**IsBackButtonVisible 必须显式 Collapsed**（顶栏塞返回按钮非常态）；`OpenPaneLength` 失义（顶栏全宽）；菜单项**只显图标+文字横排**（图标建议全给，纯文字顶栏像上古网页）。设置中心左栏形态的参数（Pane 210 + 图标 + ASB 槽）在顶栏全作废——**换形态不是换一个属性**，是一组参数的重组，先在纸上画目标形态再动 XAML。

### 22.6.7 导航与权限/状态 gating

产品导航常要"某项在特定条件下不可用"：`NavigationViewItem.IsEnabled=false`（灰显但占位——用户知道存在）vs 直接不放进 MenuItems（隐藏——用户不知道存在）。**灰显传达"以后能有"，移除传达"这里没有"**：未登录时"同步"项灰显（登录后能用），免费版里"Pro 功能"直接不出现（不想种草就别露脸）。设置中心三页永远可用，无此层——但这是真实导航壳绕不开的一课。

### 22.6.8 过渡动画与导航

页切换默认无动画（Frame.Navigate 直接跳）——加 `Frame.ContentTransitions`（NavigationThemeTransition）获得系统级滑动过场，一行 XAML。**导航动画的方向语义**：前进从右滑入、后退向左滑出——Frame 的导航栈自动判定方向，你不用管。设置中心没加（设置页切换要"快"不要"炫"）；内容消费类应用（阅读器、浏览器）值得加——**动画的存在理由是解释空间关系**（从哪来、到哪去），不是装饰。

## 22.7 练习与思考

1. 22.6.3 的返回栈：给设置中心加 IsBackButtonVisible=Auto，实测点三次导航后按返回——栈里是什么？再用 BackStack().Clear() 的姿势修它。
2. 把搜索结果做成第四种导航来源（22.6.1 的三路径之外）：搜索选中后返回栈要不要记录？你的规则是什么？
3. FooterMenuItems 加 About 页（22.6.5）——它和主菜单的 Tag 路由共用 NavigateTo 吗？分离的理由？

### 22.6.9 导航项的数据驱动形态

导航项过十或需要权限过滤时，MenuItems 换 `MenuItemsSource`（接向量 + ItemTemplate）——设置中心三页的静态 XAML 是教学形态；数据驱动的完整形态：`IVector<NavItem{Name, Glyph, Tag}>` 模板里 x:Bind 三样，SelectionChanged 的路由逻辑一字不改。**静态到数据驱动的切换点**：导航结构进入配置/权限系统时——本地代码常量永远快过任何绑定，别过早数据化。

## 22.6 小结

| 需求 | API |
|------|-----|
| 应用外壳 | NavigationView：MenuItems + Frame + SelectionChanged |
| 稳定左栏 | `PaneDisplayMode="Left"`（别赌 Auto） |
| 底部设置区 | FooterMenuItems / SettingsItem |
| 返回 | IsBackButtonVisible + BackRequested + Frame.GoBack |
| 自制侧栏 | SplitView：DisplayMode + IsPaneOpen |

设置中心的外壳就是 NavigationView：三项导航 + 内建 AutoSuggestBox 搜索槽位 + Frame 承载三页；构造期直接 Navigate 到首页（不依赖初始选中事件——22 章实测坑）。运行时证据：`.smoke/07-settings-hub/search/tap-2.png`。

---

上一篇：[21 TabView 与 Expander](./21-tabview-expander.md) ｜ 下一篇：[23 CommandBar 与菜单](./23-commandbar-menus.md) ｜ 返回 [目录](../README.md)
