# 26. 样式与控件模板

上一篇：[25 TeachingTip、InfoBar 与 ToolTip](./25-overlays.md) ｜ 下一篇：[27 自定义控件与 UserControl](./27-custom-controls.md)

界面的"同一套外观"从重复属性里解放出来靠 Style；"换骨架"靠 ControlTemplate。本章讲两者机制与分工。示例来自画廊工程 `examples/26-customization/` 的 `StylesPage`（导航 **Styles** 项）。

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

## 26.5 小结

| 需求 | 手段 |
|------|------|
| 统一属性 | 隐式 Style（作用域内全类型生效） |
| 变体 | keyed Style + BasedOn |
| 换骨架 | ControlTemplate + ContentPresenter/TemplateBinding |
| 状态视觉 | VisualStateManager（28 章） |

画廊 `StylesPage` 运行时证据：`.smoke/26-customization/styles/click-2.png`——隐式样式两按钮成卡片、AccentBtn 实心、模板按钮药丸形，点击报 **"styled button works"**。

---

上一篇：[25 TeachingTip、InfoBar 与 ToolTip](./25-overlays.md) ｜ 下一篇：[27 自定义控件与 UserControl](./27-custom-controls.md) ｜ 返回 [目录](../README.md)
