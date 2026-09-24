# 26. 样式与控件模板

上一篇：[25 TeachingTip、InfoBar 与 ToolTip](./25-overlays.md) ｜ 下一篇：[27 自定义控件与 UserControl](./27-custom-controls.md)

界面的"同一套外观"从重复属性里解放出来靠 Style；"换骨架"靠 ControlTemplate。本章讲两者机制与分工。示例代码来自功能工程 `examples/26-theme-lab/`（主题实验室：预设换肤、自定义控件仪表盘、accent 即改、VSM、动画、Shape 图表）。

## 26.1 Style：属性批量覆盖

```xml
<Page.Resources>
    <!-- 隐式样式：无 x:Key，作用于本页所有 Button；另挂 key 供 BasedOn 继承
         （WinUI 3 无 x:Type，隐式样式没法直接被 BasedOn 引用） -->
    <Style x:Key="BaseBtn" TargetType="Button">
        <Setter Property="Background" Value="{ThemeResource CardBackgroundFillColorSecondaryBrush}"/>
        <Setter Property="BorderBrush" Value="{ThemeResource AccentFillColorDefaultBrush}"/>
        <Setter Property="BorderThickness" Value="1"/>
        <Setter Property="Padding" Value="14,8"/>
        <Setter Property="CornerRadius" Value="6"/>
    </Style>

    <Style x:Key="AccentBtn" TargetType="Button" BasedOn="{StaticResource BaseBtn}">
        <Setter Property="Background" Value="{ThemeResource AccentFillColorDefaultBrush}"/>
        <Setter Property="Foreground" Value="{ThemeResource TextOnAccentFillColorDefaultBrush}"/>
    </Style>
</Page.Resources>
```

机制三则：

1. **隐式 vs 显式**：`TargetType` 无 `x:Key` = 隐式，同类型控件全量生效；有 key 则要 `Style="{StaticResource key}"` 显式引用。隐式的杀伤范围是**声明所在的资源作用域**（本页 Resources 只影响本页；放 App.xaml 就是全应用——33 章的分层）。
2. **`BasedOn` 继承链**：在基样式上做增量。**UWP 的 `BasedOn="{StaticResource {x:Type Button}}"`（引用隐式样式）在 WinUI 3 编译不过——`x:Type` 不存在**（WMC0001 Unknown type 'Type'，实测）。要"隐式 + 可继承"，就像上面那样给隐式样式同时挂个 key。
3. **Setter 只设得到属性**：能写进 Style 的是控件的依赖属性；模板结构、事件挂接不行——那是模板/代码的事。

## 26.2 ControlTemplate：换骨架

```xml
<Button Content="Templated round" Click="OnTemplatedClicked">
    <Button.Template>
        <ControlTemplate TargetType="Button">
            <Border x:Name="PART_Border" CornerRadius="18"
                    Background="{ThemeResource AccentFillColorDefaultBrush}"
                    Padding="20,10" BorderThickness="1">
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"
                                  Foreground="{ThemeResource TextOnAccentFillColorDefaultBrush}"/>
            </Border>
        </ControlTemplate>
    </Button.Template>
</Button>
```

- **模板树替换视觉骨架，交互能力保留**——Click 照样触发（本页实测：点击报 "templated button works"）。
- `ContentPresenter` 是模板里"宿主内容"的占位；`TemplateBinding`（27 章的 `{TemplateBinding Label}`）把宿主属性透传进模板。
- **`ControlTemplate.Triggers` 不存在**（WPF/UWP 资料常见写法，WMC0011 实测）：模板内的状态视觉（hover/pressed）走 VisualStateManager，在 28 章展开。

**改样式还是改模板的决策线**：属性层差异（颜色/边距/圆角）用 Style；结构差异（要不要边框、内容放哪）用 Template。模板副本是深度定制——先看主题资源（33 章）里有没有现成的键可覆盖。

## 26.3 样式的查找链

`{StaticResource key}` 的解析沿元素树向上（Page.Resources → Window 无法承载 → App.Resources → 主题字典）。找不到 key 是**运行时抛错**（XamlParseException），不是静默；`ThemeResource` 与 `StaticResource` 的区别（主题切换是否重取）在 33 章展开。

## 26.4 实测坑位

1. **`x:Type` 不存在**（26.1，BasedOn 引隐式样式的 UWP 写法 → 挂 key）。
2. **`ControlTemplate.Triggers` 不存在**（26.2，WMC0011）。
3. **`TextElement.Foreground` 附加属性写法在 ContentPresenter 上不认**（实测 WMC0010）：直接用 `Foreground` 属性。
4. **隐式样式误伤**：给 App.xaml 写隐式 Button 样式 = 全应用按钮变形，确认这是意图。
5. **Style 里 setter 顺序**：同类属性后写覆盖先写；BasedOn 的优先级低于本地显式设置（XAML 属性 > Style）。

## 26.6 实战：运行时改主题资源（主题实验室）

演示页里换肤是"换个 Style 名"；主题实验室把换肤做成**资源系统级的操作**——往 `Application.Resources` 里盖一层 accent 键，全树的 `{ThemeResource Accent*}` 引用跟着走：

```cpp
void MainWindow::ApplyAccent(Windows::UI::Color const& color)
{
    auto resources = Application::Current().Resources();
    auto brush = SolidColorBrush(color);
    resources.Insert(box_value(L"AccentFillColorDefaultBrush"), brush);
    resources.Insert(box_value(L"AccentFillColorSecondaryBrush"), SolidColorBrush(Windows::UI::Color{
        0xFF,
        static_cast<uint8_t>(color.R * 0.8f),
        static_cast<uint8_t>(color.G * 0.8f),
        static_cast<uint8_t>(color.B * 0.8f) }));
    for (auto&& bar : m_bars) { bar.Fill(SolidColorBrush(color)); }
}
```

三个层次各司其职：

- **资源字典 Insert** 是正路：`AccentFillColorDefaultBrush` 是 XamlControlsResources 里的主题键，应用级字典同键覆盖后，按钮填充、单选圆点、滑杆轨道……所有走 ThemeResource 的控件换色——一处改，处处改。
- **Secondary 键手工调暗 20%**：Fluent 的次级 accent 有自己的明度曲线，简化成 0.8 倍乘算——够用且可控。
- **代码造的元素（m_bars 柱子）不能靠 ThemeResource**：`Resources().TryLookup` 拿不到 XamlControlsResources 内层字典的键（实测返回空）——代码里建的 Shape 想跟 accent 走，就把元素登记进容器，ApplyAccent 时全量重刷。**"资源跟随"与"手动重刷"的边界就是 XAML 声明与代码创建的边界。**

### 26.6.1 明暗壳：RequestedTheme 的双赋值

预设还带明暗（Sunset=暗壳）：

```cpp
if (auto root = Content().try_as<FrameworkElement>())
{
    root.RequestedTheme(preset.Dark ? ElementTheme::Dark : ElementTheme::Light);
}
```

配套实测坑：**运行时对根设 RequestedTheme，同值连设不触发 ThemeResource 重估**（WindowsAppSDK 实测）——先设 `ElementTheme::Default` 再设目标值，两轮变更通知才把整树刷过来。这条在设置中心（07 章）与主题实验室都验证过。

### 26.6.2 预设列表：隐式样式 + 数据模板的组合位

```xml
<ListBox x:Name="PresetList" SelectionChanged="OnPresetSelected">
    <ListBox.ItemTemplate>
        <DataTemplate x:DataType="local:PresetInfo">
            <StackPanel Orientation="Horizontal" Spacing="10">
                <Border Width="22" Height="22" CornerRadius="6">
                    <Border.Background>
                        <SolidColorBrush Color="{x:Bind Swatch}"/>
                    </Border.Background>
                </Border>
                <TextBlock Text="{x:Bind Name}" VerticalAlignment="Center"/>
            </StackPanel>
        </DataTemplate>
    </ListBox.ItemTemplate>
</ListBox>
```

每个预选项 = 色板（`Color` 直接 x:Bind 进 SolidColorBrush.Color）+ 名字。**色板是这套 UI 的"样式预览"**——用户不读 "#C42B1C"，读的是那块红。选中预设后 `PresetStatus` 状态行复述（"preset 'Sunset' (dark shell)"）——与 8 章的状态行纪律同源。

`.smoke/26-theme-lab/preset/tap-1.png`：Sunset 选中、窗口暗壳、柱状图红、状态行复述——Style/资源/主题三层在一次点击里同时生效，这就是"主题实验室"的存在意义。

### 26.6.3 ColorPicker：accent 的自由形态

```xml
<ColorPicker x:Name="AccentPicker" IsColorSliderVisible="True"
             IsColorChannelTextInputVisible="False"
             IsHexInputVisible="True" ColorChanged="OnAccentChanged"/>
```

`ColorChanged` 直通 ApplyAccent——拖动光谱的每一下都实时改全局 accent（状态行同步 "accent = #107,10,10"，`.smoke/26-theme-lab/picker/tap-1.png`）。三个可见性开关是信息密度旋钮：色相/饱和度光谱 + 明度滑杆 + 十六进制输入，按用户光谱（随手拖）到工程光谱（要精确值）分层供给。

### 26.6.4 隐式样式的覆盖顺位

应用级字典 Insert 的 accent 键优先于主题字典（先查应用层）——这正是 ApplyAccent 生效的机制。通用规律：**资源查找从使用点向上冒泡**（控件自身 Style → 页面资源 → 应用资源 → 主题资源），先命中先用。所以三层覆盖手法：控件直设属性（最高）> 页面/应用资源 > 主题默认。**别越过层级写死**——在控件上写死颜色的那一刻，主题切换、换肤、高对比模式全部失效；设置中心预览条用 `{ThemeResource AccentFillColorDefaultBrush}`（跟 accent 走）而文字用 `TextOnAccentFillColorDefaultBrush`（accent 上的前景色，自动保证对比度）——两个键成对用是 Fluent 的配色纪律。

### 26.6.5 Style 与资源的分工

Style 是"一组属性的预设包"（按类型命中）；资源是"值的具名仓库"（按键命中）。换肤改资源（值层，一处改处处跟）；换皮肤密度改 Style（结构层，ListViewItem 的 MinHeight——14 章实战）。**混淆的信号**：你在 Style 里写死颜色（该是 ThemeResource 引用）、或在资源里塞 Setter（该是 Style）。主题实验室的 ApplyAccent 动资源不动 Style，设置中心的 OnDensityChanged 动 Style 不动资源——两工程各示范一半，合起来是完整答案。

### 26.6.6 主题资源键的速查锚点

做换肤/配主题时最常用的键（Fluent 家族的公共子集）：`AccentFillColorDefaultBrush`（主强调填充）、`AccentTextFillColorPrimaryBrush`（强调文字色）、`CardBackgroundFillColorDefaultBrush`/`CardStrokeColorDefaultBrush`（卡片底/描边——DataExplorer 卡片、LabeledValueControl 瓷贴都用）、`LayerFillColorDefaultBrush`（浮层底）、`TextOnAccentFillColorDefaultBrush`（accent 上的文字）。**找键的方法**：Visual Studio 的 Live Visual Tree 看系统控件实际用的键名，或 WinUI 的 generic.xaml 源码——比背表可靠，因为版本会加新键。

### 26.6.7 BasedOn：站在默认样式的肩膀上

改一两个属性而保留系统样式的其余部分：

```xml
<Style TargetType="Button" BasedOn="{StaticResource DefaultButtonStyle}">
    <Setter Property="MinWidth" Value="120"/>
</Style>
```

**BasedOn 引的是 key 而非类型**——系统样式都有资源 key（DefaultButtonStyle/AcccentButtonStyle...），隐式样式（无 key）之间不能 BasedOn（要挂 key 才行，26 章实测坑的正式解法）。设置中心保存按钮直接用 AccentButtonStyle（零自定义）；密度样式（14 章）是纯代码 Style 不 BasedOn（容器自定义从零起更干净）——**两条路线：覆盖资源（值变）零样式代码，改结构才写 Style**。

## 26.7 练习与思考

1. 26.6.7 的 BasedOn：给 AccentButtonStyle 加 MinWidth=120 的派生样式——BasedOn 的 key 是什么？隐式样式间能 BasedOn 吗（26 章实测坑）？
2. 把 ThemeLab 的预设色板做成 Contrast 校验（WCAG AA 4.5:1）——哪些预设过不了？改色还是接受？
3. 26.6.3 的边界：柱子改用 ThemeResource 引用 + 资源覆盖（不手动重刷）——为什么 TryLookup 拿不到？两条路的本质差异是什么？

### 26.6.8 换肤的完整决策树

把这一章的散点串成一棵可执行的树：**换色值？**→ 覆盖 Application.Resources 的主题键（26.6）；**换布局参数？**→ Style + Setter（14 章密度）；**换整块长相？**→ ControlTemplate 重写（26.3）；**换明暗？**→ RequestedTheme 双赋值（26.6.1）；**全部一起换？**→ 预设（ThemeLab：四件事打包成一次点击）。**判断从"变的是什么"开始**，每层的成本与影响半径递增——最贵的（重模板）应该是最后的选择。

## 26.8 上生产前的审查清单

- [ ] 颜色全部走 ThemeResource/资源键，无写死
- [ ] 换肤路线按"变什么"选层（26.6.8 决策树）
- [ ] RequestedTheme 双赋值（重估坑）
- [ ] BasedOn 引 key 且注意隐式样式限制
- [ ] accent 上的文字用 TextOnAccent 系保证对比度

## 26.5 小结

| 需求 | 手段 |
|------|------|
| 统一属性 | 隐式 Style（作用域内全类型生效） |
| 变体 | keyed Style + BasedOn |
| 换骨架 | ControlTemplate + ContentPresenter/TemplateBinding |
| 状态视觉 | VisualStateManager（28 章） |

运行时证据：`.smoke/26-theme-lab/preset/tap-1.png`——点 Sunset 预设：`Application::Current().Resources()` 里 Insert 覆盖 Accent 键（26 章资源系统的运行时正路），整树 ThemeResource 引用跟着走、RequestedTheme 切暗（双赋值触发重估）、柱状图与新 accent 同帧变红。

---

上一篇：[25 TeachingTip、InfoBar 与 ToolTip](./25-overlays.md) ｜ 下一篇：[27 自定义控件与 UserControl](./27-custom-controls.md) ｜ 返回 [目录](../README.md)
